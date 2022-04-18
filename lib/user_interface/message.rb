module Takara
  module UI
    module Message
      # Message API
      #=============
      def add_context_message *messages
        message_added_at = state.tick_count

        formatted_messages = messages.map do |msg|
          { text: msg, timeout: 0, a: 255 }
        end

        formatted_messages.each do |msg|
          if state.messages[:context].any? { |m| m.text == msg.text }
          else
            state.messages[:context] << msg
          end
        end
      end

      def remove_context_message
        state.messages.context = []
      end

      def render_context_messages
        messages = state.messages.context

        messages.each_with_index do |msg, i|
          size = 2
          message_rect  = context_message_rect(msg.text, i, size)
          message_label = message_rect.merge({
            text: msg.text, primitive_marker: :label,
            rgba: [255]*4, size_enum: size
          })

          message_shadow = message_label.merge({
            x: message_label.x - 1, y: message_label.y - 1,
            w: message_label.w + 4, h: message_label.h + 4,
            rgba: [15, 15, 15, 255], size_enum: size
          })

          message_background = message_rect.merge({
            x: message_rect.x - 4,
            y: message_rect.y - message_rect.h,
            w: message_rect.w + 8,
            h: message_rect.h + 2,
            rgba: DARK_SLATE_GRAY[0..2].push(220)
          })

          outputs.primitives << [message_background, message_shadow, message_label]
        end
      end

      def context_message_rect text, index, size
        text_rect = gtk.calcstringbox(text, size)

        { x: grid.w.half - text_rect[0].half,
          y: grid.h - 28 - (text_rect[1] * index),
          w: text_rect[0], h: text_rect[1],
          primitive_marker: :solid }
      end

      def add_inform_message *messages
        message_added_at = state.tick_count

        formatted_messages = messages.map do |msg|
          { text: msg, timeout: message_added_at + 300, a: 255 }
        end

        formatted_messages.each do |msg|
          if state.messages[:inform].any? { |m| m.text == msg.text }
          else
            state.messages[:inform] << msg
          end
        end
      end

      def render_inform_messages
        messages = state.messages[:inform]

        messages.each_with_index do |msg, i|
          size = -1
          message_rect  = inform_message_rect(msg.text, i, size)
          message_label = message_rect.merge({
            text: msg.text, primitive_marker: :label,
            rgba: [255]*4, size_enum: size, a: msg.a
          })

          message_shadow = message_label.merge({
            x: message_label.x - 1, y: message_label.y - 1,
            rgba: [15, 15, 15, 255], size_enum: size, a: msg.a
          })

          message_background = message_rect.merge({
            x: message_rect.x - 4,
            y: message_rect.y - message_rect.h,
            w: message_rect.w + 8,
            h: message_rect.h + 2,
            rgba: DARK_SLATE_GRAY[0..2].push(msg.a.clamp(0, 220))
          })

          outputs.primitives << [message_background, message_shadow, message_label]
        end
      end

      def inform_message_rect text, index, size
        text_rect = gtk.calcstringbox(text, size)

        { x: grid.w.half - text_rect[0].half,
          y: grid.h - 125 - (index * (text_rect[1] + 4)),
          w: text_rect[0], h: text_rect[1],
          primitive_marker: :solid }
      end

      def reject_messages
        state.messages[:inform] = state.messages[:inform].reject do |msg|
          if msg.timeout.elapsed?
            msg.a -= (255 / 60)
          end

          (msg.timeout + 60).elapsed?
        end
      end

      def render_messages
        render_context_messages

        render_inform_messages
      end
    end
  end
end