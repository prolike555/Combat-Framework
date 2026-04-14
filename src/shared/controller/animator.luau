local RunService = game:GetService("RunService")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local replecs = require("@game/ReplicatedStorage/Packages/replecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local types = require("@game/ReplicatedStorage/Shared/core/common/types")

local ChildOf = jecs.ChildOf
local pair = jecs.pair
local reliable = replecs.reliable
local relation = replecs.relation

local animation_table: { [string]: Animation } = {}

local function create_animation_instance(animation_id: string): Animation
	if not animation_table[animation_id] then
		local animation = Instance.new("Animation")
		animation.AnimationId = animation_id
		
		animation_table[animation_id] = animation
	end
	
	return animation_table[animation_id]
end

local function query_animations(world: jecs.World, character_entity: jecs.Entity, ...: jecs.Id): jecs.Query<string, AnimationTrack>
	return world
		:query(ct.AnimationId, ct.AnimationTrack)
		:with(pair(ChildOf, character_entity), ...)
end

local function stop(world: jecs.World, character_entity: jecs.Entity, animation_id: string): ()
	local animations = query_animations(world, character_entity)
	
	for entity, id, track in animations do
		if id == animation_id then
			world:delete(entity)
		end
	end
end

local function get(world: jecs.World, character_entity: jecs.Entity, animation_id: string): (AnimationTrack?, jecs.Entity?)
	local animations = query_animations(world, character_entity)

	for entity, id, track in animations do
		if id == animation_id then
			return track, entity
		end
	end

	return nil, nil
end

local function is_playing(world: jecs.World, character_entity: jecs.Entity, animation_id: string): boolean
	local track = get(world, character_entity, animation_id)

	if track and track.IsPlaying then
		return true
	end
	
	return false
end

local function play(
    world: jecs.World, 
    character: jecs.Entity, 
    id: string, 
    weight: Enum.AnimationPriority?, 
    speed: number?, 
    fade: number?
): (AnimationTrack, jecs.Entity)
	local animator = world:get(character, ct.Animator) :: Animator
	
	local animation = create_animation_instance(id)
	local track = animator:LoadAnimation(animation)

	track:AdjustSpeed(speed)
	track:AdjustWeight(weight and weight.Value, fade)

	local components = {
		ct.AnimationTrack,
		ct.AnimationId,

		pair(ChildOf, character)
		
	} :: { any }
	
	local player = world:target(character, ct.OwnedBy)
	
	if player then
		table.insert(components, pair(ct.OwnedBy, player))
	end

	if RunService:IsServer() then
		table.insert(components, pair(reliable, ct.AnimationId))
		table.insert(components, pair(relation, ChildOf))
		table.insert(components, pair(relation, ct.OwnedBy))

		table.insert(components, replecs.Networked)
	end

	local track_entity = world:entity()
	jecs.bulk_insert(world, track_entity, components, { track, id })

	return track, track_entity
end

local function set_default_animations(world: jecs.World, character_entity: jecs.Entity, animations: types.DefaultAnimations)
	world:set(character_entity, ct.JumpAnimationConfig, { length = 0.448 , time = 0})
	world:set(character_entity, ct.DefaultAnimations, animations :: { [keyof<types.DefaultAnimations>]: string })
end

return {
	play = play,
	stop = stop,
	is_playing = is_playing,
	get = get,
	set_default_animations = set_default_animations,
	create_animation_instance = create_animation_instance,
	query_animations = query_animations,
}
