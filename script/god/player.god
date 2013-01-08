RAILS_ROOT = File.expand_path('../../..', __FILE__)

God.watch do |w|
  w.name = "jukebox_player"
  w.log = "#{File.join(RAILS_ROOT, 'log', 'player.log')}"
  w.start = "ruby #{File.join(RAILS_ROOT, 'lib', 'audio', 'player.rb')}"
  w.dir = RAILS_ROOT
  w.keepalive
end