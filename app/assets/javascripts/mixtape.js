$(function(){
  var refresh = function() {
    // document.location.href = document.location.href;
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
      $.when([].map.call(e.originalEvent.dataTransfer.files, uploadSong))
      .always(refresh);
    }
  }).bind("dragover", function(e) {
    // If we don't do this, Firefox will load the dropped object
    e.preventDefault();
  });

  var uploadSong = function (file) {
    var data = new FormData();
    data.append('song_file', file);

    return $.ajax({
      url: document.location.href + '/songs',
      type: 'POST',
      data: data,
      cache: false,
      processData: false,
      contentType: false,
      timeout: 30000,
    });
  };
});
