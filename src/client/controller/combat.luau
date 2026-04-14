--!strict
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local animator = require("@game/ReplicatedStorage/Shared/controller/animator")
local types = require("@game/ReplicatedStorage/Shared/core/common/types")

type AnimationData = {
	ids: { string }
}

type ConsolidatedMoveset = types.Moveset & {
	animation_cache: { [string]: AnimationData }
}

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

local function require_movesets()
	local folder = ReplicatedStorage.Shared.moveset
	local modules = folder:GetChildren()
	local animation_instances = {}

	for _, module in modules do
		if not module:IsA("ModuleScript") then continue end

		local moveset = require(module) :: types.Moveset
		local name = module.Name

		registry[name] = moveset :: ConsolidatedMoveset
		registry[name].animation_cache = {}

		if not moveset.Abilities then continue end

		local unique_ids = {}

		for _, ability in moveset.Abilities do
			for _, id in extract_animation_ids(ability) do
				unique_ids[id] = true
			end
		end

		for id in unique_ids do
			registry[name].animation_cache[id] = {
				ids = { id }
			}

			table.insert(animation_instances, animator.create_animation_instance(id))
		end

		local defaults = moveset.DefaultAnimations or {}

		for _, id in defaults do
			table.insert(animation_instances, animator.create_animation_instance(id))
		end
	end

	task.spawn(function()
		ContentProvider:PreloadAsync(animation_instances)
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

local function get_animation_ids(moveset_name: string, ability_name: string): { string }
	local ability = get_ability(moveset_name, ability_name)
	if not ability then return {} end

	return extract_animation_ids(ability)
end

local function get_animation_id(moveset_name: string, ability_name: string): string?
	local ids = get_animation_ids(moveset_name, ability_name)
	
	if ids then
		return ids[1]
	end

	return nil
end

local function is_ready(): boolean
	return is_loaded
end

return {
	require_movesets = require_movesets,
	get_moveset = get_moveset,
	get_ability = get_ability,
	get_animation_id = get_animation_id,
	is_ready = is_ready
}