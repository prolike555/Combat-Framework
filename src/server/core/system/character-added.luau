local Players = game:GetService("Players")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local replecs = require("@game/ReplicatedStorage/Packages/replecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local cts = require("@game/ServerScriptService/Server/core/common/component")
local collect = require("@game/ReplicatedStorage/Shared/core/utility/collect")
local replicator = require("@game/ServerScriptService/Server/controller/replicator")
local ref = require("@game/ReplicatedStorage/Shared/core/utility/ref")

local pair = jecs.pair
local reliable = replecs.Reliable
local ChildOf = jecs.ChildOf
local __ = jecs.Wildcard

local function create_character_entity(world: jecs.World, character: Model): jecs.Entity
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local humanoidrootpart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	
	assert(humanoid, "character must have a humanoid")
	assert(humanoidrootpart, "character must have a humanoidrootpart")
	
	local components = {
		ct.Renderable,
		ct.Character,
		ct.Humanoid,
		ct.HumanoidRootPart,
		ct.Walkspeed,
		ct.Jumppower,
		ct.Alive,
		
		pair(reliable, ct.Renderable),
		pair(reliable, ct.Character),
		pair(reliable, ct.Humanoid),
		pair(reliable, ct.HumanoidRootPart),
		pair(reliable, ct.Walkspeed),
		pair(reliable, ct.Jumppower),
		pair(reliable, ct.Alive),
		
		replecs.Networked,
	}

	local entity = ref(character)
	
	jecs.bulk_insert(world, entity, components, { character, character, humanoid, humanoidrootpart, 0, 0 })
	replicator:set_custom(entity, ct.Character)

	character.Parent = workspace.entity

	return entity
end

local function initalize_existing_characters(world: jecs.World)
	for _, character in workspace.entity:GetChildren() do
		create_character_entity(world, character :: Model)
	end
end

return function(world: jecs.World)
	local entity_folder_child_added = collect(workspace.entity.ChildAdded)
	
	initalize_existing_characters(world)

	return function()
		for _, character in entity_folder_child_added do
			local character_entity = create_character_entity(world, character :: Model)
			local player_entity = ref.find(Players:GetPlayerFromCharacter(character :: Model))
			
			if not player_entity then
				continue
			end
				
			local components = {
				pair(ChildOf, player_entity),
				pair(ct.OwnedBy, player_entity),
				pair(replecs.relation, ChildOf),
				pair(replecs.relation, ct.OwnedBy)
			}

			jecs.bulk_insert(world, character_entity, components, {})
			world:add(player_entity, pair(ct.OwnedCharacter, character_entity))
			
			local player_data = world:get(player_entity, ct.Data)
			
			if player_data then
				world:set(character_entity, cts.MovesetRequestSet, player_data.ability)
			end
		end
	end
end