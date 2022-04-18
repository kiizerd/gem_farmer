module Takara
  module Controllers
    class InteractionController
      include Takara
      include Action

      def tick
        if state.tick_count < 1
          3.times do |i|
            growing_sprite_path((Time.now.to_i) + (10*(i+1)))
          end
          plant_sprite_path
        end

        listen
        render
      end

      def listen
        listen_for_click
        listen_for_block_interaction
        listen_for_interaction_timeout
      end

      def render
        render_interactions
      end

      def listen_for_click
        click   = inputs.mouse.click
        l_click = inputs.mouse.button_bits == 1
        menu_clicked  = state.context_menu_button_clicked_at == state.tick_count
        anim_started  = state.simple_interaction_animation_start_at

        if (click && l_click && !menu_clicked) || anim_started
          start_mouse_click_animation
        end
      end

      def listen_for_block_interaction
        context_menu = state.ui_context_menu
        if context_menu
          block = state.world.mouse_block
          state.current_interacting_block ||= block
        end
  
        if state.context_menu_option_selected && state.current_interacting_block
          block = state.current_interacting_block
          interaction = state.context_menu_option_selected
          
          interact(block, interaction)
  
          state.current_interacting_block    = false
          state.context_menu_option_selected = false
        end
  
        if !context_menu
          state.current_interacting_block    = false
          state.context_menu_option_selected = false
        end
      end

      def listen_for_interaction_timeout
        interactions = state.world.interactions
        # Retrieve all interactions where the current time
        # is greater than the timein + timeout of the interaction
        timed_out = interactions.reject do |pos, data|
          timeout = timeout_key[data[0]] || YEAR
          Time.new.to_i < (data[1] + timeout)
        end
  
        if !timed_out.empty?
          timed_out.each do |pos, data|
            remove_interaction_at(pos)
            interaction = data[0]
            if interaction == :plant
              update_blockstate_at(pos, :growing)
              update_interactions_at(pos, :growing)
            elsif interaction == :growing
              update_blockstate_at(pos, :grown)
              update_interactions_at(pos, :grown)
            else
              update_blockstate_at(pos, :natural)
            end
          end
        end
      end

      def render_interactions
        outputs[:overlay].w = state.world.w
        outputs[:overlay].h = state.world.h
        state.world.interactions.each do |pos, data|
          block  = block_from_action(pos, data)
          rgba   = action_color[data[0]] || block.values_at(:r, :g, :b, :a)
          border = block.merge({
            r: rgba[0] * 0.75, g: rgba[1] * 0.75, b: rgba[2] * 0.75,
            primitive_marker: :border
          })

          if ![ :natural, :gathered ].include? state.world.blockstates[pos]
            outputs[:overlay].primitives << block
          end

          outputs[:overlay].primitives << border
        end
      end

      def start_mouse_click_animation
        state.simple_interaction_animation_start_at ||= state.tick_count
        start_tick  = state.simple_interaction_animation_start_at
        duration    = 30
        easing_args = [ start_tick, state.tick_count, duration, :identity ]
        current_progress = easing.ease *easing_args
        if current_progress >= 1
          state.simple_interaction_animation_start_at = false
          state.simple_interaction_animation_pos  = false
          state.simple_interaction_animation_rgba = false
        end
      end
    end
  end
end