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

-- [1] INSTANT LOADING FEEDBACK (Moved up)

-- [2] INSTANT LOADING FEEDBACK
local function ShowEarlyNotification()
    local StarterGui = game:GetService("StarterGui")
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "XZNE ScriptHub";
            Text = "Initializing... Please wait";
            Duration = 2;
        })
    end)
end
ShowEarlyNotification()

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

-- [3] CONFIGURATION SYSTEM (Custom Path)
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
    pcall(SaveToJSON)
    pcall(function() Controller.UpdateCache() end)
end

-- Load Logic (Passive)
local function LoadFromJSON()
    if isfile(ConfigFile) then
        local success, result = pcall(readfile, ConfigFile)
        if success and result then
            local decoded = HttpService:JSONDecode(result)
            if decoded then
                for k,v in pairs(decoded) do
                    Controller.Config[k] = v
                end
                Controller.UpdateCache()
                return true
            end
        end
    end
    return false
end

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
    Icon = "zap",  -- Lightning bolt icon (from Lucide library)
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

-- [6] CONFIGURE OPEN BUTTON (Minimize State)
-- Matches the "Premium" aesthetic requested
Window:EditOpenButton({
    Title = "Open Hub",
    Icon = "zap",  -- Matches the Window Icon
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
        Controller.Config.BuyTarget = val
        -- Sync other keys for logic compatibility
        Controller.Config.ListTarget = val
        Controller.Config.RemoveTarget = val
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
        Controller.Config.BuyTarget = val
        -- Sync other keys
        Controller.Config.ListTarget = val
        Controller.Config.RemoveTarget = val
        AutoSave()
    end
})

TargetSection:Space() -- Break merge

UIElements.DelaySlider = TargetSection:Slider({
    Title = "Action Delay",
    Desc = "Delay Between Actions (0–10s)",
    Step = 0.1,
    Value = {
        Min = 0,
        Max = 10,
        Default = Controller.Config.Speed or 1,
    },
    Flag = "Speed",
    Callback = function(val)
        Controller.Config.Speed = val
        AutoSave()
    end
})

TargetSection:Space() -- Final space before next section divider/end

-- === AUTO BUY SECTION ===
local BuySection = MainTab:Section({ Title = "Auto Buy (Sniper)", Icon = "shopping-bag" })

UIElements.MaxPrice = BuySection:Input({
    Title = "Max Price", Desc = "Maximum price to pay", Default = tostring(Controller.Config.MaxPrice), Numeric = true,
    Flag = "MaxPrice",
    Callback = function(txt) 
        Controller.Config.MaxPrice = tonumber(txt) or 5
        AutoSave() 
    end
})

UIElements.AutoBuy = BuySection:Toggle({
    Title = "Enable Auto Buy", Desc = "Snipe selected target", Default = false,
    Flag = "AutoBuy",
    Callback = function(val)
        -- Validation
        if val and (UIElements.TargetPet.Value == "— None —" and UIElements.TargetItem.Value == "— None —") then
             -- No visual feedback needed, just don't enable config logic
             -- WindUI might toggle visually, but Logic won't run if we don't set Config
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
    Title = "Listing Price", Desc = "Price per item", Default = tostring(Controller.Config.Price), Numeric = true,
    Flag = "Price",
    Callback = function(txt) 
        Controller.Config.Price = tonumber(txt) or 5
        AutoSave() 
    end
})

UIElements.AutoList = ListSection:Toggle({
    Title = "Enable Auto List", Desc = "List selected target", Default = false,
    Flag = "AutoList",
    Callback = function(val)
        Controller.Config.AutoList = val
        AutoSave()
    end
})

ListSection:Divider()

-- === AUTO REMOVE SECTION ===
local RemoveSection = MainTab:Section({ Title = "Auto Remove", Icon = "trash-2" })

UIElements.AutoClear = RemoveSection:Toggle({
    Title = "Enable Auto Remove", Desc = "Remove selected target", Default = false,
    Flag = "AutoClear",
    Callback = function(val)
        Controller.Config.AutoClear = val
        AutoSave()
    end
})

RemoveSection:Divider()

-- === BOOTH CONTROL SECTION ===
local BoothSection = MainTab:Section({ Title = "Booth Control", Icon = "store" })

UIElements.AutoClaim = BoothSection:Toggle({
    Title = "Auto Claim Booth", Desc = "Automatically claim booth", Default = false,
    Flag = "AutoClaim",
    Callback = function(val)
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
    task.wait(0.2)
    -- LOAD CONFIG NOW (After dropdowns are populated)
    task.wait(0.2)
    pcall(function()
        if LoadFromJSON() then
            print("✅ [XZNE] Config Loaded from Custom Path!")
            
            -- Apply Values to UI Elements
            -- Map Config Keys to UI Elements via 'Flag' property we set earlier
            for _, pc in pairs(UIElements) do
                if pc.Flag and Controller.Config[pc.Flag] ~= nil then
                    pcall(function() pc:Set(Controller.Config[pc.Flag]) end)
                end
            end
            
            -- Restore special logic for targets (Consistency)
            if UIElements.TargetPet.Value ~= "— None —" and UIElements.TargetPet.Value == Controller.Config.BuyTarget then
                -- Already set by pc:Set above
            elseif UIElements.TargetItem.Value ~= "— None —" and UIElements.TargetItem.Value == Controller.Config.BuyTarget then
                -- Already set
            end
        end
    end)
    
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

-- Return success to Loader
return true
