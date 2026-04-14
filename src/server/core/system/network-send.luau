local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")

local replicator = require("@game/ServerScriptService/Server/controller/replicator")
local interval = require("@game/ReplicatedStorage/Shared/core/utility/interval")

local send_update = ReplicatedStorage.Remote.send_update
local send_update_unreliable = ReplicatedStorage.Remote.send_update_unreliable

return function(world: jecs.World)
    local update_interval = interval(1 / 20)
    local update_interval_unreliable = interval(1 / 30)
    
	return function()
        if update_interval() then
            local updates = replicator:collect_updates()
            
            for _, buf, variants in updates do
                send_update:FireAllClients(buf, variants)
            end
        end
        
        if update_interval_unreliable() then
            local updates = replicator:collect_unreliable()

            for _, buf, variants in updates do
                send_update_unreliable:FireAllClients(buf, variants)
            end
        end
	end
end
