--[[
	Title: MySQL

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

local OS = jit.os

-- Check if we have MySQLOO installed first. If we don't, break out of stack.
if (OS == "Linux" and not file.Exists("bin/gsmv_mysqloo_linux*.dll", "LUA")) or (OS == "Windows" and not file.Exists("bin/gsmv_mysqloo_win*.dll", "LUA")) then
	GST.Warn("MySQLOO not found. Reverting to SQLite...")
	GST.DataProvider = GST.SQLite
	return -- Exit this file
end

require("mysqloo") -- Required for MySQLOO to be loaded. Will throw an error if not present

GST.MySQL = {} -- Global table for GST-related MySQL functions.
GST.DataProvider = GST.MySQL -- Cleaner access
local _internalData = {} -- Used for storing data of connected players if DB goes down.
local m = GST.MySQL -- Because I don't want to type "GST.MySQL" over and over.

-- Create database
local db = mysqloo.connect(hostname, username, password, database, port)
db:setAutoReconnect(true)

--[[ Local Helper Functions ]]--

-- Helper function for GST.MySQL.UpdateAll. Makes sure nullable values are passed as "NULL" if there is no value set.
local function _valueOrNull(val)
	if val then return val else return "NULL" end
end

-- Helper function for callbacks on queries that require no processing
local function _defaultCallback(q, data)
	GST.Log("Query \"" .. q .. "\" completed successfully.")
end

--[[ GST.MySQL Functionality ]]--

local allWeapons = nil
function db:onConnected()
	GST.Info("Connected to the MySQL database! Creating tables...")
	GST.Info("Creating master table...")
	local Q1 = db:query([[CREATE TABLE IF NOT EXISTS 
						gst_master (
							steamid VARCHAR(17) NOT NULL PRIMARY KEY, 
							kills INTEGER NOT NULL,
							headshots INTEGER NOT NULL,
							deaths INTEGER NOT NULL,
							time INTEGER DEFAULT NULL
						);]])
	
	function Q1:onSuccess(data)
		GST.Info("Master table created successfully!")
	end

	function Q1:onError(err, sql)
		GST.Error("Failed in creating master database: " .. err .. " (" .. sql .. ")")
	end

	Q1:start()

	while Q1:isRunning() end -- lock until query done to add weapons tables.

	GST.Info("Checking weapon tables...")
	if not allWeapons then
		GST.Info("Creating weapon tables...")
		local tbl = {}
		local weps = weapons.GetList()

		for _, wep in ipairs(weps) do
			if wep then
				if WEPS and WEPS.IsEquipment(wep) then continue end
				table.insert(tbl, wep)
				local name = wep:GetClass()
				local Q2 = db:query(
					string.format([[CREATE TABLE IF NOT EXISTS
									gst_%s (
										steamid VARCHAR(17) NOT NULL PRIMARY KEY,
										kills INTEGER DEFAULT NULL,
										deaths INTEGER DEFAULT NULL
									);]], name))

				function Q2:onError(err, sql)
					GST.Error("Could not create weapon table for weapon: \"" .. name .. "\". Error: " .. err)
				end

				Q2.onSuccess = _defaultCallback

				Q2:start()
			end
		end
		allWeapons = tbl -- cache it so if DB disconnects during the round and reconnects we don't have to run this all again.
	end
	GST.Info("Weapon tables verified successfully!")
end

function db:onConnectionFailed(err)
	GST.Error("Failed to connect to the MySQL database (" .. err .. "). Reverting to SQLite...")
	GST.DataProvider = GST.SQLite
	GST.DataProvider.UpdateAll()
end

db:connect()
timer.Create("GST_PingDatabase_" .. tostring(math.random(-2000000000, 2000000001)), 67, 0, function() -- Timer name is sanity check. Makes sure people can't interrupt database pinging.
	GST.Info("Pinging database...")
	local connected = db:ping() -- This can be dangerous because server will hang for at least 2x ping to database if it's down. Should be less than a fraction of a second, though, if ping isn't bad.

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

	if from_local then -- Update all connected players from the local database.
		for _, ply in ipairs(players) do
			if ply:IsBot() continue end
			-- Data to be entered
			local sid = ply:SteamID()
			local kills = ply:GetKills()
			local deaths = ply:GetDeaths()
			local time

			if ply.GetUTimeTotalTime then
				time = ply:GetUTimeTotalTime()
			end

			local playerData = sql.QueryRow("SELECT * FROM gst_master WHERE steamid = " .. sid .. ";")
			local weaponData = sql.QueryRow("SELECT * FROM gst_weapon WHERE steamid = " .. sid .. ";")
			
			local Q1 = db:query(string.format("UPDATE gst_master SET kills = %d, deaths = %d, time = %d WHERE steamid = %s", kills, deaths, _valueOrNull(time), sid))

			function Q1:onError(err, sql)
				GST.Error("Query \"" .. sql .. "\" threw an error: " .. err)
			end

			Q1.onSuccess = _defaultCallback
			_internalData[sid] = {kills, deaths, time}
		end
	else -- This assumes we are only updating connected players using their current data
		for _, ply in ipairs(players) do
			
		end
	end
end

-- Group: Data

--[[
	Function: MySQL.SetData

	Parameters:
		
		ply - Player to set the data of.
		key - Data to change.
		val - Value to change it to.

	Changes a players data value.
]]--
function m.SetData(ply,key,val)
	if not ply:IsPlayer() then
		GST.Error("Tried to set data on a non-player!")
		return
	end

	if not hook.Call("GST_DataValueChanged", nil, ply, key, GST.GetData(ply,key,val)) then return end

	local sid = ply:SteamID()
	local Q = db:query(string.format("UPDATE gst_master SET %s = ".. tostring(val) .." WHERE steamid = %s", key, sid))

	function Q:onError(err,sql)
		GST.Error("Query \"" .. sql .. "\" threw an error: " .. err)
	end

	Q.onSuccess = _defaultCallback
end

--[[
	Function: MySQL.GetData

	Parameters:
		
		ply - Player to get the data of.

	Returns:

		A table containing a players data.

]]--
function m.GetData(ply)
	if not ply:IsPlayer() then
		GST.Error("Tried to get data from a non-player!")
		return
	end
	local sid = ply:SteamID()
	return sql.QueryRow("SELECT * FROM gst_master WHERE steamid = " .. sid .. ";")
end

--[[
	Function: MySQL.SetWeaponData

	Parameters:
		
		ply - Player to set the data of.
		weapon - Weapon to set the data of.
		key - Data to change.
		val - Value to change it to.

	Changes a players weapon data value.
]]--
function m.SetWeaponData(ply,weapon,key,val)
	if not ply:IsPlayer() then
		GST.Error("Tried to set data on a non-player!")
		return
	end
	if not weapon:IsWeapon() then
		GST.Error("Tried to get weapon data from a non-weapon!")
		return
	end

	if not hook.Call("GST_DataValueChanged", nil, ply, key, GST.GetWeaponData(ply, weapon, key, val), weapon) then return end

	local sid = ply:SteamID()
	local type = GST.GetDataValue(key).Type
	local Q = db:query(string.format("UPDATE gst_%s SET %s = ".. tostring(val) .." WHERE steamid = %s", weapon:GetClass(), key, sid))

	function Q:onError(err,sql)
		GST.Error("Query \"" .. sql .. "\" threw an error: " .. err)
	end

	Q.onSuccess = _defaultCallback
end


--[[
	Function: MySQL.SetWeaponData

	Parameters:
		
		ply - Player to get the data of.
		weapon - Weapon to get the data of.

	Returns:

		A players weapon data.

]]--
function m.GetWeaponData(ply,weapon)
	if not ply:IsPlayer() then
		GST.Error("Tried to get data from a non-player!")
		return
	end
	if not weapon:IsWeapon() then
		GST.Error("Tried to get weapon data from a non-weapon!")
		return
	end

	local sid = ply:SteamID()
	return sql.QueryRow("SELECT * FROM gst_".. weapon:GetClass() .." WHERE steamid = " .. sid .. ";")
end
