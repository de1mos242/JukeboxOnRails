class JukeboxOnRails.Routers.ControlPanelRouter extends Backbone.Router
  initialize: (options) ->
    @songs = new JukeboxOnRails.Collections.SongsCollection()
    @songs.reset options.songs

  routes:
    "new"      : "newSong"
    "index"    : "index"
    ":id/edit" : "edit"
    ":id"      : "show"
    "find/:query" : "find"
    "find/" : "find"
    ".*"        : "index"

  newSong: ->
    @view = new JukeboxOnRails.Views.Songs.NewView(collection: @songs)
    $("#songs").html(@view.render().el)

  index: ->
    @view.dispose() if @view
    @view = new JukeboxOnRails.Views.Songs.IndexView(songs: @songs)
    $("#songs").html(@view.render().el)

  find: (query = '')->
    @last_query = decodeURIComponent(query)
    @view.dispose() if @view
    @view = new JukeboxOnRails.Views.Songs.IndexView()
    $("#songs").html(@view.render().el)
    $("#find_query").val(@last_query)
    $('#find_song_button').attr('disabled', 'disabled')
    $('#find_song_button').attr('value', 'Searching...')
    self = this
    @songs.fetch({data: {find_query: query}, success: () ->
        self.on_fetch_songs()
      }
    )

  on_fetch_songs: () ->
    @view.dispose() if @view
    @view = new JukeboxOnRails.Views.Songs.IndexView(songs: @songs)
    $("#songs").html(@view.render().el)
    $("#find_query").val(@last_query)

  show: (id) ->
    song = @songs.get(id)

    @view = new JukeboxOnRails.Views.Songs.ShowView(model: song)
    $("#songs").html(@view.render().el)

  edit: (id) ->
    song = @songs.get(id)

    @view = new JukeboxOnRails.Views.Songs.EditView(model: song)
    $("#songs").html(@view.render().el)
