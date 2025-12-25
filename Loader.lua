--[[
    💠 XZNE SCRIPTHUB v0.0.01 [Beta] - LOADER
    
    🚀 Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/perf-v28.1/Loader.lua"))()
]]

-- IMPORTANT: Official Main Branch
local Repo = "https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/"
print("[XZNE] Booting v0.0.01 [Beta] (Official Main)...")

-- [ADVANCED LOADER]
local function SmartLoad(ScriptName)
    local Url = Repo .. ScriptName .. "?t=" .. tostring(os.time()) .. "&r=" .. tostring(math.random(1, 100000))
    local Content = nil
    
    -- Try 1: request/http_request (Better for bypassing cache)
    local req = (http_request or request or HttpPost)
    if req then
        pcall(function()
            local response = req({Url = Url, Method = "GET"})
            if response and response.Body then Content = response.Body end
        end)
    end
    
    -- Try 2: game:HttpGet (Standard Fallback)
    if not Content then
        pcall(function() Content = game:HttpGet(Url) end)
    end
    
    if Content then
        local func, err = loadstring(Content)
        if func then 
            func() 
            return true
        else
            warn("[XZNE] Syntax Error in " .. ScriptName .. ": " .. tostring(err))
        end
    else
        warn("[XZNE] Empty content for " .. ScriptName)
    end
    return false
end

-- Retry Loop for Gui
local GuiLoaded = false
for i = 1, 3 do
    if SmartLoad("Gui.lua") then 
        GuiLoaded = true 
        break 
    end
    warn("[XZNE] Attempt " .. i .. " failed to load Gui.lua. Retrying...")
    task.wait(1.5)
end

if not GuiLoaded then warn("❌ FATAL: Could not load Gui.lua after 3 attempts.") end

-- 2. Load Logic Core (Main.lua)
print("🧠 [XZNE] Loading Logic...")
LoadScript("Main.lua")
