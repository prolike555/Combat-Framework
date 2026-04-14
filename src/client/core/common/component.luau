local jecs = require("@game/ReplicatedStorage/Packages/jecs")
local replecs = require("@game/ReplicatedStorage/Packages/replecs")

local ct = require("@game/ReplicatedStorage/Shared/core/common/component")
local ref = require("@game/ReplicatedStorage/Shared/core/utility/ref")

local custom_handler = replecs.custom_handler
local meta = jecs.meta
local Name = jecs.Name

local function set_component_meta<T>(components: T)
	meta(ct.Player, custom_handler :: any, function(player: Player)
		player.AncestryChanged:Connect(function(_, parent: Instance?)
			if not parent then
				ref.delete(player)
			end
		end)
		
		return ref(player)
	end)
	
	meta(ct.Character, custom_handler :: any, function(character: Model)
		character.AncestryChanged:Connect(function(_, parent: Instance?) 
			if not parent then
				ref.delete(character)
			end
		end)
		
		return ref(character)
	end)
end

local function initalize_component_table<T>(components: T): T
	for name, ct in components :: { [string]: jecs.Id } do
		meta(ct, Name, name)
	end
	
	set_component_meta(components)

	table.freeze(components)
	
	return components
end


local client_components = {
	-- [[ MOVESET & ABILITY ]] --
	AbilityEventIndex = 		jecs.component() :: jecs.Id<number>,
	
	AbilityCurrentAnimation = 	jecs.tag()
}

return initalize_component_table(client_components)
