# AxA — Build Plan

## Current Status: World Overhaul Complete ✅
Last updated: 2026-03-04

---

## Build Priority Order

### Stage 1: Foundation ✅ COMPLETE
- [x] **1.1** Xcode project setup — SpriteKit template, landscape, asset catalog structure
- [x] **1.2** Tile map — Salt World Lake Room 1 (Spawn Beach) using SKTileMapNode. Pink salt ground, water, crystals, nono trees as obstacles.
- [x] **1.3** Player movement — Wiz walking with virtual joystick. Camera follows. Wall/water collision.
- [x] **1.4** Room transitions — Moving between connected rooms via screen-edge triggers.

### Stage 2: Combat ✅ COMPLETE
- [x] **2.1** Wiz attack animation + hit detection
- [x] **2.2** Salt Knight enemy — patrol AI, health, damage, death, drops
- [x] **2.3** HUD — Health bar, crystal count, character portrait
- [x] **2.4** Player damage + knockback + death/respawn

### Stage 3: Puzzles & Exploration ✅ COMPLETE
- [x] **3.1** Broken Bridge puzzle — grappling hook mechanic for Wiz (Lake Shore East, Room 3)
- [x] **3.2** Salt Cave room — indoor tileset, darker palette, tight corridors (Room 4)
- [x] **3.3** Salt Protector enemy — ranged crystal projectiles, frontal shield mechanic
- [x] **3.4** Breakable salt crystal walls + hidden golden key + locked door

### Stage 4: Character System ✅ COMPLETE
- [x] **4.1** Snack Bag system — gold bag with white smiley face, open reveal animation, light shaft effect
- [x] **4.2** Bob the Chicken unlock — Bob emerges from snack bag in the Salt Cave with a celebration sequence
- [x] **4.3** Character switching — tap portrait on HUD. Sparkle effect. Each character keeps own HP.
- [x] **4.4** Bob's abilities — Peck attack (short range, 0.3s cooldown), Flutter Dash (quick burst on B), Dig (press B on soft ground to find hidden crystals)

### World Overhaul (Zig's Playtest Feedback) ✅ COMPLETE
- [x] **W.1** Fixed scene size to 960×640 — game is now visually 2× larger on iPad (was using device bounds which made everything tiny)
- [x] **W.2** Tile size 16→32pt — all sprites and environments proportionally doubled
- [x] **W.3** All 4 rooms expanded: Beach 38×26, Crystal 44×28, Lake Shore 40×24, Salt Cave 36×28
- [x] **W.4** Nono trees now have faces: eyes and worried mouth in tile texture
- [x] **W.5** Salt rock tile type — outdoor blocking rock formations with highlight
- [x] **W.6** Enemy sprites 16×16→28×28 (Salt Knight + Salt Protector)
- [x] **W.7** Crystal collectibles 8→20pt, more visible
- [x] **W.8** Grapple posts 16→32pt with updated detection radius
- [x] **W.9** Babeee is now the STARTER character (Zig's explicit design decision)
  - Babeee: Tail Slap (A button), Tiny Rush (B button — brief invincibility + dash)
  - Bob: first unlock from Salt Cave snack bag (unchanged)
  - Wiz: NEW second unlock — snack bag in Crystal Fields, col 40 row 14
- [x] **W.10** 6 Salt Knights in Crystal Fields (was 4), better spread across expanded room

### Stage 5: World Completion
- [ ] **5.1** Lake Shore West room (Room 5) — Water Level switch puzzle. Three crystal switches, correct order lowers water. Wrong order resets. Colour hint on wall.
- [ ] **5.2** Nono Grove room (Room 6) — Ring of nono trees. Gate check: all rooms cleared? Trees chant "no no no" / "go go go". Dialogue system needed.
- [ ] **5.3** Monontoe boss fight (Room 7) — 3 phases: charge/dodge, summons Salt Knights + tail whip, faster + ground slam shockwave.
- [ ] **5.4** Babeee SECOND unlock — post-Monontoe reward snack bag with celebration (Babeee is starter so this is now a "reward" moment, perhaps unlocking a secret ability or cosmetic)

### Stage 6: Polish & Flow
- [ ] **6.1** Tablet UI — minimap, current quest, character roster, inventory. Opens on Y button.
- [ ] **6.2** Main menu + intro text + "World 1 Complete" screen + World 2 tease
- [ ] **6.3** Dialogue system — text box at screen bottom. Portrait left, text right. Typewriter effect. Tap to advance.
- [ ] **6.4** Save system — auto-save on room transition + key events using UserDefaults or JSON
- [ ] **6.5** Audio — royalty-free 8-bit/chiptune SFX and music. Build silent first with system ready for drop-in.
- [ ] **6.6** Polish — screen shake on hits, particle sparkles on collection/unlock, death animations, crystal sparkle trails

---

## Rooms Built

| Room | Name | Status | Notes |
|------|------|--------|-------|
| 1 | Spawn Beach | ✅ Built | 38×26 tiles, 10 nono trees w/ faces, 12 crystals, salt rocks |
| 2 | Crystal Fields | ✅ Built | 44×28 tiles, 6 Salt Knights, Wiz snack bag (col 40 row 14) |
| 3 | Lake Shore East | ✅ Built | 40×24 tiles, broken bridge gap cols 14-24, 2 grapple posts at col 13 |
| 4 | Salt Cave | ✅ Built | 36×28 tiles, 2 Salt Protectors, key, locked door, Bob snack bag, 2 dig spots |
| 5 | Lake Shore West | ⬜ Not built | Water level switches puzzle |
| 6 | Nono Grove | ⬜ Not built | Gate check, "no no no"/"go go go" dialogue |
| 7 | Monontoe's Lair | ⬜ Not built | 3-phase boss arena |

---

## Enemies Built

| Enemy | Status | Location | Notes |
|-------|--------|----------|-------|
| Salt Knight | ✅ Built | Rooms 2, 3 | Patrol + chase AI, 2 HP, 28×28 sprite, drops crystals |
| Salt Protector | ✅ Built | Room 4 | Ranged, frontal shield, 4 HP, 28×28 sprite |
| Monontoe | ⬜ Not built | Room 7 | 3-phase boss |

---

## Characters Built

| Character | Status | Unlock Method | Abilities |
|-----------|--------|---------------|-----------|
| Babeee | ✅ Playable | **STARTER** (Zig's design) | Tail Slap (A, very short range), Tiny Rush (B, dash + brief invincibility) |
| Bob the Chicken | ✅ Playable | Snack bag in Salt Cave | Peck (A, 0.3s), Flutter Dash (B), Dig (B on soft ground) |
| Wiz | ✅ Playable | Snack bag in Crystal Fields | Staff Swing (A, medium range), Grapple Hook (B near posts) |
| ET | ⬜ Design pending | TBD — awaiting Zig's input | TBD |

---

## Definition of Done (World 1)

- [x] Babeee is the starter character (Zig's decision)
- [x] Bob the Chicken unlockable and playable (Salt Cave snack bag)
- [x] Wiz unlockable and playable (Crystal Fields snack bag)
- [x] Virtual joystick and attack button work reliably
- [x] Salt Knights patrol and can be fought/defeated
- [x] Salt Protectors have shields and throw projectiles
- [x] Broken Bridge puzzle works with grappling hook
- [ ] Water Level puzzle works with switches
- [x] Salt Cave has locked door + key (snack bag behind door)
- [x] Snack bags unlock characters with celebration
- [x] Character switching works between all unlocked characters
- [x] Each character has distinct attack and B-button ability
- [ ] Nono Trees block exit until all challenges complete
- [ ] Nono Trees chant "no no no" / "go go go" appropriately
- [ ] Monontoe boss fight has 3 phases
- [ ] Game saves progress
- [ ] Main menu exists
- [ ] Runs smoothly on iPad
