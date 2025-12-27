# 💠 XZNE ScriptHub - TradingMarket Bot

**Version:** 0.0.01 Beta  
**Game:** Trading Market (Grow A Garden)

---

## 📁 Project Structure

```
TradingMarket/
├── src/                    # Source Code
│   ├── Loader.lua         # Entry point & execution lock
│   ├── Main.lua           # Core logic & controller
│   └── Gui.lua            # WindUI interface
│
├── data/                   # Static Data
│   ├── Database.json      # Item/Pet database (640 entries)
│   └── Database.lua       # Lua format fallback
│
└── README.md              # This file

Executor Workspace:
└── .xzne/                 # Config Folder (auto-created)
    ├── XZNE_Config.json   # User settings
    └── XZNE_Database.json # Cached database
```

---

## 🚀 Quick Start

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/src/Loader.lua"))()
```

---

## ✨ Features

- **Auto Buy (Sniper)** - Instantly snipe listings below max price
- **Auto List** - Automatically list items/pets for sale
- **Auto Remove** - Clear specific items from your booth
- **Auto Claim** - Auto-claim available booths
- **Tab-Based Lazy Loading** - 67% faster GUI with on-demand dropdown loading
- **JSON Database Caching** - 99% faster subsequent loads
- **Silent Production Mode** - Clean console, no debug spam

---

## 🎨 GUI Features

- Glassmorphism design
- Search in all dropdowns (640 items)
- Live stats display
- Config auto-save
- Tab-based lazy loading (instant GUI)

---

## 📦 Configuration

All configs stored in `.xzne/` folder in executor workspace:

- **XZNE_Config.json** - User settings (auto-saves)
- **XZNE_Database.json** - Cached database (instant loads)

To reset: Delete `.xzne/` folder

---

## 🔧 Development

**Folder Purpose:**
- `src/` - All Lua source code
- `data/` - Static databases
- `.xzne/` - Runtime configs (executor workspace)

**File Roles:**
- `Loader.lua` - Entry point, prevents double execution
- `Main.lua` - Core bot logic, controller, auto functions
- `Gui.lua` - WindUI interface, tab-based lazy loading

---

## 📝 Changelog

### Latest (v0.0.01 Beta)
- ✅ Tab-based lazy loading (67% performance boost)
- ✅ Silent production mode (clean console)
- ✅ JSON database caching (99% faster 2nd load)
- ✅ Workspace restructure (src/, data/, .xzne/)
- ✅ Execution lock (prevents triple-run bug)
- ✅ Global function caching (30-40% runtime boost)

---

## ⚠️ Notes

- First load: ~2s (downloads database)
- Second+ load: <100ms (uses cache)
- GUI appears: ~100ms (instant)
- Dropdowns load on-demand per tab
- Console is clean (production mode)

---

**Made with ❤️ by Xzero One**
