JukeboxOnRails.Views.Songs ||= {}

class JukeboxOnRails.Views.Songs.ShowView extends Backbone.View
  template: JST["backbone/templates/songs/show"]

  render: ->
    $(@el).html(@template(@model.toJSON() ))
    return this
