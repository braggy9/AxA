# AxA — Claude Code Project Instructions

## What This Is
A top-down 2D adventure game (Zelda-style) built with Swift + SpriteKit for iPad/iPhone. Designed by Zig (age 6) and his dad Tom.

## Key Reference Docs
- `docs/GAME-DESIGN-SPEC.md` — Full game design specification (worlds, characters, mechanics, puzzles)
- `docs/BUILD-PLAN.md` — Prioritised build order with definition of done
- `docs/ASSET-GUIDE.md` — Art style, asset naming conventions, and sourcing strategy

## Tech Stack
- **Language:** Swift 6+
- **Framework:** SpriteKit (SKScene, SKTileMapNode, SKSpriteNode, SKPhysicsBody, SKCameraNode)
- **Game Logic:** GameplayKit (GKStateMachine, GKGridGraph)
- **Target:** iOS 17+, iPad (primary), iPhone (secondary)
- **Orientation:** Landscape only
- **Art:** 16-bit pixel art, nearest-neighbor scaling, no anti-aliasing

## Architecture Rules
- Design at 256×144 or 320×180 logical pixels, scale up to device resolution
- Use `SKTileMapNode` for world tile maps
- Use `SKPhysicsBody` categories for collision: player, enemy, projectile, wall, water, interactable, trigger
- Use `SKCameraNode` clamped to room bounds
- Use `GKStateMachine` for enemy AI states
- Use `SKAction` sequences for animations (not manual frame updates)
- Keep all magic numbers in `Constants.swift`
- All touch targets minimum 44pt × 44pt (this is for a 6-year-old)
- Assets organised for easy sprite replacement (Zig will customise characters later)

## Build Approach
- Build incrementally following `docs/BUILD-PLAN.md`
- Get each stage playable before moving to the next
- Use free pixel art asset packs (itch.io, OpenGameArt, Kenney.nl) where possible
- Generate simple coloured placeholder sprites where free packs don't cover it
- Current scope: World 1 (Salt World Lake) fully playable

## Asset Naming Convention
```
char_{name}_{action}_{direction}_{frame}.png
enemy_{name}_{action}_{frame}.png
tile_{world}_{type}.png
ui_{element}.png
sfx_{description}.wav
music_{world}_{section}.mp3
```

## Important Creative Details (from Zig)
- Nono trees say "no no no" in chorus when you approach early, "go go go" when you're ready
- Yummy snack bags are gold bags with white smiley faces
- Wiz carries his staff with his tail
- Bob the Chicken is just a chicken among axolotls — he's vibing
- The game's ultimate villain is Queen Owarla (World 3 boss, not built yet)
- "Obliterate" is the preferred verb for defeating enemies
