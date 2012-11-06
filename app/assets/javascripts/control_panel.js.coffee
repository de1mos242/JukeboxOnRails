# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

refreshPage = () ->
  request = $.ajax({
    url: '/control_panel/refresh.json',
    dataType: 'json'
  })
  request.done(onRefreshResponse);

onRefreshResponse = (response) ->
  $('#playlist_items_container').empty();
  $('#playlistItemTemplate').tmpl(response.playlist_items).appendTo('#playlist_items_container')
  if (response.current_song != null)
    $("#current_song").html(response.current_song.artist + " - " + response.current_song.title + " " + response.current_position + "/" + response.current_song.duration);
  else
    $("#current_song").empty();
  
onFindSongs = (response) ->
  $('#songs_container').empty();
  $('#songTemplate').tmpl(response).appendTo('#songs_container');
  addToPlaylistBlocker();

setInterval(refreshPage, 1000);

addToPlaylistBlocker = () ->
  $(".add_to_playlist").click(
    () -> 
      $(this).hide("fast"));

$(() ->
  $("#refresh-btn").click(refreshPage);
  $("#clear-btn").click(() ->
      $("#find_query").val('');
    );

  addToPlaylistBlocker();

  $("#find_form").bind("ajax:success", (xhr, data, status) ->
        onFindSongs(data);
    );
);