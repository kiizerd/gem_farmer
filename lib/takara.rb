module Takara
  def outputs; $outputs     end
  def easing;  $args.easing end
  def inputs;  $inputs      end
  def state;   $state       end
  def grid;    $grid        end
  def gtk;     $gtk         end
  def geo;     $geometry    end

  def gtk_easing; $args.easing end
  def gtk_string; $args.string end

  def render_target target_symbol
    $args.render_target(target_symbol)
  end

  def fade_color color, fade_amount=0.85, fade_alpha=false
    raise "BadColor" if !color.is_a?(Array)
    raise "BadFade"  if !fade_amount.is_a?(Numeric)

    if fade_alpha.is_a?(Numeric)
      color[0..2].map { |c| c * fade_amount }
                 .push(color[3] * fade_alpha)
    else
      color[0..2].map { |c| c * fade_amount }.push(color[3])
    end
  end
end