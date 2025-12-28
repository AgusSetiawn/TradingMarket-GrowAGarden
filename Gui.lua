--[[
    💠 XZNE SCRIPTHUB v0.0.01 Beta - UI LOADER
    
    🎨 WindUI Interface
    🔗 Connects to: Main.lua (_G.XZNE_Controller)
]]

local WindUI
local Controller = _G.XZNE_Controller

if not Controller then
    warn("[XZNE] Controller not found! Please run Main.lua first.")
    return
end
print("✅ [XZNE DEBUG] Controller check passed")

-- [0] SAVE LOCK (Prevent overwrites during init)
if _G.XZNE_Restoring == nil then _G.XZNE_Restoring = true end


-- [1] CONFIGURATION SYSTEM (Moved to TOP for FORCE INIT)
-- Satisfies request: "XZNE ScriptHub/Config.json"
local HttpService = game:GetService("HttpService")
local ConfigFile = "XZNE ScriptHub/Config.json"

local function SaveToJSON()
    if not isfolder("XZNE ScriptHub") then makefolder("XZNE ScriptHub") end
    
    local success, json = pcall(function()
        return HttpService:JSONEncode(Controller.Config)
    end)
    
    if success then
        writefile(ConfigFile, json)
    end
end

local function AutoSave()
    if _G.XZNE_Restoring then 
        warn("⚠️ [XZNE DEBUG] AutoSave blocked (Restoring Phase)")
        return 
    end
    pcall(SaveToJSON)
    pcall(function() Controller.UpdateCache() end)
end

-- Load Logic (Passive)
local function LoadFromJSON()
    print("📂 [XZNE DEBUG] Attempting to load config from: " .. ConfigFile)
    if isfile(ConfigFile) then
        local success, result = pcall(readfile, ConfigFile)
        if success and result then
            print("   > File Read Success. Bytes: " .. #result)
            local decoded = HttpService:JSONDecode(result)
            if decoded then
                print("   > JSON Decode Success. Keys found: " .. table.getn(decoded) or "N/A")
                for k,v in pairs(decoded) do
                    Controller.Config[k] = v
                end
                Controller.UpdateCache()
                print("   > Config Updated. MaxPrice is now: " .. tostring(Controller.Config.MaxPrice))
                return true
            else
                 warn("❌ [XZNE DEBUG] JSON Decode Failed!")
            end
        else
            warn("❌ [XZNE DEBUG] Readfile Failed!")
        end
    else
        warn("⚠️ [XZNE DEBUG] Config file not found (First run?)")
    end
    return false
end

-- ⚡ FORCE LOAD CONFIG NOW (Before UI Creation)
-- This ensures 'Default' values in UI are correct from birth!
_G.XZNE_Restoring = true -- LOCK
local loadStatus = LoadFromJSON()
print("✅ [XZNE DEBUG] Config Init Done. Success: " .. tostring(loadStatus))



-- ❌ OPTIMIZATION: LoadConfig() already called in Main.lua (redundant)
-- Controller.LoadConfig() removed to save 50-100ms

-- [2] LOAD WINDUI
do
    local success, result = pcall(function()
        local url = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
        local content = game:HttpGet(url)
        if #content < 100 then warn("⚠️ WindUI content suspicious!") end
        
        local func, err = loadstring(content)
        if not func then error("WindUI Loadstring Error: " .. tostring(err)) end
        return func()
    end)
    
    if success and result then
        WindUI = result
    else
        warn("[XZNE] Failed to load WindUI lib! Error: " .. tostring(result))
        return
    end
end
print("✅ [XZNE DEBUG] WindUI Library Loaded")

-- [1] INSTANT LOADING FEEDBACK (Moved up)

-- [3] ICONS
-- Using WindUI Native Lucide Icons for better consistency and "Geist" feel.
-- No custom registration needed.

-- [4] LOAD DATABASES (DEFERRED for faster GUI appearance)
local PetDatabase, ItemDatabase = {}, {}
local DatabaseReady = false

-- ✅ OPTIMIZATION: JSON Database with Local Caching
local CachedDBFile = "XZNE ScriptHub/Database.json"

task.defer(function()
    task.wait(0.3)  -- Let GUI render first
    
    -- Create config folder if not exists
    if makefolder and not isfolder("XZNE ScriptHub") then
        makefolder("XZNE ScriptHub")
    end
    
    -- Try loading from local cache first (INSTANT if cached)
    if isfile and isfile(CachedDBFile) then
        local success, content = pcall(function()
            return readfile(CachedDBFile)
        end)
        
        if success and content and #content > 100 then
            local decodeSuccess, decoded = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            
            if decodeSuccess and decoded then
                PetDatabase = decoded.Pets or {}
                ItemDatabase = decoded.Items or {}
                DatabaseReady = true
                return  -- ✅ INSTANT LOAD - DONE!
            end
        end
    end
    
    -- Fallback: Download from GitHub (first run or cache failed)
    local Repo = "https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/"
    
    -- Try JSON first (50% faster than Lua)
    local success, content = pcall(function()
        return game:HttpGet(Repo .. "Database.json")
    end)
    
    if success and content and #content > 100 then
        local decodeSuccess, decoded = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        
        if decodeSuccess and decoded then
            PetDatabase = decoded.Pets or {}
            ItemDatabase = decoded.Items or {}
            
            -- Save to local cache for next time
            if writefile then
                pcall(function() 
                    writefile(CachedDBFile, content) 
                end)
            end
            
            DatabaseReady = true
            return
        end
    end
    
    -- Last resort: Try Lua format (backward compatibility)
    local luaSuccess, luaResult = pcall(function()
        return loadstring(game:HttpGet(Repo .. "Database.lua"))()
    end)
    
    if luaSuccess and luaResult then
        PetDatabase = luaResult.Pets or {}
        ItemDatabase = luaResult.Items or {}
        DatabaseReady = true
    else
        warn("❌ [XZNE] Failed to load database from all sources")
        PetDatabase = {}
        ItemDatabase = {}
        DatabaseReady = true
    end
end)

-- [5] CREATE WINDOW (Premium Mac-Style Design)
local Window = WindUI:CreateWindow({
    Title = "XZNE ScriptHub",
    Icon = "rbxassetid://123378346805284",  -- Lightning bolt icon (from Lucide library)
    Author = "By. Xzero One",
    Size = UDim2.fromOffset(580, 460),  -- Optimal size
    
    -- Premium Settings
    Transparency = 0.5,       -- Higher transparency for glassmorphism effect
    Acrylic = true,           -- Glassmorphism
    Theme = "Dark",
    NewElements = true,
    
    -- Mac Style Buttons (like screenshot!)
    ButtonsType = "Mac",  -- Red, Yellow, Green dots!
    
    Topbar = {
        Height = 50,
        CornerRadius = UDim.new(0, 8),
        Transparency = 0.1  -- Very transparent topbar
    },
    
    Sidebar = {
        Width = 180,
        Transparency = 0.15
    }
})
-- Store window reference for cleanup
Controller.Window = Window
print("✅ [XZNE DEBUG] Window Created")

-- [6] CONFIGURE OPEN BUTTON (Minimize State)
-- Matches the "Premium" aesthetic requested
Window:EditOpenButton({
    Title = "Open Hub",
    Icon = "rbxassetid://123378346805284",  -- Matches the Window Icon
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- Indigo to Purple Gradient matching theme
        Color3.fromRGB(99, 102, 241), 
        Color3.fromRGB(168, 85, 247) 
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

-- Add minimize toggle keybind (RightControl)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        pcall(function()
            if Window and Window.ToggleVisibility then
                Window:ToggleVisibility()
            elseif Window and Window.Visible ~= nil then
                Window.Visible = not Window.Visible
            end
        end)
    end
end)

local UIElements = {}

-- [MAIN TAB with Premium Icon]
local MainTab = Window:Tab({ 
    Title = "Trading", 
    Icon = "arrow-left-right",  -- Logical icon for "Trading" (Swapping)
    IconColor = Color3.fromRGB(99, 102, 241),  -- Indigo
    IconShape = "Square",  -- Colored square wrapper
})
MainTab:Space() -- Spacing for better UI

-- [SETTINGS TAB with Premium Icon]
local SettingsTab = Window:Tab({ 
    Title = "Settings", 
    Icon = "settings",  -- Settings gear icon
    IconColor = Color3.fromRGB(251, 146, 60),  -- Orange
    IconShape = "Square",  -- Colored square wrapper
})
SettingsTab:Space() -- Spacing for better UI

-- === TARGET SELECTION SECTION ===
local TargetSection = MainTab:Section({ 
    Title = "Target Selection", 
    Icon = "crosshair"
})

TargetSection:Paragraph({
    Title = "💡 Quick Guide",
    Desc = "Select your target Pet or Item below. Then enable which function you want to use (Buy/List/Remove)."
})
TargetSection:Space() -- Separate Guide from Dropdowns

-- SHARED Pet Dropdown (used by ALL functions)
UIElements.TargetPet = TargetSection:Dropdown({
    Title = "Target Pet", 
    Desc = "🔍 Search pets...",
    Values = {"— None —"}, Default = 1, SearchBarEnabled = true,
    Flag = "BuyTarget", -- Binds to Config
    Callback = function(val) 
        if _G.XZNE_Restoring then return end
        
        -- Logic Key (Active Target)
        Controller.Config.BuyTarget = val
        Controller.Config.ListTarget = val
        Controller.Config.RemoveTarget = val
        
        -- Logic Key (Category Enforcer)
        Controller.Config.BuyCategory = "Pet"
        Controller.Config.ListCategory = "Pet"
        Controller.Config.RemoveCategory = "Pet"
        
        -- UI Restoration Key (Unique to this dropdown)
        Controller.Config.BuyTargetPet = val 
        
        AutoSave()
    end
})

TargetSection:Space() -- Break merge

-- SHARED Item Dropdown (used by ALL functions)
UIElements.TargetItem = TargetSection:Dropdown({
    Title = "Target Item", 
    Desc = "🔍 Search items...",
    Values = {"— None —"}, Default = 1, SearchBarEnabled = true,
    Flag = "BuyTargetItem", -- Separate flag for Item dropdown
    Callback = function(val) 
        if _G.XZNE_Restoring then return end
        
        -- Logic Key (Active Target)
        Controller.Config.BuyTarget = val
        Controller.Config.ListTarget = val
        Controller.Config.RemoveTarget = val
        
        -- Logic Key (Category Enforcer)
        Controller.Config.BuyCategory = "Item"
        Controller.Config.ListCategory = "Item"
        Controller.Config.RemoveCategory = "Item"
        
        -- UI Restoration Key (Unique to this dropdown)
        Controller.Config.BuyTargetItem = val
        
        AutoSave()
    end
})

TargetSection:Space() -- Break merge

UIElements.DelaySlider = TargetSection:Slider({
    Title = "Action Delay",
    Desc = "Delay Interval (0–10s)",
    Step = 0.1,
    Value = {
        Min = 0,
        Max = 10,
        Default = Controller.Config.Speed or 1, -- Force load
    },
    Flag = "Speed",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.Speed = val
        AutoSave()
    end
})

TargetSection:Space() -- Final space before next section divider/end

-- === AUTO BUY SECTION ===
local BuySection = MainTab:Section({ Title = "Auto Buy (Sniper)", Icon = "shopping-bag" })

UIElements.MaxPrice = BuySection:Input({
    Title = "Max Price", Desc = "Maximum price to pay", Default = tostring(Controller.Config.MaxPrice or 5), Numeric = true,
    Flag = "MaxPrice",
    Callback = function(txt) 
        if _G.XZNE_Restoring then return end
        Controller.Config.MaxPrice = tonumber(txt) or 5
        AutoSave() 
    end
})

UIElements.AutoBuy = BuySection:Toggle({
    Title = "Enable Auto Buy", Desc = "Snipe selected target", Default = Controller.Config.AutoBuy or false,
    Flag = "AutoBuy",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        -- Validation
        if val and (UIElements.TargetPet.Value == "— None —" and UIElements.TargetItem.Value == "— None —") then
             -- No visual feedback needed
             warn("⚠️ Select a target first!")
        end
        Controller.Config.AutoBuy = val
        AutoSave()
    end
})

BuySection:Divider()

-- === AUTO LIST SECTION ===
local ListSection = MainTab:Section({ Title = "Auto List", Icon = "tag" })

UIElements.Price = ListSection:Input({
    Title = "Listing Price", Desc = "Price per item", Default = tostring(Controller.Config.Price or 5), Numeric = true,
    Flag = "Price",
    Callback = function(txt) 
        if _G.XZNE_Restoring then return end
        Controller.Config.Price = tonumber(txt) or 5
        AutoSave() 
    end
})

UIElements.AutoList = ListSection:Toggle({
    Title = "Enable Auto List", Desc = "List selected target", Default = Controller.Config.AutoList or false,
    Flag = "AutoList",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.AutoList = val
        AutoSave()
    end
})

ListSection:Divider()

-- === AUTO REMOVE SECTION ===
local RemoveSection = MainTab:Section({ Title = "Auto Remove", Icon = "trash-2" })

UIElements.AutoClear = RemoveSection:Toggle({
    Title = "Enable Auto Remove", Desc = "Remove selected target", Default = Controller.Config.AutoClear or false,
    Flag = "AutoClear",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.AutoClear = val
        AutoSave()
    end
})

RemoveSection:Divider()

-- === BOOTH CONTROL SECTION ===
local BoothSection = MainTab:Section({ Title = "Booth Control", Icon = "store" })

UIElements.AutoClaim = BoothSection:Toggle({
    Title = "Auto Claim Booth", Desc = "Automatically claim booth", Default = Controller.Config.AutoClaim or false,
    Flag = "AutoClaim",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.AutoClaim = val
        AutoSave()
    end
})

BoothSection:Button({
    Title = "Unclaim Booth", Desc = "Release booth ownership", Icon = "log-out",
    Callback = function() Controller.UnclaimBooth() end
})

-- [GUI POPULATION - 2 SHARED DROPDOWNS]
task.defer(function()
    -- Wait for database
    while not DatabaseReady do task.wait(0.1) end
    task.wait(1) -- Small delay for GUI stability
    
    -- Helper function to populate dropdowns  
    local function SafeUpdate(element, db)
        if element then
            -- Add database entries after "— None —"
            local values = {"— None —"}
            for _, item in ipairs(db) do
                table.insert(values, item)
            end
            element.Values = values
            element.Desc = "🔍 Search "..#db.." items..."
            if element.Refresh then pcall(function() element:Refresh(values) end) end
        end
    end
    
    -- Populate only 2 dropdowns (shared across all functions)
    SafeUpdate(UIElements.TargetPet, PetDatabase)
    task.wait(0.05)
    SafeUpdate(UIElements.TargetItem, ItemDatabase)
    
    -- Apply saved selections (only if valid and not None)
    -- LOAD CONFIG NOW (After dropdowns are populated)
    -- Apply saved selections (only if valid and not None)

    
end)

-- Stats Section (in Settings Tab)
local StatsSection = SettingsTab:Section({ Title = "📊 Session Statistics" })
local StatsParagraph = StatsSection:Paragraph({
    Title = "Performance Metrics",
    Desc = "Sniped: 0 | Listed: 0 | Removed: 0 | Uptime: 0m"
})

-- Stats Updater
task.spawn(function()
    local startTime = tick()
    while true do
        task.wait(10)
        local uptime = math.floor((tick() - startTime) / 60)
        pcall(function()
            if StatsParagraph and StatsParagraph.SetDesc then
                local s = Controller.Stats
                StatsParagraph:SetDesc(string.format("Sniped: %d | Listed: %d | Removed: %d | Uptime: %dm", 
                    s.SnipeCount, s.ListedCount, s.RemovedCount, uptime))
            end
        end)
    end
end)



-- Notify User
Controller.Window = Window
print("✅ [XZNE] GUI Loaded Successfully!")
WindUI:Notify({
    Title = "XZNE ScriptHub Loaded",
    Content = "Welcome, " .. game.Players.LocalPlayer.Name,
    Icon = "check-circle-2",
    Duration = 5
})


-- [7] EXPLICIT VISUAL SYNC (The "Double-Tap")
-- Force UI to match Config after creation
-- [7] EXPLICIT VISUAL SYNC (The "Double-Tap")
-- Force UI to match Config after creation
task.defer(function()
    _G.XZNE_Restoring = true -- LOCK (Just in case)
    
    -- Wait for UI to render AND Database to be ready (for Dropdowns)
    task.wait(1.5) 
    
    local Timeout = 0
    while not DatabaseReady and Timeout < 5 do
        task.wait(0.5)
        Timeout = Timeout + 0.5
    end
    
    print("🔄 [XZNE DEBUG] Starting Visual Sync...")
    
    local C = Controller.Config
    
    -- Helper for safe updates
    local function Sync(element, value, elementType)
        if element and value ~= nil then 
            pcall(function()
                print("   > Syncing " .. tostring(elementType) .. ": " .. tostring(value))
                
                if elementType == "Dropdown" and element.Select then
                    -- Dropdowns must use Select
                    element:Select(value)
                    
                elseif elementType == "Input" then
                     -- DEBUG: Inspect available methods if first time
                     if element == UIElements.MaxPrice then
                         print("   > [DEBUG] Input Methods: ")
                         for key,val in pairs(getmetatable(element) or element) do
                              if type(val) == "function" then print("     - " .. tostring(key)) end
                         end
                     end

                     -- Input Strategy: Try SetText -> SetValue -> Set
                    local sVal = tostring(value)
                    local success = false
                    
                    if element.SetText then element:SetText(sVal); success = true; print("     -> Used SetText")
                    elseif element.SetValue then element:SetValue(sVal); success = true; print("     -> Used SetValue")
                    elseif element.Set then element:Set(sVal); success = true; print("     -> Used Set")
                    end
                    
                    if not success then warn("❌ [XZNE DEBUG] No suitable Set method found for Input!") end
                    
                else -- Toggle, Slider use :Set()
                    if element.Set then element:Set(value) end
                end
            end)
        end
    end

    -- Sync Toggles
    Sync(UIElements.AutoBuy, C.AutoBuy, "Toggle")
    Sync(UIElements.AutoList, C.AutoList, "Toggle")
    Sync(UIElements.AutoClear, C.AutoClear, "Toggle")
    Sync(UIElements.AutoClaim, C.AutoClaim, "Toggle")
    
    -- Sync Sliders & Inputs
    Sync(UIElements.DelaySlider, C.Speed, "Slider")
    Sync(UIElements.MaxPrice, C.MaxPrice, "Input")
    Sync(UIElements.Price, C.Price, "Input")
    
    -- Sync Dropdowns (Now that DB is ready)
    if C.BuyTargetPet and C.BuyTargetPet ~= "— None —" then
         Sync(UIElements.TargetPet, C.BuyTargetPet, "Dropdown")
    end
    
    if C.BuyTargetItem and C.BuyTargetItem ~= "— None —" then
         Sync(UIElements.TargetItem, C.BuyTargetItem, "Dropdown")
    end
    
    print("✅ [XZNE DEBUG] Visual Sync Complete")
    
    task.wait(0.5)
    _G.XZNE_Restoring = false -- UNLOCK
    print("🔓 [XZNE DEBUG] Save Lock Released (Ready to Save)")
end)

-- Return success to Loader
print("✅ [XZNE DEBUG] Reached End of Script, returning true")
return true
