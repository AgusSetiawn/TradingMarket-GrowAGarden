--[[
    💠 XZNE SCRIPTHUB v28.0 - MASTER LOADER
    
    🚀 Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/Loader.lua"))()
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
    task.wait(0.5)
    Timeout = Timeout + 0.5
end

-- 3. Load GUI
LoadScript("Gui.lua")
