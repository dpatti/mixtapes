require 'redcarpet'

module CommentHelper
  class SelectiveRenderer < Redcarpet::Render::HTML
    def header(text, level)
      "#{"#" * level}#{text}"
    end
  end

  def renderer
    SelectiveRenderer.new(
      escape_html: true,
      hard_wrap: true,
      link_attributes: { target: '_blank' }
    )
  end

  def markdown(text)
    @markdown ||= Redcarpet::Markdown.new(renderer, {
      autolink: true,
      tables: true
    })

    @markdown.render(text).html_safe
  end
end
