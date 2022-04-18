module Takara
  module World
    class Terrain
      include Takara
      attr_accessor :blocks
      attr_reader :height, :width

      DataPath = 'data/terrain/'

      def initialize(world_size, sea_level)
        @size      = world_size
        @sea_level = sea_level
        @width     = world_size * 16
        @height    = world_size *  9
        terrain = generate_terrain_noise
        
        terrain_string_array = Terrain.stringify_terrain(terrain)
        Terrain.write_terrain_strings(terrain_string_array)

        state.terrain_init_finish_at = Time.new.to_i
      end

      def self.stringify_terrain terrain_array
        lookup, land, ocean, states, types = terrain_array

        lookup = Terrain.stringify_lookup(lookup)
        land   = Terrain.stringify_blocks(land)
        ocean  = Terrain.stringify_blocks(ocean)
        states = Terrain.stringify_state(states)
        types  = Terrain.stringify_types(types)
        
        [ lookup, land, ocean, states, types ]
      end

      def self.write_terrain_strings strings
        lookup, land, ocean, states, types = strings

        $gtk.write_file('data/terrain/lookup', lookup)
        $gtk.write_file('data/terrain/island', land)
        $gtk.write_file('data/terrain/ocean', ocean)
        $gtk.write_file('data/terrain/blockstates', states)
        $gtk.write_file('data/terrain/blocktypes', types)
        $gtk.write_file('data/terrain/interactions', '')
      end

      def self.stringify_blocks blocks
        size = blocks.size

        values = blocks.first.map do |key, _|
          [key, []]
        end.to_h

        blocks.each_with_index do |block, index|
          block.each do |key, value|
            values[key][index] = key == :pos ? value.join('+') : value
          end
        end

        values.map { |value_set| value_set.join('|') }.join('-|-')
      end

      def self.stringify_lookup lookup
        lookup.map { |pos, n| [pos.join('+'), n].join('=') }.join('|')
      end

      def self.stringify_state state
        state.map { |pos, s| [pos.join('+'), s].join('=') }.join('|')
      end

      def self.stringify_types types
        types.map { |pos, t| [pos.join('+'), t].join('=')  }.join('|')
      end

      def self.parse_blocks filename
        block_key  = [:x, :y, :w, :h, :r, :g, :b, :a, :pos, :type, :noise]
        raw_data   = $gtk.read_file(filename)
        block_data = raw_data.split('-|-').map { |d| d.split('|') }
        
        block_count = block_data.first.count
        block_count.times.map do |block_index|
          block_key.map_with_index do |key, key_index|
            data = block_data[key_index][block_index]
            if [ :pos, :type, :noise ].include? key
              case key
              when :pos then data = data.split('+').map(&:to_i)
              when :type then data = data.to_sym
              when :noise then data = data.to_f
              end
            else
              data = data.to_i
            end
            [key, data]
          end.to_h
        end
      end

      def self.parse_lookup filename
        raw_data = $gtk.read_file(filename)
        raw_data.split('|').map do |lookup_string|
          pos_str, noise_str = lookup_string.split('=')
          pos   = pos_str.split('+').map(&:to_i)
          noise = noise_str.to_f
          
          [pos, noise]
        end.to_h
      end

      def self.parse_state filename
        raw_data = $gtk.read_file(filename)
        raw_data.split('|').map do |state_string|
          pos_str, state_str = state_string.split('=')
          pos   = pos_str.split('+').map(&:to_i)
          state = state_str.to_sym

          [pos, state]
        end.to_h
      end
      
      def self.parse_types filename
        raw_data = $gtk.read_file(filename)
        raw_data.split('|').map do |type_string|
          pos_str, type_str = type_string.split('=')
          pos  = pos_str.split('+').map(&:to_i)
          type = type_str.to_sym

          [pos, type]
        end.to_h
      end

      ############################################################

      # Returns a single terrain block
      def self.build_block pos, noise
        # width, height = [16, 9].map { |x| x * $state.world_size }
        block_width, block_height = block_size
        #[$grid.w / width, $grid.h / height].map(&:floor)
        block_x = pos[0] * block_width
        block_y = pos[1] * block_height
        type = calc_terrain_type(noise)
        rgba = calc_terrain_rgba(noise, type)
  
        {
          x: block_x, y: block_y,
          w: block_width, h: block_height,
          r: rgba[0], g: rgba[1], b: rgba[2], a: rgba[3],
          pos: pos, type: type,
          noise: noise.round(7)
        }
      end

      def self.calc_terrain_type num
        sea_level = $state.sea_level

        case
        when num < sea_level then :ocean
        when num.between?(sea_level, sea_level + 0.05)       then :sand
        when num.between?(sea_level + 0.05, sea_level + 0.2) then :grass
        when num.between?(sea_level + 0.2, sea_level + 0.3)  then :forest
        when num.between?(sea_level + 0.3, sea_level + 0.4)  then :mntn
        else
          :snow
        end
      end

      def self.calc_terrain_sprite_path type
        case type
        when :sand then 'sprites/blocks/sand_block.png'
        end
      end

      def self.calc_terrain_rgba noise, type
        case type
        when :sand  then [194, 178, 128, 255] # Sand color
        when :grass  then [16,  182,  16, 255] # Grass color
        when :forest then [34,  139,  34, 255] # Forest color
        when :mntn   then [95,  110, 125, 255] # Mountain color
        when :snow   then [255, 255, 255, 255] # Snow color
        when :ocean  then calc_ocean_color(noise) # Ocean color
        else
          [255, 0, 255, 255] # Magenta
        end
      end

      def self.calc_ocean_color noise
        # [128, 177, 194, 255] Base Ocean color
        num = noise + ($state.sea_level / 2)
        [
          108 + (75 * num) - 75,
          157 + (55 * num) - 55,
          194 + (25 * num) - 25,
          255
        ].map(&:floor)
      end

      def self.block_size
        width, height = [16, 9].map { |x| x * $state.world_size }

        [$grid.w / width, $grid.h / height].map(&:floor)
      end

      def generate_terrain_noise
        noises   = Perlin::Noise.new 2
        gradient = calc_island_gradient
        lookup = {}
        land   = []
        ocean  = []
        states = {}
        types  = {}

        x = 0
        while x < @width
          y = 0
          while y < @height
            pos = [x, y]
            n   = terrain_noise_formula(noises, pos) - (gradient[x][y] * 0.9)
            n   = n.round(7)

            if n > @sea_level
              land << Terrain.build_block(pos, n)
              lookup[pos] = n
              states[pos] = :natural
              types[pos]  = Terrain.calc_terrain_type(n)
            end

            $state.sea_level = 1.0
            ocean << Terrain.build_block(pos, n)
            $state.sea_level = @sea_level            

            y += 1
          end
          x += 1
        end

        [ lookup, land, ocean, states, types ]
      end

      def terrain_noise_formula noises, pos
        x, y = pos
        n1 = noises[x * 0.090 + 13.7, y * 0.120 + 25.1]
        n2 = noises[x * 0.060 + 3.42, y * 0.075 + 3.71]
        n3 = noises[x * 0.120 + 46.1, y * 0.150 + 50.2]
        n4 = noises[x * 0.027 + 0.71, y * 0.034 + 0.89]
        n5 = noises[x * 0.170 + 61.9, y * 0.195 + 72.4]

        (n1 + n2 + n3 + n4 + n5) / (0.5 + 0.75 + 1 + 0.315 + 0.827)
      end

      # Generates a cirlce gradient map from the center out
      # to fade out the noise that generates the terrain and form an island
      # Returns 2D array of floats between 0.0 and 1.0
      def calc_island_gradient
        center = [$grid.w.half, $grid.h.half]
        max_x_dist = $geometry.distance([0, center[1]], center) * 0.85
        max_y_dist = $geometry.distance([center[0], 0], center) * 0.7
        max_circle_dist = $geometry.distance([0, 36], center) * 0.8
        block_width, block_height = terrain_block_size
          
        @width.times.map do |x|
          @height.times.map do |y|
            block_x = x * block_width
            block_y = y * block_width
            x_dist  = (center[0] - block_x).abs
            y_dist  = (center[1] - block_y).abs
            circle_dist = $geometry.distance(center, [block_x, block_y])            

            rhombus = (((x_dist / max_x_dist) + (y_dist / max_y_dist)) / 2).round(5)
            circle = (circle_dist / max_circle_dist).round(5)

            (rhombus + circle) / 2
          end
        end
      end
      
      #######################################
      # Old methods - keeping for reference #
      #######################################
      def terrain_blocks width=@width, height=@width
        noises   = Perlin::Noise.new 2
        gradient = calc_island_gradient        
        blocks   = Array.new(width) { Array.new(height) }
        
        x = 0
        while x < width
          y = 0
          while y < height
            n1 = noises[x * 0.090 + 13.7, y * 0.120 + 25.1]
            n2 = noises[x * 0.060 + 3.42, y * 0.075 + 3.71]
            n3 = noises[x * 0.120 + 46.1, y * 0.150 + 50.2]
            n4 = noises[x * 0.027 + 0.71, y * 0.034 + 0.89]
            n5 = noises[x * 0.170 + 61.9, y * 0.195 + 72.4]
            n = (n1 + n2 + n3 + n4 + n5) / (0.5 + 0.75 + 1 + 0.315 + 0.827)

            elevation = n - (gradient[x][y] * 0.9)
            
            blocks[x][y] ||= terrain_single_block({
              x: x, y: y,
              block_size: terrain_block_size,
              noise: elevation,
              height: elevation
            })

            y += 1
          end
          x += 1
        end

        blocks
      end

      # Returns a single terrain block with the data from the creation loop
      def terrain_single_block block
        block_width, block_height = block.block_size
        block_x = block.x * block_width
        block_y = block.y * block_height
        type = calc_terrain_type(block)
        temp = calc_terrain_temp(block, [block_x, block_y])
        rgba = calc_terrain_rgba(block, type)
  
        {
          x: block_x, y: block_y,
          w: block_width, h: block_height,
          r: rgba[0], g: rgba[1], b: rgba[2], a: rgba[3],
          pos: [block.x, block.y],
          type: type, temp: temp,
          noise: block.noise.round(7)
        }
      end

      # Returns the size of terrain blocks in pixels
      def terrain_block_size
        [$grid.w / @width, $grid.h / @height].map(&:floor)
      end

      # Determines the type of terrain based on the noise height map
      def calc_terrain_type block
        num = block.noise
        case
        when num < @sea_level then :ocean
        when num.between?(@sea_level, @sea_level + 0.05)       then :sand
        when num.between?(@sea_level + 0.05, @sea_level + 0.2) then :grass
        when num.between?(@sea_level + 0.2, @sea_level + 0.3)  then :forest
        when num.between?(@sea_level + 0.3, @sea_level + 0.4)  then :mntn
        else
          :snow
        end
      end

      # Calculates the moisture at a certain Y-level
      def calc_terrain_temp block, block_pos
        block_height  = block_pos[1]
        center_height = $grid.h.half

        (block_height - center_height).abs
      end

      def calc_terrain_rgba block, type
        # return (4.times.map { 255 * block.noise })

        case type
        when :sand  then [194, 178, 128, 255] # Sand color
        when :grass  then [16, 182, 16, 255]   # Grass color
        when :forest then [34, 139, 34, 255]   # Forest color
        when :mntn   then [95, 110, 125, 255]  # Mountain color
        when :snow   then [255, 255, 255, 255] # Snow color
        when :ocean  then calc_ocean_color(block.noise)
        else
          [255, 0, 255, 255] # Magenta
        end
      end
      
      def calc_island_gradient_old
        center = [$grid.w.half, $grid.h.half]
        max_dist = $geometry.distance([0, 36], center) * 0.8
        width, height = terrain_block_size
          
        @width.times.map do |x|
          @height.times.map do |y|
            distance = $geometry.distance(center, [x * width, y * height])
            (distance / max_dist).round(5)
          end
        end
      end
  
      # Assign ocean tile color based on distance from shore
      # Blackest at deepest depth
      def calc_ocean_color noise
        # [128, 177, 194, 255] Base Ocean color
        num = noise + (@sea_level / 2)
        [
          108 + (75 * num) - 75,
          157 + (55 * num) - 55,
          194 + (25 * num) - 25,
          255
        ].map(&:floor)
      end
    end
  end
end