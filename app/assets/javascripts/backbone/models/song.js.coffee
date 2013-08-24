class JukeboxOnRails.Models.Song extends Backbone.Model
  paramRoot: 'song'

  defaults:
    artist: null
    title: null
    url: null
    duration: null
    added_to_playlist: false
    room: 1

  same_song: (another_song) ->
    (@attributes.artist == another_song.attributes.artist and 
      @attributes.title == another_song.attributes.title and
      @attributes.duration == another_song.attributes.duration)

class JukeboxOnRails.Collections.SongsCollection extends Backbone.Collection
  model: JukeboxOnRails.Models.Song
  url: '/songs/find'
