local Players = game:GetService("Players")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local replecs = require("@game/ReplicatedStorage/Packages/replecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local cts = require("../common/component")
local replicator = require("@game/ServerScriptService/Server/controller/replicator")
local ref = require("@game/ReplicatedStorage/Shared/core/utility/ref")

local pair = jecs.pair
local reliable = replecs.Reliable
local ChildOf = jecs.ChildOf
local __ = jecs.Wildcard

local function create_health(world: jecs.World, character: Model, character_entity: jecs.Entity)
	local components = {
		ct.Health,
		cts.HealthRegenTick,

		pair(reliable, ct.Health)
	}

	jecs.bulk_insert(world, character_entity, components, { { current = 100, max = 100 }, os.clock()})
end

local function create_animator(world: jecs.World, character: Model, character_entity: jecs.Entity)
	local animator = character:QueryDescendants("Animator")[1] :: Animator?

	if not animator then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

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

	jecs.bulk_insert(world, character_entity, components, { animator, {}, { time = 0, length = 0 }, "other" })
end

local function create_character_entity(world: jecs.World, character: Model): jecs.Entity
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local humanoidrootpart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	
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

	local character_entity = ref(character)
	
	jecs.bulk_insert(world, character_entity, components, { character, character, humanoid, humanoidrootpart, 0, 0 })

	create_animator(world, character, character_entity)
	create_health(world, character, character_entity)

	replicator:set_custom(character_entity, ct.Character)

	character.Parent = workspace.entity

	return character_entity
end

return function(world: jecs.World)

	-- TODO: create a way to spawn characters
	local collect_create_character = character_lifecycle.collect_character_initialization()
	local collect_destroy_character = character_lifecycle.collect_character_destruction()

	return function()
		for character in collect_create_character do
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

			character_lifecycle.signal_character_created:Fire(character_entity :: any, character)
		end

		for character in collect_destroy_character do
			local character_entity = ref.find(character)

			if not character_entity then
				continue
			end

			world:delete(character_entity)
			character_lifecycle.signal_character_destroyed:Fire(character_entity :: any, character)
		end
	end
end