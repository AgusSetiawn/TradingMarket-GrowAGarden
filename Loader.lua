--[[
    💠 XZNE SCRIPTHUB v0.0.01 [Beta] - LOADER
    
    🚀 Penggunaan: loadstring(game:HttpGet("https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/Loader.lua"))()
    
    📋 Fungsi: Memuat Main.lua dan Gui.lua dari GitHub repository
    ⚡ Fitur: Cache busting otomatis untuk memastikan versi terbaru selalu dimuat
]]

-- Repository GitHub resmi (main branch)
local Repo = "https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/"

-- [PENTING] Kunci eksekusi: Mencegah script berjalan berulang kali saat masih loading
if _G.XZNE_EXECUTING then
    -- Script sudah sedang berjalan, keluar dari eksekusi untuk menghindari konflik
    return
end
-- Set flag bahwa script sedang berjalan
_G.XZNE_EXECUTING = true

-- Fungsi untuk memuat script dari GitHub dengan validasi
local function LoadScript(Script)
    -- Cache Busting: Tambahkan timestamp agar selalu download versi terbaru
    -- Ini mencegah Roblox menggunakan cache lama
    local Success, Result, ErrMsg = pcall(function()
        -- Download konten dari GitHub dengan parameter timestamp
        local Content = game:HttpGet(Repo .. Script .. "?t=" .. tostring(os.time()))
        
        -- Validasi: Pastikan konten yang didownload tidak kosong
        if not Content or #Content < 50 then 
            return nil, "HTTP Error: Konten kosong atau tidak valid"
        end
        
        -- Validasi: Cek apakah konten terlihat seperti kode Lua yang valid
        local firstLine = string.match(Content, "^([^\n]+)")
        if not firstLine or (#firstLine > 0 and not string.match(firstLine, "^%-%-") and not string.match(firstLine, "^%s*local") and not string.match(firstLine, "^%s*function")) then
            -- Konten mencurigakan tapi tetap lanjutkan (mungkin format berbeda)
        end
        
        -- Compile kode Lua menjadi function
        local Func, SyntaxErr = loadstring(Content)
        if not Func then
            -- Ada kesalahan syntax dalam kode
            return nil, "Syntax Error: " .. tostring(SyntaxErr)
        end
        
        -- Jalankan function yang sudah di-compile
        return Func()
    end)
    
    -- Cek apakah proses loading berhasil
    if not Success or Result == nil then
        -- Jika pcall gagal, Result berisi pesan error
        -- Jika pcall berhasil tapi function return nil, ErrMsg berisi error
        local finalErr = not Success and Result or ErrMsg
        -- Loading gagal, return false (tidak menampilkan warn lagi)
        return false
    end
    
    -- Loading berhasil
    return true
end

-- [LANGKAH 1] Muat file Main.lua (berisi logika inti)
local mainLoaded = LoadScript("Main.lua")

-- Cek apakah Main.lua berhasil dimuat
if not mainLoaded then
    -- Main.lua gagal dimuat, hentikan eksekusi
    _G.XZNE_EXECUTING = false
    return
end

-- [LANGKAH 2] Tunggu sampai Controller tersedia (dibuat oleh Main.lua)
local Timeout = 0
while not _G.XZNE_Controller and Timeout < 10 do
    task.wait(0.2)  -- Tunggu 0.2 detik
    Timeout = Timeout + 0.2
end

-- Cek apakah Controller berhasil dibuat
if not _G.XZNE_Controller then
    -- Controller tidak tersedia setelah 10 detik, ada masalah di Main.lua
    _G.XZNE_EXECUTING = false  -- Lepaskan kunci eksekusi
    return
end

-- [LANGKAH 3] Muat file Gui.lua (berisi antarmuka pengguna)
LoadScript("Gui.lua")

-- [PENTING] Lepaskan kunci eksekusi setelah loading selesai
task.defer(function()
    task.wait(0.5)  -- Delay kecil untuk memastikan GUI sudah stabil
    _G.XZNE_EXECUTING = false  -- Script sekarang boleh dijalankan ulang jika diperlukan
end)
