module Takara
  module UI
    module Toolbar
      BG_COLOR  = TOOLBAR_BG_COLOR
      BTN_COLOR = TOOLBAR_BTN_BG_COLOR

      def toolbar
        rect = toolbar_rect
        
        rounded = round_rect(rect, 3)
        shadows = rounded.flatten.map { |r| rect_shadow(r) }
        
        [ 
          shadows, rounded,
          *toolbar_components
        ]
      end

      def toolbar_rect
        w = grid.w*0.75
        h = 56
        x = grid.w.half - w.half
        y = grid.h - h.half + 2
        
        {
          x: x, y: y, w: w, h: h, rgba: BG_COLOR,
          primitive_marker: :solid
        }
      end

      def toolbar_components
        [ 
          toolbar_menu_button,
          toolbar_camera_info,
          toolbar_system_time,
          toolbar_config_button,
          toolbar_inventory_button,
          toolbar_character_button,
          toolbar_stats_button
        ]
      end

      def toolbar_camera_info
        bar_rect = toolbar_rect
        rect     = camera_info_rect
        label    = camera_info_label
        divider  = camera_info_divider
        button   = camera_info_button

        handle_camera_info_click

        [ label, divider, button ]
      end

      def handle_camera_info_click
        mouse = inputs.mouse
        click = mouse.button_bits == 1
        rect  = camera_info_button_rect
        hover = mouse.point.intersect_rect? rect
        
        state.last_camera_button_clicked_at ||= state.tick_count
        click_timeout = state.last_camera_button_clicked_at + 15
        if click && hover && click_timeout.elapsed?
          state.last_camera_button_clicked_at = state.tick_count
          camera   = state.camera
          new_mode = [ :tight, :loose ] - [ camera.mode_variation ]
          camera.mode_variation = new_mode.first
        end
      end

      def camera_info_rect
        toolbar_rect.merge({
          x: toolbar_rect.x+(toolbar_rect.w/12)*11,
          w: toolbar_rect.w/12,
          h: toolbar_rect.h/2,
        })
      end

      def camera_info_button
        bar_rect = toolbar_rect
        rect     = camera_info_button_rect
        icon     = camera_info_icon
        outline  = camera_info_icon_outline
        rounded  = round_rect(rect, 1)

        mouse = inputs.mouse.point
        if mouse.intersect_rect? rect
          [ rounded, icon, outline ]
        else
          [ rounded, icon]
        end
      end

      def camera_info_button_rect
        rect = camera_info_rect
        rect.merge({
          x: rect.x - 2, y: rect.y + 2,
          w: 24, h: 22,
          rgba: BTN_COLOR
        })
      end

      def camera_info_icon
        rect = camera_info_button_rect
        rect.merge({
          path: 'sprites/ui/camera_icon.png',
          primitive_marker: :sprite,
          x: rect.x + 2,
          y: rect.y + 1,
          w: 20, h: 20
        })
      end

      def camera_info_icon_outline
        icon = camera_info_icon
        icon.merge({
          path: 'sprites/ui/camera_icon_outline.png',
          x: icon.x - 1, y: icon.y - 1,
          w: icon.w + 2, h: icon.h + 2
        })
      end

      def camera_info_label
        rect        = camera_info_rect
        camera      = state.camera
        player_mode = camera.mode == :player
        text        = player_mode ? camera.mode_variation : camera.mode
        textbox = gtk.calcstringbox(text.to_s, -3)
        {
          x: rect.x + 30, y: rect.y + textbox[1].half + rect.h.half - 3,
          text: text.to_s.upcase, size_enum: -3, rgba: BLACK
        }
      end

      def camera_info_divider
        rect = camera_info_rect
        rect.merge({
          x: rect.x - 18, w: 6,
          rgba: fade_color(rect.rgba, 0.7)
        })
      end

      def toolbar_system_time
        bar_rect = toolbar_rect

        rect = bar_rect.merge({
          w: bar_rect.w/14, x: bar_rect.x + 16,
          h: bar_rect.h/2
        })

        time = Time.new
        hour   = [12, 24].include?(time.hour) ? 12 : time.hour%12
        minute = time.min < 10 ? "0#{time.min}" : time.min
        second = time.sec < 10 ? "0#{time.sec}" : time.sec
        text = "#{hour}:#{minute}:#{second}"
        textbox = gtk.calcstringbox(text, -3)
        label = {
          x: rect.x, y: rect.y + textbox[1].half + rect.h.half - 2,
          text: text, size_enum: -3, rgba: BLACK
        }

        divider = rect.merge({
          x: rect.x + rect.w,
          w: 6,
          rgba: fade_color(rect.rgba, 0.7)
        })

        [ label, divider ]
      end

      def toolbar_menu_button
        bar_rect = toolbar_rect
        rect = bar_rect.merge({
          x: bar_rect.x+(bar_rect.w/15*14) - 70,
          y: bar_rect.y + 3,
          w: 20, h: 21,
          rgba: BTN_COLOR
        })

        icon = rect.merge({
          path: 'sprites/ui/hamburger_menu_icon.png',
          primitive_marker: :sprite,
          x: rect.x, y: rect.y, w: 20, h: 20
        })

        outline = icon.merge({
          path: 'sprites/ui/hamburger_menu_icon_outline.png',
          x: icon.x, y: icon.y,
          w: icon.w, h: icon.h
        })

        mouse = inputs.mouse.point
        if mouse.intersect_rect? rect
          [ round_rect(rect, 1), icon, outline ]
        else
          [ round_rect(rect, 1), icon ]
        end
      end

      def toolbar_config_button
        bar_rect = toolbar_rect
        rect = bar_rect.merge({
          x: bar_rect.x+(bar_rect.w/15)*13 - 55,
          y: bar_rect.y + 3,
          w: 20, h: 21,
          rgba: BTN_COLOR
        })

        icon = rect.merge({
          path: 'sprites/ui/config_icon.png',
          primitive_marker: :sprite,
          x: rect.x, y: rect.y, w: 20, h: 20
        })

        outline = icon.merge({
          path: 'sprites/ui/config_icon_outline.png',
          x: icon.x, y: icon.y,
          w: icon.w, h: icon.h
        })

        mouse = inputs.mouse.point
        if mouse.intersect_rect? rect
          [ round_rect(rect, 1), icon, outline ]
        else
          [ round_rect(rect, 1), icon ]
        end
      end

      def toolbar_inventory_button
        bar_rect = toolbar_rect
        rect = bar_rect.merge({
          x: bar_rect.x+(bar_rect.w/15)*2 - 20,
          y: bar_rect.y + 3,
          w: 20, h: 21,
          rgba: BTN_COLOR
        })

        icon = rect.merge({
          path: 'sprites/ui/inventory_icon.png',
          primitive_marker: :sprite,
          x: rect.x, y: rect.y, w: 20, h: 20
        })

        outline = icon.merge({
          path: 'sprites/ui/inventory_icon_outline.png',
          x: icon.x, y: icon.y,
          w: icon.w, h: icon.h
        })

        mouse = inputs.mouse.point
        if mouse.intersect_rect? rect
          [ round_rect(rect, 1), icon, outline ]
        else
          [ round_rect(rect, 1), icon ]
        end
      end

      def toolbar_character_button
        bar_rect = toolbar_rect
        rect = bar_rect.merge({
          x: bar_rect.x+(bar_rect.w/15)*3 - 35,
          y: bar_rect.y + 3,
          w: 20, h: 21,
          rgba: BTN_COLOR
        })

        icon = rect.merge({
          path: 'sprites/ui/character_icon.png',
          primitive_marker: :sprite,
          x: rect.x, y: rect.y, w: 20, h: 20
        })

        outline = icon.merge({
          path: 'sprites/ui/character_icon_outline.png',
          x: icon.x, y: icon.y,
          w: icon.w, h: icon.h
        })

        mouse = inputs.mouse.point
        if mouse.intersect_rect? rect
          [ round_rect(rect, 1), icon, outline ]
        else
          [ round_rect(rect, 1), icon ]
        end
      end

      def toolbar_stats_button
        bar_rect = toolbar_rect
        rect = bar_rect.merge({
          x: bar_rect.x+(bar_rect.w/15)*4 - 50,
          y: bar_rect.y + 3,
          w: 20, h: 21,
          rgba: BTN_COLOR
        })

        icon = rect.merge({
          path: 'sprites/ui/stats_icon.png',
          primitive_marker: :sprite,
          x: rect.x, y: rect.y, w: 20, h: 20
        })

        outline = icon.merge({
          path: 'sprites/ui/stats_icon_outline.png',
          x: icon.x, y: icon.y,
          w: icon.w, h: icon.h
        })

        mouse = inputs.mouse.point
        if mouse.intersect_rect? rect
          [ round_rect(rect, 1), icon, outline ]
        else
          [ round_rect(rect, 1), icon ]
        end
      end
    end
  end
end