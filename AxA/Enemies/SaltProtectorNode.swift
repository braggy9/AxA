// SaltProtectorNode.swift
// AxA — Salt Protector: ranged enemy with a frontal shield.
// 4 HP. Fires crystal shards at the player every ~2 seconds.
// Attacks from the front are blocked — player must hit from side or behind.

import SpriteKit
import GameplayKit

final class SaltProtectorNode: EnemyNode {

    // MARK: - AI

    private var stateMachine: GKStateMachine!
    weak var playerRef: PlayerNode?

    // MARK: - State

    var shootTimer: TimeInterval = 0
    var facingAngle: CGFloat = 0   // radians, updated each frame toward player

    /// Fired by the scene after this node is added so the projectile has a parent.
    var onFireProjectile: ((CGVector) -> Void)?

    // MARK: - Init

    override init(health: Int, sprite: SKSpriteNode) {
        super.init(health: health, sprite: sprite)
    }

    convenience init() {
        self.init(health: ProtectorConst.health,
                  sprite: SaltProtectorNode.buildPlaceholderSprite())
        setupStateMachine()
        setupOnDeath()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Update

    func update(deltaTime dt: TimeInterval) {
        stateMachine.update(deltaTime: dt)

        if let player = playerRef {
            let dx = player.position.x - position.x
            let dy = player.position.y - position.y
            facingAngle = atan2(dy, dx)
            // Flip sprite to face player
            sprite.xScale = dx >= 0 ? 1 : -1
        }
    }

    // MARK: - Shield Check

    /// Returns true if an attack coming from `attackDirection` is blocked by the shield.
    func isShielding(attackDirection: CGVector) -> Bool {
        // attackDirection = enemy.position - player.position (points FROM player TO enemy).
        // facingAngle points FROM protector TOWARD player.
        // A frontal attack arrives from the player's side (attackAngle ≈ facingAngle + π).
        // We block when the attack is nearly opposite to the facing direction (diff near ±π).
        let attackAngle = atan2(attackDirection.dy, attackDirection.dx)
        var diff = attackAngle - facingAngle
        while diff >  .pi { diff -= .pi * 2 }
        while diff < -.pi { diff += .pi * 2 }
        let halfShield = ProtectorConst.shieldAngleDeg * .pi / 180 / 2
        return abs(abs(diff) - .pi) < halfShield
    }

    // MARK: - Combat Overrides

    override func takeDamage(_ amount: Int) {
        guard !(stateMachine.currentState is ProtectorDeadState) else { return }
        super.takeDamage(amount)
        if health > 0 {
            stateMachine.enter(ProtectorHurtState.self)
        }
    }

    func shoot() {
        guard let player = playerRef else { return }
        let dx = player.position.x - position.x
        let dy = player.position.y - position.y
        let dist = hypot(dx, dy)
        guard dist > 0 else { return }
        let speed = ProtectorConst.projectileSpeed
        let vel = CGVector(dx: dx / dist * speed, dy: dy / dist * speed)
        onFireProjectile?(vel)
    }

    // MARK: - State Machine

    private func setupStateMachine() {
        let idle   = ProtectorIdleState(protector: self)
        let patrol = ProtectorPatrolState(protector: self)
        let aim    = ProtectorAimState(protector: self)
        let hurt   = ProtectorHurtState(protector: self)
        let dead   = ProtectorDeadState(protector: self)

        stateMachine = GKStateMachine(states: [idle, patrol, aim, hurt, dead])
        stateMachine.enter(ProtectorIdleState.self)
    }

    private func setupOnDeath() {
        onDeath = { [weak self] in
            self?.stateMachine.enter(ProtectorDeadState.self)
        }
    }

    // MARK: - Placeholder Sprite

    private static func buildPlaceholderSprite() -> SKSpriteNode {
        let size = CGSize(width: 28, height: 28)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            // Body — teal armoured axolotl
            c.setFillColor(SKColor(red: 0.2, green: 0.6, blue: 0.7, alpha: 1).cgColor)
            c.fillEllipse(in: CGRect(x: 3, y: 3, width: 18, height: 18))

            // Heavy armour plate — silver
            c.setFillColor(SKColor(red: 0.7, green: 0.75, blue: 0.8, alpha: 1).cgColor)
            c.fill(CGRect(x: 5, y: 8, width: 14, height: 8))

            // Shield (right side)
            c.setFillColor(SKColor(red: 0.6, green: 0.65, blue: 0.7, alpha: 1).cgColor)
            let shieldPath = CGMutablePath()
            shieldPath.move(to: CGPoint(x: 21, y: 22))
            shieldPath.addLine(to: CGPoint(x: 28, y: 19))
            shieldPath.addLine(to: CGPoint(x: 28, y: 6))
            shieldPath.addLine(to: CGPoint(x: 21, y: 3))
            shieldPath.closeSubpath()
            c.addPath(shieldPath)
            c.fillPath()
            c.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
            c.setLineWidth(1)
            c.addPath(shieldPath)
            c.strokePath()

            // Eyes
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: 7, y: 14, width: 4, height: 4))
            c.fillEllipse(in: CGRect(x: 14, y: 14, width: 4, height: 4))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return SKSpriteNode(texture: tex, size: size)
    }
}
