--[[ 
    💠 XZNE SCRIPTHUB v18.0 - LOGIC CORE
    
    🔧 REFACTOR NOTES:
    - UI completely removed (moved to Loader.lua)
    - "Auto Clear" removed due to bugs
    - "Clear Mode" & "Clear Delay" removed
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
        TargetName = "Bone Blossom",  -- Attribute 'f'
        Price = 5,
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
local ListedCache = {}

-- [3] REMOTES
local TradeEvents = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("TradeEvents")
local Booths = TradeEvents:WaitForChild("Booths")
local CreateListingRemote = Booths:WaitForChild("CreateListing")
local ClaimBoothRemote = Booths:WaitForChild("ClaimBooth")
local RemoveBoothRemote = Booths:WaitForChild("RemoveBooth")

-- [4] HELPER FUNCTIONS

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

-- [CRITICAL] Find Target UUID - EXACT COPY from v2.0
local function FindTargetUUID()
    local locations = {
        LocalPlayer:FindFirstChild("Backpack"), 
        LocalPlayer.Character
    }
    
    for _, loc in pairs(locations) do
        if loc then
            for _, item in pairs(loc:GetChildren()) do
                if item:IsA("Tool") then
                    local realName = item:GetAttribute("f")
                    if realName and string.find(string.lower(realName), string.lower(Config.TargetName)) then
                        local uuid = item:GetAttribute("c")
                        if uuid and not ListedCache[uuid] then
                            return uuid, item.Name
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

-- [5] CORE LOGIC TASKS

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
        
        if not ownerId or ownerId == 0 or ownerId == "" then
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
            ListedCache[uuid] = true
            Stats.LastListTime = tick()
            Stats.ListedCount = Stats.ListedCount + 1
        else
            ListedCache[uuid] = nil
        end
    end
end

-- [6] API EXPORTS
function Controller.UnclaimBooth()
    pcall(function() RemoveBoothRemote:FireServer() end)
end

function Controller.ClearCache()
    ListedCache = {}
    Stats.ListedCount = 0
end

-- [7] MAIN LOOP
task.spawn(function()
    print("[XZNE] Logic Core Started")
    while Config.Running do
        if Config.AutoClaim then
            RunAutoClaim()
            task.wait(0.5)
        end
        
        if Config.AutoList then
            RunAutoList()
            task.wait(Config.ListDelay)
        else
            task.wait(1)
        end
    end
    print("[XZNE] Logic Core Stopped")
end)