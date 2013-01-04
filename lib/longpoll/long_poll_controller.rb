RAILS_ROOT = File.expand_path('../../..', __FILE__)
require RAILS_ROOT + '/config/boot'
require 'sinatra/async'

require 'active_record'
require 'active_support/all'
require 'active_support/json'

db_config = YAML.load(File.read('./config/database.yml')).with_indifferent_access
ActiveRecord::Base.include_root_in_json = false
ActiveRecord::Base.configurations = db_config
ActiveRecord::Base.establish_connection(ENV['RACK_ENV'] || 'development')

require RAILS_ROOT + "/app/models/playlist_item"
require RAILS_ROOT + "/app/models/song"

class LongPollController < Sinatra::Base
  register Sinatra::Async

  def self.get_data
    data = {}
    data[:playlist_items] = PlaylistItem.position_sorted.in_queue.all
    data[:current_song] = PlaylistItem.current_song
    data
  end

  @@current_data = get_data
  @@changed_time = Time.now

  EM.next_tick do
    EM.add_periodic_timer(1) do
      new_data = get_data
      unless new_data == @@current_data
        p "check happen"
        @@changed_time = Time.now
        @@current_data = new_data
      end
    end
  end

  # Create a new HTTP verb called OPTIONS.
  # Browsers (should) send an OPTIONS request to get Access-Control-Allow-* info.
  def self.http_options(path, opts={}, &block)
    route 'OPTIONS', path, opts, &block
  end

  # Ideally this would be in http_options below. But not all browsers send
  # OPTIONS pre-flight checks correctly, so we'll just send these with every
  # response. I'll discuss what some of them mean in Part 2.
  before do
    response.headers['Access-Control-Allow-Origin'] = '*' # If you need multiple domains, just use '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'X-CSRF-Token' # This is a Rails header, you may not need it
  end

  # We need something to respond to OPTIONS, even if it doesn't do anything
  http_options '/' do
    halt 200
  end

  # The root path will serve as a kind of "ping" for our clients.
  # We'll respond to everything with JSON.
  aget '/' do
    response.headers['Content-Type'] = 'application/json'
    body "ok"
  end

  # Technically we should use GET, but POST makes it less susceptible to abuse
  apost '/refresh' do
    begin
      p 'get post'
      response.headers['Content-Type'] = 'application/json'

      callback = proc do |new_data|
        p "get callback with data: #{new_data}"
        if new_data.has_key?(:current_song)
          result = '{'
          result += "\"playlist_items\": #{new_data[:playlist_items].to_json(include: {song: {only: [:artist, :title, :duration]}}).html_safe},"
          result += "\"current_song\": #{new_data[:current_song].to_json(only: [:artist, :title, :duration]).html_safe},"
          result += "\"last_update\": \"#{@@changed_time.to_r}\""
          result += '}'
        else
          result = new_data.to_json.html_safe
        end
        p "send to client: #{result}"
        body result
      end
      p "params: #{params.inspect} #{params["last_update"]} and #{params["last_update"].blank?}"
      unless params["last_update"].blank?
        p "run async"
        request_time = Time.at(params["last_update"].to_r)
        p "request_time: #{request_time}"
        pollster = proc do
          time = 0
          until time > 10
            break if @@changed_time > request_time
            sleep 0.5
            time += 0.5
          end
          p "data changed! with #{@@changed_time} and #{request_time}" if @@changed_time > request_time
          @@changed_time > request_time ? @@current_data : {"noData" => "nothing happen", "last_update" =>  "#{@@changed_time.to_r}"}
        end
        p "begin async"
        # Begin asynchronous work
        EM.defer(pollster, callback)

      else
        p 'answer sync'
        callback.call(@@current_data)
        #body "ok"
      end

    rescue Exception => ex
      p "handle exc: #{ex}"
    end
  end
  
end