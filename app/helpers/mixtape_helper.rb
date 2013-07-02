module MixtapeHelper
  def song_like_button(song, opts={})
    liked = current_user.likes?(song)
    classes = ['btn btn-like']
    classes << 'like' unless opts[:dummy]
    classes << 'btn-success' if liked

    content_tag 'button', :"data-song-id" => song.id,
                          :class => classes.join(' ') do
      content_tag('label'){ "Stand out song" }
    end
  end
end
