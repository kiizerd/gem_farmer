module Takara
  module Views
    class Camera
      include Takara

      attr_reader :x, :y, :scale, :prev, :focus_zone
      attr_accessor :mode, :mode_variation

      def initialize
        @x = 0
        @y = 0
        @scale = 0.5
        @mode  = :player
        @mode_variation = :tight
        @target     = [ 1280, 720 ]
        @focus_zone = new_focus_zone
      end

      def tick
        state.player_last_centered_at ||= 0
        state.player_last_centered_at = state.tick_count if player_centered?
        zoom_to_player if state.camera_zoom_to_player
        handle_inputs
        
        case @mode
        when :mouse  then target_mouse
        when :player then target_player
        when :center then center_on_player
        end

        follow_target
      end

      def zoom_to_player
        center_on_player
        scale_diff = (@scale - 2.0).abs

        @scale += @scale < 2.0 ? (scale_diff/30) : -(scale_diff/30)
        if player_centered?
          state.camera_zoom_to_player = false
        end
      end

      def follow_target
        @focus_zone = new_focus_zone
        update!(calc_scene)
      end
      
      def target_player
        case @mode_variation
        when :tight then target_player_tight
        when :loose then target_player_loose
        end
      end

      def target_player_tight
        player = state.player.focus_point

        if !player_centered?
          @target = interpolate_point(@target, player)
        end
      end

      def target_player_loose
        player = state.player.next_center.values
        
        if !player_in_focus?
          @mode = :center
        end
      end

      def target_mouse
        mouse = mouse_pos_in_scene

        if !mouse_in_focus?
          @target = interpolate_point(@target, mouse, 45)
        end
      end

      def target_player_focus_mouse
        player = state.player
        mouse  = mouse_pos_in_scene

        if player_in_focus?
          if !mouse_in_focus?
            @target = interpolate_point(@target, mouse)
          end
        else
          @target = interpolate_point(@target, player.focus_point)
        end
      end

      def center_on_player
        if player_centered?(-20)
          @mode = :player
          target_player
        end

        player_center = state.player.next_center.values
        @target = interpolate_point(@target, player_center, 30)        
      end

      def center_on_mouse
        mouse = mouse_pos_in_scene[0..1]
        @target = interpolate_point(@target, mouse, 30)
      end

      def player_in_focus?
        player = state.player.focus_point
        player_focus_colliders.none? do |collider|
          collider.intersect_rect? player
        end
      end

      def player_centered? variance=0
        player = state.player.next_center.values
        
        geo.distance(center_point, player) < (30 + variance)
      end

      def mouse_in_focus?
        mouse = inputs.mouse.point
        mouse_focus_colliders.none? do |collider|
          collider.intersect_rect? mouse
        end
      end

      def calc_scene
        x_offset = (@focus_zone.x + @focus_zone.w.half)
        y_offset = (@focus_zone.y + @focus_zone.h.half)
        w = state.world.w * @scale
        h = state.world.h * @scale
        
        x = grid.w.half - (x_offset * @scale)
        y = grid.h.half - (y_offset * @scale)

        { x: x, y: y, w: w, h: h, scale: @scale }
      end

      # Interpolates the best point between prev and dest
      def interpolate_point prev, dest, speed=90
        x_distance = (prev[0] - dest[0]).abs
        y_distance = (prev[1] - dest[1]).abs
        x_dist_factor = (100 / x_distance).clamp(0.01, 10)
        y_dist_factor = (100 / y_distance).clamp(0.01, 10)
        delta_x = (x_distance / speed * x_dist_factor).round(22)
        delta_y = (y_distance / speed * y_dist_factor).round(22)

        dest_x = prev[0] + (dest[0] > prev[0] ? delta_x : -delta_x)
        dest_y = prev[1] + (dest[1] > prev[1] ? delta_y : -delta_y)

        [ dest_x, dest_y ]
      end

      def new_focus_zone
        point = @target
        w = 1 / current.scale / 2 * 1024 * 1.6
        h = 1 / current.scale / 2 * 1024 * 0.9
        x = point[0] - w.half
        y = point[1] - h.half

        { x: x, y: y, w: w, h: h }.merge({ 
          primitive_marker: :border,
          rgba: [17, 13, 9, 255]
        })
      end

      def mouse_pos_in_scene
        # Get actual mouse point position
        mx, my = inputs.mouse.point
        # Shift origin to scene origin
        mx -= @x
        my -= @y
        # Scale position
        mx *= inverse_scale
        my *= inverse_scale

        [mx, my, 0, 0]
      end

      def mouse_block_selection
        x, y = mouse_pos_in_scene[0..1]
        w, h = state.world.terrain_block_size.map { |x| x*2 * @scale }

        x *= @scale
        y *= @scale
        
        x += @x
        y += @y

        x -= (x - @x) % w
        y -= (y - @y) % h

        { x: x, y: y, w: w, h: h }
      end

      def current
        { x: @x, y: @y, w: @w, h: @h, scale: @scale }
      end

      def world_center
        [ 1280, 720 ]
      end

      def center_point
        w = 2560/@scale / 4
        h = 1440/@scale / 4
        x = -@x/@scale + w
        y = -@y/@scale + h
        
        [ x, y ]
      end

      def center_rect
        size = 32 * @scale
        x, y = center_point.map { |x| x - size.half }

        { x: x, y: y, w: size, h: size }
      end

      def screen_rect
        w = 2560/@scale / 2
        h = 1440/@scale / 2
        x = -@x/@scale
        y = -@y/@scale

        { x: x, y: y, w: w, h: h }
      end

      def mode_label
        { x: 10, y: grid.h - 100, text: 'Camera mode: ' + @mode.to_s }
      end

      def mode_variation_label
        { x: 10, y: grid.h - 120, text: 'Mode variation: ' + @mode_variation.to_s }
      end

      def selection_label
        mouse = mouse_block_selection
        { x: 10, y: grid.h - 120, text: "Selector - x: #{mouse.x.floor}|y: #{mouse.y.floor}" }
      end

      def mouse_label
        mouse = mouse_pos_in_scene

        {x: 10, y: grid.h - 140, text: "In_Scene - x: #{mouse.x.floor}|y: #{mouse.y.floor}" }
      end

      private

      def inverse_scale
        1 / @scale
      end

      def update! source
        @x = source.x || @x
        @y = source.y || @y
        @w = source.w || @w
        @h = source.h || @h
        @scale = source.scale || @scale
      end

      def handle_inputs
        handle_zoom
        handle_mode_switch
        handle_mouse_drag

        handle_center
      end

      def handle_zoom
        state.last_camera_zoom_at ||= state.tick_count
        zoom_timeout = state.last_camera_zoom_at + 4

        if inputs.mouse.wheel&.y && zoom_timeout.elapsed?
          state.last_camera_zoom_at = state.tick_count

          scroll = $inputs.mouse.wheel.y
          scale  = @scale
          scale += scroll > 0 ? 0.125 : -0.125
          scale  = scale.greater(0.5)
          scale  = scale.clamp(1, 3) if state.player.pos

          update!({ scale: scale })
        end
      end

      def handle_mode_switch
        modes = [ :tight, :loose ]
        state.last_camera_mode_switch_at ||= state.tick_count
        switch_timeout = state.last_camera_mode_switch_at + 15
        if inputs.keyboard.key_down.tab && switch_timeout.elapsed?
          state.last_camera_mode_switch_at = state.tick_count

          @mode_variation = modes[(modes.index(@mode_variation) + 1) % modes.size]
        end
      end

      def handle_center
        state.last_camera_center_at ||= state.tick_count
        center_timeout = state.last_camera_center_at + 20
        if inputs.keyboard.key_down.space && center_timeout.elapsed?
          state.last_camera_center_at = state.tick_count

          @mode = :center
        end
      end

      def handle_mouse_drag
        state.last_mouse_drag_at ||= state.tick_count
        middle_click = inputs.mouse.button_bits == 2        
        return unless middle_click || !last_drag_resolved?

        if middle_click
          @mode = :mouse
          state.last_mouse_drag_at = state.tick_count
        else
          if last_drag_resolved?
            @mode = :player
          else
            @mode = :center
          end
        end
      end

      def last_drag_resolved?
        state.last_mouse_drag_at < state.player_last_centered_at
      end

      def last_center_resolved?
        (state.last_camera_center_at + 20).elapsed?
      end

      def valid_destination? dest
        # Check if screen_rect with a center of destination
        # will intersect with player
        w = screen_rect.w
        h = screen_rect.h
        x = dest[0] - w.half
        y = dest[1] - h.half
        screen_at_dest = screen_rect.merge({ x: x, y: y, w: w, h: h })
        
        screen_at_dest.intersect_rect? state.player.rect
      end

      def player_focus_colliders
        focus_zone = @focus_zone
        vertical_width    = grid.w * 10
        vertical_height   = grid.h * 12
        horizontal_width  = grid.w * 12
        horizontal_height = grid.h * 10

        [
          # Top collider
          { x: focus_zone.x - horizontal_width/4,
            y: focus_zone.y + focus_zone.h,
            w: horizontal_width,
            h: horizontal_height },
          # Right collider
          { x: focus_zone.x + focus_zone.w,
            y: focus_zone.y - vertical_height/4,
            w: vertical_width,
            h: vertical_height },
            # Bottom collider
          { x: focus_zone.x - horizontal_width/4,
            y: focus_zone.y - horizontal_height,
            w: horizontal_width,
            h: horizontal_height },
          # Left collider
          { x: focus_zone.x - vertical_width,
            y: focus_zone.y - vertical_height/4,
            w: vertical_width,
            h: vertical_height }
        ]
      end

      def mouse_focus_colliders
        vw = grid.w.half*1.3
        vh = grid.h*2

        hw = grid.w*2
        hh = grid.h.half*1.3

        vert_margin = (grid.w - vw)/2
        horz_margin = (grid.h - hh)/2

        [
          # Top collider
          { x: -hw/4, y: grid.h - horz_margin, w: hw, h: hh },
          # Right collider
          { x: grid.w - vert_margin, y: -vh/4, w: vw, h: vh },
          # Bottom collider
          { x: -hw/4, y: horz_margin - hh, w: hw, h: hh },
          # Left Collider
          { x: vert_margin - vw, y: -vh/4, w: vw, h: vh }
        ]
      end
    end
  end
end