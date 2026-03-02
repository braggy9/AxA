// EnemyNode.swift
// AxA — Abstract base class for all enemy nodes.
// Subclass this for each enemy type. Do not instantiate directly.

import SpriteKit

class EnemyNode: SKNode {

    // MARK: State

    var health: Int
    var maxHealth: Int

    /// Called when health reaches 0. Subclasses override to play death animation.
    var onDeath: (() -> Void)?

    /// The sprite node representing this enemy visually.
    let sprite: SKSpriteNode

    // MARK: Init

    init(health: Int, sprite: SKSpriteNode) {
        self.health    = health
        self.maxHealth = health
        self.sprite    = sprite
        super.init()
        addChild(sprite)
        zPosition = ZPos.enemy
        setupBasePhysics()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: Combat

    func takeDamage(_ amount: Int) {
        guard health > 0 else { return }
        health -= amount

        // White hurt flash
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.05),
            SKAction.wait(forDuration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.05)
        ])
        sprite.run(flash, withKey: "hurt")

        if health <= 0 {
            health = 0
            onDeath?()
        }
    }

    func knockback(from direction: CGVector) {
        guard let body = physicsBody else { return }
        let mag = EnemyConst.saltKnightKnockback
        // Normalise direction
        let len = hypot(direction.dx, direction.dy)
        guard len > 0 else { return }
        let impulse = CGVector(dx: direction.dx / len * mag,
                               dy: direction.dy / len * mag)
        body.applyImpulse(impulse)
    }

    // MARK: Physics (base setup — subclasses can customise after super.init)

    private func setupBasePhysics() {
        let body = SKPhysicsBody(circleOfRadius: 6)
        body.categoryBitMask    = PhysicsCategory.enemy
        body.collisionBitMask   = PhysicsCategory.wall | PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile
        body.allowsRotation = false
        body.linearDamping = 6
        physicsBody = body
    }
}
