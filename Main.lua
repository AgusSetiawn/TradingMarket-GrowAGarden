--[[ 
    💠 XZNE SCRIPTHUB v21.0 - LOGIC CORE
    
    🔧 FEATURES:
    - Smart List (Prevent Duplicates via Data Hook)
    - Smart Clear (Auto remove items)
    - Auto Claim (Fast & Reliable)
    - Exposes API via _G.XZNE_Controller
]]

-- [1] SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- [2] CONTROLLER SETUP
_G.XZNE_Controller = {
    Config = {
        AutoList = false,
        AutoClaim = false,
        AutoClear = false, -- [NEW]
        TargetName = "Bone Blossom",
        Price = 5,
        DeleteAll = false, -- [NEW]
        ListDelay = 2.0,
        Running = true
    },
    Stats = {
        ListedCount = 0,
        LastListTime = 0
    }
}

local Controller = _G.XZNE_Controller
local Config = Controller.Config
local Stats = Controller.Stats
local ListingDebounce = {} -- [OPTIMIZATION] Temporary debounce instead of permanent cache

-- [3] REMOTES & DATA
local TradeEvents = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("TradeEvents")
local BoothsRemote = TradeEvents:WaitForChild("Booths")
local CreateListingRemote = BoothsRemote:WaitForChild("CreateListing")
local ClaimBoothRemote = BoothsRemote:WaitForChild("ClaimBooth")
local RemoveBoothRemote = BoothsRemote:WaitForChild("RemoveBooth")
local RemoveListingRemote = BoothsRemote:WaitForChild("RemoveListing")

-- [DATA HOOK] Attempt to load BoothsReceiver (Primary) or TradeBoothsData (Fallback)
local BoothsReceiver = nil
local TradeBoothsData = nil

task.spawn(function()
    -- Try ReplicationReciever (Snippet Method)
    pcall(function()
        local RepModules = ReplicatedStorage:WaitForChild("Modules", 2)
        if RepModules then
            local ReplicationReciever = require(RepModules:WaitForChild("ReplicationReciever", 2))
            if ReplicationReciever then
                BoothsReceiver = ReplicationReciever.new("Booths")
                print("✅ [XZNE] BoothsReceiver Hooked")
            end
        end
    end)

    -- Try TradeBoothsData (Fallback)
    if not BoothsReceiver then
        pcall(function()
            TradeBoothsData = require(ReplicatedStorage.Data.TradeBoothsData)
            print("✅ [XZNE] TradeBoothsData Hooked")
        end)
    end
end)

-- [4] HELPER FUNCTIONS

local function GetPlayerKey()
    return "Player_" .. LocalPlayer.UserId
end

local function GetMyBooth()
    local folder = Workspace:FindFirstChild("TradeWorld")
    if folder then folder = folder:FindFirstChild("Booths") end
    if not folder then return nil end
    
    for _, booth in pairs(folder:GetChildren()) do
        local ownerId = booth:GetAttribute("OwnerId") or booth:GetAttribute("UserId")
        if not ownerId then
            local ownerValue = booth:FindFirstChild("OwnerId")
            if ownerValue then ownerId = ownerValue.Value end
        end
        if tostring(ownerId) == tostring(LocalPlayer.UserId) then
            return booth
        end
    end
    return nil
end

local function GetBoothsData()
    if BoothsReceiver then
        return BoothsReceiver:GetData()
    elseif TradeBoothsData then
        return TradeBoothsData:GetData()
    end
    return nil
end

local function GetActiveListings()
    local activeUUIDs = {}
    local data = GetBoothsData()
    
    if data and data.Players then
        -- Handle both "Player_ID" and "ID" keys
        local myData = data.Players[GetPlayerKey()] or data.Players[tostring(LocalPlayer.UserId)] or data.Players[LocalPlayer.UserId]
        
        if myData and myData.Listings then
            for uuid, _ in pairs(myData.Listings) do
                activeUUIDs[uuid] = true
            end
        end
    end

    -- Fallback: Check Workspace if no data
    if next(activeUUIDs) == nil then
        local myBooth = GetMyBooth()
        if myBooth and myBooth:FindFirstChild("DynamicInstances") then
            for _, item in pairs(myBooth.DynamicInstances:GetChildren()) do
                activeUUIDs[item.Name] = true
            end
        end
    end
    
    return activeUUIDs
end

-- [CRITICAL] Find Target UUID
local function FindTargetUUID()
    local locations = {
        LocalPlayer:FindFirstChild("Backpack"), 
        LocalPlayer.Character
    }
    
    local alreadyListed = GetActiveListings()
    local currentTime = tick()
    
    for _, loc in pairs(locations) do
        if loc then
            for _, item in pairs(loc:GetChildren()) do
                if item:IsA("Tool") then
                    local realName = item:GetAttribute("f")
                    if realName and string.find(string.lower(realName), string.lower(Config.TargetName)) then
                        local uuid = item:GetAttribute("c")
                        
                        -- Check internal data hook AND debounce
                        if uuid and not alreadyListed[uuid] then
                            -- Only skip if recently attempted (5s debounce)
                            if not ListingDebounce[uuid] or (currentTime - ListingDebounce[uuid] > 5) then
                                return uuid, item.Name
                            end
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

-- [5] CORE LOGIC TASKS

local function RunAutoClear()
    if not Config.AutoClear or not Config.Running then return end

    local data = GetBoothsData()
    if not data then return end
    
    local myData = data.Players[GetPlayerKey()] or data.Players[tostring(LocalPlayer.UserId)]
    
    if myData and myData.Listings then
        for listingUUID, listingInfo in pairs(myData.Listings) do
            if not Config.Running then break end
            
            local itemId = listingInfo.ItemId
            local itemData = myData.Items[itemId]
            
            if itemData then
                -- Determine Real Name from various possible fields
                local realName = itemData.Name or itemData.ItemName or itemData.PetType or (itemData.ItemData and itemData.ItemData.ItemName) or ""
                
                local shouldRemove = false
                if Config.DeleteAll then
                    shouldRemove = true
                elseif realName ~= "" and string.find(string.lower(tostring(realName)), string.lower(Config.TargetName)) then
                    shouldRemove = true
                end
                
                if shouldRemove then
                    -- print("🗑️ Removing: " .. realName)
                    pcall(function() RemoveListingRemote:InvokeServer(listingUUID) end)
                    task.wait(Config.ListDelay) -- Use same delay as listing
                end
            end
        end
    end
end

local function RunAutoClaim()
    if GetMyBooth() then return end
    
    local folder = Workspace:WaitForChild("TradeWorld", 5)
    if not folder then return end
    folder = folder:FindFirstChild("Booths")
    if not folder then return end
    
    for _, booth in pairs(folder:GetChildren()) do
        if not Config.AutoClaim or not Config.Running then break end
        
        local ownerId = booth:GetAttribute("OwnerId")
        if not ownerId then
            local ownerValue = booth:FindFirstChild("OwnerId")
            if ownerValue then ownerId = ownerValue.Value end
        end
        
        -- Smart check: nil, 0, or empty string
        if ownerId == nil or ownerId == 0 or ownerId == "" then
            local success = pcall(function()
                ClaimBoothRemote:FireServer(booth)
            end)
            
            if success then
                if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                    LocalPlayer.Character:SetPrimaryPartCFrame(
                        booth.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
                    )
                end
                task.wait(1)
                if GetMyBooth() then return end
            end
        end
    end
end

local function RunAutoList()
    if not Config.AutoList or not Config.Running then return end
    
    local uuid, toolName = FindTargetUUID()
    if uuid then
        local success = pcall(function()
            return CreateListingRemote:InvokeServer("Holdable", uuid, Config.Price)
        end)
        
        if success then
            ListingDebounce[uuid] = tick() -- Reset debounce
            Stats.LastListTime = tick()
            Stats.ListedCount = Stats.ListedCount + 1
        end
    end
end

-- [6] API EXPORTS
function Controller.UnclaimBooth()
    pcall(function() RemoveBoothRemote:FireServer() end)
end

function Controller.ClearCache()
    -- Deprecated: Cache is now self-healing (debounce)
    ListingDebounce = {}
    Stats.ListedCount = 0
end

-- [7] MAIN LOOP
task.spawn(function()
    print("[XZNE] Logic Core v21 Started")
    while Config.Running do
        if Config.AutoClaim then
            RunAutoClaim()
            task.wait(0.5)
        end
        
        if Config.AutoClear then
            RunAutoClear()
             -- Delay handled inside loop but add small wait to prevent crash if loop empty
             task.wait(0.1)
        end
        
        if Config.AutoList then
            RunAutoList()
            task.wait(Config.ListDelay)
        else
            -- If AutoList OFF but others ON, we still need a loop delay
            if not Config.AutoClaim and not Config.AutoClear then
                 task.wait(1)
            else
                 task.wait(0.5)
            end
        end
    end
    print("[XZNE] Logic Core Stopped")
end)