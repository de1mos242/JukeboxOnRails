class JukeboxOnRails.Models.ControlPanel extends Backbone.Model
  defaults:
    current_song: null
    current_song_timer: 0
    elapsed_time: "00:00"
    on_elapsed_time_changed: null

  start_song_timer: () ->
    @current_song_timer = 0
    self = this
    @intervalHandler = setInterval( () ->
        self.update_elapsed_time()
    1000);

  update_elapsed_time: () ->
    @current_song_timer++
    minutes = parseInt( @current_song_timer / 60 );
    seconds = @current_song_timer % 60;
    string_minutes = if (minutes < 10) then "0" + minutes else minutes
    string_seconds = if (seconds < 10) then "0" + seconds else seconds
    @elapsed_time = string_minutes + ":" + string_seconds
    @on_elapsed_time_changed(this) if @on_elapsed_time_changed

  remove: () ->
    @destroy()
    window.clearInterval(@intervalHandler)