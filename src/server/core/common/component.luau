--!strict
local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local meta = jecs.meta
local Name = jecs.Name

local function initalize_component_table<T>(components: T): T
	for name, ct in components :: { [string]: jecs.Id } do
		meta(ct, Name, name)
	end

	table.freeze(components)

	return components
end

local server_components = {
	-- [[ CHARACTER ]] --
	ClonedCharacter = 		jecs.component() :: jecs.Id<Model>,
	Respawn = 				jecs.component() :: jecs.Id<{ time_of_death: number, respawn_time: number }>,
	HealthRegenTick = 		jecs.component() :: jecs.Id<number>,
	
	-- [[ MOVESET & ABILITY ]] --
	AbilityEventIndex = 	jecs.component() :: jecs.Id<number>,
	MovesetRequestSet = 	jecs.component() :: jecs.Id<string>,
	MovesetRequestRemove = 	jecs.component() :: jecs.Id<>,
	
	-- Character tags
	DoNotRespawn =			jecs.tag() :: jecs.Id,
}

return initalize_component_table(server_components)
