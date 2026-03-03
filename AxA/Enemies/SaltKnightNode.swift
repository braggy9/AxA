// SaltKnightNode.swift
// AxA — Salt Knight enemy. Pink armoured axolotl patrol enemy for Crystal Fields.
// Stage 2: patrol + chase + hurt + dead states, crystal drops, player damage on contact.

import SpriteKit
import GameplayKit

final class SaltKnightNode: EnemyNode {

    // MARK: AI

    private var stateMachine: GKStateMachine!

    /// Weak reference to the player — set by the scene after spawning.
    weak var playerRef: PlayerNode?

    // MARK: Patrol Waypoints

    var patrolStart: CGPoint = .zero
    var patrolEnd: CGPoint   = .zero
    /// true = moving toward patrolEnd; false = moving toward patrolStart
    var patrolForward: Bool  = true

    // MARK: Init

    override init(health: Int, sprite: SKSpriteNode) {
        super.init(health: health, sprite: sprite)
    }

    convenience init() {
        self.init(health: EnemyConst.saltKnightHealth,
                  sprite: SaltKnightNode.buildPlaceholderSprite())
        setupStateMachine()
        setupOnDeath()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: Update (called by scene each frame)

    func update(deltaTime: TimeInterval) {
        guard stateMachine.currentState != nil else { return }
        stateMachine.update(deltaTime: deltaTime)

        // Flip sprite to face movement direction
        if let vel = physicsBody?.velocity {
            if abs(vel.dx) > 2 {
                sprite.xScale = vel.dx > 0 ? 1 : -1
            }
        }
    }

    // MARK: Combat Overrides

    override func takeDamage(_ amount: Int) {
        guard !(stateMachine.currentState is DeadState) else { return }
        super.takeDamage(amount)
        if health > 0 {
            stateMachine.enter(HurtState.self)
        }
        // If health == 0, onDeath fires which enters DeadState
    }

    // MARK: Crystal Drops (called by DeadState)

    func dropCrystals() {
        guard let parent = parent else { return }
        let count = Int.random(in: EnemyConst.crystalDropMin...EnemyConst.crystalDropMax)
        for i in 0..<count {
            let crystal = CrystalNode()
            // Scatter around death position
            let angle = CGFloat(i) / CGFloat(count) * .pi * 2
            let radius: CGFloat = 22
            crystal.position = CGPoint(
                x: position.x + cos(angle) * radius,
                y: position.y + sin(angle) * radius
            )
            parent.addChild(crystal)
        }
    }

    // MARK: Private — State Machine Setup

    private func setupStateMachine() {
        let idle    = IdleState(knight: self)
        let patrol  = PatrolState(knight: self)
        let chase   = ChaseState(knight: self)
        let hurt    = HurtState(knight: self)
        let dead    = DeadState(knight: self)

        stateMachine = GKStateMachine(states: [idle, patrol, chase, hurt, dead])
        stateMachine.enter(IdleState.self)
    }

    private func setupOnDeath() {
        onDeath = { [weak self] in
            self?.stateMachine.enter(DeadState.self)
        }
    }

    // MARK: Private — Placeholder Sprite

    private static func buildPlaceholderSprite() -> SKSpriteNode {
        let size = CGSize(width: 28, height: 28)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            // Body — pink rectangle (armoured axolotl)
            c.setFillColor(SKColor(red: 0.9, green: 0.5, blue: 0.7, alpha: 1).cgColor)
            c.fill(CGRect(x: 3, y: 3, width: 20, height: 18))

            // Armour highlight — lighter pink strip across chest
            c.setFillColor(SKColor(red: 1.0, green: 0.75, blue: 0.85, alpha: 0.8).cgColor)
            c.fill(CGRect(x: 5, y: 9, width: 16, height: 5))

            // Eyes — two white dots
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: 7, y: 16, width: 4, height: 4))
            c.fillEllipse(in: CGRect(x: 17, y: 16, width: 4, height: 4))

            // Sword — gold vertical line (right side)
            c.setStrokeColor(SKColor(red: 0.9, green: 0.75, blue: 0.2, alpha: 1).cgColor)
            c.setLineWidth(2.5)
            c.move(to: CGPoint(x: 25, y: 2))
            c.addLine(to: CGPoint(x: 25, y: 16))
            c.strokePath()

            // Sword crossguard
            c.move(to: CGPoint(x: 21, y: 13))
            c.addLine(to: CGPoint(x: 28, y: 13))
            c.strokePath()
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return SKSpriteNode(texture: tex, size: size)
    }
}
