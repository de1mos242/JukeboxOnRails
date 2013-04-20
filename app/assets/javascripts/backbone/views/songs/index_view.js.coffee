JukeboxOnRails.Views.Songs ||= {}

class JukeboxOnRails.Views.Songs.IndexView extends Backbone.View
  template: JST["backbone/templates/songs/index"]

  events:
    "submit .form-search": "findSongs"
    "input #find_query": "selectSongs"
    "click #clear-btn": "clearSearchField"

  findSongs: (e) =>
    e.preventDefault()
    Backbone.history.navigate("/find/"+$('#find_query').val(), {trigger: true})

  selectSongs: (e) =>
    searchQuery = $('#find_query').val().toLowerCase()
    if searchQuery.length == 0
      @selectedSongs = @options.songs
    else
      @selectedSongs = new JukeboxOnRails.Collections.SongsCollection()
      for idxItem in @songIndex
        if idxItem.idx.search(searchQuery) >= 0
          @selectedSongs.add(idxItem.data)
    @addAll()

  clearSearchField: (e) =>
    $('#find_query').val('')

  initialize: () ->
    @options.songs = new JukeboxOnRails.Collections.SongsCollection() unless @options.songs?
    @options.songs.bind('reset', @addAll)
    @selectedSongs = @options.songs
    @songIndex = []
    @selectedSongs.each((song) ->
      @songIndex.push {idx: song.get('artist').toLowerCase() + " " + song.get('title').toLowerCase(), data: song }
    this)

  addAll: () =>
    @$el.find("#songs_list").empty()
    @selectedSongs.each(@addOne)

  addOne: (song) =>
    view = new JukeboxOnRails.Views.Songs.SongView({model : song})
    @$el.find("#songs_list").append(view.render().el)

  render: =>
    @$el.html(@template())
    @addAll()
    return this
