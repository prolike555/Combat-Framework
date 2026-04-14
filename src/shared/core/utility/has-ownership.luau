--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local ct = require("../common/component")
local ref = require("./ref")

local pair = jecs.pair

local is_server = RunService:IsServer()

return function(world: jecs.World, entity: jecs.Entity): boolean
	if is_server then
		return not world:target(entity, ct.OwnedBy)
	end
	
	local local_player_entity = ref.find(Players.LocalPlayer)

	if local_player_entity then
		return world:has(entity, pair(ct.OwnedBy, local_player_entity))
	end
		
	return world:get(entity, ct.Character) == (Players.LocalPlayer :: Player).Character
end