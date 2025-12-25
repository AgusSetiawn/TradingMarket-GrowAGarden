--[[
    💠 XZNE SCRIPTHUB v28.0 - ENTERPRISE LOADER
    
    🚀 Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/main.lua"))()
]]

local Repo = "https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/"
print("[XZNE] Booting v28.0 Enterprise Loader...")

local function LoadScript(Script)
    local Success, Result = pcall(function()
        return loadstring(game:HttpGet(Repo .. Script .. "?t=" .. tostring(os.time())))()
    end)
    
    if not Success then
        warn("[XZNE] Failed to load " .. Script .. ": " .. tostring(Result))
    end
end

-- 1. Load Logic
LoadScript("Main.lua")

-- 2. Wait for Controller (Safety Check)
local Timeout = 0
while not _G.XZNE_Controller and Timeout < 5 do
    task.wait(0.2) -- Optimized from 0.5s
    Timeout = Timeout + 0.2
end

-- 3. Load GUI
LoadScript("Gui.lua")
