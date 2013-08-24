class JukeboxOnRails.Models.LongpollData extends Backbone.Model
  url: long_poll_server_url

  refresh: (options = {}) ->
    options.type = "POST"
    #options.processData = true
    options.data = $.param(
      last_update: @attributes.last_update
      room: @attributes.room
      )
    @fetch(options)

  defaults:
    position: null
    auto: null
    song: null
    room: 1
    last_update: "100/100"

  get_control_panel_model: () ->
    model = new JukeboxOnRails.Models.ControlPanel()
    model.current_song = new JukeboxOnRails.Models.Song(@attributes.current_song)
    model