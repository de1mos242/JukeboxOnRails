JukeboxOnRails.Views.PlaylistItems ||= {}

class JukeboxOnRails.Views.PlaylistItems.PlaylistItemView extends Backbone.View
  template: JST["backbone/templates/playlist_items/playlist_item"]

  events:
    "click .destroy" : "destroy"
    
  tagName: "li"
  className: "song"

  destroy: () ->
    @model.destroy()
    this.remove()

    return false

  render: ->
    @$el.html(@template(@model))
    return this
