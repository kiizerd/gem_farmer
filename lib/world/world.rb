module Takara
  module World
    class World
      include Takara
      attr_reader :x, :y, :w, :h, :blocks, :world_size, :sea_level,
                  :blockstates, :blocktypes, :interactions

      def initialize world_size, sea_level
        @x = 0
        @y = 0
        @w = 1280 * 2
        @h = 720  * 2
        @block_size = Terrain.block_size

        if !state.load_world
         generate_terrain(world_size, sea_level)
        end

        read_terrain_from_file
        state.world_init_finish_at = Time.new.to_i
      end

      def safe_lookup pos
        possible = @lookup[pos]

        possible || 0.01
      end

      def is_land_block? pos
        safe_lookup(pos) > state.sea_level
      end

      def is_ocean_block? pos
        safe_lookup(pos) < state.sea_level
      end

      def block_from pos, noise=false
        noise = noise ? noise : safe_lookup(pos)
        Terrain::build_block(pos, noise)
      end

      def mouse_block
        x, y = state.camera.mouse_pos_in_scene[0..1]
        x = (x / @block_size[0] / 2).floor
        y = (y / @block_size[1] / 2).floor
        block_data = [[x, y], safe_lookup([x, y])]

        Terrain::build_block(*block_data)
      end

      def player_block
        player = state.player
        block_data = [player.pos, safe_lookup(player.pos)]
        
        Terrain::build_block(*block_data)
      end

      def blocks_around pos
        positions_around(pos).map do |new_pos|
          block_data = [new_pos, safe_lookup(new_pos)]
          Terrain::build_block(*block_data)
        end
      end

      def positions_around pos
        [
          [pos[0] - 1, pos[1] + 1],
          [pos[0],     pos[1] + 1],
          [pos[0] + 1, pos[1] + 1],
          [pos[0] - 1, pos[1]],
          [pos[0] + 1, pos[1]],
          [pos[0] - 1, pos[1] - 1],
          [pos[0],     pos[1] - 1],
          [pos[0] + 1, pos[1] - 1]
        ]
      end

      def terrain_block_size
        @block_size
      end

      def animated_ocean
        ocean_sprite = { 
          x: -((state.tick_count % 240) - 120).abs / 6,
          y: -((state.tick_count % 240) - 120).abs / 6,
          w: grid.w + ((state.tick_count % 240) - 120).abs / 6 * 2,
          h: grid.h + ((state.tick_count % 240) - 120).abs / 6 * 2,
          path: :oceans
        }
        
        [
          ocean_sprite,
          ocean_sprite.merge(blendmode_enum: 3),
          ocean_sprite.merge({
            blendmode_enum: 2,
            r: 143, g: 185, b: 225,
            a: (((state.tick_count % 240) - 120).abs/3) + 75
          })
        ]
      end

      def reload_blockstates!
        @blockstates = Terrain.parse_state('data/terrain/blockstates')
      end

      def reload_interactions!
        @interactions = Block.parse_interactions
      end

      private

      def generate_terrain size, sea_level
        Terrain.new(size, sea_level)
      end

      def read_terrain_from_file
        land_blocks   = Terrain.parse_blocks('data/terrain/island')
        ocean_blocks  = Terrain.parse_blocks('data/terrain/ocean')
        @lookup       = Terrain.parse_lookup('data/terrain/lookup')
        @blockstates  = Terrain.parse_state('data/terrain/blockstates')
        @blocktypes   = Terrain.parse_types('data/terrain/blocktypes')
        @interactions = state.ctrl.interaction.parse_interactions
        sprite_land_blocks = blocks_as_sprites(land_blocks[1..-1])

        $outputs[:island].primitives << sprite_land_blocks
        $outputs[:oceans].solids     << ocean_blocks
      end

      def blocks_as_sprites blocks
        blocks.map do |block|
          rgba   = WHITE
          is_border = block_is_border?(block)

          if is_border && block.type != :sand            
            rgba = rgba[0..-2].map { |x| x*0.95 }.push(rgba[-1])
          end

          block.merge({
            r: rgba[0], g: rgba[1], b: rgba[2], a: rgba[3],
            primitive_marker: :sprite,
            path: "sprites/blocks/#{block.type.to_s}_block.png"
          })
        end
      end

      def block_is_border? block
        pos = block.pos
        adjacent_positions = positions_around(pos)
        adjacent_blocks = adjacent_positions.map { |p| @lookup[pos] }.compact

        type = block.type
        adjacent_blocks.any? { |n| Terrain.calc_terrain_type(n) != type }
      end
    end
  end
end
