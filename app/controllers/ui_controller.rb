module Takara
  module Controllers
    class UIController
      include Takara
      include Takara::UI
      include Takara::UI::Panel
      include Takara::UI::Toolbar
      include Takara::UI::Message
      include Takara::UI::ActionBar
      include Takara::UI::ContextMenu
      include Takara::UI::Confirmation

      def tick
        clear_menu if state.tick_count < 1
        reject_messages

        render

        listen_for_context_menu_click

        handle_cursor
      end

      def render
        render_messages

        menu = state.ui_context_menu
        if menu
          outputs.primitives << interacting_block_selection
        end

        if state.player.pos
          outputs.primitives << actionbar
        end

        outputs.primitives << toolbar
        # outputs.primitives << panel
      end

      def mouse_block_selection
        camera = state.camera
        x, y, w, h = camera.mouse_block_selection.values
        
        # Create a rect from mouse position and get the sides of the rect
        rect = { x: x, y: y, w: w, h: h }
        sides = Takara::Rect.sides_of_rect(rect)

        # Return each side merged with a solid primitive marker
        sides.values.map { |s| s.merge primitive_marker: :solid }
      end

      def interacting_block_selection
        x, y = state.ui_context_menu.pos
        w, h = state.camera.mouse_block_selection.values[2..3]

        rect = { x: x, y: y - h + 1, w: w, h: h }
        sides = Takara::Rect.sides_of_rect(rect)

        sides.values.map { |s| s.merge primitive_marker: :solid }
      end

      def handle_cursor
        if state.tick_count <= 1
          gtk.set_cursor('sprites/cursor/gradient_cursor.png')
        end
      end
    end
  end  
end