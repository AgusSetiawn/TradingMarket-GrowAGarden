--[[
    💠 XZNE SCRIPTHUB v0.0.01 [Beta] - LOADER
    
    🚀 Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/perf-v28.1/Loader.lua"))()
]]

-- IMPORTANT: Pointing to perf-v28.1 branch for Beta access
local Repo = "https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/perf-v28.1/"
print("[XZNE] Booting v0.0.01 [Beta] (Modular)...")

local function LoadScript(Script)
    -- Cache Busting: ?t=os.time() forces fresh download every execution
    local Success, Result = pcall(function()
        return loadstring(game:HttpGet(Repo .. Script .. "?t=" .. tostring(os.time())))()
    end)
    
    if not Success then
        warn("[XZNE] Failed to load " .. Script .. ": " .. tostring(Result))
        -- Fallback not needed if Repo is correct
    end
end

-- 1. Load Logic
LoadScript("Main.lua")

-- 2. Wait for Controller (Safety Check)
local Timeout = 0
while not _G.XZNE_Controller and Timeout < 10 do
    task.wait(0.2)
    Timeout = Timeout + 0.2
end

if not _G.XZNE_Controller then
    warn("❌ [XZNE] Controller Failed to Load! Check Main.lua.")
    return
end

-- 3. Load GUI (Clean Modular Load)
LoadScript("Gui.lua")
