# AxA — Build Plan

## Current Status: Stage 5 Complete ✅
Last updated: 2026-03-06

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

### Stage 5: World Completion ✅ COMPLETE
- [x] **5.1** Lake Shore West room (Room 5) — Water Level switch puzzle. Green→Blue→Red correct order drains flood overlays. Wrong order: red flash + reset.
- [x] **5.2** Nono Grove room (Room 6) — Ring of 12 nono trees. Gate check: Bob AND Wiz unlocked. DialogueNode: "NO! NO! NO!" / "GO! GO! GO!" typewriter effect, tap to advance.
- [x] **5.3** Monontoe boss fight (Room 7) — 3 phases: charge + chase / tail whip + Salt Knight summons / faster + ground slam shockwave. 12 HP boss health bar in HUD.
- [x] **5.4** ET unlock — post-Monontoe snack bag. ET is pale mint alien axolotl: Stun Touch (A), Float/speed boost (B), 4 HP. Alien-style oversized eyes, bioluminescent gill fronds.

### Stage 5 Extra: Axolotl Redesigns ✅ COMPLETE
- [x] Babeee: redesigned with proper gill frond stalks, stubby legs, sweeping tail — clearly axolotl
- [x] Wiz: redesigned as axolotl wizard — hat on center gill frond, gold staff, round purple body, legs, tail
- [x] Monontoe: 48×48 dark teal boss axolotl — dramatic 6 fronds, vertical slit pupils, wide tooth-filled mouth
- [x] ET: bioluminescent mint axolotl — 3 glowing frond tips, massive alien eyes, slender body

### Stage 6: Polish & Flow
- [ ] **6.1** Tablet UI — minimap, current quest, character roster, inventory. Opens on Y button.
- [ ] **6.2** Main menu + intro text + "World 1 Complete" screen + World 2 tease
- [x] **6.3** Dialogue system — DialogueNode: text box at screen bottom. Typewriter effect. Tap to advance. ✅ Done (used in NonoGrove)
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
| 5 | Lake Shore West | ✅ Built | 42×26 tiles, 3-switch water puzzle (G→B→R), flood overlays |
| 6 | Nono Grove | ✅ Built | 40×32 tiles, 12-tree ring, gate check (Bob+Wiz), dialogue |
| 7 | Monontoe's Lair | ✅ Built | 44×34 tiles, boss arena with pillars, 3-phase fight |

---

## Enemies Built

| Enemy | Status | Location | Notes |
|-------|--------|----------|-------|
| Salt Knight | ✅ Built | Rooms 2, 3 | Patrol + chase AI, 2 HP, 28×28 sprite, drops crystals |
| Salt Protector | ✅ Built | Room 4 | Ranged, frontal shield, 4 HP, 28×28 sprite |
| Monontoe | ✅ Built | Room 7 | 3-phase boss: charge+chase / tail whip+summons / ground slam, 12 HP |

---

## Characters Built

| Character | Status | Unlock Method | Abilities |
|-----------|--------|---------------|-----------|
| Babeee | ✅ Playable | **STARTER** (Zig's design) | Tail Slap (A, very short range), Tiny Rush (B, dash + brief invincibility) |
| Bob the Chicken | ✅ Playable | Snack bag in Salt Cave | Peck (A, 0.3s), Flutter Dash (B), Dig (B on soft ground) |
| Wiz | ✅ Playable | Snack bag in Crystal Fields | Staff Swing (A, medium range), Grapple Hook (B near posts) |
| ET | ✅ Playable | Snack bag in Monontoe's Lair (post-boss) | Stun Touch (A, 0.5s cooldown), Float (B, speed boost + hover) |

---

## Definition of Done (World 1)

- [x] Babeee is the starter character (Zig's decision)
- [x] Bob the Chicken unlockable and playable (Salt Cave snack bag)
- [x] Wiz unlockable and playable (Crystal Fields snack bag)
- [x] Virtual joystick and attack button work reliably
- [x] Salt Knights patrol and can be fought/defeated
- [x] Salt Protectors have shields and throw projectiles
- [x] Broken Bridge puzzle works with grappling hook
- [x] Water Level puzzle works with switches (green→blue→red, flood drains)
- [x] Salt Cave has locked door + key (snack bag behind door)
- [x] Snack bags unlock characters with celebration
- [x] Character switching works between all unlocked characters (Babeee/Bob/Wiz/ET)
- [x] Each character has distinct attack and B-button ability
- [x] Nono Trees block exit until Bob AND Wiz are unlocked
- [x] Nono Trees chant "no no no" / "go go go" appropriately (DialogueNode)
- [x] Monontoe boss fight has 3 phases (charge/tail whip+summons/ground slam)
- [ ] Game saves progress
- [ ] Main menu exists
- [ ] Runs smoothly on iPad
