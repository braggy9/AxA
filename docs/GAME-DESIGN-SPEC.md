# AxA — Game Design Specification

## Overview
**Game Name:** AxA
**Genre:** Top-down 2D adventure (Zelda-style)
**Platform:** iPad (primary), iPhone (secondary)
**Players:** Solo
**Art Style:** 16-bit pixel art

**One-Sentence Description:** Player is an axolotl who moves through worlds, solving puzzles and battling evil axolotl knights and protectors. Once a world is saved, the hero moves to the next world.

---

## Worlds

### World 1: Salt World Lake (BUILD THIS FIRST)
A giant lake with visible pink salt crystals. Ground is Himalayan pink salt coloured. Surrounded by **nono trees** — magical trees guarding the passage to the next world.

**Rooms/Screens:**
1. **Spawn Beach** — Starting area. Safe zone. Tutorial hints.
2. **Crystal Fields** — Open area, salt crystal formations. First enemies (Salt Knights).
3. **Lake Shore East** — Broken bridge puzzle. Wiz uses staff as grappling hook.
4. **Salt Cave** — Indoor, darker, tight corridors. Salt Protectors. Hidden snack bag with Bob the Chicken.
5. **Lake Shore West** — Water level switch puzzle.
6. **The Nono Grove** — Ring of nono trees. Block exit until all challenges complete. Chant "no no no" / "go go go".
7. **Monontoe's Lair** — Boss arena.

### World 2: Go-Go Forest (DESIGN ONLY)
Dense, thick forest. Hard to navigate, lots of secrets. Big river — water-type axolotls can cross, Wiz uses grappling hook on vines. New forest-themed enemies and puzzles.

### World 3: The Underworld (DESIGN ONLY)
Floor is black volcanic stone. Bushes made of liquid fire that drips occasionally (environmental hazard). Big temple to discover. Inside: final boss **Queen Owarla**. Underworld guardians have **blue fire swords** that look like dripping bright blue liquid fire.

---

## Playable Characters

### Wiz the Wizard Axolotl (STARTER)
- Purple axolotl, small wizard hat, carries staff with tail
- **Attack:** Staff swing (melee, medium range)
- **Special:** Staff converts to grappling hook (at grapple points) OR fires magic bolt
- **Puzzle Use:** Grappling hook for Broken Bridge

### Bob the Chicken (UNLOCK — Salt Cave snack bag)
- A chicken. Just a chicken among axolotls. He's vibing.
- **Attack:** Peck (melee, short range, fast)
- **Special:** Flutter-jump (short glide). Dig in soft ground to find hidden items.
- **Puzzle Use:** Digging finds hidden switches/items

### Babeee the Baby Axolotl (UNLOCK — defeat Monontoe)
- Tiny, cute baby axolotl. Big eyes. Smaller than others.
- **Attack:** Tail slap (very short range)
- **Special:** Fits through narrow passages. Can swim through shallow water.
- **Puzzle Use:** Access small passages for shortcuts/secrets (more relevant Worlds 2-3)

### Character Switching
- Start with Wiz only. Unlock others via snack bags or boss defeats.
- Switch anytime via Tablet UI or quick-switch (double-tap portrait on HUD).
- Switch happens in-place with sparkle effect.
- Each character retains own health.
- Game hints when specific character needed for puzzle.

---

## Enemies

### Salt Knight (World 1 — Standard)
- Basic melee, patrol route. 2 hits to defeat.
- Drops salt crystals. Pink/white palette.

### Salt Protector (World 1 — Tough)
- Ranged, throws salt crystal projectiles.
- 4 hits to defeat. Shield blocks frontal attacks (hit from side/behind).
- Drops salt crystals + occasional snack bag.

### Monontoe — World 1 Boss
Giant mutant axolotl.
- **Phase 1:** Charges at player. Dodge, hit from behind.
- **Phase 2 (50% HP):** Summons 2 Salt Knights. Adds tail whip.
- **Phase 3 (25% HP):** Faster, erratic. Ground slam = shockwave.

---

## Puzzles (World 1)

1. **Broken Bridge (Room 3):** Use grappling hook to swing across gap.
2. **Water Level Switches (Room 5):** Three crystal switches. Correct order lowers water. Wrong order resets. Hint: crystal colours match order on nearby wall.
3. **Salt Cave Key (Room 4):** Locked door blocks snack bag. Key hidden behind breakable salt crystal walls.

---

## Items & Collectibles

### Yummy Snack Bags
- Gold bags with white smiley faces
- Found hidden or dropped by tough enemies
- Opening: fun reveal animation (bag opens, light shines, item floats up)
- Contains: characters, health refills, power-ups, salt crystals

### Salt Crystals
- Basic collectible/currency. Dropped by enemies, found in world.
- Count on HUD. Use TBD (shop in future worlds or just score).

### The Tablet
- In-game menu: minimap, current quest, character roster, inventory
- Styled as futuristic tablet held by axolotl

---

## Controls (Touch)

- **Virtual Joystick (left):** 8-directional. Appears where thumb touches.
- **A Button:** Attack / primary
- **B Button:** Special ability
- **Y Button:** Open Tablet UI
- **Quick Switch:** Double-tap character portrait on HUD
- All targets at least 44pt x 44pt. This is for a 6-year-old.

---

## Dialogue System
- Text box at bottom of screen. Portrait left, text right.
- Typewriter effect. Tap to advance/skip.

---

## Game Flow — World 1

1. Main Menu > New Game > intro text
2. Spawn at Spawn Beach with Wiz. Tutorial prompts.
3. Crystal Fields > fight Salt Knights
4. Lake Shore East > Broken Bridge > grappling hook
5. Salt Cave > Salt Protectors > find key > snack bag > unlock Bob
6. Lake Shore West > Water Level puzzle
7. Nono Grove > "no no no" until all complete > "go go go!"
8. Monontoe boss fight (3 phases)
9. Victory > unlock Babeee > World 1 Complete > tease World 2
10. Main Menu or Free Roam

---

## Audio
- Royalty-free 8-bit/chiptune (freesound.org, opengameart.org)
- If sourcing is complex, build silent first with audio system ready for drop-in

---

## Save System
- Auto-save on room transition and key events
- Single save slot. UserDefaults or JSON file.
