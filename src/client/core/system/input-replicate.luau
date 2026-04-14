-- The only purpose of this script is to replicate input to server because keyboard inputs arent replicated
-- Once they are replicated delete this, its no longer needed
local Players = game:GetService("Players")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local input = require("@game/ReplicatedStorage/Shared/controller/input")

local remote = game.ReplicatedStorage.Remote.send_input
local input_state_changed_collection = input.collect_input_actions(Players.LocalPlayer :: Player, true)

return function(world: jecs.World, dt: number)
	for _, input_key, state in input_state_changed_collection do
		remote:FireServer(input_key, state)
	end
end
