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

  escapeRegExp: (str) =>
    str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")

  selectSongs: (e) =>
    searchQuery = @escapeRegExp($('#find_query').val().toLowerCase())
    if searchQuery.length == 0
      @selectedSongs = @options.songs
    else
      @selectedSongs = new JukeboxOnRails.Collections.SongsCollection()
      for idxItem in @songIndex
        if idxItem.idx.search(searchQuery) >= 0
          @selectedSongs.add(idxItem.data)
    @addFirstPage()

  clearSearchField: (e) =>
    $('#find_query').val('')
    @selectSongs()

  initialize: () ->
    self = this
    $(window).scroll( () ->
      if($(document).height() - $(window).height() <= $(window).scrollTop() + 50)
        self.nextPage()
    )

    @options.songs = new JukeboxOnRails.Collections.SongsCollection() unless @options.songs?
    @options.songs.bind('reset', @addFirstPage)
    @selectedSongs = @options.songs
    @songIndex = []
    @selectedSongs.each((song) ->
      @songIndex.push {idx: song.get('artist').toLowerCase() + " " + song.get('title').toLowerCase(), data: song }
    this)

  dispose: () ->
    $(window).unbind('scroll')

  perPage: 20

  currentPage: 0

  selectedSongs: null

  addFirstPage: =>
    @$el.find("#songs_list").empty()
    @addPage(1)
    @currentPage = 1

  nextPage: () =>
    if @selectedSongs.length > @currentPage * @perPage
      @addPage(@currentPage)
      @currentPage = @currentPage + 1

  addPage: (page) =>
    fromIdx = (page - 1) * @perPage
    appendElements = $()
    for songModel, idx in @selectedSongs.models
      if fromIdx <= idx < fromIdx + @perPage
        appendElements = appendElements.add(@getSongElement(songModel))
    @$el.find("#songs_list").append(appendElements)

  addAll: () =>
    @$el.find("#songs_list").empty()
    appendElements = $()
    @selectedSongs.each( (song) =>
      appendElements = appendElements.add(@getSongElement(song))
    this)
    @$el.append(appendElements)

  addOne: (song) =>
    @$el.find("#songs_list").append(@getSongElement(song))

  getSongElement: (song) =>
    view = new JukeboxOnRails.Views.Songs.SongView({model : song})
    view.render().el

  render: =>
    @$el.html(@template())
    @addFirstPage()
    return this
