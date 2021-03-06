rails_root = File.expand_path('../../..', __FILE__)
require "rubygems"
require "amqp"
require 'yaml'

require 'active_record'
require 'active_support/all'
require 'active_support/json'

require "#{rails_root}/lib/audio/playback_base"
require "#{rails_root}/lib/audio/gstream_playback"

require "#{rails_root}/lib/mq/base_queue"

require "#{rails_root}/app/models/playlist_item"
require "#{rails_root}/app/models/song"
require "#{rails_root}/app/models/playlist"

db_config = YAML.load(File.read(File.join(rails_root, 'config', 'database.yml'))).with_indifferent_access
ActiveRecord::Base.include_root_in_json = false
ActiveRecord::Base.configurations = db_config
ActiveRecord::Base.establish_connection(ENV['RACK_ENV'] || 'development')

credentials = MessageQueue::BaseQueue.load_credentials

def on_refresh_message
	Playlist.refresh
end

def on_stop_message
	Playlist.stop
end

def on_skip_message
	Playlist.skip
end

def on_add_song(song_id)
	p "add song with id #{song_id}"
	song = Song.find(song_id)
	p "add song #{song}"
	Playlist.add_song(song)
end

def push_to_longpoll(channel, exchange_prefix)
  exchange = channel.fanout("#{exchange_prefix}.longpoll.refresh")

end

begin
	AMQP.start(host: credentials[:location],
			user: credentials[:user], 
			pass: credentials[:pass], 
			vhost: credentials[:vhost]
			) do |connection|

    Playlist.refresh

    connection.on_error do |conn, connection_close|
      puts <<-ERR
      Handling a connection-level exception.

      AMQP class id : #{connection_close.class_id},
      AMQP method id: #{connection_close.method_id},
      Status code   : #{connection_close.reply_code}
      Error message : #{connection_close.reply_text}
      ERR

      EventMachine.stop
    end

    channel = AMQP::Channel.new(connection)
		channel.on_error do |ch, close|
			puts "Huston, channel problems: #{close.reply_text}, #{close.inspect}"
			EventMachine.stop
		end

		exchange_prefix = "#{credentials[:entities_prefix]}"

		p "refresh"
		exchange = channel.fanout("#{exchange_prefix}.playlist.refresh")
		channel.queue("#{exchange_prefix}.playlist.refresh.queue", auto_delete:true).bind(exchange).subscribe do |metadata, payload|
    		p "get refresh"
    		on_refresh_message
		end

		p "skip"
		exchange = channel.fanout("#{exchange_prefix}.playlist.skip")
		channel.queue("#{exchange_prefix}.playlist.skip.queue", auto_delete:true).bind(exchange).subscribe do |metadata, payload|
    		p "get skip"
    		on_skip_message
		end

		p "stop"
		exchange = channel.fanout("#{exchange_prefix}.playlist.stop")
		channel.queue("#{exchange_prefix}.playlist.stop.queue", auto_delete:true).bind(exchange).subscribe do |metadata, payload|
    		p "get stop"
    		on_stop_message
		end

		p "add song"
		exchange = channel.fanout("#{exchange_prefix}.playlist.add.song")
		channel.queue("#{exchange_prefix}.playlist.add_song.queue", auto_delete:true).bind(exchange).subscribe do |metadata, payload|
    		p "add song"
    		on_add_song payload
		end
	end
rescue Exception => e
	puts "Huston, some common problems: #{e}"
	puts "Backtrace: #{e.backtrace}"
	EventMachine.stop if EventMachine.reactor_running?
end