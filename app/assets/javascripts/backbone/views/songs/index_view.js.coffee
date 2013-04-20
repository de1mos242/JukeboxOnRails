JukeboxOnRails.Views.Songs ||= {}

class JukeboxOnRails.Views.Songs.IndexView extends Backbone.View
  template: JST["backbone/templates/songs/index"]

  events:
    "submit .form-search": "findSongs"
    "input #find_query": "selectSongs"

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

  initialize: () ->
    @options.songs.bind('reset', @addAll)
    @selectedSongs = @options.songs

  addAll: () =>
    @$("#songs_list").empty()
    @selectedSongs.each(@addOne)

  addOne: (song) =>
    view = new JukeboxOnRails.Views.Songs.SongView({model : song})
    @$("#songs_list").append(view.render().el)

  render: =>
    $(@el).html(@template(songs: @selectedSongs.toJSON() ))
    @addAll()

    return this
