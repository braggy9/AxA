import SpriteKit

// MARK: - Direction

enum FacingDirection {
    case up, down, left, right

    /// Returns the direction closest to the given vector.
    static func from(vector: CGVector) -> FacingDirection {
        if abs(vector.dx) > abs(vector.dy) {
            return vector.dx > 0 ? .right : .left
        } else {
            return vector.dy > 0 ? .up : .down
        }
    }

    /// Unit vector pointing in this direction.
    var unitVector: CGVector {
        switch self {
        case .right: return CGVector(dx:  1, dy:  0)
        case .left:  return CGVector(dx: -1, dy:  0)
        case .up:    return CGVector(dx:  0, dy:  1)
        case .down:  return CGVector(dx:  0, dy: -1)
        }
    }
}

// MARK: - PlayerNode
// Represents Wiz. Uses placeholder coloured shapes until real sprites arrive.
// Swap out `buildPlaceholderSprite()` with texture loading once assets exist.

final class PlayerNode: SKNode {

    // MARK: Movement State

    private(set) var facing: FacingDirection = .down

    let sprite: SKSpriteNode
    private var walkFrames: [SKTexture] = []
    private var idleFrames: [SKTexture] = []

    // MARK: Combat State

    var maxHealth: Int = PlayerCombatConst.maxHealth
    var currentHealth: Int = PlayerCombatConst.maxHealth

    /// True during invincibility frames (briefly after being hit)
    private(set) var isInvincible: Bool = false

    private var attackCooldownRemaining: TimeInterval = 0
    private var attackHitbox: SKSpriteNode?

    /// Called whenever health changes. Args: (current, max)
    var onHealthChanged: ((Int, Int) -> Void)?

    // MARK: Init

    override init() {
        sprite = PlayerNode.buildPlaceholderSprite()
        super.init()

        addChild(sprite)
        setupPhysics()
        zPosition = ZPos.player
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: Movement

    /// Call each frame from the scene's update loop.
    /// `delta` is time since last update. `direction` is normalised joystick vector.
    func move(direction: CGVector, delta: TimeInterval) {
        // Tick down attack cooldown
        if attackCooldownRemaining > 0 {
            attackCooldownRemaining -= delta
        }

        guard direction != .zero else {
            stopWalking()
            return
        }

        let dx = direction.dx * PlayerConst.walkSpeed * delta
        let dy = direction.dy * PlayerConst.walkSpeed * delta
        position = CGPoint(x: position.x + dx, y: position.y + dy)

        let newFacing = FacingDirection.from(vector: direction)
        if newFacing != facing {
            facing = newFacing
            updateSpriteOrientation()
            // Reposition attack hitbox offset to new facing direction if active
            updateHitboxPosition()
        }

        startWalking()
    }

    // MARK: Combat — Attack

    /// Triggered by the attack button. Does nothing if on cooldown.
    func performAttack() {
        guard attackCooldownRemaining <= 0 else { return }
        attackCooldownRemaining = PlayerCombatConst.attackCooldown

        // Create hitbox or reuse existing
        let hitbox: SKSpriteNode
        if let existing = attackHitbox {
            hitbox = existing
        } else {
            hitbox = SKSpriteNode(color: .clear, size: PlayerCombatConst.attackHitboxSize)
            hitbox.name = "attackHitbox"
            addChild(hitbox)
            attackHitbox = hitbox
        }

        // Position ahead of player in facing direction
        updateHitboxPosition()

        // Enable physics contact
        let hitboxBody = SKPhysicsBody(rectangleOf: PlayerCombatConst.attackHitboxSize)
        hitboxBody.isDynamic = false
        hitboxBody.affectedByGravity = false
        hitboxBody.categoryBitMask    = PhysicsCategory.projectile
        hitboxBody.collisionBitMask   = PhysicsCategory.none
        hitboxBody.contactTestBitMask = PhysicsCategory.enemy
        hitbox.physicsBody = hitboxBody
        hitbox.alpha = 1

        // Small visual swing
        let swingOut = SKAction.move(by: CGVector(dx: facing.unitVector.dx * 4,
                                                   dy: facing.unitVector.dy * 4),
                                      duration: 0.08)
        let swingBack = SKAction.move(by: CGVector(dx: facing.unitVector.dx * -4,
                                                    dy: facing.unitVector.dy * -4),
                                       duration: 0.08)
        sprite.run(.sequence([swingOut, swingBack]), withKey: "swing")

        // Disable hitbox after active duration
        let wait = SKAction.wait(forDuration: PlayerCombatConst.attackActiveDuration)
        let disable = SKAction.run { [weak hitbox] in
            hitbox?.physicsBody = nil
            hitbox?.alpha = 0
        }
        hitbox.run(.sequence([wait, disable]), withKey: "hitboxLifetime")
    }

    // MARK: Combat — Take Damage

    func takeDamage(_ amount: Int, from direction: CGVector) {
        guard !isInvincible && currentHealth > 0 else { return }

        currentHealth = max(0, currentHealth - amount)
        onHealthChanged?(currentHealth, maxHealth)

        if currentHealth <= 0 {
            die()
            return
        }

        // Knockback
        if let body = physicsBody {
            let len = hypot(direction.dx, direction.dy)
            if len > 0 {
                let impulse = CGVector(
                    dx: direction.dx / len * PlayerCombatConst.knockbackForce,
                    dy: direction.dy / len * PlayerCombatConst.knockbackForce
                )
                body.applyImpulse(impulse)
            }
        }

        // Invincibility frames + hurt flash
        isInvincible = true
        let flashOn  = SKAction.colorize(with: .white, colorBlendFactor: 0.9, duration: 0.08)
        let flashOff = SKAction.colorize(withColorBlendFactor: 0, duration: 0.08)
        let flash    = SKAction.repeat(.sequence([flashOn, flashOff]),
                                       count: Int(PlayerCombatConst.invincibilityDuration / 0.16))
        let endInvincibility = SKAction.run { [weak self] in
            self?.isInvincible = false
            self?.sprite.colorBlendFactor = 0
        }
        sprite.run(.sequence([flash, endInvincibility]), withKey: "invincibility")
    }

    func die() {
        isInvincible = true  // prevent further damage during death
        let deathAnim = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.1, duration: PlayerCombatConst.respawnDelay * 0.6),
                SKAction.fadeOut(withDuration: PlayerCombatConst.respawnDelay * 0.6)
            ]),
            SKAction.wait(forDuration: PlayerCombatConst.respawnDelay * 0.4)
            // Scene will detect health == 0 and handle respawn/game over
        ])
        sprite.run(deathAnim)
    }

    // MARK: Animations

    private func startWalking() {
        guard sprite.action(forKey: "walk") == nil else { return }
        sprite.removeAction(forKey: "idle")
        // Placeholder: simple bob animation
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 1.5, duration: 0.1),
            SKAction.moveBy(x: 0, y: -1.5, duration: 0.1)
        ])
        sprite.run(.repeatForever(bob), withKey: "walk")
    }

    private func stopWalking() {
        guard sprite.action(forKey: "walk") != nil else { return }
        sprite.removeAction(forKey: "walk")
        sprite.position = .zero  // reset bob offset
    }

    private func updateSpriteOrientation() {
        // Flip sprite horizontally for left/right. Placeholder only — real sprites will
        // have directional frames.
        switch facing {
        case .right: sprite.xScale =  1
        case .left:  sprite.xScale = -1
        case .up, .down: sprite.xScale = 1
        }
    }

    // MARK: Helpers

    private func updateHitboxPosition() {
        guard let hitbox = attackHitbox else { return }
        let offset = PlayerCombatConst.attackHitboxOffset
        hitbox.position = CGPoint(
            x: facing.unitVector.dx * offset,
            y: facing.unitVector.dy * offset
        )
    }

    // MARK: Physics

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: PlayerConst.physicsRadius)
        body.categoryBitMask    = PhysicsCategory.player
        body.collisionBitMask   = PhysicsCategory.wall | PhysicsCategory.water
        body.contactTestBitMask = PhysicsCategory.trigger |
                                  PhysicsCategory.interactable |
                                  PhysicsCategory.crystal |
                                  PhysicsCategory.enemy
        body.allowsRotation = false
        body.linearDamping = 8
        physicsBody = body
    }

    // MARK: Placeholder Sprite
    // A purple axolotl-shaped blob with a tiny hat. Replace with real texture atlas later.

    private static func buildPlaceholderSprite() -> SKSpriteNode {
        let size = PlayerConst.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            // Body — purple oval
            c.setFillColor(Palette.wizBody.cgColor)
            c.fillEllipse(in: CGRect(x: 2, y: 2, width: 12, height: 10))

            // Hat — dark purple triangle on top
            c.setFillColor(Palette.wizHat.cgColor)
            let hat = CGMutablePath()
            hat.move(to: CGPoint(x: 8, y: 16))
            hat.addLine(to: CGPoint(x: 4, y: 8))
            hat.addLine(to: CGPoint(x: 12, y: 8))
            hat.closeSubpath()
            c.addPath(hat)
            c.fillPath()

            // Staff — gold line from tail (bottom right)
            c.setStrokeColor(Palette.wizStaff.cgColor)
            c.setLineWidth(1.5)
            c.move(to: CGPoint(x: 12, y: 2))
            c.addLine(to: CGPoint(x: 15, y: 6))
            c.strokePath()

            // Eyes — two white dots
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: 5, y: 6, width: 2, height: 2))
            c.fillEllipse(in: CGRect(x: 9, y: 6, width: 2, height: 2))
        }

        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest  // pixel art — no blur
        let node = SKSpriteNode(texture: tex, size: size)
        return node
    }
}
