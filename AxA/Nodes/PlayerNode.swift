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
// Represents the active playable character (Babeee, Bob, or Wiz).
// Character switching swaps visible sprites and adjusts stats.
// Each character retains its own health across switches and room transitions.

final class PlayerNode: SKNode {

    // MARK: - Character State

    var activeCharacter: CharacterType = .babeee {
        didSet { updateCharacterVisuals() }
    }
    var unlockedCharacters: Set<CharacterType> = [.babeee]

    /// Per-character health — persists across switches and room transitions.
    var babeeHealth: Int = BabeeConst.maxHealth
    var bobHealth: Int   = BobConst.maxHealth
    var wizHealth: Int   = PlayerCombatConst.maxHealth
    var etHealth: Int    = ETConst.maxHealth

    // MARK: - Movement State

    private(set) var facing: FacingDirection = .down

    private let babeeSprite: SKSpriteNode
    private let bobSprite:   SKSpriteNode
    private let wizSprite:   SKSpriteNode
    private let etSprite:    SKSpriteNode

    /// The currently active sprite — always matches activeCharacter.
    var sprite: SKSpriteNode {
        switch activeCharacter {
        case .babeee: return babeeSprite
        case .bob:    return bobSprite
        case .wiz:    return wizSprite
        case .et:     return etSprite
        }
    }

    // MARK: - Combat State

    var maxHealth: Int     = BabeeConst.maxHealth
    var currentHealth: Int = BabeeConst.maxHealth

    private(set) var isInvincible: Bool = false

    private var attackCooldownRemaining: TimeInterval = 0
    private var attackHitbox: SKSpriteNode?

    private var isFlutterDashing: Bool = false
    private var isRushing: Bool = false
    private var isFloating: Bool = false

    /// Called whenever health changes. Args: (current, max)
    var onHealthChanged: ((Int, Int) -> Void)?

    /// Called when the active character changes. Arg: new character.
    var onCharacterChanged: ((CharacterType) -> Void)?

    // MARK: - Init

    override init() {
        babeeSprite = PlayerNode.buildBabeeSprite()
        bobSprite   = PlayerNode.buildBobSprite()
        wizSprite   = PlayerNode.buildWizSprite()
        etSprite    = PlayerNode.buildETSprite()

        super.init()

        addChild(babeeSprite)
        bobSprite.isHidden   = true
        wizSprite.isHidden   = true
        etSprite.isHidden    = true
        addChild(bobSprite)
        addChild(wizSprite)
        addChild(etSprite)

        setupPhysics()
        zPosition = ZPos.player
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Character Switching

    func unlock(_ character: CharacterType) {
        unlockedCharacters.insert(character)
        switch character {
        case .babeee: babeeHealth = BabeeConst.maxHealth
        case .bob:    bobHealth   = BobConst.maxHealth
        case .wiz:    wizHealth   = PlayerCombatConst.maxHealth
        case .et:     etHealth    = ETConst.maxHealth
        }
    }

    func switchTo(character: CharacterType) {
        guard unlockedCharacters.contains(character), character != activeCharacter else { return }

        // Save outgoing health
        switch activeCharacter {
        case .babeee: babeeHealth = currentHealth
        case .bob:    bobHealth   = currentHealth
        case .wiz:    wizHealth   = currentHealth
        case .et:     etHealth    = currentHealth
        }

        activeCharacter = character   // triggers updateCharacterVisuals()

        // Restore incoming health
        switch character {
        case .babeee:
            maxHealth     = BabeeConst.maxHealth
            currentHealth = babeeHealth
        case .bob:
            maxHealth     = BobConst.maxHealth
            currentHealth = bobHealth
        case .wiz:
            maxHealth     = PlayerCombatConst.maxHealth
            currentHealth = wizHealth
        case .et:
            maxHealth     = ETConst.maxHealth
            currentHealth = etHealth
        }

        onHealthChanged?(currentHealth, maxHealth)
        onCharacterChanged?(character)
        playSwapEffect()
    }

    // MARK: - Movement

    /// Call each frame from the scene's update loop.
    func move(direction: CGVector, delta: TimeInterval) {
        if attackCooldownRemaining > 0 { attackCooldownRemaining -= delta }

        guard direction != .zero else {
            stopWalking()
            return
        }

        let speed = PlayerConst.walkSpeed
        position = CGPoint(x: position.x + direction.dx * speed * delta,
                           y: position.y + direction.dy * speed * delta)

        let newFacing = FacingDirection.from(vector: direction)
        if newFacing != facing {
            facing = newFacing
            updateSpriteOrientation()
            updateHitboxPosition()
        }

        startWalking()
    }

    // MARK: - Combat — Attack

    /// Triggered by the A button. Delegates to the active character's attack.
    func performAttack() {
        switch activeCharacter {
        case .babeee: performTailSlap()
        case .bob:    performPeck()
        case .wiz:    performStaffSwing()
        case .et:     performStunTouch()
        }
    }

    // Babeee tail slap — very short range, 0.45s cooldown
    private func performTailSlap() {
        guard attackCooldownRemaining <= 0 else { return }
        attackCooldownRemaining = BabeeConst.tailSlapCooldown

        fireHitbox(size: BabeeConst.tailSlapHitboxSize,
                   offset: BabeeConst.tailSlapHitboxOffset)

        // Tiny rear-swing animation
        let slapOut  = SKAction.move(by: CGVector(dx: facing.unitVector.dx * 3,
                                                   dy: facing.unitVector.dy * 3), duration: 0.07)
        let slapBack = SKAction.move(by: CGVector(dx: facing.unitVector.dx * -3,
                                                   dy: facing.unitVector.dy * -3), duration: 0.07)
        sprite.run(.sequence([slapOut, slapBack]), withKey: "tailslap")
    }

    // Bob peck — short range, 0.3s cooldown
    private func performPeck() {
        guard attackCooldownRemaining <= 0 else { return }
        attackCooldownRemaining = BobConst.peckCooldown

        fireHitbox(size: BobConst.peckHitboxSize,
                   offset: BobConst.peckHitboxOffset)

        let jab  = SKAction.move(by: CGVector(dx: facing.unitVector.dx * 5,
                                               dy: facing.unitVector.dy * 5), duration: 0.06)
        let back = SKAction.move(by: CGVector(dx: facing.unitVector.dx * -5,
                                               dy: facing.unitVector.dy * -5), duration: 0.06)
        sprite.run(.sequence([jab, back]), withKey: "peck")
    }

    // Wiz staff swing — medium range, 0.5s cooldown
    private func performStaffSwing() {
        guard attackCooldownRemaining <= 0 else { return }
        attackCooldownRemaining = PlayerCombatConst.attackCooldown

        fireHitbox(size: PlayerCombatConst.attackHitboxSize,
                   offset: PlayerCombatConst.attackHitboxOffset)

        let swingOut  = SKAction.move(by: CGVector(dx: facing.unitVector.dx * 4,
                                                    dy: facing.unitVector.dy * 4), duration: 0.08)
        let swingBack = SKAction.move(by: CGVector(dx: facing.unitVector.dx * -4,
                                                    dy: facing.unitVector.dy * -4), duration: 0.08)
        sprite.run(.sequence([swingOut, swingBack]), withKey: "swing")
    }

    private func fireHitbox(size: CGSize, offset: CGFloat) {
        let hitbox: SKSpriteNode
        if let existing = attackHitbox {
            hitbox = existing
        } else {
            hitbox = SKSpriteNode(color: .clear, size: size)
            hitbox.name = "attackHitbox"
            addChild(hitbox)
            attackHitbox = hitbox
        }
        hitbox.size = size
        updateHitboxPosition(offset: offset)

        let hitboxBody = SKPhysicsBody(rectangleOf: size)
        hitboxBody.isDynamic        = false
        hitboxBody.affectedByGravity = false
        hitboxBody.categoryBitMask    = PhysicsCategory.projectile
        hitboxBody.collisionBitMask   = PhysicsCategory.none
        hitboxBody.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.breakableWall
        hitbox.physicsBody = hitboxBody
        hitbox.alpha = 1

        let wait    = SKAction.wait(forDuration: PlayerCombatConst.attackActiveDuration)
        let disable = SKAction.run { [weak hitbox] in
            hitbox?.physicsBody = nil
            hitbox?.alpha = 0
        }
        hitbox.run(.sequence([wait, disable]), withKey: "hitboxLifetime")
    }

    // MARK: - Babeee Special — Tiny Rush

    func performTinyRush() {
        guard !isRushing else { return }
        isRushing = true

        // Brief invincibility during rush
        isInvincible = true

        physicsBody?.isDynamic = false

        let dashVec = CGVector(dx: facing.unitVector.dx * BabeeConst.rushDistance,
                               dy: facing.unitVector.dy * BabeeConst.rushDistance)
        let dash = SKAction.moveBy(x: dashVec.dx, y: dashVec.dy,
                                   duration: BabeeConst.rushDuration)
        dash.timingMode = .easeOut

        // Squish + stretch visual
        let squish   = SKAction.scale(to: CGSize(width: 1.3, height: 0.75), duration: 0.05)
        let stretch  = SKAction.scale(to: CGSize(width: 0.8, height: 1.2), duration: 0.05)
        let restore  = SKAction.scale(to: CGSize(width: 1.0, height: 1.0), duration: 0.1)
        sprite.run(.sequence([squish, stretch, restore]), withKey: "rush")

        // Brief glow
        let glow    = SKAction.colorize(with: Palette.babeeAccent, colorBlendFactor: 0.7, duration: 0.05)
        let unglow  = SKAction.colorize(withColorBlendFactor: 0, duration: 0.2)
        sprite.run(.sequence([glow, unglow]))

        run(.sequence([
            dash,
            .run { [weak self] in
                self?.physicsBody?.isDynamic = true
                self?.isRushing = false
            },
            .wait(forDuration: BabeeConst.rushInvincibilityDuration - BabeeConst.rushDuration),
            .run { [weak self] in
                self?.isInvincible = false
                self?.sprite.colorBlendFactor = 0
            }
        ]), withKey: "tinyRush")
    }

    // MARK: - ET Attack — Stun Touch

    // ET stun touch — medium range, stuns enemies on hit, 0.5s cooldown
    private func performStunTouch() {
        guard attackCooldownRemaining <= 0 else { return }
        attackCooldownRemaining = ETConst.stunTouchCooldown

        fireHitbox(size: ETConst.stunTouchHitboxSize,
                   offset: ETConst.stunTouchHitboxOffset)

        // Pulsing glow animation
        let glow = SKAction.sequence([
            SKAction.colorize(with: Palette.etGlow, colorBlendFactor: 0.8, duration: 0.06),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.12)
        ])
        sprite.run(glow, withKey: "stunTouch")

        // Brief scale pulse
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.07),
            SKAction.scale(to: 1.0, duration: 0.10)
        ])
        sprite.run(pulse)
    }

    // MARK: - ET Special — Float

    func performFloat() {
        guard !isFloating else { return }
        isFloating = true

        // Speed boost + glow for duration
        let glowOn  = SKAction.colorize(with: Palette.etGlow, colorBlendFactor: 0.5, duration: 0.15)
        let glowOff = SKAction.colorize(withColorBlendFactor: 0, duration: 0.3)

        // Bobbing effect while floating
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 0.25),
            SKAction.moveBy(x: 0, y: -3, duration: 0.25)
        ])
        sprite.run(glowOn)
        sprite.run(.repeatForever(bob), withKey: "floatBob")

        run(.sequence([
            .wait(forDuration: ETConst.floatDuration),
            .run { [weak self] in
                self?.sprite.removeAction(forKey: "floatBob")
                self?.sprite.run(glowOff)
                self?.isFloating = false
            }
        ]), withKey: "float")
    }

    var isCurrentlyFloating: Bool { isFloating }

    // MARK: - Bob Special — Flutter Dash

    func performFlutterDash() {
        guard !isFlutterDashing else { return }
        isFlutterDashing = true

        physicsBody?.isDynamic = false

        let dashVec = CGVector(dx: facing.unitVector.dx * BobConst.flutterDistance,
                               dy: facing.unitVector.dy * BobConst.flutterDistance)
        let dash = SKAction.moveBy(x: dashVec.dx, y: dashVec.dy,
                                   duration: BobConst.flutterDuration)
        dash.timingMode = .easeOut

        // Wing-flap visual: quick scale wobble
        let flapUp   = SKAction.scale(to: CGSize(width: 1.2, height: 0.8), duration: 0.06)
        let flapDown = SKAction.scale(to: CGSize(width: 0.85, height: 1.15), duration: 0.06)
        let flapBack = SKAction.scale(to: CGSize(width: 1.0, height: 1.0), duration: 0.08)
        sprite.run(.sequence([flapUp, flapDown, flapBack]), withKey: "flap")

        run(.sequence([
            dash,
            .run { [weak self] in
                self?.physicsBody?.isDynamic = true
                self?.isFlutterDashing = false
            }
        ]), withKey: "flutter")
    }

    // MARK: - Combat — Take Damage

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
                body.applyImpulse(CGVector(
                    dx: direction.dx / len * PlayerCombatConst.knockbackForce,
                    dy: direction.dy / len * PlayerCombatConst.knockbackForce
                ))
            }
        }

        // Invincibility frames + hurt flash
        isInvincible = true
        let flashOn  = SKAction.colorize(with: .white, colorBlendFactor: 0.9, duration: 0.08)
        let flashOff = SKAction.colorize(withColorBlendFactor: 0, duration: 0.08)
        let flash    = SKAction.repeat(.sequence([flashOn, flashOff]),
                                       count: Int(PlayerCombatConst.invincibilityDuration / 0.16))
        let endIframes = SKAction.run { [weak self] in
            self?.isInvincible = false
            self?.sprite.colorBlendFactor = 0
        }
        sprite.run(.sequence([flash, endIframes]), withKey: "invincibility")
    }

    func die() {
        isInvincible = true
        let deathAnim = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.1, duration: PlayerCombatConst.respawnDelay * 0.6),
                SKAction.fadeOut(withDuration: PlayerCombatConst.respawnDelay * 0.6)
            ]),
            SKAction.wait(forDuration: PlayerCombatConst.respawnDelay * 0.4)
        ])
        sprite.run(deathAnim)
    }

    // MARK: - Animations

    private func startWalking() {
        guard sprite.action(forKey: "walk") == nil else { return }
        sprite.removeAction(forKey: "idle")
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 1.5, duration: 0.1),
            SKAction.moveBy(x: 0, y: -1.5, duration: 0.1)
        ])
        sprite.run(.repeatForever(bob), withKey: "walk")
    }

    private func stopWalking() {
        guard sprite.action(forKey: "walk") != nil else { return }
        sprite.removeAction(forKey: "walk")
        sprite.position = .zero
    }

    private func updateSpriteOrientation() {
        let scale: CGFloat = facing == .left ? -1 : 1
        sprite.xScale = scale
    }

    // MARK: - Character Visuals

    private func updateCharacterVisuals() {
        babeeSprite.isHidden = (activeCharacter != .babeee)
        bobSprite.isHidden   = (activeCharacter != .bob)
        wizSprite.isHidden   = (activeCharacter != .wiz)
        etSprite.isHidden    = (activeCharacter != .et)
        for s in [babeeSprite, bobSprite, wizSprite, etSprite] {
            s.removeAction(forKey: "walk")
            s.position = .zero
        }
    }

    private func playSwapEffect() {
        // Flash + bounce on the newly-active sprite
        let flash  = SKAction.sequence([
            SKAction.colorize(with: Palette.celebSparkle, colorBlendFactor: 0.9, duration: 0.07),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.15)
        ])
        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.35, duration: 0.08),
            SKAction.scale(to: 1.0,  duration: 0.12)
        ])
        sprite.run(flash)
        run(bounce, withKey: "swap")

        // Scatter small sparkle dots
        let colours: [SKColor] = [Palette.celebSparkle, .white, Palette.crystal]
        for i in 0..<6 {
            let angle = CGFloat(i) / 6.0 * .pi * 2
            let spark = SKSpriteNode(color: colours[i % colours.count],
                                     size: CGSize(width: 2.5, height: 2.5))
            spark.position = .zero
            spark.zPosition = ZPos.player + 2
            addChild(spark)
            let move = SKAction.moveBy(x: cos(angle) * 14, y: sin(angle) * 14, duration: 0.3)
            move.timingMode = .easeOut
            spark.run(.sequence([.group([move, .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
        }
    }

    // MARK: - Helpers

    private func updateHitboxPosition(offset: CGFloat = PlayerCombatConst.attackHitboxOffset) {
        guard let hitbox = attackHitbox else { return }
        hitbox.position = CGPoint(x: facing.unitVector.dx * offset,
                                  y: facing.unitVector.dy * offset)
    }

    private func updateHitboxPosition() {
        updateHitboxPosition(offset: PlayerCombatConst.attackHitboxOffset)
    }

    // MARK: - Physics

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: PlayerConst.physicsRadius)
        body.categoryBitMask    = PhysicsCategory.player
        body.collisionBitMask   = PhysicsCategory.wall | PhysicsCategory.water
        body.contactTestBitMask = PhysicsCategory.trigger    |
                                  PhysicsCategory.interactable |
                                  PhysicsCategory.crystal    |
                                  PhysicsCategory.enemy      |
                                  PhysicsCategory.enemyProjectile |
                                  PhysicsCategory.grappleZone |
                                  PhysicsCategory.key        |
                                  PhysicsCategory.door       |
                                  PhysicsCategory.snackBag   |
                                  PhysicsCategory.softGround
        body.allowsRotation = false
        body.linearDamping  = 8
        physicsBody = body
    }

    // MARK: - Placeholder Sprites

    private static func buildBabeeSprite() -> SKSpriteNode {
        let size = PlayerConst.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            let w = size.width, h = size.height

            // Tail — sweeping from left side (UIKit low y = SpriteKit visual bottom)
            c.setFillColor(Palette.babeeAccent.cgColor)
            let tail = UIBezierPath()
            tail.move(to: CGPoint(x: w * 0.18, y: h * 0.12))
            tail.addQuadCurve(to: CGPoint(x: w * -0.05, y: h * 0.06),
                               controlPoint: CGPoint(x: w * 0.04, y: h * 0.18))
            tail.addLine(to: CGPoint(x: w * 0.0, y: h * 0.02))
            tail.addQuadCurve(to: CGPoint(x: w * 0.22, y: h * 0.05),
                               controlPoint: CGPoint(x: w * 0.08, y: h * 0.14))
            tail.close()
            c.addPath(tail.cgPath)
            c.fillPath()

            // Chubby round body — pale pink
            c.setFillColor(Palette.babeeBody.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.10, y: h * 0.14, width: w * 0.80, height: h * 0.52))

            // Wide flat axolotl head (UIKit high y = SpriteKit visual top)
            c.fillEllipse(in: CGRect(x: w * 0.08, y: h * 0.50, width: w * 0.84, height: h * 0.42))

            // Subtle head belly marking
            c.setFillColor(UIColor(red: 1.00, green: 0.88, blue: 0.92, alpha: 0.7).cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.22, y: h * 0.52, width: w * 0.56, height: h * 0.20))

            // Stubby front legs
            c.setFillColor(Palette.babeeAccent.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.02, y: h * 0.26, width: w * 0.18, height: h * 0.12))
            c.fillEllipse(in: CGRect(x: w * 0.80, y: h * 0.26, width: w * 0.18, height: h * 0.12))

            // Gill fronds — 3 tall stalks on top of head (SpriteKit visual top)
            c.setFillColor(Palette.babeeAccent.cgColor)
            // Left frond: stalk + round tip
            c.fill(CGRect(x: w * 0.22, y: h * 0.82, width: w * 0.07, height: h * 0.14))
            c.fillEllipse(in: CGRect(x: w * 0.18, y: h * 0.91, width: w * 0.15, height: h * 0.14))
            // Centre frond (tallest)
            c.fill(CGRect(x: w * 0.46, y: h * 0.85, width: w * 0.07, height: h * 0.12))
            c.fillEllipse(in: CGRect(x: w * 0.42, y: h * 0.93, width: w * 0.15, height: h * 0.14))
            // Right frond
            c.fill(CGRect(x: w * 0.70, y: h * 0.82, width: w * 0.07, height: h * 0.14))
            c.fillEllipse(in: CGRect(x: w * 0.66, y: h * 0.91, width: w * 0.15, height: h * 0.14))

            // Big round eyes (baby-proportioned, high on head)
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.20, y: h * 0.60, width: w * 0.22, height: h * 0.20))
            c.fillEllipse(in: CGRect(x: w * 0.58, y: h * 0.60, width: w * 0.22, height: h * 0.20))

            // Pupils
            c.setFillColor(UIColor.black.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.26, y: h * 0.64, width: w * 0.11, height: h * 0.11))
            c.fillEllipse(in: CGRect(x: w * 0.64, y: h * 0.64, width: w * 0.11, height: h * 0.11))

            // Eye shine
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.29, y: h * 0.68, width: w * 0.05, height: h * 0.05))
            c.fillEllipse(in: CGRect(x: w * 0.67, y: h * 0.68, width: w * 0.05, height: h * 0.05))

            // Tiny smile arc
            c.setStrokeColor(UIColor(red: 0.75, green: 0.30, blue: 0.45, alpha: 1).cgColor)
            c.setLineWidth(1.5)
            c.move(to:    CGPoint(x: w * 0.34, y: h * 0.53))
            c.addQuadCurve(to: CGPoint(x: w * 0.66, y: h * 0.53),
                           control: CGPoint(x: w * 0.50, y: h * 0.45))
            c.strokePath()
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return SKSpriteNode(texture: tex, size: size)
    }

    private static func buildBobSprite() -> SKSpriteNode {
        let size = PlayerConst.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            let w = size.width, h = size.height

            // Body — yellow oval (chicken body)
            c.setFillColor(Palette.bobBody.cgColor)
            c.fillEllipse(in: CGRect(x: 2, y: 1, width: w - 4, height: h - 4))

            // Head — smaller circle on top
            c.fillEllipse(in: CGRect(x: 5, y: h - 8, width: 7, height: 7))

            // Red comb on top of head
            c.setFillColor(Palette.bobComb.cgColor)
            c.fillEllipse(in: CGRect(x: 6, y: h - 5, width: 3, height: 4))
            c.fillEllipse(in: CGRect(x: 8, y: h - 4, width: 2.5, height: 3))

            // Beak — orange triangle
            c.setFillColor(Palette.bobBeak.cgColor)
            let beak = CGMutablePath()
            beak.move(to:    CGPoint(x: 12, y: h - 4))
            beak.addLine(to: CGPoint(x: 15, y: h - 5.5))
            beak.addLine(to: CGPoint(x: 12, y: h - 7))
            beak.closeSubpath()
            c.addPath(beak)
            c.fillPath()

            // Eye — white dot then pupil
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: 9, y: h - 6, width: 3, height: 3))
            c.setFillColor(UIColor.black.cgColor)
            c.fillEllipse(in: CGRect(x: 10, y: h - 5.5, width: 1.5, height: 1.5))

            // Wing hint — slightly darker stripe
            c.setFillColor(SKColor(red: 0.80, green: 0.72, blue: 0.20, alpha: 0.7).cgColor)
            let wing = CGMutablePath()
            wing.move(to:    CGPoint(x: 3,  y: 7))
            wing.addLine(to: CGPoint(x: 9,  y: 9))
            wing.addLine(to: CGPoint(x: 8,  y: 5))
            wing.closeSubpath()
            c.addPath(wing)
            c.fillPath()
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return SKSpriteNode(texture: tex, size: size)
    }

    private static func buildWizSprite() -> SKSpriteNode {
        let size = PlayerConst.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            let w = size.width, h = size.height

            // Tail — purple squiggle at low UIKit y (SpriteKit visual bottom)
            c.setFillColor(SKColor(red: 0.50, green: 0.28, blue: 0.72, alpha: 1).cgColor)
            let tail = UIBezierPath()
            tail.move(to: CGPoint(x: w * 0.18, y: h * 0.12))
            tail.addQuadCurve(to: CGPoint(x: w * -0.04, y: h * 0.06),
                               controlPoint: CGPoint(x: w * 0.04, y: h * 0.20))
            tail.addLine(to: CGPoint(x: w * 0.02, y: h * 0.01))
            tail.addQuadCurve(to: CGPoint(x: w * 0.22, y: h * 0.06),
                               controlPoint: CGPoint(x: w * 0.10, y: h * 0.15))
            tail.close()
            c.addPath(tail.cgPath)
            c.fillPath()

            // Body — round purple axolotl
            c.setFillColor(Palette.wizBody.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.10, y: h * 0.14, width: w * 0.80, height: h * 0.52))

            // Wide flat head
            c.fillEllipse(in: CGRect(x: w * 0.08, y: h * 0.50, width: w * 0.84, height: h * 0.42))

            // Lighter belly marking
            c.setFillColor(SKColor(red: 0.75, green: 0.55, blue: 0.92, alpha: 0.65).cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.22, y: h * 0.52, width: w * 0.56, height: h * 0.20))

            // Stubby legs
            c.setFillColor(Palette.wizHat.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.02, y: h * 0.26, width: w * 0.18, height: h * 0.12))
            c.fillEllipse(in: CGRect(x: w * 0.80, y: h * 0.26, width: w * 0.18, height: h * 0.12))

            // Gill fronds — with a tiny wizard hat on the center frond
            c.setFillColor(Palette.wizHat.cgColor)
            // Left frond
            c.fill(CGRect(x: w * 0.22, y: h * 0.82, width: w * 0.07, height: h * 0.14))
            c.fillEllipse(in: CGRect(x: w * 0.18, y: h * 0.91, width: w * 0.15, height: h * 0.12))
            // Right frond
            c.fill(CGRect(x: w * 0.70, y: h * 0.82, width: w * 0.07, height: h * 0.14))
            c.fillEllipse(in: CGRect(x: w * 0.66, y: h * 0.91, width: w * 0.15, height: h * 0.12))
            // Center frond stalk
            c.fill(CGRect(x: w * 0.46, y: h * 0.82, width: w * 0.07, height: h * 0.14))
            // Wizard hat brim on center frond
            c.fill(CGRect(x: w * 0.34, y: h * 0.94, width: w * 0.32, height: h * 0.04))
            // Hat cone
            let hatPath = CGMutablePath()
            hatPath.move(to: CGPoint(x: w * 0.50, y: h * 1.04))
            hatPath.addLine(to: CGPoint(x: w * 0.37, y: h * 0.94))
            hatPath.addLine(to: CGPoint(x: w * 0.63, y: h * 0.94))
            hatPath.closeSubpath()
            c.addPath(hatPath)
            c.fillPath()
            // Star on hat
            c.setFillColor(Palette.wizStaff.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.46, y: h * 0.99, width: w * 0.08, height: h * 0.06))

            // Eyes
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.20, y: h * 0.60, width: w * 0.20, height: h * 0.18))
            c.fillEllipse(in: CGRect(x: w * 0.60, y: h * 0.60, width: w * 0.20, height: h * 0.18))
            c.setFillColor(UIColor.black.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.25, y: h * 0.64, width: w * 0.10, height: h * 0.10))
            c.fillEllipse(in: CGRect(x: w * 0.65, y: h * 0.64, width: w * 0.10, height: h * 0.10))
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.28, y: h * 0.67, width: w * 0.04, height: h * 0.04))
            c.fillEllipse(in: CGRect(x: w * 0.68, y: h * 0.67, width: w * 0.04, height: h * 0.04))

            // Slight wizard smile
            c.setStrokeColor(SKColor(red: 0.45, green: 0.20, blue: 0.65, alpha: 1).cgColor)
            c.setLineWidth(1.5)
            c.move(to:    CGPoint(x: w * 0.36, y: h * 0.53))
            c.addQuadCurve(to: CGPoint(x: w * 0.64, y: h * 0.53),
                           control: CGPoint(x: w * 0.50, y: h * 0.46))
            c.strokePath()

            // Gold staff — held out to right side
            c.setStrokeColor(Palette.wizStaff.cgColor)
            c.setLineWidth(2.2)
            c.move(to: CGPoint(x: w * 0.85, y: h * 0.20))
            c.addLine(to: CGPoint(x: w * 0.88, y: h * 0.44))
            c.strokePath()
            // Staff tip gem
            c.setFillColor(Palette.wizStaff.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.82, y: h * 0.16, width: w * 0.11, height: h * 0.10))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return SKSpriteNode(texture: tex, size: size)
    }

    private static func buildETSprite() -> SKSpriteNode {
        let size = PlayerConst.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            let w = size.width, h = size.height

            // Tail — mint green, slender
            c.setFillColor(Palette.etAccent.cgColor)
            let tail = UIBezierPath()
            tail.move(to: CGPoint(x: w * 0.20, y: h * 0.14))
            tail.addQuadCurve(to: CGPoint(x: w * -0.04, y: h * 0.08),
                               controlPoint: CGPoint(x: w * 0.05, y: h * 0.22))
            tail.addLine(to: CGPoint(x: w * 0.02, y: h * 0.02))
            tail.addQuadCurve(to: CGPoint(x: w * 0.24, y: h * 0.06),
                               controlPoint: CGPoint(x: w * 0.10, y: h * 0.16))
            tail.close()
            c.addPath(tail.cgPath)
            c.fillPath()

            // Body — slender pale mint axolotl
            c.setFillColor(Palette.etBody.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.12, y: h * 0.16, width: w * 0.76, height: h * 0.50))

            // Wide flat head
            c.fillEllipse(in: CGRect(x: w * 0.08, y: h * 0.50, width: w * 0.84, height: h * 0.40))

            // Bioluminescent belly — slightly lighter
            c.setFillColor(UIColor(red: 0.80, green: 1.00, blue: 0.88, alpha: 0.5).cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.24, y: h * 0.52, width: w * 0.52, height: h * 0.18))

            // Stubby legs with bioluminescent tips
            c.setFillColor(Palette.etAccent.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.02, y: h * 0.28, width: w * 0.16, height: h * 0.11))
            c.fillEllipse(in: CGRect(x: w * 0.82, y: h * 0.28, width: w * 0.16, height: h * 0.11))
            // Glowing toe tips
            c.setFillColor(Palette.etGlow.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.01, y: h * 0.27, width: w * 0.07, height: h * 0.07))
            c.fillEllipse(in: CGRect(x: w * 0.92, y: h * 0.27, width: w * 0.07, height: h * 0.07))

            // Gill fronds — tall, thin, with glowing tips (alien/bioluminescent look)
            c.setFillColor(Palette.etAccent.cgColor)
            // Left frond stalk
            c.fill(CGRect(x: w * 0.22, y: h * 0.84, width: w * 0.06, height: h * 0.14))
            // Right frond stalk
            c.fill(CGRect(x: w * 0.72, y: h * 0.84, width: w * 0.06, height: h * 0.14))
            // Centre stalk (tallest)
            c.fill(CGRect(x: w * 0.47, y: h * 0.86, width: w * 0.06, height: h * 0.12))
            // Glowing frond tips
            c.setFillColor(Palette.etGlow.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.18, y: h * 0.92, width: w * 0.14, height: h * 0.12))
            c.fillEllipse(in: CGRect(x: w * 0.68, y: h * 0.92, width: w * 0.14, height: h * 0.12))
            c.fillEllipse(in: CGRect(x: w * 0.43, y: h * 0.94, width: w * 0.14, height: h * 0.12))

            // Alien eyes — very large, wide-spaced, glowing
            c.setFillColor(Palette.etGlow.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.12, y: h * 0.56, width: w * 0.28, height: h * 0.26))
            c.fillEllipse(in: CGRect(x: w * 0.60, y: h * 0.56, width: w * 0.28, height: h * 0.26))
            // Eye inner — dark teal iris
            c.setFillColor(Palette.etAccent.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.16, y: h * 0.60, width: w * 0.20, height: h * 0.18))
            c.fillEllipse(in: CGRect(x: w * 0.64, y: h * 0.60, width: w * 0.20, height: h * 0.18))
            // Pupils
            c.setFillColor(UIColor.black.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.20, y: h * 0.63, width: w * 0.12, height: h * 0.12))
            c.fillEllipse(in: CGRect(x: w * 0.68, y: h * 0.63, width: w * 0.12, height: h * 0.12))
            // Bright eye shine
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.24, y: h * 0.68, width: w * 0.05, height: h * 0.05))
            c.fillEllipse(in: CGRect(x: w * 0.72, y: h * 0.68, width: w * 0.05, height: h * 0.05))

            // Subtle smile
            c.setStrokeColor(Palette.etAccent.cgColor)
            c.setLineWidth(1.2)
            c.move(to:    CGPoint(x: w * 0.36, y: h * 0.53))
            c.addQuadCurve(to: CGPoint(x: w * 0.64, y: h * 0.53),
                           control: CGPoint(x: w * 0.50, y: h * 0.46))
            c.strokePath()
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return SKSpriteNode(texture: tex, size: size)
    }
}
