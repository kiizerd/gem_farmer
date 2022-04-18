module Takara
  module UI
    module Panel
      module Inventory
        def inventory_content
          [ inventory_squares ]
        end

        def inventory_squares
          rect = panel_rect
          size = rect.w/10
          cols = ((rect.w/size).floor-1)
          rows = 4
          rgba = fade_color(rect.rgba, 0.6, 0.8)

          active_row = inventory_active_row(cols, size, rgba)
          whole_bag  = inventory_whole_bag(rows, cols, size, rgba)
          equip_row  = inventory_equip_row(size, rgba)
          
          [ active_row, whole_bag, equip_row ]
        end

        def inventory_active_row cols, size, rgba
          rect = panel_rect
          cols.times.map do |i|
            rect.merge({
              x: rect.x + 10 + ((size+4)*i),
              y: rect.y + 10,
              w: size, h: size,
              rgba: rgba
            })
          end
        end

        def inventory_whole_bag rows, cols, size, rgba
          rect = panel_rect
          rows.times.map do |i|
            cols.times.map do |j|
              rect.merge({
                x: rect.x + 10 + ((size+4)*j),
                y: rect.y + rect.h - (size*3) - 35 - ((size+4)*i),
                w: size, h: size,
                rgba: rgba
              })
            end
          end.flatten
        end

        def inventory_equip_row size, rgba
          rect = panel_rect
          7.times.map do |i|
            rect.merge({
              x: rect.x + 10 + ((size+20)*i),
              y: rect.y + rect.h - size - 35,
              w: size, h: size,
              rgba: rgba
            })
          end
        end
      end
    end
  end
end