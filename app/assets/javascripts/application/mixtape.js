$(function(){
  var time = function(s) {
    return ~~(s / 60) + ":" + ("0" + ~~(s % 60)).slice(-2);
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
    $.ajax(document.location.pathname, {
      type: 'patch',
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

  var updateSong = function(id, attrs) {
    if (!id) return;

    return $.ajax(document.location.pathname + '/songs/' + id, {
      type: 'patch',
      data: {
        song: attrs,
      },
    })
    .fail(function(res){
      addFlash('error', res.responseText);
    });
  };

  var loadMixtapeAttributes = function(mixtape) {
    $("#mixtape tr:last td").eq(4).text(time(parseInt(mixtape.duration)));

    if (!mixtape.warning) {
      $("#mixtape-warning").remove();
    } else {
      $warning = $("#mixtape-warning");
      if (!$warning.length) {
        $warning = $("<div>", { id: 'mixtape-warning', class: 'alert alert-danger' }).insertAfter('#mixtape');
      }
      $warning.text(mixtape.warning);
    }
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
      .find('.progress-bar')
      .removeClass('progress-bar-success');

    return $.ajax({
      url: document.location.pathname + '/songs',
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
              $upload.find('.progress-bar').width(percentage + '%');
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
        .find('.progress-bar')
        .addClass('progress-bar-success');
    })
    .done(function(payload){
      var song = payload.song,
          mixtape = payload.mixtape;

      addFlash('info', file.name + ' succeeded');

      $("<tr>")
        .data('song-id', song.id)
        .append(
          $("<td>").append(
            $("<div>", { class: 'handle' }).html("&#9776;")
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
            $("<input>", { type: 'text', placeholder: 'Song Original Album' })
              .val(song.album)
          )
        ).append(
          $("<td>").text(time(song.duration))
        ).append(
          $("<td>").append(
            $("<button>", { class: 'delete btn btn-danger' })
              .text('Delete')
          )
        ).insertBefore('#mixtape tr:last');

      loadMixtapeAttributes(mixtape);
    })
    .fail(function(res){
      addFlash('error', file.name + ' failed: ' + res.responseText);
    });
  };

  $.fn.songs = function(){
    return $(this).find('tr').map(function(){ return $(this).data('song-id'); }).toArray();
  };

  $("#mixtape tbody").sortable({
    items: 'tr:not(:last)',
    handle: '.handle',
    placeholder: 'ui-state-highlight',
    start: function(){
      var originalOrder = $(this).songs();

      $(this).one('sortstop', function(){
        var finalOrder = $(this).songs();

        finalOrder.forEach(function(idSong, index){
          if (originalOrder[index] !== idSong) {
            updateSong(idSong, { track_number: index + 1 });
          }
        });
      });
    },
  });

  $(document).on('change', "table input", function(){
    var row = $(this).closest('tr'),
        id = row.data('song-id'),
        inputs = row.find('input').map(function(){ return $(this).val(); });

    updateSong(id, {
      title: inputs[0],
      artist: inputs[1],
      album: inputs[2],
    });
  });

  $(document).on('click', "table button.delete", function(){
    var row = $(this).closest('tr'),
        id = row.data('song-id');

    if (confirm("Are you sure you want to remove this song from your mixtape?")) {
      $.ajax(document.location.pathname + '/songs/' + id, {
        type: 'delete',
      })
      .done(function(mixtape){
        var base = row.index() + 1;
        row
        .fadeOut(function(){ $(this).remove(); })
        .nextAll().each(function(index, row){
          updateSong($(row).data('song-id'), { track_number: index + base });
        });

        loadMixtapeAttributes(mixtape);
      });
    }
  });

  $(document).on('keyup', "input[type=text]", function(e){
    if (e.keyCode == 13) {
      $(this).change();
    }
  });

  // Comments
  $(document).on('keyup', "#comment_comment", function(e){
    if (e.keyCode == 13 && (e.ctrlKey || e.metaKey)) {
      $(this).closest('form').submit();
    }
  });

  $('.edit-comment').click(function(e){
    e.preventDefault();

    var $this = $(this),
        $body = $this.closest('.comment').find('.body'),
        text = $body.text(),
        $editForm = $('#new_comment').clone(),
        commentId = $this.closest('.comment').data('comment-id');

    var cancel = function(e) {
      e.preventDefault();
      $this.parent().show();
      $body.text(text);
    };

    // Let the other elements know we're taking over edits
    $(document).trigger('editComment');

    // Hide edit/delete controls
    $this.parent().hide();

    // Remove text
    $body.text('');

    // Modify and append form
    $editForm
      .attr('id', 'edit_comment')
      .removeClass()
      .find('p').remove().end()
      .find('input[type=submit]').val('Save Changes').end()
      .find('textarea').text(text).end()
      .append(
        $('<button class="cancel btn">Cancel</button>')
          .on('click', cancel)
      )
      .on('submit', function(e){
        e.preventDefault();
        $.ajax($(this).attr('action') + '/' + commentId, {
          data: new FormData(this),
          type: 'patch',
          cache: false,
          contentType: false,
          processData: false,
        })
        .always(function(){
          document.location.reload(true);
        });
      })
      .appendTo($body);

      // Also listen to other edit openings
      $(document).bind('editComment', cancel);
  });

  $('.delete-comment').click(function(e){
    e.preventDefault();
    if (confirm("Are you sure you want to delete this comment?")) {
      var url = $('#new_comment').attr('action') + '/' + $(this).closest('.comment').data('comment-id');

      $.ajax(url, {
        type: 'delete'
      })
      .always(function(){
        document.location.reload(true);
      });
    }
  });

  // Load in link
  var highlightComment = function(id){
    $("a[name=" + id +"]")
      .closest('.comment')
      .addClass('highlighted')
      .siblings()
      .removeClass('highlighted');
  };
  if (document.location.hash) {
    highlightComment(document.location.hash.slice(1));
  }
  $("a.anchor").click(function(e){
    highlightComment($(this).attr('name'));
  });

  // Likes
  $('.like').click(function(e){
    var $this = $(this),
        like = $this.is('.btn-success'),
        songId = $this.data('song-id'),
        url = document.location.pathname + '/songs/' + songId + '/like';

    $.ajax(url, {
      type: 'put',
      data: {
        value: !like || undefined,
      },
    }).success(function(){
      $this.toggleClass('btn-success');
    });
  });

  // Quickplay
  var player = new Audio();
  $('.play').click(function(e){
    var songId = $(this).data('song-id'),
        url = document.location.pathname + '/songs/' + songId + '/listen';

    if (!player.paused) {
      player.pause();

      // If we press the same play button twice, just stop
      if (player.src.indexOf(url) >= 0)
        return;
    }

    player.src = url;
    player.play();
  });

  // Unread
  $('.unread').closest('td').on('click', 'a', function(){
    if (history) {
      var row = $(this).closest('tr'),
          index = row.index(),
          last = row.find('.unread').attr('href'),
          state = history.state || {};

      state[index] = last;
      history.replaceState(state, 'visited', '');
    }
  });

  var handleState = function(){
    if (history && history.state) {
      for (var index in history.state) {
        var unread = $('#mixes tbody tr:eq('+index+') .unread');
        if (unread.attr('href') == history.state[index]) {
          unread.hide();
        }
      }
    }
  };

  // Firefox does not fire popstate when you load a page, so we call it
  // immediately too.
  handleState();
  $(window).on('popstate', handleState);

  // Guesses
  $('select.guess').change(function(e){
    $.ajax('/guesses', {
      method: 'patch',
      data: {
        guess: {
          mixtape_id: $(this).data('mixtape'),
          user_guessed_id: $(this).val(),
        }
      }
    });
  });

  // Votes
  $('select.vote').change(function(e){
    $.ajax('/votes', {
      method: 'patch',
      data: {
        vote: {
          award_id: $(this).data('award'),
          mixtape_id: $(this).val(),
        }
      }
    });
  });
});
