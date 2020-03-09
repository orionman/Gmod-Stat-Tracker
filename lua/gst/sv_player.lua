--[[
	Player meta functions.

	Handles the tracking of things like kills, deaths, etc.
]]--
local Player = FindMetaTable("Player")

if not Player then
	error("Cannot find Player metatable.")
end

function Player:SetKills(kills)
	assert(kills > 0, "Cannot set player to negative kills!")
end

function Player:GetKills()
	return GST.DataProvider.GetData(self).kills
end

function Player:GetDeaths()
	return GST.DataProvider.GetData(self).deaths
end

function Player:GetTime()
	return GST.DataProvider.GetData(self).overallTime
end

function Player:GetTotalTime()
	return self:GetTime()
end

function Player:GetSessionTime()
	return GST.DataProvider.GetData(self).sessionTime
end
