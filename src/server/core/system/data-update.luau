local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local cts = require("@game/ServerScriptService/Server/core/common/component")
local ref = require("@game/ReplicatedStorage/Shared/core/utility/ref")

local pair = jecs.pair

return function(world: jecs.World)
	local query_updated_data = world
		:query(ct.Player, ct.Data, pair(ct.Dirty, ct.Data))
		:cached()
	
	return function()
		for entity, player, data, dirty_data in query_updated_data do
			if data.ability ~= dirty_data.ability then
				local character_entity = ref.find(player.Character)
				
				if character_entity then
					world:set(character_entity, cts.MovesetRequestSet, data.ability)
				end
			end
			
			world:remove(entity, pair(ct.Dirty, ct.Data))
		end
	end
end