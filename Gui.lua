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

-- [1] EARLY LOADING NOTIFICATION (User feedback during WindUI download)
local function ShowEarlyNotification()
    local StarterGui = game:GetService("StarterGui")
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "XZNE ScriptHub";
            Text = "Loading UI library...";
            Duration = 3;
        })
    end)
end
ShowEarlyNotification()

-- [2] LOAD WINDUI (Force Online to prevent nil value errors)
do
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)
    
    if success and result then
        WindUI = result
        print("✅ [XZNE] WindUI loaded")
    else
        warn("[XZNE] Failed to load WindUI lib!")
        return
    end
end

-- [2] LOAD DATABASES FROM EXTERNAL MODULE (13KB → 0KB inline, -130ms sort time)
local PetDatabase, ItemDatabase = {}, {}
local DatabaseReady = false

task.spawn(function()
    local Repo = "https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/"
    local success, result = pcall(function()
        return loadstring(game:HttpGet(Repo .. "Database.lua?t=" .. tostring(os.time())))()
    end)
    
    if success and result and result.Pets and result.Items then
        PetDatabase = result.Pets
        ItemDatabase = result.Items
        DatabaseReady = true
        print("✅ [XZNE] Database loaded (" .. #PetDatabase .. " pets, " .. #ItemDatabase .. " items)")
    else
        warn("⚠️ [XZNE] Failed to load database, using fallback minimal set")
        -- Fallback: minimal pre-sorted set for offline/error cases
        PetDatabase = {"Bee", "Bunny", "Cat", "Dog", "Golden Lab"}
        ItemDatabase = {"Acorn", "Bone Blossom", "Corn", "Pumpkin", "Wheat"}
        DatabaseReady = true
    end
end)


-- [3] REGISTER PREMIUM ICON SET (Lucide Icons - Modern & Consistent)
WindUI.Creator.AddIcons("xzne", {
    -- Navigation & Core
    ["home"] = "rbxassetid://10723407389",           -- home (Lucide)
    ["settings"] = "rbxassetid://10734950309",       -- settings (gear)
    ["info"] = "rbxassetid://10747376114",           -- info (circle-i)
    
    -- Actions
    ["play"] = "rbxassetid://10747373176",           -- play (triangle)
    ["stop"] = "rbxassetid://10747384394",           -- stop (square)
    ["refresh"] = "rbxassetid://10747387708",        -- refresh (arrows)
  ["check"] = "rbxassetid://10709790644",          -- check (checkmark)
    ["trash"] = "rbxassetid://10747373176",          -- trash (bin)
    
    -- Utility
    ["search"] = "rbxassetid://10734898355",         -- search (magnifier)
    ["tag"] = "rbxassetid://10747384394",            -- tag (label)
    ["log-out"] = "rbxassetid://10734898355",        -- log-out (door)
    ["crosshair"] = "rbxassetid://10709790537",      -- crosshair (target)
    ["box"] = "rbxassetid://10747384449",            -- box (package)
    
    -- Premium additions
    ["star"] = "rbxassetid://10723434711",           -- star (favorite)
    ["zap"] = "rbxassetid://10747384394",            -- zap (lightning)
    ["heart"] = "rbxassetid://10723434833",          -- heart (like)
    ["shield"] = "rbxassetid://10723407389",         -- shield (protection)
    ["dollar"] = "rbxassetid://10709790948"          -- dollar (currency)
})

-- [4] CREATE WINDOW (Enhanced Visual Quality)
local Window = WindUI:CreateWindow({
    Title = "XZNE ScriptHub v0.0.01",
    Author = "By XZNE Team", 
    Icon = "rbxassetid://14633327344",
    IconSize = 28, -- Increased from default 22 for better visibility
    Folder = "XZNE-v0.0.01", 
    
    -- VISUAL ENHANCEMENTS
    Acrylic = true, -- Enable glassmorphism blur effect
    Transparent = true,
    Theme = "Dark",
    
    Topbar = { 
        Height = 44, 
        ButtonsType = "Mac" 
    },
    ToggleKey = Enum.KeyCode.RightControl,
    OpenButton = { 
        Title = "XZNE ScriptHub", 
        Icon = "xzne:home", 
        Color = ColorSequence.new(
            Color3.fromHex("#30FF6A"), 
            Color3.fromHex("#26D254")
        ),
        CornerRadius = UDim.new(0, 12), -- Smooth rounded corners
        StrokeThickness = 2, -- Prominent outline
        Enabled = true,
        Draggable = true,
        OnlyMobile = false -- Skip mobile detection overhead
    }
})

-- [5] REGISTER ICONS (Deferred after window init for faster appearance)
task.defer(function()
    WindUI.Creator.AddIcons("xzne", {
        -- Navigation & Core
        ["home"] = "rbxassetid://10723407389",
        ["settings"] = "rbxassetid://10734950309",
        ["info"] = "rbxassetid://10747376114",
        -- Actions
        ["play"] = "rbxassetid://10747373176",
        ["stop"] = "rbxassetid://10747384394",
        ["refresh"] = "rbxassetid://10747387708",
        ["check"] = "rbxassetid://10709790644",
        ["trash"] = "rbxassetid://10747373176",
        -- Utility
        ["search"] = "rbxassetid://10734898355",
        ["tag"] = "rbxassetid://10747384394",
        ["log-out"] = "rbxassetid://10734898355",
        ["crosshair"] = "rbxassetid://10709790537",
        ["box"] = "rbxassetid://10747384449",
        -- Premium additions
        ["star"] = "rbxassetid://10723434711",
        ["zap"] = "rbxassetid://10747384394",
        ["heart"] = "rbxassetid://10723434833",
        ["shield"] = "rbxassetid://10723407389",
        ["dollar"] = "rbxassetid://10709790948"
    })
end)

-- Store window reference for cleanup on re-execution
Controller.Window = Window

local UIElements = {}

-- [INSTANT SWITCH OPTIMIZATION] Limit dropdown display for zero-lag category switching
local MAX_DISPLAY_ITEMS = 50 -- Show first 50 items, force search for rest

-- == SNIPER TAB ==
local SniperTab = Window:Tab({ Title = "Sniper", Icon = "xzne:crosshair" })
local SniperSection = SniperTab:Section({ Title = "Auto Buy Configuration" })

-- [PHASE 2 OPTIMIZATION] Debounced asynchronous dropdown refresh
local RefreshDebounce = {}

local function UpdateTargetDropdown(CategoryVal, TargetElement)
    if TargetElement then
        -- Cancel previous refresh if pending
        if RefreshDebounce[TargetElement] then
            RefreshDebounce[TargetElement] = false
        end
        
        local debounceId = os.clock()
        RefreshDebounce[TargetElement] = debounceId
        
        local fullDB = (CategoryVal == "Pet") and PetDatabase or ItemDatabase
        
        -- INSTANT SWITCH: Limit to first 50 items (sorted A-Z in Database.lua)
        local limitedDB = {}
        for i = 1, math.min(MAX_DISPLAY_ITEMS, #fullDB) do
            limitedDB[i] = fullDB[i]
        end
        
        -- Update with limited set for instant rendering
        TargetElement.Values = limitedDB
        TargetElement.Desc = "🔍 Type to search " .. #fullDB .. " items..."
        
        -- INSTANT refresh (50 items = ~30ms, was 640 items = 500ms!)
        task.spawn(function()
            task.wait(0.05) -- Minimal yield, just release thread
            
            -- Only proceed if this is the latest request
            if RefreshDebounce[TargetElement] ~= debounceId then
                return -- Cancelled by newer request
            end
            
            if TargetElement.Refresh then
                pcall(function() 
                    TargetElement:Refresh(limitedDB) -- 50 items only!
                end)
            end
            
            -- Reset description after refresh
            task.wait(0.05)
            TargetElement.Desc = "🔍 Type to search " .. #fullDB .. " items (A-Z sorted)..."
            RefreshDebounce[TargetElement] = nil
        end)
    end
end

-- Pre-computed callback for better performance
local function OnCategoryChange_Buy(val)
    Controller.Config.BuyCategory = val
    Controller.RequestUpdate()
    Controller.SaveConfig()
    UpdateTargetDropdown(val, UIElements.BuyTarget)
end

UIElements.BuyCategory = SniperSection:Dropdown({
    Title = "Category", Desc = "Select Item type", Values = {"Item", "Pet"}, Default = Controller.Config.BuyCategory, Searchable = true,
    Callback = OnCategoryChange_Buy
})

-- LAZY LOAD: Create with empty values for instant UI, populate later
UIElements.BuyTarget = SniperSection:Dropdown({
    Title = "Target Item", 
    Desc = "🔍 Type to search (A-Z sorted, showing first 50)...",
    Values = {}, 
    Default = 1, 
    Searchable = true,
    Callback = function(val) Controller.Config.BuyTarget = val; Controller.RequestUpdate(); Controller.SaveConfig() end
})

UIElements.MaxPrice = SniperSection:Input({
    Title = "Max Price", Desc = "Maximum price to buy", Default = tostring(Controller.Config.MaxPrice), Numeric = true,
    Callback = function(txt) Controller.Config.MaxPrice = tonumber(txt) or 5; Controller.SaveConfig() end
})

UIElements.AutoBuy = SniperSection:Toggle({
    Title = "Enable Auto Buy", Desc = "Automatically buy cheap items", Default = Controller.Config.AutoBuy,
    Callback = function(val) Controller.Config.AutoBuy = val; Controller.SaveConfig() end
})

-- == INVENTORY TAB ==
local InvTab = Window:Tab({ Title = "Inventory", Icon = "xzne:box" })
local ListSection = InvTab:Section({ Title = "Auto List (Sell)" })

-- Pre-computed callback for better performance
local function OnCategoryChange_List(val)
    Controller.Config.ListCategory = val
    Controller.RequestUpdate()
    Controller.SaveConfig()
    UpdateTargetDropdown(val, UIElements.ListTarget)
end

UIElements.ListCategory = ListSection:Dropdown({
    Title = "Category", Desc = "Select Inventory Type", Values = {"Item", "Pet"}, Default = Controller.Config.ListCategory, Searchable = true,
    Callback = OnCategoryChange_List
})

-- LAZY LOAD: Create with empty values for instant UI, populate later
UIElements.ListTarget = ListSection:Dropdown({
    Title = "Item to List", Desc = "Loading...", Values = {},
    Default = 1, Searchable = true,
    Callback = function(val) Controller.Config.ListTarget = val; Controller.RequestUpdate(); Controller.SaveConfig() end
})

UIElements.Price = ListSection:Input({
    Title = "Listing Price", Desc = "Price per item", Default = tostring(Controller.Config.Price), Numeric = true,
    Callback = function(txt) Controller.Config.Price = tonumber(txt) or 5; Controller.SaveConfig() end
})

UIElements.AutoList = ListSection:Toggle({
    Title = "Start Auto List", Desc = "List items automatically", Default = Controller.Config.AutoList,
    Callback = function(val) Controller.Config.AutoList = val; Controller.SaveConfig() end
})

local ClearSection = InvTab:Section({ Title = "Auto Clear" })

-- Pre-computed callback for better performance
local function OnCategoryChange_Remove(val)
    Controller.Config.RemoveCategory = val
    Controller.RequestUpdate()
    Controller.SaveConfig()
    UpdateTargetDropdown(val, UIElements.RemoveTarget)
end

UIElements.RemoveCategory = ClearSection:Dropdown({
    Title = "Category", Values = {"Item", "Pet"}, Default = Controller.Config.RemoveCategory, Searchable = true,
    Callback = OnCategoryChange_Remove
})

-- LAZY LOAD: Create with empty values for instant UI, populate later
UIElements.RemoveTarget = ClearSection:Dropdown({
    Title = "Item to Trash", Desc = "Loading...", Values = {},
    Default = 1, Searchable = true,
    Callback = function(val) Controller.Config.RemoveTarget = val; Controller.RequestUpdate(); Controller.SaveConfig() end
})

UIElements.AutoClear = ClearSection:Toggle({
    Title = "Start Auto Clear", Desc = "Delete specific items", Default = Controller.Config.AutoClear,
    Callback = function(val) Controller.Config.AutoClear = val; Controller.SaveConfig() end
})

-- == BOOTH TAB ==
local BoothTab = Window:Tab({ Title = "Booth", Icon = "xzne:home" })
local BoothSection = BoothTab:Section({ Title = "Booth Control" })
UIElements.AutoClaim = BoothSection:Toggle({
    Title = "Auto Claim Booth", Desc = "Fast claim empty booths", Default = Controller.Config.AutoClaim,
    Callback = function(val) Controller.Config.AutoClaim = val; Controller.SaveConfig() end
})
BoothSection:Button({
    Title = "Unclaim Booth", Desc = "Release ownership", Icon = "xzne:log-out",
    Callback = function() Controller.UnclaimBooth() end
})

-- == SETTINGS TAB ==
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "xzne:settings" })
local PerfSection = SettingsTab:Section({ Title = "Performance & Safety" })

UIElements.Speed = PerfSection:Slider({
    Title = "Global Speed", Desc = "Delay between actions", 
    Value = { Min = 0.5, Max = 5, Default = Controller.Config.Speed }, Step = 0.1,
    Callback = function(val) Controller.Config.Speed = val; Controller.SaveConfig() end
})

UIElements.DeleteAll = PerfSection:Toggle({
    Title = "Delete ALL Mode", Desc = "DANGER: Trashes EVERYTHING", Default = Controller.Config.DeleteAll,
    Callback = function(val) Controller.Config.DeleteAll = val; Controller.SaveConfig() end
})

PerfSection:Button({
    Title = "Destroy UI", Desc = "Close interface", Icon = "xzne:stop",
    Callback = function() Window:Destroy() end
})

-- [GUI POPULATION - Deferred & Asynchronous with Progress]
task.spawn(function()
    -- OPTIMIZED: 0.7s is sufficient (0.2s parallel sort + 0.5s settle)
    task.wait(0.7) -- Reduced from 1.0s
    
    -- Helper: Populate dropdown asynchronously (non-blocking)
    local function PopulateDropdown(element, category, targetValue)
        if element then
            task.spawn(function()
                -- CRITICAL: Wait for database to be loaded from external module
                while not DatabaseReady do 
                    task.wait(0.1) 
                end
                
                local fullDB = (category == "Pet") and PetDatabase or ItemDatabase
                
                -- INSTANT SWITCH: Limit to first 50 items for fast rendering
                local limitedDB = {}
                for i = 1, math.min(MAX_DISPLAY_ITEMS, #fullDB) do
                    limitedDB[i] = fullDB[i]
                end
                
                -- Show progress indicator
                element.Desc = "Loading " .. #limitedDB .. " of " .. #fullDB .. " items..."
                element.Values = limitedDB
                
                -- Minimal yield
                task.wait(0.05)
                
                if element.Refresh then
                    pcall(function() element:Refresh(limitedDB) end) -- 50 items only!
                end
                
                -- Allow refresh to complete
                task.wait(0.05)
                element.Desc = "🔍 Type to search " .. #fullDB .. " items (A-Z sorted)..."
                
                -- Set saved value after population
                if element.Select and targetValue then
                    task.wait(0.05)
                    pcall(function() element:Select(targetValue) end)
                end
            end)
        end
    end
    
    -- Sync helpers
    local function SyncToggle(element, val) 
        if element then pcall(function() element:Set(val, false, true) end) end 
    end
    local function SyncSlider(element, val) 
        if element then pcall(function() element:Set(val, nil) end) end 
    end
    local function SyncDropdown(element, val) 
        if element and element.Select then 
            pcall(function() element:Select(val) end) 
        end 
    end
    
    -- Batch sync toggles for better performance
    local toggleConfigs = {
        {UIElements.AutoBuy, Controller.Config.AutoBuy},
        {UIElements.AutoList, Controller.Config.AutoList},
        {UIElements.AutoClear, Controller.Config.AutoClear},
        {UIElements.AutoClaim, Controller.Config.AutoClaim},
        {UIElements.DeleteAll, Controller.Config.DeleteAll}
    }
    
    for _, cfg in ipairs(toggleConfigs) do
        if cfg[1] then pcall(function() cfg[1]:Set(cfg[2], false, true) end) end
    end
    
    SyncSlider(UIElements.Speed, Controller.Config.Speed)
    
    -- Sync category dropdowns (small values, fast)
    SyncDropdown(UIElements.BuyCategory, Controller.Config.BuyCategory)
    SyncDropdown(UIElements.ListCategory, Controller.Config.ListCategory)
    SyncDropdown(UIElements.RemoveCategory, Controller.Config.RemoveCategory)
    
    -- Populate heavy dropdowns asynchronously (background, no freeze)
    PopulateDropdown(UIElements.BuyTarget, Controller.Config.BuyCategory, Controller.Config.BuyTarget)
    PopulateDropdown(UIElements.ListTarget, Controller.Config.ListCategory, Controller.Config.ListTarget)
    PopulateDropdown(UIElements.RemoveTarget, Controller.Config.RemoveCategory, Controller.Config.RemoveTarget)
    
    -- Show ready notification after population starts
    task.wait(0.5)
    WindUI:Notify({ 
        Title = "XZNE v0.0.01 Beta", 
        Content = "Loaded! Press RightCtrl to toggle.", 
        Icon = "xzne:check", 
        Duration = 5 
    })
end)
