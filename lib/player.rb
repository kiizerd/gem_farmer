module Takara
  class Player
    include Takara

    attr_sprite
    attr_accessor :dx, :dy, :pos
    attr_reader :inventory, :held_item

    def initialize opts={}
      @x = opts.x || 632 * 2
      @y = opts.y || 352 * 2
      @w = opts.w || 16
      @h = opts.h || 16
      @rgba = opts.rgba || [145, 167, 83, 255]
      @path = opts.path || 'sprites/isometric/black.png'

      @dx = 0
      @dy = 0
      @speed = 0.4

      @pos = false

      @inventory = Takara::Container.new(:player_inventory, 45)
      shovel = state.ctrl.item.new_item(
        name: :shovel, type: :tool, opts: {
          container: :player_inv,
          durability: 250
        }
      )
      @inventory.place_item_at(0, shovel)
      @held_item = 0
    end

    def tick
      apply_deltas      
      handle_inputs
    end

    def inv
      @inventory
    end

    def spawn_at pos
      @x = pos[0]
      @y = pos[1]

      update_position
    end

    def point
      { x: @x, y: @y }
    end

    def center
      { x: @x + @w.half, y: @y + @h.half }
    end

    def next_center
      { x: @x + @dx, y: @y + @dy }
    end

    def rect
      { x: @x, y: @y, w: @w, h: @h }
    end

    def sprite
      rect.merge path: @path
    end

    def focus_point
      [ center.x + (@dx * 15), center.y + (@dy * 15) ]
    end

    def next_world_block
      next_x = center.x + (@dx*20)
      next_y = center.y + (@dy*20)
      pos = [ next_x ,next_y ]
      noise = state.world.safe_lookup(pos)
      state.world.block_from(pos, noise)
    end

    def current_world_block
      state.world.player_block
    end

    def surrounding_blocks
      state.world.blocks_around(@pos)
    end

    def possible_next_blocks
      surrounding_blocks.select do |block|
        block.noise > state.sea_level
      end.push(current_world_block)
    end

    private

    def handle_inputs
      if inputs.directional_angle
        @dx += inputs.directional_angle.vector_x * @speed
        @dy += inputs.directional_angle.vector_y * @speed
      end

      handle_number_keys
    end

    def apply_deltas
      @dx *= 0.8
      @dy *= 0.8

      @x += @dx if can_move_horz?
      @y += @dy if can_move_vert?

      @x  = @x.clamp(0, ($state.world.w - @w))
      @y  = @y.clamp(0, ($state.world.h - @h))

      update_position
    end

    def update_position
      @dx = @dx.round(5) / 1000 * 1000
      @dy = @dy.round(5) / 1000 * 1000

      @x  = @x.round(1) #(3) * 100 / 100
      @y  = @y.round(1) #(3) * 100 / 100

      @pos = [ (next_center.x / state.world.terrain_block_size[0]/2).floor,
               (next_center.y / state.world.terrain_block_size[1]/2).floor ]
    end

    def handle_number_keys
      kb = inputs.keyboard.key_down
      if kb.one
        @held_item = 0
      elsif kb.two
        @held_item = 1
      elsif kb.three
        @held_item = 2
      elsif kb.four
        @held_item = 3
      elsif kb.five
        @held_item = 4
      elsif kb.six
        @held_item = 5
      elsif kb.seven
        @held_item = 6
      elsif kb.eight
        @held_item = 7
      elsif kb.nine
        @held_item = 8
      end
    end
    
    def can_move_horz?
      x = @dx > 0 ? (@x + @dx + @w) : (@x + @dx)
      x = (x / state.world.terrain_block_size[0]/2).floor
      pos = [x, @pos[1]]

      state.world.is_land_block?(pos)
    end

    def can_move_vert?
      y = @dy > 0 ? (@y + @dy + @h) : (@y + @dy)
      y = (y / state.world.terrain_block_size[1]/2).floor
      pos = [@pos[0], y]

      state.world.is_land_block?(pos)
    end
  end
end
