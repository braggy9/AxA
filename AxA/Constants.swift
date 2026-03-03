// Constants.swift
// AxA — all magic numbers live here. Never hardcode these elsewhere.

import SpriteKit

// MARK: - Screen / World

enum World {
    /// Tile size in logical pixels.
    static let tileSize: CGFloat = 32

    /// Spawn Beach map dimensions (in tiles)
    static let spawnBeachCols: Int = 38
    static let spawnBeachRows: Int = 26
}

// MARK: - World (Crystal Fields)

extension World {
    static let crystalFieldsCols: Int = 44
    static let crystalFieldsRows: Int = 28
}

// MARK: - World (Lake Shore East)

extension World {
    static let lakeShoreEastCols: Int = 40
    static let lakeShoreEastRows: Int = 24
}

// MARK: - World (Salt Cave)

extension World {
    static let saltCaveCols: Int = 36
    static let saltCaveRows: Int = 28
}

// MARK: - Physics Categories

enum PhysicsCategory {
    static let none:           UInt32 = 0
    static let player:         UInt32 = 1 << 0  // 1
    static let enemy:          UInt32 = 1 << 1  // 2
    static let projectile:     UInt32 = 1 << 2  // 4
    static let wall:           UInt32 = 1 << 3  // 8
    static let water:          UInt32 = 1 << 4  // 16
    static let interactable:   UInt32 = 1 << 5  // 32
    static let trigger:        UInt32 = 1 << 6  // 64
    static let crystal:        UInt32 = 1 << 7  // 128
    static let enemyProjectile: UInt32 = 1 << 8
    static let grappleZone:    UInt32 = 1 << 9
    static let breakableWall:  UInt32 = 1 << 10
    static let door:           UInt32 = 1 << 11
    static let key:            UInt32 = 1 << 12
    static let snackBag:       UInt32 = 1 << 13
    static let softGround:     UInt32 = 1 << 14
}

// MARK: - Player

enum PlayerConst {
    static let walkSpeed: CGFloat = 160         // points per second
    static let size: CGSize = CGSize(width: 28, height: 28)
    static let physicsRadius: CGFloat = 11
    static let zPosition: CGFloat = 10
    static let animFrameDuration: TimeInterval = 0.15
}

// MARK: - Player Combat Constants

enum PlayerCombatConst {
    static let maxHealth = 5
    static let attackCooldown: TimeInterval = 0.5
    static let attackHitboxSize = CGSize(width: 40, height: 32)
    static let attackHitboxOffset: CGFloat = 22
    static let attackActiveDuration: TimeInterval = 0.2
    static let attackDamage = 1
    static let invincibilityDuration: TimeInterval = 1.5
    static let knockbackForce: CGFloat = 380
    static let respawnDelay: TimeInterval = 1.5
}

// MARK: - Camera

enum CameraConst {
    /// How tightly the camera tracks the player (0 = instant, 1 = never catches up)
    static let followSmoothing: CGFloat = 0.12
}

// MARK: - Virtual Joystick

enum JoystickConst {
    static let baseRadius: CGFloat = 70
    static let knobRadius: CGFloat = 35
    static let maxDisplacement: CGFloat = 58
    static let alpha: CGFloat = 0.75
    static let baseColour = SKColor(red: 1, green: 1, blue: 1, alpha: 0.25)
    static let knobColour = SKColor(red: 1, green: 1, blue: 1, alpha: 0.55)
    /// Distance from left/bottom edge of screen, in points
    static let xOffset: CGFloat = 120
    static let yOffset: CGFloat = 120
    static let zPosition: CGFloat = 100
}

// MARK: - Buttons

enum ButtonConst {
    static let size: CGFloat = 72
    static let attackAlpha: CGFloat = 0.75
    static let xOffsetFromRight: CGFloat = 100
    static let yOffsetFromBottom: CGFloat = 120
    static let zPosition: CGFloat = 100
}

// MARK: - Special Button

enum SpecialButtonConst {
    static let size: CGFloat = 72
    static let xOffsetFromRight: CGFloat = 185
    static let yOffsetFromBottom: CGFloat = 120
    static let zPosition: CGFloat = 100
}

// MARK: - Tile

enum TileConst {
    // Z-layers
    static let groundZ: CGFloat = 0
    static let detailZ: CGFloat = 1
    static let objectZ: CGFloat = 2
}

// MARK: - HUD Constants

enum HUDConst {
    static let healthBarWidth: CGFloat = 130
    static let healthBarHeight: CGFloat = 14
    static let healthBarX: CGFloat = -370   // relative to camera centre
    static let healthBarY: CGFloat = 290    // relative to camera centre
    static let crystalCounterX: CGFloat = -370
    static let crystalCounterY: CGFloat = 268
    static let portraitSize: CGFloat = 44
    static let portraitX: CGFloat = -432
    static let portraitY: CGFloat = 291
}

// MARK: - Room Constants

enum RoomConst {
    static let transitionTriggerWidth: CGFloat = 16
    static let transitionFadeDuration: TimeInterval = 0.3
}

// MARK: - Enemy Constants

enum EnemyConst {
    static let saltKnightHealth = 2
    static let patrolSpeed: CGFloat = 60
    static let chaseSpeed: CGFloat = 110
    static let chaseRadius: CGFloat = 180
    static let waypointTolerance: CGFloat = 9
    static let damage = 1
    static let knockback: CGFloat = 350
    static let crystalDropMin = 1
    static let crystalDropMax = 3

    // Legacy aliases kept so AIStates compile without changes
    static let saltKnightPatrolSpeed: CGFloat = patrolSpeed
    static let saltKnightChaseSpeed: CGFloat = chaseSpeed
    static let saltKnightChaseRadius: CGFloat = chaseRadius
    static let saltKnightWaypointTolerance: CGFloat = waypointTolerance
    static let saltKnightDamage = damage
    static let saltKnightKnockback: CGFloat = knockback
}

// MARK: - Salt Protector

enum ProtectorConst {
    static let health              = 4
    static let patrolSpeed: CGFloat = 50
    static let chaseRadius: CGFloat = 200
    static let shootInterval: TimeInterval = 2.2
    static let projectileSpeed: CGFloat = 180
    static let damage              = 1
    static let knockback: CGFloat  = 340
    static let shieldAngleDeg: CGFloat = 70
}

// MARK: - Grapple Hook

enum GrappleConst {
    static let detectionRadius:  CGFloat = 60
    static let ropeDrawDuration: TimeInterval = 0.15
    static let zipDuration:      TimeInterval = 0.35
    static let postSize:         CGFloat = 32
}

// MARK: - Bob Constants

enum BobConst {
    static let maxHealth                  = 4
    static let peckCooldown: TimeInterval = 0.3
    static let peckHitboxSize             = CGSize(width: 28, height: 24)
    static let peckHitboxOffset: CGFloat  = 18
    static let flutterDistance: CGFloat   = 90
    static let flutterDuration: TimeInterval = 0.22
}

// MARK: - Babeee Constants

enum BabeeConst {
    static let maxHealth                         = 3
    static let tailSlapCooldown: TimeInterval    = 0.45
    static let tailSlapHitboxSize                = CGSize(width: 22, height: 18)
    static let tailSlapHitboxOffset: CGFloat     = 8
    static let rushDistance: CGFloat             = 110
    static let rushDuration: TimeInterval        = 0.22
    static let rushInvincibilityDuration: TimeInterval = 0.4
}

// MARK: - Snack Bag

enum SnackBagConst {
    static let size                       = CGSize(width: 28, height: 28)
    static let floatAmplitude: CGFloat    = 3
    static let floatDuration: TimeInterval = 0.85
    static let openAnimDuration: TimeInterval = 0.55
}

// MARK: - Soft Ground (Bob dig spots)

enum SoftGroundConst {
    static let size                       = CGSize(width: 28, height: 20)
    static let detectionRadius: CGFloat   = 28
    static let digDuration: TimeInterval  = 0.5
    static let crystalReward              = 3
}

// MARK: - Enemy Projectile

enum EnemyProjectileConst {
    static let size = CGSize(width: 12, height: 12)
    static let lifetime: TimeInterval = 2.5
}

// MARK: - Character Types

enum CharacterType: String, CaseIterable {
    case wiz
    case bob
    case babeee
}

// MARK: - Colours (Salt World Lake palette)

enum Palette {
    static let saltGround    = SKColor(red: 0.94, green: 0.72, blue: 0.70, alpha: 1) // Himalayan pink
    static let saltSand      = SKColor(red: 0.99, green: 0.88, blue: 0.80, alpha: 1) // pale peach sand
    static let water         = SKColor(red: 0.35, green: 0.72, blue: 0.95, alpha: 1) // bright lake blue
    static let waterDeep     = SKColor(red: 0.20, green: 0.50, blue: 0.80, alpha: 1) // deeper water
    static let crystal       = SKColor(red: 1.00, green: 0.90, blue: 0.95, alpha: 1) // pink crystal
    static let nonoTreeTrunk = SKColor(red: 0.45, green: 0.28, blue: 0.12, alpha: 1) // brown
    static let nonoTreeLeaf  = SKColor(red: 0.20, green: 0.65, blue: 0.25, alpha: 1) // green
    static let wizBody       = SKColor(red: 0.60, green: 0.35, blue: 0.80, alpha: 1) // purple
    static let wizHat        = SKColor(red: 0.30, green: 0.15, blue: 0.55, alpha: 1) // dark purple
    static let wizStaff      = SKColor(red: 0.80, green: 0.65, blue: 0.30, alpha: 1) // gold
    static let saltRock      = SKColor(red: 0.78, green: 0.65, blue: 0.62, alpha: 1) // pinkish-grey rock
}

// MARK: - Cave Colours

extension Palette {
    static let caveFloor       = SKColor(red: 0.22, green: 0.18, blue: 0.25, alpha: 1)
    static let caveWall        = SKColor(red: 0.12, green: 0.10, blue: 0.14, alpha: 1)
    static let caveRock        = SKColor(red: 0.30, green: 0.25, blue: 0.35, alpha: 1)
    static let saltCrystalWall = SKColor(red: 0.80, green: 0.65, blue: 0.78, alpha: 1)
    static let keyGold         = SKColor(red: 1.00, green: 0.82, blue: 0.20, alpha: 1)
    static let lockedDoor      = SKColor(red: 0.45, green: 0.25, blue: 0.10, alpha: 1)
    static let grapplePost     = SKColor(red: 0.55, green: 0.38, blue: 0.18, alpha: 1)
    static let grappleRing     = SKColor(red: 0.75, green: 0.60, blue: 0.25, alpha: 1)
    static let ropeColour      = SKColor(red: 0.75, green: 0.60, blue: 0.35, alpha: 1)
    static let bridgeWater     = SKColor(red: 0.28, green: 0.58, blue: 0.82, alpha: 1)
}

// MARK: - Stage 4 Colours

extension Palette {
    static let bobBody      = SKColor(red: 0.98, green: 0.90, blue: 0.30, alpha: 1) // chicken yellow
    static let bobBeak      = SKColor(red: 0.95, green: 0.55, blue: 0.10, alpha: 1) // orange beak
    static let bobComb      = SKColor(red: 0.88, green: 0.12, blue: 0.12, alpha: 1) // red comb
    static let snackBagGold = SKColor(red: 0.95, green: 0.78, blue: 0.18, alpha: 1) // gold bag
    static let softDirt     = SKColor(red: 0.38, green: 0.28, blue: 0.18, alpha: 1) // dark soil
    static let celebSparkle = SKColor(red: 1.00, green: 0.90, blue: 0.30, alpha: 1) // celebration yellow
    static let babeeBody    = SKColor(red: 0.98, green: 0.78, blue: 0.85, alpha: 1) // pale pink
    static let babeeAccent  = SKColor(red: 0.95, green: 0.55, blue: 0.70, alpha: 1) // darker pink
}

// MARK: - Z-Positions (scene-level)

enum ZPos {
    static let ground: CGFloat = 0
    static let object: CGFloat = 2
    static let player: CGFloat = 10
    static let enemy:  CGFloat = 10
    static let hud:    CGFloat = 50
    static let ui:     CGFloat = 100
}
