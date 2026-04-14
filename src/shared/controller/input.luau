--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player_input_actions: { [Player]: { [string]: InputAction } } = {}

local function map_input_actions(player: Player): { [string]: InputAction }
	local play_context = player:FindFirstChildOfClass("InputContext") :: InputContext

	if not play_context then
		play_context = ReplicatedStorage.PlayContext:Clone()
		play_context.Parent = player
	end

	local input_actions = play_context:GetChildren() :: { InputAction }

	local raw_input_actions: { [string]: InputAction } = {}

	for _, action in input_actions do
		raw_input_actions[action.Name] = action
	end

	return raw_input_actions
end

local function init_player_input_actions(player: Player)
	local input_action_map = map_input_actions(player)
	player_input_actions[player] = input_action_map
	
	player.AncestryChanged:Once(function()  
		player_input_actions[player] = nil
	end)
end

local function is_input_pressed(player: Player, name: string): boolean
	local input_action_table = player_input_actions[player]
	local input_action = input_action_table[name]

	if input_action then
		return input_action.Enabled
	end

	return false
end

local function collect_input_actions(player: Player?, collect_state_changed: boolean?)
	local enqueued = {} ::  { { Player | string | boolean? } }
	local player_connection: RBXScriptConnection
	
	local i = 0

	local function enqueue_input_action(input_action: InputAction)
		local event: RBXScriptSignal = collect_state_changed and input_action.StateChanged or input_action.Pressed
		local player = (input_action.Parent :: InputContext).Parent :: Player
		
		event:Connect(function(value: boolean?) 
			table.insert(enqueued, { player, input_action.Name, value })
			i += 1
		end)
	end
	
	local function player_added(player: Player)
		if not player_input_actions[player] then
			init_player_input_actions(player)
		end
		
		for _, input_action in player_input_actions[player] do
			enqueue_input_action(input_action)
		end
	end

	local function iter(): any
		if i == 0 then
			return
		end

		i -= 1

		local args: any = table.remove(enqueued, 1)

		return unpack(args)
	end

	local function destroy()
		player_connection:Disconnect()
	end
	
	for _, player in Players:GetPlayers() do
		task.spawn(player_added, player)
	end
	
	player_connection = Players.PlayerAdded:Connect(player_added)

	return iter, destroy
end

local function initalize()
	local send_input_remote = ReplicatedStorage.Remote.send_input
	--local send_input_raw = ReplicatedStorage.Remote.send_input_raw

	if RunService:IsServer() then
		send_input_remote.OnServerEvent:Connect(function(player: Player, key: string, value: any) 
			if player_input_actions[player] and player_input_actions[player][key] then
				player_input_actions[player][key]:Fire(value)
			end
		end)
	end
end

type CollectInputActions = 
	(player: Player?, collect_state_changed: false?) -> (() -> (Player, string), RBXScriptConnection) &
	(player: Player?, collect_state_changed: true) -> (() -> (Player, string, boolean), RBXScriptConnection)

return {
	collect_input_actions = collect_input_actions :: CollectInputActions,
	is_input_pressed = is_input_pressed,
	initalize = initalize
}
