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
    @view = new JukeboxOnRails.Views.Songs.IndexView(songs: @songs)
    $("#songs").html(@view.render().el)

  find: (query = '')->
    query = decodeURIComponent(query)
    @songs.fetch({data: {find_query: query}})
    @view = new JukeboxOnRails.Views.Songs.IndexView(songs: @songs)
    $("#songs").html(@view.render().el)
    $("#find_query").val(query)

  show: (id) ->
    song = @songs.get(id)

    @view = new JukeboxOnRails.Views.Songs.ShowView(model: song)
    $("#songs").html(@view.render().el)

  edit: (id) ->
    song = @songs.get(id)

    @view = new JukeboxOnRails.Views.Songs.EditView(model: song)
    $("#songs").html(@view.render().el)
