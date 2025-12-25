local Controller = _G.XZNE_Controller
local WindUI = LoadWindUI()

-- [ Database Helpers ]
local ItemDatabase = {}
local PetDatabase = {}

task.spawn(function()
    -- Populate ItemDatabase (Tools in Backpack + Character)
    local seen = {}
    local function scan(loc)
        for _, v in pairs(loc:GetChildren()) do
            if v:IsA("Tool") then
                local name = v:GetAttribute("f") or v.Name
                if name and not seen[name] then
                    table.insert(ItemDatabase, name)
                    seen[name] = true
                end
            end
        end
    end
    -- Initial Scan
    if game.Players.LocalPlayer then
        if game.Players.LocalPlayer.Backpack then scan(game.Players.LocalPlayer.Backpack) end
        if game.Players.LocalPlayer.Character then scan(game.Players.LocalPlayer.Character) end
    end
    table.sort(ItemDatabase)
    
    -- Populate PetDatabase (From ReplicatedStorage if possible, or static list for now)
    -- Ideally this comes from DataService, but for UI we might need to rely on static or cached data
    -- For now, let's add some common placeholders or try to read if available
    table.insert(PetDatabase, "Dog")
    table.insert(PetDatabase, "Cat")
    table.insert(PetDatabase, "Bunny")
    -- (Real pet data gathering would be complex without direct access to the table, 
    --  but the user can search if we eventually populate this from the remote data)
end)


-- [ Window Creation ]
local Window = WindUI:CreateWindow({
    Title = "XZNE ScriptHub (v28.0)",
    Icon = "xzne:logo", -- Assuming custom icon exists or fallback
    Author = "@AgusSetiawn",
    Folder = "XZNE-v28",
    Transparent = true, 
    Theme = "Dark",
    SidebarWidth = 200,
    OpenButton = {
        Title = nil, -- Set to nil to force Icon-only (Circle) mode
        Icon = "xzne:logo", 
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 0,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
    }
})

local Tabs = {
    Sniper = Window:Tab({ Title = "Sniper", Icon = "target" }),
    Inventory = Window:Tab({ Title = "Inventory", Icon = "package" }),
    Booth = Window:Tab({ Title = "Booth", Icon = "store" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings" }),
}

-- >> SNIPER TAB <<
local SniperSection = Tabs.Sniper:Section({ Title = "Auto Buy Configuration" })

local SniperTarget, SniperTargetEle -- Forward declaration

SniperSection:Dropdown({
    Title = "Category", Desc = "Select Item or Pet", Values = {"Item", "Pet"}, Value = Controller.Config.BuyCategory,
    Callback = function(val)
        Controller.Config.BuyCategory = val
        Controller.RequestUpdate()
        Controller.SaveConfig()
        
        -- Refresh Target List
        local db = (val == "Pet") and PetDatabase or ItemDatabase
        if SniperTargetEle then SniperTargetEle:Refresh(db) end
    end
})

SniperTarget, SniperTargetEle = SniperSection:Dropdown({
    Title = "Target Item", Desc = "Search for item...", Values = ItemDatabase, Value = Controller.Config.BuyTarget,
    SearchBarEnabled = true, -- Fix: Searchable
    Callback = function(val)
        Controller.Config.BuyTarget = val; Controller.RequestUpdate(); Controller.SaveConfig()
    end
})

SniperSection:Input({
    Title = "Max Price", Desc = "Maximum price to buy", Value = tostring(Controller.Config.MaxPrice), Numeric = true,
    Callback = function(txt) Controller.Config.MaxPrice = tonumber(txt) or 5; Controller.SaveConfig() end
})

SniperSection:Slider({
    Title = "Buy Speed", Desc = "Delay after buying (Seconds)", 
    Value = { Min = 0.1, Max = 2, Default = Controller.Config.BuySpeed or 0.5 },
    Step = 0.1,
    Callback = function(val) Controller.Config.BuySpeed = val; Controller.SaveConfig() end
})

SniperSection:Toggle({
    Title = "Enable Auto Buy", Desc = "Automatically buy cheap items", Value = Controller.Config.AutoBuy,
    Callback = function(val) Controller.Config.AutoBuy = val; Controller.SaveConfig() end
})


-- >> INVENTORY TAB <<
local ListSection = Tabs.Inventory:Section({ Title = "Auto List (Sell)" })

local ListTarget, ListTargetEle -- Forward declaration

ListSection:Dropdown({
    Title = "Category", Desc = "Select Inventory Type", Values = {"Item", "Pet"}, Value = Controller.Config.ListCategory,
    Callback = function(val) 
        Controller.Config.ListCategory = val
        Controller.RequestUpdate() 
        Controller.SaveConfig() 
        
        local db = (val == "Pet") and PetDatabase or ItemDatabase
        if ListTargetEle then ListTargetEle:Refresh(db) end
    end
})

ListTarget, ListTargetEle = ListSection:Dropdown({
    Title = "Item to List", Desc = "Select item to sell", Values = ItemDatabase, Value = Controller.Config.ListTarget,
    SearchBarEnabled = true,
    Callback = function(val) Controller.Config.ListTarget = val; Controller.RequestUpdate(); Controller.SaveConfig() end
})

ListSection:Input({
    Title = "Listing Price", Desc = "Price per item", Value = tostring(Controller.Config.Price), Numeric = true,
    Callback = function(txt) Controller.Config.Price = tonumber(txt) or 5; Controller.SaveConfig() end
})

ListSection:Slider({
    Title = "List Speed", Desc = "Delay between listings", 
    Value = { Min = 1, Max = 10, Default = Controller.Config.ListSpeed or 2.0 },
    Step = 0.5,
    Callback = function(val) Controller.Config.ListSpeed = val; Controller.SaveConfig() end
})

ListSection:Toggle({
    Title = "Start Auto List", Desc = "List items automatically", Value = Controller.Config.AutoList,
    Callback = function(val) Controller.Config.AutoList = val; Controller.SaveConfig() end
})

-- Auto Clear
local ClearSection = Tabs.Inventory:Section({ Title = "Auto Clear (Trash)" })

local RemoveTarget, RemoveTargetEle -- Forward declaration

ClearSection:Dropdown({
    Title = "Category", Values = {"Item", "Pet"}, Value = Controller.Config.RemoveCategory,
    Callback = function(val) 
        Controller.Config.RemoveCategory = val 
        Controller.RequestUpdate()
        Controller.SaveConfig() 
        
        local db = (val == "Pet") and PetDatabase or ItemDatabase
        if RemoveTargetEle then RemoveTargetEle:Refresh(db) end
    end
})

RemoveTarget, RemoveTargetEle = ClearSection:Dropdown({
    Title = "Item to Trash", Values = ItemDatabase, Value = Controller.Config.RemoveTarget, 
    SearchBarEnabled = true,
    Callback = function(val) Controller.Config.RemoveTarget = val; Controller.RequestUpdate(); Controller.SaveConfig() end
})

ClearSection:Slider({
    Title = "Clear Speed", Desc = "Delay between removals", 
    Value = { Min = 0.5, Max = 5, Default = Controller.Config.RemoveSpeed or 1.0 },
    Step = 0.1,
    Callback = function(val) Controller.Config.RemoveSpeed = val; Controller.SaveConfig() end
})

ClearSection:Toggle({
    Title = "Start Auto Clear", Desc = "Delete specific items", Value = Controller.Config.AutoClear,
    Callback = function(val) Controller.Config.AutoClear = val; Controller.SaveConfig() end
})


-- >> BOOTH TAB <<
local BoothSection = Tabs.Booth:Section({ Title = "Booth Control" })
BoothSection:Toggle({
    Title = "Auto Claim Booth", Desc = "Fast claim empty booths", Value = Controller.Config.AutoClaim,
    Callback = function(val) Controller.Config.AutoClaim = val; Controller.SaveConfig() end
})
BoothSection:Button({
    Title = "Unclaim Booth", Desc = "Remove your booth", 
    Callback = function() Controller.UnclaimBooth() end
})


-- >> SETTINGS TAB <<
local PerfSection = Tabs.Settings:Section({ Title = "Performance & Safety" })

PerfSection:Label({
    Title = "Configuration",
    Desc = "Settings are saved automatically."
})

-- Initialize Config Loading (Ensure GUI reflects Loaded State)
Controller.LoadConfig()

Window:SelectTab(1)
