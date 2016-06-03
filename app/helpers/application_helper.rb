module ApplicationHelper
  def navbar_link_to(text, path, options={})
    if current_page?(path)
      options[:class] = [options[:class], 'active'].compact.join(' ')
    end

    content_tag 'li', options do
      link_to text, path
    end
  end

  def seconds_to_time seconds
    "%d:%02d" % [seconds / 60, seconds % 60]
  end

  def anonymize(name)
    if contest_ended
      name
    else
      "anonymous"
    end
  end
end
