--!strict
local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local ct = require("@game/ReplicatedStorage/Shared/core/common/component")

type EventFunction = (world: jecs.World, ability: jecs.Entity, source: jecs.Entity, ...any) -> ()

local pair = jecs.pair

local handlers = {}

local function register(event_name: string, fn: EventFunction)
	if handlers[event_name] then
		error(`{event_name} is already registered`)
	end

	handlers[event_name] = fn
end

local function dispatch(world: jecs.World, character_entity: jecs.Entity, event_name: string, ...)
	local handler = handlers[event_name]

	if not handler then
		warn(`{event_name} is not registered`)
		return
	end

	handler(world, character_entity, ...)
end

register("hitbox", function(world: jecs.World, character_entity: jecs.Entity)
	local humanoidrootpart = world:get(character_entity, ct.HumanoidRootPart) :: BasePart
	
	local hitbox = world:entity()

	world:set(hitbox, ct.Hitbox, {
		size = Vector3.one * 5,
		cframe = humanoidrootpart.CFrame,
		duration = 0,
		start = workspace:GetServerTimeNow(),
	})
	
	world:set(hitbox, ct.HitboxIgnore, { [character_entity] = true })
	world:add(hitbox, pair(ct.OwnedBy, character_entity))
end)

return {
	register = register,
	dispatch = dispatch
}
