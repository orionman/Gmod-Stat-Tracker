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
local _internalWepData = {} -- Used for storing weapon data of connected players if DB goes down.

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

local function _defaultErrorCallback(q, sql, err)
	GST.Error("Query \"%s\" threw an error: %s", sql, err)
end

--[[ GST.MySQL Functionality ]]--

local allWeapons = allWeapons or nil
function db:onConnected()
	GST.Info("Connected to the MySQL database! Creating tables...")
	GST.Info("Creating master table...")
	local Q1 = db:query([[CREATE TABLE IF NOT EXISTS 
						gst_master (
							steamid INTEGER NOT NULL PRIMARY KEY, 
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
										steamid INTEGER NOT NULL PRIMARY KEY,
										kills INTEGER DEFAULT NULL,
										deaths INTEGER DEFAULT NULL
									);]], name))

				function Q2:onError(err, sql)
					GST.Error("Could not create weapon table for weapon: \"%s\". Error: %s", name, err)
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
	GST.Error("Failed to connect to the MySQL database: %s. Reverting to SQLite...", err)
	GST.DataProvider = GST.SQLite
	GST.DataProvider.UpdateAll()
end

db:connect()
timer.Create("GST_PingDatabase_" .. tostring(math.random(-2000000000, 2000000001)), 67, 0, function() -- Timer name is sanity check. Makes sure people can't interrupt database pinging.
	GST.Info("Pinging database...")
	local connected = db:ping() -- This can be dangerous because server will hang for at least 2x ping to database if it's down. Should be less than a fraction of a second, though, if ping isn't bad.

	if not connected then
		GST.Error("Connection to database lost. Will attempt to reconnect every 60 seconds... Reverting to SQLite until connection restored.")
		GST.SQLite.Integrate(_internalData)
		GST.DataProvider = GST.SQLite
	else
		GST.Info("Connection restored to database. Updating...")
		GST.MySQL.UpdateAll()
		GST.DataProvider = GST.MySQL
	end
end)

function m.UpdateAll()
	local players = player.GetAll()

	GST.MessageAll("Database is updating... expect some lag.")

	for _, ply in ipairs(players) do
		if ply:IsBot() continue end
		-- Data to be entered
		local sid = ply:SteamID64()

		local q

		for k,v in pairs(_internalData[sid]) do
			q = db:query(string.format("UPDATE gst_master SET %s = %s WHERE steamid = %s", k, _valueOrNull(v), sid))

			q.onError = _defaultErrorCallback
			q.onSuccess = _defaultCallback

			q:start()
		end

		for k, v in pairs(_internalWepData[sid]) do
			for k1, v1 in pairs(v) do
				q = db:query(string.format("UPDATE gst_%s SET %s = %s WHERE steamid = %s", k, k1, _valueOrNull(v1), sid))

				q.onError = _defaultErrorCallback
				q.onSuccess = _defaultCallback

				q:start()
			end
		end
		
		GST.MessageAll("Update complete!")
	end
end

-- Group: Data

--[[
	Function: MySQL.SetData

	Changes a players data value.

	Parameters:
		
		ply - Player to set the data of.
		key - Data to change.
		val - Value to change it to.
]]--
function m.SetData(ply, key, val)
	if not ply:IsPlayer() then
		GST.Error("Tried to set data on a non-player!")
		return
	end

	if not hook.Call("GST_DataValueChanged", nil, ply, key, GST.GetData(ply,key,val)) then return end

	local sid = ply:SteamID64()
	local q = db:query(string.format("UPDATE gst_master SET %s = %s WHERE steamid = %s", key, tostring(val), sid))

	q.onSuccess = _defaultCallback
	_internalData[sid][key] = val

	q:start()
end

--[[
	Function: MySQL.GetData

	Parameters:
		
		ply - Player to get the data of.

	Returns:

		A table containing a player's data.
]]--
function m.GetData(ply,key)
	if not IsValid(ply) or not ply:IsPlayer() then
		GST.Error("Tried to get data from a non-player!")
		return
	end

	local sid = ply:SteamID64()
	local q = db:query(string.format("SELECT * FROM gst_master WHERE steamid = %s", sid))

	function q.onSuccess(data)
		_defaultErrorCallback()
		if key then
			return data[key]
		else
			return data
		end
	end

	Q:onError = _defaultErrorCallback
	
end

--[[
	Function: MySQL.SetWeaponData

	Changes a players weapon data value.

	Parameters:
		
		ply - Player to set the data of.
		weapon - Weapon to set the data of.
		key - Data to change.
		val - Value to change it to.
]]--
function m.SetWeaponData(ply,weapon,key,val)
	if not IsValid(ply) or not ply:IsPlayer() then
		GST.Error("Tried to set data on a non-player!")
		return
	end

	if not IsValid(weapon) or not weapon:IsWeapon() then
		GST.Error("Tried to get weapon data from a non-weapon!")
		return
	end

	if not hook.Call("GST_DataValueChanged", nil, ply, key, GST.GetWeaponData(ply, weapon, key, val), weapon) then return end

	local sid = ply:SteamID64()
	local q = db:query(string.format("UPDATE gst_%s SET %s=%s WHERE steamid = %s", weapon:GetClass(), key, tostring(val), sid))

	q.onError = _defaultErrorCallback
	q.onSuccess = _defaultCallback

	q:start()

	_internalWepData[sid][weapon][key] = val
end


--[[
	Function: MySQL.GetWeaponData

	Parameters:
		
		ply - Player to get the data of.
		weapon - Weapon to get the data of.

	Returns:

		A player's weapon data.
]]--
function m.GetWeaponData(ply, weapon)
	if not IsValid(ply) or not ply:IsPlayer() then
		GST.Error("Tried to get data from a non-player!")
		return
	end

	if not IsValid(weapon) or weapon:IsWeapon() then
		GST.Error("Tried to get weapon data from a non-weapon!")
		return
	end

	local sid = ply:SteamID64()
	if _internalWepData[sid][weapon][key] then return _internalWepData[sid][weapon][key] end

	local q = db:query(string.format("SELECT * FROM gst_%s WHERE steamid = %s", weapon:GetClass(), sid))
	
	function q:onSuccess(data)
		if key then
			return data[key]
		else
			return data
		end
	end

	q.onError = _defaultErrorCallback

end
