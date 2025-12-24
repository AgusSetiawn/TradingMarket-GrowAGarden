# XZNE ScriptHub - Trading Market Manager

A powerful script hub for Roblox Trading Market, featuring Auto List (v2.0 Logic) and Auto Claim.
Refactored directly from v18.0 Logic Core.

## 🚀 How to Run

Execute the following script in your executor (Solara, Wave, Synapse X, etc.):

```lua
-- 1. Load Logic Core
loadstring(game:HttpGet("https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/Main.lua"))()

-- 2. Load UI (WindUI)
loadstring(game:HttpGet("https://raw.githubusercontent.com/AgusSetiawn/TradingMarket-GrowAGarden/main/Loader.lua"))()
```

## ✨ Features

- **Auto Claim**: Automatically claims empty booths.
- **Auto List**: Lists items with specific Attributes (`f` for name, `c` for UUID) - Uses exact v2.0 logic.
- **Manager UI**: 
  - Modern macOS-style Interface (WindUI).
  - Real-time toggles and configuration.
- **Performance**: Optimized clear cache and efficient loops.

## ⚠️ Notes

- The script automatically loads `WindUI` from the official repository if not found locally.
- Ensure your executor supports `HttpGet` and `loadstring`.
- **Auto Clear** featured was removed in v18.0 due to instability.

---
*Developed by XZNE Team | Refactored by Assistant*
