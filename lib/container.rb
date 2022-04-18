module Takara
  class Container
    attr_reader :name, :size, :store

    def initialize name, size
      @name = name
      @size = size

      @store = size.times.reduce({}) do |store, i|
        store["#{i}"] = nil

        store
      end
    end

    # Returns item at indexor as a number
    # or first item with indexor as a symbol as an item name
    def [](indexor)
      if indexor.is_a? Integer
        @store[indexor.to_s]
      elsif [Symbol, String].include?(indexor.class)
        @store.find { |k, v| v.item_name == indexor }[1]
      else
        nil
      end
    end

    def remove_item_at number
      @store["#{number}"] = nil
    end

    def place_item_at number, item
      @store["#{number}"] ||= item
    end

    def index item
      of_item = @store.key(item)
    end

    def items
      @store.values.compact
    end

    def first_open_space
      @store.find { |k, v| v == nil }.first
    end

    def has_item? item_name
      item = @store.find { |k, v| v&.item_name == item_name }

      item || false
    end
  end
end