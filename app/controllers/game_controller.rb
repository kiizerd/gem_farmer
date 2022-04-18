module Takara
  module Controllers
    class GameController
      include Takara
      # All placeholder stuff
      GAME_STATES = [ :setup, :paused, :running, :loading ]

      def tick
        listen_for_state_change

        handle_state
      end

      def handle_state
        case state.game_state
        when :setup
        when :paused
        when :running
        when :loading
        end
      end

      def listen_for_state_change
        if state.start_button_pressed
          change_state(:running)
        end

        if state.pause_button_pressed
          change_state(:paused)
        end

        if state.world_generating
          change_state(:loading)
        end

        if state.returning_to_menu
          change_state(:setup)
        end
      end

      private

      def change_state new_state
        raise 'InvalidGameState' if !GAME_STATES.include?(new_state)

        state.game_state = new_state
      end
    end
  end
end