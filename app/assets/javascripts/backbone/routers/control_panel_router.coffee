class JukeboxOnRails.Routers.ControlPanelRouter extends Backbone.Router
  initialize: (options) ->
    @songs = new JukeboxOnRails.Collections.SongsCollection()
    @songs.reset options.songs
    @longpoll_data =new JukeboxOnRails.Models.LongpollData()
    @refresh_longpoll()

  refresh_longpoll: () ->
    self = this
    @longpoll_data.refresh({
        success: () ->
            self.on_get_longpoll_data()
            self.refresh_longpoll()
        error: (e) ->
            self.refresh_longpoll()
        }
    )

  routes:
    "new"      : "newSong"
    "index"    : "index"
    ":id/edit" : "edit"
    ":id"      : "show"
    "find/:query" : "find"
    "find/" : "find"
    ".*"        : "index"

  newSong: ->
    @view.songs_view = new JukeboxOnRails.Views.Songs.NewView(collection: @songs)
    $("#songs").html(@view.songs_view.render().el)

  index: ->
    @view ||= {}
    @view.songs_view.dispose() if @view.songs_view
    @view.songs_view = new JukeboxOnRails.Views.Songs.IndexView(songs: @songs)
    $("#songs").html(@view.songs_view.render().el)

  find: (query = '')->
    @view ||= {}
    @last_query = decodeURIComponent(query)
    @view.songs_view.dispose() if @view && @view.songs_view
    @view.songs_view = new JukeboxOnRails.Views.Songs.IndexView()
    $("#songs").html(@view.songs_view.render().el)
    $("#find_query").val(@last_query)
    $('#find_song_button').attr('disabled', 'disabled')
    $('#find_song_button').attr('value', 'Searching...')
    self = this
    @songs.fetch({cache: false, data: {find_query: query}, success: () ->
        self.on_fetch_songs()
    error: (e) ->
      self.on_failure_search(e)
    }
    )

  on_get_longpoll_data: () ->
    @view.playlist_items_view.dispose() if @view.playlist_items_view
    @view.playlist_items_view = new JukeboxOnRails.Views.PlaylistItems.IndexView(playlist_items: @longpoll_data.attributes.playlist_items)
    $("#playlist_items_container").html(@view.playlist_items_view.render().el)

    #@view.control_panel_view.dispose() if @view.control_panel_view
    if @view.control_panel_view
      @view.control_panel_view.update_model(@longpoll_data.get_control_panel_model())
    else
      @view.control_panel_view = new JukeboxOnRails.Views.ControlPanel.ControlPanelView(model: @longpoll_data.get_control_panel_model() )
      $("#control_panel").html(@view.control_panel_view.render().el)
    
  on_fetch_songs: () ->
    @view.songs_view.dispose() if @view && @view.songs_view
    @view.songs_view = new JukeboxOnRails.Views.Songs.IndexView(songs: @songs)
    $("#songs").html(@view.songs_view.render().el)
    $("#find_query").val(@last_query)

  on_failure_search: (e) ->
    $('#find_song_button').removeAttr('disabled')
    $('#find_song_button').attr('value', 'Search')
    $('#error_block').append('<p>Search failed, try to relogin</p>')

  show: (id) ->
    song = @songs.get(id)

    @view.songs_view = new JukeboxOnRails.Views.Songs.ShowView(model: song)
    $("#songs").html(@view.songs_view.render().el)

  edit: (id) ->
    song = @songs.get(id)

    @view.songs_view = new JukeboxOnRails.Views.Songs.EditView(model: song)
    $("#songs").html(@view.songs_view.render().el)
