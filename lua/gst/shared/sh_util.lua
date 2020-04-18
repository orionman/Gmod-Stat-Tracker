--[[
	Title: Utilities

	Contains public utility functions that are commonly used.
]]--

--[[ Helper functions ]]--

local function _logWithPrefix(message, prefix, ...)
	if SERVER then
		ServerLog("[GST] " .. prefix .. " " .. string.format(message, ...))
	end

	MsgN("[GST] " .. prefix .. " " .. string.format(message, ...))
end

--[[
	Function: Log

	Prints a message out to the console.
]]--
function GST.Log(message, ...)
	_logWithPrefix("[LOG]", message, ...)
end

--[[
	Function: Info

	Prints an info message out to the console.
]]--
function GST.Info(message, ...)
	_logWithPrefix("[INFO]", message, ...)
end

--[[
	Function: Warn

	Prints an error message to the console. These are non-fatal errors that have no immediate effect but may affect future function calls.
]]--
function GST.Warn(message, ...)
	_logWithPrefix("[WARN]", message, ...)
end

--[[
	Function: Error

	Prints an error message to the console. These are fatal errors that require immediate action.
]]--
function GST.Error(message, ...)
	_logWithPrefix("[ERROR]", message, ...)
	
	if CLIENT then
		MsgN("[GST] Please contact a server administrator with the error above and any additional information!")
	end
end

--[[
		Function: MessageAll

		Sends a message to everyone. This is shared, but does nothing on the client.
]]--
function GST.MessageAll(message, ...)
	message = string.format(message, ...)
	if ULib then
		ULib.tsayColor(_, "", -- empty string is required because color doesn't always work right away
			Color(255, 255, 255), "[", 
			Color(14, 176, 160), "GST",
			Color(255, 255, 255), "] ",
			Color(199, 12, 37), message)
	elseif SERVER then
		net.Start("GST_MessageAll")
			net.WriteString(message)
		net.Broadcast()
	end
end

--[[
		Function: MessagePlayer

		Sends a message to a specific player. This is shared, but does nothing on the client.
]]--
function GST.MessagePlayer(ply, message, ...)
	message = string.format(message, ...)
	if ULib then
		ULib.tsayColor(ply, "", -- empty string is required because color doesn't always work right away
			Color(255, 255, 255), "[", 
			Color(14, 176, 160), "GST",
			Color(255, 255, 255), "] ",
			Color(199, 12, 37), message)
	elseif SERVER then
		net.Start("GST_MessagePlayer")
			net.WriteString(message)
		net.Send(ply)
	end
end