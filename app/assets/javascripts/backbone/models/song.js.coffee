class JukeboxOnRails.Models.Song extends Backbone.Model
  paramRoot: 'song'

  defaults:
    artist: null
    title: null
    url: null
    duration: null
    added_to_playlist: false

class JukeboxOnRails.Collections.SongsCollection extends Backbone.Collection
  model: JukeboxOnRails.Models.Song
  url: '/songs/find'
