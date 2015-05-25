require 'digest/md5'

class Gravatar
  def initialize(email)
    @email = email
  end

  def url(s=60)
    "https://secure.gravatar.com/avatar/#{ hash }?s=#{ s }&d=retro"
  end

  def hash
    Digest::MD5.hexdigest(@email)
  end
end

