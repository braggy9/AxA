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
// Represents the active playable character (Wiz or Bob).
// Character switching swaps visible sprites and adjusts stats.
// Each character retains its own health across switches and room transitions.

final class PlayerNode: SKNode {

    // MARK: - Character State

    var activeCharacter: CharacterType = .wiz {
        didSet { updateCharacterVisuals() }
    }
    var unlockedCharacters: Set<CharacterType> = [.wiz]

    /// Per-character health — persists across switches and room transitions.
    var wizHealth: Int = PlayerCombatConst.maxHealth
    var bobHealth: Int = BobConst.maxHealth

    // MARK: - Movement State

    private(set) var facing: FacingDirection = .down

    private let wizSprite: SKSpriteNode
    private let bobSprite: SKSpriteNode

    /// The currently active sprite — always matches activeCharacter.
    var sprite: SKSpriteNode { activeCharacter == .wiz ? wizSprite : bobSprite }

    // MARK: - Combat State

    var maxHealth: Int = PlayerCombatConst.maxHealth
    var currentHealth: Int = PlayerCombatConst.maxHealth

    private(set) var isInvincible: Bool = false

    private var attackCooldownRemaining: TimeInterval = 0
    private var attackHitbox: SKSpriteNode?

    private var isFlutterDashing: Bool = false

    /// Called whenever health changes. Args: (current, max)
    var onHealthChanged: ((Int, Int) -> Void)?

    /// Called when the active character changes. Arg: new character.
    var onCharacterChanged: ((CharacterType) -> Void)?

    // MARK: - Init

    override init() {
        wizSprite = PlayerNode.buildWizSprite()
        bobSprite = PlayerNode.buildBobSprite()

        super.init()

        addChild(wizSprite)
        bobSprite.isHidden = true
        addChild(bobSprite)

        setupPhysics()
        zPosition = ZPos.player
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Character Switching

    func unlock(_ character: CharacterType) {
        unlockedCharacters.insert(character)
        switch character {
        case .bob: bobHealth = BobConst.maxHealth
        case .wiz: break
        }
    }

    func switchTo(character: CharacterType) {
        guard unlockedCharacters.contains(character), character != activeCharacter else { return }

        // Save outgoing health
        switch activeCharacter {
        case .wiz: wizHealth = currentHealth
        case .bob: bobHealth = currentHealth
        }

        activeCharacter = character   // triggers updateCharacterVisuals()

        // Restore incoming health
        switch character {
        case .wiz:
            maxHealth     = PlayerCombatConst.maxHealth
            currentHealth = wizHealth
        case .bob:
            maxHealth     = BobConst.maxHealth
            currentHealth = bobHealth
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
        case .wiz: performStaffSwing()
        case .bob: performPeck()
        }
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
        switch facing {
        case .right: sprite.xScale =  1
        case .left:  sprite.xScale = -1
        case .up, .down: sprite.xScale = 1
        }
    }

    // MARK: - Character Visuals

    private func updateCharacterVisuals() {
        wizSprite.isHidden = (activeCharacter != .wiz)
        bobSprite.isHidden = (activeCharacter != .bob)
        // Stop any walk animation on the outgoing sprite (direction/state carried forward)
        for s in [wizSprite, bobSprite] {
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

    private static func buildWizSprite() -> SKSpriteNode {
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
            hat.move(to:    CGPoint(x: 8,  y: 16))
            hat.addLine(to: CGPoint(x: 4,  y: 8))
            hat.addLine(to: CGPoint(x: 12, y: 8))
            hat.closeSubpath()
            c.addPath(hat)
            c.fillPath()

            // Staff — gold line from tail (bottom right)
            c.setStrokeColor(Palette.wizStaff.cgColor)
            c.setLineWidth(1.5)
            c.move(to:    CGPoint(x: 12, y: 2))
            c.addLine(to: CGPoint(x: 15, y: 6))
            c.strokePath()

            // Eyes — two white dots
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: 5, y: 6, width: 2, height: 2))
            c.fillEllipse(in: CGRect(x: 9, y: 6, width: 2, height: 2))
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
}
