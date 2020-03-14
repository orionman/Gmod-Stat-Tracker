--[[
	File: sv_hook.lua

	Contains all the main hooks for GST. 
]]--

--[[ Helper functions ]]--

local function _wasHeadshot(victim)
	return victim:LastHitGroup() == HITGROUP_HEAD
end

--[[
	Function: GST.PlayerDeath

	Called when a player dies. Used to track player kills and deaths.

	Note:
		
		*DO NOT CALL THIS MANUALLY, ONLY THROUGH `hook.Call`*
]]--
function GST.PlayerDeath(victim, weapon, attacker)
	victim:AddDeath()

	if victim == attacker or not IsValid(attacker) then return end -- no further processing is required if suicide.

	local headshot = _wasHeadshot(victim)
	local attackerData = {} -- stores the attacker's data to update
	local victimData = {} -- stores the victim's data to update

	if IsValid(weapon) and weapon:IsWeapon() then
		attackerData.Weapon = weapon.ClassName
	end
end
