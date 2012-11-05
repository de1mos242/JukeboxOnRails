require 'gst'

module AudioPlayback
  
  class GStreamPlayback

    def self.play_file(filename, &on_stop)
      instance.set_file filename
      p "run play file"
      instance.set_callback on_stop
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

      @playing = false
      
      @pipeline = Gst::ElementFactory.make("playbin2")
      @bin = Gst::Bin.new()

      @volume_control = Gst::ElementFactory.make("volume")
      @audiosink = Gst::ElementFactory.make("autoaudiosink")

      @bin.add(@volume_control)
      @bin.add(@audiosink)
      @volume_control >> @audiosink

      @bin.add_pad(Gst::GhostPad.new("gpad", @volume_control.get_pad("sink")))
      @pipeline.audio_sink = @bin

      @volume_control.volume = 0.5

      @loop = GLib::MainLoop.new(nil, false)

      bus = @pipeline.bus
      bus.add_watch do |bus, message|
        case message.type
          when Gst::Message::EOS
            p "get eos"
            do_stop
          when Gst::Message::ERROR
            p "exc in watch: #{message.parse}"
            do_stop
          when Gst::Message::STATE_CHANGED
            #p "state changed: #{message.parse}"
        end
        #p "get message #{message}"
        true
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
            #@pipeline.stop
            p "stop playing"
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
      @pipeline.uri= GLib.filename_to_uri(filename)
    end

    def play
      prepare unless prepared?
      p "start playing"
      @playing = true
      @pipeline.play
    end

    def playing?
      prepare unless prepared?
      #p "playing state: #{@pipeline.get_state}.to_s"
      #@pipeline.get_state.include?(Gst::State::PLAYING)
      @playing
    end

    def stop
      prepare unless prepared?
      do_stop
    end

    def set_callback(callback)
      @stop_callback = callback
      p "callback setted #{self} #{@stop_callback} at thread #{Thread.current}"
    end

    def do_stop
      p "do stop it thread #{Thread.current}  #{self}"
      p "no callback on stop!" if @stop_callback.nil?
      @pipeline.stop
      @playing = false
      @stop_callback.call unless @stop_callback.nil?
      #@stop_callback = nil
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