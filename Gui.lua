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

-- [2] CREATE WINDOW
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
        Title = "XZNE",
        CornerRadius = UDim.new(1, 0), -- Round
        StrokeThickness = 0,
        Enabled = true,
        Draggable = true,
        Color = ColorSequence.new(
            Color3.fromHex("#30FF6A"), 
            Color3.fromHex("#26D254")
        )
    }
})

-- [FEATURE] Version Tag
Window:Tag({
    Title = "v0.0.01",
    Icon = "github", -- Uses internal WindUI icon mapping if available
    Color = Color3.fromHex("#30ff6a"),
    Radius = 4,
})

-- [3] TABS & SECTIONS

-- == MANAGER TAB ==
local ManagerTab = Window:Tab({
    Title = "Manager",
    Icon = "home",
})

local MainSection = ManagerTab:Section({ Title = "Automation" })

MainSection:Toggle({
    Title = "Auto Claim Booth",
    Desc = "Automatically finds and claims free booths",
    Default = Controller.Config.AutoClaim,
    Callback = function(val)
        Controller.Config.AutoClaim = val
    end
})

MainSection:Toggle({
    Title = "Auto List Items",
    Desc = "Lists items matching Attribute 'f' & 'c'",
    Default = Controller.Config.AutoList,
    Callback = function(val)
        Controller.Config.AutoList = val
    end
})

MainSection:Space()

MainSection:Button({
    Title = "Unclaim Booth",
    Desc = "Release current booth ownership",
    Callback = function()
        Controller.UnclaimBooth()
        WindUI:Notify({
            Title = "Booth",
            Content = "Unclaimed command executed",
            Duration = 2
        })
    end
})


-- == CONFIG TAB ==
local ConfigTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

local ItemSection = ConfigTab:Section({ Title = "Item Configuration" })

ItemSection:Input({
    Title = "Target Item Name",
    Desc = "Internal name (Attribute 'f')",
    Default = Controller.Config.TargetName,
    Callback = function(text)
        Controller.Config.TargetName = text
    end
})

ItemSection:Input({
    Title = "Listing Price",
    Desc = "Price for each listed item",
    Default = tostring(Controller.Config.Price),
    Numeric = true,
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
    Desc = "Wait time between actions (seconds)",
    Min = 0.1,
    Max = 10,
    Default = Controller.Config.ListDelay,
    Step = 0.1,
    Callback = function(val)
        Controller.Config.ListDelay = val
    end
})

PerfSection:Button({
    Title = "Clear Item Cache",
    Desc = "Reset memory of listed items",
    Callback = function()
        Controller.ClearCache()
        WindUI:Notify({
            Title = "System",
            Content = "Cache cleared successfully",
            Duration = 2
        })
    end
})


-- == INFO TAB ==
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "info",
})

local InfoSection = InfoTab:Section({ Title = "About" })

InfoSection:Paragraph({
    Title = "XZNE ScriptHub v0.0.01",
    Desc = "A refined trading automation tool.\n\nCredits:\n• Logic: v2.0 (Verified)\n• UI: WindUI Library"
})

InfoSection:Button({
    Title = "Destroy UI",
    Desc = "Close interface completely",
    Callback = function()
        Window:Destroy()
    end
})

-- [4] NOTIFICATION 
WindUI:Notify({
    Title = "XZNE Loaded",
    Content = "Version v0.0.01 Ready.",
    Duration = 4
})
