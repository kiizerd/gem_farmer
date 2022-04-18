class Numeric
  def abs2
    self * self
  end

  def fluctuate freq
    return self unless $args&.state&.tick_count

    self - ($state.tick_count % (60*freq) - (30*freq)).abs
  end
end