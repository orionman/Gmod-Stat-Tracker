-- List of all GST.Modules and Data Values, we only need these here
local datavalues = {}
local weapondatavalues = {}

-- Registers data value into the database
local function _registerDataValue(key, module, type, desc, displayname)
    type = type or GST.DataType.Int
    desc = desc or "No Description Set"
    displayname = displayname or key
    local Q = GST.DataProvider.query(string.format(
			[[
				SELECT count(*) FROM information_schema.COLUMNS
					WHERE COLUMN_NAME = '%s'
					AND TABLE_NAME = 'gst_master';
			]], key))

    function Q:onSuccess(data)
        -- TODO insert new tables
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
        Q = GST.DataProvider.query(string.format([[IF NOT EXISTS (
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

-- Group: Modules

--[[
	Function: EnableModule

	Enables the given module

	Parameters:
		
		name - Name of the module.
]]--
function GST.EnableModule(name)
    GST.Modules[name].Enabled = true
end

--[[
	Function: DisableModule

	Disables the given module

	Parameters:
		
		name - Name of the module.
]]--
function GST.DisableModule(name)
    GST.Modules[name].Enabled = false
end

--[[
	Function: ToggleModule

	Toggles the given module

	Parameters:
		
		name - Name of the module.
]]--
function GST.ToggleModule(name)
    GST.Modules[name].Enabled = not GST.Modules[name].Enabled
end

--[[
	Function: GetModule

	Parameters:
		
		name - Name of the module.

	Returns:

		The specified module, if it exists.
]]--
function GST.GetModule(name)
    if SERVER then return GST.Modules[name] end
end

--[[
	Function: GetModules

	Returns:

		A table containing all GST.Modules.
]]--
function GST.GetModules()
    if SERVER then return GST.Modules end
end

-- Group: Data Values

--[[
	Function: Module:DataValue

	Adds a data value specific to the module.

	Parameters:

		name - The internal name of the data value.
		type - The type of the data value, see <DataType>.
		val - Default value.
		desc - Description used in the GUI.
		displayname - Pretty name used in the GUI.
]]--
function GST.Module:DataValue(name, type, desc, displayname)
    _registerDataValue(name, self.Name, type, desc, displayname)
end

--[[
	Function: MiscDataValue

	Adds a data value, not specific to any module.

	Parameters:

		name - The internal name of the data value.
		type - The type of the data value, see <DataType>.
		val - Default value.
		desc - Description used in the GUI.
		displayname - Pretty name used in the GUI.
]]--
function GST.MiscDataValue(name, type, desc, displayname)
    _registerDataValue(name, "Misc", type, desc, displayname)
end

--[[
	Function: Module:WeaponDataValue

	Adds a weapon data value specific to the module.

	Parameters:

		name - The internal name of the data value.
		type - The type of the data value, see <DataType>.
		val - Default value.
		desc - Description used in the GUI.
		displayname - Pretty name used in the GUI.
]]--
function GST.Module:WeaponDataValue(name, type, desc, displayname)
    _registerWeaponDataValue(name, self.Name, type, desc, displayname)
end

--[[
	Function: MiscWeaponDataValue

	Adds a weapon data value, not specific to any module.

	Parameters:

		name - The internal name of the data value.
		type - The type of the data value, see <DataType>.
		val - Default value.
		desc - Description used in the GUI.
		displayname - Pretty name used in the GUI.
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
