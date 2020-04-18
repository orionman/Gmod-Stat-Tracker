--[[
	Title: SQLite

	Used incase MySQL isnt set up, or the MySQL DB goes down.
]]--

GST.SQLite = {}

local s = GST.SQLite -- easier to type

-- Local Helpers
local function _valueOrNull(val)
	if val then return val else return "NULL" end
end

sql.m_strError = nil
setmetatable(sql,{__newindex = function(t,k,v) if k == "m_strError" and v then GST.Error("[SQLite] "..v) end end}) -- thank you wiki

--[[ GST.SQLite Functionality ]]--

local allWeapons = allWeapons or nil
local function _createTables()
	GST.Info("Creating master table...")
	sql.query([[CREATE TABLE 
				gst_master (
					steamid INTEGER NOT NULL PRIMARY KEY, 
					kills INTEGER NOT NULL,
					headshots INTEGER NOT NULL,
					deaths INTEGER NOT NULL,
					time INTEGER DEFAULT NULL
				);]])
end

local function _createWeaponTable(weapon)
	if not weapon:IsWeapon() then return end
	local name = weapon:GetClass()
	GST.Info("Creating weapon table".. name .."...")
	sql.query(string.format([[CREATE TABLE IF NOT EXISTS
							gst_%s (
								steamid INTEGER NOT NULL PRIMARY KEY,
								kills INTEGER DEFAULT NULL,
								deaths INTEGER DEFAULT NULL
							);]], name))
	end
	GST.Info("Weapon table ".. name .." created successfully!")
end

if not sql.TableExists("gst_master") then _createTables() end
for _, wep in ipairs(weapons.GetList()) do
	if not sql.TableExists("gst_")
end

function s.UpdateAll()
	local players = player.GetAll()

	GST.MessageAll("Database is updating... expect some lag.")

	for _, ply in ipairs(players) do
		if ply:IsBot() continue end
		-- Data to be entered
		local sid = ply:SteamID64()

		local q

		for k,v in pairs(GST.InternalData[sid]) do
			q = db:query(string.format("UPDATE gst_master SET %s = %s WHERE steamid = %d", k, _valueOrNull(v), sid))

			q.onError = _defaultErrorCallback
			q.onSuccess = _defaultCallback

			q:start()
		end

		for k, v in pairs(GST.InternalWepData[sid]) do
			for k1, v1 in pairs(v) do
				q = db:query(string.format("UPDATE gst_%s SET %s = %s WHERE steamid = %d", k, k1, _valueOrNull(v1), sid))

				q.onError = _defaultErrorCallback
				q.onSuccess = _defaultCallback

				q:start()
			end
		end
		
		GST.MessageAll("Update complete!")
end

function s.Integrate(data, wepdata)
	local players = player.GetAll()

	for sid, values in pairs(data) do
		sql.query(string.format("UPDATE gst_master SET %s = %s WHERE steamid = %d", key, tostring(val), sid))
	end
end

-- Group: Data

--[[
	Function: SQLite.Query

	Manually queries something, only intended for internal use.

	Parameters:
		
		input - The query to execute
]]--
function s.Query(input)
	sql.query(input)
end

--[[
	Function: SQLite.SetData

	Changes a players data value.

	Parameters:
		
		ply - Player to set the data of.
		key - Data to change.
		val - Value to change it to.
]]--
function s.SetData(ply, key, val)
	if not ply:IsPlayer() then
		GST.Error("Tried to set data on a non-player!")
		return
	end

	if not hook.Call("GST_DataValueChanged", nil, ply, key, GST.GetData(ply,key,val)) then return end

	local sid = ply:SteamID64()
	sql.query(string.format("UPDATE gst_master SET %s = %s WHERE steamid = %d", key, tostring(val), sid))
end

--[[
	Function: SQLite.GetData

	Parameters:
		
		ply - Player to get the data of.

	Returns:

		A table containing a player's data.
]]--
function s.GetData(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		GST.Error("Tried to get data from a non-player!")
		return
	end

	local sid = ply:SteamID64()
	
	return sql.query(string.format("SELECT * FROM gst_master WHERE steamid = %s", sid))
end

--[[
	Function: SQLite.SetWeaponData

	Changes a players weapon data value.

	Parameters:
		
		ply - Player to set the data of.
		weapon - Weapon to set the data of.
		key - Data to change.
		val - Value to change it to.
]]--
function s.SetWeaponData(ply,weapon,key,val)
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
	return sql.query(string.format("UPDATE gst_%s SET %s=%s WHERE steamid = %s", weapon:GetClass(), key, tostring(val), sid))
end


--[[
	Function: SQLite.GetWeaponData

	Parameters:
		
		ply - Player to get the data of.
		weapon - Weapon to get the data of.

	Returns:

		A player's weapon data.
]]--
function s.GetWeaponData(ply, weapon)
	if not IsValid(ply) or not ply:IsPlayer() then
		GST.Error("Tried to get data from a non-player!")
		return
	end

	if not IsValid(weapon) or weapon:IsWeapon() then
		GST.Error("Tried to get weapon data from a non-weapon!")
		return
	end

	local sid = ply:SteamID64()

	return sql.query(string.format("SELECT * FROM gst_%s WHERE steamid = %s", weapon:GetClass(), sid))
end
