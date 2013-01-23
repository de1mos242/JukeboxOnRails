require "rubygems"
require "amqp"
require 'yaml'

module MessageQueue

	class BaseQueue
		def self.SendBroadcastMessage(exchange_name,headers = {},body = "")
			event_machine_was_running = EM.reactor_running?
			begin
				p "sending message #{exchange_name} with #{body} when reactor_running? #{event_machine_was_running}"
				if event_machine_was_running
					SendBroadcastInEM(exchange_name, headers, body, false)
				else
					EM.run do
						SendBroadcastInEM(exchange_name, headers, body, true)
					end
				end
			rescue Exception => e
				puts "Hustron, some common problems with send: #{e}"
				puts "Backtrace: #{e.backtrace}"
				EventMachine.stop if EM.reactor_running? && !event_machine_was_running
			end

			#EM.add_timer(3) {EM.stop}
			#end
	  end

		def self.load_credentials
			rails_root = File.expand_path('../../..', __FILE__)
			env = ENV['RACK_ENV'] || 'development'
			YAML.load(File.read(File.join(rails_root, "config", "mq.yml")))[env]
		end

		def self.SendBroadcastInEM(exchange_name,headers,body, need_stop_reactor)
			credentials = load_credentials
			AMQP.connect(host: credentials[:location], 
					user: credentials[:user], 
					pass: credentials[:pass], 
					vhost: credentials[:vhost]
					) do |connection|
				p "connected to amqp"
				connection.on_error do |conn, connection_close|
			      puts <<-ERR
			      Handling a connection-level exception.
			 
			      AMQP class id : #{connection_close.class_id},
			      AMQP method id: #{connection_close.method_id},
			      Status code   : #{connection_close.reply_code}
			      Error message : #{connection_close.reply_text}
			      ERR
			 
			      EventMachine.stop unless need_stop_reactor
			    end
				channel = AMQP::Channel.new(connection)
				channel.on_error do |ch, close|
    				puts "Huston, channel problems: #{close.reply_text}, #{close.inspect}"
    				EventMachine.stop unless need_stop_reactor
  				end
  				exchange = channel.fanout("#{credentials[:entities_prefix]}.#{exchange_name}")
  				p "message sending to #{credentials[:entities_prefix]}.#{exchange_name}"
  				exchange.publish(body, headers: headers, timestamp: Time.now.to_i) do
  					p "message sended to #{credentials[:entities_prefix]}.#{exchange_name}"
  					p "reactor state: running? #{EM.reactor_running?} and need_stop_reactor: #{need_stop_reactor}"
  					EventMachine.stop if need_stop_reactor
  				end
			end
		end

    # Required to be running in EventMachine
    def self.Listen(exchange_name, callback)
      credentials = load_credentials
      AMQP.connect(host: credentials[:location],
                   user: credentials[:user],
                   pass: credentials[:pass],
                   vhost: credentials[:vhost]
      ) do |connection|
        p "connected to amqp"
        connection.on_error do |conn, connection_close|
          puts <<-ERR
			      Handling a connection-level exception.

			      AMQP class id : #{connection_close.class_id},
			      AMQP method id: #{connection_close.method_id},
			      Status code   : #{connection_close.reply_code}
			      Error message : #{connection_close.reply_text}
          ERR
        end
        channel = AMQP::Channel.new(connection)
        channel.on_error do |ch, close|
          puts "Huston, channel problems: #{close.reply_text}, #{close.inspect}"
        end
        exchange = channel.fanout("#{credentials[:entities_prefix]}.#{exchange_name}")
        p "reveiving messages from #{credentials[:entities_prefix]}.#{exchange_name}..."
        channel.queue("#{credentials[:entities_prefix]}.#{exchange_name}.queue", auto_delete:true).bind(exchange).subscribe do |metadata, payload|
          p "get message from #{exchange_name}"
          callback.call(payload, metadata)
        end
      end
    end









		def initialize
			
			rails_root = File.expand_path('../../..', __FILE__)
			env = ENV['RACK_ENV'] || 'development'
			@credentials = YAML.load(File.read(File.join(rails_root, "config", "mq.yml")))[env]
			unless EM.reactor_running?
				Thread.new do 
					connect
				end
				sleep(1)
			else
				connect
			end
			@connection = AMQP.connection
			x = gets
			get_channel

		end

		def connect
			begin
				AMQP.connect(host: @credentials[:location], 
						user: @credentials[:user], 
						pass: @credentials[:pass], 
						vhost: @credentials[:vhost],
						on_tcp_connection_failure: Proc.new {|e| handle_tcp_exception(e) }
						) do |connection|
					yield(connection) if block_given?
				end
			#rescue Exception => e
		#		connection_error(e)
			end
		end

		def get_channel
			raise "Not connected!" if @connection.nil?
			@channel = AMQP::Channel.new(@connection)
	  		@channel.on_error(&method(:handle_channel_exception))
		end

		def run_in_event_machine
			em_was_running = EM.reactor_running?
			p "run in em before: #{em_was_running}"
			unless em_was_running
				p "run em"
				EM.run do
					p "run yield in created em"
					yield
					p "stop em"
					EM.add_timer(2) { EM.stop }
		  		end
	  		else
	  			p "just run"
	  			yield
			end
		end

		def handle_channel_exception(channel, channel_close)
			exception_string = "code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
			puts "Huston, we have a problem: #{exception_string}"
			on_error exception_string
		end # handle_channel_exception(channel, channel_close)

		def handle_tcp_exception(e)
			puts "TCP connection failed with: #{e}"
			on_error e
		end

		def handle_authentication_exception(e)
			puts "Authenticate failed with: #{e}"
			on_error e
		end

		def connection_error(e)
			puts "Common connection failed with: #{e}"
			on_error e
		end

		def on_error(e)
			#EventMachine.stop if EventMachine.reactor_running?
			raise e
		end
	end
end