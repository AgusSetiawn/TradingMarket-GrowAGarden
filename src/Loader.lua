--[[
    💠 XZNE SCRIPTHUB v0.0.01 [Beta] - LOADER
    
    🚀 Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/perf-v28.1/Loader.lua"))()
]]

-- IMPORTANT: Official Main Branch
local Repo = "https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/"

-- [CRITICAL] Execution Lock: Prevent re-entry during load
if _G.XZNE_EXECUTING then
    warn("⚠️ [XZNE] Script is already loading! Please wait for current execution to finish.")
    warn("⚠️ [XZNE] If stuck, wait 10 seconds or restart Roblox.")
    return
end
_G.XZNE_EXECUTING = true

local function LoadScript(Script)
    -- Cache Busting: ?t=os.time() forces fresh download every execution
    local Success, Result = pcall(function()
        local Content = game:HttpGet(Repo .. Script .. "?t=" .. tostring(os.time()))
        
        -- CRITICAL: Validate content before loadstring
        if not Content or #Content < 50 then 
            return nil, "HTTP Error: Empty or invalid content (got " .. #(Content or "") .. " bytes)"
        end
        
        -- Check if content looks like valid Lua (starts with -- or local or function)
        local firstLine = string.match(Content, "^([^\n]+)")
        if not firstLine or (#firstLine > 0 and not string.match(firstLine, "^%-%-") and not string.match(firstLine, "^%s*local") and not string.match(firstLine, "^%s*function")) then
            warn("⚠️ [XZNE DEBUG] Suspicious content for " .. Script .. ": " .. tostring(firstLine))
        end
        
        local Func, SyntaxErr = loadstring(Content)
        if not Func then
            return nil, "Syntax Error: " .. tostring(SyntaxErr)
        end
        
        return Func()
    end)
    
    if not Success or Result == nil then
        warn("❌ [XZNE] Failed to load " .. Script .. ": " .. tostring(Result))
        return false
    end
    
    return true
end

-- 1. Load Logic
local mainLoaded = LoadScript("src/Main.lua")

if not mainLoaded then
    warn("❌ [XZNE] Failed to load Main.lua! Check GitHub repo structure.")
    _G.XZNE_EXECUTING = false
    return
end

-- 2. Wait for Controller (Safety Check)
local Timeout = 0
while not _G.XZNE_Controller and Timeout < 10 do
    task.wait(0.2)
    Timeout = Timeout + 0.2
end

if not _G.XZNE_Controller then
    warn("❌ [XZNE] Controller Failed to Load! Check Main.lua.")
    _G.XZNE_EXECUTING = false  -- Release lock on failure
    return
end

-- 3. Load GUI (Clean Modular Load)
LoadScript("src/Gui.lua")

-- [CRITICAL] Release execution lock after successful load
task.defer(function()
    task.wait(0.5)  -- Small delay to ensure GUI is stable
    _G.XZNE_EXECUTING = false
end)
