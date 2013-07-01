class String
  def clean
    downcase.strip
  end

  # Largest substring
  def similar_to(other, opts={})
    opts = {
      :length_diff_thresh => 6, # Auto-false if length difference is at least this
      :exact_thresh => 6, # Only compare if strings are under this length
      :similarity_thresh => 70, # Return true if the substring is at least this percentage of the max length
      :pre_clean => false, # Call clean (above) on inputs before running
    }.merge(opts)

    opts[:diff_thresh] ||= 6
    opts[:similarity_thresh] ||= 70
    
    if opts[:pre_clean]
      return clean.similar_to(other.clean, opts.merge(:pre_clean => false))
    end

    if length == 0 or other.length == 0 or (length - other.length).abs >= opts[:diff_thresh]
      return false
    end

    if length < opts[:exact_thresh] && other.length < opts[:exact_thresh]
      return self == other
    end
      
    if self == other
      return true
    end

    # Init
    longest = [Array.new(other.length+1, 0)] +
      Array.new(length){[0]+Array.new(other.length, nil)}

    # Ruby uses C stack size. To prevent this from going too deep, we just have
    # to do it in O(ab)

    (1..length).each do |i|
      (1..other.length).each do |j|
        longest[i][j] = [
          longest[i-1][j],
          longest[i][j-1],
          longest[i-1][j-1] + (self[i] == other[j] ? 1 : 0)
        ].max
      end
    end

    100 * longest[length][other.length] / [length, other.length].max > opts[:similarity_thresh]
  end
end
