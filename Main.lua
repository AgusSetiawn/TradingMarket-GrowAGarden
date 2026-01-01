--[[ 
    💠 XZNE SCRIPTHUB v0.0.01 [Beta] - LOGIC CORE
    
    🔧 FITUR:
    - Auto Buy (Sniper) - Otomatis membeli item/pet dengan harga murah
    - Pet Support (DataService) - Mendukung transaksi pet
    - Smart List & Clear - List dan hapus item/pet secara cerdas
    - Auto Claim - Klaim booth secara otomatis
    - Performance Optimizations - Optimasi performa dengan caching
]]

-- [1] SERVICES & OPTIMASI PERFORMA
-- Cache fungsi global untuk operasi 3-5x lebih cepat
local string_lower = string.lower       -- Fungsi lowercase string
local string_find = string.find         -- Fungsi pencarian string
local string_match = string.match       -- Fungsi pattern matching
local tostring = tostring               -- Konversi ke string
local tonumber = tonumber               -- Konversi ke angka
local math_floor = math.floor           -- Pembulatan kebawah
local math_max = math.max               -- Nilai maksimum
local pairs = pairs                     -- Iterator tabel
local tick = tick                       -- Waktu sistem

-- Ambil service yang dibutuhkan dari Roblox
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local LocalUserId = LocalPlayer.UserId
local MyPlayerKey = "Player_" .. LocalUserId  -- Kunci pemain di database

-- [2] SETUP CONTROLLER (Terlindungi dari eksekusi ganda)
if _G.XZNE_Controller then
    -- Script sudah berjalan, bersihkan instance lama terlebih dahulu
    
    -- Hentikan controller lama segera
    _G.XZNE_Controller.Config.Running = false
    
    -- Hancurkan window lama jika ada
    if _G.XZNE_Controller.Window and _G.XZNE_Controller.Window.Destroy then
        pcall(function() 
            _G.XZNE_Controller.Window:Destroy() 
        end)
    end
    
    -- Hapus referensi global
    _G.XZNE_Controller = nil
    
    -- Tunggu proses cleanup selesai
    task.wait(0.8)
end

-- Buat Controller baru (objek utama yang mengelola semua logika)
_G.XZNE_Controller = {
    Config = {
        -- Pengaturan Global
        Running = true,              -- Status script (aktif/nonaktif)
        AntiAFK = false,             -- Toggle fitur anti afk
        Speed = 1.0,                 -- Delay global untuk semua aksi (detik)
        
        -- Pengaturan Auto Buy (Sniper)
        AutoBuy = false,             -- Toggle fitur auto buy
        BuyCategory = "Item",        -- Kategori target: "Item" atau "Pet"
        BuyTarget = "Bone Blossom",  -- Nama item/pet yang ingin dibeli
        MaxPrice = 5,                -- Harga maksimal untuk membeli
        
        -- Pengaturan Auto List
        AutoList = false,            -- Toggle fitur auto list
        ListCategory = "Item",       -- Kategori yang akan di-list
        ListTarget = "Bone Blossom", -- Nama item/pet yang akan di-list
        Price = 5,                   -- Harga jual per item
        ListDelay = 2.0,             -- Delay khusus untuk listing (opsional)
        
        -- Pengaturan Auto Clear (Remove)
        AutoClear = false,           -- Toggle fitur auto clear
        RemoveCategory = "Item",     -- Kategori yang akan dihapus
        RemoveTarget = "Bone Blossom", -- Nama item/pet yang akan dihapus
        DeleteAll = false,           -- Jika true, hapus semua listing
        
        -- Pengaturan Auto Claim
        AutoClaim = false,           -- Toggle fitur auto claim booth
        
        -- Pengaturan Anti AFK (NEW)
        AntiAFK = false,             -- Toggle fitur anti afk
        
        -- Pengaturan Auto Hop (NEW - Fitur Server Hopping)
        AutoHop = false,             -- Toggle fitur auto hop
        HopInterval = 5,             -- Interval hop dalam MENIT (default 5 menit)
    },
    Stats = {
        ListedCount = 0,             -- Jumlah item yang berhasil di-list
        LastListTime = 0,            -- Waktu terakhir listing
        SnipeCount = 0,              -- Jumlah item yang berhasil di-snipe
        RemovedCount = 0             -- Jumlah item yang dihapus
    },
    Window = nil                     -- Referensi ke window GUI (diisi oleh Gui.lua)
}

-- Shortcut untuk akses cepat
local Controller = _G.XZNE_Controller
local Config = Controller.Config
local Stats = Controller.Stats
local ListingDebounce = {}  -- Mencegah item yang sama di-list berulang kali
local CachedTargets = { Buy = "", List = "", Remove = "" }  -- Cache nama target (lowercase) untuk performa

-- [CATATAN CONFIG]
-- Konfigurasi sekarang dikelola oleh Gui.lua (menggunakan sistem WindUI)
-- File ini hanya menyimpan state yang digunakan oleh logika


-- [3] REMOTES & HOOKS (Koneksi ke server game)
-- Ambil remote events untuk komunikasi dengan server
local TradeEvents = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("TradeEvents")
local BoothsRemote = TradeEvents:WaitForChild("Booths")
local CreateListingRemote = BoothsRemote:WaitForChild("CreateListing")    -- Untuk membuat listing
local ClaimBoothRemote = BoothsRemote:WaitForChild("ClaimBooth")          -- Untuk claim booth
local RemoveBoothRemote = BoothsRemote:WaitForChild("RemoveBooth")        -- Untuk unclaim booth
local RemoveListingRemote = BoothsRemote:WaitForChild("RemoveListing")    -- Untuk hapus listing
local BuyListingRemote = BoothsRemote:WaitForChild("BuyListing")          -- Untuk membeli listing

-- Variabel untuk hooks ke data game
local BoothsReceiver = nil       -- Hook untuk data booth (metode utama)
local DataService = nil          -- Hook untuk data pet
local TradeBoothsData = nil      -- Fallback jika BoothsReceiver gagal

-- Muat hooks secara asynchronous (tidak menghalangi GUI)
task.defer(function()
    pcall(function()
        -- Tunggu folder Modules tersedia (timeout 10 detik)
        local RepModules = ReplicatedStorage:WaitForChild("Modules", 10)
        if RepModules then
            -- Coba hook ke BoothsReceiver (untuk data booth)
            local ReplicationReciever = require(RepModules:WaitForChild("ReplicationReciever", 5))
            if ReplicationReciever then
                BoothsReceiver = ReplicationReciever.new("Booths")
            end
            
            -- Coba hook ke DataService (untuk data pet)
            DataService = require(RepModules:WaitForChild("DataService", 5))
        end
    end)
    
    -- Jika BoothsReceiver gagal, coba metode fallback
    if not BoothsReceiver then
        pcall(function()
            TradeBoothsData = require(ReplicatedStorage.Data.TradeBoothsData)
        end)
    end
end)

-- [4] FUNGSI HELPER & OPTIMASI

-- Fungsi untuk update cache string target (dipanggil saat Config berubah)
-- Fungsi untuk update cache string target (dipanggil saat Config berubah)
-- Supports String (Single) or Table (Multi)
function Controller.UpdateCache()
    -- Helper untuk process target (convert ke lowercase table/string)
    local function ProcessTarget(val)
        if type(val) == "table" then
            local t = {}
            for _, v in pairs(val) do 
                if v ~= "— None —" then table.insert(t, string.lower(v)) end 
            end
            return t -- Return table of strings
        else
            local s = string.lower(tostring(val or ""))
            return (s == "— none —") and "" or s
        end
    end

    -- Cache terpisah untuk Pet dan Item (mendukung dual target & multi-choice)
    CachedTargets.BuyPet = ProcessTarget(Config.BuyTargetPet)
    CachedTargets.BuyItem = ProcessTarget(Config.BuyTargetItem)
    
    -- Legacy/Fallback keys (jika masih dipakai logika lama)
    CachedTargets.Buy = CachedTargets.BuyPet -- Pointer reference
    CachedTargets.List = CachedTargets.BuyPet 
    CachedTargets.Remove = CachedTargets.BuyPet
end
-- Inisialisasi cache pertama kali
Controller.UpdateCache()

-- [PERFORMA] Cache untuk mencegah operasi berulang
local BoothCache = { booth = nil, time = 0 }        -- Cache untuk booth pemain
local DataCache = { data = nil, time = 0 }          -- Cache untuk data booth
local PlayerLookupCache = {}                         -- Cache untuk lookup player

-- [PERFORMA] Pembersihan debounce otomatis (berjalan setiap 30 detik)
-- Membersihkan data lama untuk mencegah memory leak
task.defer(function()
    while true do
        task.wait(30)  -- Tunggu 30 detik
        local currentTime = tick()
        
        -- Bersihkan ListingDebounce (hanya jika ada isinya)
        if next(ListingDebounce) then
            for uuid, timestamp in pairs(ListingDebounce) do
                -- Hapus entry yang sudah lebih dari 10 detik
                if currentTime - timestamp > 10 then
                    ListingDebounce[uuid] = nil
                end
            end
        end
        
        -- Bersihkan PlayerLookupCache (hanya jika ada isinya)
        if next(PlayerLookupCache) then
            for userId, cacheEntry in pairs(PlayerLookupCache) do
                -- Hapus entry yang sudah lebih dari 5 detik
                if currentTime - cacheEntry.time > 5 then
                    PlayerLookupCache[userId] = nil
                end
            end
        end
    end
end)

-- Fungsi untuk mengambil data booths dari game (dengan caching)
local function GetBoothsData()
    local currentTime = tick()
    -- Gunakan cache jika masih fresh (< 1 detik) untuk menghindari panggilan berulang
    if DataCache.data and (currentTime - DataCache.time < 1) then
        return DataCache.data
    end
    
    -- Ambil data dari hook yang tersedia
    local data = nil
    if BoothsReceiver then 
        data = BoothsReceiver:GetData()
    elseif TradeBoothsData then 
        data = TradeBoothsData:GetData() 
    end
    
    -- Update cache
    DataCache.data = data
    DataCache.time = currentTime
    return data
end

-- Fungsi untuk mencari booth milik pemain (dengan caching)
local function GetMyBooth()
    local currentTime = tick()
    -- Gunakan cache jika masih fresh (< 2 detik)
    if BoothCache.booth and (currentTime - BoothCache.time < 2) then
        return BoothCache.booth
    end
    
    -- Cari booth di Workspace
    local folder = Workspace:FindFirstChild("TradeWorld")
    if folder then folder = folder:FindFirstChild("Booths") end
    
    -- Loop semua booth untuk mencari yang dimiliki pemain
    for _, b in pairs(folder and folder:GetChildren() or {}) do
        local oid = b:GetAttribute("OwnerId") or b:GetAttribute("UserId")
        if not oid then 
            local v = b:FindFirstChild("OwnerId")
            if v then oid = v.Value end
        end
        
        -- Cek apakah booth ini milik pemain lokal
        if tostring(oid) == tostring(LocalUserId) then
            BoothCache.booth = b
            BoothCache.time = currentTime
            return b  -- Booth ditemukan
        end
    end
    
    -- Booth tidak ditemukan
    BoothCache.booth = nil
    BoothCache.time = currentTime
    return nil
end

-- Fungsi untuk mencari player berdasarkan UserId (dengan caching)
local function GetCachedPlayer(userId)
    local currentTime = tick()
    local cached = PlayerLookupCache[userId]
    
    -- Gunakan cache jika masih fresh (< 5 detik)
    if cached and (currentTime - cached.time < 5) then
        return cached.player
    end
    
    -- Cari player dan simpan di cache
    local player = Players:GetPlayerByUserId(userId)
    PlayerLookupCache[userId] = { player = player, time = currentTime }
    return player
end

-- [5] LOGIKA INTI

-- [FUNGSI HELPER] Match Target (Multi/Single)
-- Mengecek apakah 'name' cocok dengan 'target' (String atau Table)
local function CheckTargetMatch(name, target)
    if not name or not target then return false end
    if target == "" or (type(target) == "table" and #target == 0) then return false end
    
    local nameLower = string_lower(name)
    
    if type(target) == "table" then
        -- Multi-target search
        for _, tVal in pairs(target) do
            if string_find(nameLower, tVal) then return true end
        end
        return false
    else
        -- Single-target search
        return string_find(nameLower, target)
    end
end

-- >> FUNGSI AUTO BUY (SNIPER)
-- Otomatis membeli item/pet yang sesuai target dengan harga dibawah MaxPrice
local function RunAutoBuy()
    -- Keluar jika fitur tidak aktif
    if not Config.AutoBuy then return end
    
    -- Ambil data booths dari game
    local data = GetBoothsData()
    if not data then return end
    
    local maxPrice = Config.MaxPrice
    
    -- Loop semua pemain yang punya booth
    for playerKey, playerData in pairs(data.Players) do
        -- Hentikan jika script dimatikan
        if not Config.Running then break end
        
        -- Skip booth milik sendiri, hanya cek booth pemain lain
        if playerKey ~= MyPlayerKey and playerData.Listings then
            -- Loop semua listing di booth pemain ini
            for listingUUID, listingInfo in pairs(playerData.Listings) do
                -- Cek ulang toggle (bisa berubah saat loop)
                if not Config.AutoBuy then break end
                
                -- OPTIMASI: Cek harga terlebih dahulu (paling cepat untuk filter)
                if listingInfo.Price <= maxPrice then
                    -- Cek apakah tipe item cocok dengan target
                    local targetMatch = false
                    local listType = listingInfo.ItemType
                    
                    -- Jika ini Pet dan kita punya target Pet, cocok
                    local buyPet = CachedTargets.BuyPet
                    local buyItem = CachedTargets.BuyItem
                    
                    if listType == "Pet" and (type(buyPet) == "table" and #buyPet > 0 or buyPet ~= "") then 
                        targetMatch = true 
                    -- Jika ini Item dan kita punya target Item, cocok
                    elseif listType == "Holdable" and (type(buyItem) == "table" and #buyItem > 0 or buyItem ~= "") then 
                        targetMatch = true
                    end
                    
                    -- Jika tipe cocok, lanjut cek nama
                    if targetMatch then
                        local itemData = playerData.Items[listingInfo.ItemId]
                        if itemData then
                            -- Ambil nama asli item/pet
                            local realName = itemData.Name or itemData.ItemName or itemData.PetType or (itemData.ItemData and itemData.ItemData.ItemName) or ""
                            local lowerName = string_lower(tostring(realName))
                            local isMatch = false
                            
                            -- Cek nama spesifik berdasarkan tipe
                            if listingInfo.ItemType == "Pet" then
                                -- Cocokkan dengan target Pet (Via Helper)
                                if CheckTargetMatch(realName, CachedTargets.BuyPet) then 
                                    isMatch = true 
                                end
                            elseif listingInfo.ItemType == "Holdable" then
                                -- Cocokkan dengan target Item
                                if CheckTargetMatch(realName, CachedTargets.BuyItem) then 
                                    isMatch = true 
                                end
                            end
                            
                            -- Jika nama cocok, beli item ini!
                            if isMatch then
                                -- Ambil owner dari playerKey
                                local ownerId = tonumber(string_match(playerKey, "Player_(%d+)"))
                                local owner = GetCachedPlayer(ownerId)
                                
                                if owner then
                                    -- BUG FIX: Hapus duplikasi pemanggilan
                                    pcall(function() 
                                        BuyListingRemote:InvokeServer(owner, listingUUID) 
                                    end)
                                    Stats.SnipeCount = Stats.SnipeCount + 1
                                    task.wait(Config.Speed)  -- Tunggu sesuai delay setting
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- >> FUNGSI AUTO LIST (Item & Pet)
-- Otomatis list item/pet yang ada di inventory/backpack ke booth
local function RunAutoList()
    -- Keluar jika fitur tidak aktif
    if not Config.AutoList then return end
    
    -- Ambil daftar item yang sudah terlisting (untuk hindari duplikasi)
    local data = GetBoothsData()
    local myData = data and data.Players[MyPlayerKey]
    local listedUUIDs = {}  -- Tabel untuk track UUID yang sudah di-list
    local listingCount = 0  -- Counter jumlah listing
    
    if myData and myData.Listings then
        for _, v in pairs(myData.Listings) do 
            listedUUIDs[v.ItemId] = true 
            listingCount = listingCount + 1
        end
    end
    
    -- [SMART FEATURE] Capacity Limit Detection
    -- Jika booth sudah penuh (50 item), berhenti sementara (anti-spam)
    if listingCount >= 50 then
        -- Optional: Print debug info every 5 seconds
        -- if tick() % 5 < 0.1 then print("⏸️ [XZNE] Booth Full (50/50). Auto List Paused.") end
        return 
    end
    
    local price = Config.Price
    local currentTime = tick()
    
    -- LOGIKA GANDA: Cek Pet dan Item secara berurutan
    
    -- [1] LISTING PET
    -- BUG FIX: Gunakan Config.ListCategory, bukan CachedTargets.List
    local listPetTarget = CachedTargets.BuyPet
    local hasPetTarget = (type(listPetTarget) == "table" and #listPetTarget > 0) or (type(listPetTarget) == "string" and listPetTarget ~= "")

    if (Config.ListCategory == "Pet" or hasPetTarget) and hasPetTarget then
        -- Logic Check Passed
            -- Pet Listing membutuhkan DataService
            local playerData = DataService and DataService:GetData()
            if playerData and playerData.PetsData and playerData.PetsData.PetInventory then
                -- Loop semua pet di inventory
                for petUUID, petData in pairs(playerData.PetsData.PetInventory.Data) do
                    -- Hentikan jika script dimatikan atau toggle dimatikan
                    if not Config.Running or not Config.AutoList then break end
                    
                    -- Cek apakah pet ini belum terlisting dan tidak dalam debounce
                    if not listedUUIDs[petUUID] and (not ListingDebounce[petUUID] or currentTime - ListingDebounce[petUUID] > 5) then
                        local petName = petData.PetType or petData.Name
                        -- Cek apakah nama pet cocok dengan target
                        if petName and CheckTargetMatch(petName, listPetTarget) then
                            -- List pet ini
                            pcall(function() 
                                CreateListingRemote:InvokeServer("Pet", petUUID, price) 
                            end)
                            
                            -- Update counter manual (biar ga overshoot 50 di loop yang sama)
                            listingCount = listingCount + 1
                            if listingCount >= 50 then return end -- Cutoff immediate
                            ListingDebounce[petUUID] = currentTime
                            Stats.ListedCount = Stats.ListedCount + 1
                            task.wait(Config.Speed)
                        end
                    end
                end
            end
        end


    -- [2] LISTING ITEM
    local listItemTarget = CachedTargets.BuyItem
    local hasItemTarget = (type(listItemTarget) == "table" and #listItemTarget > 0) or (type(listItemTarget) == "string" and listItemTarget ~= "")
    
    if (Config.ListCategory == "Item" or hasItemTarget) and hasItemTarget then
        -- Logic Check Passed
            -- Item Listing dari Backpack
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if backpack then
                -- Loop semua item di backpack
                for _, item in pairs(backpack:GetChildren()) do
                    -- BUG FIX: Hapus duplikasi check toggle (cukup satu)
                    if not Config.Running or not Config.AutoList then break end
                    
                    if item:IsA("Tool") then
                        -- Ambil nama asli dan UUID dari attribute
                        local realName = item:GetAttribute("f")
                        local uuid = item:GetAttribute("c")
                        
                        -- Cek apakah item ini belum terlisting dan tidak dalam debounce
                        if realName and uuid and not listedUUIDs[uuid] and (not ListingDebounce[uuid] or currentTime - ListingDebounce[uuid] > 5) then
                            -- Cek apakah nama item cocok dengan target
                            if CheckTargetMatch(realName, listItemTarget) then
                                -- List item ini
                                pcall(function() 
                                    CreateListingRemote:InvokeServer("Holdable", uuid, price) 
                                end)
                                
                                listingCount = listingCount + 1
                                if listingCount >= 50 then return end
                                ListingDebounce[uuid] = currentTime
                                Stats.ListedCount = Stats.ListedCount + 1
                                task.wait(Config.Speed)
                            end
                        end
                    end
                end
            end
        end

end

-- >> FUNGSI AUTO CLEAR (Smart Remove)
-- Otomatis hapus listing yang sesuai target dari booth
local function RunAutoClear()
    -- Keluar jika fitur tidak aktif
    if not Config.AutoClear then return end
    
    -- Ambil target Pet dan Item
    local targetPet = CachedTargets.BuyPet
    local targetItem = CachedTargets.BuyItem
    
    local hasPet = (type(targetPet) == "table" and #targetPet > 0) or targetPet ~= ""
    local hasItem = (type(targetItem) == "table" and #targetItem > 0) or targetItem ~= ""
    
    -- Jika tidak DeleteAll dan tidak ada target, keluar
    if not Config.DeleteAll and not hasPet and not hasItem then 
        return 
    end
    
    -- Ambil data booth milik sendiri
    local data = GetBoothsData()
    if not data then return end
    local myData = data.Players[MyPlayerKey]
    
    -- Loop semua listing milik sendiri
    if myData and myData.Listings then
        for listingUUID, listingInfo in pairs(myData.Listings) do
            -- Hentikan jika script dimatikan atau toggle dimatikan
            if not Config.Running or not Config.AutoClear then break end
            
            -- Filter berdasarkan kategori (mendukung multi-target)
            if Config.DeleteAll or (listingInfo.ItemType == "Pet" and targetLowerPet ~= "") or (listingInfo.ItemType == "Holdable" and targetLowerItem ~= "") then
                local itemId = listingInfo.ItemId
                local itemData = myData.Items[itemId]
                
                if itemData then
                    -- Ambil nama asli item/pet
                    local realName = itemData.Name or itemData.ItemName or itemData.PetType or (itemData.ItemData and itemData.ItemData.ItemName) or ""
                    local lowerName = string_lower(tostring(realName))
                    local shouldRemove = false
                    
                    -- Tentukan apakah listing ini harus dihapus
                    if Config.DeleteAll then 
                        -- Mode DeleteAll: hapus semua
                        shouldRemove = true
                    elseif listingInfo.ItemType == "Pet" and hasPet and CheckTargetMatch(realName, targetPet) then 
                        -- Hapus Pet yang cocok target
                        shouldRemove = true
                    elseif listingInfo.ItemType == "Holdable" and hasItem and CheckTargetMatch(realName, targetItem) then 
                        -- Hapus Item yang cocok target
                        shouldRemove = true
                    end
                    
                    -- Jika harus dihapus, hapus listing ini
                    if shouldRemove then
                        pcall(function() 
                            RemoveListingRemote:InvokeServer(listingUUID) 
                        end)
                        Stats.RemovedCount = Stats.RemovedCount + 1
                        task.wait(Config.Speed)
                    end
                end
            end
        end
    end
end

-- >> FUNGSI AUTO CLAIM (Improved & Smart)
-- Otomatis cari, teleport, dan claim booth kosong
-- >> FUNGSI AUTO CLAIM (Improved & Smart)
-- Otomatis cari, teleport, dan claim booth kosong
local function RunAutoClaim()
    -- Keluar jika fitur tidak aktif
    if not Config.AutoClaim then return end
    
    -- [STRICT CHECK] Jika sudah punya booth, pause (return)
    if GetMyBooth() then return end
    
    -- Gunakan Module Game Internal untuk Teleport
    local success, err = pcall(function()
        local TradeBoothController = require(ReplicatedStorage.Modules.TradeBoothControllers.TradeBoothController)
        TradeBoothController:TeleportToBooth()
    end)
    
    if not success then return end

    -- [SPAM CLAIM STRATEGY]
    local StartTime = tick()
    local MaxDuration = 4.0 -- Naikkan sedikit durasi (4 detik)
    
    while (tick() - StartTime) < MaxDuration do
        if GetMyBooth() then break end
        
        local char = LocalPlayer.Character
        if char and char.PrimaryPart then
            local myPos = char.PrimaryPart.Position
            local nearestBooth = nil
            local minDst = 20
            
            local folder = Workspace:FindFirstChild("TradeWorld") and Workspace.TradeWorld:FindFirstChild("Booths")
            if folder then
                for _, booth in pairs(folder:GetChildren()) do
                    -- Gunakan PVInstance:GetPivot() agar lebih aman daripada PrimaryPart
                    local boothPos = booth:GetPivot().Position
                    local dist = (boothPos - myPos).Magnitude
                    
                    if dist < minDst then
                        minDst = dist
                        nearestBooth = booth
                    end
                end
            end
            
            -- Attempt Claim
            if nearestBooth then
                -- Cek status ownership (Opsional: Kita bisa paksa claim jika glitch)
                local oid = nearestBooth:GetAttribute("OwnerId") or nearestBooth:GetAttribute("UserId")
                
                -- Fallback cari Value Object jika Attribute tidak ada
                if not oid then 
                    local v = nearestBooth:FindFirstChild("OwnerId")
                    if v then oid = v.Value end
                end
                
                -- Hanya claim jika kosong (nil/0/empty) ATAU jika kita percaya diri
                if not oid or oid == 0 or oid == "" then
                    pcall(function() 
                        ClaimBoothRemote:FireServer(nearestBooth) 
                    end)
                end
            end
        end
        task.wait(0.1) 
    end
    
    task.wait(2)
end

-- [6] API EXPORTS (Fungsi yang bisa dipanggil dari GUI)

-- Fungsi untuk unclaim booth (digunakan oleh tombol di GUI)
function Controller.UnclaimBooth()
    pcall(function() 
        RemoveBoothRemote:FireServer() 
    end)
end

-- Fungsi untuk request update cache (dipanggil saat config berubah)
function Controller.RequestUpdate()
    Controller.UpdateCache()
end

-- [NEW FEATURE] SERVER HOPPING & REJOIN SYSTEM
-- Service untuk teleportasi antar server
local TeleportService = game:GetService("TeleportService")

-- Tracking server yang sudah dikunjungi (agar tidak hop ke server yang sama)
local VisitedServers = {}
local VisitedServersFile = "XZNE ScriptHub/VisitedServers.json"
local LastHopTime = 0  -- Waktu terakhir hop

-- Fungsi untuk load daftar server yang sudah dikunjungi dari file
local function LoadVisitedServers()
    if isfile and isfile(VisitedServersFile) then
        local success, content = pcall(readfile, VisitedServersFile)
        if success and content and #content > 10 then
            local decodeSuccess, decoded = pcall(function() 
                return HttpService:JSONDecode(content) 
            end)
            if decodeSuccess and decoded then 
                VisitedServers = decoded 
            end
        end
    end
end

-- Fungsi untuk save daftar visited servers ke file
local function SaveVisitedServers()
    if writefile then
        pcall(function()
            writefile(VisitedServersFile, HttpService:JSONEncode(VisitedServers))
        end)
    end
end

-- Fungsi untuk tandai server saat ini sebagai visited
local function MarkCurrentServer()
    local jobId = game.JobId
    if jobId and jobId ~= "" then
        VisitedServers[jobId] = tick()  -- Simpan dengan timestamp
        SaveVisitedServers()
    end
end

-- Fungsi untuk bersihkan server lama (lebih dari 24 jam)
local function CleanOldVisitedServers()
    local currentTime = tick()
    local changed = false
    for jobId, timestamp in pairs(VisitedServers) do
        -- Hapus server yang sudah dikunjungi lebih dari 24 jam yang lalu
        if currentTime - timestamp > 86400 then
            VisitedServers[jobId] = nil
            changed = true
        end
    end
    if changed then SaveVisitedServers() end
end

-- [FUNGSI] Auto Rejoin (Simplified)
function Controller.DoRejoin()
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    -- Teleport back to the same server instance
    if jobId and jobId ~= "" then
        pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
        end)
    else
        -- Fallback: Just teleport to the place (random server) if JobId is missing
        pcall(function()
            TeleportService:Teleport(placeId, LocalPlayer)
        end)
    end
end


function Controller.SmartHop()
	if _G.XZNE_Hopping then return end
	_G.XZNE_Hopping = true
	
	local PlaceID = game.PlaceId
	
	task.spawn(function()
		if WindUI then
			WindUI:Notify({
				Title = "🚀 Server Hopping",
				Content = "Jumping to random server...",
				Icon = "shuffle",
				Duration = 3
			})
		end
		
		-- Mark current server as visited
		local currentJobId = game.JobId
		if currentJobId and currentJobId ~= "" then
			VisitedServers[currentJobId] = tick()
			SaveVisitedServers()
		end
		
		-- PURE TELEPORT: Let Roblox pick a random server automatically
		-- This works universally because we're not querying any API
		-- TeleportService:Teleport() automatically sends to a different available server
		
		local success, err = pcall(function()
			-- Pure random hop - Roblox handles server selection internally
			TeleportService:Teleport(PlaceID, LocalPlayer)
		end)
		
		if not success then
			-- Teleport failed
			if WindUI then
				WindUI:Notify({
					Title = "⚠️ Hop Failed",
					Content = "Error: " .. tostring(err),
					Icon = "alert-triangle",
					Duration = 5
				})
			end
			_G.XZNE_Hopping = false
		else
			-- Success - player is being teleported
			-- Script will terminate when player leaves, so no need to reset flag
		end
	end)
end

-- Inisialisasi: Load visited servers dan cleanup
LoadVisitedServers()
CleanOldVisitedServers()
MarkCurrentServer()

-- Auto Hop Timer (jika toggle aktif)
task.spawn(function()
    while true do
        if Config.AutoHop and Config.HopInterval > 0 then
            local currentTime = tick()
            -- Default fallback lebih aman (bisa disesuaikan user jika perlu)
            -- if currentTime - LastHopTime >= Config.HopInterval then
            --     Controller.SmartHop()
            --     LastHopTime = currentTime
            -- end
            
            -- Konversi menit ke detik (Config.HopInterval sekarang dalam menit)
            local intervalSeconds = (Config.HopInterval or 5) * 60
            
            if currentTime - LastHopTime >= intervalSeconds then
                -- Reset hopping flag jika sudah lewat interval jauh (safety)
                _G.XZNE_Hopping = false 
                Controller.SmartHop()
                LastHopTime = currentTime
            end
            task.wait(10)  -- Check setiap 10 detik
        else
            task.wait(30)  -- Jika tidak aktif, check lebih jarang
        end
    end
end)

-- [ANTI-AFK SYSTEM]
-- Mencegah player dikick karena idle 20 menit
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- [7] MAIN LOOP (Loop utama yang menjalankan semua fitur)
-- Defer start supaya GUI selesai loading terlebih dahulu
local MIN_SPEED = 0  -- Delay minimum (0 detik = instant)

task.defer(function()
    task.wait(1)  -- Tunggu GUI selesai loading
    
    -- [LOOP 1] FAST LOOP (Auto Claim - Instant)
    -- Jalan terpisah agar tidak terhambat Action Delay fitur lain
    task.spawn(function()
        while true do
            if Config.Running and Config.AutoClaim then
                RunAutoClaim()
            end
            task.wait(0.1) -- Cek sangat cepat (hampir instant)
        end
    end)

    -- [LOOP 2] THROTTLED LOOP (Buy, List, Clear)
    -- Jalan sesuai Speed setting
    while true do
        if not Config.Running then 
            task.wait(1) 
        else
            pcall(function()
                -- AutoClaim dipisah ke loop atas
                if Config.AutoBuy   then RunAutoBuy()   end  -- Snipe items
                if Config.AutoList  then RunAutoList()  end  -- List items
                if Config.AutoClear then RunAutoClear() end  -- Remove listings
            end)
            
            task.wait(math_max(Config.Speed or 1, MIN_SPEED))
        end
    end
end)

-- Return success to Loader
return true