--[[
	Title: Modules
	
	Module meta functions and values.

	Handles creation of custom Modules and values.

]]--

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

-- List of all Modules and Data Values, we only need these here
local modules = {}
local datavalues = {}
local weapondatavalues = {}

-- Registers data value into the database
local function _registerDataValue(key, module, type, desc, displayname)
    type = type or GST.DataType.Int
    desc = desc or "No Description Set"
    displayname = displayname or key
    local Q = GST.DataProvider:query(string.format([[IF NOT EXISTS (
										SELECT
											*
										FROM
											gst_master
										WHERE
											COLUMN_NAME = '%s')
										ALTER TABLE gst_master
											ADD %s %s NULL
										END;]], key, key, type))

    function Q:onSuccess(data)
        GST.Info("Value " .. key .. " added successfully!")
    end

    function Q:onError(err, sql)
        GST.Error("Failed in adding value " .. key .. " : " .. err .. " (" .. sql .. ")")
    end

    datavalues[key] = {
        Module = module,
        Desc = desc,
        Displayname = displayname,
        Type = type
    }
end

-- Registers data value into every weapon table
local function _registerWeaponDataValue(key, module, type, desc, displayname)
    type = type or GST.DataType.Int
    desc = desc or "No Description Set"
    displayname = displayname or key
    weps = weapons.GetList()
    local Q

    for _, wep in ipairs(weps) do
        Q = GST.DataProvider:query(string.format([[IF NOT EXISTS (
											SELECT
												*
											FROM
												gst_%s
											WHERE
												COLUMN_NAME = '%s')
											ALTER TABLE gst_%s
												ADD %s %s NULL
											END;]], wep, key, wep, key, type))

        function Q:onSuccess(data)
            GST.Info("Weapon value " .. key .. " added successfully!")
        end

        function Q:onError(err, sql)
            GST.Error("Failed in adding weapon value " .. key .. " : " .. err .. " (" .. sql .. ")")
        end
    end

    weapondatavalues[key] = {
        Module = module,
        Desc = desc,
        Displayname = displayname,
        Type = type
    }
end

-- Group: Module
GST.Module = {}
GST.Module.Name = ""
GST.Module.DisplayName = ""
GST.Module.Description = ""
GST.Module.Version = ""
GST.Module.Author = ""
GST.Module.Gamemode = ""
GST.Module.Enabled = true


--[[
	Function: Module:New

	Parameters:
		
		name - Name of the module.

	Returns:

		A Module table.

	Note:

		Must be registered with <Module:Register>
]]--
function GST.Module:New(name)
    newModule = {
        Name = name
    }

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

    table.insert(modules, self)
    GST.Info("Module " .. name .. " registered!")
end

--[[
	Function: EnableModule

	Enables the given module

	Parameters:
		
		name - Name of the module.
]]--
function GST.EnableModule(name)
    modules[name].Enabled = true
end

--[[
	Function: DisableModule

	Disables the given module

	Parameters:
		
		name - Name of the module.
]]--
function GST.DisableModule(name)
    modules[name].Enabled = false
end

--[[
	Function: ToggleModule

	Parameters:
		
		name - Name of the module.

	Toggles the given module
]]--
function GST.ToggleModule(name)
    modules[name].Enabled = not modules[name].Enabled
end

--[[
	Function: GetModule

	Parameters:
		
		name - Name of the module.

	Returns:

		The specified module, if it exists.
]]--
function GST.GetModule(name)
    return modules[name]
end

--[[
	Function: GetModules

	Returns:

		A table containing all modules.
]]--
function GST.GetModules()
    return modules
end

-- Group: Data Values

--[[
	Function: Module:DataValue

	Parameters:

		name - The internal name of the data value.
		type - The type of the data value, see <DataType>.
		val - Default value.
		desc - Description used in the GUI.
		displayname - Pretty name used in the GUI.

	Adds a data value specific to the module.
]]--
function GST.Module:DataValue(name, type, desc, displayname)
    _registerDataValue(name, self.Name, type, desc, displayname)
end

--[[
	Function: MiscDataValue

	Parameters:

		name - The internal name of the data value.
		type - The type of the data value, see <DataType>.
		val - Default value.
		desc - Description used in the GUI.
		displayname - Pretty name used in the GUI.

	Adds a data value, not specific to any module.
]]--
function GST.MiscDataValue(name, type, desc, displayname)
    _registerDataValue(name, "Misc", type, desc, displayname)
end

--[[
	Function: Module:WeaponDataValue

	Parameters:

		name - The internal name of the data value.
		type - The type of the data value, see <DataType>.
		val - Default value.
		desc - Description used in the GUI.
		displayname - Pretty name used in the GUI.

	Adds a weapon data value specific to the module.
]]--
function GST.Module:WeaponDataValue(name, type, desc, displayname)
    _registerWeaponDataValue(name, self.Name, type, desc, displayname)
end

--[[
	Function: MiscWeaponDataValue

	Parameters:

		name - The internal name of the data value.
		type - The type of the data value, see <DataType>.
		val - Default value.
		desc - Description used in the GUI.
		displayname - Pretty name used in the GUI.

	Adds a weapon data value, not specific to any module.
]]--
function GST.MiscWeaponDataValue(name, type, desc, displayname)
    _registerWeaponDataValue(name, "Misc", type, desc, displayname)
end

--[[
	Function: GetDataValue

	Parameters:
		
		name - Name of the data value.

	Returns:

		The specified data value, if it exists.
]]--
function GST.GetDataValue(name)
    return datavalues[name]
end

--[[
	Function: GetDataValues

	Returns:

		A table containing all data values.
]]--
function GST.GetDataValues()
    return datavalues
end

--[[
	Function: GetWeaponDataValue

	Parameters:
		
		name - Name of the data value.

	Returns:

		The specified weapon data value, if it exists.
]]--
function GST.GetWeaponDataValue(name)
    return weapondatavalues[name]
end

--[[
	Function: GetWeaponDataValues

	Returns:

		A table containing all weapon data values.
]]--
function GST.GetWeaponDataValues()
    return weapondatavalues
end
