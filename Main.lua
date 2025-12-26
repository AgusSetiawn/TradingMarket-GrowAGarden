--[[ 
    💠 XZNE SCRIPTHUB v0.0.01 [Beta] - LOGIC CORE
    
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

-- [2] CONTROLLER SETUP (Protected from double execution)
if _G.XZNE_Controller then
    warn("⚠️ [XZNE] Already running! Cleaning up old instance...")
    
    -- Stop old controller immediately (safe access)
    if _G.XZNE_Controller.Config then
        _G.XZNE_Controller.Config.Running = false
        _G.XZNE_Controller.Config.AutoBuy = false
        _G.XZNE_Controller.Config.AutoList = false
        _G.XZNE_Controller.Config.AutoClear = false
        _G.XZNE_Controller.Config.AutoClaim = false
    end
    
    -- Destroy old window if exists
    if _G.XZNE_Controller.Window and _G.XZNE_Controller.Window.Destroy then
        pcall(function() 
            _G.XZNE_Controller.Window:Destroy() 
        end)
    end
    
    -- Wait for cleanup but keep config
    task.wait(0.5)
    print("✅ [XZNE] Old instance cleaned, reinitializing...")
end

_G.XZNE_Controller = {
    Config = {
        -- Global
        Running = true,
        Speed = 1.0, -- Deprecated: kept for backward compatibility
        
        -- Auto Buy (Sniper)
        AutoBuy = false,
        BuyCategory = "Item", -- "Item" or "Pet"
        BuyTarget = "Bone Blossom",
        MaxPrice = 5,
        BuySpeed = 1.0, -- Individual speed control (0-10 seconds)
        
        -- Auto List
        AutoList = false,
        ListCategory = "Item", 
        ListTarget = "Bone Blossom",
        Price = 5, -- (ListPrice)
        ListSpeed = 1.0, -- Individual speed control (0-10 seconds)
        
        -- Auto Clear
        AutoClear = false,
        RemoveCategory = "Item",
        RemoveTarget = "Bone Blossom",
        RemoveSpeed = 1.0, -- Individual speed control (0-10 seconds)
        
        -- Auto Claim
        AutoClaim = false,
    },
    Stats = {
        ListedCount = 0,
        LastListTime = 0,
        SnipeCount = 0
    },
    Window = nil -- Store window reference for cleanup
}

local Controller = _G.XZNE_Controller
local Config = Controller.Config
local Stats = Controller.Stats
local ListingDebounce = {}
local CachedTargets = { Buy = "", List = "", Remove = "" }

-- [CONFIG PERSISTENCE]
local FileName = "XZNE_Config.json"

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

-- Load saved config immediately after initialization
Controller.LoadConfig()

-- [PERFORMANCE] Caches
local BoothCache = { booth = nil, time = 0 }
local DataCache = { data = nil, time = 0 }
local PlayerLookupCache = {}

-- [PERFORMANCE] Debounce Cleanup (runs every 30s)
task.spawn(function()
    while true do
        task.wait(30)
        local currentTime = tick()
        for uuid, timestamp in pairs(ListingDebounce) do
            if currentTime - timestamp > 10 then
                ListingDebounce[uuid] = nil
            end
        end
        -- Cleanup player lookup cache
        for userId, cacheEntry in pairs(PlayerLookupCache) do
            if currentTime - cacheEntry.time > 5 then
                PlayerLookupCache[userId] = nil
            end
        end
    end
end)

local function GetBoothsData()
    local currentTime = tick()
    -- Cache for 1 second to avoid repeated calls in same loop
    if DataCache.data and (currentTime - DataCache.time < 1) then
        return DataCache.data
    end
    
    local data = nil
    if BoothsReceiver then data = BoothsReceiver:GetData()
    elseif TradeBoothsData then data = TradeBoothsData:GetData() end
    
    DataCache.data = data
    DataCache.time = currentTime
    return data
end

local function GetMyBooth()
    local currentTime = tick()
    -- Cache for 2 seconds
    if BoothCache.booth and (currentTime - BoothCache.time < 2) then
        return BoothCache.booth
    end
    
    local folder = Workspace:FindFirstChild("TradeWorld")
    if folder then folder = folder:FindFirstChild("Booths") end
    for _, b in pairs(folder and folder:GetChildren() or {}) do
        local oid = b:GetAttribute("OwnerId") or b:GetAttribute("UserId")
        if not oid then local v = b:FindFirstChild("OwnerId"); if v then oid = v.Value end end
        if tostring(oid) == tostring(LocalUserId) then
            BoothCache.booth = b
            BoothCache.time = currentTime
            return b
        end
    end
    BoothCache.booth = nil
    BoothCache.time = currentTime
    return nil
end

local function GetCachedPlayer(userId)
    local currentTime = tick()
    local cached = PlayerLookupCache[userId]
    if cached and (currentTime - cached.time < 5) then
        return cached.player
    end
    
    local player = Players:GetPlayerByUserId(userId)
    PlayerLookupCache[userId] = { player = player, time = currentTime }
    return player
end

-- [5] CORE LOGIC

-- >> AUTO BUY (SNIPER)
local function RunAutoBuy()
    if not Config.AutoBuy then return end
    
    local data = GetBoothsData()
    if not data then return end
    
    local targetType = Config.BuyCategory == "Pet" and "Pet" or "Holdable"
    local targetLower = CachedTargets.Buy
    if targetLower == "" then return end -- Early exit
    
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
                            -- Buy with cached player lookup!
                            local ownerId = tonumber(string.match(playerKey, "Player_(%d+)"))
                            local owner = GetCachedPlayer(ownerId)
                            
                            if owner then
                                print("🔫 Sniping: " .. realName .. " @ " .. listingInfo.Price)
                                pcall(function() BuyListingRemote:InvokeServer(owner, listingUUID) end)
                                Stats.SnipeCount = Stats.SnipeCount + 1
                                task.wait(Config.BuySpeed or 1.0)
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
    
    local targetLower = CachedTargets.List
    if targetLower == "" then return end -- Early exit
    
    -- Check Active Listings (Avoid Duplicates)
    local data = GetBoothsData()
    local myData = data and data.Players[MyPlayerKey]
    local listedUUIDs = {}
    if myData and myData.Listings then
        for _, v in pairs(myData.Listings) do listedUUIDs[v.ItemId] = true end
    end
    
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
                        task.wait(Config.ListSpeed or 1.0)
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
                    local realName = item:GetAttribute("f")
                    local uuid = item:GetAttribute("c")
                    
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
    
    local targetLower = CachedTargets.Remove
    if targetLower == "" then return end -- Early exit
    
    local data = GetBoothsData()
    if not data then return end
    local myData = data.Players[MyPlayerKey]
    
    local targetType = Config.RemoveCategory == "Pet" and "Pet" or "Holdable"
    
    if myData and myData.Listings then
        for listingUUID, listingInfo in pairs(myData.Listings) do
            if not Config.Running or not Config.AutoClear then break end
            
            -- Filter by Category first
            if listingInfo.ItemType == targetType then
                local itemId = listingInfo.ItemId
                local itemData = myData.Items[itemId]
                
                if itemData then
                    local realName = itemData.Name or itemData.ItemName or itemData.PetType or (itemData.ItemData and itemData.ItemData.ItemName) or ""
                    
                    if string.find(string.lower(tostring(realName)), targetLower) then
                         pcall(function() RemoveListingRemote:InvokeServer(listingUUID) end)
                         task.wait(Config.RemoveSpeed or 1.0)
                    end
                end
    end
end

-- >> AUTO CLAIM (Improved: Smart Empty Booth Search + TP)
local function RunAutoClaim()
    if not Config.AutoClaim then return end
    
    -- Find Booth Folder
    local folder = Workspace:FindFirstChild("TradeWorld") and Workspace.TradeWorld:FindFirstChild("Booths")
    if not folder then return end
    
    -- 1. Check if we ALREADY own a booth (Stop claiming to avoid spam/switching)
    for _, booth in pairs(folder:GetChildren()) do
        local ownerId = booth:GetAttribute("OwnerId") or booth:GetAttribute("UserId")
        if not ownerId then
            local ownerValue = booth:FindFirstChild("OwnerId") or booth:FindFirstChild("UserId")
            if ownerValue then ownerId = ownerValue.Value end
        end
        
        -- If we own this booth, stop and optionally teleport to it
        if ownerId and tonumber(ownerId) == LocalUserId then
            -- Already have booth, no need to claim more
            return
        end
    end
    
    -- 2. Search for Empty Booth and Claim
    for _, booth in pairs(folder:GetChildren()) do
        if not Config.Running or not Config.AutoClaim then break end
        
        -- Get owner ID
        local ownerId = booth:GetAttribute("OwnerId") or booth:GetAttribute("UserId")
        if not ownerId then
            local ownerValue = booth:FindFirstChild("OwnerId") or booth:FindFirstChild("UserId")
            if ownerValue then ownerId = ownerValue.Value end
        end
        
        -- If booth is empty (nil, 0, or empty string)
        if ownerId == nil or ownerId == 0 or ownerId == "" then
            -- Try to claim
            local success = pcall(function()
                ClaimBoothRemote:FireServer(booth)
            end)
            
            if success then
                -- Teleport to booth (Improved: Natural position + velocity reset)
                local char = LocalPlayer.Character
                if char and char.PrimaryPart and booth.PrimaryPart then
                    -- TP to booth (Y+3 above, Z+2 forward for natural look)
                    char:SetPrimaryPartCFrame(booth.PrimaryPart.CFrame * CFrame.new(0, 3, 2))
                    
                    -- Reset velocity to prevent character being thrown
                    if char.PrimaryPart.AssemblyLinearVelocity then
                        char.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                end
                
                print("✅ [XZNE] Booth Claimed & Teleported!")
                
                -- Wait for server to process ownership
                task.wait(2)
                
                -- Exit loop (Mission complete)
                return
            end
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
    print("[XZNE] Logic Core v0.0.01 [Beta] Started")
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