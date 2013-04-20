JukeboxOnRails.Views.Songs ||= {}

class JukeboxOnRails.Views.Songs.SongView extends Backbone.View
  template: JST["backbone/templates/songs/song"]

  events:
    "click .destroy" : "destroy"
    submit: "onClickAddToPlaylist"

  tagName: "li"

  destroy: () ->
    @model.destroy()
    this.remove()

    return false

  onClickAddToPlaylist: (e) ->
    $(e.target).find('.add_to_playlist').hide('fast');

  render: ->
    this.$el.html(@template(@model.toJSON() ))
    return this
