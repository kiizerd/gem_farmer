module Takara
  class Game
    attr_gtk

    def tick
      setup

      tick_controllers
      state.camera.tick

      if state.player.pos && 15.elapsed?
        state.player.tick
      else
        spawn_player
      end

      render
    end

    def setup
      state.system_time_started_at ||= Time.new.to_i
      state.messages     ||= { context: [], inform: [] }
      state.ctrl         ||= Controllers::init
      
      state.world_size   ||= 8
      state.sea_level    ||= 0.185
      state.load_world   ||= true
      state.world        ||= new_world
      
      state.player       ||= Player.new

      state.camera       ||= Views::Camera.new
      state.active_scene ||= :world

      state.benchmark    ||= print_benchmark
    end

    def tick_controllers
      [ ui, scene_ctrl, interact_ctrl ].map(&:tick)
    end

    def ui
      state.ctrl[:ui]
    end

    def scene_ctrl
      state.ctrl[:scene]
    end

    def item_ctrl
      state.ctrl[:item]
    end

    def interact_ctrl
      state.ctrl.interaction
    end

    def render
      outputs.sprites << state.world.animated_ocean
      outputs.sprites << scene_ctrl.current_scene
    end

    def new_world
      Takara::World::World.new(state.world_size, state.sea_level)
    end

    def reset_world
      state.world = new_world
    end

    # This is very messy
    def spawn_player
      # Get mouse position and the block under the mouse
      mouse = state.camera.mouse_pos_in_scene[0..1]
      mouse_block_pos = mouse.map_with_index do |x, i|
        (x / state.world.terrain_block_size[i] / 2).floor
      end

      # Init state value if not created
      state.spawn_selected_unconfirmed ||= false
      if state.spawn_selected_unconfirmed
        # If a spawn position is selected but not yet confirmed
        # Call this method to run the confirmation
        confirm_spawn_location
      else
        # If spawn location not yet selected
        ui.add_context_message("Select spawn location.")        

        # Init state values
        state.confirmation_cancel_clicked_at ||= 0
        state.confirmation_accept_clicked_at ||= 0
        # If mouse clicked
        if inputs.mouse.button_left
          # Checks if block under mouse is valid
          mouse_on_land = state.world.is_land_block?(mouse_block_pos)
          # Sets timeout on confirmation button clicks
          # to prevent regsitering multiple clicks
          spawn_confirmation_timeout = [
            state.confirmation_accept_clicked_at + 16,
            state.confirmation_cancel_clicked_at + 16
          ]
          # If a valid block is selected
          if mouse_on_land
            # If all confirmation timeouts have elapsed
            if spawn_confirmation_timeout.all? { |x| x.elapsed? }
              # Set selected spawn point at mouse block and begin confirmation
              state.spawn_selected_unconfirmed = mouse_block_pos
            end
          # If invalid block selected
          else
            # Display help message to player
            messages = [
              "Selected location invalid. Spawn location must be either:",
              "grassland(light-green) or forest(dark-green) block"
            ]
            
            ui.add_inform_message(*messages)
          end
        end
      end
    end

    def confirm_spawn_location
      location   = state.spawn_selected_unconfirmed
      spawn_pos  = location.map { |x| x * state.world.terrain_block_size[0] * 2 }
      block      = state.world.block_from(location)
      block_data = [
        "Confirm block selection",
        "",
        "X: #{block.pos[0]} | Y: #{block.pos[1]}",
        "Elevation: #{(block.noise*10000).floor/100}"
      ]
      
      case ui.confirmation_dialog(*block_data)
      when 1        
        state.player.spawn_at(spawn_pos)
        state.camera_zoom_to_player = true
        ui.remove_context_message
      when 0
      when -1
        state.spawn_selected_unconfirmed = false
        state.confirmation_accept_clicked = false
        state.confirmation_cancel_clicked = false
      end
    end

    def print_benchmark
      game_start     = state.system_time_started_at
      world_finish   = state.world_init_finish_at   || 0
      terrain_finish = state.terrain_init_finish_at || 0

      world_gen_time   = world_finish - game_start
      terrain_gen_time = terrain_finish - game_start

      string =  "Terrain generation took.. #{terrain_gen_time} seconds\n"
      string += "World generation took.. #{world_gen_time} seconds"

      puts string

      true
    end
  end
end