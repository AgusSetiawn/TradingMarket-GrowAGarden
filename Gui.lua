--[[
    💠 XZNE SCRIPTHUB v0.0.01 - UI LOADER (WindUI)
    
    🎨 Style: macOS
    🔗 Connects to: Main.lua (_G.XZNE_Controller)
]]

local WindUI
local Controller = _G.XZNE_Controller

if not Controller then
    warn("[XZNE] Controller not found! Please run Main.lua first.")
    return
end

-- [1] LOAD WINDUI
do
    local success, result = pcall(function()
        return require(script.Parent["WindUI-1.6.62"].src.Init)
    end)
    if success then
        WindUI = result
    else
        local success_online, result_online = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
        end)
        if success_online then
            WindUI = result_online
        else
            warn("[XZNE] Failed to load WindUI!")
            return
        end
    end
end

-- [2] REGISTER ICONS (Custom Set)
-- Renamed to 'xzne' to avoid conflict with internal 'lucide' namespace
WindUI.Creator.AddIcons("xzne", {
    ["home"]        = "rbxassetid://10723406988",
    ["settings"]    = "rbxassetid://10734950309",
    ["info"]        = "rbxassetid://10709752906",
    ["play"]        = "rbxassetid://10723404337",
    ["stop"]        = "rbxassetid://10709791437",
    ["trash"]       = "rbxassetid://10747373176",
    ["refresh"]     = "rbxassetid://10709790666",
    ["check"]       = "rbxassetid://10709790646",
    ["search"]      = "rbxassetid://10709791437",
    ["tag"]         = "rbxassetid://10709791523",
    ["log-out"]     = "rbxassetid://10734949856",
})

-- [3] CREATE WINDOW
local Window = WindUI:CreateWindow({
    Title = "XZNE ScriptHub",
    SubTitle = "Trading Market Manager",
    Icon = "rbxassetid://14633327344", 
    Author = "By XZNE Team",
    Folder = "XZNE-Trading",
    Transparent = true,
    Theme = "Dark",
    
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
    
    -- [FEATURE] Floating Open Button (Bubble)
    OpenButton = {
        Title = "Open XZNE",
        Icon = "xzne:home", -- Updated reference
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 0,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(
            Color3.fromHex("#30FF6A"), 
            Color3.fromHex("#26D254")
        )
    }
})

-- [FEATURE] Version Tag
Window:Tag({
    Title = "v0.0.01",
    Icon = "xzne:tag", 
    Color = Color3.fromHex("#30ff6a"),
    Radius = 4,
})

-- [4] TABS & SECTIONS

-- == MANAGER TAB ==
local ManagerTab = Window:Tab({
    Title = "Manager",
    Icon = "xzne:home",
})

local MainSection = ManagerTab:Section({ Title = "Automation" })

MainSection:Toggle({
    Title = "Auto Claim Booth",
    Desc = "Target and claim empty booths",
    Default = Controller.Config.AutoClaim,
    Callback = function(val)
        Controller.Config.AutoClaim = val
    end
})

MainSection:Toggle({
    Title = "Auto List Items",
    Desc = "List items (Attr 'f' & 'c')",
    Default = Controller.Config.AutoList,
    Callback = function(val)
        Controller.Config.AutoList = val
    end
})

MainSection:Space()

MainSection:Button({
    Title = "Unclaim Booth",
    Desc = "Release ownership",
    Icon = "xzne:log-out",
    Callback = function()
        Controller.UnclaimBooth()
        WindUI:Notify({
            Title = "Booth",
            Content = "Unclaimed command executed",
            Icon = "xzne:check",
            Duration = 2
        })
    end
})


-- == CONFIG TAB ==
local ConfigTab = Window:Tab({
    Title = "Settings",
    Icon = "xzne:settings",
})

local ItemSection = ConfigTab:Section({ Title = "Item Configuration" })

ItemSection:Input({
    Title = "Target Item Name",
    Desc = "Internal name (Attribute 'f')",
    Default = Controller.Config.TargetName,
    Icon = "xzne:tag",
    Callback = function(text)
        Controller.Config.TargetName = text
    end
})

ItemSection:Input({
    Title = "Listing Price",
    Desc = "Price for each item",
    Default = tostring(Controller.Config.Price),
    Numeric = true,
    Icon = "xzne:tag",
    Callback = function(text)
        local num = tonumber(text)
        if num then
            Controller.Config.Price = num
        end
    end
})

local PerfSection = ConfigTab:Section({ Title = "Performance Tweaks" })

PerfSection:Slider({
    Title = "Listing Delay",
    Desc = "Seconds between actions (1-10s)",
    Value = {
        Min = 1,
        Max = 10,
        Default = math.max(1, Controller.Config.ListDelay),
    },
    Step = 1,
    Callback = function(val)
        Controller.Config.ListDelay = val
    end
})

PerfSection:Button({
    Title = "Clear Item Cache",
    Desc = "Reset internal memory",
    Icon = "xzne:trash",
    Callback = function()
        Controller.ClearCache()
        WindUI:Notify({
            Title = "System",
            Content = "Cache cleared successfully",
            Icon = "xzne:check",
            Duration = 2
        })
    end
})


-- == INFO TAB ==
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "xzne:info",
})

local InfoSection = InfoTab:Section({ Title = "About" })

InfoSection:Paragraph({
    Title = "XZNE ScriptHub v0.0.01",
    Desc = "Trading Market Automation\n\n• Logic: Verified v2.0\n• UI: WindUI (Deep Polish)\n• Icons: Lucide (Custom hosted)"
})

InfoSection:Button({
    Title = "Destroy UI",
    Desc = "Close interface completely",
    Icon = "xzne:stop",
    Callback = function()
        Window:Destroy()
    end
})

-- [5] FINAL NOTIFICATION 
WindUI:Notify({
    Title = "XZNE Loaded",
    Content = "Version v0.0.01 Ready.",
    Icon = "xzne:check",
    Duration = 4
})
