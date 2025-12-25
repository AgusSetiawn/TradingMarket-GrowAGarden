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
        return loadstring(game:HttpGet(Repo .. Script .. "?t=" .. tostring(os.time())))()
    end)
    
    if not Success then
        warn("[XZNE] Failed to load " .. Script .. ": " .. tostring(Result))
        -- Fallback not needed if Repo is correct
    end
end

-- 1. Load GUI First (So User sees UI instantly)
-- Pre-init controller stub so Gui doesn't error
if not _G.XZNE_Controller then _G.XZNE_Controller = { Config = {} } end

print("🎨 [XZNE] Loading Interface...")
-- [SOLUSI ALTERNATIF CACHE]
-- Retry Loop + Aggressive Cache Busting (Random Number)
local GuiLoaded = false
for i = 1, 3 do
    local success, err = pcall(function()
        -- Tambah math.random untuk unique URL setiap request
        loadstring(game:HttpGet(Repo .. "Gui.lua?t=" .. tostring(os.time()) .. "&r=" .. tostring(math.random(1, 10000))))()
    end)
    if success then 
        GuiLoaded = true 
        break 
    else
        warn("[XZNE] Attempt " .. i .. " failed to load Gui.lua: " .. tostring(err))
        task.wait(1)
    end
end
if not GuiLoaded then warn("❌ FATAL: Could not load Gui.lua after 3 attempts.") end

-- 2. Load Logic Core (Main.lua)
print("🧠 [XZNE] Loading Logic...")
LoadScript("Main.lua")
