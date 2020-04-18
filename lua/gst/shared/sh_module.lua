--[[
	Title: Modules
	
	Module meta functions and values.

	Handles creation of custom Modules and values.

]]--

GST.Modules = {} -- Used for shared storage.
GST.Modules.__newindex = function(t, k, v)
	if CLIENT then
		-- client can only read, not modify
		GST.MessagePlayer("Modules table is readonly.") -- PlayerMessage() uses "LocalPlayer()" as "ply" on client.
	end
end
GST.Modules.__metatable = false

-- Group: Enums

--[[
	Enum: DataType

	Values:

		Int - SQL Integer.
		Float - SQL Float.

]]--
GST.DataType = {
    Int = "INTEGER",
    Float = "FLOAT"
}

--[[ Local Helper Functions and Tables ]]--

-- Group: Module

--[[
	Function: Module:New

	Parameters:
		
		name - Name of the module.

	Returns:

		A Module table.

	Note:

		Must be registered with <Module:Register>
]]--
function GST.Module:New(newModule)
    assert(newModule.Name, "[GST Modules] Must specify a name for new Module.")

    self.__index = self

    return setmetatable(newModule, self)
end

--[[
	Function: Module:Register

	Registers a module table to be used.
]]--
function GST.Module:Register()
    local name = self.Name

    if modules[name] then
        GST.Error("Module " .. name .. " exists more then once!")

        return
    end

    table.insert(GST.Modules, self)
    GST.Info("Module " .. name .. " registered!")
end

--[[
	Group: Virtual Functions

	These are functions and hooks that Modules can override to have certain functionality.
	These are only defined here so that I can call them without errors.
]]--

--[[
	Function: Module:PlayerDeath

	Runs when a player dies.

	Parameters:

		vic - The victim.
		ent - The entity used to kill the victim.
		atk - The attacker.
]]--
function GST.Module:PlayerDeath(vic, ent, atk)
end

--[[
	Function: Module:PlayerTakeDamage

	Runs when a player takes damage.

	Parameters:

		vic - The victim.
		info - Information about the damage.
]]--
function GST.Module:PlayerTakeDamage(vic, info)
end

--[[
	Function: Module:PlayerSpawn

	Runs when a player spawns.

	Parameters:

		ply - The player.
]]--
function GST.Module:PlayerSpawn(ply)
end

hook.Add("PlayerDeath", "Module_PlayerDeath", function(v, e, a) 
	GST.Module:PlayerDeath(v, e, a) 
end)

hook.Add("EntityTakeDamage", "Module_EntityTakeDamage", function(v, i) 
	if v:IsPlayer() then GST.Module:PlayerTakeDamage(v, i) end 
end)

hook.Add("PlayerSpawn", "Module_PlayerSpawn", function(p) 
	GST.Module:PlayerSpawn(p) 
end)