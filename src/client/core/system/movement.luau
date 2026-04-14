local Players = game:GetService("Players")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local ref = require("@game/ReplicatedStorage/Shared/core/utility/ref")

local pair = jecs.pair

local camera = workspace.CurrentCamera :: Camera

return function(world: jecs.World)
	local player_entity = ref.find(Players.LocalPlayer) :: jecs.Entity
	
	local query_owned_character = world
		:query(ct.Character, ct.Walkspeed, ct.Jumppower, ct.Humanoid, ct.HumanoidRootPart)
		:with(pair(ct.OwnedBy, player_entity))
		:without(ct.UsingAbility)
		:cached()

	return function()
		for entity, character, walkspeed, jumppower, humanoid, humanoidrootpart in query_owned_character do
			local move_direction = humanoid.MoveDirection
			local goal_walkspeed = walkspeed
			
			local look_vector = move_direction:Dot(camera.CFrame.LookVector)
			local right_vector = move_direction:Dot(camera.CFrame.RightVector)

			if move_direction ~= Vector3.zero and math.abs(right_vector) < 0.85 and look_vector >= -0.1 then
				goal_walkspeed = walkspeed + 5
			end

			humanoid.WalkSpeed = goal_walkspeed
		end
	end
end
