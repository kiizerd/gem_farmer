module Takara
  module World
    class Chunk
      def initialize first, seed, gradient, num, size=[16, 9]
        @size = size
        empty_blocks = get_blocks(first)

        terrain_blocks = fill_blocks(empty_blocks, seed, gradient)
        chunk_data = stringify(terrain_blocks)
        write(chunk_data, num)
      end

      def stringify chunk_data
        # chunk_data.select { |key, data| data && !data&.empty? }
        chunk_data.map do |key, data|
          [key, stringify_data_type(key, data)]
        end.to_h
      end

      def stringify_data_type type, data
        case type
        when :chunk  then Terrain.stringify_lookup(data)
        when :land   then Terrain.stringify_blocks(data)
        when :ocean  then Terrain.stringify_blocks(data)
        when :states then Terrain.stringify_state(data)
        when :types  then Terrain.stringify_types(data)
        end
      end

      def write chunk_data, num
        chunk_data.select { |key, data| data.size > 0 }
                  .map do |key, data|
          case key
          when :chunk
            $gtk.write_file("data/terrain/chunks/lookup/chunk_#{num}", data)
          when :land
            $gtk.write_file("data/terrain/chunks/island/chunk_#{num}", data)
          when :ocean
            $gtk.write_file("data/terrain/chunks/ocean/chunk_#{num}", data)
          when :states
            $gtk.write_file("data/terrain/chunks/states/chunk_#{num}", data)
          when :types
            $gtk.write_file("data/terrain/chunks/types/chunk_#{num}", data)
          end
        end

        $gtk.write_file("data/terrain/chunks/interactions/chunk_#{num}", '')
      end

      def get_blocks first_block_pos
        width, height = @size
        first_x, first_y = first_block_pos
        blocks = width.times.map do |x|
          height.times.map do |y|
            "#{first_x + x}+#{first_y + y}"
          end
        end.flatten.map { |c| c.split('+').map(&:to_i) }

        blocks
      end

      def fill_blocks empty_blocks, noise_seed, gradient
        noise = Perlin::Noise.new(2, seed: noise_seed)
        land   = []
        ocean  = []
        states = {}
        types  = {}

        chunk = empty_blocks.map do |pos|
          n = Terrain.noise_formula(noise, pos)
          n -= (gradient[pos[0]][pos[1]] * 0.9)
          n = n.round(7)

          ocean << Terrain.build_block(pos, n - 1)

          if n > $state.sea_level
            land << Terrain.build_block(pos, n)
            states[pos] = :natural
            types[pos]  = Terrain.calc_terrain_type(n)   
          end

          [pos, n]
        end.to_h
        
        {
          chunk: chunk, land: land, ocean: ocean, states: states, types: types
        }
      end
    end
  end
end