# AxA — Build Plan

## Current Status: Stage 3 Complete ✅
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

### Stage 4: Character System — NEXT
- [ ] **4.1** Snack Bag system — gold bag with white smiley face, open reveal animation, light shaft effect
- [ ] **4.2** Bob the Chicken unlock — Bob emerges from snack bag in the Salt Cave with a celebration sequence
- [ ] **4.3** Character switching — double-tap portrait on HUD or dedicated swap button. Sparkle effect. Each character keeps own HP.
- [ ] **4.4** Bob's abilities — Peck attack (short range, fast), Flutter Jump (short glide on B), Dig (hold B on soft ground to find hidden items)

### Stage 5: World Completion
- [ ] **5.1** Lake Shore West room (Room 5) — Water Level switch puzzle. Three crystal switches, correct order lowers water. Wrong order resets. Colour hint on wall.
- [ ] **5.2** Nono Grove room (Room 6) — Ring of nono trees. Gate check: all rooms cleared? Trees chant "no no no" / "go go go". Dialogue system needed.
- [ ] **5.3** Monontoe boss fight (Room 7) — 3 phases: charge/dodge, summons Salt Knights + tail whip, faster + ground slam shockwave.
- [ ] **5.4** Babeee unlock — post-Monontoe reward. Tiny baby axolotl from snack bag with celebration.

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
| 1 | Spawn Beach | ✅ Built | Starting area, safe zone, nono trees as obstacles |
| 2 | Crystal Fields | ✅ Built | 4 Salt Knights, connects to Spawn Beach and Lake Shore East |
| 3 | Lake Shore East | ✅ Built | Broken bridge, grappling hook posts, 2 Salt Knights on far side |
| 4 | Salt Cave | ✅ Built | 2 Salt Protectors, breakable walls, key, locked door (Bob behind it) |
| 5 | Lake Shore West | ⬜ Not built | Water level switches puzzle |
| 6 | Nono Grove | ⬜ Not built | Gate check, "no no no"/"go go go" dialogue |
| 7 | Monontoe's Lair | ⬜ Not built | 3-phase boss arena |

---

## Enemies Built

| Enemy | Status | Location | Notes |
|-------|--------|----------|-------|
| Salt Knight | ✅ Built | Rooms 2, 3 | Patrol + chase AI, 2 HP, drops crystals |
| Salt Protector | ✅ Built | Room 4 | Ranged, frontal shield, 4 HP |
| Monontoe | ⬜ Not built | Room 7 | 3-phase boss |

---

## Characters Built

| Character | Status | Unlock Method |
|-----------|--------|---------------|
| Wiz | ✅ Playable | Starter |
| Bob the Chicken | ⬜ Not built | Snack bag in Salt Cave (Stage 4) |
| Babeee | ⬜ Not built | Defeat Monontoe (Stage 5) |

---

## Definition of Done (World 1)

- [x] Wiz walks around all 7 rooms — 4/7 rooms built
- [x] Virtual joystick and attack button work reliably
- [x] Salt Knights patrol and can be fought/defeated
- [x] Salt Protectors have shields and throw projectiles
- [x] Broken Bridge puzzle works with grappling hook
- [ ] Water Level puzzle works with switches
- [x] Salt Cave has locked door + key (snack bag behind door — Stage 4)
- [ ] Snack bag unlocks Bob the Chicken with celebration
- [ ] Character switching works between Wiz and Bob
- [ ] Bob has distinct attack (peck) and ability (flutter jump, dig)
- [ ] Nono Trees block exit until all challenges complete
- [ ] Nono Trees chant "no no no" / "go go go" appropriately
- [ ] Monontoe boss fight has 3 phases
- [ ] Defeating Monontoe unlocks Babeee
- [ ] Game saves progress
- [ ] Main menu exists
- [ ] Runs smoothly on iPad
