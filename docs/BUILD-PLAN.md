# AxA — Build Plan

## Build Priority Order

Build in this order so there's a playable game at each stage.

### Stage 1: Foundation
- [ ] **1.1** Xcode project setup — SpriteKit template, landscape, asset catalog structure
- [ ] **1.2** Tile map — Salt World Lake Room 1 (Spawn Beach) using SKTileMapNode. Pink salt ground, water, crystals, nono trees as obstacles.
- [ ] **1.3** Player movement — Wiz walking with virtual joystick. Camera follows. Wall/water collision.
- [ ] **1.4** Room transitions — Moving between connected rooms via screen-edge triggers.

### Stage 2: Combat
- [ ] **2.1** Wiz attack animation + hit detection
- [ ] **2.2** Salt Knight enemy — patrol AI, health, damage, death, drops
- [ ] **2.3** HUD — Health bar, crystal count, character portrait
- [ ] **2.4** Player damage + knockback + death/respawn

### Stage 3: Puzzles & Exploration
- [ ] **3.1** Broken Bridge puzzle — grappling hook mechanic for Wiz
- [ ] **3.2** Salt Cave room — indoor tileset, darker palette, tight corridors
- [ ] **3.3** Salt Protector enemy — ranged attacks, shield mechanic
- [ ] **3.4** Breakable walls + hidden key + locked door

### Stage 4: Character System
- [ ] **4.1** Snack Bag system — collectible bags, open animation
- [ ] **4.2** Bob the Chicken unlock + celebration
- [ ] **4.3** Character switching — swap between Wiz and Bob
- [ ] **4.4** Bob's unique attacks (peck) and abilities (flutter jump, dig)

### Stage 5: World Completion
- [ ] **5.1** Water Level switch puzzle (Room 5)
- [ ] **5.2** Nono Trees — gate check logic + "no no no" / "go go go" dialogue
- [ ] **5.3** Monontoe boss fight — 3 phases
- [ ] **5.4** Babeee unlock — post-boss reward

### Stage 6: Polish & Flow
- [ ] **6.1** Tablet UI — map, inventory, character roster
- [ ] **6.2** Main menu + intro + world complete screen
- [ ] **6.3** Dialogue system — typewriter text boxes
- [ ] **6.4** Save system — auto-save on room transition + key events
- [ ] **6.5** Audio — music and SFX (or silent placeholder)
- [ ] **6.6** Polish — screen shake, particles, death animations, sparkles

---

## Definition of Done (World 1)

- [ ] Wiz walks around all 7 rooms of Salt World Lake
- [ ] Virtual joystick and attack button work reliably
- [ ] Salt Knights patrol and can be fought/defeated
- [ ] Salt Protectors have shields and throw projectiles
- [ ] Broken Bridge puzzle works with grappling hook
- [ ] Water Level puzzle works with switches
- [ ] Salt Cave has locked door + key + snack bag
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
