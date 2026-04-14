local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local collect = require("@game/ReplicatedStorage/Shared/core/utility/collect")
local replicator = require("@game/StarterPlayer/StarterPlayerScripts/Client/controller/replicator")

return function(world: jecs.World)
	local update_sent = collect(ReplicatedStorage.Remote.send_update.OnClientEvent)
	local update_sent_unreliable = collect(ReplicatedStorage.Remote.send_update_unreliable.OnClientEvent)

	return function()
		for _, buf, variants in update_sent do
			replicator:apply_updates(buf, variants)
		end

		for _, buf, variants in update_sent_unreliable do
			replicator:apply_unreliable(buf, variants)
		end
	end
end
