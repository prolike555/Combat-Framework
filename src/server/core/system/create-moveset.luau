local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local replecs = require("@game/ReplicatedStorage/Packages/replecs")

local animator = require("@game/ReplicatedStorage/Shared/controller/animator")
local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local cts = require("@game/ServerScriptService/Server/core/common/component")
local combat = require("@game/ServerScriptService/Server/controller/combat")
local types = require("@game/ReplicatedStorage/Shared/core/common/types")

local ChildOf = jecs.ChildOf
local pair = jecs.pair
local reliable = replecs.Reliable
local relation = replecs.relation
local Networked = replecs.Networked
local __ = jecs.Wildcard

local function get_player_play_context_actions(player: Player): { [string]: InputAction }
	local play_context = player:FindFirstChild("PlayContext")
	assert(play_context, `{player.Name} does not have a play context`)
	
	local input_actions = {} :: { [string]: InputAction }
	
	for _, action in play_context:GetChildren() do
		if action:IsA("InputAction") then
			input_actions[action.Name] = action
		end
	end
	
	return input_actions
end

local function create_moveset(world: jecs.World, character_entity: jecs.Entity, name: string)
	local components = {
		ct.Moveset,
		ct.Awakening,
		ct.MouseComboCounter,

		pair(reliable, ct.Awakening),
		pair(reliable, ct.Moveset),
		pair(reliable, ct.MouseComboCounter)
	}
	
	jecs.bulk_insert(world, character_entity, components, { name, { current = 0, max = 100 }, 1 })
end

local function remove_moveset(world: jecs.World, entity: jecs.Entity)
	local components = {
		ct.Moveset,
		ct.Awakening,
		ct.MouseComboCounter,

		pair(reliable, ct.Awakening),
		pair(reliable, ct.Moveset),
		pair(reliable, ct.MouseComboCounter)
	}
	
	jecs.bulk_remove(world, entity, components)
	
	for ability_entity in world:query(ct.Ability):with(pair(ChildOf, entity)) do
		world:delete(ability_entity)
	end
end

local function create_ability_entity(world: jecs.World, name: string)
	local components = {
		ct.Ability,
		
		pair(reliable, ct.Ability),
		pair(reliable, ct.Cooldown),

		pair(reliable, ct.Active),
		pair(reliable, ct.Disabled),
		pair(relation, ChildOf),
		
		Networked
	}
	
	local entity = world:entity()
	jecs.bulk_insert(world, entity, components, { name })
	
	return entity
end

local function initalize_ability_entities(world: jecs.World, character_entity: jecs.Entity, abilities: { [string]: types.Ability })
	local player_entity = world:target(character_entity, ct.OwnedBy)
	local input_actions: { [string]: InputAction }

	if player_entity then
		input_actions = get_player_play_context_actions(world:get(player_entity, ct.Player) :: Player)
	end
	
	for name, ability in abilities do
		local ability_entity = create_ability_entity(world, name)
		local input_action_name = ability.input_action.Name

		if player_entity then
			local components = {
				ct.InputAction,

				pair(ct.OwnedBy, player_entity),

				pair(reliable, ct.InputAction),
				pair(relation, ct.OwnedBy),
			}

			jecs.bulk_insert(world, ability_entity, components, { input_actions[input_action_name] })
		end
		
		local animation_data = combat.get_animation_info(ability.animation)
		
		if not animation_data then
			continue
		end
		
		local components = {
			ct.AbilityEvents,
			ct.AbilityLength,
			ct.AbilityAnimation,
			ct.AbilityStartTime,
		
			cts.AbilityEventIndex,
			
			pair(reliable, ct.AbilityEvents),
			pair(reliable, ct.AbilityLength),
			pair(reliable, ct.AbilityAnimation),
			pair(reliable, ct.AbilityStartTime),
			pair(reliable, ct.Cooldown),

			pair(ChildOf, character_entity)
		}
		
		local events = animation_data.events
		local length = animation_data.length
		local anim_id = ability.animation
		
		jecs.bulk_insert(world, ability_entity, components, { events, length, anim_id, -1, 1 })
	end
end

return function(world: jecs.World)
	local query_create_moveset = world
		:query(ct.Character, cts.MovesetRequestSet)
		:with(ct.Animator, ct.Alive)
		:cached()
	
	local query_remove_moveset = world
		:query(ct.Character)
		:with(ct.Animator, ct.Alive, cts.MovesetRequestRemove)
		:cached()
	
	return function()
		for entity, character, moveset_name in query_create_moveset do
			local current_moveset = world:get(entity, ct.Moveset)
			
			if current_moveset then
				if current_moveset == moveset_name then
					world:remove(entity, cts.MovesetRequestSet)
					continue
				end
				
				remove_moveset(world, entity)
			end
			
			local moveset_info = combat.get_moveset(moveset_name)
			
			if not combat.is_ready() or not moveset_info then
				continue
			end
			
			create_moveset(world, entity, moveset_name)
			initalize_ability_entities(world, entity, moveset_info.Abilities)
			
			world:set(entity, pair(ct.Dirty, ct.Health), { max = moveset_info.MaxHealth })
			animator.set_default_animations(world, entity, moveset_info.DefaultAnimations)
			
			world:remove(entity, cts.MovesetRequestSet)
		end
		
		for entity, character in query_remove_moveset do
			remove_moveset(world, entity)
			world:remove(entity, cts.MovesetRequestRemove)
		end
	end
end
