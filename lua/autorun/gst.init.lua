--[[
	This is the init file for Gmod Stat Tracker, or GST.
]]--
GST = {} -- Global table
GST.FirstLoad = GST.FirstLoad or true

if SERVER then
	AddCSLuaFile()
end

GST.Version = "0.0.1" -- Global version string. Compared to Github's version on startup to ensure latest version is being used.
GST.Release = false -- Global release bool. Tells the addon if this is a stable release. Basically just warns the user that some things may not work properly or at all if false.

GST.Credits = {
	Authors = {
		iViscosity = {
			Name = "Spencer Murphy",
			Nick = "iViscosity",
			Email = "iviscositydevelopmentteam@gmail.com"
		},
		qualitycont = {
			Nick = "qualitycont",
			Email = "noqualitycont@gmail.com"
		},
		Orion = {
			Nick = "Orion"
		}
	},
	Designers = {
		Necro = {
			Nick = "Necro",
		}
	},
	Testers = {}
}

local function _includeSH(path)
	include(path)
	AddCSLuaFile(path)
end

-- Should only be called internally. There's no reason for it to be called elsewhere.
-- To check version, compare to GST.Version
function GST.VersionCheck()
	local url = "https://raw.githubusercontent.com/iViscosity/Gmod-Stat-Tracker/master/build.version"

	local response = ""
	http.Fetch(url,
		function(body) -- onSuccess
			response = body
		end,

		function(err) -- onError
			ErrorNoHalt(err) -- GST.Error is not defined yet.
		end
	)
	if response ~= GST.Version then
		local message = "GST is not up to date! Consider updating at https://github.com/iViscosity/Gmod-Stat-Tracker/releases!"
	
		print(message)
		if SERVER then ServerLog(message) end
	end
end

local function _init()
	-- TODO finish init function
	file.CreateDir("gst")

	if GST.FirstLoad then
		GST.VersionCheck()
	end

	hook.Run("GST_PreInitialize")

	local files

	GST.Module = {}
	GST.Module.Name = ""
	GST.Module.DisplayName = ""
	GST.Module.Description = ""
	GST.Module.Version = ""
	GST.Module.Author = ""
	GST.Module.Gamemode = ""
	GST.Module.Enabled = true
	GST.Module.Init = function() end

	if SERVER then
		files = file.Find("gst/server/sv_*.lua")
		for _, fil in pairs(files) do
			include("gst/server/" .. fil)
			GST.Info(fil .. " loaded!")
		end

		files = file.Find("gst/shared/sh_*.lua")
		for _, fil in pairs(files) do
			_includeSH("gst/shared/" .. fil)
			GST.Info(fil .. " loaded!")
		end

		files = file.Find("gst/client/cl_*.lua")
		for _, fil in pairs(files) do
			AddCSLuaFile("gst/client/" .. fil)
			GST.Info(fil .. " loaded!")
		end

		-- Modules
		files = file.Find( "gst/modules/*.lua", "LUA" )
		if #files > 0 then
			for _, fil in ipairs( files ) do
				_includeSH("gst/modules/" .. fil)
				GST.Info(fil .. " loaded!")
			end
		end
	else
		files = file.Find("gst/shared/sh_*.lua")
		for _, fil in pairs(files) do
			include("gst/shared/" .. fil)
		end

		files = file.Find("gst/client/cl_*.lua")
		for _, fil in pairs(files) do
			include("gst/client/" .. fil)
		end

		-- Modules, but on client side
		local files = file.Find( "gst/modules/*.lua", "LUA" )
		if #files > 0 then
			for _, file in ipairs( files ) do
				include("gst/modules/" .. file)
			end
		end
	end

	for _, mod in ipairs(GST.Modules) do
		if mod.Enabled then
			if engine.ActiveGamemode() == mod.Gamemode then
				mod.Init()
			elseif v.Gamemode == "" then
				mod.Init()
			end
		end
	end

	GST.Info("Version ".. GST.Version .. " fully loaded!")
	if not GST.Release then
		GST.Warn("You are not using a release build of GST, errors may occur!")
	end

	GST.FirstLoad = false
	GST.CheckULX() -- Checks if ulx is present and does some stuff if it does

	hook.Run("GST_PostInitialize")
end
hook.Add("Initialize", "GST_Init", _init)
