require 'gst'

module AudioPlayback
  
  class GStreamPlayback

    def self.play_file(filename, &on_stop)
      instance.set_file filename
      @stop_callback = on_stop
      instance.play
    end

    def self.playing?
      instance.playing?
    end

    def self.stop
      instance.stop
    end

    def self.get_volume
      {"min" => 0, "max" => 100, "current" => instance.volume}
    end

    def self.set_volume(value)
      instance.volume = value
    end

    def self.instance
      p "create new instance" if @instance.nil?
      @instance ||= new
    end

    def prepare
      return if prepared?
      
      @pipeline = Gst::Pipeline.new

      @filesrc = Gst::ElementFactory.make("filesrc")
      
      @decoder = Gst::ElementFactory.make("mad")

      @volume_control = Gst::ElementFactory.make("volume")
      @volume_control.volume = 0.5

      @audiosink = Gst::ElementFactory.make("autoaudiosink")

      @pipeline.add(@filesrc, @decoder, @volume_control, @audiosink)
      @filesrc >> @decoder >> @volume_control >> @audiosink

      @loop = GLib::MainLoop.new(nil, false)

      bus = @pipeline.bus
      unless @watcher_added
        bus.add_watch do |bus, message|
          case message.type
          when Gst::Message::EOS
            p "get eos"
            @loop.quit
            do_stop
          when Gst::Message::ERROR
            p message.parse
            @loop.quit
            do_stop
          when Gst::Message::STATE_CHANGED
            p "state changed: #{message.parse}"
          end
          p "get message #{message}"
          true
        end
      end

      p "run thread"
      @play_thread = Thread.new do
        loop do
          p "start loop"
          begin
            @loop.run
            p "loop end"
          rescue Exception => ex
            p "get exception #{ex}"
          ensure
            @pipeline.stop
            p "stop playing #{@filesrc.location}"
          end
          p "exit loop"
        end
      end
      p "from #{Thread.current} created #{@play_thread}"

      @prepared = true;
    end

    def prepared?
      not @prepared.nil?
    end

    def set_file(filename)
      prepare unless prepared?
      @filesrc.location = filename
    end

    def play
      prepare unless prepared?
      p "start playing #{@filesrc.location}"
      @pipeline.play
    end

    def playing?
      prepare unless prepared?
      @pipeline.get_state.include?(Gst::State::PLAYING)
    end

    def stop
      prepare unless prepared?
      @loop.quit
      do_stop
    end

    def do_stop
      @stop_callback.call unless @stop_callback.nil?
      @stop_callback = nil
    end

    def volume
      prepare unless prepared?
      @volume_control.volume
    end

    def volume=(value)
      prepare unless prepared?
      @volume_control.volume = value/100.0
    end
  end

end