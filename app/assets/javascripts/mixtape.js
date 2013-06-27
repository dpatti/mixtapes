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

    $upload.find('.progress')
      .addClass('active progress-striped')
      .find('.bar')
      .removeClass('bar-success');

    return $.ajax({
      url: document.location.href + '/songs',
      type: 'POST',
      data: data,
      cache: false,
      processData: false,
      contentType: false,
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
      $upload.find('.progress')
        .removeClass('active progress-striped')
        .find('.bar')
        .addClass('bar-success');
    })
    .done(function(song){
      addFlash('info', file.name + ' succeeded');

      $("<tr>")
        .data('song-id', song.id)
        .append(
          $("<div>", { class: 'handle' })
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
            $("<input>", { type: 'text', placeholder: 'Song Original Album' })
              .val(song.album)
          )
        ).append(
          $("<td>").append(
            $("<button>", { class: 'delete btn btn-danger' })
              .text('Delete')
          )
        ).appendTo('#mixtape tbody');
    })
    .fail(function(res){
      addFlash('error', file.name + ' failed: ' + res.responseText);
    });
  };

  $.fn.songs = function(){
    return $(this).find('tr').map(function(){ return $(this).data('song-id'); }).toArray();
  };

  $("#mixtape tbody").sortable({
    handle: 'td:first',
    placeholder: 'ui-state-highlight',
    start: function(){
      var originalOrder = $(this).songs();

      $(this).one('sortstop', function(){
        var finalOrder = $(this).songs();

        finalOrder.forEach(function(idSong, index){
          if (originalOrder[index] !== idSong) {
            $.ajax(document.location.href + '/songs/' + idSong, {
              type: 'put',
              data: {
                song: {
                  track_number: index + 1,
                },
              },
            })
            .fail(function(res){
              addFlash('error', res.responseText);
            });
          }
        });
      });
    },
  }).disableSelection();

  $(document).on('change', "table input", function(){
    var row = $(this).closest('tr'),
        id = row.data('song-id'),
        inputs = row.find('input').map(function(){ return $(this).val(); });

    $.ajax(document.location.href + '/songs/' + id, {
      type: 'put',
      data: {
        song: {
          title: inputs[0],
          artist: inputs[1],
          album: inputs[2],
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

  $(document).on('keyup', "input[type=text]", function(e){
    if (e.keyCode == 13) {
      $(this).change();
    }
  });
});
