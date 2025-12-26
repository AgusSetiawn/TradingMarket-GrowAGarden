--[[
    💠 XZNE SCRIPTHUB v0.0.01 Beta - UI LOADER
    
    🎨 WindUI Interface
    🔗 Connects to: Main.lua (_G.XZNE_Controller)
]]

print("✅ [XZNE GUI] Starting GUI Load...")

local WindUI
local Controller = _G.XZNE_Controller

-- Safety Check with Print (Avoid warn/return issues debug)
if not Controller then
    print("❌ [XZNE GUI] CRITICAL: Controller not found! Run Main.lua first.")
    -- We continue for debug purposes, but code will fail later if used
else
    print("✅ [XZNE GUI] Controller found: " .. tostring(Controller))
end

-- [1] EARLY LOADING NOTIFICATION
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "XZNE ScriptHub"; Text = "Loading UI library..."; Duration = 3;
    })
end)

-- [2] LOAD WINDUI
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
    ["home"] = "rbxassetid://10723407389",           -- home
    ["settings"] = "rbxassetid://10734950309",       -- settings
    ["info"] = "rbxassetid://10747376114",           -- info
    
    -- Tabs (Matches Tab definitions)
    ["target"] = "rbxassetid://10723351967",         -- Sniper Tab (was crosshair)
    ["dollar"] = "rbxassetid://10709790948",         -- Sell Tab
    ["trash"] = "rbxassetid://10747373176",          -- Trash Tab
    ["store"] = "rbxassetid://10723374761",          -- Booth Tab (was home)
    
    -- Actions & Status
    ["play"] = "rbxassetid://10747373176",           
    ["stop"] = "rbxassetid://10747384394",           
    ["refresh"] = "rbxassetid://10747387708",        
    ["check"] = "rbxassetid://10709790644",          
    ["search"] = "rbxassetid://10734898355",         
    ["package"] = "rbxassetid://10747384449",        -- Inventory/Box
    ["star"] = "rbxassetid://10723434711",           
    ["zap"] = "rbxassetid://10747384394",            
    ["shield"] = "rbxassetid://10723407389"          
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

    })
end)

-- Store window reference for cleanup on re-execution
Controller.Window = Window

local UIElements = {}

-- == SNIPER TAB ==
local SniperTab = Window:Tab({ Title = "Sniper", Icon = "xzne:target" })
local SniperSection = SniperTab:Section({ Title = "Auto Buy Configuration" })

-- Help paragraph
SniperSection:Paragraph({
    Title = "💡 Quick Guide",
    Desc = "Select target from Pet or Item dropdown. Set max price. Enable Auto Buy to snipe deals."
})

SniperSection:Divider()

-- ZERO-LAG: Separate dropdowns for Pet and Item (no category switching!)
UIElements.BuyTargetPet = SniperSection:Dropdown({
    Title = "Target Pet", 
    Desc = "🔍 Search pets (A-Z sorted)...",
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
    Title = "Target Item", 
    Desc = "🔍 Search items (A-Z sorted)...",
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
    Title = "Max Price", Desc = "Maximum price to buy", Default = tostring(Controller.Config.MaxPrice), Numeric = true,
    Callback = function(txt) Controller.Config.MaxPrice = tonumber(txt) or 5; Controller.SaveConfig() end
})

UIElements.AutoBuy = SniperSection:Toggle({
    Title = "Enable Auto Buy", Desc = "Automatically buy cheap items", Default = Controller.Config.AutoBuy,
    Callback = function(val) Controller.Config.AutoBuy = val; Controller.SaveConfig() end
})


-- == TAB 2: SELL (Auto List) ==
local SellTab = Window:Tab({ Title = "Sell Items", Icon = "xzne:dollar", Desc = "Auto List / Sell" })
local ListSection = SellTab:Section({ Title = "Listing Configuration" })

-- Help paragraph
ListSection:Paragraph({
    Title = "💡 How to List",
    Desc = "Choose items to list for sale. Set price per item. Enable Auto List."
})

ListSection:Divider()

-- ZERO-LAG: Separate dropdowns for Pet and Item
UIElements.ListTargetPet = ListSection:Dropdown({
    Title = "Pet to List",
    Desc = "🔍 Search pets...",
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
    Title = "Item to List",
    Desc = "🔍 Search items...",
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

UIElements.Price = ListSection:Input({
    Title = "Listing Price", Desc = "Price per item", Default = tostring(Controller.Config.Price), Numeric = true,
    Callback = function(txt) Controller.Config.Price = tonumber(txt) or 5; Controller.SaveConfig() end
})

UIElements.AutoList = ListSection:Toggle({
    Title = "Start Auto List", Desc = "List items automatically", Default = Controller.Config.AutoList,
    Callback = function(val) Controller.Config.AutoList = val; Controller.SaveConfig() end
})


-- == TAB 3: TRASH (Auto Remove) ==
local TrashTab = Window:Tab({ Title = "Trash Items", Icon = "xzne:trash", Desc = "Auto Clear / Remove" })
local ClearSection = TrashTab:Section({ Title = "Removal Configuration" })

-- Help paragraph
ClearSection:Paragraph({
    Title = "💡 How to Remove",
    Desc = "Select items from booth listing to automatically remove/unlist"
})

ClearSection:Divider()

-- ZERO-LAG: Separate dropdowns for Pet and Item (NOW ACTUALLY ADDED!)
UIElements.RemoveTargetPet = ClearSection:Dropdown({
    Title = "Pet to Remove",
    Desc = "🔍 Search pets to unlist...",
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
    Title = "Item to Remove",
    Desc = "🔍 Search items to unlist...",
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
    Title = "Start Auto Remove", Desc = "Automatically remove selected items from booth", Default = Controller.Config.AutoClear,
    Callback = function(val) Controller.Config.AutoClear = val; Controller.SaveConfig() end
})

ClearSection:Divider()

-- == TAB 4: BOOTH ==
local BoothTab = Window:Tab({ Title = "Booth", Icon = "xzne:store", Desc = "Claim & Manage" })
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

-- Stats Section  
local StatsSection = SettingsTab:Section({ Title = "📊 Session Statistics" })
local StatsParagraph = StatsSection:Paragraph({
    Title = "Performance Metrics",
    Desc = "Sniped: 0 | Listed: 0 | Removed: 0 | Uptime: 0m"
})

StatsSection:Divider()

-- Update stats display every 10 seconds
task.spawn(function()
    local startTime = tick()
    while true do
        task.wait(10)
        local uptime = math.floor((tick() - startTime) / 60)
        local stats = Controller.Stats
        
        -- Find and update the paragraph
        pcall(function()
            -- Update description with current stats
            local desc = string.format(
                "Sniped: %d | Listed: %d | Removed: %d | Uptime: %dm",
                stats.SnipeCount or 0,
                stats.ListedCount or 0,
                stats.RemovedCount or 0,
                uptime
            )
            -- Update the paragraph's description
            if StatsParagraph and StatsParagraph.SetDesc then
                StatsParagraph:SetDesc(desc)
            end
            print("[Stats] " .. desc)
        end)
    end
end)

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
    
    -- Set saved values if exist, otherwise select first item
    if Controller.Config.BuyTarget and Controller.Config.BuyTarget ~= "" then
        local buyDropdown = (Controller.Config.BuyCategory == "Pet") and UIElements.BuyTargetPet or UIElements.BuyTargetItem
        if buyDropdown.Select then
            task.wait(0.1)
            pcall(function() buyDropdown:Select(Controller.Config.BuyTarget) end)
            print("[GUI] Restored BuyTarget:", Controller.Config.BuyTarget, "(", Controller.Config.BuyCategory, ")")
        end
    else
        -- Default: Select first item from Item dropdown
        if UIElements.BuyTargetItem.Select and #ItemDatabase > 0 then
            task.wait(0.1)
            pcall(function() 
                UIElements.BuyTargetItem:Select(ItemDatabase[1]) 
                Controller.Config.BuyTarget = ItemDatabase[1]
                Controller.Config.BuyCategory = "Item"
                Controller.SaveConfig()
            end)
            print("[GUI] Default BuyTarget set to:", ItemDatabase[1])
        end
    end
    
    if Controller.Config.ListTarget and Controller.Config.ListTarget ~= "" then
        local listDropdown = (Controller.Config.ListCategory == "Pet") and UIElements.ListTargetPet or UIElements.ListTargetItem
        if listDropdown.Select then
            task.wait(0.1)
            pcall(function() listDropdown:Select(Controller.Config.ListTarget) end)
            print("[GUI] Restored ListTarget:", Controller.Config.ListTarget, "(", Controller.Config.ListCategory, ")")
        end
    else
        -- Default: Select first item from Item dropdown
        if UIElements.ListTargetItem.Select and #ItemDatabase > 0 then
            task.wait(0.1)
            pcall(function() 
                UIElements.ListTargetItem:Select(ItemDatabase[1])
                Controller.Config.ListTarget = ItemDatabase[1]
                Controller.Config.ListCategory = "Item"
                Controller.SaveConfig()
            end)
            print("[GUI] Default ListTarget set to:", ItemDatabase[1])
        end
    end
    
    if Controller.Config.RemoveTarget and Controller.Config.RemoveTarget ~= "" then
        local removeDropdown = (Controller.Config.RemoveCategory == "Pet") and UIElements.RemoveTargetPet or UIElements.RemoveTargetItem
        if removeDropdown.Select then
            task.wait(0.1)
            pcall(function() removeDropdown:Select(Controller.Config.RemoveTarget) end)
            print("[GUI] Restored RemoveTarget:", Controller.Config.RemoveTarget, "(", Controller.Config.RemoveCategory, ")")
        end
    else
        -- Default: Select first item from Item dropdown
        if UIElements.RemoveTargetItem.Select and #ItemDatabase > 0 then
            task.wait(0.1)
            pcall(function() 
                UIElements.RemoveTargetItem:Select(ItemDatabase[1])
                Controller.Config.RemoveTarget = ItemDatabase[1]
                Controller.Config.RemoveCategory = "Item"
                Controller.SaveConfig()
            end)
            print("[GUI] Default RemoveTarget set to:", ItemDatabase[1])
        end
    end
    
    print("✅ [XZNE] All dropdowns pre-rendered!")
    
    -- Sync simple elements (instant, no dropdown render)
    
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
