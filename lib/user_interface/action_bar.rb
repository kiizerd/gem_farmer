module Takara
  module UI
    module ActionBar
      def actionbar
        rect = actionbar_rect
        rounded = round_rect(rect, 5)
        shadow = round_rect(rect.merge({
          x: rect.x - 2, y: rect.y - 2,
          w: rect.w + 4, h: rect.h + 4,
          rgba: fade_color(rect.rgba, 0.5)
        }), 5)

        squares   = actionbar_squares
        items     = [ actionbar_item_icons, actionbar_item_counts ]
        labels    = actionbar_labels
        selection = actionbar_selection

        [ shadow, rounded, squares, items, selection, labels ]
      end

      def actionbar_rect
        w = grid.w.third*2 + 2
        h = 122

        {
          x: -w.half, y: -h.half,
          primitive_marker: :solid,
          w: w, h: h,
          rgba: ROSY_BROWN
        }
      end

      def actionbar_squares
        rect = actionbar_rect
        size = 36

        9.times.map do |i|
          square = rect.merge({
            x: rect.x + rect.w.half + 12 + ((size+10)*i),
            y: rect.y + rect.h.half + 12,
            w: size, h: size, 
            rgba: fade_color(rect.rgba)
          })
        end
      end

      def actionbar_labels
        squares = actionbar_squares
        squares.map_with_index do |square, i|
          square.merge({
            text: (i+1).to_s,
            size_enum: -3,
            x: square.x + 5, y: square.y + square.h - 2,
            primitive_marker: :label,
            rgba: BLACK
          })
        end
      end

      def actionbar_items
        actionbar_squares.map_with_index do |s, i|
          item = state.player.inv[i]
          item || nil
        end.compact
      end

      def actionbar_item_icons
        actionbar_items.map_with_index do |item, index|
          square = actionbar_squares[index]
          icon = state.ctrl.item.item_icon(item.item_name)
          icon.merge({ x: square.x + 2, y: square.y + 2 })
        end
      end

      def actionbar_item_counts
        actionbar_items.map_with_index do |item, index|
          square     = actionbar_squares[index]
          text       = item.amount.to_s
          textbox    = gtk.calcstringbox(text, -4)
          background = square.merge({
            w: textbox[0] + 2, h: textbox[1] + 1,
            rgba: fade_color(square.rgba, 0.5)
          })

          count = square.merge({
            x: square.x + 1, y: square.y + textbox[1] - 1,
            primitive_marker: :label,
            text: text, rgba: WHITE,
            size_enum: -4,
          })

          item.amount ? [ background, count ] : nil
        end.compact
      end

      def actionbar_selection
        squares = actionbar_squares
        index  = state.player.held_item
        square = squares[index]
        square.merge({
          x: square.x - 2, y: square.y - 2,
          w: square.w + 4, h: square.h + 4,
          primitive_marker: :border,
          rgba: WHITE
        })
      end
    end
  end
end