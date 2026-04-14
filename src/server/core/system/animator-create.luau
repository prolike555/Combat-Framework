local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local replecs = require("@game/ReplicatedStorage/Packages/replecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")

local reliable = replecs.reliable
local pair = jecs.pair

local function get_animator(character: Model)
	local animator = character:QueryDescendants("Animator")[1] :: Animator?

	if not animator then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return animator
end

return function(world: jecs.World)
	local query_create_animators = world
		:query(ct.Character)
		:without(ct.Animator)
		:cached()
	
	return function()
		for entity, character in query_create_animators do
			local animator = get_animator(character)

			local components = {
				ct.Animator,
				ct.DefaultAnimations,
				ct.JumpAnimationConfig,
				ct.AnimationPose,

                pair(reliable, ct.Animator),
				pair(reliable, ct.DefaultAnimations),
				pair(reliable, ct.JumpAnimationConfig),
				pair(reliable, ct.AnimationPose)
			}

			jecs.bulk_insert(world, entity, components, { animator, {}, { time = 0, length = 0 }, "other" })
		end
	end
end
