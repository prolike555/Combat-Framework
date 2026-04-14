local Players = game:GetService("Players")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local observers = require("@game/ReplicatedStorage/Shared/core/utility/observers")
local ref = require("@game/ReplicatedStorage/Shared/core/utility/ref")
local types = require("@game/ReplicatedStorage/Shared/core/common/types")

type JumpAnimationConfig = typeof(ct.JumpAnimationConfig.__T)
type DefaultAnimation = keyof<types.DefaultAnimations>

local player = Players.LocalPlayer :: Player

local ChildOf = jecs.ChildOf
local pair = jecs.pair
local __ = jecs.Wildcard

local POSE_IDLE: DefaultAnimation = "idle"
local POSE_WALKING: DefaultAnimation = "walk"
local POSE_RUNNING: DefaultAnimation = "run"
local POSE_JUMPING: DefaultAnimation = "jump"
local POSE_FALLING: DefaultAnimation = "fall"
local POSE_CLIMBING: DefaultAnimation = "climb"

local RUN_ANIMATION_OVERRIDE_JUMP = true

local function create_animation_instance(animation_id: string): Animation
	local animation = Instance.new("Animation")
	animation.AnimationId = animation_id

	return animation
end

local function is_humanoid_airbone(humanoid: Humanoid): boolean
	return humanoid.FloorMaterial == Enum.Material.Air
end

local function get_climbing_speed(character: Model): number
	local humanoidrootpart = (character :: any).HumanoidRootPart
	return math.abs(humanoidrootpart.AssemblyLinearVelocity.Y) / 12.0
end

local function get_pose(character: Model, humanoid: Humanoid, old_pose: DefaultAnimation, jump_anim_config: JumpAnimationConfig): DefaultAnimation
	local scale = character:GetScale()
	local state = humanoid:GetState()
	
	local pose: DefaultAnimation = old_pose

	if state == Enum.HumanoidStateType.Freefall then
		if (old_pose ~= POSE_RUNNING or not RUN_ANIMATION_OVERRIDE_JUMP) and jump_anim_config.time <= 0 then
			pose = POSE_FALLING
		end
	elseif state == Enum.HumanoidStateType.Jumping then
		if old_pose ~= POSE_RUNNING or not RUN_ANIMATION_OVERRIDE_JUMP then
			pose = POSE_JUMPING
		end
	elseif state == Enum.HumanoidStateType.Running then
		local current_speed = (humanoid.MoveDirection.Magnitude / scale) * humanoid.WalkSpeed

		if current_speed > 0 then
			pose = current_speed > 16 and POSE_RUNNING or POSE_WALKING
		else
			pose = POSE_IDLE
		end
	elseif state == Enum.HumanoidStateType.Climbing then
		pose = POSE_CLIMBING
	end

	return pose
end

local function on_animator_added(world: jecs.World, entity: jecs.Entity)
	local animator = world:get(entity, ct.Animator) :: Animator
	local player_entity = world:target(entity, ct.OwnedBy) :: jecs.Entity
	
	animator.AnimationPlayed:Connect(function(animationTrack: AnimationTrack) 
		local query_animations = world
			:query(ct.AnimationTrack, ct.AnimationId)
			:with(pair(ct.OwnedBy, player_entity))
			:without(ct.IsPlaying)

		for entity, track, id in query_animations do
			local animation = track.Animation 
			
			if animation and animation.AnimationId == id and track.IsPlaying then
				world:add(entity, ct.IsPlaying)
			end
		end
	end)
end

local function on_default_animations_changed(world: jecs.World, entity: jecs.Entity)
	local player_entity = world:target(entity, ct.OwnedBy) :: jecs.Entity
	
	local animator = world:get(entity, ct.Animator) :: Animator
	local default_animations = world:get(entity, ct.DefaultAnimations) :: { [string]: string }
	
	local existing_animations = {} :: { [string]: jecs.Entity }
	local kept_animations = {} :: { [string]: boolean }
	
	local query_old_default_animations = world
		:query(ct.AnimationId)
		:with(pair(ChildOf, entity), ct.DefaultAnimation)
	
	for entity, anim_id in query_old_default_animations do
		existing_animations[anim_id] = entity
	end
	
	for _, anim_id in default_animations do
		if existing_animations[anim_id] then
			kept_animations[anim_id] = true
			continue
		end
		
		local animation = create_animation_instance(anim_id)
		local track = animator:LoadAnimation(animation)
        
		track:Stop()
		
		local components = {
			ct.AnimationTrack,
			ct.AnimationId,
			ct.DefaultAnimation,
			
			pair(ct.OwnedBy, player_entity),
			pair(ChildOf, entity),
		}
		
		jecs.bulk_insert(world, world:entity(), components, { track, anim_id })
		
		kept_animations[anim_id] = true
	end
	
	for anim_id, anim_entity in existing_animations do
		if not kept_animations[anim_id] then
			world:delete(anim_entity)
		end
	end
end

local function on_track_added(world: jecs.World, entity: jecs.Entity)
	local animation_track = world:get(entity, ct.AnimationTrack) :: AnimationTrack
	
	if not animation_track then
		local character_entity = world:parent(entity) :: jecs.Entity
		
		local animator = world:get(character_entity, ct.Animator) :: Animator
		local animation_id = world:get(entity, ct.AnimationId) :: string

		local current_playing_tracks = animator:GetPlayingAnimationTracks() :: { AnimationTrack }

		for _, track in current_playing_tracks do
			local animation = track.Animation 

			if animation and animation.AnimationId == animation_id then
				world:set(entity, ct.AnimationTrack, track)
				animation_track = track
				
				break
			end
		end
	end
	
	if animation_track then
		animation_track.Stopped:Connect(function()
			world:remove(entity, ct.IsPlaying)
		end)

		if not world:has(entity, ct.DefaultAnimation) then
			animation_track:Play()
			
			animation_track.Ended:Connect(function()
				world:delete(entity)
			end)
		end
	end
end

local function on_track_removed(world: jecs.World, entity: jecs.Entity)
	local animation_track = world:get(entity, ct.AnimationTrack)

	if animation_track then
		animation_track:Stop()
		animation_track:Destroy()
	end
end

return function(world: jecs.World)
	local player_entity = ref.find(player) :: jecs.Entity
	local player_owned_pair = pair(ct.OwnedBy, player_entity)
	
	local monitor_animator = observers.monitor(world:query(ct.Animator):with(player_owned_pair))
	local monitor_tracks = observers.monitor(world:query(ct.AnimationId, ct.AnimationTrack):with(player_owned_pair))
	
	observers.observer(world:query(ct.Animator, ct.DefaultAnimations):with(player_owned_pair), function(entity: jecs.Entity)
		on_default_animations_changed(world, entity)
	end)
	
	monitor_animator.added(function(entity: jecs.Entity) 
		on_animator_added(world, entity)
	end)
	
	monitor_tracks.added(function(entity: jecs.Entity)
		on_track_added(world, entity)
	end)
	
	monitor_tracks.removed(function(entity: jecs.Entity)
		on_track_removed(world, entity)
	end)
	
	local animator = world
		:query(ct.Character, ct.Humanoid, ct.DefaultAnimations, ct.AnimationPose, ct.JumpAnimationConfig)
		:with(ct.Animator, player_owned_pair)
		:cached()
		
	return function(_, dt: number)
		for entity, character, humanoid, default_animations, current_pose, jump_config in animator do
			if jump_config.time > 0 then
				world:set(entity, ct.JumpAnimationConfig, { 
					time = jump_config.time - dt, 
					length = jump_config.length 
				})
			end
			
			local query_default_animations = world
				:query(ct.AnimationTrack, ct.AnimationId)
				:with(pair(ChildOf, entity), ct.DefaultAnimation)

			local new_pose = get_pose(character, humanoid, current_pose, jump_config)

			local target_anim_id = default_animations[new_pose]
			local active_track: AnimationTrack?
			
			for track_entity, track, anim_id in query_default_animations do
				if anim_id == target_anim_id then
					active_track = track

					if not track.IsPlaying or new_pose ~= current_pose then
						track:Play(0.1)
					end
				elseif new_pose ~= current_pose then
					track:Stop(0.1)
				end
			end

			if new_pose ~= current_pose then
				world:set(entity, ct.AnimationPose, new_pose)
				
				if new_pose == POSE_JUMPING then
					world:set(entity, ct.JumpAnimationConfig, { 
						time = jump_config.length - dt, 
						length = jump_config.length 
					})
				end
			end

			if active_track then
				if new_pose == POSE_CLIMBING then
					active_track:AdjustSpeed(get_climbing_speed(character))
				elseif new_pose == POSE_RUNNING then
					active_track:AdjustSpeed(is_humanoid_airbone(humanoid) and 0.4 or 1)
				else
					active_track:AdjustSpeed(1)
				end
			end
		end
	end
end