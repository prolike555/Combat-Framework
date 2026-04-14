local ContextActionService = game:GetService("ContextActionService")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local jabby = require("@game/ReplicatedStorage/Packages/jabby")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local combat = require("@game/StarterPlayer/StarterPlayerScripts/Client/controller/combat")
local ref = require("@game/ReplicatedStorage/Shared/core/utility/ref")
local replicator = require("@game/StarterPlayer/StarterPlayerScripts/Client/controller/replicator")
local scheduler = require("@game/StarterPlayer/StarterPlayerScripts/Client/controller/scheduler")
local types = require("@game/ReplicatedStorage/Shared/core/common/types")

require("@game/StarterPlayer/StarterPlayerScripts/Client/core/common/component")

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

	ContextActionService:BindAction("Open Jabby", function(_, state)
		if state == Enum.UserInputState.Begin then
			local client = jabby.obtain_client()
			client.spawn_app(client.apps.home :: any, nil)
		end

        return nil
	end, false, Enum.KeyCode.F4)
end

local function startup_network_sync()
	local remote = ReplicatedStorage.Remote.receive_full
	local buf, variants, handshake = remote:InvokeServer()
	
	replicator:init(world)

	local success, err = replicator:verify_handshake(handshake)
	if not success then error(`Handshake Failed: {err}`) end
	
	replicator:apply_full(buf, variants)
end

local function start()
	initialize_debug_tools()
	startup_network_sync()
	
	combat.require_movesets()
	
	local game_modules = collect_modules({
		StarterPlayer.StarterPlayerScripts.Client.core.system,
		ReplicatedStorage.Shared.core.system,
	})

	local update_systems = create_system_runner(game_modules, scheduler)
	RunService.Heartbeat:Connect(update_systems)
end

start()