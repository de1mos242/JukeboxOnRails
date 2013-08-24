JukeboxOnRails.Views.PlaylistItems ||= {}

class JukeboxOnRails.Views.PlaylistItems.IndexView extends Backbone.View
  template: JST["backbone/templates/playlist_items/index"]

  tagName: "ul"
  className: "songs_list"
  id: "playlist_items"
    
  dispose: () ->

  initialize: () ->
    @options.playlist_items = new JukeboxOnRails.Collections.PlaylistItemsCollection() unless @options.playlist_items?
    @playlist_items = @options.playlist_items

  addAll: () =>
    @$el.find("#playlist_items").empty()
    appendElements = $()
    for playlist_item in @playlist_items
      appendElements = appendElements.add(@getPlaylistItemElement(playlist_item))
    @$el.append(appendElements)

  addOne: (playlist_item) =>
    @$el.find("#playlist_items").append(@getPlaylistItemElement(playlist_item))

  getPlaylistItemElement: (playlist_item) =>
    view = new JukeboxOnRails.Views.PlaylistItems.PlaylistItemView({model : playlist_item})
    view.render().el

  render: =>
    @$el.html(@template())
    @addAll()
    return this
