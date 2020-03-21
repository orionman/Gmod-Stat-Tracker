--[[
	Title: Contracts
	
	Contract meta functions and values.

	Handles creation of custom Contracts and adding them to modules.

]]--

--[[ Local Helper Functions and Tables ]]--

-- List of contracts, incase something needs them
local contracts = {}

-- Creates the table for the contract if it doesnt exist already
local function _registerContract(contract)
    local name = contract.Name

    if not GST.GetDataValue(contract.Data) then
        GST.Error("Data value to track does not exist! (".. data ..")")
        return 
    end
    local desc = contract.Description or "No Description Set"
    local displayname = contract.Displayname or name

    local goalstr = [[]]

    for k, v in pairs(contract.Goals) do
        goalstr = goalstr + "   "..k .. " INTEGER DEFAULT 0\n"
    end   

    local Q = GST.DataProvider:query(string.format([[CREATE TABLE IF NOT EXISTS
									gst_contract_%s (
										steamid VARCHAR(17) NOT NULL PRIMARY KEY,
										cur INTEGER DEFAULT 0
                                        complete BIT DEFAULT 0
                                        complete_time DATE DEFAULT NULL]]..goalstr
									[[);]], name)))

    function Q:onSuccess(data)
        GST.Info("Contract " .. name .. " added successfully!")
    end

    function Q:onError(err, sql)
        GST.Error("Failed in creating contract " .. name .. " : " .. err .. " (" .. sql .. ")")
    end

    contracts[name] = contract
end

local function _setContractComplete(ply, contract, amount)
    assert(amount == true or amount == false, "Complete must be set to a bool!")
    if not ply:IsPlayer() then
		GST.Error("Tried to increment contract data on a non-player!")
		return
	end

    if not contracts[contract] then
        GST.Error("Tried to increment data on a non-contract!")
		return
    end

    if amount then amount = 1 else amount = 0 end

    local sid = ply:SteamID()
    local Q = db:query(string.format("UPDATE gst_contract_%s SET complete = ".. tostring(amount) .." WHERE steamid = %s", contract, sid))

	function Q:onError(err,sql)
		GST.Error("Query \"" .. sql .. "\" threw an error: " .. err)
	end
end

local function _setContractProgress(ply, contract, amount)
    if not ply:IsPlayer() then
		GST.Error("Tried to set contract data on a non-player!")
		return
	end
    local condata = contracts[contract]

    if not condata then
        GST.Error("Tried to set data on a non-contract!")
		return
    end

    local sid = ply:SteamID()
    local plydata = db:query(string.format("SELECT * FROM gst_contract_%s WHERE steamid = " .. sid .. ";", contract))
    if plydata.complete == 1 then return end -- Checks if the contract is complete

    if amount >= condata.Goal then _setContractComplete(ply, contract, true) end

	local Q = db:query(string.format("UPDATE gst_contract_%s SET cur = ".. tostring(amount) .." WHERE steamid = %s", contract, sid))

	function Q:onError(err,sql)
		GST.Error("Query \"" .. sql .. "\" threw an error: " .. err)
	end

end

local function _addContractProgress(ply, contract, amount)
    if not ply:IsPlayer() then
		GST.Error("Tried to increment contract data on a non-player!")
		return
	end

    local sid = ply:SteamID()
    local plydata = db:query(string.format("SELECT * FROM gst_contract_%s WHERE steamid = " .. sid .. ";", contract))
    _setContractProgress(ply, contract, amount + plydata.cur)
end

-- Group: Contracts

GST.Contract = {}
GST.Contract.Name = ""
GST.Contract.DisplayName = ""
GST.Contract.Description = ""
GST.Contract.Data = "" -- Which data value to track
GST.Contract.Goals = {
    --[[
        For displaying scores on the hud and secondary goals
        You need to specify at least one
    ]]--
    maingoal = {
        Description = "Do something", -- The description for the HUD and GUI
        Value = 1, -- How much progress this goal adds
        Amount = 0 -- How many times this goal can be completed, 0 or less for infinite times
    },
    secondarygoal = {
        Description = "Do something more specific",
        Value = 3,
        Amount = 5
    },
}
GST.Contract.GoalAmount = 100 -- The amount of progress a player has to get for the contract to be complete, has to be positive
GST.Contract.Onetime = false
GST.Contract.Module = "Misc"

--[[
	Function: Contract:OnDataChanged

    Called when the data which the contract is linked to changes.
    Return true if the data change should progress the contract.
    Also eturn how much the data should change.

	Parameters:
		
		ply - The player which value has changed.
        value - The value the data has right now.
	
]]--
function GST.Contract:OnDataChanged(ply,value)
    return true, 0
end

--[[
	Function: Contract:OnComplete

    Called when a player completes the contract.

	Parameters:
		
		ply - The player which completed the contract
	
]]--
function GST.Contract:OnComplete(ply)
    
end

--[[
	Function: Contract:OnStart

    Called when a player starts the contract.

	Parameters:
		
		ply - The player which started the contract
	
]]--
function GST.Contract:OnStart(ply)
    
end

--[[
	Function: Contract:New

	Parameters:
		
		name - Name of the contract.

	Returns:

		A Contract table.

	Note:

		Must be registered with <Contract:Register>
]]--
function GST.Contract:New(name)
    newContract = {
        Name = name
    }

    self.__index = self

    return setmetatable(newContract, self)
end

--[[
	Function: Contract:Register

	Registers a contract table to be used.
]]--
function GST.Contract:Register()
    local name = self.Name

    if contracts[name] then
        GST.Error("Contract " .. name .. " exists more then once!")

        return
    end

    _registerContract(self)
end

--[[
	Function: GetContract

	Parameters:
		
		name - Name of the contract.

	Returns:

		The specified contract, if it exists.
]]--
function GST.GetContract(name)
    return contracts[name]
end

--[[
	Function: GetContracts

	Returns:

		A table containing all contracts.
]]--
function GST.GetContracts()
    return contracts
end

--[[
	Function: Module:LinkContract

    Links the specified contract to the module, if possible.

	Parameters:
		
		name - Name of the contract.
]]--
function GST.Module:LinkContract(name)
    contracts[name].Module = self.Name
end

hook.Add("GST_DataValueChanged", "GST_TriggerContracts".. self.Name, function(ply,data,value)
    for k,v in pairs(contracts) do
        if data == v.Data then
            local increment, amount = self:OnDataChanged(ply, value)

            if increment and amount then
                _addContractProgress(ply, k, amount)
            end
            increment = nil
            amount = nil
        end
    end
end)