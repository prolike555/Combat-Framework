local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local ct = require("@game/ReplicatedStorage/Shared/core/common/component")

return function(world: jecs.World)
	local query_cooldowns = world
		:query(ct.Cooldown)
		:cached()
	
	return function()
		local time_now = workspace:GetServerTimeNow()
		
		for entity, cooldown in query_cooldowns do
			local end_time = cooldown.end_time
			
			if end_time > time_now then
				continue
			end
			
			world:remove(entity, ct.Cooldown)
		end
	end
end