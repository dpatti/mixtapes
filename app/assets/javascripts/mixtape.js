$(function(){
  var addFlash = function(type, txt, time) {
    if (time == undefined)
      time = 4000;

    var $alert = $('<div>')
                  .addClass('alert alert-' + type)
                  .text(txt)
                  .hide()
                  .appendTo('#alerts')
                  .fadeIn();

    setTimeout(function(){
      $alert.fadeOut();
    }, time);
  };

  $("#name").change(function(){
    $.ajax(document.location.href, {
      type: 'put',
      data: { mixtape: { name: $(this).val() }},
    });
  });

  var uploadQueue = [];
  var processQueue = function(){
    var next = uploadQueue[0];
    if (!next) return;

    uploadSong(next)
    .always(function(){
      uploadQueue.shift();
      processQueue();
    });
  };

  $(document).bind("drop", function(e) {
    e.preventDefault();
    if (e.originalEvent && e.originalEvent.dataTransfer && e.originalEvent.dataTransfer.files) {
      var files = e.originalEvent.dataTransfer.files;
      // Execute these in a queue
      [].push.apply(uploadQueue, files);
    }

    if (uploadQueue.length == files.length) {
      processQueue();
    }
  }).bind("dragover", function(e) {
    // If we don't do this, Firefox will load the dropped object
    e.preventDefault();
  });

  var uploadSong = function (file) {
    var data = new FormData();
    data.append('song_file', file);

    var $upload = $('#current-upload');
    $upload.find('p').hide().after(
      $('<p>').text('Uploading ' + file.name + '...')
    );

    $upload.find('.progress').addClass('active');

    return $.ajax({
      url: document.location.href + '/songs',
      type: 'POST',
      data: data,
      cache: false,
      processData: false,
      contentType: false,
      timeout: 30000,
      xhr: function() {
        // Use a custom XHR for progress
        var xhr = new XMLHttpRequest(),
        upload = xhr.upload;

        if (upload) {
          upload.addEventListener('progress', function (e) {
            if (e.lengthComputable) {
              // Check if progress has changed
              var percentage = Math.round(100 * e.loaded / e.total);
              $upload.find('.bar').width(percentage + '%');
            }
          });
        }
        return xhr;
      }
    })
    .always(function(){
      $upload.find('p').show().filter(':last').remove();
      $upload.find('.progress').removeClass('active');
    })
    .done(function(song){
      addFlash('info', file.name + ' succeeded');

      $("<tr>")
        .data('song-id', song.id)
        .append(
          $("<td>").append(
            $("<input>", { type: 'text', class: 'input-mini' })
              .val(song.track_number)
          )
        ).append(
          $("<td>").append(
            $("<input>", { type: 'text', placeholder: 'Song Title' })
              .val(song.title)
          )
        ).append(
          $("<td>").append(
            $("<input>", { type: 'text', placeholder: 'Song Artist' })
              .val(song.artist)
          )
        ).append(
          $("<td>").append(
            $("<button>", { class: 'delete' })
              .text('Delete')
          )
        ).appendTo('#mixtape tbody');
    })
    .fail(function(res, err, body){
      addFlash('error', file.name + ' failed: ' + res.responseText);
    });
  };

  $(document).on('change', "table input", function(){
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

  $(document).on('click', "table button.delete", function(){
    var row = $(this).closest('tr'),
        id = row.data('song-id');

    if (confirm("Are you sure you want to remove this song from your mixtape?")) {
      $.ajax(document.location.href + '/songs/' + id, {
        type: 'delete',
      })
      .done(function(){
        row.fadeOut(function(){ $(this).remove(); });
      });
    }
  });
});
