--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local jabby = require("@game/ReplicatedStorage/Packages/jabby")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local replicator = require("@game/ServerScriptService/Server/controller/replicator")
local ref = require("@game/ReplicatedStorage/Shared/core/utility/ref")
local combat = require("@game/ServerScriptService/Server/controller/combat")
local scheduler = require("@game/ServerScriptService/Server/controller/scheduler")
local player_store = require("@game/ServerScriptService/Server/controller/player-store")
local types = require("@game/ReplicatedStorage/Shared/core/common/types")

require("@game/ServerScriptService/Server/core/common/component")

type SystemData = {
	id: number, 
	system: (...any) -> () 
}

local world = jecs.world()

local function get_entity_from_part(part: BasePart): (jecs.Entity<any>?, PVInstance?)
	for id, model in world:query(ct.Renderable) do
		if part:IsDescendantOf(model) then
			return id, model
		end
	end
	return nil, nil
end

local function register_system(module: ModuleScript, scheduler: types.Scheduler, ...): SystemData
	local fn = require(module) :: (...any) -> ()
	local system = fn(...) or fn

	local system_id = scheduler:register_system({
		name = module.Name,
		module = module,
	})

	return { system = system, id = system_id }
end

local function create_system_runner(modules: { ModuleScript }, scheduler: types.Scheduler)
	local systems = {} :: { SystemData }

	for i, module in modules do
		systems[i] = register_system(module, scheduler, world, 0)
	end

	return function(dt: number)
		for _, config in systems do
			scheduler:run(config.id, config.system, world, dt)
		end
	end
end

local function collect_modules(folders: {Instance}): { ModuleScript }
	local modules = {}
	for _, folder in folders do
		for _, child in folder:GetChildren() do
			if not child:IsA("ModuleScript") then
				continue
			end

			table.insert(modules, child)
		end
	end
	return modules
end

local function initialize_debug_tools()
	ref.world(world)

	jabby.register({
		applet = jabby.applets.world,
		name = "World",
		configuration = {
			world = world,
			get_entity_from_part = get_entity_from_part,
		}
	} :: any)
end

local function startup_network_sync()
	replicator:init(world)
	
	local remote = ReplicatedStorage.Remote.receive_full
	
	remote.OnServerInvoke = function(player: Player)
		replicator:mark_player_ready(player)

		local handshake = replicator:generate_handshake()
		local buf, variants = replicator:get_full(player)

		return buf, variants, handshake
	end
end

local function start()
	initialize_debug_tools()
	startup_network_sync()
	
	player_store:initialize(world)

	local game_modules = collect_modules({
		ServerScriptService.Server.core.system,
		ReplicatedStorage.Shared.core.system
	})

	local update_systems = create_system_runner(game_modules, scheduler)
	RunService.Heartbeat:Connect(update_systems)
	
	combat.require_movesets()
end

start()