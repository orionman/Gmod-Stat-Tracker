--[[
	File: sv_player.lua
	
	Player meta functions.

	Handles the tracking of things like kills, deaths, etc.

	To use these functions, 
]]--
local Player = FindMetaTable("Player")

if not Player then
	error("Cannot find Player metatable.")
end

-- Group: Setters

--[[
	Function: Player:SetData

	Sets specific data of a player to a specific value

	Parameters:

		key - The name of the data value to set
		val - The value to set it to

	Note:

		You will have to implement handling the value yourself

	See Also:

		<Player:GetData>
]]--
function Player:SetData(key,val)
	GST.DataProvider.SetData(self, key, val)
end

--[[
	Function: Player:SetKills

	Sets the kills of a player to a value greater than 0.

	Parameters:

		kills - The number of kills to give the player. 

	Note:

		This does not add kills, simply sets the value to the value specified.

	See Also:

		<Player:GetKills>
]]--
function Player:SetKills(kills)
	assert(kills > 0, "Cannot set player to negative kills!")
	GST.DataProvider.SetKills(self, kills)
end

local oldSetDeaths = Player.SetDeaths

--[[
	Function: Player:SetDeaths

	Sets the deaths of a player to a value greater than 0.

	Parameters:

		deaths - The number of deaths to give the player. 
		override - If GST Deaths should be set, in case other addons want to use the default function.

	Note:

		This does not add deaths, simply sets the value to the value specified.

	See Also:

		<Player:GetDeaths>
]]--
function Player:SetDeaths(deaths,override)
	oldSetDeaths(deaths)
	if not override return end
	assert(deaths > 0, "Cannot set player to negative deaths!")
	GST.DataProvider.SetDeaths(self, deaths)
end

--[[
	Function: Player:SetTime

	Sets a player's total time played.

	Parameters:

		time - The amount of time, in seconds. Must be greater than 0, but less than (2 ^ 31) - 1 (2,147,483,647).

	See Also:

		<Player:GetTime>

		<Player:GetSessionTime>
]]--
function Player:SetTotalTime(time)
	assert(time > 0, "Cannot set negative time!")
	assert(time < math.pow(2, 31) - 1, "Cannot set time above 2,147,483,647 seconds!")
	GST.DataProvider.SetTotalTime(self, time)
end

-- Group: Getters

--[[
	Function: Player:GetData

	Gets specific data of a player

	Parameters:

		key - The name of the data value to get

	Returns:

		The value of the data val.

	See Also:

		<Player:SetData>
]]--
function Player:GetData(key)
	return GST.DataProvider.GetData(self)[key]
end

--[[
	Function: Player:GetKills

	Gets the number kills of a player.

	Returns:

		The number of kills a Player has.

	See Also:

		<Player:SetKills>
]]--
function Player:GetKills()
	return GST.DataProvider.GetData(self).kills
end

--[[
	Function: Player:GetDeaths

	Gets the number deaths of a player.

	Returns:

		The number of deaths a player has.

	See Also:

		<Player:SetDeaths>
]]--
function Player:GetDeaths()
	return GST.DataProvider.GetData(self).deaths
end

--[[
	Function: Player:GetTime

	Returns:

		The number of seconds the player has played on the server.

	See Also:

		<Player:SetTime>

		<Player:GetSessionTime>
]]--
function Player:GetTime()
	return GST.DataProvider.GetData(self).overallTime
end

--[[
	Function: Player:GetTotalTime

	Alias of <Player:GetTime>
]]--
function Player:GetTotalTime()
	return self:GetTime()
end

--[[
	Function: Player:GetSessionTime

	Returns:

		The number of seconds that the player has played on the server in the current session.

	See Also:

		<Player:GetTime>
]]--
function Player:GetSessionTime()
	return GST.DataProvider.GetData(self).sessionTime
end

function Player:AddDeath()
	self:SetDeaths(self:GetDeaths() + 1)
end

function Player:AddKill()
	self:SetKills(self:GetKills() + 1)
end
