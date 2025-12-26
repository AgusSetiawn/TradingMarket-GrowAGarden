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

-- == SNIPER TAB ==
local SniperTab = Window:Tab({ Title = "Sniper", Icon = "xzne:crosshair" })
local SniperSection = SniperTab:Section({ Title = "Auto Buy Configuration" })

-- ZERO-LAG: Separate dropdowns for Pet and Item (no category switching!)
SniperSection:Paragraph({
    Title = "💡 How It Works",
    Desc = "Monitor trading market for cheap items. Automatically purchase when price below maximum."
})

UIElements.BuyTargetPet = SniperSection:Dropdown({
    Title = "🐾 Target Pet to Buy", 
    Desc = "Search from 277 pets (A-Z sorted) - Type to filter",
    Values = {}, 
    Default = 1, 
    Searchable = true,
    Callback = function(val) 
        Controller.Config.BuyTarget = val
        Controller.Config.BuyCategory = "Pet"
        Controller.RequestUpdate()
        Controller.SaveConfig()
    end
})

UIElements.BuyTargetItem = SniperSection:Dropdown({
    Title = "🌿 Target Item to Buy", 
    Desc = "Search from 363 items (A-Z sorted) - Type to filter",
    Values = {}, 
    Default = 1, 
    Searchable = true,
    Callback = function(val) 
        Controller.Config.BuyTarget = val
        Controller.Config.BuyCategory = "Item"
        Controller.RequestUpdate()
        Controller.SaveConfig()
    end
})

SniperSection:Divider()

UIElements.MaxPrice = SniperSection:Input({
    Title = "💰 Maximum Price (Robux)",
    Desc = "Only buy items priced at or below this amount",
    Default = tostring(Controller.Config.MaxPrice),
    Numeric = true,
    Callback = function(txt) Controller.Config.MaxPrice = tonumber(txt) or 5; Controller.SaveConfig() end
})

UIElements.BuySpeed = SniperSection:Slider({
    Title = "⏱️ Buy Speed", Desc = "Delay between buy attempts (0-10 seconds)",
    Value = { Min = 0, Max = 10, Default = Controller.Config.BuySpeed or 1.0 }, Step = 0.1,
    Callback = function(val) Controller.Config.BuySpeed = val; Controller.SaveConfig() end
})

UIElements.AutoBuy = SniperSection:Toggle({
    Title = "🚀 Enable Auto Buy",
    Desc = "Start automatic purchasing when enabled",
    Default = Controller.Config.AutoBuy,
    Callback = function(val) Controller.Config.AutoBuy = val; Controller.SaveConfig() end
})

-- == INVENTORY TAB ==
local InvTab = Window:Tab({ Title = "Inventory", Icon = "xzne:box" })
local ListSection = InvTab:Section({ Title = "Auto List (Sell Items)" })

ListSection:Paragraph({
    Title = "💡 How It Works",
    Desc = "Automatically list your inventory items on trading market at specified price."
})

-- ZERO-LAG: Separate dropdowns for Pet and Item
UIElements.ListTargetPet = ListSection:Dropdown({
    Title = "🐾 Pet to List",
    Desc = "Search from 277 pets (A-Z sorted) - Type to filter",
    Values = {},
    Default = 1,
    Searchable = true,
    Callback = function(val) 
        Controller.Config.ListTarget = val
        Controller.Config.ListCategory = "Pet"
        Controller.RequestUpdate()
        Controller.SaveConfig()
    end
})

UIElements.ListTargetItem = ListSection:Dropdown({
    Title = "🌿 Item to List",
    Desc = "Search from 363 items (A-Z sorted) - Type to filter",
    Values = {},
    Default = 1,
    Searchable = true,
    Callback = function(val) 
        Controller.Config.ListTarget = val
        Controller.Config.ListCategory = "Item"
        Controller.RequestUpdate()
        Controller.SaveConfig()
    end
})

ListSection:Divider()

UIElements.Price = ListSection:Input({
    Title = "💰 Listing Price (Robux)",
    Desc = "Price per item for market listing",
    Default = tostring(Controller.Config.Price),
    Numeric = true,
    Callback = function(txt) Controller.Config.Price = tonumber(txt) or 5; Controller.SaveConfig() end
})

UIElements.ListSpeed = ListSection:Slider({
    Title = "⏱️ List Speed", Desc = "Delay between listing actions (0-10 seconds)",
    Value = { Min = 0, Max = 10, Default = Controller.Config.ListSpeed or 1.0 }, Step = 0.1,
    Callback = function(val) Controller.Config.ListSpeed = val; Controller.SaveConfig() end
})

UIElements.AutoList = ListSection:Toggle({
    Title = "🚀 Enable Auto List",
    Desc = "Start automatic listing when enabled",
    Default = Controller.Config.AutoList,
    Callback = function(val) Controller.Config.AutoList = val; Controller.SaveConfig() end
})

local ClearSection = InvTab:Section({ Title = "Auto Remove Listing" })

ClearSection:Paragraph({
    Title = "💡 How It Works",
    Desc = "Automatically remove (delist) your items from trading market."
})

-- ZERO-LAG: Separate dropdowns for Pet and Item
UIElements.RemoveTargetPet = ClearSection:Dropdown({
    Title = "🐾 Pet to Remove",
    Desc = "Search from 277 pets (A-Z sorted) - Type to filter",
    Values = {},
    Default = 1,
    Searchable = true,
    Callback = function(val) 
        Controller.Config.RemoveTarget = val
        Controller.Config.RemoveCategory = "Pet"
        Controller.RequestUpdate()
        Controller.SaveConfig()
    end
})

UIElements.RemoveTargetItem = ClearSection:Dropdown({
    Title = "🌿 Item to Remove",
    Desc = "Search from 363 items (A-Z sorted) - Type to filter",
    Values = {},
    Default = 1,
    Searchable = true,
    Callback = function(val) 
        Controller.Config.RemoveTarget = val
        Controller.Config.RemoveCategory = "Item"
        Controller.RequestUpdate()
        Controller.SaveConfig()
    end
})

ClearSection:Divider()

UIElements.AutoClear = ClearSection:Toggle({
    Title = "🚀 Enable Auto Remove",
    Desc = "Start automatic delisting when enabled",
    Default = Controller.Config.AutoClear,
    Callback = function(val) Controller.Config.AutoClear = val; Controller.SaveConfig() end
})

UIElements.RemoveSpeed = ClearSection:Slider({
    Title = "⏱️ Remove Speed", Desc = "Delay between remove actions (0-10 seconds)",
    Value = { Min = 0, Max = 10, Default = Controller.Config.RemoveSpeed or 1.0 }, Step = 0.1,
    Callback = function(val) Controller.Config.RemoveSpeed = val; Controller.SaveConfig() end
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

PerfSection:Button({
    Title = "Close & Stop All", Desc = "Stop all automation and close UI", Icon = "xzne:stop",
    Callback = function() 
        -- Stop all running operations
        Controller.Config.Running = false
        Controller.Config.AutoBuy = false
        Controller.Config.AutoList = false
        Controller.Config.AutoClear = false
        Controller.Config.AutoClaim = false
        
        -- Save config
        Controller.SaveConfig()
        
        -- Clear window reference to allow re-execution
        Controller.Window = nil
        
        -- Destroy UI
        task.wait(0.2)
        Window:Destroy()
        
        print("✅ [XZNE] GUI closed. Run Loader.lua again to reopen.")
    end
})

-- [GUI POPULATION - Pre-render ALL dropdowns at startup for instant category switching]
task.spawn(function()
    -- OPTIMIZED: 0.7s is sufficient (0.2s parallel sort + 0.5s settle)
    task.wait(0.7)
    
    -- Wait for database to be ready
    while not DatabaseReady do 
        task.wait(0.1) 
    end
    
    print("🔄 [XZNE] Pre-rendering all dropdowns...")
    
    -- Pre-render all Pet dropdowns
    UIElements.BuyTargetPet.Values = PetDatabase
    UIElements.BuyTargetPet.Desc = "🔍 Search " .. #PetDatabase .. " pets (A-Z sorted)..."
    if UIElements.BuyTargetPet.Refresh then
        pcall(function() UIElements.BuyTargetPet:Refresh(PetDatabase) end)
    end
    
    UIElements.ListTargetPet.Values = PetDatabase
    UIElements.ListTargetPet.Desc = "🔍 Search " .. #PetDatabase .. " pets (A-Z sorted)..."
    if UIElements.ListTargetPet.Refresh then
        pcall(function() UIElements.ListTargetPet:Refresh(PetDatabase) end)
    end
    
    UIElements.RemoveTargetPet.Values = PetDatabase
    UIElements.RemoveTargetPet.Desc = "🔍 Search " .. #PetDatabase .. " pets (A-Z sorted)..."
    if UIElements.RemoveTargetPet.Refresh then
        pcall(function() UIElements.RemoveTargetPet:Refresh(PetDatabase) end)
    end
    
    -- Pre-render all Item dropdowns
    UIElements.BuyTargetItem.Values = ItemDatabase
    UIElements.BuyTargetItem.Desc = "🔍 Search " .. #ItemDatabase .. " items (A-Z sorted)..."
    if UIElements.BuyTargetItem.Refresh then
        pcall(function() UIElements.BuyTargetItem:Refresh(ItemDatabase) end)
    end
    
    UIElements.ListTargetItem.Values = ItemDatabase
    UIElements.ListTargetItem.Desc = "🔍 Search " .. #ItemDatabase .. " items (A-Z sorted)..."
    if UIElements.ListTargetItem.Refresh then
        pcall(function() UIElements.ListTargetItem:Refresh(ItemDatabase) end)
    end
    
    UIElements.RemoveTargetItem.Values = ItemDatabase
    UIElements.RemoveTargetItem.Desc = "🔍 Search " .. #ItemDatabase .. " items (A-Z sorted)..."
    if UIElements.RemoveTargetItem.Refresh then
        pcall(function() UIElements.RemoveTargetItem:Refresh(ItemDatabase) end)
    end
    
    -- Set saved values if exist
    if Controller.Config.BuyTarget then
        local buyDropdown = (Controller.Config.BuyCategory == "Pet") and UIElements.BuyTargetPet or UIElements.BuyTargetItem
        if buyDropdown.Select then
            task.wait(0.1)
            pcall(function() buyDropdown:Select(Controller.Config.BuyTarget) end)
        end
    end
    
    if Controller.Config.ListTarget then
        local listDropdown = (Controller.Config.ListCategory == "Pet") and UIElements.ListTargetPet or UIElements.ListTargetItem
        if listDropdown.Select then
            task.wait(0.1)
            pcall(function() listDropdown:Select(Controller.Config.ListTarget) end)
        end
    end
    
    if Controller.Config.RemoveTarget then
        local removeDropdown = (Controller.Config.RemoveCategory == "Pet") and UIElements.RemoveTargetPet or UIElements.RemoveTargetItem
        if removeDropdown.Select then
            task.wait(0.1)
            pcall(function() removeDropdown:Select(Controller.Config.RemoveTarget) end)
        end
    end
    
    print("✅ [XZNE] All dropdowns pre-rendered!")
    
    -- Sync simple elements (instant, no dropdown render)
    
    -- Batch sync toggles for better performance (removed DeleteAll)
    local toggleConfigs = {
        {UIElements.AutoBuy, Controller.Config.AutoBuy},
        {UIElements.AutoList, Controller.Config.AutoList},
        {UIElements.AutoClear, Controller.Config.AutoClear},
        {UIElements.AutoClaim, Controller.Config.AutoClaim}
    }
    
    for _, cfg in ipairs(toggleConfigs) do
        if cfg[1] then pcall(function() cfg[1]:Set(cfg[2], false, true) end) end
    end
    
    -- Sync individual speed sliders
    if UIElements.BuySpeed and UIElements.BuySpeed.Set then
        pcall(function() UIElements.BuySpeed:Set(Controller.Config.BuySpeed or 1.0) end)
    end
    if UIElements.ListSpeed and UIElements.ListSpeed.Set then
        pcall(function() UIElements.ListSpeed:Set(Controller.Config.ListSpeed or 1.0) end)
    end
    if UIElements.RemoveSpeed and UIElements.RemoveSpeed.Set then
        pcall(function() UIElements.RemoveSpeed:Set(Controller.Config.RemoveSpeed or 1.0) end)
    end
    
    -- Show ready notification after population starts
    task.wait(0.5)
    WindUI:Notify({ 
        Title = "XZNE v0.0.01 Beta", 
        Content = "Loaded! Press RightCtrl to toggle.", 
        Icon = "xzne:check", 
        Duration = 5 
    })
end)
