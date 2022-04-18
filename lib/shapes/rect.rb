module Takara
  module Rect
    def self.sides_of_rect rect
      sides.map { |s| side_of_rect(s, rect) }.to_h
    end

    def self.sides
      %i[top left right bottom]
    end

    def self.side_of_rect side, rect
      side_rect = {}
      if side == :top
        side_rect = top_of_rect(rect)
      elsif side == :left
        side_rect = left_of_rect(rect)
      elsif side == :right
        side_rect = right_of_rect(rect)
      elsif side == :bottom
        side_rect = bottom_of_rect(rect)
      end
      [side, side_rect]
    end

    def self.top_of_rect rect
      {
        x: rect.x - 1, y: rect.y + rect.h - 1,
        w: rect.w + 2, h: 3
      }
    end

    def self.left_of_rect rect
      {
        x: rect.x - 1, y: rect.y - 1,
        w: 3, h: rect.h + 2
      }
    end

    def self.right_of_rect rect
      {
        x: rect.x + rect.w - 1, y: rect.y - 1,
        w: 3, h: rect.h + 2
      }
    end

    def self.bottom_of_rect rect
      {
        x: rect.x - 1, y: rect.y - 1,
        w: rect.w + 2, h: 3
      }
    end
  end
end