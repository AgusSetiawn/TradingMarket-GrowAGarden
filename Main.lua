--[[ 
    💠 XZNE SCRIPTHUB v0.0.01 [Beta] - LOGIC CORE
    
    🔧 FEATURES:
    - Auto Buy (Sniper) [NEW]
    - Pet Support (DataService) [NEW]
    - Smart List & Clear (Item/Pet)
    - Auto Claim (Fast)
    - Performance Optimizations (Cached Targets)
]]

-- [1] SERVICES & PERFORMANCE OPTIMIZATIONS
-- Cache globals for 3-5x faster operations in hot paths
local string_lower = string.lower
local string_find = string.find
local string_match = string.match
local tostring = tostring
local tonumber = tonumber
local math_floor = math.floor
local math_max = math.max
local pairs = pairs
local tick = tick

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
    
    -- Stop old controller immediately
    _G.XZNE_Controller.Config.Running = false
    
    -- Destroy old window if exists
    if _G.XZNE_Controller.Window and _G.XZNE_Controller.Window.Destroy then
        pcall(function() 
            _G.XZNE_Controller.Window:Destroy() 
        end)
    end
    
    -- Clear global reference
    _G.XZNE_Controller = nil
    
    -- Wait for cleanup
    task.wait(0.8)
end

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
    },
    Window = nil -- Store window reference for cleanup
}

local Controller = _G.XZNE_Controller
local Config = Controller.Config
local Stats = Controller.Stats
local ListingDebounce = {}
local CachedTargets = { Buy = "", List = "", Remove = "" }

-- [CONFIG]
-- Config is now handled by Gui.lua (WindUI ConfigManager)
-- Passively holds state for logic to use.


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

-- ✅ OPTIMIZATION: Use defer instead of spawn to ensure GUI loads first
task.defer(function()
    pcall(function()
        local RepModules = ReplicatedStorage:WaitForChild("Modules", 10)  -- Increased timeout
        if RepModules then
            -- Booths Hook
            local ReplicationReciever = require(RepModules:WaitForChild("ReplicationReciever", 5))
            if ReplicationReciever then
                BoothsReceiver = ReplicationReciever.new("Booths")
            else
                warn("❌ [XZNE] ReplicationReciever not found!")
            end
            -- Pets Hook
            DataService = require(RepModules:WaitForChild("DataService", 5))
            if DataService then 
                -- Hooked successfully
            else
                warn("❌ [XZNE] DataService not found!")
            end
        else
            warn("❌ [XZNE] Modules folder not found in ReplicatedStorage!")
        end
    end)
    
    if not BoothsReceiver then
        pcall(function()
            TradeBoothsData = require(ReplicatedStorage.Data.TradeBoothsData)
        end)
        if not TradeBoothsData then
            warn("❌ [XZNE] TradeBoothsData fallback ALSO failed! Auto functions will NOT work.")
        end
    end
end)

-- [4] HELPERS & OPTIMIZATION

-- Update Cached Strings (Call this when Config changes)
function Controller.UpdateCache()
    CachedTargets.Buy = string.lower(Config.BuyTarget or "")
    CachedTargets.List = string.lower(Config.ListTarget or "")
    CachedTargets.Remove = string.lower(Config.RemoveTarget or "")
    
    -- Multi-Target Caching (Pet/Item Simultaneous)
    CachedTargets.BuyPet = string.lower(Config.BuyTargetPet or "")
    CachedTargets.BuyItem = string.lower(Config.BuyTargetItem or "")
    
    -- Filter "none" to empty string for safety
    if CachedTargets.BuyPet == "— none —" then CachedTargets.BuyPet = "" end
    if CachedTargets.BuyItem == "— none —" then CachedTargets.BuyItem = "" end
end
Controller.UpdateCache() -- Init

-- Init Cache
Controller.UpdateCache()

-- [PERFORMANCE] Caches
local BoothCache = { booth = nil, time = 0 }
local DataCache = { data = nil, time = 0 }
local PlayerLookupCache = {}

-- [PERFORMANCE] Debounce Cleanup (runs every 30s)
-- ✅ OPTIMIZATION: Defer start and skip empty table iterations
task.defer(function()
    while true do
        task.wait(30)
        local currentTime = tick()
        
        -- Only iterate if table has entries
        if next(ListingDebounce) then
            for uuid, timestamp in pairs(ListingDebounce) do
                if currentTime - timestamp > 10 then
                    ListingDebounce[uuid] = nil
                end
            end
        end
        
        -- Cleanup player lookup cache (only if not empty)
        if next(PlayerLookupCache) then
            for userId, cacheEntry in pairs(PlayerLookupCache) do
                if currentTime - cacheEntry.time > 5 then
                    PlayerLookupCache[userId] = nil
                end
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
    if BoothsReceiver then 
        data = BoothsReceiver:GetData()
    elseif TradeBoothsData then 
        data = TradeBoothsData:GetData() 
    else
        -- DEBUG: Log if no hooks available
        if not DataCache.warningShown then
            warn("⚠️ [XZNE DEBUG] No data hooks available (BoothsReceiver and TradeBoothsData are nil)")
            DataCache.warningShown = true
        end
    end
    
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
        -- Optimized: Use cached tostring
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
    if not data then 
        return 
    end
    
    -- Remove Single Target Logic
    -- local targetType = Config.BuyCategory == "Pet" and "Pet" or "Holdable"
    -- local targetLower = CachedTargets.Buy
    -- if targetLower == "" then return end
    
    local maxPrice = Config.MaxPrice
    
    for playerKey, playerData in pairs(data.Players) do
        if not Config.Running then break end
        if playerKey ~= MyPlayerKey and playerData.Listings then
            for listingUUID, listingInfo in pairs(playerData.Listings) do
                if not Config.AutoBuy then break end -- FIX: Check toggle inside loop
                -- Optimization: Price Check FIRST (fastest fail)
                if listingInfo.Price <= maxPrice then
                     -- Multi-Target Check
                     local targetMatch = false
                     local listType = listingInfo.ItemType
                     
                     if listType == "Pet" and CachedTargets.BuyPet ~= "" then targetMatch = true 
                     elseif listType == "Holdable" and CachedTargets.BuyItem ~= "" then targetMatch = true
                     end
                     
                     if targetMatch then
                    local itemData = playerData.Items[listingInfo.ItemId]
                    if itemData then
                        local realName = itemData.Name or itemData.ItemName or itemData.PetType or (itemData.ItemData and itemData.ItemData.ItemName) or ""
                        local lowerName = string_lower(tostring(realName))
                        local isMatch = false
                        
                        -- Specific Name Check based on Type
                        if listingInfo.ItemType == "Pet" then
                            if string_find(lowerName, CachedTargets.BuyPet) then isMatch = true end
                        elseif listingInfo.ItemType == "Holdable" then
                             if string_find(lowerName, CachedTargets.BuyItem) then isMatch = true end
                        end
                        
                        -- Optimized: Use cached string functions
                        if isMatch then
                            -- Buy with cached player lookup!
                            local ownerId = tonumber(string_match(playerKey, "Player_(%d+)"))
                            local owner = GetCachedPlayer(ownerId)
                            
                            if owner then
                                pcall(function() BuyListingRemote:InvokeServer(owner, listingUUID) end)
                                Stats.SnipeCount = Stats.SnipeCount + 1
                                pcall(function() BuyListingRemote:InvokeServer(owner, listingUUID) end)
                                Stats.SnipeCount = Stats.SnipeCount + 1
                                task.wait(Config.Speed) -- Respect global speed setting
                            end
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
    
    -- Remove Early Exit
    -- local targetLower = CachedTargets.List
    -- if targetLower == "" then return end
    
    -- Check Active Listings (Avoid Duplicates)
    local data = GetBoothsData()
    local myData = data and data.Players[MyPlayerKey]
    local listedUUIDs = {}
    if myData and myData.Listings then
        for _, v in pairs(myData.Listings) do listedUUIDs[v.ItemId] = true end
    end
    
    -- Remove Single Target Logic
    -- local targetType = Config.ListCategory == "Pet" and "Pet" or "Holdable"
    local price = Config.Price
    local currentTime = tick()
    
    -- Dual Logic: Check both PET and ITEM lists sequentially
    
    -- 1. Pet Listing
    if CachedTargets.List == "Pet" or CachedTargets.BuyPet ~= "" then
        -- Pet Listing logic...
        local petTarget = CachedTargets.BuyPet
        if petTarget ~= "" then
        -- Pet Listing (requires DataService)
        local playerData = DataService and DataService:GetData()
        if playerData and playerData.PetsData and playerData.PetsData.PetInventory then
            for petUUID, petData in pairs(playerData.PetsData.PetInventory.Data) do
                if not Config.Running or not Config.AutoList then break end
                
                if not listedUUIDs[petUUID] and (not ListingDebounce[petUUID] or currentTime - ListingDebounce[petUUID] > 5) then
                    local petName = petData.PetType or petData.Name
                    -- Optimized: Use cached string functions
                    if petName and string_find(string_lower(petName), petTarget) then
                        pcall(function() CreateListingRemote:InvokeServer("Pet", petUUID, price) end)
                        ListingDebounce[petUUID] = currentTime
                        task.wait(Config.Speed)
                    end
                end
            end
    -- End Dual Logic
        end
    end
    end

    -- 2. Item Listing
    if CachedTargets.List == "Holdable" or CachedTargets.BuyItem ~= "" then
        local itemTarget = CachedTargets.BuyItem
        if itemTarget ~= "" then
        
        -- Item Listing (Backpack)
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in pairs(backpack:GetChildren()) do
                if not Config.AutoList then break end -- FIX: Check toggle inside loop
                if not Config.Running or not Config.AutoList then break end
                
                if item:IsA("Tool") then
                    local realName = item:GetAttribute("f")
                    local uuid = item:GetAttribute("c")
                    
                    if realName and uuid and not listedUUIDs[uuid] and (not ListingDebounce[uuid] or currentTime - ListingDebounce[uuid] > 5) then
                         -- Optimized: Use cached string functions
                         if string_find(string_lower(realName), itemTarget) then
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
end

-- >> AUTO CLEAR (Smart Remove)
local function RunAutoClear()
    if not Config.AutoClear then return end
    
    -- Dual Logic:
    local targetLowerPet = CachedTargets.BuyPet
    local targetLowerItem = CachedTargets.BuyItem
    if not Config.DeleteAll and targetLowerPet == "" and targetLowerItem == "" then return end
    
    local data = GetBoothsData()
    if not data then return end
    local myData = data.Players[MyPlayerKey]
    
    -- Remove Single Target Type restriction
    -- local targetType = Config.RemoveCategory == "Pet" and "Pet" or "Holdable"
    
    if myData and myData.Listings then
        for listingUUID, listingInfo in pairs(myData.Listings) do
            if not Config.Running or not Config.AutoClear then break end
            
            -- Filter by Category (Multi-Target Friendly)
            if Config.DeleteAll or (listingInfo.ItemType == "Pet" and targetLowerPet ~= "") or (listingInfo.ItemType == "Holdable" and targetLowerItem ~= "") then
                local itemId = listingInfo.ItemId
                local itemData = myData.Items[itemId]
                
                if itemData then
                    local realName = itemData.Name or itemData.ItemName or itemData.PetType or (itemData.ItemData and itemData.ItemData.ItemName) or ""
                    
                    local lowerName = string_lower(tostring(realName))
                    local shouldRemove = false
                    
                    if Config.DeleteAll then shouldRemove = true
                    elseif listingInfo.ItemType == "Pet" and targetLowerPet ~= "" and string_find(lowerName, targetLowerPet) then shouldRemove = true
                    elseif listingInfo.ItemType == "Holdable" and targetLowerItem ~= "" and string_find(lowerName, targetLowerItem) then shouldRemove = true
                    end
                    
                    -- Optimized: Use cached string functions
                    if shouldRemove then
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
-- ✅ OPTIMIZATION: Defer start by 1s to let GUI render first
local MIN_SPEED = 0  -- Safety: Allow 0s delay as requested (was 0.5)

task.defer(function()
    task.wait(1)  -- Let GUI finish loading
    while true do
        if not Config.Running then task.wait(1) else
            pcall(function()
                if Config.AutoClaim then RunAutoClaim() end
                if Config.AutoBuy   then RunAutoBuy()   end
                if Config.AutoList  then RunAutoList()  end
                if Config.AutoClear then RunAutoClear() end
            end)
            
            -- Dynamic Speed with safety bound
            task.wait(math_max(Config.Speed or 1, MIN_SPEED))
        end
    end
end)

-- Return success to Loader
return true