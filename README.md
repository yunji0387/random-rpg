# Random RPG

A 3D open-world RPG prototype built in Godot 4.7.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the game flow, system boundaries, and a complete scene/script/shader reference.

## Getting Started

1. Open this folder in Godot 4.7+.
2. Press **Run Project** (F5). The game starts at the main menu; click **Start** to load the world.
3. Controls:
   - `WASD` — move
   - Mouse — look around
   - `Space` — jump
   - `Shift` — sprint (drains stamina)
   - `Ctrl` — crouch
   - `R` — roll/dodge (costs stamina, has a cooldown)
   - `Left Mouse Button` — melee attack
  - `I` — inventory and equipment screen
  - `P` — pause menu
  - `Settings` — configure mouse sensitivity and brightness from the main menu or pause menu
  - Pause menu `Save Game` / `Load Game` — persist or restore player progress
  - `Esc` — open/close the pause menu, or close the inventory screen

## Project Structure

```
scenes/
  ui/
    MainMenu.tscn   # Title screen
    HUD.tscn        # In-game overlay (health/mana/stamina/xp bars, quest, time, messages, debug readout)
  Main.tscn         # Open world root (sky, sun, streamed terrain, weather, quests, player, HUD)
  Player.tscn        # Playable 3D character
  Enemy.tscn         # Wandering/chasing enemy
  Pickup.tscn        # World item (weapon/armor/potion)
  NPC.tscn           # Dialogue-triggering NPC
scripts/
  Player.gd           # Movement, stats, combat, inventory/equipment
  HUD.gd
  MainMenu.gd
  Main.gd
  WorldGenerator.gd   # Streams terrain chunks + scatters props/enemies/pickups/NPC around the player
  TerrainChunk.gd     # Builds one chunk's heightmap mesh + collision
  DayNightCycle.gd    # Rotates the sun and adjusts sky/ambient lighting over time
  Weather.gd          # Randomly toggles rain + fog, follows the player
  Enemy.gd            # Patrol/chase/attack AI
  Pickup.gd           # Item pickup behavior
  NPC.gd              # Dialogue trigger
  QuestManager.gd     # Tracks a simple kill-count quest
  Item.gd             # Weapon/armor/consumable item resource
  Inventory.gd        # Player item list
shaders/
  terrain.gdshader    # Height-based terrain coloring (grass/rock/snow)
```

## Roadmap

### Phase 0 — Foundation (done)
- [x] Project scaffolding, main menu, HUD
- [x] Basic 3D character controller (walk, look, jump)
- [x] Placeholder open-world ground plane, sky, and lighting

### Phase 1 — Core Movement & Camera (done)
- [x] Sprint / stamina system
- [x] Crouch and roll/dodge
- [x] Third-person camera collision (SpringArm3D shape) and FOV smoothing
- [x] Placeholder animation state machine (idle/walk/run/crouch/jump/fall/roll) driving squash-and-stretch until real animations are added

### Phase 2 — World Building (done)
- [x] Replaced the flat ground with real terrain: chunks generate a heightmap mesh (FastNoiseLite) with matching `HeightMapShape3D` collision, colored by height/slope via a shader
- [x] Streaming/chunked world loading — `WorldGenerator.gd` spawns chunks in a radius around the player and frees ones that fall out of range
- [x] Environment props: trees and rocks scattered per chunk with `MultiMeshInstance3D` (deterministic per-chunk seed)
- [x] Day/night cycle (`DayNightCycle.gd`, rotates the sun and fades sky/ambient light) and simple weather (`Weather.gd`, randomly toggles rain + fog)

### Phase 3 — Gameplay Systems (done)
- [x] Player stats: health, mana, XP, and leveling (`Player.gd`), shown in the HUD
- [x] Inventory and equipment: `Item.gd`/`Inventory.gd`, world pickups auto-equip weapons/armor or heal on pickup
- [x] Melee combat (left-click) with enemy hit-flash reactions
- [x] Enemy AI (`Enemy.gd`): patrol around a home point, chase the player within range, attack on contact
- [x] Minimal quest system (`QuestManager.gd`, kill-count quest with XP reward) and a dialogue-triggering NPC

### Phase 4 — UI/UX
- [x] Inventory & equipment screens
- [ ] Quest log and journal
- [ ] Minimap / world map
- [x] Save/load system with pause menu UI (`user://random_rpg_save.json`)

### Phase 5 — Content & Polish
- [ ] NPC towns/villages
- [ ] Dungeons/points of interest
- [ ] Audio: music, ambience, SFX
- [ ] Performance passes (LOD, occlusion culling)
- [ ] Playtesting & balancing

## Contributing Notes
This is an early prototype — scenes and scripts are intentionally simple placeholders meant to be expanded on as systems are built out.
