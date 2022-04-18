module Takara
  module Scene
    # Extend Takara module to give it's instance methods
    # as class methods in this module
    extend Takara

    class PropBuildError  < StandardError;  end
    class PropNameError   < PropBuildError; end
    class PropRectError   < PropBuildError; end
    class PropMarkerError < PropBuildError; end

    VALID_MARKERS = [ :solid, :sprite, :label, :line, :border ]

    # Entry point for SceneProp Api.
    # Returns a SceneProp and writes it to file.
    def self.build_prop(name: next_valid_name, marker:, opts:{}, rect: default_rect)
      return get_prop(name) if valid_prop_exists?(name)

      # puts "\n-- Building Prop --\n\n"

      raise PropNameError   unless name_valid?(name)
      raise PropMarkerError unless marker_valid?(marker)

      valid_name = validate_name(name)
      valid_rect = validate_rect(rect)
      rect_hash  = rect_to_h(valid_rect)

      prop = {
        name: name,
        x: rect_hash.x, y: rect_hash.y,
        w: rect_hash.w, h: rect_hash.h,
        primitive_marker: marker.to_sym,
      }.merge(opts)

      write_prop_as_json(prop)
      update_prop_directory(prop.name)

      prop
    end

    def self.write_prop_as_json prop
      dir = 'data/scene_props/'
      filename = dir + prop.name.to_s
      json_prop = '{ ' + prop.keys.map do |key|
        value = json_stringify(prop[key])

        "\"#{key.to_s}\": #{value}"
      end.join(', ') + ' }'

      gtk.write_file(filename + '.json', json_prop)
    end

    def self.json_stringify value
      if value.is_a? Numeric
        value
      elsif value.is_a? Array
        '[' + value.map { |v| json_stringify(v) }.join(',') + ']'
      elsif value.is_a? Hash
        '{' + value.map do |k, v|
          "\"#{k.to_s}\": #{json_stringify(v)}"
        end.join(', ') + '}'
      elsif value.is_a? Symbol
        "\":#{value}\""
      else
        "\"#{value}\""
      end
    end

    def self.prop_name_to_filename prop_name
      dir = 'data/scene_props/'

      if prop_name.to_s.split('_').first == 'noname'
        dir += 'unnamed/'
      end

      dir + prop_name.to_s + '.json'
    end

    def self.read_json_prop prop_filename
      json = gtk.read_file(prop_filename)
      json_data = json[2..-3].split(', ')
      json_data.map do |pair|
        json_key, json_value = pair.split(': ')
        key   = symbolize_json_key(json_key)
        value = actualize_json_value(json_value)

        [key, value]
      end.to_h
    end

    def self.symbolize_json_key key
      key[1..-2].to_sym
    end

    def self.actualize_json_value value
      int_codes = ('0'..'9').to_a.join.codepoints
      unquoted = value[1..-2]

      # Value is symbol
      if unquoted[0] == ':' 
        unquoted[1..-1].to_sym
      # Value is integer        
      elsif int_codes.include? value.ord
        value.to_i
      # Value is float
      elsif unquoted.chars.include? '.'
        value.to_f
      # Value is array
      elsif value&.split(',')
        value[1..-2].split(',').map { |v| actualize_json_value(v) }
      else
        value
      end
    end

    def self.validate_name name
      if name_valid?(name)
        name
      else
        valid_name = next_valid_name
        puts "\nGiven name invalid\nUsing next valid name: #{valid_name}", "\n"
        valid_name
      end
    end

    def self.next_valid_name
      dir_name = 'data/scene_props/unnamed/'
      filename = 'noname_prop_'
      file_index = 0
      data = gtk.read_file(filename + file_index.to_s)

      while data && data.size < 1
        file_index += 1
        data = gtk.read_file(filename + file_index.to_s)
      end

      'unnamed/' + filename + file_index.to_s
    end

    def self.name_valid? name
      return false unless [String, Symbol].include? name.class
      return false unless name.size >= 4
      return false if prop_name_exists?(name)
      
      true
    end

    def self.prop_name_exists? name
      filename = 'data/scene_props/' + name.to_s
      data = gtk.read_file(filename)
      data && data.size < 1
    end

    def self.validate_rect rect
      if rect_valid?(rect)
        rect
      else
        puts "\nGiven rect invalid\nUsing default: #{default_rect}", "\n"
        default_rect
      end
    end

    def self.rect_valid? rect
      return false unless [Array, Hash].include? rect.class
      return false unless rect.size == 4

      if rect.class == Array
        rect_array_valid?(rect)
      elsif rect.class == Hash
        rect_hash_valid?(rect)
      end
    end

    def self.rect_array_valid? rect
      rect.all? do |rect_value|
        rect_value.is_a? Integer
      end
    end

    def self.rect_hash_valid? rect
      [ :x, :y, :w, :h ].all? do |key|
        rect.has_key?(key) && rect[key].is_a?(Integer)
      end
    end

    def self.marker_valid? marker
      VALID_MARKERS.include? marker.to_sym
    end

    def self.rect_to_h rect
      return rect if rect.class == Hash
      
      [ :x, :y, :w, :h ].map_with_index do |key, index|
        [key, rect[index]]
      end.to_h
    end

    def self.default_rect
      { x: grid.w.half - 16, y: grid.h.half - 16, w: 32, h: 32 }
    end

    def self.get_prop prop_name
      prop_directory[prop_name].call
    end

    def self.valid_prop_exists? prop_name
      prop = ''
      begin
        prop = prop_directory[prop_name]&.call
      rescue Exception
        return false
      end

      is_valid_prop?(prop)
    end

    def self.is_valid_prop? prop
      return false unless [Array, Hash].include? prop.class
      return false unless name_valid?(prop.name)

      rect = [ prop.x, prop.y, prop.w, prop.h ]
      return false unless rect_valid?(rect)
      return false unless marker_valid?(prop.primitive_marker)

      true
    end

    def self.prop_directory
      @@prop_directory ||= {}
    end

    def self.update_prop_directory prop_name
      filename = prop_name_to_filename(prop_name)
      prop_directory[prop_name] = -> { read_json_prop(filename) }
    end
  end
end