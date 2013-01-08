

God.watch do |w|
  rails_root = File.expand_path('../../..', __FILE__)
  w.name = "jukebox_player"
  w.log = "#{File.join(rails_root, 'log', 'player.log')}"
  w.start = "ruby #{File.join(rails_root, 'lib', 'audio', 'player.rb')}"
  w.dir = rails_root
  w.keepalive
end