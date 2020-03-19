--[[
	This is the init file for Gmod Stat Tracker, or GST.
]]--
GST = {} -- Global table

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

local function _init()
	-- TODO finish init function
	file.CreateDir("gst")
	if SERVER then
		_includeSH( "gst/shared/sh_util.lua" )
		GST.Info( "sh_util.lua Loaded!" )

		_includeSH( "gst/shared/sh_module.lua" )
		GST.Info( "sh_module.lua Loaded!" )

		_includeSH( "gst/shared/sh_contracts.lua" )
		GST.Info( "sh_contracts.lua Loaded!" )

		include( "gst/server/sv_mysql.lua" )
		GST.Info( "sv_mysql.lua Loaded!" )

		include( "gst/server/sv_player.lua" )
		GST.Info( "sv_player.lua Loaded!" )

		include( "gst/server/sv_hook.lua" )
		GST.Info( "sv_hook.lua Loaded!" )

		-- Modules
		local files = file.Find( "gst/modules/*.lua", "LUA" )
		if #files > 0 then
			for _, file in ipairs( files ) do
				GST.Info( "Loading module: " .. file )
				_includeSH("gst/modules/" .. file)
			end
		end
		
		files = file.Find( "gst/modules/sv/*.lua", "LUA" )
		if #files > 0 then
			for _, file in ipairs( files ) do
				GST.Info( "Loading SERVER module: " .. file )
				_includeSH("gst/modules/sv/" .. file)
			end
		end
		
		files = file.Find( "gst/modules/cl/*.lua", "LUA" )
		if #files > 0 then
			for _, file in ipairs( files ) do
				GST.Info( "Loading CLIENT module: " .. file )
				AddCSLuaFile("gst/modules/cl/" .. file)
			end
		end
	else
		include( "gst/sh_util.lua" )
		include( "gst/sh_module.lua" )
		include( "gst/sh_contracts.lua" )

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
end
hook.Add("Initialize", "GST_Init", _init)
