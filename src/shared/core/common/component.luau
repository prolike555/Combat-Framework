local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local replecs = require("@game/ReplicatedStorage/Packages/replecs")

local types = require("./types")

local serdes = replecs.serdes
local Shared = replecs.Shared
local meta = jecs.meta
local Name = jecs.Name

local ct = {
	-- [[ CORE & ENGINE ]] --
	Renderable = 			jecs.component() :: jecs.Id<PVInstance>,
	Transform = 			jecs.component() :: jecs.Id<CFrame>,
	
	-- [[ PLAYER & CHARACTER ]] --
	Player = 				jecs.component() :: jecs.Id<Player>,
	Data = 					jecs.component() :: jecs.Id<types.PlayerData>,
	Settings = 				jecs.component() :: jecs.Id<{}>,
	Character = 			jecs.component() :: jecs.Id<Model>,
	Health = 				jecs.component() :: jecs.Id<{ current: number, max: number }>,
	Humanoid = 				jecs.component() :: jecs.Id<Humanoid>,
	HumanoidRootPart = 		jecs.component() :: jecs.Id<BasePart>,
	
	-- [[ MOVESET & ABILITY ]] --
	AbilityEvents = 		jecs.component() :: jecs.Id<{ types.AnimationEvent }>,
	AbilityLength = 		jecs.component() :: jecs.Id<number>,
	AbilityAnimation = 		jecs.component() :: jecs.Id<string>,
	AbilityStartTime = 		jecs.component() :: jecs.Id<number>,
	Moveset = 				jecs.component() :: jecs.Id<string>,
	Awakening = 			jecs.component() :: jecs.Id<{ current: number, max: number }>,
	MouseComboCounter = 	jecs.component() :: jecs.Id<number>,
	Ability = 				jecs.component() :: jecs.Id<string>,
	InputAction = 			jecs.component() :: jecs.Id<InputAction>,
	Cooldown = 				jecs.component() :: jecs.Id<{ length: number, end_time: number }>,
	
	-- [[ ANIMATION ]] --
	Animator = 				jecs.component() :: jecs.Id<Animator>,
	DefaultAnimations = 	jecs.component() :: jecs.Id<{ [keyof<types.DefaultAnimations>]: string }>,
	JumpAnimationConfig = 	jecs.component() :: jecs.Id<{ time: number, length: number }>,
	AnimationPose = 		jecs.component() :: jecs.Id<keyof<types.DefaultAnimations>>,
	AnimationId = 			jecs.component() :: jecs.Id<string>,
	AnimationTrack = 		jecs.component() :: jecs.Id<AnimationTrack>,
	
	-- [[ HITBOX ]] --
	Hitbox = 				jecs.component() :: jecs.Id<{ size: Vector3, cframe: CFrame, duration: number, start: number }>,
	HitboxIgnore =			jecs.component() :: jecs.Id<{ [jecs.Entity]: boolean }>,
	
	-- Core & Engine Tags
	Dirty = 				jecs.tag() :: jecs.Id,
	Damage = 				jecs.tag() :: jecs.Id,
	Alive = 				jecs.tag() :: jecs.Id,
	
	-- State tags
	Disabled = 				jecs.tag() :: jecs.Id,
	UsingAbility = 			jecs.tag() :: jecs.Id,	
	Canceled = 				jecs.tag() :: jecs.Id,
	
	-- Reliationship Tags
	OwnedBy = 				jecs.tag() :: jecs.Id,
	OwnedCharacter = 		jecs.tag() :: jecs.Id,
	
	-- Ability Tags
	Active = 				jecs.tag() :: jecs.Id,
	RequestActive = 		jecs.tag() :: jecs.Id,
	--Selected = 			jecs.tag() :: jecs.Id,
	
	-- Animation Tags
	RunDefaultAnimations = 	jecs.tag() :: jecs.Id,
	DefaultAnimation = 		jecs.tag() :: jecs.Id,
	IsPlaying = 			jecs.tag() :: jecs.Id,
}

local function set_component_meta<T>(components: T)
	meta(ct.Transform, serdes :: any, {
		serialize = function(transform: CFrame)
			local buf = buffer.create(12)

			buffer.writef32(buf, 0, transform.X)
			buffer.writef32(buf, 4, transform.Y)
			buffer.writef32(buf, 8, transform.Z)

			return buf
		end,

		deserialize = function(buf: buffer)
			return CFrame.new(buffer.readf32(buf, 0), buffer.readf32(buf, 4), buffer.readf32(buf, 8))
		end,

		bytespan = 12
	})
end

local function initalize_component_table<T>(components: T): T
	set_component_meta(components)
	
	for name, ct in components :: { [string]: jecs.Id } do
		meta(ct, Name, name)
		meta(ct, Shared)
	end
	
	table.freeze(components)

	return components
end

return initalize_component_table(ct)