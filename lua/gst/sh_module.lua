--[[
	File: sv_module.lua
	
	Module meta functions and values.

	Handles creation of custom Modules and values.

]]--

--[[ Enums ]]--

--[[
	Enum: DataType

	Values:

		Int - SQL Integer
		String - SQL Varchar
		Float - SQL Float

]]--

GST.DataType = {
	Int = "INTEGER",
	String = "VARCHAR",
	Float = "FLOAT"
}

--[[ Local Helper Functions and Tables]]--

-- List of all Modules and Data Values, we only need this here
local modules = {}
local datavalues = {}

-- Registers data value into the database
local function _registerDataValue(key,module,type,val,desc,displayname)
	local type = type or GST.DataType.String
	local val = val or "NULL"
	local desc = desc or "No Description Set"
	local displayname = displayname or key
	local Q = GST.DataProvider:query(string.format([[IF NOT EXISTS (
										SELECT
											*
										FROM
											gst_master
										WHERE
											COLUMN_NAME = '%d')
										ALTER TABLE gst_master
											ADD %d %d %d
										END;]],key,key,type,val))

	function Q:onSuccess(data)
		GST.Info("Value "..key.." added successfully!")
	end
	function Q:onError(err, sql)
		GST.Error("Failed in adding value "..key.." : " .. err .. " (" .. sql .. ")")
	end
	datavalues[key] = {module=module,desc=desc,displayname=displayname}
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
		
		name - Name of the module

	Returns:

		A Module table

	Note:

		Must be registered with <Module:Register>
]]--

function GST.Module:New(name)
	newModule = {Name = name}
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
		GST.Error("Module "..name.." exists more then once!")
		return
	end
	table.insert(modules,self)
	GST.Info("Module "..name.." registered!")
end

-- Group: Data Values

--[[
	Function: Module:DataValue

	Parameters:

		name - The internal name of the data value.
		type - The type of the data value, see <DataType>
		val - Default value
		desc - Description used in the GUI
		displayname - Pretty name used in the GUI

	Adds a data value specific to the module
]]--

function GST.Module:DataValue(name,type,val,desc,displayname)
	_registerDataValue(name,self.Name,type,val,desc,displayname)
end

--[[
	Function: MiscDataValue

	Parameters:

		name - The internal name of the data value.
		type - The type of the data value, see <DataType>
		val - Default value
		desc - Description used in the GUI
		displayname - Pretty name used in the GUI

	Adds a data value, not specific to any addon
]]--

function GST.MiscDataValue(name,type,val,desc,displayname)
	_registerDataValue(name,"Misc",type,val,desc,displayname)
end