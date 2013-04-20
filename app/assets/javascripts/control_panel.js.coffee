# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

current_song = null;
current_song_timer = 0;
prevous_song = null;
last_update = null;

refreshPage = (request_data) ->
  return null unless (long_poll_server_url?)
  request = $.ajax({
    #url: 'http://localhost/',
    #type: 'POST'
    #dataType: 'application/x-www-form-urlencoded'
    url: long_poll_server_url,
    async: true,
    timeout: 180000, # 3 minutes
    type: 'POST', # Using POST because it makes the polling app a little harder to abuse
    dataType: 'json',
    data: request_data
  })
  request.done(onRefreshResponse);
  request.error(onRefreshResponseFailure);
  
onRefreshResponse = (response) ->
  if (typeof response != "undefined" && response != null && response.hasOwnProperty('current_song'))
    $('#playlist_items_container').empty();
    if (response.playlist_items != null && response.playlist_items.length > 0)
      $('#playlistItemTemplate').tmpl(response.playlist_items).appendTo('#playlist_items_container')
    current_song = response.current_song;
    refreshCurrentSong();
    last_update = response.last_update
  refreshPage({"last_update" : last_update});

onRefreshResponseFailure = () ->
  setTimeout(refreshPage(null), 2000);

refreshCurrentSong = () ->
  if (current_song != null)
    if (prevous_song == null || prevous_song.artist != current_song.artist || prevous_song.title != current_song.title)
      current_song_timer = 0;
    minutes = parseInt( current_song_timer / 60 );
    seconds = current_song_timer % 60;
    string_minutes = if (minutes < 10) then "0" + minutes else minutes
    string_seconds = if (seconds < 10) then "0" + seconds else seconds
    duration = string_minutes + ":" + string_seconds
    sond_duration_string = if (current_song.duration != null) then current_song.duration else "&infin;"
    $("#current_song").html(current_song.artist + " - " + current_song.title + " " + duration + "/" + sond_duration_string);
    current_song_timer += 1;
  else
    $("#current_song").empty();
  prevous_song = current_song
  
onFindSongs = (response) ->
  $('#songs_container').empty();
  $('#songTemplate').tmpl(response).appendTo('#songs_container');
  addToPlaylistBlocker();

setInterval(refreshCurrentSong, 1000);

addToPlaylistBlocker = () ->
  $(".add_to_playlist").click(
    () -> 
      $(this).hide("fast"));

$(() ->
  $("#refresh-btn").click(refreshPage);
  #$("#clear-btn").click(() ->
  #    $("#find_query").val('');
  #  );

  #addToPlaylistBlocker();

  #$("#find_form").bind("ajax:success", (xhr, data, status) ->
  #      onFindSongs(data);
  #  );

  refreshPage(null);
);