local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local cts = require("@game/ServerScriptService/Server/core/common/component")

local pair = jecs.pair

local HEALTH_REGEN_TICK = 1
local REGEN_RATE = 1 / 100

return function(world: jecs.World)
	local query_health_heal = world
		:query(ct.Humanoid, ct.Health, cts.HealthRegenTick)
		:with(ct.Alive)
		:without(pair(ct.Damage, ct.Health))
		:cached()

	return function(_, dt: number)
		for entity, humanoid, health, regen_tick in query_health_heal do
			local current_healh = health.current
			local max_health = health.max

			if current_healh < max_health and (os.clock() - regen_tick >= HEALTH_REGEN_TICK) then
				local heal = (REGEN_RATE + dt) * max_health
				
				world:set(entity, pair(ct.Damage, ct.Health), -heal)
				world:set(entity, cts.HealthRegenTick, os.clock())
			end
		end
	end
end
