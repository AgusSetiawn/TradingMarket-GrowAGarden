--[[
    💠 XZNE SCRIPTHUB v18.0 - UI LOADER (WindUI)
    
    🎨 Style: macOS
    🔗 Connects to: Main.lua (_G.XZNE_Controller)
]]

local WindUI
local Controller = _G.XZNE_Controller

if not Controller then
    warn("[XZNE] Controller not found! Please run Main.lua first.")
    -- Optional: Attempt to load Main.lua if it's in the same closure, 
    -- but usually standard practice is to run the script bundle.
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
        -- Fallback to loadstring (Online) if local file fails or not in Studio
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
    Icon = "rbxassetid://14633327344", -- Keep original icon
    Author = "v18.0", 
    Folder = "XZNE-Trading",
    Transparent = true, -- Acrylic effect
    Theme = "Dark",
    
    Topbar = {
        Height = 44,
        ButtonsType = "Mac", -- Requested macOS style
    }
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
    Desc = "Automatically claims free booths",
    Default = Controller.Config.AutoClaim,
    Callback = function(val)
        Controller.Config.AutoClaim = val
    end
})

MainSection:Toggle({
    Title = "Auto List Items",
    Desc = "Automatically lists target items",
    Default = Controller.Config.AutoList,
    Callback = function(val)
        Controller.Config.AutoList = val
    end
})

MainSection:Space()

MainSection:Button({
    Title = "Unclaim Booth",
    Desc = "Drops current booth ownership",
    Callback = function()
        Controller.UnclaimBooth()
        WindUI:Notify({
            Title = "Booth",
            Content = "Unclaimed command sent!",
            Duration = 2
        })
    end
})


-- == CONFIG TAB ==
local ConfigTab = Window:Tab({
    Title = "Configuration",
    Icon = "settings",
})

local ItemSection = ConfigTab:Section({ Title = "Item Settings" })

ItemSection:Input({
    Title = "Target Item Name",
    Desc = "The internal name (Attribute 'f')",
    Default = Controller.Config.TargetName,
    Callback = function(text)
        Controller.Config.TargetName = text
    end
})

ItemSection:Input({
    Title = "Listing Price",
    Desc = "Price to list items for",
    Default = tostring(Controller.Config.Price),
    Numeric = true,
    Callback = function(text)
        local num = tonumber(text)
        if num then
            Controller.Config.Price = num
        end
    end
})

local SpeedSection = ConfigTab:Section({ Title = "Performance" })

SpeedSection:Slider({
    Title = "Listing Delay",
    Desc = "Time between listings (seconds)",
    Min = 0.1,
    Max = 10,
    Default = Controller.Config.ListDelay,
    Step = 0.1,
    Callback = function(val)
        Controller.Config.ListDelay = val
    end
})

SpeedSection:Button({
    Title = "Clear Cache",
    Desc = "Reset listed items memory",
    Callback = function()
        Controller.ClearCache()
        WindUI:Notify({
            Title = "Memory",
            Content = "Cache cleared!",
            Duration = 2
        })
    end
})


-- == INFO TAB ==
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "info",
})

local InfoSection = InfoTab:Section({ Title = "Statistics" })

-- Live Stats Update
local StatParams = {
    Title = "Status",
    Desc = "Waiting for data..."
}
-- We can't update a Paragraph directly in WindUI standard API easily without storing the object 
-- or using a label updater if supported. 
-- For now, we'll try to re-render or use a specific element if available, 
-- but standard WindUI Paragraphs illustrate static text often. 
-- Let's use a Section Title update or similar if possible, OR just static info for now
-- since dynamic label updating depends on library version features.
-- Assuming standard usage:
InfoSection:Paragraph({
    Title = "Session Stats",
    Desc = "Check server console (F9) for detailed logs.\n\nWindUI Version: " .. (WindUI.Version or "Unknown")
})

local CreditSection = InfoTab:Section({ Title = "Credits" })
CreditSection:Paragraph({
    Title = "XZNE ScriptHub",
    Desc = "Refactored by Assistant.\nUsing WindUI Library."
})

CreditSection:Button({
    Title = "Close UI",
    Callback = function()
        Window:Destroy()
        -- Controller.Config.Running = false -- Optional: Stop logic too?
    end
})

-- [4] NOTIFICATION
WindUI:Notify({
    Title = "XZNE Hub Loaded",
    Content = "Welcome back! Logic v18.0 Active.",
    Duration = 5
})
