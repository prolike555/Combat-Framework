local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local cts = require("@game/ServerScriptService/Server/core/common/component")
local ref = require("@game/ReplicatedStorage/Shared/core/utility/ref")
local respawn_times = require("@game/ServerScriptService/Server/core/common/respawn-times")

local pair = jecs.pair
local __ = jecs.Wildcard

return function(world: jecs.World)
	local query_respawn = world
		:query(ct.Character, cts.Respawn)
		:without(ct.Alive, cts.DoNotRespawn)
		:cached()
	
	local query_create_respawn = world
		:query(ct.Character)
		:without(pair(ct.OwnedBy, __), cts.Respawn)
		:cached()
	
	return function()
		for entity, character in query_create_respawn do
			local respawn_time = respawn_times[character.Name]
			
			if not respawn_time then
				world:add(entity, cts.DoNotRespawn)
				continue
			end
			
			world:set(entity, cts.ClonedCharacter, character:Clone())
			world:set(entity, cts.Respawn, { time_of_death = -1, respawn_time = respawn_time })
		end

		for entity, character, respawn_info in query_respawn do
			local respawn_time = respawn_info.respawn_time
			local time_of_death = respawn_info.time_of_death

			if time_of_death == -1 then
				world:set(entity, cts.Respawn, { 
					time_of_death = os.clock(),
					respawn_time = respawn_time
				})
				continue
			end
			
			if os.clock() - time_of_death <= respawn_time then
				continue
			end

			local cloned_character = world:get(entity, cts.ClonedCharacter) :: Model

			ref.delete(character)
			world:delete(entity)
				
			character:Destroy()
				
			cloned_character.Parent = workspace.entity
		end
	end
end
