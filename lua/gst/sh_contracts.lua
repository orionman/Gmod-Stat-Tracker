--[[
	File: sh_contracts.lua
	
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
    

    local Q = GST.DataProvider:query(string.format([[CREATE TABLE IF NOT EXISTS
									gst_contract_%s (
										steamid VARCHAR(17) NOT NULL PRIMARY KEY,
										cur INTEGER DEFAULT 0
                                        complete BIT DEFAULT 0
                                        complete_time DATE DEFAULT NULL
									);]], name)))

    function Q:onSuccess(data)
        GST.Info("Contract " .. name .. " added successfully!")
    end

    function Q:onError(err, sql)
        GST.Error("Failed in creating contract " .. name .. " : " .. err .. " (" .. sql .. ")")
    end

    contracts[name] = contract
end

-- Group: Contracts

GST.Contract = {}
GST.Contract.Name = ""
GST.Contract.DisplayName = ""
GST.Contract.Description = ""
GST.Contract.Data = "" -- Which data value to track
GST.Contract.Goal = "" -- The amount the data value has to get for the contract to be complete
GST.Contract.Onetime = false
GST.Contract.Module = "Misc"

--[[
	Function: Contract:OnDataChanged

	Parameters:
		
		ply - The player which value has changed.
        value - The value the data has right now.

    Called when the data which the contract is linked to changes.
    Return true if the data change should progress the contract.
	
]]--
function GST.Contract:OnDataChanged(ply,value)
    return true
end

--[[
	Function: Contract:OnComplete

	Parameters:
		
		ply - The player which completed the contract

    Called when a player completes the contract.
	
]]--
function GST.Contract:OnComplete(ply)
    
end

--[[
	Function: Contract:OnStart

	Parameters:
		
		ply - The player which started the contract

    Called when a player starts the contract.
	
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
    hook.Add("GST_DataValueChanged", "GST_TriggerContracts_".. self.Name, function(ply,data,value)
        if data == self.Data then
            return self:OnDataChanged(ply, value)
        end
    end)
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

	Parameters:
		
		name - Name of the contract.

	Links the specified contract to the module, if possible.
]]--
function GST.Module:LinkContract(name)
    contracts[name].Module = self.Name
end
