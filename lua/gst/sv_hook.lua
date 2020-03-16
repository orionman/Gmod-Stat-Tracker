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

	if IsValid(weapon) and weapon:IsWeapon() then
		local class = weapon.ClassName
		victim:SetWeaponData(class, "deaths", victim:GetWeaponData(class, "deaths") + 1)
		if attacker:IsPlayer() then attacker:SetWeaponData(class, "kills", attacker:GetWeaponData(class, "kills") + 1) end
	end

	if attacker:IsPlayer() then
		attacker:AddKill()
		if headshot then
			attacker:SetData("headshots", attacker:GetData("headshots") + 1)
		end
	end
end

--[[
	Function: DataValueChanged

	Called when a GST Data Value is Changed

	Note:
		
		*DO NOT CALL THIS MANUALLY, ONLY THROUGH `hook.Call`*
]]--
function GST.DataValueChanged(data)
	local datamodule = GST.GetModule(data.Module)
	if not datamodule.Enabled or (gmod.GetGamemode().FolderName ~= datamodule.Gamemode and datamodule.Gamemode ~= "") then return false end
end

hook.Add("PlayerDeath", "GST_PlayerDeath", GST.PlayerDeath)
hook.Add("GST_DataValueChanged", "GST_DataValueChangeValid", GST.DataValueChanged)
