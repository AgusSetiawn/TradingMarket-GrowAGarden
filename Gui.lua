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

-- [1] INSTANT LOADING FEEDBACK
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

-- [3] REGISTER ICONS
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
end)

-- [4] LOAD DATABASES (DEFERRED for faster GUI appearance)
local HttpService = game:GetService("HttpService")
local PetDatabase, ItemDatabase = {}, {}
local DatabaseReady = false

-- ✅ OPTIMIZATION: JSON Database with Local Caching
local CachedDBFile = ".xzne/XZNE_Database.json"

task.defer(function()
    task.wait(0.3)  -- Let GUI render first
    
    -- Create config folder if not exists
    if makefolder and not isfolder(".xzne") then
        makefolder(".xzne")
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

-- [5] CREATE WINDOW (Premium Glassmorphism Style)
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
-- Store window reference for cleanup
Controller.Window = Window

local UIElements = {}

-- [SINGLE MAIN TAB - ULTRA SIMPLIFIED]
local MainTab = Window:Tab({ Title = "Main", Icon = "xzne:target" })

-- === SHARED TARGET SELECTION ===
local TargetSection = MainTab:Section({ Title = "🎯 Target Selection", Icon = "crosshair" })

TargetSection:Paragraph({
    Title = "💡 Quick Guide",
    Desc = "Select your target Pet or Item below. Then enable which function you want to use (Buy/List/Remove)."
})
TargetSection:Divider()

-- SHARED Pet Dropdown (used by ALL functions)
UIElements.TargetPet = TargetSection:Dropdown({
    Title = "Target Pet", 
    Desc = "🔍 Search 277 pets...",
    Values = {}, Default = 1, Search = true,
    Callback = function(val) 
        -- Update ALL configs to use this pet
        Controller.Config.BuyTarget = val
        Controller.Config.BuyCategory = "Pet"
        Controller.Config.ListTarget = val
        Controller.Config.ListCategory = "Pet"
        Controller.Config.RemoveTarget = val
        Controller.Config.RemoveCategory = "Pet"
        Controller.RequestUpdate()
        Controller.SaveConfig()
    end
})

-- SHARED Item Dropdown (used by ALL functions)
UIElements.TargetItem = TargetSection:Dropdown({
    Title = "Target Item", 
    Desc = "🔍 Search 363 items...",
    Values = {}, Default = 1, Search = true,
    Callback = function(val) 
        -- Update ALL configs to use this item
        Controller.Config.BuyTarget = val
        Controller.Config.BuyCategory = "Item"
        Controller.Config.ListTarget = val
        Controller.Config.ListCategory = "Item"
        Controller.Config.RemoveTarget = val
        Controller.Config.RemoveCategory = "Item"
        Controller.RequestUpdate()
        Controller.SaveConfig()
    end
})

TargetSection:Divider()

-- === AUTO BUY SECTION ===
local BuySection = MainTab:Section({ Title = "💰 Auto Buy (Sniper)", Icon = "zap" })

UIElements.MaxPrice = BuySection:Input({
    Title = "Max Price", Desc = "Maximum price to pay", Default = tostring(Controller.Config.MaxPrice), Numeric = true,
    Callback = function(txt) Controller.Config.MaxPrice = tonumber(txt) or 5; Controller.SaveConfig() end
})

UIElements.AutoBuy = BuySection:Toggle({
    Title = "Enable Auto Buy", Desc = "Snipe selected target", Default = Controller.Config.AutoBuy,
    Callback = function(val) Controller.Config.AutoBuy = val; Controller.SaveConfig() end
})

BuySection:Divider()

-- === AUTO LIST SECTION ===
local ListSection = MainTab:Section({ Title = "📦 Auto List (Sell)", Icon = "xzne:package" })

UIElements.Price = ListSection:Input({
    Title = "Listing Price", Desc = "Price per item", Default = tostring(Controller.Config.Price), Numeric = true,
    Callback = function(txt) Controller.Config.Price = tonumber(txt) or 5; Controller.SaveConfig() end
})

UIElements.AutoList = ListSection:Toggle({
    Title = "Enable Auto List", Desc = "List selected target", Default = Controller.Config.AutoList,
    Callback = function(val) Controller.Config.AutoList = val; Controller.SaveConfig() end
})

ListSection:Divider()

-- === AUTO REMOVE SECTION ===
local RemoveSection = MainTab:Section({ Title = "🗑️ Auto Remove", Icon = "xzne:trash-2" })

UIElements.AutoClear = RemoveSection:Toggle({
    Title = "Enable Auto Remove", Desc = "Remove selected target", Default = Controller.Config.AutoClear,
    Callback = function(val) Controller.Config.AutoClear = val; Controller.SaveConfig() end
})

UIElements.DeleteAll = RemoveSection:Toggle({
    Title = "Remove ALL Listings", Desc = "Clear entire booth", Default = Controller.Config.DeleteAll,
    Callback = function(val) Controller.Config.DeleteAll = val; Controller.SaveConfig() end
})

RemoveSection:Divider()

-- === BOOTH CONTROL SECTION ===
local BoothSection = MainTab:Section({ Title = "🏪 Booth Control", Icon = "xzne:store" })

UIElements.AutoClaim = BoothSection:Toggle({
    Title = "Auto Claim Booth", Desc = "Automatically claim booth", Default = Controller.Config.AutoClaim,
    Callback = function(val) Controller.Config.AutoClaim = val; Controller.SaveConfig() end
})

BoothSection:Button({
    Title = "Unclaim Booth", Desc = "Release booth ownership", Icon = "xzne:log-out",
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
            element.Values = db
            element.Desc = "🔍 Search "..#db.." items..."
            if element.Refresh then pcall(function() element:Refresh(db) end) end
        end
    end
    
    -- Populate only 2 dropdowns (shared across all functions)
    SafeUpdate(UIElements.TargetPet, PetDatabase)
    task.wait(0.05)
    SafeUpdate(UIElements.TargetItem, ItemDatabase)
    
    -- Set default selection if empty
    if not Controller.Config.BuyTarget or Controller.Config.BuyTarget == "" then
        if #ItemDatabase > 0 then
            pcall(function() UIElements.TargetItem:Select(ItemDatabase[1]) end)
            Controller.Config.BuyTarget = ItemDatabase[1]
            Controller.Config.BuyCategory = "Item"
        end
    end
    
    -- Apply saved selections
    if Controller.Config.BuyTarget then
        local db = Controller.Config.BuyCategory == "Pet" and UIElements.TargetPet or UIElements.TargetItem
        if db and db.Select then 
            task.defer(function()
                pcall(function() db:Select(Controller.Config.BuyTarget) end)
            end)
        end
    end
end)

-- Settings Tab
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



-- Notify User
Controller.Window = Window
print("✅ [XZNE] GUI Loaded Successfully!")
WindUI:Notify({
    Title = "XZNE ScriptHub Loaded",
    Content = "Welcome, " .. game.Players.LocalPlayer.Name,
    Icon = "xzne:target",
    Duration = 5
})
