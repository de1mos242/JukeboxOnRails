require 'gst'

module AudioPlayback
  
  class GStreamPlayback

    # song = {filename, artist, title}
    def self.play_song(song, &on_stop)
      instance.set_song song
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

    def self.get_current_volume
      {"min" => 30, "max" => 100, "current" => (instance.volume * 100).round}
    end

    def self.set_volume(value)
      instance.volume = value
    end

    def self.get_position
      instance.current_position
    end

    def self.get_shoutcast_url
      instance.shoutcast_url
    end

    def self.instance
      p "create new instance" if @instance.nil?
      @instance ||= new
    end

    def prepare
      return if prepared?
      p "prepare started"

      shoutcast_config = Rails.application.config.shoutcast_config
      speakers_config = Rails.application.config.speakers_config

      @playing = false

      @pipeline = Gst::Pipeline.new

      @fakesrc = Gst::ElementFactory.make("audiotestsrc")
      @fakesrc.wave = 4 #silence
      @fake_queue = Gst::ElementFactory.make("queue")
      @muter = Gst::ElementFactory.make("volume")
      @muter.volume = 0

      @filesrc = Gst::ElementFactory.make("filesrc")
      @filesrc.location = Rails.root.join("public","empty.mp3").to_s
      @decoder = Gst::ElementFactory.make("mad")

      @adder = Gst::ElementFactory.make("adder")

      @volume_control = Gst::ElementFactory.make("volume")
      @volume_control.volume = 0.5

      @tee = Gst::ElementFactory.make("tee")

      if speakers_config[:enabled]
        @audiosink_queue = Gst::ElementFactory.make("queue")

        @audiosink = Gst::ElementFactory.make("autoaudiosink")
      end

      if shoutcast_config[:enabled]
        @shoutcast_queue = Gst::ElementFactory.make("queue")

        @audioconvert = Gst::ElementFactory.make("audioconvert")
        @lame = Gst::ElementFactory.make("lame")
        @lame.bitrate = 192

        @taginject = Gst::ElementFactory.make("taginject")

        # and an audio sink
        @shoutcast = Gst::ElementFactory.make("shout2send")
        @shoutcast.ip = shoutcast_config[:ip]
        @shoutcast.port = shoutcast_config[:port]
        @shoutcast.password = shoutcast_config[:password]
        @shoutcast.mount = shoutcast_config[:mount]
        @shoutcast.sync = shoutcast_config[:sync]
        @shoutcast.max_lateness = shoutcast_config[:max_lateness]

        @shoutcast_url = shoutcast_config[:listen_url]
      end

      @pipeline.add(@filesrc, @decoder)
      #@pipeline.add(@fakesrc, @fake_queue, @muter)
      @pipeline.add(@adder, @volume_control, @tee)
      @pipeline.add(@audiosink_queue, @audiosink) if speakers_config[:enabled]
      @pipeline.add(@shoutcast_queue, @audioconvert, @lame, @taginject, @shoutcast) if shoutcast_config[:enabled]
      #@fakesrc >> @fake_queue >> @muter >> @adder
      @filesrc >> @decoder >> @adder
      @adder >> @volume_control >> @tee
      @tee >> @audiosink_queue >> @audiosink if speakers_config[:enabled]
      @tee >> @shoutcast_queue >> @audioconvert >> @lame >> @taginject >> @shoutcast if shoutcast_config[:enabled]

      @loop = GLib::MainLoop.new(nil, false)

      bus = @pipeline.bus
      bus.add_watch do |bus, message|
        #p "msg #{message.class}" #unless message.class == Gst::MessageTag
        case message.type
          when Gst::Message::EOS
            p "get eos" if @playing
            do_stop
          when Gst::Message::ERROR
            p "exc in watch: #{message.parse}"
            do_stop
          when Gst::Message::STATE_CHANGED
            p "changed state to: #{@pipeline.get_state.to_s}"
          when Gst::Message::STREAM_STATUS
            p "get stream event: #{message.structure["type"].name}"
            do_stop if message.structure["type"].name == "GST_STREAM_STATUS_TYPE_LEAVE"
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
      @prepared = true
      @pipeline.ready
    end

    def prepared?
      not @prepared.nil?
    end

    def set_song(song)
      prepare unless prepared?
      p "set song #{song[:title]}"
      p "create new source #{song[:filename]}"

      @pipeline.pause
      @pipeline.seek_simple(Gst::Format::TIME, Gst::Seek::FLAG_FLUSH, 0)

      unlink_file_source
      @filesrc.location = song[:filename]
      if @pipeline.find_index(@filesrc).nil?
        @pipeline.add(@filesrc, @decoder)
        @decoder.link(@adder)
        @filesrc.link(@decoder)
      end
      @decoder.sync_state_with_parent
      @filesrc.sync_state_with_parent
      @taginject.tags = "title=\"#{song[:title]}\",artist=\"#{song[:artist]}\"" unless @taginject.nil?
    end

    def play
      prepare unless prepared?
      p "start playing"
      p "playing state: #{@pipeline.get_state.to_s}"
      @pipeline.play
      p "playing state: #{@pipeline.get_state.to_s}"

      @playing = true
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
      p "no callback on stop!" if @stop_callback.nil?
      p "stop playing #{@filesrc.location}" if @playing
      p "prev state #@waiting_eof"
      #unless @waiting_eof
        #@pipeline.pause
        #@taginject.tags = "title=\"enjoy the silence\",artist=\"silence\"" unless @taginject.nil?

        unlink_file_source

        #@pipeline.play

        @playing = false

        @stop_callback.call unless @stop_callback.nil?
      #else
      #  @waiting_eof = false
      #end
    end

    def unlink_file_source
      unless @pipeline.find_index(@filesrc).nil?
        p "remove old source #{@filesrc.location}"
        @filesrc.unlink(@decoder)
        @decoder.unlink(@adder)
        @pipeline.remove(@decoder, @filesrc)
        @filesrc.stop
        @decoder.stop
        @waiting_eof = true
      end
    end

    def volume
      prepare unless prepared?
      @volume_control.volume
    end

    def volume=(value)
      prepare unless prepared?
      @volume_control.volume = [value,self.get_current_volume["min"]].max/100.0
    end

    def current_position
      prepare unless prepared?
      return nil unless playing?

      clk = @pipeline.clock.time
      pos = clk/1000000000.0
      Time.at(pos).gmtime.strftime('%M:%S')
    end

    def shoutcast_url
      prepare unless prepared?
      return @shoutcast_url unless @shoutcast_url.blank?
      nil
    end

  end

end