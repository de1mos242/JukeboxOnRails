rails_root = File.expand_path('../../..', __FILE__)
require rails_root + '/config/boot'
require 'sinatra/async'

require 'active_record'
require 'active_support/all'
require 'active_support/json'

db_config = YAML.load(File.read("#{rails_root}/config/database.yml")).with_indifferent_access
ActiveRecord::Base.include_root_in_json = false
ActiveRecord::Base.configurations = db_config
ActiveRecord::Base.establish_connection(ENV['RACK_ENV'] || 'development')

require "#{rails_root}/app/models/playlist_item"
require "#{rails_root}/app/models/song"
require "#{rails_root}/lib/mq/base_queue"

class LongPollController < Sinatra::Base
  register Sinatra::Async

  @@current_data = "{}"
  @@changed_time = Time.now

  listener_callback = proc do |body, metadata|
    @@current_data = body
    @@changed_time = Time.at(metadata.headers["update_ts"].to_r)
  end

  EM.next_tick do
    MessageQueue::BaseQueue.Listen("longpoll.refresh", listener_callback)
    MessageQueue::BaseQueue.SendBroadcastMessage("playlist.refresh") # send request for initial data
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

      callback = proc do |result|
        p "get callback with data: #{result}"
        if result[:has_data]
          body result[:new_data]
        else
          status 304
          content_type "application/json"
          body "{}"
        end
      end


      p "params: #{params.inspect} #{params["last_update"]} and #{params["last_update"].blank?}"
      unless params["last_update"].blank?
        p "run async"
        request_time = Time.at(params["last_update"].to_r)
        p "request_time: #{request_time}"
        pollster = proc do
          time = 0
          until time > 25
            break if @@changed_time > request_time
            sleep 0.5
            time += 0.5
          end
          p "data changed! with #{@@changed_time} and #{request_time}" if @@changed_time > request_time
          @@changed_time > request_time ? {has_data: true, new_data: @@current_data} : {has_data:false}
        end
        p "begin async"
        # Begin asynchronous work
        EM.defer(pollster, callback)

      else
        p 'answer sync'
        callback.call({has_data: true, new_data: @@current_data})
        #body "ok"
      end

    rescue Exception => ex
      p "handle exc: #{ex}"
    end
  end
  
end