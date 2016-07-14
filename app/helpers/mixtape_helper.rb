module MixtapeHelper
  def song_listen_button(song)
    content_tag 'button', :"data-song-id" => song.id,
                          :class => 'btn play' do
      content_tag('label'){ "Play" }
    end
  end

  def song_like_button(song, opts={})
    liked = current_user.likes?(song)
    classes = ['btn btn-like']
    classes << 'like' unless opts[:dummy]
    classes << 'btn-success' if liked

    content_tag 'button', :"data-song-id" => song.id,
                          :class => classes.join(' ') do
      content_tag('label'){ "Stand-out song" }
    end
  end

  def mixtape_comments(tape, comment='comments')
    "%s#%s" % [mixtape_path(tape), comment]
  end
end
