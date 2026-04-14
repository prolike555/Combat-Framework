local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local animator = require("@game/ReplicatedStorage/Shared/controller/animator")
local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local ctc = require("@game/StarterPlayer/StarterPlayerScripts/Client/core/common/component")
local dispatcher = require("@game/ReplicatedStorage/Shared/controller/event-dispatch")

local pair = jecs.pair
local __ = jecs.Wildcard

return function(world: jecs.World)
	local query_active = world
		:query(ct.Ability, ct.AbilityEvents, ct.AbilityStartTime, ctc.AbilityEventIndex)
		:with(ct.Active, pair(ctc.AbilityCurrentAnimation, __))
		:cached()
	
	local query_requested = world
		:query(ct.Ability, ct.AbilityAnimation)
		:with(ct.RequestActive)
		:cached()

	return function()
		for entity, ability, events, start_time, event_index in query_active do
			local now = workspace:GetServerTimeNow() - start_time
			local index = event_index
			
			while index <= #events do
				local event = events[index]

				if now < event.time then
					break
				end

				local character_entity = world:parent(entity) :: jecs.Entity

				dispatcher.dispatch(world, character_entity, event.event, event.params)
				index += 1
			end

			if index ~= event_index then
				world:set(entity, ctc.AbilityEventIndex, index)
			end
		end
		
		for entity, ability, animation in query_requested do
			local character_entity = world:parent(entity) :: jecs.Entity
			
			local now = workspace:GetServerTimeNow()

			animator.stop(world, character_entity, animation)

			local _, animation_entity = animator.play(world, character_entity, animation)

			world:set(entity, ctc.AbilityEventIndex, 1)
			world:set(entity, ct.AbilityStartTime, now)
			world:add(entity, pair(ctc.AbilityCurrentAnimation, animation_entity))
			
			world:remove(entity, ct.RequestActive)
		end
	end
end

