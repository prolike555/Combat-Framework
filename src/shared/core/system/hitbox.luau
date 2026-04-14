local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local ct = require("../common/component")
local ref = require("../utility/ref")

local function get_entities_from_hitbox(results: { BasePart }): { jecs.Entity }
	local entities: { jecs.Entity } = {}
	local seen: { [jecs.Entity]: boolean } = {}

	for _, part in results do
		local model = part:FindFirstAncestorOfClass("Model")
		if not model then continue end

		local entity = ref.find(model)
		if not entity then continue end

		if not seen[entity] then
			seen[entity] = true
			table.insert(entities, entity)
		end
	end

	return entities
end

return function(world: jecs.World)
	local query_hitbox = world
		:query(ct.Hitbox, ct.HitboxIgnore)
		:cached()
	
	return function(_, dt: number)
		for entity, hitbox, ignore in query_hitbox do
			local size = hitbox.size
			local cframe = hitbox.cframe
			local duration = hitbox.duration
			local start = hitbox.start
			
			local now = workspace:GetServerTimeNow()
			
			local entities_hit = get_entities_from_hitbox(workspace:GetPartBoundsInBox(cframe, size))
			local update_ignore_list = false
			
			for _, entity in entities_hit do
				if ignore[entity] then
					continue
				end
				
				ignore[entity] = true
				update_ignore_list = true
			end
			
			if update_ignore_list then
				world:set(entity, ct.HitboxIgnore, ignore)
			end
			
			if now - start > duration then
				world:delete(entity)
			end
		end
	end
end
