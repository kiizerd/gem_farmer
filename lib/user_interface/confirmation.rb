module Takara
  module UI
  module Confirmation
    # Confirmation API
    #==================
    def confirmation_dialog *texts
      state.confirmation_dialog_opened_at ||= state.tick_count
      dialog_ready = (state.confirmation_dialog_opened_at + 5).elapsed?
      listen_for_confirmation_click if dialog_ready

      elements = [ 
        confirmation_dialog_rect,
        confirmation_text_elements(texts),
        confirmation_accept_button,
        confirmation_cancel_button
      ]

      outputs.primitives << elements

      if state.confirmation_accept_clicked
        1
      elsif state.confirmation_cancel_clicked
        -1
      else
        0
      end
    end

    def listen_for_confirmation_click
      listen_for_accept_button_click
      listen_for_cancel_button_click
    end

    def listen_for_accept_button_click
      btn_rect = confirmation_accept_button_rect
      mouse    = inputs.mouse.point
      click    = inputs.mouse.button_left
      hover    = mouse.intersect_rect? btn_rect

      if hover && click
        state.confirmation_accept_clicked_at = state.tick_count
        state.confirmation_accept_clicked    = true
        state.confirmation_dialog_opened_at  = false
      end
    end

    def listen_for_cancel_button_click
      btn_rect = confirmation_cancel_button_rect
      mouse    = inputs.mouse.point
      click    = inputs.mouse.button_left
      hover    = mouse.intersect_rect? btn_rect

      if hover && click
        state.confirmation_cancel_clicked_at = state.tick_count
        state.confirmation_cancel_clicked    = true
        state.confirmation_dialog_opened_at  = false
      end
    end

    def confirmation_text_elements texts
      rect = confirmation_dialog_rect
      texts.map_with_index do |text, i|
        size = i == 0 ? 0 : -2
        text_box = gtk.calcstringbox(text, size)

        text_shadow = { 
          x: rect.x + rect.w.half - text_box[0].half - 1,
          y: rect.y + rect.h - 15 - 1 - (text_box[1]*i),
          rgba: [15, 15, 15, 255],
          text: text, primitive_marker: :label,
          size_enum: size
        }

        label = {
          x: rect.x + rect.w.half - text_box[0].half,
          y: rect.y + rect.h - 15 - (text_box[1]*i),
          rgba: [255]*4,
          text: text, primitive_marker: :label,
          size_enum: size
        }

        [ text_shadow, label ]
      end.flatten
    end

    def confirmation_accept_button
      [
        confirmation_accept_button_rect,
        confirmation_accept_button_text_shadow,
        confirmation_accept_button_label
      ]
    end

    def confirmation_accept_button_rect
      rect = confirmation_dialog_rect
      {
        x: rect.x + 10, y: rect.y + 10,
        w: rect.w.third, h: 30,
        rgba: [40, 38, 36, 220],
        primitive_marker: :solid
      }
    end

    def confirmation_accept_button_text_shadow
      text = 'Accept'
      accept_text_box = gtk.calcstringbox(text)
      accept_button = confirmation_accept_button_rect

      {
        x: accept_button.x + accept_button.w.half - accept_text_box[0].half - 1,
        y: accept_button.y + accept_button.h.half + accept_text_box[1].half - 1,
        text: text,
        rgba: [15, 15, 15, 255],
        primitive_marker: :label
      }
    end

    def confirmation_accept_button_label
      text = 'Accept'
      accept_text_box = gtk.calcstringbox(text)
      accept_button = confirmation_accept_button_rect

      {
        x: accept_button.x + accept_button.w.half - accept_text_box[0].half,
        y: accept_button.y + accept_button.h.half + accept_text_box[1].half,
        text: text,
        rgba: [255]*4,
        primitive_marker: :label
      }
    end

    def confirmation_cancel_button
      [
        confirmation_cancel_button_rect,
        confirmation_cancel_button_text_shadow,
        confirmation_cancel_button_label
      ]
    end

    def confirmation_cancel_button_rect
      rect = confirmation_dialog_rect
      {
        x: rect.x + rect.w - rect.w.third - 10,
        y: rect.y + 10,
        w: rect.w.third, h: 30,
        rgba: [40, 38, 36, 220],
        primitive_marker: :solid
      }
    end

    def confirmation_cancel_button_text_shadow
      text = 'Cancel'
      cancel_text_box = gtk.calcstringbox(text)
      cancel_button = confirmation_cancel_button_rect

      {
        x: cancel_button.x + cancel_button.w.half - cancel_text_box[0].half - 1,
        y: cancel_button.y + cancel_button.h.half + cancel_text_box[1].half - 1,
        text: text,
        rgba: [15, 15, 15, 255],
        primitive_marker: :label
      }
    end

    def confirmation_cancel_button_label
      text = 'Cancel'
      cancel_text_box = gtk.calcstringbox(text)
      cancel_button = confirmation_cancel_button_rect

      {
        x: cancel_button.x + cancel_button.w.half - cancel_text_box[0].half,
        y: cancel_button.y + cancel_button.h.half + cancel_text_box[1].half,
        text: text,
        rgba: [255]*4,
        primitive_marker: :label
      }
    end

    def confirmation_dialog_rect
      w = grid.w/4
      h = grid.h/5

      { x: grid.w.half - w.half,
        y: grid.h - (h*2),
        w: w, h: h,
        rgba: UI::UI_BG_COLOR,
        primitive_marker: :solid }
    end    
  end
end
end