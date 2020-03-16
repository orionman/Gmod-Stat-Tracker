--[[
	File: sh_util.lua

	Contains public utility functions that are commonly used.
]]--

--[[ Helper functions ]]--

local function _logWithPrefix(message, prefix)
	if SERVER then
		ServerLog("[GST] " .. prefix .. " " .. message)
	end

	MsgN("[GST] " .. prefix .. " " .. message)
end

--[[
	Function: Log

	Prints a message out to the console.
]]--
function GST.Log(message)
	_logWithPrefix("[LOG]", message)
end

--[[
	Function: Info

	Prints an info message out to the console.
]]--
function GST.Info(message)
	_logWithPrefix("[INFO]", message)
end

--[[
	Function: Warn

	Prints an error message to the console. These are non-fatal errors that have no immediate effect but may affect future function calls.
]]--
function GST.Warn(message)
	_logWithPrefix("[WARN]", message)
end

--[[
	Function: Error

	Prints an error message to the console. These are fatal errors that require immediate action.
]]--
function GST.Error(message)
	_logWithPrefix("[ERROR]", message)
	
	if CLIENT then
		MsgN("[GST] Please contact a server administrator with the error above and any additional information!")
	end
end
