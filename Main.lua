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
        
        -- Pengaturan Auto Hop (NEW - Fitur Server Hopping)
        AutoHop = false,             -- Toggle fitur auto hop
        HopInterval = 300,           -- Interval hop dalam detik (default 5 menit)
        RejoinBypassPrivate = true   -- Bypass private server saat rejoin (true = rejoin ke public)
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
function Controller.UpdateCache()
    -- Cache nama target dalam lowercase untuk pencarian lebih cepat
    CachedTargets.Buy = string.lower(Config.BuyTarget or "")
    CachedTargets.List = string.lower(Config.ListTarget or "")
    CachedTargets.Remove = string.lower(Config.RemoveTarget or "")
    
    -- Cache terpisah untuk Pet dan Item (mendukung dual target)
    CachedTargets.BuyPet = string.lower(Config.BuyTargetPet or "")
    CachedTargets.BuyItem = string.lower(Config.BuyTargetItem or "")
    
    -- Filter "— none —" menjadi string kosong untuk keamanan
    if CachedTargets.BuyPet == "— none —" then CachedTargets.BuyPet = "" end
    if CachedTargets.BuyItem == "— none —" then CachedTargets.BuyItem = "" end
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
                    if listType == "Pet" and CachedTargets.BuyPet ~= "" then 
                        targetMatch = true 
                    -- Jika ini Item dan kita punya target Item, cocok
                    elseif listType == "Holdable" and CachedTargets.BuyItem ~= "" then 
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
                                -- Cocokkan dengan target Pet
                                if string_find(lowerName, CachedTargets.BuyPet) then 
                                    isMatch = true 
                                end
                            elseif listingInfo.ItemType == "Holdable" then
                                -- Cocokkan dengan target Item
                                if string_find(lowerName, CachedTargets.BuyItem) then 
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
    if myData and myData.Listings then
        for _, v in pairs(myData.Listings) do 
            listedUUIDs[v.ItemId] = true 
        end
    end
    
    local price = Config.Price
    local currentTime = tick()
    
    -- LOGIKA GANDA: Cek Pet dan Item secara berurutan
    
    -- [1] LISTING PET
    -- BUG FIX: Gunakan Config.ListCategory, bukan CachedTargets.List
    if Config.ListCategory == "Pet" or CachedTargets.BuyPet ~= "" then
        local petTarget = CachedTargets.BuyPet
        if petTarget ~= "" then
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
                        if petName and string_find(string_lower(petName), petTarget) then
                            -- List pet ini
                            pcall(function() 
                                CreateListingRemote:InvokeServer("Pet", petUUID, price) 
                            end)
                            ListingDebounce[petUUID] = currentTime
                            Stats.ListedCount = Stats.ListedCount + 1
                            task.wait(Config.Speed)
                        end
                    end
                end
            end
        end
    end

    -- [2] LISTING ITEM
    -- BUG FIX: Gunakan Config.ListCategory, bukan CachedTargets.List
    if Config.ListCategory == "Item" or CachedTargets.BuyItem ~= "" then
        local itemTarget = CachedTargets.BuyItem
        if itemTarget ~= "" then
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
                            if string_find(string_lower(realName), itemTarget) then
                                -- List item ini
                                pcall(function() 
                                    CreateListingRemote:InvokeServer("Holdable", uuid, price) 
                                end)
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
end

-- >> FUNGSI AUTO CLEAR (Smart Remove)
-- Otomatis hapus listing yang sesuai target dari booth
local function RunAutoClear()
    -- Keluar jika fitur tidak aktif
    if not Config.AutoClear then return end
    
    -- Ambil target Pet dan Item
    local targetLowerPet = CachedTargets.BuyPet
    local targetLowerItem = CachedTargets.BuyItem
    
    -- Jika tidak DeleteAll dan tidak ada target, keluar
    if not Config.DeleteAll and targetLowerPet == "" and targetLowerItem == "" then 
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
                    elseif listingInfo.ItemType == "Pet" and targetLowerPet ~= "" and string_find(lowerName, targetLowerPet) then 
                        -- Hapus Pet yang cocok target
                        shouldRemove = true
                    elseif listingInfo.ItemType == "Holdable" and targetLowerItem ~= "" and string_find(lowerName, targetLowerItem) then 
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

-- >> FUNGSI AUTO CLAIM
-- Otomatis claim booth kosong yang tidak ada pemiliknya
local function RunAutoClaim()
    -- Keluar jika fitur tidak aktif
    if not Config.AutoClaim then return end
    
    -- Jika sudah punya booth, tidak perlu claim lagi
    if GetMyBooth() then return end
    
    -- Cari folder yang berisi semua booth
    local folder = Workspace:FindFirstChild("TradeWorld") and Workspace.TradeWorld:FindFirstChild("Booths")
    if not folder then return end
    
    -- Loop semua booth untuk mencari yang kosong
    for _, booth in pairs(folder:GetChildren()) do
        -- Ambil OwnerId dari booth
        local oid = booth:GetAttribute("OwnerId")
        if not oid then 
            local v = booth:FindFirstChild("OwnerId")
            if v then oid = v.Value end
        end
        
        -- Jika booth tidak ada pemilik, claim booth ini
        if oid == nil or oid == 0 or oid == "" then
            pcall(function() 
                ClaimBoothRemote:FireServer(booth) 
            end)
            
            -- Teleport karakter ke booth yang di-claim
            if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                LocalPlayer.Character:SetPrimaryPartCFrame(booth.PrimaryPart.CFrame + Vector3.new(0,3,0))
            end
            
            task.wait(1)  -- Tunggu server memproses claim
            
            -- Jika sudah berhasil claim, keluar dari function
            if GetMyBooth() then return end
        end
    end
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

-- [FUNGSI] Auto Rejoin (Manual button, bukan auto-detect)
function Controller.DoRejoin()
    local placeId = game.PlaceId
    local privateServerId = game.PrivateServerId
    
    -- Jika bypass private server aktif DAN kita sedang di private server
    if Config.RejoinBypassPrivate and privateServerId and privateServerId ~= "" then
        -- Rejoin ke PUBLIC server (bypass private)
        pcall(function()
            TeleportService:Teleport(placeId, LocalPlayer)
        end)
    else
        -- Rejoin ke server yang sama (termasuk private jika ada)
        if privateServerId and privateServerId ~= "" then
            -- Rejoin ke private server yang sama
            pcall(function()
                TeleportService:TeleportToPrivateServer(
                    placeId, 
                    privateServerId, 
                    {LocalPlayer}
                )
            end)
        else
            -- Rejoin ke public server yang sama
            pcall(function()
                TeleportService:TeleportToPlaceInstance(
                    placeId, 
                    game.JobId, 
                    LocalPlayer
                )
            end)
        end
    end
end

-- [FUNGSI] Smart Auto Hop ADVANCED (Server hopping cerdas dengan multi-strategy)
-- [NEW] BACKGROUND SERVER CACHER (Untuk True Instant Hop)
-- Thread ini berjalan di background untuk menimbun server kosong
_G.XZNE_ServerCache = {}
local function StartServerCacher()
    task.spawn(function()
        local PlaceID = game.PlaceId
        local currentJobId = game.JobId
        
        while true do
            -- Hanya cache jika cache kosong/sedikit untuk hemat bandwidth
            if #_G.XZNE_ServerCache < 5 then
                local url = 'https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Desc&limit=100'
                local success, result = pcall(function() return game:HttpGet(url) end)
                
                if success and result then
                    local Site = HttpService:JSONDecode(result)
                    if Site and Site.data then
                        local tempCache = {}
                        for _, v in pairs(Site.data) do
                            local ID = tostring(v.id)
                            local maxPlayers = tonumber(v.maxPlayers) or 0
                            local playing = tonumber(v.playing) or 0
                            
                            -- Filter: Beda Server & Tidak Penuh
                            if ID ~= tostring(currentJobId) and maxPlayers > playing then
                                table.insert(tempCache, ID)
                            end
                        end
                        
                        -- Update Global Cache jika ada hasil
                        if #tempCache > 0 then
                            -- Shuffle results agar lebih random
                            for i = #tempCache, 2, -1 do
                                local j = math.random(i)
                                tempCache[i], tempCache[j] = tempCache[j], tempCache[i]
                            end
                            _G.XZNE_ServerCache = tempCache
                        end
                    end
                end
            end
            task.wait(15) -- Refresh cache setiap 15 detik
        end
    end)
end

-- Start Cacher Immediately
StartServerCacher()

-- [FUNGSI] INSTANT RANDOM HOP (CACHED)
-- Menggunakan sistem cache untuk 0-delay instant hop
function Controller.SmartHop()
    if _G.XZNE_Hopping then return end
    _G.XZNE_Hopping = true
    
    local PlaceID = game.PlaceId
    
    -- [STEP 1] Coba gunakan CACHE terlebih dahulu (Instant)
    if #_G.XZNE_ServerCache > 0 then
        if WindUI then
            WindUI:Notify({
                Title = "Instant Hop",
                Content = "Server found in cache! Teleporting...",
                Icon = "zap",
                Duration = 3
            })
        end
        
        -- Ambil server pertama dari cache (sudah di-shuffle saat caching)
        local targetID = table.remove(_G.XZNE_ServerCache, 1)
        
        local success, err = pcall(function()
             TeleportService:TeleportToPlaceInstance(PlaceID, targetID, LocalPlayer)
        end)
        
        if success then return end -- Berhasil trigger teleport
        -- Jika gagal, lanjut ke manual fetch (fallback)
    end

    -- [STEP 2] Manual Fetch (Fallback jika cache kosong/gagal)
    if WindUI then
        WindUI:Notify({
            Title = "Hopping...",
            Content = "Fetching new server list...",
            Icon = "shuffle",
            Duration = 3
        })
    end
    
    local currentJobId = game.JobId
    
    task.spawn(function()
        -- Fetch 100 Server Terbaru (Desc)
        local url = 'https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Desc&limit=100'
        local success, result = pcall(function() return game:HttpGet(url) end)
        
        if success and result then
            local Site = HttpService:JSONDecode(result)
            if Site and Site.data then
                local candidates = {}
                
                for _, v in pairs(Site.data) do
                    local ID = tostring(v.id)
                    local maxPlayers = tonumber(v.maxPlayers) or 0
                    local playing = tonumber(v.playing) or 0
                    
                    if ID ~= tostring(currentJobId) and maxPlayers > playing then
                        table.insert(candidates, ID)
                    end
                end
                
                if #candidates > 0 then
                    -- Shuffle & Retry Loop
                    local function shuffle(tbl)
                        for i = #tbl, 2, -1 do
                            local j = math.random(i)
                            tbl[i], tbl[j] = tbl[j], tbl[i]
                        end
                        return tbl
                    end
                    shuffle(candidates)
                    
                    for _, targetID in ipairs(candidates) do
                        local tSuccess, _ = pcall(function()
                            TeleportService:TeleportToPlaceInstance(PlaceID, targetID, LocalPlayer)
                        end)
                        if tSuccess then 
                            if WindUI then
                                WindUI:Notify({Title="Teleporting", Content="Teleporting...", Icon="plane"})
                            end
                            return 
                        end
                        task.wait(0.2)
                    end
                else
                    if WindUI then WindUI:Notify({Title="No Servers", Content="Server list empty.", Icon="x-circle"}) end
                end
            end
        end
        
        task.wait(1)
        _G.XZNE_Hopping = false
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
            
            if currentTime - LastHopTime >= Config.HopInterval then
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

-- [7] MAIN LOOP (Loop utama yang menjalankan semua fitur)
-- Defer start supaya GUI selesai loading terlebih dahulu
local MIN_SPEED = 0  -- Delay minimum (0 detik = instant)

task.defer(function()
    task.wait(1)  -- Tunggu GUI selesai loading
    
    -- Loop tak terbatas selama script berjalan
    while true do
        if not Config.Running then 
            -- Jika script pause, tunggu 1 detik
            task.wait(1) 
        else
            -- Jalankan semua fungsi auto yang aktif
            pcall(function()
                if Config.AutoClaim then RunAutoClaim() end  -- Claim booth dulu
                if Config.AutoBuy   then RunAutoBuy()   end  -- Snipe items
                if Config.AutoList  then RunAutoList()  end  -- List items
                if Config.AutoClear then RunAutoClear() end  -- Remove listings
            end)
            
            -- Tunggu sesuai setting Speed (dengan batas minimum)
            task.wait(math_max(Config.Speed or 1, MIN_SPEED))
        end
    end
end)

-- Return success to Loader
return true