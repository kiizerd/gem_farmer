module Takara
  module UI
    module Panel
      def panel
        rect = panel_rect
        rounded = round_rect(rect, 1)
        shadow_rect = rect.merge({
          x: rect.x - 2, y: rect.y - 2,
          w: rect.w + 4, h: rect.h + 4, 
          rgba: fade_color(rect.rgba, 0.7)
        })
        shadow_rounded = round_rect(shadow_rect, 1)
        name = 'Inventory'
        # content = inventory_content

        [ shadow_rounded, rounded, panel_header(name), content ]
      end

      def panel_rect
        w = grid.w / 2.5
        h = grid.h / 1.5

        { x: grid.w/2 - w/2, y: grid.h/2 - h/2,
          w: w, h: h,
          primitive_marker: :solid,
          rgba: fade_color(SEA_GREEN, 0.9, 0.8) }
      end

      def panel_header text
        rect   = round_rect(panel_header_rect, 1)
        shadow = round_rect(panel_header_shadow, 1)
        label  = panel_header_label(text)
        close  = panel_header_close_button

        [ shadow, rect, label, close ]
      end

      def panel_header_rect
        h = 48
        rect = panel_rect
        rect.merge({
          x: rect.x - 12, y: rect.y + rect.h - h.half,
          h: h, w: rect.w + 24,
          rgba: fade_color(rect.rgba, 1.2, 1.3)
        })
      end

      def panel_header_shadow
        rect = panel_header_rect
        rect.merge({
          x: rect.x - 2, y: rect.y - 2,
          w: rect.w + 4, h: rect.h + 4,
          rgba: fade_color(rect.rgba, 0.7, 0.8)
        })
      end

      def panel_header_label text
        rect = panel_header_rect
        textbox = gtk.calcstringbox(text, 2)
        rect.merge({
          text: text,
          x: rect.x + 6, y: rect.y + textbox[1]/2 + rect.h/2,
          primitive_marker: :label,
          size_enum: 2,
          rgba: WHITE
        })
      end

      def panel_header_close_button
        rect = panel_header_rect
        size = rect.h / 1.5
        textbox = gtk.calcstringbox('x', 6)
        button_rect = rect.merge({
          x: rect.x + rect.w - size*1.25,
          y: rect.y + size/4,
          w: size, h: size,
          rgba: fade_color(rect.rgba)
        })

        outline = button_rect.merge({
          x: button_rect.x - 1, y: button_rect.y - 1,
          w: button_rect.w + 2, h: button_rect.h + 2,
          rgba: fade_color(button_rect.rgba)
        })

        label = button_rect.merge({
          x: button_rect.x + button_rect.w/4,
          y: button_rect.y + button_rect.h + 1,
          text: 'x',
          size_enum: 6,
          rgba: WHITE,
          primitive_marker: :label
        })

        if inputs.mouse.point.intersect_rect? button_rect
          outline = outline.merge({
            rgba: fade_color(button_rect.rgba, 1.3)
          })
        end
        
        [ outline, button_rect ].map { |r| round_rect(r, 1) }.push(label)
      end
    end
  end
end
