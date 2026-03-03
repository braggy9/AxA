# AxA — Claude Code Project Instructions

## What This Is
A top-down 2D adventure game (Zelda-style) built with Swift + SpriteKit for iPad/iPhone. Designed by Zig (age 6) and his dad Tom.

## Current Status (2026-03-04)
**Stage 4 complete.** Stages 1–4 fully built and committed.
- 4 of 7 World 1 rooms are playable (Spawn Beach, Crystal Fields, Lake Shore East, Salt Cave)
- Bob the Chicken fully playable: peck attack, flutter dash, dig, per-character HP
- Next: **Stage 5** — Lake Shore West (water switches), Nono Grove, Monontoe boss, Babeee unlock
- See `docs/BUILD-PLAN.md` for full progress tracker

## Key Reference Docs
- `docs/GAME-DESIGN-SPEC.md` — Full game design specification (worlds, characters, mechanics, puzzles)
- `docs/BUILD-PLAN.md` — Prioritised build order with definition of done and room/enemy status tables
- `docs/ASSET-GUIDE.md` — Art style, asset naming conventions, and sourcing strategy

## Workflow (Tom's MacBook Pro)
- Repo: `https://github.com/braggy9/AxA` — always the source of truth
- Local path: `/Users/tombragg/Desktop/Projects/AxA` (properly cloned, not iCloud)
- Remote is SSH: `git@github.com:braggy9/AxA.git`
- Before pushing: `ssh-add ~/.ssh/id_ed25519`
- Xcode not installed on this Mac — build/test on the other MBP or iPad
- XcodeGen installed: run `xcodegen generate` after adding new Swift files or changing project structure
- All new Swift files in `AxA/` subfolders are auto-discovered by XcodeGen (no manual project.pbxproj editing)

## Tech Stack
- **Language:** Swift 6+
- **Framework:** SpriteKit (SKScene, SKTileMapNode, SKSpriteNode, SKPhysicsBody, SKCameraNode)
- **Game Logic:** GameplayKit (GKStateMachine, GKGridGraph)
- **Target:** iOS 17+, iPad (primary), iPhone (secondary)
- **Orientation:** Landscape only
- **Art:** 16-bit pixel art, nearest-neighbor scaling, no anti-aliasing

## Architecture Rules
- Design at 320×180 logical pixels, scale up to device resolution
- Use `SKTileMapNode` for world tile maps (built programmatically via `TileMapBuilder`)
- New tile types go in `TileType` enum + `makeTexture(for:)` switch + `buildWallNodes` blocking check
- Use `SKPhysicsBody` categories — ALL categories defined in `Constants.swift`
- Use `SKCameraNode` clamped to room bounds
- Use `GKStateMachine` for all enemy AI — each enemy gets its own States file
- Use `SKAction` sequences for animations (not manual frame updates)
- Keep ALL magic numbers in `Constants.swift` — never hardcode
- All touch targets minimum 44pt × 44pt (this is for a 6-year-old)
- Assets organised for easy sprite replacement (Zig will customise characters later)
- New rooms: subclass `BaseGameScene`, override `subclassSetup()`
- New enemies: subclass `EnemyNode`, add case to `EnemyType`, handle in `BaseGameScene.setupEnemies()`

## Key Files
```
AxA/
├── Constants.swift          — ALL constants, physics categories, palette colours
├── Rooms/RoomID.swift       — Room identifiers and Edge enum
├── Tiles/TileMapBuilder.swift — Tile layouts + buildMap helper + texture generation
├── Scenes/
│   ├── BaseGameScene.swift  — Camera, player, HUD, enemies, physics contacts, transitions
│   ├── SpawnBeachScene.swift
│   ├── CrystalFieldsScene.swift
│   ├── LakeShoreEastScene.swift
│   └── SaltCaveScene.swift
├── Nodes/
│   ├── PlayerNode.swift     — Movement, attack, character switching, Bob abilities
│   ├── HUDNode.swift        — Health bar, crystal counter, character portrait
│   ├── AttackButtonNode.swift (A button)
│   ├── SpecialButtonNode.swift (B button — context-aware: Grapple/Flutter/Dig hint)
│   ├── VirtualJoystickNode.swift
│   ├── CrystalNode.swift    — Collectible drop
│   ├── GrapplePointNode.swift — Wooden post with detection zone
│   ├── BreakableWallNode.swift — Shatters on one hit
│   ├── KeyNode.swift        — Golden key collectible
│   ├── LockedDoorNode.swift — Opens when player has key
│   ├── SnackBagNode.swift   — Gold snack bag, reveal animation, triggers character unlock
│   └── SoftGroundNode.swift — Dig spot for Bob (press B to uncover crystals)
└── Enemies/
    ├── EnemyNode.swift      — Base class (health, damage, knockback, crystal drops)
    ├── SaltKnightNode.swift + AIStates.swift
    └── SaltProtectorNode.swift + SaltProtectorStates.swift
```

## Build Approach
- Build incrementally following `docs/BUILD-PLAN.md`
- Get each stage playable before moving to the next
- Use placeholder coloured sprites — replace with real art later (Zig will customise)
- Current scope: World 1 (Salt World Lake) fully playable

## Physics Categories (Constants.swift)
```
player, enemy, projectile (player attack hitbox), wall, water,
interactable, trigger, crystal, enemyProjectile, grappleZone,
breakableWall, door, key, snackBag, softGround
```

## Important Creative Details (from Zig)
- Nono trees say "no no no" in chorus when you approach early, "go go go" when you're ready
- Yummy snack bags are gold bags with white smiley faces
- Wiz carries his staff with his tail
- Bob the Chicken is just a chicken among axolotls — he's vibing
- The game's ultimate villain is Queen Owarla (World 3 boss, not built yet)
- "Obliterate" is the preferred verb for defeating enemies
