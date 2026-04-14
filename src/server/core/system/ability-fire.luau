local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local cts = require("@game/ServerScriptService/Server/core/common/component")
local dispatcher = require("@game/ReplicatedStorage/Shared/controller/event-dispatch")
local server = require("@game/ServerScriptService/Server/controller/combat")

return function(world: jecs.World)
	local query_requested_active = world
		:query(ct.Ability)
		:with(ct.RequestActive)
		:cached()
	
	local query_active = world
		:query(ct.Ability, ct.AbilityEvents, ct.AbilityLength, ct.AbilityStartTime, cts.AbilityEventIndex)
		:with(ct.Active)
		:cached()
	
	return function()
		for entity, ability, events, length, start_time, event_index in query_active do
			local time_now = workspace:GetServerTimeNow()
			local current_time = time_now - start_time
			local index = event_index
			
			while index <= #events do
				local event = events[index]

				if current_time < event.time then
					break
				end
				
				local character_entity = world:parent(entity) :: jecs.Entity

				dispatcher.dispatch(world, character_entity, event.event, event.params)
				index += 1
			end
			
			if index ~= event_index then
				world:set(entity, cts.AbilityEventIndex, index)
			end
			
			if current_time >= length or world:has(entity, ct.Canceled) then
				world:remove(entity, ct.Active)
				
				local character_entity = world:parent(entity) :: jecs.Entity
				local moveset = world:get(character_entity, ct.Moveset) :: string
				
				local ability_info = server.get_ability(moveset, ability)
				local cooldown = ability_info and ability_info.cooldown or 0
				
				world:set(entity, ct.Cooldown, {
					end_time = time_now + cooldown,
					length = cooldown,
				})
				
				world:remove(entity, ct.Canceled)
			end
		end
		
		for entity, ability in query_requested_active do
			local player_entity = world:target(entity, ct.OwnedBy)
			local player = player_entity and world:get(player_entity, ct.Player)
			
			local time_called = workspace:GetServerTimeNow()
			local adjusted_time = player and server.get_adjusted_time(time_called, player) or time_called
			
			world:set(entity, ct.AbilityStartTime, adjusted_time)
			world:set(entity, cts.AbilityEventIndex, 1)
		
			world:remove(entity, ct.RequestActive)
			world:add(entity, ct.Active)
		end
	end
end

