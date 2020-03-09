--[[
	MySQL

	MySQL is a database software used for synchronizing information between servers. Gmod MySQL uses FredyH's MySQLOO (https://github.com/FredyH/MySQLOO)
	in order to function. If this is not present in your server, MySQL will NOT work.
]]--

--[[ Config Settings ]]--
local hostname 	= ""
local username 	= ""
local password 	= ""
local database 	= ""
local port 		= 3306 -- This is probably 3306. Don't change it unless you know it's different
--[[ End Config Settings ]]--

--[[-----------------------------------
	DON'T EDIT ANYTHING PAST THIS POINT
-----------------------------------]]--

require("mysqloo") -- Required for MySQLOO to be loaded

GST.MySQL = {} -- Global table for GST-related MySQL functions.
GST.DataProvider = GST.MySQL -- Cleaner access
local _internalData = {} -- Used for storing data of connected players if DB goes down.
local m = GST.MySQL -- Because I don't want to type "GST.MySQL" over and over.

-- Create database
local db = mysqloo.connect(hostname, username, password, database, port)
db:setAutoReconnect(true)

function db:onConnected()
	GST.Info("Connected successfully to the MySQL database! Creating tables...")
	local Q1 = db:query([[CREATE TABLE IF NOT EXISTS 
						gst_master (
							steamid VARCHAR(17) NOT NULL PRIMARY KEY, 
							kills INTEGER NOT NULL,
							deaths INTEGER NOT NULL,
							time INTEGER NOT NULL
						);]]) -- TODO add more columns for more data
	-- TODO add weapons column
end

function db:onConnectionFailed(err)
	GST.Error("Failed to connect to the MySQL database. Reverting to SQLite...")
	GST.DataProvider = GST.SQLite
	GST.DataProvider.UpdateAll()
end

db:connect()
timer.Create("GST_PingDatabase_" .. tostring(math.random(-2000000000, 2000000001)), 67, 0, function() -- Timer name is sanity check. Makes sure people can't interrupt database pinging.
	GST.Info("Pinging database...")
	local connected = db:ping()

	if not connected then
		GST.Error("Connection to database lost. Will attempt to reconnect every 60 seconds... Reverting to SQLite until connection restored.")
		GST.SQLite.Integrate(_internalData, true)
		GST.DataProvider = GST.SQLite
	else
		GST.Info("Connection restored to database. Updating...")
		GST.MySQL.UpdateAll(true)
		GST.DataProvider = GST.MySQL
	end
end)

-- TODO finish function
function m.UpdateAll(from_local)
	local players = player.GetAll()

	if from_local then
		for _, ply in ipairs(players) do
			if ply:IsBot() continue end
			local sid = ply:SteamID()

			local playerData = sql.QueryRow("SELECT * FROM gst_master WHERE steamid = " .. sid .. ";")
			local weaponData = sql.QueryRow("SELECT * FROM gst_weapon WHERE steamid = " .. sid .. ";")
			
			local Q1 = db:query(string.format("UPDATE gst_master SET kills = %i")
		end
	end
end
