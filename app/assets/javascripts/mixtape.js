$(function(){
  var refresh = function() {
    document.location.href = document.location.href;
  };

  var addStatus = function(txt) {
    $('<p>').text(txt).appendTo('#status')
  };

  $("#name").change(function(){
    $.ajax(document.location.href, {
      type: 'put',
      data: { mixtape: { name: $(this).val() }},
    });
  });

  $(document).bind("drop", function(e) {
    e.preventDefault();
    if (e.originalEvent && e.originalEvent.dataTransfer && e.originalEvent.dataTransfer.files) {
      $.when.apply($, [].map.call(e.originalEvent.dataTransfer.files, uploadSong))
      .always(refresh);
    }
  }).bind("dragover", function(e) {
    // If we don't do this, Firefox will load the dropped object
    e.preventDefault();
  });

  var uploadSong = function (file) {
    var data = new FormData();
    data.append('song_file', file);

    addStatus('Uploading ' + file.name);

    return $.ajax({
      url: document.location.href + '/songs',
      type: 'POST',
      data: data,
      cache: false,
      processData: false,
      contentType: false,
      timeout: 30000,
    })
    .done(function(){
      addStatus(file.name + ' succeeded');
    })
    .fail(function(res, err, body){
      addStatus(file.name + ' failed: ' + body);
    });
  };

  $("table input").change(function(){
    var row = $(this).closest('tr'),
        id = row.data('song-id'),
        inputs = row.find('input').map(function(){ return $(this).val(); });

    $.ajax(document.location.href + '/songs/' + id, {
      type: 'put',
      data: {
        song: {
          track_number: inputs[0],
          title: inputs[1],
          artist: inputs[2],
        },
      },
    });
  });

  $("table button.delete").click(function(){
    var row = $(this).closest('tr'),
        id = row.data('song-id');

    if (confirm("Are you sure you want to remove this song from your mixtape?")) {
      $.ajax(document.location.href + '/songs/' + id, {
        type: 'delete',
      })
      .done(function(){
        row.remove();
      });
    }
  });
});
