JukeboxOnRails.Views.ControlPanel ||= {}

class JukeboxOnRails.Views.ControlPanel.ControlPanelView extends Backbone.View
  template: JST["backbone/templates/control_panel/control_panel"]

  destroy: () ->
    @model.destroy()
    this.remove()

    return false

  initialize: () ->
    @on_new_model()

  render: ->
    @$el.html(@template(@model))
    return this

  update_model: (model) ->
    unless (@model.current_song.same_song(model.current_song))
      @model.remove()
      @model = model
      @on_new_model()
      @render()

  on_new_model: () ->
    @model.on_elapsed_time_changed = (model) ->
      $("#current_song_elapsed_time").html(model.elapsed_time)
    @model.start_song_timer()
