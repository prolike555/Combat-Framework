local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local ct = require("../common/component")
local collect_input = require("@game/ReplicatedStorage/Shared/controller/input")
local ref = require("../utility/ref")

local ChildOf = jecs.ChildOf
local pair = jecs.pair
local __ = jecs.Wildcard

return function(world: jecs.World)
	local enqueued_input_actions = collect_input.collect_input_actions(if RunService:IsServer() then nil else Players.LocalPlayer)

	return function()
		for player, input_key in enqueued_input_actions do
			local player_entity = ref.find(player)
			local character_entity = ref.find(player.Character)
			
			if not player_entity or not character_entity then
				continue
			end
			
			local query_abilities = world
				:query(ct.Ability, ct.InputAction)
				:without(ct.Disabled)
				:with(pair(ChildOf, character_entity))
			
			for ability_entity, ability, input_action in query_abilities do
				if input_action.Name ~= input_key then
					continue
				end
				
				--local cooldown_start = cooldown.start
				--local cooldown_length = cooldown.length
				
				--local time_now = workspace:GetServerTimeNow()
				
				--if time_now - cooldown_start < cooldown_length then
				--	continue
				--end
				
				world:add(ability_entity, ct.RequestActive)
			end
		end
	end
end

