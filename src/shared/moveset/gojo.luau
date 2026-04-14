local ReplicatedStorage = game:GetService("ReplicatedStorage")

local types = require("@game/ReplicatedStorage/Shared/core/common/types")

local DEFAULT_WALK_ANIM = 'rbxassetid://13761893084'
local DEFAULT_IDLE_ANIM = "http://www.roblox.com/asset/?id=180435571"
local DEFAULT_RUN_ANIM = 'rbxassetid://13769858822'
local DEFAULT_JUMP_ANIM = "http://www.roblox.com/asset/?id=125750702"
local DEFAULT_FALL_ANIM = "http://www.roblox.com/asset/?id=180436148"
local DEFAULT_CLIMB_ANIM = "http://www.roblox.com/asset/?id=180436334"

local play_context = ReplicatedStorage.PlayContext

local gojo_moves: types.Moveset = {
	Abilities = {
		["Lapse Blue"] = {
			animation = "rbxassetid://119175992565284",
			input_action = play_context.AttackOne,
			
			cooldown = 2,
		},
		
		["Reversal Red"] = {
			animation = "rbxassetid://139775793263214",
			input_action = play_context.AttackTwo,
			cooldown = 3,
		},
		["I'm not finished yet!"] = {
			animation = "rbxassetid://109957277442457",
			--Animation2 = "rbxassetid://75350158022697",
			input_action = play_context.AttackThree,
			
			cooldown = 2,
		},
		["Teleport Kick"] = {
			animation = "rbxassetid://115221749892627",
			input_action = play_context.AttackFour,
			cooldown = 3,
		},
	},
	
	DefaultAnimations = {
		idle = DEFAULT_IDLE_ANIM,
		walk = DEFAULT_WALK_ANIM,
		run = DEFAULT_RUN_ANIM,
		jump = DEFAULT_JUMP_ANIM,
		fall = DEFAULT_FALL_ANIM,
		climb = DEFAULT_CLIMB_ANIM,
	},
	
	MaxHealth = 80,
}

return gojo_moves
