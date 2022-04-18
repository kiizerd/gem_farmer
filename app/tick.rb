def tick args
  $game      ||= Takara::Game.new
  $game.args ||= args
  $game.tick
  $outputs.background_color = [42, 39, 32, 255]
end