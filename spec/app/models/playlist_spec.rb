require "rspec"
require "spec_helper"
require "playlist"

describe Playlist do
  let(:song) { Song.create(title: "ts", artist: "art", filename: "/fake.mp3", duration: "10", url: "http://vk.com/fake.mp3") }
  before(:each) do
    Playlist.stub(:push_to_longpoll)
  end

  it "should playsong" do
      AudioPlayback::GStreamPlayback.should_receive(:play_song).once
      Playlist.add_song(song)
      PlaylistItem.all.length.should be == 1
  end
end