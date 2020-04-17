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
		}
	},
	Designers = {
		Necro = {
			Name = "?",
			Nick = "Necro",
			Email = "?"
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
			for _, file in ipairs( files ) do
				GST.Info( "Loading module: " .. file )

				GST.Module = {}
				GST.Module.Name = ""
				GST.Module.DisplayName = ""
				GST.Module.Description = ""
				GST.Module.Version = ""
				GST.Module.Author = ""
				GST.Module.Gamemode = ""
				GST.Module.Enabled = true
				GST.Module.Init = function() end

				include("gst/modules/" .. file)
				if GST.Module.Gamemode and engine.ActiveGamemode() == GST.Module.Gamemode and GST.Module.Enabled then
					GST.Module.Init()
				end
			end
		end
	else
		files = file.Find("gst/shared/sh_*.lua")
		for _, fil in pairs(files) do
			include("gst/shared/" .. fil)
			GST.Info(fil .. " loaded!")
		end

		files = file.Find("gst/client/cl_*.lua")
		for _, fil in pairs(files) do
			include("gst/client/" .. fil)
			GST.Info(fil .. " loaded!")
		end

		-- Modules, but on client side
		local files = file.Find( "gst/modules/*.lua", "LUA" )
		if #files > 0 then
			for _, file in ipairs( files ) do
				include("gst/modules/" .. file)
			end
		end

		files = file.Find("gst/modules/cl/*.lua", "LUA")
		if #files > 0 then
			for _, file in ipairs(files) do
				GST.Info("Loading CLIENT module: " .. file)
				include("gst/modules/cl/" .. file)
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
