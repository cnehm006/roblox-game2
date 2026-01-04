# Coin Incremental Game

A Roblox incremental coin collection game with multiple progression systems.

## 🎮 Features

### Coin Rarities
Coins spawn on the platform with 8 different rarity tiers:
- **Bronze** - Common (brownish)
- **Silver** - Uncommon (gray/white)
- **Gold** - Rare (yellow/golden)
- **Diamond** - Very Rare (light blue)
- **Emerald** - Epic (green)
- **Ruby** - Legendary (red)
- **Obsidian** - Mythic (black/dark gray)
- **Quartz** - Ultra Rare (white)

Each rarity has increasing value multipliers and XP yields.

### Level System
- Collect coins to earn XP
- Levels scale into the hundreds of millions
- XP requirements scale normally until level 100
- At level 100+, XP requirement is capped at 12,000 for endless progression

### Base Upgrades
Spend coins on upgrades at the upgrade board:
- **Faster Respawning** (200 levels) - Coins spawn more frequently
- **Coin Value Multiplier** (400 levels) - Increases coin value
- **Coin Rarity Chance** (300 levels) - Better rare coin odds
- **Max Coins on Platform** (250 levels) - More coins can exist
- **Coin Pulling Strength** (500 levels) - Attract coins from further away

### Rebirth System
- Rebirth at 1,000,000 coins
- Resets coins, XP, and upgrades
- Grants permanent coin boost (+10% per rebirth)
- Grants speed boost (+2% per rebirth, max 100%)
- Unlocks the Rebirth Board after first rebirth

### Rebirth Upgrades
Advanced upgrades with fixed costs (unlocked after first rebirth):
- **Quick Upgrades** (25M/level, 20 levels) - Free upgrades on rebirth
- **Rebirth Vault** (60M/level, 50 levels) - Keep coins on rebirth
- **Offline Collection** (30M/level, 500 levels) - Earn coins offline
- **Auto Upgrading** (35M/level, 100 levels) - Automatic base upgrades
- **Auto Rebirths** (2.5B/level, 5 levels) - Automatic rebirthing

## 📁 Project Structure

```
src/
├── shared/
│   ├── GameConfig.luau      # All game configuration and constants
│   ├── PlayerDataTemplate.luau # Player data structure
│   └── Remotes.luau         # Network communication
├── server/
│   ├── init.server.luau     # Main server entry point
│   ├── DataManager.luau     # Player data persistence
│   ├── CoinSpawner.luau     # Coin spawning logic
│   ├── CoinCollector.luau   # Collection and attraction
│   ├── LevelSystem.luau     # XP and leveling
│   ├── UpgradeSystem.luau   # Base upgrades
│   ├── RebirthSystem.luau   # Rebirth mechanics
│   └── RebirthBoardSystem.luau # Advanced upgrades
└── client/
    ├── init.client.luau     # Main client entry point
    ├── UIManager.luau       # All UI creation and updates
    └── CoinEffects.luau     # Visual effects
```

## 🚀 Getting Started

1. Install [Rojo](https://rojo.space/) if you haven't already
2. Run `rojo serve` in the project directory
3. Connect to the Rojo server from Roblox Studio
4. Play test the game!

## 🎨 UI Layout

- **Top Center**: Stats HUD (coins, level, XP bar, rebirth count)
- **Left Side**: Upgrade Board panel
- **Bottom Right**: Rebirth panel
- **Right Side**: Rebirth Board (unlocks after first rebirth)

## ⚙️ Configuration

All game values can be adjusted in `src/shared/GameConfig.luau`:
- Coin rarities and weights
- Upgrade costs and effects
- Rebirth requirements and bonuses
- Level scaling formulas
- Spawn intervals and limits

## 🔧 Technical Details

- Uses DataStoreService for persistent player data
- Auto-saves every 60 seconds
- Supports offline coin collection
- Implements session locking to prevent data loss
- Client-side prediction for smooth UI updates

## 🎯 Future Expansion Ideas

- Particle effects for rare coin spawns
- Prestige system beyond rebirths
- Sound effects for milestones
- Leaderboards
- Daily rewards
- Pet/companion system
