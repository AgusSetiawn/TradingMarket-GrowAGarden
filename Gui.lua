--[[
    💠 XZNE SCRIPTHUB v0.0.01 Beta - UI LOADER
    
    🎨 WindUI Interface - Antarmuka pengguna dengan desain premium
    🔗 Terhubung ke: Main.lua (_G.XZNE_Controller)
    📋 Fungsi: Membuat GUI, mengelola konfigurasi, dan bind ke logic controller
]]

local WindUI
local Controller = _G.XZNE_Controller

-- Validasi: Controller harus sudah ada (dibuat oleh Main.lua)
if not Controller then
    -- Controller tidak ditemukan, GUI tidak bisa dimuat
    return
end

-- [0] KUNCI SAVE (Mencegah overwrite saat inisialisasi)
-- Flag ini digunakan untuk mencegah autosave saat GUI sedang loading config
if _G.XZNE_Restoring == nil then _G.XZNE_Restoring = true end

-- [1] SISTEM KONFIGURASI (Dipindah ke atas untuk inisialisasi paksa)
-- Menyimpan dan memuat konfigurasi dari file JSON lokal
local HttpService = game:GetService("HttpService")
local ConfigFile = "XZNE ScriptHub/Config.json"  -- Path file konfigurasi

-- Fungsi untuk menyimpan konfigurasi ke file JSON
local function SaveToJSON()
    -- Buat folder jika belum ada
    if not isfolder("XZNE ScriptHub") then makefolder("XZNE ScriptHub") end
    
    local success, json = pcall(function()
        -- Encode tabel Config menjadi JSON string
        return HttpService:JSONEncode(Controller.Config)
    end)
    
    if success then
        -- Tulis JSON ke file
        writefile(ConfigFile, json)
    end
end

-- Fungsi AutoSave (dipanggil setiap kali config berubah)
local function AutoSave()
    -- Jangan save jika sedang dalam fase restoring
    if _G.XZNE_Restoring then 
        return 
    end
    -- Save ke JSON dan update cache di Main.lua
    pcall(SaveToJSON)
    pcall(function() Controller.UpdateCache() end)
end

-- Fungsi untuk memuat konfigurasi dari file JSON (Pasif)
local function LoadFromJSON()
    -- Cek apakah file config ada
    if isfile(ConfigFile) then
        local success, result = pcall(readfile, ConfigFile)
        if success and result then
            -- File berhasil dibaca, decode JSON
            local decoded = HttpService:JSONDecode(result)
            if decoded then
                -- Copy semua nilai dari decoded ke Controller.Config
                for k,v in pairs(decoded) do
                    Controller.Config[k] = v
                end
                -- Update cache target di Main.lua
                Controller.UpdateCache()
                return true
            end
        end
    end
    return false
end

-- MUAT KONFIGURASI SEKARANG (Sebelum UI dibuat)
-- Ini memastikan nilai 'Default' di UI sudah benar sejak awal
_G.XZNE_Restoring = true  -- KUNCI (Lock save)
local loadStatus = LoadFromJSON()



-- [2] MUAT WINDUI LIBRARY
-- Download dan load library WindUI dari GitHub
do
    local success, result = pcall(function()
        local url = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
        local content = game:HttpGet(url)
        
        -- Validasi: Pastikan konten tidak kosong
        if #content < 100 then 
            error("WindUI content terlalu kecil, kemungkinan gagal download") 
        end
        
        -- Compile konten menjadi function
        local func, err = loadstring(content)
        if not func then 
            error("WindUI Loadstring Error: " .. tostring(err)) 
        end
        
        -- Jalankan function dan return library
        return func()
    end)
    
    if success and result then
        WindUI = result  -- Library berhasil dimuat
    else
        -- Gagal memuat WindUI, GUI tidak bisa dibuat
        return
    end
end

-- [3] ICONS
-- Menggunakan icon bawaan WindUI (Lucide Icons) untuk konsistensi desain
-- Tidak perlu registrasi custom icon

-- [4] MUAT DATABASE (DEFERRED untuk GUI muncul lebih cepat)
-- Database Pet dan Item diload secara asynchronous agar tidak menghalangi GUI
local PetDatabase, ItemDatabase = {}, {}
local DatabaseReady = false

-- Optimasi: Cache database lokal untuk loading instant
local CachedDBFile = "XZNE ScriptHub/Database.json"

task.defer(function()
    task.wait(0.3)  -- Tunggu GUI render terlebih dahulu
    
    -- Buat folder config jika belum ada
    if makefolder and not isfolder("XZNE ScriptHub") then
        makefolder("XZNE ScriptHub")
    end
    
    -- Coba load dari cache lokal dulu (INSTANT jika ada)
    if isfile and isfile(CachedDBFile) then
        local success, content = pcall(function()
            return readfile(CachedDBFile)
        end)
        
        if success and content and #content > 100 then
            local decodeSuccess, decoded = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            
            if decodeSuccess and decoded then
                -- Cache hit! Load instant
                PetDatabase = decoded.Pets or {}
                ItemDatabase = decoded.Items or {}
                DatabaseReady = true
                return  -- Selesai, tidak perlu download
            end
        end
    end
    
    -- Fallback: Download dari GitHub (first run atau cache gagal)
    local Repo = "https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/"
    
    -- Coba JSON dulu (50% lebih cepat dari Lua)
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
            
            -- Save ke cache lokal untuk next time
            if writefile then
                pcall(function() 
                    writefile(CachedDBFile, content) 
                end)
            end
            
            DatabaseReady = true
            return
        end
    end
    
    -- Last resort: Coba format Lua (backward compatibility)
    local luaSuccess, luaResult = pcall(function()
        return loadstring(game:HttpGet(Repo .. "Database.lua"))()
    end)
    
    if luaSuccess and luaResult then
        PetDatabase = luaResult.Pets or {}
        ItemDatabase = luaResult.Items or {}
        DatabaseReady = true
    else
        -- Gagal semua, gunakan database kosong
        PetDatabase = {}
        ItemDatabase = {}
        DatabaseReady = true
    end
end)

-- [5] BUAT WINDOW (Desain Premium Mac-Style)
-- Konfigurasi window utama dengan tema gelap dan efek glassmorphism
local Window = WindUI:CreateWindow({
    Title = "XZNE ScriptHub",
    Icon = "rbxassetid://123378346805284",  -- Icon petir dari Lucide library
    Author = "By. Xzero One",
    Size = UDim2.fromOffset(580, 460),      -- Ukuran optimal
    
    -- Pengaturan Premium
    Transparency = 0.5,       -- Transparansi tinggi untuk efek glassmorphism
    Acrylic = true,           -- Efek glassmorphism (blur)
    Theme = "Dark",           -- Tema gelap
    NewElements = true,       -- Gunakan elemen UI terbaru
    
    -- Tombol Mac Style (titik merah, kuning, hijau seperti macOS)
    ButtonsType = "Mac",
    
    Topbar = {
        Height = 50,
        CornerRadius = UDim.new(0, 8),
        Transparency = 0.1          -- Topbar sangat transparan
    },
    
    Sidebar = {
        Width = 180,
        Transparency = 0.15
    }
})
-- Simpan referensi window untuk cleanup
Controller.Window = Window

-- [6] KONFIGURASITOMBOL OPEN (Minimize State)
-- Tombol untuk membuka GUI kembali setelah di-minimize
Window:EditOpenButton({
    Title = "Open Hub",
    Icon = "rbxassetid://123378346805284",  -- Sama dengan icon window
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- Gradient Indigo ke Purple (sesuai tema)
        Color3.fromRGB(99, 102, 241), 
        Color3.fromRGB(168, 85, 247) 
    ),
    OnlyMobile = false,  -- Aktif di semua platform
    Enabled = true,
    Draggable = true,    -- Bisa di-drag
})

-- Tambah keybind untuk minimize/maximize (RightControl)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        -- Toggle visibility window saat tekan RightControl
        pcall(function()
            if Window and Window.ToggleVisibility then
                Window:ToggleVisibility()
            elseif Window and Window.Visible ~= nil then
                Window.Visible = not Window.Visible
            end
        end)
    end
end)

-- Tabel untuk menyimpan semua elemen UI
local UIElements = {}

-- [TAB UTAMA - Trading]
-- Tab ini berisi semua fitur auto trading
local MainTab = Window:Tab({ 
    Title = "Trading", 
    Icon = "arrow-left-right",  -- Icon swap (logis untuk trading)
    IconColor = Color3.fromRGB(99, 102, 241),  -- Warna Indigo
    IconShape = "Square",  -- Wrapper kotak berwarna
})
MainTab:Space()  -- Spasi untuk UI lebih rapi

-- [TAB SETTINGS]
local SettingsTab = Window:Tab({ 
    Title = "Settings", 
    Icon = "settings",  -- Icon gear
    IconColor = Color3.fromRGB(251, 146, 60),  -- Warna Orange
    IconShape = "Square",
})
SettingsTab:Space()

-- === SECTION: TARGET SELECTION ===
-- Bagian untuk memilih target Pet atau Item yang ingin di-trade
local TargetSection = MainTab:Section({ 
    Title = "Target Selection", 
    Icon = "crosshair"
})

TargetSection:Paragraph({
    Title = "💡 Quick Guide",
    Desc = "Pilih target Pet atau Item di bawah ini. Lalu aktifkan fungsi yang ingin digunakan (Buy/List/Remove)."
})
TargetSection:Space()  -- Pisahkan Guide dari Dropdown

-- DROPDOWN: Target Pet (digunakan oleh SEMUA fungsi)
UIElements.TargetPet = TargetSection:Dropdown({
    Title = "Target Pet", 
    Desc = "🔍 Cari pets...",
    Values = {"— None —"}, Default = 1, SearchBarEnabled = true,
    Flag = "BuyTarget",  -- Bind ke Config
    Callback = function(val) 
        -- Skip jika sedang dalam fase restoring
        if _G.XZNE_Restoring then return end
        
        -- Set target untuk semua fungsi (Buy, List, Remove)
        Controller.Config.BuyTarget = val
        Controller.Config.ListTarget = val
        Controller.Config.RemoveTarget = val
        
        -- Set kategori menjadi Pet
        Controller.Config.BuyCategory = "Pet"
        Controller.Config.ListCategory = "Pet"
        Controller.Config.RemoveCategory = "Pet"
        
        -- Simpan untuk restore UI
        Controller.Config.BuyTargetPet = val
        
        AutoSave()  -- Simpan konfigurasi
    end
})

TargetSection:Space()

-- DROPDOWN: Target Item (digunakan oleh SEMUA fungsi)
UIElements.TargetItem = TargetSection:Dropdown({
    Title = "Target Item", 
    Desc = "🔍 Cari items...",
    Values = {"— None —"}, Default = 1, SearchBarEnabled = true,
    Flag = "BuyTargetItem",  -- Flag terpisah untuk Item dropdown
    Callback = function(val) 
        if _G.XZNE_Restoring then return end
        
        -- Set target untuk semua fungsi
        Controller.Config.BuyTarget = val
        Controller.Config.ListTarget = val
        Controller.Config.RemoveTarget = val
        
        -- Set kategori menjadi Item
        Controller.Config.BuyCategory = "Item"
        Controller.Config.ListCategory = "Item"
        Controller.Config.RemoveCategory = "Item"
        
        -- Simpan untuk restore UI
        Controller.Config.BuyTargetItem = val
        
        AutoSave()
    end
})

TargetSection:Space()

-- SLIDER: Action Delay (delay antar aksi)
UIElements.DelaySlider = TargetSection:Slider({
    Title = "Action Delay",
    Desc = "Interval Delay (0–10s)",
    Step = 0.1,
    Value = {
        Min = 0,
        Max = 10,
        Default = Controller.Config.Speed or 1,  -- Load dari config
    },
    Flag = "Speed",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.Speed = val
        AutoSave()
    end
})

TargetSection:Space()

-- === SECTION: AUTO BUY (SNIPER) ===
-- Fitur untuk otomatis membeli item/pet dengan harga murah
local BuySection = MainTab:Section({ Title = "Auto Buy (Sniper)", Icon = "shopping-bag" })

-- INPUT: Harga maksimal untuk membeli
UIElements.MaxPrice = BuySection:Input({
    Title = "Max Price", 
    Desc = "Harga maksimal untuk membeli", 
    Default = tostring(Controller.Config.MaxPrice or 5), 
    Numeric = true,
    Flag = "MaxPrice",
    Callback = function(txt) 
        if _G.XZNE_Restoring then return end
        Controller.Config.MaxPrice = tonumber(txt) or 5
        AutoSave() 
    end
})

-- TOGGLE: Aktifkan Auto Buy
UIElements.AutoBuy = BuySection:Toggle({
    Title = "Enable Auto Buy", 
    Desc = "Snipe target yang dipilih", 
    Default = Controller.Config.AutoBuy or false,
    Flag = "AutoBuy",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.AutoBuy = val
        AutoSave()
    end
})

BuySection:Divider()  -- Garis pemisah

-- === SECTION: AUTO LIST ===
-- Fitur untuk otomatis list item/pet ke booth
local ListSection = MainTab:Section({ Title = "Auto List", Icon = "tag" })

-- INPUT: Harga jual per item
UIElements.Price = ListSection:Input({
    Title = "Listing Price", 
    Desc = "Harga per item", 
    Default = tostring(Controller.Config.Price or 5), 
    Numeric = true,
    Flag = "Price",
    Callback = function(txt) 
        if _G.XZNE_Restoring then return end
        Controller.Config.Price = tonumber(txt) or 5
        AutoSave() 
    end
})

-- TOGGLE: Aktifkan Auto List
UIElements.AutoList = ListSection:Toggle({
    Title = "Enable Auto List", 
    Desc = "List target yang dipilih", 
    Default = Controller.Config.AutoList or false,
    Flag = "AutoList",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.AutoList = val
 AutoSave()
    end
})

ListSection:Divider()

-- === SECTION: AUTO REMOVE ===
-- Fitur untuk otomatis hapus listing dari booth
local RemoveSection = MainTab:Section({ Title = "Auto Remove", Icon = "trash-2" })

-- TOGGLE: Aktifkan Auto Remove
UIElements.AutoClear = RemoveSection:Toggle({
    Title = "Enable Auto Remove", 
    Desc = "Hapus target yang dipilih", 
    Default = Controller.Config.AutoClear or false,
    Flag = "AutoClear",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.AutoClear = val
        AutoSave()
    end
})

RemoveSection:Divider()

-- === SECTION: BOOTH CONTROL ===
-- Control booth (claim/unclaim)
local BoothSection = MainTab:Section({ Title = "Booth Control", Icon = "store" })

-- TOGGLE: Auto Claim Booth
UIElements.AutoClaim = BoothSection:Toggle({
    Title = "Auto Claim Booth", 
    Desc = "Otomatis claim booth", 
    Default = Controller.Config.AutoClaim or false,
    Flag = "AutoClaim",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.AutoClaim = val
        AutoSave()
    end
})

-- BUTTON: Unclaim Booth
BoothSection:Button({
    Title = "Unclaim Booth", 
    Desc = "Lepas kepemilikan booth", 
    Icon = "log-out",
    Callback = function() Controller.UnclaimBooth() end
})

-- [POPULASI GUI - 2 DROPDOWN YANG SHARED]
-- Isi dropdown dengan data dari database setelah database selesai dimuat
task.defer(function()
    -- Tunggu database siap
    while not DatabaseReady do task.wait(0.1) end
    task.wait(1)  -- Delay kecil untuk stabilitas GUI
    
    -- Fungsi helper untuk update dropdown dengan aman
    local function SafeUpdate(element, db)
        if element then
            -- Tambah entry database setelah "— None —"
            local values = {"— None —"}
            for _, item in ipairs(db) do
                table.insert(values, item)
            end
            element.Values = values
            element.Desc = "🔍 Cari "..#db.." items..."
            -- Refresh dropdown display
            if element.Refresh then pcall(function() element:Refresh(values) end) end
        end
    end
    
    -- Populate hanya 2 dropdown (shared untuk semua fungsi)
    SafeUpdate(UIElements.TargetPet, PetDatabase)
    task.wait(0.05)
    SafeUpdate(UIElements.TargetItem, ItemDatabase)
end)

-- [SECTION STATS - Di Tab Settings]
-- Menampilkan statistik performa script
local StatsSection = SettingsTab:Section({ Title = "📊 Statistik Sesi" })
local StatsParagraph = StatsSection:Paragraph({
    Title = "Metrik Performa",
    Desc = "Sniped: 0 | Listed: 0 | Removed: 0 | Uptime: 0m"
})

-- Updater statistik (berjalan setiap 10 detik)
task.spawn(function()
    local startTime = tick()  -- Catat waktu mulai
    while true do
        task.wait(10)  -- Update setiap 10 detik
        local uptime = math.floor((tick() - startTime) / 60)  -- Hitung uptime dalam menit
        pcall(function()
            if StatsParagraph and StatsParagraph.SetDesc then
                local s = Controller.Stats
                -- Format string statistik
                StatsParagraph:SetDesc(string.format("Sniped: %d | Listed: %d | Removed: %d | Uptime: %dm", 
                    s.SnipeCount, s.ListedCount, s.RemovedCount, uptime))
            end
        end)
    end
end)

StatsSection:Divider()

-- === SECTION: AUTO REJOIN ===
-- Fitur untuk rejoin server (manual button)
local RejoinSection = SettingsTab:Section({ 
    Title = "Auto Rejoin", 
    Icon = "refresh-cw" 
})

RejoinSection:Paragraph({
    Title = "Info",
    Desc = "Rejoin server dengan 1 klik. Bisa bypass private server untuk join ke public server."
})

-- TOGGLE: Bypass Private Server
UIElements.RejoinBypassPrivate = RejoinSection:Toggle({
    Title = "Bypass Private Server",
    Desc = "Jika ON: rejoin ke public | Jika OFF: rejoin ke server sama",
    Default = Controller.Config.RejoinBypassPrivate or true,
    Flag = "RejoinBypassPrivate",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.RejoinBypassPrivate = val
        AutoSave()
    end
})

-- BUTTON: Rejoin Now
RejoinSection:Button({
    Title = "Rejoin Now!",
    Desc = "Klik untuk rejoin server sekarang",
    Icon = "rotate-cw",
    Callback = function()
        Controller.DoRejoin()
    end
})

RejoinSection:Divider()

-- === SECTION: SMART AUTO HOP ===
-- Fitur untuk server hopping otomatis
local HopSection = SettingsTab:Section({ 
    Title = "Smart Auto Hop", 
    Icon = "globe" 
})

HopSection:Paragraph({
    Title = "Info",
    Desc = "Server hopping cerdas: Pilih server sehat, hindari server yang pernah dikunjungi."
})

-- TOGGLE: Enable Auto Hop
UIElements.AutoHop = HopSection:Toggle({
    Title = "Enable Auto Hop",
    Desc = "Hop otomatis setiap interval waktu",
    Default = Controller.Config.AutoHop or false,
    Flag = "AutoHop",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.AutoHop = val
        AutoSave()
    end
})

-- SLIDER: Hop Interval
UIElements.HopInterval = HopSection:Slider({
    Title = "Hop Interval",
    Desc = "Waktu antar hop (60-600 detik)",
    Step = 30,
    Value = {
        Min = 60,
        Max = 600,
        Default = Controller.Config.HopInterval or 300,
    },
    Flag = "HopInterval",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.HopInterval = val
        AutoSave()
    end
})

-- SLIDER: Min Players
UIElements.HopMinPlayers = HopSection:Slider({
    Title = "Min Players",
    Desc = "Server minimal player count",
    Step = 1,
    Value = {
        Min = 1,
        Max = 30,
        Default = Controller.Config.HopMinPlayers or 5,
    },
    Flag = "HopMinPlayers",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.HopMinPlayers = val
        AutoSave()
    end
})

-- SLIDER: Max Players
UIElements.HopMaxPlayers = HopSection:Slider({
    Title = "Max Players",
    Desc = "Server maksimal player count",
    Step = 1,
    Value = {
        Min = 10,
        Max = 50,
        Default = Controller.Config.HopMaxPlayers or 25,
    },
    Flag = "HopMaxPlayers",
    Callback = function(val)
        if _G.XZNE_Restoring then return end
        Controller.Config.HopMaxPlayers = val
        AutoSave()
    end
})

-- BUTTON: Hop Now
HopSection:Button({
    Title = "Hop Now!",
    Desc = "Force hop ke server terbaik sekarang",
    Icon = "zap",
    Callback = function()
        Controller.SmartHop()
    end
})

-- Simpan referensi window dan notifikasi user
Controller.Window = Window
WindUI:Notify({
    Title = "XZNE ScriptHub Loaded",
    Content = "Selamat datang, " .. game.Players.LocalPlayer.Name,
    Icon = "check-circle-2",
    Duration = 5
})


-- [7] SINKRONISASI VISUAL EKSPLISIT
-- Paksa UI untuk match dengan Config setelah dibuat
-- Ini memastikan semua toggle, slider, dan dropdown menampilkan nilai yang benar
task.defer(function()
    _G.XZNE_Restoring = true  -- KUNCI (mencegah autosave saat sync)
    
    -- Tunggu UI fully rendered DAN database siap (untuk Dropdown)
    task.wait(1.5) 
    
    -- Timeout untuk menunggu database
    local Timeout = 0
    while not DatabaseReady and Timeout < 5 do
        task.wait(0.5)
        Timeout = Timeout + 0.5
    end
    
    local C = Controller.Config
    
    -- Fungsi helper untuk sync elemen UI dengan aman
    local function Sync(element, value, elementType)
        if element and value ~= nil then 
            pcall(function()
                if elementType == "Dropdown" and element.Select then
                    -- Dropdown menggunakan metode Select
                    element:Select(value)
                    
                elseif elementType == "Input" then
                    -- Input: Coba SetText -> SetValue -> Set (fallback cascade)
                    local sVal = tostring(value)
                    
                    if element.SetText then 
                        element:SetText(sVal)
                    elseif element.SetValue then 
                        element:SetValue(sVal)
                    elseif element.Set then 
                        element:Set(sVal)
                    end
                    
                else  -- Toggle, Slider menggunakan :Set()
                    if element.Set then element:Set(value) end
                end
            end)
        end
    end

    -- Sync semua Toggle
    Sync(UIElements.AutoBuy, C.AutoBuy, "Toggle")
    Sync(UIElements.AutoList, C.AutoList, "Toggle")
    Sync(UIElements.AutoClear, C.AutoClear, "Toggle")
    Sync(UIElements.AutoClaim, C.AutoClaim, "Toggle")
    
    -- Sync NEW toggles (Auto Hop & Rejoin)
    Sync(UIElements.AutoHop, C.AutoHop, "Toggle")
    Sync(UIElements.RejoinBypassPrivate, C.RejoinBypassPrivate, "Toggle")
    
    -- Sync Slider & Input
    Sync(UIElements.DelaySlider, C.Speed, "Slider")
    Sync(UIElements.MaxPrice, C.MaxPrice, "Input")
    Sync(UIElements.Price, C.Price, "Input")
    
    -- Sync NEW sliders (Auto Hop params)
    Sync(UIElements.HopInterval, C.HopInterval, "Slider")
    Sync(UIElements.HopMinPlayers, C.HopMinPlayers, "Slider")
    Sync(UIElements.HopMaxPlayers, C.HopMaxPlayers, "Slider")
    
    -- Sync Dropdown (INDEPENDENT - Bisa simultanlam)
    if C.BuyTargetPet and C.BuyTargetPet ~= "— None —" then
         Sync(UIElements.TargetPet, C.BuyTargetPet, "Dropdown")
    end
    
    if C.BuyTargetItem and C.BuyTargetItem ~= "— None —" then
         Sync(UIElements.TargetItem, C.BuyTargetItem, "Dropdown")
    end
    
    task.wait(0.5)
    _G.XZNE_Restoring = false  -- UNLOCK (autosave sekarang aktif)
    
    -- UPDATE: Force update cache di Main.lua dengan nilai yang baru di-sync
    pcall(function() Controller.UpdateCache() end)
end)

-- Return success ke Loader
return true
