module Takara
  module Controllers
    class ItemController
      include Takara
      
      DataPath      = 'data/item/'
      IndexPath     = DataPath + 'item_index'
      TypeIndexPath = DataPath + 'type_index'
      
      def initialize
        if state.load_world # File.exists?('./game/data/item/')
          load_item_data_tree
        else
          create_item_data_tree
        end
      end

      def new_item name:, type:, opts:{}
        type_symbol = type.to_sym
        push_type_to_index(type_symbol) if !type_index.include?(type_symbol)

        properties = { item_type: type_symbol, item_name: name, **opts }
        item = state.new_entity :item, **properties
        
        push_item_to_index(item)
        item
      end

      def type_index
        data = gtk.read_file TypeIndexPath

        parse_type_index(data)
      end

      def item_index
        data = gtk.read_file IndexPath

        parse_item_index(data)
      end

      def item_icon item_type
        filepath = "./game/sprites/items/#{item_type.to_s}_icon.png"
        if File.exists? filepath
          spritepath = "sprites/items/#{item_type.to_s}_icon.png"
          spritebox = gtk.calcspritebox(spritepath)
          { x: 0, y: 0, w: spritebox[0], h: spritebox[1],
            path: spritepath, primitive_marker: :sprite }
        else
          { x: 0, y: 0, w: 20, h: 20, primitive_marker: :solid }
        end
      end

      private

      def create_item_data_tree
        gtk.write_file DataPath, ''
        gtk.write_file IndexPath, ''
        gtk.write_file TypeIndexPath, ''
      end

      def load_item_data_tree
      end

      def push_item_to_index new_item
        index = item_index
        index << new_item

        gtk.write_file IndexPath, stringify_item_index(index)
      end

      def push_type_to_index new_type
        index = type_index
        index << new_type

        gtk.write_file TypeIndexPath, stringify_type_index(index)
      end

      def stringify_item_index index
        index_string = index.map do |entry|
          gtk.serialize_state(entry)
        end.join('|')

        index_string
      end

      def stringify_type_index index
        index_string = index.map do |entry|
          entry.to_s
        end.join('|')

        index_string
      end

      def parse_item_index string
        string.split('|').map do |entry|
          gtk.deserialize_state(entry)
        end
      end

      def parse_type_index string
        string.split('|').map do |entry|
          entry.to_sym
        end
      end
    end
  end
end