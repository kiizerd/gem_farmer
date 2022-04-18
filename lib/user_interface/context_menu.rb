module Takara
  module UI
    module ContextMenu
      # Builds a context menu and renders it
      def context_menu pos
        setup_context_menu(pos)
        render_context_menu
        context_menu_listen
      end

      # Assigns context_state variables when new context menu invoked
      def setup_context_menu pos
        context = determine_context(pos)

        context_state.pos     ||= pos
        context_state.options ||= determine_options(context)

        rect = menu_rect(context_state.pos, context_state.options)
        context_state.rect    = rect
      end

      # Assembles elements of context menu and sends it to $outputs.primitives
      def render_context_menu
        rect = context_state.rect
        btns = menu_buttons(context_state.options)

        outputs.primitives << [ rect, btns ]
      end

      # Listens for important changes in state and calls other listen methods
      def context_menu_listen
        listen_for_menu_click

        if state.context_menu_button_clicked
          button_index   = state.context_menu_button_clicked
          button_clicked = context_state.options[button_index]
          state.context_menu_option_selected = button_clicked

          clear_menu
        elsif state.context_menu_clicked_away_from
          clear_menu
        end
      end

      # Returns symbol of context under mouse click pos
      def determine_context pos
        # Some determination logic
        # For now only relevant context is :block

        :block
      end

      # Returns an array of options for context menu at mouse pos
      def determine_options context
        case context
        when :block then determine_block_options
        when :someothercontext
        end
      end

      # Returns an array of options context menu of a block
      # Returns different options depending on selected blocks state
      def determine_block_options
        mouse = state.camera.mouse_pos_in_scene[0..1]
        pos   = mouse.map_with_index do |x, i|
          (x / state.world.terrain_block_size[i] / 2).floor
        end
        blockstate = state.world.blockstates[pos]

        if blockstate == :natural
          determine_natural_block_options(pos)
        else
          determine_unnatural_block_options(pos)
        end
      end

      def determine_natural_block_options pos
        block_type = state.world.blocktypes[pos]
        options = state.ctrl.interaction.type_action_key[block_type].map(&:to_s)
        options.map { |s| (s[0].upcase + s[1..-1]).gsub('_', ' ') }
      end

      def determine_unnatural_block_options pos
        blockstate = state.world.blockstates[pos]
        options = state.ctrl.interaction.state_action_key[blockstate].map(&:to_s)
        options.map { |s| (s[0].upcase + s[1..-1]).gsub('_', ' ') }
      end

      # Listens for right click
      # Opens context menu if valid
      def listen_for_context_menu_click
        menu = state.ui_context_menu
        
        if click_should_open_context_menu? || menu
          mouse = mouse_block_selection.first.values[0..1]
          context_menu(mouse)
        elsif !click_should_open_context_menu? && !menu
          inform_message_for_context_click
        end
      end

      # Returns true if right click should open new context menu
      def click_should_open_context_menu?
        r_click  = inputs.mouse.button_right
        mouse    = state.camera.mouse_pos_in_scene[0..1]
        is_land  = mouse_block_is_land?(mouse)
        in_reach = mouse_block_in_reach?(mouse)
        player_spawned = state.player.pos

        [
          !mouse_over_toolbar?, r_click,
          is_land, in_reach,
          player_spawned
        ].all?
      end

      # Informs user of validations if context menu not opened
      def inform_message_for_context_click
        player_spawned = state.player.pos
        r_click = inputs.mouse.button_right
        mouse = state.camera.mouse_pos_in_scene[0..1]
        return unless r_click && player_spawned && !mouse_over_toolbar?

        if !mouse_block_is_land?(mouse)
          add_inform_message('Only land block are interactable.')
        elsif !mouse_block_in_reach?(mouse)
          add_inform_message('Can only interact with blocks within your reach')
        end
      end

      def mouse_over_toolbar?
        toolbar_rect.intersect_rect? inputs.mouse.point
      end

      # Returns true if context menu opened over land block
      def mouse_block_is_land? mouse
        block = mouse.map_with_index do |x, i|
          (x / state.world.terrain_block_size[i] / 2).floor
        end

        state.world.is_land_block?(block)
      end
      
      # Returns true if context menu opened inside players reach
      def mouse_block_in_reach? mouse
        distance = geo.distance(mouse, state.player.point)

        distance <= 78
      end

      # Listens for a click in the menu to select options
      # Or a click away from the menu to close it
      def listen_for_menu_click
        listen_for_menu_button_click
        listen_for_menu_click_away
      end

      # Listens to each of the buttons within the menu for a click
      # Sets state.context_menu_button_clicked
      # to the index of the option selected
      def listen_for_menu_button_click
        buttons = context_state.options.map_with_index do |option, i|
          menu_button_rect(option, i)
        end

        buttons.each_with_index do |button, i|
          hover = button.intersect_rect?(inputs.mouse.point)
          click = inputs.mouse.button_left

          if hover && click
            state.context_menu_button_clicked = i
            state.context_menu_button_clicked_at = state.tick_count
          end
        end
      end

      # Listens for any click outside the menu
      # Closes menu if click heard
      def listen_for_menu_click_away
        click = inputs.mouse.button_left
        rect  = context_state.rect
        hover = rect.intersect_rect? inputs.mouse.point

        if click && !hover 
          state.context_menu_clicked_away_from = true
        end
      end
      
      # Returns a rect representing the context menu at pos with options
      def menu_rect pos, options
        text_boxes = options.map { |s| gtk.calcstringbox(s, 1) }
        max_w = text_boxes.map { |b| b[0] }.max
        max_h = text_boxes.map { |b| b[1] }.max

        context_state.max_w ||= max_w
        context_state.max_h ||= max_h

        w = max_w + 7
        h = (max_h + 6)*options.size + 1
        
        {
          x: pos.first, y: pos.last,
          w: w, h: h,
          rgba: UI::UI_BG_COLOR[0..2].push(150),
          primitive_marker: :solid
        }
      end

      # Returns an array of menu buttons for current context menu
      def menu_buttons options
        rect = menu_rect(context_state.pos, context_state.options)

        # for each option with index
        # make a button, a label, and a text shadow
        # offset each options y by the index * (max_h + 2)
        options.map_with_index do |option, i|          
          [
            menu_button_rect(option, i),
            menu_button_text_shadow(option, i),
            menu_button_label(option, i)
          ]
        end
      end

      # Returns a hash representing a single button of the context menu
      def menu_button_rect option, index
        menu_rect = context_state.rect
        w = context_state.max_w - 1
        h = context_state.max_h
        x = menu_rect.x + 4
        y = menu_rect.y + menu_rect.h - ((h+4.5) * (index+1))
        
        {
          x: x, y: y, w: w, h: h,
          rgba: UI::UI_BG_COLOR[0..2],
          primitive_marker: :solid
        }
      end

      # Returns a label for the text shadow of a single context menu button
      def menu_button_text_shadow option, index
        button_label = menu_button_label(option, index)

        button_label.merge({
          x: button_label.x - 1, y: button_label.y - 1,
          rgba: [0, 0, 0, 255]
        })
      end

      # Returns a label for the text of a context menu button
      def menu_button_label option, index
        button_rect = menu_button_rect(option, index)
        
        button_rect.merge({
          x: button_rect.x + 2,
          y: button_rect.y + button_rect.h - 2,
          text: option, primitive_marker: :label,
          rgba: [255, 255, 255, 255]
        })
      end

      # Returns the current state.ui_context_menu
      def context_state
        state.ui_context_menu ||= {}
      end

      # Clears the context menu and resets all state variables
      def clear_menu
        state.context_menu_button_clicked    = false
        state.context_menu_clicked_away_from = false
        state.new_context_options            = false

        state.ui_context_menu = false
      end
    end
  end
end