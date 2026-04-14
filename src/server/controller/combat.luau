--!strict
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local types = require("@game/ReplicatedStorage/Shared/core/common/types")

type AnimationEvent = {
	time: number, 
	event: string, 
	params: { string },
}

type AnimationData = {
	events: { AnimationEvent },
	length: number,
}

type ConsolidatedMoveset = types.Moveset & {
	AnimationCache: { [string]: AnimationData }
}

local MAX_LAG_COMPENSATION = 0.25

local registry: { [string]: ConsolidatedMoveset } = {}
local is_loaded = false

local function extract_animation_ids(ability: any): { string }
	local ids = {}
	
	for _, value in ability do
		if typeof(value) == "string" then
			local numeric_id = value:match("%d+")
			
			if numeric_id and #numeric_id >= 4 then
				table.insert(ids, value)
			end
		end
	end
	
	return ids
end

local function fetch_animation_data(id: string): AnimationData?
	local success, sequence = pcall(function()
		return KeyframeSequenceProvider:GetKeyframeSequenceAsync(id) :: KeyframeSequence
	end)

	if not success or not sequence then
		warn(`[Registry] Failed to fetch: {id} | {sequence}`)
		return nil
	end

	local events: { AnimationEvent } = {}
	local length = 0
	local keyframes = sequence:GetKeyframes() :: { Keyframe }

	for _, keyframe in keyframes do
		length = math.max(length, keyframe.Time)

		for _, marker in keyframe:GetChildren() do
			if not marker:IsA("KeyframeMarker") then 
				continue
			end

			local params = {} :: { string }
			
			for _, p in marker.Value:split(",") do
				table.insert(params, p:match("^%s*(.-)%s*$") :: string) -- Trim whitespace
			end

			table.insert(events, {
				time = keyframe.Time,
				event = marker.Name:lower(),
				params = params
			})
		end
	end

	table.sort(events, function(a: AnimationEvent, b: AnimationEvent) 
		return a.time < b.time 
	end)
	
	sequence:Destroy()

	return { events = events, length = length }
end

local function require_movesets()
	local moveset_folder = ReplicatedStorage.Shared.moveset
	local modules = moveset_folder:GetChildren()
	local pending_animations = 0

	for _, module in modules do
		if not module:IsA("ModuleScript") then 
			continue 
		end

		local moveset = require(module) :: types.Moveset
		
		local name = module.Name
		registry[name] = moveset :: ConsolidatedMoveset
		registry[name].AnimationCache = {}
		
		if not moveset.Abilities then
			continue
		end

		local unique_ids = {}
		
		for _, ability in moveset.Abilities do
			for _, id in extract_animation_ids(ability) do
				unique_ids[id] = true
			end
		end

		for id in unique_ids do
			pending_animations += 1
			
			task.spawn(function()
				local data = fetch_animation_data(id)
				
				if data then
					registry[name].AnimationCache[id] = data
				end
				
				pending_animations -= 1
			end)
		end
	end

	task.spawn(function()
		while pending_animations > 0 do 
			task.wait()
		end
		
		is_loaded = true
	end)
end

local function get_moveset(name: string): ConsolidatedMoveset?
	return registry[name]
end

local function get_ability(moveset_name: string, ability_name: string): types.Ability?
	local moveset = registry[moveset_name]
	return if moveset then moveset.Abilities[ability_name] else nil
end

local function get_animation_info(id: string): AnimationData?
	for _, moveset in registry do
		if moveset.AnimationCache[id] then
			return moveset.AnimationCache[id]
		end
	end
	return nil
end

local function get_adjusted_time(marker_time: number, player: Player): number
	local compensation = math.min(player:GetNetworkPing(), MAX_LAG_COMPENSATION)
	
	return math.max(0, marker_time - compensation)
end

local function is_ready(): boolean
	return is_loaded
end

return {
	require_movesets = require_movesets,
	get_moveset = get_moveset,
	get_ability = get_ability,
	get_animation_info = get_animation_info,
	is_ready = is_ready,
	get_adjusted_time = get_adjusted_time
}