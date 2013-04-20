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
    @selectedSongs = new JukeboxOnRails.Collections.SongsCollection()
    @options.songs.each( (song) ->
      if song.get('artist').toLowerCase().search(searchQuery) >= 0 || song.get('title').toLowerCase().search(searchQuery) >= 0
        @selectedSongs.add(song)
    this)
    @addAll()

  clearSearchField: (e) =>
    $('#find_query').val('')

  initialize: () ->
    @options.songs = new JukeboxOnRails.Collections.SongsCollection() unless @options.songs?
    @options.songs.bind('reset', @addAll)
    @selectedSongs = @options.songs

  addAll: () =>
    @$("#songs_list").empty()
    @memoryElement = $('<div />', {id: 'songs_data'})
    @selectedSongs.each(@addOne)
    @$("#songs_list").append(@memoryElement)

  addOne: (song) =>
    view = new JukeboxOnRails.Views.Songs.SongView({model : song})
    @memoryElement.append(view.render().el)

  render: =>
    $(@el).html(@template())

    return this
