local Players = game:GetService("Players")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local replecs = require("@game/ReplicatedStorage/Packages/replecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local collect = require("@game/ReplicatedStorage/Shared/core/utility/collect")
local ref = require("@game/ReplicatedStorage/Shared/core/utility/ref")
local replicator = require("@game/ServerScriptService/Server/controller/replicator")

local pair = jecs.pair
local reliable = replecs.Reliable
local relation = replecs.relation
local Networked = replecs.Networked

return function(world: jecs.World)
	local player_added = collect(Players.PlayerAdded)
	local player_removing = collect(Players.PlayerRemoving)

	return function()
		for _, player in player_added do
			local player_entity = ref(player)

			local components = {
				ct.Player,

				pair(relation, ct.OwnedCharacter),
				pair(reliable, ct.Player),
				Networked,
			}

			replicator:set_custom(player_entity, ct.Player)
			jecs.bulk_insert(world, player_entity, components, { player })
		end

		for _, player in player_removing do
			local player_entity = ref.find(player) :: jecs.Entity

			ref.delete(player)
			world:delete(player_entity)
		end
	end
end