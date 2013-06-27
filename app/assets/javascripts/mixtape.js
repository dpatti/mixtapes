$(function(){
  var refresh = function() {
    addFlash('notice', "Refresh to see your tapes because reasons");
  };

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
    .done(function(){
      addFlash('info', file.name + ' succeeded');
    })
    .fail(function(res, err, body){
      addFlash('error', file.name + ' failed: ' + res.responseText);
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
