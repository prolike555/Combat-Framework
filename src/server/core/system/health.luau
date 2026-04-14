local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local replecs = require("@game/ReplicatedStorage/Packages/replecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local cts = require("@game/ServerScriptService/Server/core/common/component")

local pair = jecs.pair
local reliable = replecs.Reliable

return function(world: jecs.World)
	local query_no_health = world
		:query(ct.Character)
		:without(ct.Health)
		:cached()
	
	local query_health_damage = world
		:query(ct.Humanoid, ct.Health, pair(ct.Damage, ct.Health))
		:with(ct.Alive)
		:cached()
	
	local query_health_update = world
		:query(ct.Humanoid, ct.Health, pair(ct.Dirty, ct.Health))
		:with(ct.Alive)
		:cached()
	
	return function(_, dt: number)
		for entity in query_no_health do
			world:set(entity, ct.Health, { current = 100, max = 100 })
			world:set(entity, cts.HealthRegenTick, os.clock())
			
			world:add(entity, pair(reliable, ct.Health))
		end
		
		for entity, humanoid, health, damage in query_health_damage do
			local current_health = health.current
			local max_health = health.max
			
			local new_health = math.clamp(current_health - damage, 0, max_health)
			
			world:set(entity, ct.Health, {
				current = new_health,
				max = max_health
			})
			
			humanoid.Health = new_health
			
			if new_health == 0 then
				world:remove(entity, ct.Alive)
			end
			
			world:remove(entity, pair(ct.Damage, ct.Health))
		end
		
		for entity, humanoid, health, update in query_health_update do
			local new_health_raw = update.current :: number?
			local new_max_health = update.max :: number?

			local current_max = new_max_health or health.max
			
			if new_max_health then
				world:set(entity, ct.Health, {
					current = math.min(health.current, new_max_health),
					max = new_max_health
				})
				
				humanoid.MaxHealth = new_max_health
			end

			if new_health_raw then
				local clamped_health = math.clamp(new_health_raw, 0, current_max)

				world:set(entity, ct.Health, {
					current = clamped_health,
					max = current_max
				})
				
				humanoid.Health = clamped_health
			end
			
			world:remove(entity, pair(ct.Dirty, ct.Health))
		end
	end
end
