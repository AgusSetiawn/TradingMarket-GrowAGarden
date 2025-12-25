--[[ 
    💠 XZNE SCRIPTHUB v28.0 - LOGIC CORE
    
    🔧 FEATURES:
    - Auto Buy (Sniper) [NEW]
    - Pet Support (DataService) [NEW]
    - Smart List & Clear (Item/Pet)
    - Auto Claim (Fast)
    - Performance Optimizations (Cached Targets)
]]

-- [1] SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local LocalUserId = LocalPlayer.UserId
local MyPlayerKey = "Player_" .. LocalUserId

-- [2] CONTROLLER SETUP
_G.XZNE_Controller = {
    Config = {
        -- Global
        Running = true,
        Speed = 1.0, -- Replaces ListDelay for global speed
        
        -- Auto Buy (Sniper)
        AutoBuy = false,
        BuyCategory = "Item", -- "Item" or "Pet"
        BuyTarget = "Bone Blossom",
        MaxPrice = 5,
        
        -- Auto List
        AutoList = false,
        ListCategory = "Item", 
        ListTarget = "Bone Blossom",
        Price = 5, -- (ListPrice)
        ListDelay = 2.0, -- Specific delay for listing (optional overriding Speed)
        
        -- Auto Clear
        AutoClear = false,
        RemoveCategory = "Item",
        RemoveTarget = "Bone Blossom",
        DeleteAll = false,
        
        -- Auto Claim
        AutoClaim = false,
    },
    Stats = {
        ListedCount = 0,
        LastListTime = 0,
        SnipeCount = 0
    }
}

local Controller = _G.XZNE_Controller
local Config = Controller.Config
local Stats = Controller.Stats
local ListingDebounce = {}
local CachedTargets = { Buy = "", List = "", Remove = "" }

-- [CONFIG PERSISTENCE]
local FileName = "XZNE_Config_v28.json"

function Controller.SaveConfig()
    if not HttpService then return end
    local success, json = pcall(function() return HttpService:JSONEncode(Config) end)
    if success then
        pcall(function() writefile(FileName, json) end)
    end
end

function Controller.LoadConfig()
    if not isfile or not isfile(FileName) then return end
    local success, content = pcall(function() return readfile(FileName) end)
    if success and content then
        local decodedS, decoded = pcall(function() return HttpService:JSONDecode(content) end)
        if decodedS and decoded then
            for k, v in pairs(decoded) do
                if Config[k] ~= nil then Config[k] = v end
            end
            -- Update dependent caches
            Controller.UpdateCache() 
            print("✅ [XZNE] Config Loaded")
        end
    end
end

-- [3] REMOTES & HOOKS
local TradeEvents = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("TradeEvents")
local BoothsRemote = TradeEvents:WaitForChild("Booths")
local CreateListingRemote = BoothsRemote:WaitForChild("CreateListing")
local ClaimBoothRemote = BoothsRemote:WaitForChild("ClaimBooth")
local RemoveBoothRemote = BoothsRemote:WaitForChild("RemoveBooth")
local RemoveListingRemote = BoothsRemote:WaitForChild("RemoveListing")
local BuyListingRemote = BoothsRemote:WaitForChild("BuyListing")

local BoothsReceiver = nil
local DataService = nil -- For Pets
local TradeBoothsData = nil -- Fallback

task.spawn(function()
    pcall(function()
        local RepModules = ReplicatedStorage:WaitForChild("Modules", 5)
        if RepModules then
            -- Booths Hook
            local ReplicationReciever = require(RepModules:WaitForChild("ReplicationReciever", 2))
            if ReplicationReciever then
                BoothsReceiver = ReplicationReciever.new("Booths")
                print("✅ [XZNE] BoothsReceiver Hooked")
            end
            -- Pets Hook
            DataService = require(RepModules:WaitForChild("DataService", 2))
            if DataService then print("✅ [XZNE] DataService Hooked") end
        end
    end)
    
    if not BoothsReceiver then
        pcall(function()
            TradeBoothsData = require(ReplicatedStorage.Data.TradeBoothsData)
            print("✅ [XZNE] TradeBoothsData Hooked (Fallback)")
        end)
    end
end)

-- [4] HELPERS & OPTIMIZATION

-- Update Cached Strings (Call this when Config changes)
function Controller.UpdateCache()
    CachedTargets.Buy = string.lower(Config.BuyTarget or "")
    CachedTargets.List = string.lower(Config.ListTarget or "")
    CachedTargets.Remove = string.lower(Config.RemoveTarget or "")
end
Controller.UpdateCache() -- Init

local function GetBoothsData()
    if BoothsReceiver then return BoothsReceiver:GetData()
    elseif TradeBoothsData then return TradeBoothsData:GetData() end
    return nil
end

local function GetMyBooth()
    local folder = Workspace:FindFirstChild("TradeWorld")
    if folder then folder = folder:FindFirstChild("Booths") end
    for _, b in pairs(folder and folder:GetChildren() or {}) do
        local oid = b:GetAttribute("OwnerId") or b:GetAttribute("UserId")
        if not oid then local v = b:FindFirstChild("OwnerId"); if v then oid = v.Value end end
        if tostring(oid) == tostring(LocalUserId) then return b end
    end
    return nil
end

-- [5] CORE LOGIC

-- >> AUTO BUY (SNIPER)
local function RunAutoBuy()
    if not Config.AutoBuy then return end
    
    local data = GetBoothsData()
    if not data then return end
    
    local targetType = Config.BuyCategory == "Pet" and "Pet" or "Holdable"
    local targetLower = CachedTargets.Buy
    local maxPrice = Config.MaxPrice
    
    for playerKey, playerData in pairs(data.Players) do
        if not Config.Running then break end
        if playerKey ~= MyPlayerKey and playerData.Listings then
            for listingUUID, listingInfo in pairs(playerData.Listings) do
                -- Optimization: Check Price & Type FIRST
                if listingInfo.Price <= maxPrice and listingInfo.ItemType == targetType then
                    local itemData = playerData.Items[listingInfo.ItemId]
                    if itemData then
                        local realName = itemData.Name or itemData.ItemName or itemData.PetType or (itemData.ItemData and itemData.ItemData.ItemName) or ""
                        
                        if string.find(string.lower(tostring(realName)), targetLower) then
                            -- Buy!
                            local ownerId = tonumber(string.match(playerKey, "Player_(%d+)"))
                            local owner = Players:GetPlayerByUserId(ownerId)
                            
                            if owner then
                                print("🔫 Sniping: " .. realName .. " @ " .. listingInfo.Price)
                                pcall(function() BuyListingRemote:InvokeServer(owner, listingUUID) end)
                                Stats.SnipeCount = Stats.SnipeCount + 1
                                task.wait(0.5) -- Prevent multi-buy spam of same item if laggy
                            end
                        end
                    end
                end
            end
        end
    end
end

-- >> AUTO LIST (Item & Pet)
local function RunAutoList()
    if not Config.AutoList then return end
    
    -- Check Active Listings (Avoid Duplicates)
    local data = GetBoothsData()
    local myData = data and data.Players[MyPlayerKey]
    local listedUUIDs = {}
    if myData and myData.Listings then
        for _, v in pairs(myData.Listings) do listedUUIDs[v.ItemId] = true end
    end
    
    local targetLower = CachedTargets.List
    local targetType = Config.ListCategory == "Pet" and "Pet" or "Holdable"
    local price = Config.Price
    local currentTime = tick()
    
    if targetType == "Pet" then
        -- Pet Listing (requires DataService)
        local playerData = DataService and DataService:GetData()
        if playerData and playerData.PetsData and playerData.PetsData.PetInventory then
            for petUUID, petData in pairs(playerData.PetsData.PetInventory.Data) do
                if not Config.Running or not Config.AutoList then break end
                
                if not listedUUIDs[petUUID] and (not ListingDebounce[petUUID] or currentTime - ListingDebounce[petUUID] > 5) then
                    local petName = petData.PetType or petData.Name
                    if petName and string.find(string.lower(petName), targetLower) then
                        pcall(function() CreateListingRemote:InvokeServer("Pet", petUUID, price) end)
                        ListingDebounce[petUUID] = currentTime
                        task.wait(Config.Speed)
                    end
                end
            end
        end
    else
        -- Item Listing (Backpack)
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in pairs(backpack:GetChildren()) do
                if not Config.Running or not Config.AutoList then break end
                
                if item:IsA("Tool") then
                    local realName = item:GetAttribute("f") -- Name
                    local uuid = item:GetAttribute("c")     -- UUID
                    
                    if realName and uuid and not listedUUIDs[uuid] and (not ListingDebounce[uuid] or currentTime - ListingDebounce[uuid] > 5) then
                         if string.find(string.lower(realName), targetLower) then
                             pcall(function() CreateListingRemote:InvokeServer("Holdable", uuid, price) end)
                             ListingDebounce[uuid] = currentTime
                             task.wait(Config.Speed)
                         end
                    end
                end
            end
        end
    end
end

-- >> AUTO CLEAR (Smart Remove)
local function RunAutoClear()
    if not Config.AutoClear then return end
    
    local data = GetBoothsData()
    if not data then return end
    local myData = data.Players[MyPlayerKey]
    
    local targetLower = CachedTargets.Remove
    local targetType = Config.RemoveCategory == "Pet" and "Pet" or "Holdable"
    
    if myData and myData.Listings then
        for listingUUID, listingInfo in pairs(myData.Listings) do
            if not Config.Running or not Config.AutoClear then break end
            
            -- Filter by Category first
            if listingInfo.ItemType == targetType or Config.DeleteAll then
                local itemId = listingInfo.ItemId
                local itemData = myData.Items[itemId]
                
                if itemData then
                    local realName = itemData.Name or itemData.ItemName or itemData.PetType or (itemData.ItemData and itemData.ItemData.ItemName) or ""
                    
                    if Config.DeleteAll or string.find(string.lower(tostring(realName)), targetLower) then
                         pcall(function() RemoveListingRemote:InvokeServer(listingUUID) end)
                         task.wait(Config.Speed)
                    end
                end
            end
        end
    end
end

-- >> AUTO CLAIM
local function RunAutoClaim()
    if not Config.AutoClaim then return end
    if GetMyBooth() then return end
    
    local folder = Workspace:FindFirstChild("TradeWorld") and Workspace.TradeWorld:FindFirstChild("Booths")
    if not folder then return end
    
    for _, booth in pairs(folder:GetChildren()) do
         local oid = booth:GetAttribute("OwnerId")
         if not oid then local v = booth:FindFirstChild("OwnerId"); if v then oid = v.Value end end
         
         if oid == nil or oid == 0 or oid == "" then
             pcall(function() ClaimBoothRemote:FireServer(booth) end)
             if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                  LocalPlayer.Character:SetPrimaryPartCFrame(booth.PrimaryPart.CFrame + Vector3.new(0,3,0))
             end
             task.wait(1)
             if GetMyBooth() then return end
         end
    end
end

-- [6] API EXPORTS
function Controller.UnclaimBooth()
    pcall(function() RemoveBoothRemote:FireServer() end)
end

function Controller.RequestUpdate()
    Controller.UpdateCache()
end

-- [7] MAIN LOOP
task.spawn(function()
    print("[XZNE] Logic Core v28 Started")
    while true do
        if not Config.Running then task.wait(1) else
            pcall(function()
                if Config.AutoClaim then RunAutoClaim() end
                if Config.AutoBuy   then RunAutoBuy()   end
                if Config.AutoList  then RunAutoList()  end
                if Config.AutoClear then RunAutoClear() end
            end)
            
            -- Dynamic Speed
            task.wait(Config.Speed or 1)
        end
    end
end)