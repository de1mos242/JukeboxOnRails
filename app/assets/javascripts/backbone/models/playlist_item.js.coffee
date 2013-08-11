class JukeboxOnRails.Models.PlaylistItem extends Backbone.Model
  paramRoot: 'playlist_item'

  defaults:
    position: null
    auto: null
    song: null

class JukeboxOnRails.Collections.PlaylistItemsCollection extends Backbone.Collection
  model: JukeboxOnRails.Models.PlaylistItem
  url: '/playlist_items'
