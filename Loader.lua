--[[
    💠 XZNE SCRIPTHUB v0.0.01 [Beta] - LOADER
    
    🚀 Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/perf-v28.1/Loader.lua"))()
]]

-- IMPORTANT: Official Main Branch
local Repo = "https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/"
print("[XZNE] Booting v0.0.01 [Beta] (Official Main)...")

local function LoadScript(Script)
    -- Cache Busting: ?t=os.time() forces fresh download every execution
    local Success, Result = pcall(function()
        local Content = game:HttpGet(Repo .. Script .. "?t=" .. tostring(os.time()))
        if not Content then return nil, "HTTP 404/Empty" end
        
        local Func, SyntaxErr = loadstring(Content)
        if not Func then
            return nil, "Syntax Error: " .. tostring(SyntaxErr)
        end
        
        return Func()
    end)
    
    if not Success or Result == nil then
        warn("❌ [XZNE] Failed to load " .. Script .. ": " .. tostring(Result))
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
