module Takara
  module UI
    UI_BG_COLOR = [62, 54, 48, 195]
    TOOLBAR_BG_COLOR     = ROSY_BROWN
    TOOLBAR_BTN_BG_COLOR = PASTEL_GREEN

    def round_rect rect, count, sides=Takara::Rect.sides
      small_rect = count.times.reduce(rect) do |rect, x|
        smaller_rect(rect)
      end

      roundings = count.times.map do |x|
        rounding(small_rect, x, sides)
      end

      [ small_rect, roundings, ]
    end

    def smaller_rect rect
      rect.merge({
        x: rect.x + 1, y: rect.y + 1, w: rect.w - 2, h: rect.h - 2
      })
    end

    def rounding rect, number, sides
      rect_sides = Takara::Rect.sides_of_rect(rect).select do |k, v|
        sides.include? k
      end

      rect_sides.map do |side, side_rect|
        case side
        when :left   then left_rounding(rect, number)
        when :right  then right_rounding(rect, number)
        when :top    then top_rounding(rect, number)
        when :bottom then bottom_rounding(rect, number)
        end.merge primitive_marker: :solid#, rgba: BLACK
      end
    end

    def left_rounding rect, offset
      rect.merge({
        x: rect.x - offset - 1,
        y: rect.y + (1*offset) + (0.5*offset) + (0.25*offset),
        w: 1,
        h: rect.h - (2*offset) - offset - (offset/2)
      })
    end
    
    def right_rounding rect, offset
      rect.merge({
        x: rect.x + rect.w + offset,
        y: rect.y + (1*offset) + (0.5*offset) + (0.25*offset),
        w: 1,
        h: rect.h - (2*offset) - offset - (offset/2)
      })
    end

    def top_rounding rect, offset
      rect.merge({
        x: rect.x + (1*offset) + (0.5*offset) + (0.25*offset),
        y: rect.y + rect.h + offset,
        w: rect.w - (2*offset) - offset - (offset/2),
        h: 1
      })
    end

    def bottom_rounding rect, offset
      rect.merge({
        x: rect.x + (1*offset) + (0.5*offset) + (0.25*offset),
        y: rect.y - offset - 1,
        w: rect.w - (2*offset) - offset - (offset/2),
        h: 1
      })
    end

    def rect_border rect
      rect.merge({
        primitive_marker: :border,
        rgba: DARK_SLATE_GRAY
      })
    end

    def rect_shadow rect, offset=[0, 3]
      [
        tall_shadow(rect, offset),
        wide_shadow(rect, offset)
      ]
    end

    def tall_shadow rect, offset
      rect.merge({
        x: rect.x + rect.w, y: rect.y - offset[1],
        w: offset[0], h: rect.h + offset[1],
        rgba: fade_color(rect.rgba, 0.35, 0.5)
      })
    end

    def wide_shadow rect, offset
      rect.merge({
        x: rect.x, y: rect.y - offset[1],
        w: rect.w + offset[0], h: offset[1],
        rgba: fade_color(rect.rgba, 0.35, 0.5)
      })
    end
  end
end