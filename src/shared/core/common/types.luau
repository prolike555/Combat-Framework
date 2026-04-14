local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local jabby = require("@game/ReplicatedStorage/Packages/jabby")

export type World = jecs.World
export type Entity<T = any> = jecs.Entity<T>
export type Id<T> = jecs.Id
export type Query<T> = jecs.Query<T>
export type Scheduler = typeof(jabby.scheduler.create())

export type AbilityType = "Custom" | "Grab" | "Attack" | "Projectile" | "MouseCombo" | "Movement"

type AbilityCallback = (world: World, player_entity: Entity, character_entity: Entity, ability_entity: Entity) -> ()

type AbilityHitboxInfo = {
	Size: Vector3,
	offset: Vector3?,
}

export type Ability = {
	cooldown: number,
	input_action: InputAction,
	
	animation: string,
	hitbox: AbilityHitboxInfo?,
	damage: number?,
	
	prerequisite: AbilityCallback?,
}

export type Moveset = {
	Abilities: { [string]: Ability },
	DefaultAnimations: DefaultAnimations,

	MaxHealth: number,
}

export type AnimationEvent = {
	time: number, 
	event: string, 
	params: { string },
}

export type DefaultAnimations = {
	idle: string,
	walk: string,
	run: string,
	jump: string,
	fall: string,
	climb: string,
	other: nil
}

export type PlayerData = {
	money: number,
	ability: string
}

return nil
