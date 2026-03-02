# AxA — Asset Guide

## Art Style
- 16-bit pixel art
- Nearest-neighbor scaling (no anti-aliasing, no smoothing)
- Design sprites at 16x16 or 16x24 pixels
- Design tiles at 16x16 pixels
- Bright, saturated colours — this is a game for a 6-year-old

## Sourcing Strategy

### Phase 1: Free Asset Packs (Current)
Use free pixel art packs to get the game playable fast.

**Sources:**
- **itch.io** — search "top down RPG tileset free", "pixel art character free"
- **OpenGameArt.org** — CC0 and CC-BY licensed assets
- **Kenney.nl** — public domain game assets

**Priority assets to source:**
1. Top-down RPG tileset (ground, water, walls, objects)
2. Character sprites with walk/attack animations (recolour for different characters)
3. Enemy sprites
4. UI elements (health bar, buttons, text box)
5. Item sprites (bags, crystals, keys)

### Phase 2: Custom Sprites (Later)
Zig will customise specific sprites. Priority for customisation:
1. Playable characters (Wiz, Bob, Babeee)
2. Nono trees
3. Yummy snack bags
4. Monontoe boss

**Process for Zig's custom art:**
- Zig draws on paper
- Photo of drawing
- Convert to pixel sprite (can use tools like Piskel, Aseprite, or AI upscaling)
- Replace placeholder in asset catalog

## Naming Convention
```
char_{name}_{action}_{direction}_{frame}.png

Examples:
char_wiz_idle_down_0.png
char_wiz_walk_down_0.png
char_wiz_walk_down_1.png
char_wiz_attack_right_0.png
char_bob_idle_down_0.png
char_bob_peck_right_0.png

enemy_{name}_{action}_{frame}.png
enemy_salt_knight_idle_0.png
enemy_salt_knight_walk_0.png
enemy_monontoe_charge_0.png

tile_{type}.png
tile_salt_ground.png
tile_salt_crystal.png
tile_salt_crystal_breakable.png
tile_nono_tree.png
tile_water.png
tile_water_shallow.png
tile_cave_floor.png
tile_cave_wall.png

item_{name}.png
item_snack_bag.png
item_salt_crystal.png
item_key.png
item_health.png

ui_{element}.png
ui_joystick_base.png
ui_joystick_knob.png
ui_button_attack.png
ui_button_special.png
ui_button_tablet.png
ui_health_bar_bg.png
ui_health_bar_fill.png
ui_dialogue_box.png
ui_portrait_frame.png

sfx_{description}.wav
music_{world}_{section}.mp3
```

## Folder Structure in Assets.xcassets
```
Assets.xcassets/
├── Characters/
│   ├── Wiz/
│   ├── Bob/
│   └── Babeee/
├── Enemies/
│   ├── SaltKnight/
│   ├── SaltProtector/
│   └── Monontoe/
├── Tiles/
│   ├── SaltWorldLake/
│   ├── GoGoForest/     (empty, future)
│   └── Underworld/     (empty, future)
├── Items/
├── UI/
├── Effects/
└── NPCs/
    └── NonoTree/
```

## Licence Tracking
Keep a LICENCES.md file in assets/ listing every asset pack used, its source URL, and licence type. This is good practice and Zig should learn it early.
