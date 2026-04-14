local Players = game:GetService("Players")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local replecs = require("@game/ReplicatedStorage/Packages/replecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local collect = require("@game/ReplicatedStorage/Shared/core/utility/collect")
local player_store = require("@game/ServerScriptService/Server/controller/player-store")
local ref = require("@game/ReplicatedStorage/Shared/core/utility/ref")
local replicator = require("@game/ServerScriptService/Server/controller/replicator")

local pair = jecs.pair
local reliable = replecs.Reliable
local Networked = replecs.Networked

local function character_added(character: Model)
	character.Parent = workspace.entity
end

local function character_removed(world: jecs.World, character: Model)
	local character_entity = ref(character)
	local player_entity = world:target(character_entity, ct.OwnedBy) :: jecs.Entity
	
	if player_entity then
		world:remove(player_entity, pair(ct.OwnedCharacter, character_entity))
	end

	ref.delete(character)
	world:delete(character_entity)	
end

local function setup_player_entity(world: jecs.World, player: Player)
	local player_entity = ref(player)

	replicator:set_custom(player_entity, ct.Player)
	world:set(player_entity, ct.Player, player)

	local replicated = {
		pair(reliable, ct.Data),
		pair(reliable, ct.Player),
		Networked,
	}

	jecs.bulk_insert(world, player_entity, replicated, { { [player] = true } })
end

local function cleanup_player(world: jecs.World, player: Player)
	local player_entity = ref.find(player) :: jecs.Entity

	ref.delete(player)
	world:delete(player_entity)
	
	player_store:unload(player)
end

return function(world: jecs.World)
	local player_added = collect(Players.PlayerAdded)
	local player_removing = collect(Players.PlayerRemoving)

	return function()
		for _, player in player_added do
			player_store:load(player)
			
			setup_player_entity(world, player)

			if player.Character then 
				character_added(player.Character) 
			end

			player.CharacterAppearanceLoaded:Connect(character_added)
			player.CharacterRemoving:Connect(function(char) 
				character_removed(world, char) 
			end)
		end

		for _, player in player_removing do
			cleanup_player(world, player)
		end
	end
end