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

-- [2] DATABASES 
local PetDatabase = {
    "Dog", "Golden Lab", "Bunny", "Black Bunny", "Cat", "Deer", "Chicken", "Orange Tabby", "Spotted Deer", "Rooster", 
    "Monkey", "Pig", "Silver Monkey", "Turtle", "Cow", "Sea Otter", "Polar Bear", "Caterpillar", "Snail", "Giant Ant", 
    "Praying Mantis", "Dragonfly", "Panda", "Hedgehog", "Kiwi", "Mole", "Frog", "Echo Frog", "Raccoon", "Night Owl", 
    "Owl", "Grey Mouse", "Squirrel", "Brown Mouse", "Red Giant Ant", "Red Fox", "Chicken Zombie", "Blood Hedgehog", 
    "Blood Kiwi", "Blood Owl", "Moon Cat", "Bee", "Honey Bee", "Petal Bee", "Bear Bee", "Queen Bee", "Wasp", 
    "Tarantula Hawk", "Moth", "Butterfly", "Disco Bee", "Cooked Owl", "Pack Bee", "Starfish", "Crab", "Seagull", 
    "Toucan", "Flamingo", "Sea Turtle", "Seal", "Orangutan", "Peacock", "Capybara", "Scarlet Macaw", "Ostrich", 
    "Mimic Octopus", "Meerkat", "Sand Snake", "Axolotl", "Hyacinth Macaw", "Fennec Fox", "Hamster", "Bald Eagle", 
    "Raptor", "Stegosaurus", "Triceratops", "Pterodactyl", "Brontosaurus", "Radioactive Stegosaurus", "T-Rex", 
    "Parasaurolophus", "Iguanodon", "Pachycephalosaurus", "Dilophosaurus", "Ankylosaurus", "Spinosaurus", 
    "Rainbow Parasaurolophus", "Rainbow Iguanodon", "Rainbow Pachycephalosaurus", "Rainbow Dilophosaurus", 
    "Rainbow Ankylosaurus", "Rainbow Spinosaurus", "Shiba Inu", "Nihonzaru", "Tanuki", "Tanchozuru", "Kappa", 
    "Kitsune", "Koi", "Football", "Maneki-neko", "Kodama", "Corrupted Kodama", "Raiju", "Corrupted Kitsune", 
    "Rainbow Maneki-neko", "Rainbow Kodama", "Rainbow Corrupted Kitsune", "Bagel Bunny", "Pancake Mole", 
    "Sushi Bear", "Spaghetti Sloth", "French Fry Ferret", "Mochi Mouse", "Junkbot", "Bacon Pig", "Hotdog Daschund", 
    "Lobster Thermidor", "Sunny-Side Chicken", "Gorilla Chef", "Rainbow Bacon Pig", "Rainbow Hotdog Daschund", 
    "Rainbow Lobster Thermidor", "Dairy Cow", "Jackalope", "Seedling", "Golem", "Golden Goose", "Spriggan", 
    "Peach Wasp", "Apple Gazelle", "Lemon Lion", "Green Bean", "Elk", "Mandrake", "Griffin", "Gnome", "Rainbow Elk", 
    "Rainbow Mandrake", "Rainbow Griffin", "Ladybug", "Pixie", "Imp", "Glimmering Sprite", "Cockatrice", "Cardinal", 
    "Shroomie", "Phoenix", "Wisp", "Drake", "Luminous Sprite", "Rainbow Cardinal", "Rainbow Shroomie", 
    "Rainbow Phoenix", "Robin", "Badger", "Grizzly Bear", "Barn Owl", "Swan", "GIANT Robin", "GIANT Badger", 
    "GIANT Grizzly Bear", "GIANT Barn Owl", "GIANT Swan", "Chipmunk", "Red Squirrel", "Marmot", "Sugar Glider", 
    "Space Squirrel", "Salmon", "Woodpecker", "Mallard", "Red Panda", "Tree Frog", "Hummingbird", "Iguana", 
    "Chimpanzee", "Tiger", "Blue Jay", "Silver Dragonfly", "Firefly", "Mizuchi", "Rainbow Blue Jay", 
    "GIANT Silver Dragonfly", "GIANT Firefly", "Rainbow Mizuchi", "Chubby Chipmunk", "Farmer Chipmunk", 
    "Idol Chipmunk", "Chinchilla", "Rainbow Farmer Chipmunk", "Rainbow Idol Chipmunk", "Rainbow Chinchilla", 
    "Hyrax", "Fortune Squirrel", "Bat", "Bone Dog", "Spider", "Black Cat", "Headless Horseman", "Ghostly Bat", 
    "Ghostly Bone Dog", "Ghostly Spider", "Ghostly Black Cat", "Ghostly Headless Horseman", "Pumpkin Rat", 
    "Ghost Bear", "Wolf", "Reaper", "Crow", "Goat", "Goblin", "Dark Spriggan", "Hex Serpent", 
    "Ghostly Dark Spriggan", "Scarab", "Tomb Marmot", "Mummy", "Ghostly Scarab", "Ghostly Tomb Marmot", 
    "Ghostly Mummy", "Lich", "Woody", "Specter", "Armadillo", "Stag Beetle", "Mantis Shrimp", "Hydra", "Oxpecker", 
    "Zebra", "Giraffe", "Rhino", "Elephant", "GIANT Armadillo", "Rainbow Stag Beetle", "GIANT Mantis Shrimp", 
    "Rainbow Hydra", "Rainbow Oxpecker", "Rainbow Zebra", "Rainbow Giraffe", "Rainbow Rhino", "Rainbow Elephant", 
    "Gecko", "Hyena", "Cape Buffalo", "Hippo", "Crocodile", "Lion", "Topaz Snail", "Amethyst Beetle", 
    "Emerald Snake", "Sapphire Macaw", "Diamond Panther", "Ruby Squid", "Termite", "Geode Turtle", "Trapdoor Spider", 
    "Goblin Miner", "Smithing Dog", "Cheetah", "Silver Piggy", "Golden Piggy", "Clam", "Magpie", "Bearded Dragon", 
    "Rainbow Clam", "Rainbow Magpie", "Rainbow Bearded Dragon", "Pack Mule", "Water Buffalo", "Chimera", "Sheckling", 
    "Messenger Pigeon", "Camel", "Snowman Soldier", "Snowman Builder", "Arctic Fox", "Frost Dragon", 
    "GIANT Snowman Soldier", "GIANT Snowman Builder", "Rainbow Arctic Fox", "Rainbow Frost Dragon", "Gift Rat", 
    "Penguin", "Snow Bunny", "French Hen", "Christmas Gorilla", "Mistletoad", "Krampus", "Rainbow Snow Bunny", 
    "Rainbow French Hen", "Rainbow Christmas Gorilla", "Rainbow Mistletoad", "Rainbow Krampus", "Turtle Dove", 
    "Reindeer", "Nutcracker", "Yeti", "Ice Golem", "Festive Turtle Dove", "Festive Reindeer", "Festive Nutcracker", 
    "Festive Yeti", "Festive Ice Golem", "Pine Beetle", "Cocoa Cat", "Eggnog Chick", "Red-Nosed Reindeer", 
    "Partridge", "Santa Bear", "Moose", "Frost Squirrel", "Wendigo", "Festive Partridge", "Festive Santa Bear", 
    "Festive Moose", "Festive Frost Squirrel", "Festive Wendigo", "Summer Kiwi", "Christmas Spirit", "Red Dragon", 
    "Golden Bee", "Tsuchinoko", "Rainbow Fortune Squirrel", "Glass Dog", "Glass Cat"
}

local ItemDatabase = {
    "Ackee", "Acorn", "Acorn Squash", "Aetherfruit", "Aloe Vera", "Amber Spine", "Amberfruit Shrub", "Amberheart", 
    "Antlerbloom", "Apple", "Artichoke", "Asteris", "Auburn Pine", "Aurora Vine", "Autumn Shroom", "Avocado", 
    "Badlands Pepper", "Bamboo", "Bamboo Tree", "Banana", "Banana Orchid", "Banesberry", "Baobab", "Beanstalk", 
    "Bee Balm", "Beetroot", "Bell Pepper", "Bendboo", "Bitter Melon", "Black Bat Flower", "Blood Banana", 
    "Blood Orange", "Bloodred Mushroom", "Blue Raspberry", "Blueberry", "Bone Blossom", "Boneboo", "Briar Rose", 
    "Broccoli", "Brussels Sprout", "Buddhas Hand", "Burning Bud", "Bush Flake", "Buttercup", "Butternut Squash", 
    "Cacao", "Cactus", "Calla Lily", "Canary Melon", "Candy Blossom", "Candy Cane", "Candy Cornflower", 
    "Candy Sunflower", "Cantaloupe", "Carnival Pumpkin", "Carrot", "Castor Bean", "Cauliflower", "Celestiberry", 
    "Cherry Blossom", "Chicken Feed", "Chocolate Carrot", "Christmas Cracker", "Cocomango", "Coconut", "Cocovine", 
    "Coilvine", "Coinfruit", "Cookie Stack", "Corn", "Corpse Flower", "Cranberry", "Crimson Thorn", "Crocus", 
    "Crown Melon", "Crown of Thorns", "Cryo Rose", "Cryoshard", "Cursed Fruit", "Cyclamen", "Daffodil", "Daisy", 
    "Dandelion", "Delphinium", "Devilroot", "Dezen", "Dragon Fruit", "Dragon Pepper", "Durian", "Duskpuff", 
    "Easter Egg", "Eggplant", "Elder Strawberry", "Elephant Ears", "Ember Lily", "Emerald Bud", "Enkaku", 
    "Fall Berry", "Feijoa", "Ferntail", "Firefly Fern", "Firewell", "Firework Flower", "Fissure Berry", 
    "Flare Daisy", "Flare Melon", "Fossilight", "Foxglove", "Frostspike", "Frostwing", "Frosty Bite", "Fruitball", 
    "Gem Fruit", "Ghost Bush", "Ghost Pepper", "Ghoul Root", "Gift Berry", "GingerBread Blossom", "Giant Pinecone", 
    "Glass Kiwi", "Gleamroot", "Glowpod", "Glowshroom", "Glowthorn", "Golden Egg", "Golden Peach", "Grand Tomato", 
    "Grand Volcania", "Grape", "Great Pumpkin", "Green Apple", "Guanabana", "Gumdrop", "Hazelnut", "Hinomai", 
    "Hive Fruit", "Hollow Bamboo", "Holly Berry", "Honeysuckle", "Horned Dinoshroom", "Horned Melon", "Horned Redrose", 
    "Horsetail", "Inferno Quince", "Jack O Lantern", "Jalapeno", "Java Banana", "King Cabbage", "Kiwi", "Kniphofia", 
    "Lavender", "Legacy Sunflower", "Lemon", "Liberty Lily", "Lightshoot", "Lilac", "Lily of the Valley", 
    "Lingonberry", "Loquat", "Lotus", "Lucky Bamboo", "Lumin Bloom", "Lumira", "Luna Stem", "Mandrake", 
    "Mandrone Berry", "Mango", "Mangosteen", "Mangrove", "Manuka Flower", "Maple Apple", "Maple Resin", 
    "Meyer Lemon", "Mint", "Monoblooma", "Monster Flower", "Moon Blossom", "Moon Mango", "Moon Melon", 
    "Moonflower", "Moonglow", "Multitrap", "Mummy's Hand", "Mushroom", "Naval Wort", "Nectar Thorn", "Nectarine", 
    "Nectarshade", "Nightshade", "Octobloom", "Olive", "Onion", "Orange Delight", "Orange Tulip", "Papaya", 
    "Paradise Petal", "Parasol Flower", "Parsley", "Passionfruit", "Peace Lily", "Peach", "Peacock Tail", 
    "Pear", "Pecan", "Pepper", "Peppermint Pop", "Peppermint Vine", "Persimmon", "Pineapple", "Pink Lily", 
    "Pinkside Dandelion", "Pitcher Plant", "Pixie Faern", "Poinsettia", "Poison Apple", "Pollen Cone", 
    "Pomegranate", "Poseidon Plant", "Potato", "Pricklefruit", "Prickly Pear", "Princess Thorn", "Protea", 
    "Pumpkin", "Purple Dahlia", "Pyracantha", "Radish", "Rafflesia", "Raspberry", "Red Lollipop", "Reindeer Root", 
    "Rhubarb", "Romanesco", "Rose", "Rosemary", "Rosy Delight", "Sakura Bush", "Seer Vine", "Serenity", 
    "Severed Spine", "Sherrybloom", "Snaparino Beanarini", "Snowman Sprout", "Soft Sunshine", "Soul Fruit", 
    "Speargrass", "Spider Vine", "Spiked Mango", "Spirit Flower", "Spirit Sparkle", "Spring Onion", "Starfruit", 
    "Stonebite", "Strawberry", "Succulent", "Sugar Apple", "Sugarglaze", "Sunbulb", "Suncoil", "Sundew", 
    "Sunflower", "Taco Fern", "Tall Asparagus", "Taro Flower", "Thornspire", "Tomato", "Torchflare", 
    "Tranquil Bloom", "Traveler's Fruit", "Trinity Fruit", "Turnip", "Twisted Tangle", "Untold Bell", 
    "Urchin Plant", "Veinpetal", "Venus Fly Trap", "Viburnum Berry", "Violet Corn", "Watermelon", "Weeping Branch", 
    "Wereplant", "Wild Carrot", "Wild Pineapple", "Willowberry", "Wisp Flower", "Wispwing", "Wyrmvine", "Yarrow", 
    "Zebrazinkle", "Zen Rocks", "Zenflare", "Zombie Fruit", "Zucchini"
}

-- [PHASE 1 OPTIMIZATION] Pre-sort databases asynchronously at startup
task.spawn(function()
    table.sort(PetDatabase)
    table.sort(ItemDatabase)
    print("✅ [XZNE] Databases sorted and ready")
end)

-- [3] REGISTER ICONS
WindUI.Creator.AddIcons("xzne", {
    ["home"] = "rbxassetid://10723406988", ["settings"] = "rbxassetid://10734950309", ["info"] = "rbxassetid://10709752906",
    ["play"] = "rbxassetid://10723404337", ["stop"] = "rbxassetid://10709791437", ["trash"] = "rbxassetid://10747373176",
    ["refresh"] = "rbxassetid://10709790666", ["check"] = "rbxassetid://10709790646", ["search"] = "rbxassetid://10709791437",
    ["tag"] = "rbxassetid://10709791523", ["log-out"] = "rbxassetid://10734949856", ["crosshair"] = "rbxassetid://10709790537",
    ["box"] = "rbxassetid://10709791360"
})

-- [4] CREATE WINDOW
local Window = WindUI:CreateWindow({
    Title = "XZNE ScriptHub v0.0.01",
    SubTitle = "Beta Release",
    Icon = "rbxassetid://14633327344", 
    Author = "By XZNE Team", 
    Folder = "XZNE-v0.0.01", 
    Transparent = true, 
    Theme = "Dark",
    Topbar = { Height = 44, ButtonsType = "Mac" },
    ToggleKey = Enum.KeyCode.RightControl,
    OpenButton = { Title = "XZNE", Icon = "xzne:home", Color = ColorSequence.new(Color3.fromHex("#30FF6A"), Color3.fromHex("#26D254")) }
})

local UIElements = {}

-- == SNIPER TAB ==
local SniperTab = Window:Tab({ Title = "Sniper", Icon = "xzne:crosshair" })
local SniperSection = SniperTab:Section({ Title = "Auto Buy Configuration" })

-- [PHASE 2 OPTIMIZATION] Asynchronous dropdown refresh with micro-yield
local function UpdateTargetDropdown(CategoryVal, TargetElement)
    if TargetElement then
        local newDB = (CategoryVal == "Pet") and PetDatabase or ItemDatabase
        
        -- Update the Values property
        TargetElement.Values = newDB
        
        -- Asynchronous refresh to prevent main-thread blocking
        task.spawn(function()
            task.wait(0.05) -- Micro-yield: allows button click animation to complete
            if TargetElement.Refresh then
                pcall(function() 
                    TargetElement:Refresh(newDB)
                end)
            end
        end)
    end
end

UIElements.BuyCategory = SniperSection:Dropdown({
    Title = "Category", Desc = "Select Item type", Values = {"Item", "Pet"}, Default = Controller.Config.BuyCategory, Searchable = true,
    Callback = function(val)
        Controller.Config.BuyCategory = val; Controller.RequestUpdate(); Controller.SaveConfig()
        UpdateTargetDropdown(val, UIElements.BuyTarget)
    end
})

-- LAZY LOAD: Create with empty values for instant UI, populate later
UIElements.BuyTarget = SniperSection:Dropdown({
    Title = "Target Item", Desc = "Loading...", Values = {}, 
    Default = 1, Searchable = true,
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

UIElements.ListCategory = ListSection:Dropdown({
    Title = "Category", Desc = "Select Inventory Type", Values = {"Item", "Pet"}, Default = Controller.Config.ListCategory, Searchable = true,
    Callback = function(val) 
        Controller.Config.ListCategory = val; Controller.RequestUpdate(); Controller.SaveConfig()
        UpdateTargetDropdown(val, UIElements.ListTarget)
    end
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

local ClearSection = InvTab:Section({ Title = "Auto Clear (Trash)" })
UIElements.RemoveCategory = ClearSection:Dropdown({
    Title = "Category", Values = {"Item", "Pet"}, Default = Controller.Config.RemoveCategory, Searchable = true,
    Callback = function(val) 
        Controller.Config.RemoveCategory = val; Controller.RequestUpdate(); Controller.SaveConfig()
        UpdateTargetDropdown(val, UIElements.RemoveTarget)
    end
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

-- [GUI POPULATION - Deferred & Asynchronous]
task.spawn(function()
    -- Wait for databases to finish sorting
    task.wait(0.5)
    
    -- Helper: Populate dropdown asynchronously (non-blocking)
    local function PopulateDropdown(element, category, targetValue)
        if element then
            task.spawn(function()
                local db = (category == "Pet") and PetDatabase or ItemDatabase
                element.Values = db
                element.Desc = "Search for item..." -- Reset description
                
                if element.Refresh then
                    pcall(function() element:Refresh(db) end)
                end
                
                -- Set saved value after population
                if element.Select and targetValue then
                    task.wait(0.1) -- Allow refresh to complete
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
    
    -- Sync simple elements first (instant, no freeze)
    SyncToggle(UIElements.AutoBuy, Controller.Config.AutoBuy)
    SyncToggle(UIElements.AutoList, Controller.Config.AutoList)
    SyncToggle(UIElements.AutoClear, Controller.Config.AutoClear)
    SyncToggle(UIElements.AutoClaim, Controller.Config.AutoClaim)
    SyncToggle(UIElements.DeleteAll, Controller.Config.DeleteAll)
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
