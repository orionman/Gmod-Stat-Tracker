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
			Nick = "qualitycont"
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

local function _init()
	-- TODO init function
end
hook.Add("Initialize", "GST_Init", _init)
