--[[
    💠 XZNE SCRIPTHUB v0.0.01 Beta - UI LOADER
    
    🎨 WindUI Interface
    🔗 Connects to: Main.lua (_G.XZNE_Controller)
]]

print("🔍 [XZNE DEBUG] 1. Gui.lua Start")

local WindUI
local Controller = _G.XZNE_Controller
print("🔍 [XZNE DEBUG] 2. Controller Found:", Controller ~= nil)

if not Controller then
    warn("[XZNE] Controller not found! Please run Main.lua first.")
    return
end

-- [1] INSTANT LOADING FEEDBACK
print("🔍 [XZNE DEBUG] 3. Sending Notification")
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
print("🔍 [XZNE DEBUG] 4. Loading WindUI")
do
    local success, result = pcall(function()
        local url = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
        local content = game:HttpGet(url)
        print("🔍 [XZNE DEBUG] 4a. WindUI Content Size:", #content)
        if #content < 100 then warn("⚠️ WindUI content suspicious!") end
        
        local func, err = loadstring(content)
        if not func then error("WindUI Loadstring Error: " .. tostring(err)) end
        return func()
    end)
    
    if success and result then
        WindUI = result
        print("✅ [XZNE] WindUI loaded")
    else
        warn("[XZNE] Failed to load WindUI lib! Error: " .. tostring(result))
        return
    end
end

-- [3] REGISTER ICONS
print("🔍 [XZNE DEBUG] 5. Registering Icons")
task.defer(function()
    WindUI.Creator.AddIcons("xzne", {
        ["target"] = "rbxassetid://10734884548",      -- Crosshair → Target (Sniper)
        ["shopping-cart"] = "rbxassetid://10747372992", -- Shopping Cart (Buy)
        ["package"] = "rbxassetid://10723434711",    -- Package (Inventory/Sell)
        ["trash-2"] = "rbxassetid://10747838902",    -- Trash (Remove)
        ["store"] = "rbxassetid://10747372167",      -- Store (Booth)
        ["settings"] = "rbxassetid://10734950309",   -- Settings
        ["zap"] = "rbxassetid://10747374308",        -- Lightning
        ["check-circle"] = "rbxassetid://10734896206", -- Success
        ["alert-circle"] = "rbxassetid://10702779645", -- Warning
        ["x-circle"] = "rbxassetid://10747384394",  -- Error
        ["info"] = "rbxassetid://10723407389",       -- Info
        ["chart"] = "rbxassetid://10723346959"       -- Stats
    })
    print("✅ [XZNE] Icons registered")
end)

-- [4] LOAD DATABASES (DEFERRED for faster GUI appearance)
print("🔍 [XZNE DEBUG] 6. Deferring Database Load")
local PetDatabase, ItemDatabase = {}, {}
local DatabaseReady = false

-- ✅ OPTIMIZATION: Defer DB load until after GUI renders
task.defer(function()
    task.wait(0.3)  -- Let GUI render first
    local Repo = "https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/"
    local success, result = pcall(function()
        -- Load as raw lua table return
        return loadstring(game:HttpGet(Repo .. "Database.lua"))() 
    end)
    
    if success and result then
        if result.Pets then PetDatabase = result.Pets end
        if result.Items then ItemDatabase = result.Items end
        DatabaseReady = true
        print("✅ [XZNE] External Database Loaded ("..#PetDatabase.." pets, "..#ItemDatabase.." items)")
    else
        warn("⚠️ [XZNE] Failed to load external database: " .. tostring(result))
        -- Fallback empty
        DatabaseReady = true
    end
end)

-- [5] CREATE WINDOW (Premium Glassmorphism Style)
print("🔍 [XZNE DEBUG] 7. Creating Window")
local Window = WindUI:CreateWindow({
    Title = "XZNE ScriptHub",
    Icon = "xzne:target",
    Author = "By. Xzero One",
    -- Folder = "XZNE_Config",  -- ❌ REMOVED: Caused dual state system (WindUI state vs our JSON)
    Transparency = 0.45,       -- 0.45 = Ideal Glass Effect
    Acrylic = true,           -- Enable Glassmorphism Blur
    Theme = "Dark",           -- Dark Mode for contrast
    NewElements = true,       -- Enable modern UI elements
    
    -- Window Controls on RIGHT (Default/Windows Style)
    -- ButtonsType = "Mac",   <-- DISABLED (Places buttons on Left)
    
    Topbar = {
        Height = 44,
        ButtonsType = "Default" -- Force Windows Style (Right side)
    }
})

print("🔍 [XZNE DEBUG] 8. Window Created")

local UIElements = {}

-- == SNIPER TAB ==
print("🔍 [XZNE DEBUG] 9. Creating Sniper Tab")
local SniperTab = Window:Tab({ Title = "Sniper", Icon = "xzne:target" })
local SniperSection = SniperTab:Section({ Title = "Auto Buy Configuration" })

SniperSection:Paragraph({
    Title = "💡 Quick Guide",
    Desc = "Select target. Set max price. Enable Auto Buy."
})
SniperSection:Divider()

-- Dropdowns
print("🔍 [XZNE DEBUG] 10. Creating Dropdowns")
UIElements.BuyTargetPet = SniperSection:Dropdown({
    Title = "Target Pet", 
    Desc = "🔍 Search pets...",
    Values = {}, Default = 1, Search = true,
    Callback = function(val) Controller.Config.BuyTarget = val; Controller.Config.BuyCategory = "Pet"; Controller.RequestUpdate(); Controller.SaveConfig() end
})

UIElements.BuyTargetItem = SniperSection:Dropdown({
    Title = "Target Item", 
    Desc = "🔍 Search items...",
    Values = {}, Default = 1, Search = true,
    Callback = function(val) Controller.Config.BuyTarget = val; Controller.Config.BuyCategory = "Item"; Controller.RequestUpdate(); Controller.SaveConfig() end
})

SniperSection:Divider()

UIElements.MaxPrice = SniperSection:Input({
    Title = "Max Price", Desc = "Max price", Default = tostring(Controller.Config.MaxPrice), Numeric = true,
    Callback = function(txt) Controller.Config.MaxPrice = tonumber(txt) or 5; Controller.SaveConfig() end
})

UIElements.AutoBuy = SniperSection:Toggle({
    Title = "Enable Auto Buy", Desc = "Snipe cheap items", Default = Controller.Config.AutoBuy,
    Callback = function(val) Controller.Config.AutoBuy = val; Controller.SaveConfig() end
})

-- == INVENTORY TAB == (List)
print("🔍 [XZNE DEBUG] 11. Creating Inventory Tab")
local InvTab = Window:Tab({ Title = "Inventory", Icon = "xzne:package" })
local ListSection = InvTab:Section({ Title = "Auto List (Sell)" })

ListSection:Paragraph({
    Title = "💡 How to List",
    Desc = "Choose items to list. Set price. Enable Auto List."
})
ListSection:Divider()

UIElements.ListTargetPet = ListSection:Dropdown({
    Title = "Pet to List", Desc = "🔍 Search...", Values = {}, Default = 1, Search = true,
    Callback = function(val) Controller.Config.ListTarget = val; Controller.Config.ListCategory = "Pet"; Controller.RequestUpdate(); Controller.SaveConfig() end
})

UIElements.ListTargetItem = ListSection:Dropdown({
    Title = "Item to List", Desc = "🔍 Search...", Values = {}, Default = 1, Search = true,
    Callback = function(val) Controller.Config.ListTarget = val; Controller.Config.ListCategory = "Item"; Controller.RequestUpdate(); Controller.SaveConfig() end
})

UIElements.Price = ListSection:Input({
    Title = "Listing Price", Desc = "Price per item", Default = tostring(Controller.Config.Price), Numeric = true,
    Callback = function(txt) Controller.Config.Price = tonumber(txt) or 5; Controller.SaveConfig() end
})

UIElements.AutoList = ListSection:Toggle({
    Title = "Start Auto List", Desc = "List automatically", Default = Controller.Config.AutoList,
    Callback = function(val) Controller.Config.AutoList = val; Controller.SaveConfig() end
})

-- == REMOVE LIST (Clear) ==
print("🔍 [XZNE DEBUG] 12. Creating Remove List Only")
local ClearSection = InvTab:Section({ Title = "Remove List" })

ClearSection:Paragraph({
    Title = "💡 How to Remove", Desc = "Select items to unlist."
})
ClearSection:Divider()

UIElements.RemoveTargetPet = ClearSection:Dropdown({
    Title = "Pet to Remove", Desc = "🔍 Search...", Values = {}, Default = 1, Search = true,
    Callback = function(val) Controller.Config.RemoveTarget = val; Controller.Config.RemoveCategory = "Pet"; Controller.RequestUpdate(); Controller.SaveConfig() end
})

UIElements.RemoveTargetItem = ClearSection:Dropdown({
    Title = "Item to Remove", Desc = "🔍 Search...", Values = {}, Default = 1, Search = true,
    Callback = function(val) Controller.Config.RemoveTarget = val; Controller.Config.RemoveCategory = "Item"; Controller.RequestUpdate(); Controller.SaveConfig() end
})

ClearSection:Divider()

UIElements.AutoClear = ClearSection:Toggle({
    Title = "Start Auto Remove", Desc = "Remove selected items", Default = Controller.Config.AutoClear,
    Callback = function(val) Controller.Config.AutoClear = val; Controller.SaveConfig() end
})

-- == BOOTH TAB ==
print("🔍 [XZNE DEBUG] 13. Creating Booth Tab")
local BoothTab = Window:Tab({ Title = "Booth", Icon = "xzne:store" })
local BoothSection = BoothTab:Section({ Title = "Booth Control" })
UIElements.AutoClaim = BoothSection:Toggle({
    Title = "Auto Claim Booth", Desc = "Fast claim", Default = Controller.Config.AutoClaim,
    Callback = function(val) Controller.Config.AutoClaim = val; Controller.SaveConfig() end
})
BoothSection:Button({
    Title = "Unclaim Booth", Desc = "Release ownership", Icon = "xzne:log-out",
    Callback = function() Controller.UnclaimBooth() end
})

-- == SETTINGS TAB ==
print("🔍 [XZNE DEBUG] 14. Creating Settings Tab")
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "xzne:settings" })

-- Stats
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

-- [GUI POPULATION]
print("🔍 [XZNE DEBUG] 15. Pre-rendering Dropdowns")
task.defer(function()
    -- ✅ OPTIMIZATION: Removed arbitrary 0.7s delay (saves 700ms)
    while not DatabaseReady do task.wait(0.1) end
    
    -- ✅ LAZY LOADING: Wait 2s after GUI ready, then populate slowly
    task.wait(2)
    print("🔄 [XZNE] Populating dropdowns in background...")

    local function SafeUpdate(element, db)
        if element then
            element.Values = db
            element.Desc = "🔍 Search "..#db.." items..."
            if element.Refresh then pcall(function() element:Refresh(db) end) end
        end
    end
    
    -- ✅ PROGRESSIVE LOADING: Populate in background, 1s between each
    SafeUpdate(UIElements.BuyTargetPet, PetDatabase)
    task.wait(1)  -- Progressive: 1s delay (user can interact with GUI)
    
    SafeUpdate(UIElements.BuyTargetItem, ItemDatabase)
    task.wait(1)
    
    SafeUpdate(UIElements.ListTargetPet, PetDatabase)
    task.wait(1)
    
    SafeUpdate(UIElements.ListTargetItem, ItemDatabase)
    task.wait(1)
    
    SafeUpdate(UIElements.RemoveTargetPet, PetDatabase)
    task.wait(1)
    
    SafeUpdate(UIElements.RemoveTargetItem, ItemDatabase)
    task.wait(0.5)  -- Final dropdown
    
    -- Default Selections (Fix empty targets)
    if not Controller.Config.BuyTarget or Controller.Config.BuyTarget == "" then
        if #ItemDatabase > 0 then
            pcall(function() UIElements.BuyTargetItem:Select(ItemDatabase[1]) end)
            Controller.Config.BuyTarget = ItemDatabase[1]
            print("[GUI] Default BuyTarget: " .. ItemDatabase[1])
        end
    end
    -- Apply Saved Selections
    if Controller.Config.BuyTarget then
         local db = Controller.Config.BuyCategory == "Pet" and UIElements.BuyTargetPet or UIElements.BuyTargetItem
         if db and db.Select then pcall(function() db:Select(Controller.Config.BuyTarget) end) end
    end
    
    print("✅ [XZNE] All dropdowns populated!")
end)

-- Notify User
Controller.Window = Window
print("✅ [XZNE] GUI Loaded Successfully!")
WindUI:Notify({
    Title = "XZNE ScriptHub Loaded",
    Content = "Welcome, " .. game.Players.LocalPlayer.Name,
    Icon = "xzne:target",
    Duration = 5
})
