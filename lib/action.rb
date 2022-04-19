module Takara
  module Action
    include Takara
    def interact block, interaction
      block_type = $state.world.blocktypes[block.pos]
      blockstate = $state.world.blockstates[block.pos]
      action     = interaction.to_s.downcase.gsub(' ', '_').to_sym
      
      valid = false
      if blockstate == :natural
        valid = validate_interaction_by_type(block_type, action)
      else
        valid = validate_interaction_by_state(blockstate, action)
      end
      if valid
        apply_action(block, action)
      else
        # inform player about failed interaction
      end
    end

    def validate_interaction_by_type type, action
      type_action_key[type].include? action
    end

    def validate_interaction_by_state state, action
      state_action_key[state].include? action
    end

    # Hash store of actions for a certain natural block type.
    def type_action_key
      {
        sand:   [ :play_in_sand ],
        snow:   [ :play_in_snow ],
        mntn:   [ :headbutt_rock ],
        grass:  [ :clear, :gather_seeds ],
        forest: [ :clear, :gather_wood ],
      }
    end

    # Hash store of actions for a certain block state.
    def state_action_key
      {
        grown:     [ :harvest ],
        plowed:    [ :clear, :plant ],
        cleared:   [ :plow, :irrigate ],
        planted:   [ :uproot ],
        irrigated: [ :clear ],  # [:hydrate],
        gathered:  [ :nature_must_reclaim ],
        growing:   [ :water, :feed, :love, :uproot]
      }
    end

    def plant_actions; [ :water, :feed, :love, :uproot, :harvest ] end
    def gather_actions; [ :gather_wood, :gather_seeds ] end
    def generic_actions; [ :clear ] end
    def standard_actions; [ :plow, :irrigate, :plant ] end
    def empty_actions
      [
        :nature_must_reclaim,
        :play_in_snow, :play_in_sand,
        :headbutt_rock
      ]
    end

    # Applies given action to block.
    # Each unique action in the 2 hashes above should be represented here.
    def apply_action block, action
      case
      when plant_actions.include?(action)
        apply_plant_action(block, action)
      when gather_actions.include?(action)
        apply_gather_action(block, action)
      when standard_actions.include?(action)
        apply_standard_action(block, action)
      when empty_actions.include?(action)
        puts "Empty action - doing nothing"
      else
        apply_generic_action(block, action)
      end
    end

    def apply_plant_action block, action
      case action
      when :feed then feed_plant(block)
      when :love then love_plant(block)
      when :water then water_plant(block)
      when :uproot then clear_block(block)
      when :harvest then harvest_plant(block)
      else
        raise 'UnknownPlantAction'
      end
    end

    def apply_gather_action block, action
      case action
      when :gather_seeds then gather_seeds(block)
      when :gather_woods then gather_wood(block)
      else
        raise 'UnknownGatherAction'
      end
    end

    def apply_standard_action block, action
      case action
      when :plow then plow_block(block)
      when :plant then plant_block(block)
      when :irrigate then irrigate_block(block)
      else
        raise 'UnknownStandardAction'
      end
    end

    def apply_generic_action block, action
      case action
      when :clear then clear_block(block)
      else
        puts "#{action} unknown_action"
        raise 'UnknownGenericAction'
      end
    end

    ## Block Actions ##
    # Every result of the above case statement
    # calls one of these methods corresponding to the action being taken.
    # :water, :feed, :love, :uproot, :harvest
    # :gather_wood, :gather_seeds
    # :clear
    # :plow, :irrigate

    def water_plant block
    end

    def feed_plant block
    end

    def love_plant block
    end

    def uproot_plant block
    end

    def harvest_plant block
      amount = Kernel.rand(25).clamp(6, 15)
      inv = $state.player.inv
      player_has_crop = inv.items.any? { |i| i.item_name == :crop }
      crop = $game.item_ctrl.new_item(
        name: :crop, type: :gathered,
        opts: { amount: amount }
      )
      if player_has_crop
        old_crop = inv.items.find { |i| i.item_name == :crop }
        old_crop.amount += crop.amount
      else
        inv.place_item_at(inv.first_open_space, crop)
      end
      update_blockstate_at(block.pos, :gathered)
      update_interactions_at(block.pos, :gather)
    end

    def plow_block block
      update_blockstate_at(block.pos, :plowed)
      update_interactions_at(block.pos, :plow)
    end

    def clear_block block
      update_blockstate_at(block.pos, :cleared)
      update_interactions_at(block.pos, :clear)
    end

    def plant_block block
      inv = $state.player.inv
      return unless inv.has_item? :seeds
      seeds = inv[:seeds]
      seeds.amount -= 1
      
      if seeds.amount <= 0
        inv.remove_item_at(inv.index(seeds))
      end
      update_blockstate_at(block.pos, :planted)
      update_interactions_at(block.pos, :plant)
    end

    def irrigate_block block
      update_blockstate_at(block.pos, :irrigated)
      update_interactions_at(block.pos, :irrigate)
    end

    def gather_wood block
      amount = Kernel.rand(25).clamp(6, 15)
      inv = $state.player.inv
      player_has_wood = inv.items.any? { |i| i.item_name == :wood }
      wood = $game.item_ctrl.new_item(
        name: :wood, type: :gathered,
        opts: { amount: amount }
      )
      if player_has_wood
        old_wood = inv.items.find { |i| i.item_name == :wood }
        old_wood.amount += wood.amount
      else
        inv.place_item_at(inv.first_open_space, wood)
      end
      update_blockstate_at(block.pos, :gathered)
      update_interactions_at(block.pos, :gather)
    end

    def gather_seeds block
      amount = Kernel.rand(8).clamp(1, 5)
      inv = $state.player.inv
      player_has_seeds = inv.items.any? { |i| i.item_name == :seeds }
      seeds = $game.item_ctrl.new_item(
        name: :seeds, type: :gathered,
        opts: { amount: amount }
      )
      if player_has_seeds
        old_seeds = inv.items.find { |i| i.item_name == :seeds }
        old_seeds.amount += seeds.amount
      else
        inv.place_item_at(inv.first_open_space, seeds)
      end
      update_blockstate_at(block.pos, :gathered)
      update_interactions_at(block.pos, :gather)
    end

    def block_from_action pos, action_data
      block = $state.world.block_from(pos)
      action = action_data.first
      action_time = action_data.last
      path = if [ :grown, :growing, :plant ].include? action
        calc_growth_stage_sprite(action_data)
      else
        action_sprite_path[action]
      end

      block.merge({
        x: block.x*2, y: block.y*2,
        w: block.w*2, h: block.h*2,
        r: 255, g: 255, b: 255, a: 255,
        path: path
      })
    end

    def action_color
      {
        plow:     [ 55, 29, 10, 255 ],
        clear:    [ 185, 115, 66, 255 ],
        plant:    [ 75, 40, 25, 255 ],
        irrigate: [ 33, 173, 168, 255 ],
        gather:   [ 88, 168, 124, 255 ],
        growing:  [ 75, 40, 25, 255 ],
        grown:    [ 75, 40, 25, 255 ],
      }
    end

    def action_sprite_path
      {
        plow: 'sprites/blocks/plow_block.png',
        clear: 'sprites/blocks/clear_block.png',
        irrigate: 'sprites/blocks/irrigate_block.png',
      }
    end

    def calc_growth_stage_sprite plant_data
      stage = plant_data.first
      if stage == :plant
        plant_sprite_path
      elsif stage == :grown
        grown_sprite_path
      else
        growing_sprite_path(plant_data.last)
      end
    end

    def grown_sprite_path
      block_size = state.world.terrain_block_size
      outputs[:grown].w = block_size[0]
      outputs[:grown].h = block_size[1]
      outputs[:grown].sprites << {
        x: 0, y: 0, w: block_size[0], h: block_size[1],
        path: 'sprites/blocks/plow_block.png'
      }

      outputs[:grown].sprites << {
        x: 0, y: 0, w: block_size[0], h: block_size[1],
        path: 'sprites/plants/growing_2.png'        
      }

      :grown
    end

    def growing_sprite_path time_planted_at
      block_size = state.world.terrain_block_size

      lifetime = Time.now.to_i - time_planted_at + 1
      lifespan = 300
      sprite_index = (lifetime / 10).floor.clamp(0, 2)
      render_target_symbol = "growing_#{sprite_index}".to_sym

      outputs[render_target_symbol].w = block_size[0]
      outputs[render_target_symbol].h = block_size[1]
      outputs[render_target_symbol].sprites << {
        x: 0, y: 0, w: block_size[0], h: block_size[1],
        path: 'sprites/blocks/plow_block.png'
      }

      outputs[render_target_symbol].sprites << {
        x: 0, y: 0, w: block_size[0], h: block_size[1],
        path: "sprites/plants/growing_#{sprite_index}.png"
      }

      render_target_symbol
    end

    def plant_sprite_path
      block_size = state.world.terrain_block_size
      outputs[:planted].w = block_size[0]
      outputs[:planted].h = block_size[1]
      outputs[:planted].sprites << {
        x: 0, y: 0, w: block_size[0], h: block_size[1],
        path: 'sprites/blocks/plow_block.png'
      }

      outputs[:planted].sprites << {
        x: 0, y: 0, w: block_size[0], h: block_size[1],
        path: 'sprites/plants/planted.png'        
      }

      :planted
    end

    ## Data Store methods ##

    def update_blockstate_at pos, blockstate
      old_blockstates      = $state.world.blockstates
      old_blockstates[pos] = blockstate        
      blockstates_string   = old_blockstates.map do |k, v|
        [k.join('+'), v].join('=')
      end.join('|')
      $gtk.write_file('data/terrain/blockstates', blockstates_string)
      $state.world.reload_blockstates!
    end

    def remove_interaction_at pos
      $state.world.interactions.delete(pos)
    end

    def update_interactions_at pos, action
      old_interactions      = $state.world.interactions
      timein                = Time.new.to_i
      interaction           = [ action, timein ]
      old_interactions[pos] = interaction
      interactions_string   = old_interactions.map do |pos, data|
        [pos.join('+'), data.map(&:to_s).join('&')].join('=')
      end.join('|')
      $gtk.write_file('data/terrain/interactions', interactions_string)
    end

    def parse_interactions filename=false
      data = $gtk.read_file(filename || 'data/terrain/interactions') || ''
      data.split('|').map do |data_string|
        pos_str, interaction_str = data_string.split('=')
        pos = pos_str.split('+').map(&:to_i)
        interaction = interaction_str.split('&')
        action = interaction.first.to_sym
        timein = interaction.last.to_i
        [pos, [action, timein]]
      end.to_h
    end

    def timeout_key
      {
        plow:     15, #HOUR * 2,
        clear:    15, #HOUR,
        plant:    15, #MINUTE * 15,
        gather:   15, #MINUTE * 5,
        irrigate: 15, #DAY,
        growing: 30
      }
    end

    # Will search seed/plant DB table for plant at position
    # and get timeout according to plant type or whatever
    # for now.. returns 300, a 5 minute timeout
    # After this timeout, the plant will be grown
    def plant_timeout_key pos
      {

      }
    end
  end
end