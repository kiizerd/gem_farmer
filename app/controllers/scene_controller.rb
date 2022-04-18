module Takara
  module Controllers
    class SceneController
      include Takara

      def tick
        render
      end

      def render
        outputs[:scene].w = state.world.w
        outputs[:scene].h = state.world.h

        # render_debug

        outputs[:scene].primitives << scenes[state.active_scene]
      end

      def render_debug
        outputs.primitives << gtk.current_framerate_primitives
      end

      def interaction_overlay
        island_sprite.merge path: :overlay
      end

      def island_sprite
        {
          x: 0, y: 0, w: state.world.w, h: state.world.h,
          blendmode_enum: 1, path: :island,
          primitive_marker: :sprite
        }
      end

      def island_border
        {
          x: -8, y: -8, w: state.world.w + 16, h: state.world.h + 16,
          blendmode_enum: 1, path: :island, r: 0, g: 0, b: 0, a: 185,
          primitive_marker: :sprite
        }
      end

      def coast_sim
        { 
          x: -16, y: -16, w: state.world.w + 32, h: state.world.h + 32,
          path: :island, primitive_marker: :sprite,
          r: 36, g: 103, b: 205,
          blendmode_enum: 1,
          a: (((state.tick_count % 240) - 120).abs) + 125
        }
      end

      def confirmation_selected_block
        location = state.spawn_selected_unconfirmed
        block = state.world.block_from(location)
        x = block.x * 2 - block.w * 2
        y = block.y * 2 - block.h * 2
        w = block.w * 6
        h = block.h * 6
        
        block.merge({
          x: x, y: y, w: w, h: h,
          r: 225, g: 100, b: 90,
          a: 255.fluctuate(4),
          primitive_marker: :solid
        })
      end

      def interaction_animation
        color_key = {
          sand: GOLD, grass: LIME, forest: [0, 75, 0, 255], mntn: SILVER,
          snow: GRAY, ocean: [32, 178, 170, 255]
        }
        if state.simple_interaction_animation_start_at
          mouse = state.camera.mouse_pos_in_scene[0..1]
          block = state.world.mouse_block
          start_tick = state.simple_interaction_animation_start_at
          duration   = 30
          easing_args = [ start_tick, state.tick_count, duration, :identity ]
          current_progress = $args.easing.ease *easing_args
          frame_index = (7 * current_progress).ceil.clamp(1, 7)
          state.simple_interaction_animation_rgba ||= color_key[block.type]
          state.simple_interaction_animation_pos  ||= mouse
          rgba = state.simple_interaction_animation_rgba
          pos  = state.simple_interaction_animation_pos
          {
            path: "sprites/animations/pop000#{frame_index}.png",
            x: pos[0] - block.w.half, y: pos[1] - block.h.half,
            w: block.w, h: block.h,
            r: rgba[0], g: rgba[1], b: rgba[2], a: 255,
            blendmode_enum: [:snow, :ocean].include?(block.type) ? 1 : 2
          }
        else
          []
        end
      end

      def world_prop
        [
          island_border, coast_sim, island_sprite,
          interaction_overlay, interaction_animation
        ]
      end

      def player_prop
        [
          state.player.sprite
        ]
      end

      def world_scene
        if state.player.pos
          world_prop << player_prop
        elsif state.spawn_selected_unconfirmed
          world_prop << confirmation_selected_block
        else
          world_prop
        end
      end

      def scenes
        { world:  world_scene }
      end

      def current_scene
        state.camera.current.merge path: :scene
      end
    end
  end
end