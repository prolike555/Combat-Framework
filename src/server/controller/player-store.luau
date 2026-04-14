local Players = game:GetService("Players")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local lyra = require("@game/ReplicatedStorage/Packages/lyra")
local t = require("@game/ReplicatedStorage/Packages/t")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local observe = require("@game/ReplicatedStorage/Shared/core/utility/observers")
local ref = require("@game/ReplicatedStorage/Shared/core/utility/ref")
local types = require("@game/ReplicatedStorage/Shared/core/common/types")

local pair = jecs.pair

type ExtendedPlayerStore = PlayerStore & {
	world: jecs.World,
	initialize: (self: ExtendedPlayerStore, world: jecs.World) -> (),
}

local PLAYER_STORE_NAME = "Fighting Game LOLL"
local PLAYER_STORE_TEMPLATE: types.PlayerData = {
	money = 100,
	ability = "gojo",
}

local PLAYER_STORE_SCHEMA = t.strictInterface({
	money = t.number,
	ability = t.string,
})

local player_store: ExtendedPlayerStore

local function on_data_changed(key: string, new: types.PlayerData, old: types.PlayerData?)
	local world = player_store.world
	if not world then return end

	local player_id = tonumber(key)
	if not player_id then return end

	local player = Players:GetPlayerByUserId(player_id)
	if not player then return end

	local player_entity = ref.find(player)
	
	if player_entity and not world:has(player_entity, ct.Data) then
		world:set(player_entity, ct.Data, new)
		world:set(player_entity, pair(ct.Dirty, ct.Data), {})
	end
end

local function setup_observers(extended: ExtendedPlayerStore)
	local world = extended.world

	observe.observer(world:query(ct.Data, ct.Player), function(entity: jecs.Entity) 
		local current_data = world:get(entity, ct.Data) :: types.PlayerData
		local player = world:get(entity, ct.Player) :: Player

		extended:update(player, function(data: types.PlayerData)
			local schema_ok, err = PLAYER_STORE_SCHEMA(current_data :: any)

			if schema_ok then
				if not world:has(entity, pair(ct.Dirty, ct.Data)) then
					world:set(entity, pair(ct.Dirty, ct.Data), data)
				end
				
				data = current_data
				
				return true 
			end

			warn(`[PlayerStore] Invalid data for player {player.Name}: {err}`)
			world:set(entity, ct.Data, data)
			
			return false
		end)
	end)
end

local base_store = lyra.createPlayerStore({
	name = PLAYER_STORE_NAME,
	template = PLAYER_STORE_TEMPLATE,
	schema = PLAYER_STORE_SCHEMA,
	changedCallbacks = { on_data_changed }
})

type PlayerStore = typeof(base_store)

player_store = setmetatable({
	world = nil :: any,
}, { __index = base_store }) :: ExtendedPlayerStore

function player_store:initialize(world: jecs.World)
	if self.world then return end
	self.world = world

	setup_observers(self)

	game:BindToClose(function()
		self:closeAsync()
	end)
end

return player_store 