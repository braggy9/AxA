// MonontoeNode.swift
// AxA — World 1 boss. Dark teal axolotl. 12 HP, 3 escalating phases.
//
// Phase 1 (12–9 HP): Chase + charge.
// Phase 2 (8–5 HP): Tail whip AoE + summon 2 Salt Knights + charge.
// Phase 3 (4–1 HP): Everything faster, ground slam shockwave added.

import SpriteKit

enum MonontoePhase {
    case phase1, phase2, phase3
}

final class MonontoeNode: EnemyNode {

    // MARK: - Phase State

    private(set) var phase: MonontoePhase = .phase1
    private(set) var isDead: Bool = false
    private var isInvincible: Bool = false
    private var isInAction: Bool = false

    // MARK: - Attack Timers

    private var chargeTimer: TimeInterval     = 2.0
    private var tailWhipTimer: TimeInterval   = 2.5
    private var groundSlamTimer: TimeInterval = 4.5
    private var summonTimer: TimeInterval     = 3.0

    // MARK: - Callbacks

    weak var playerRef: PlayerNode?

    /// Provides spawn positions for two new Salt Knights.
    var onSummonKnights: ((_ positions: [CGPoint]) -> Void)?
    /// Fires when boss is fully dead.
    var onDied: (() -> Void)?
    /// Fires when phase changes.
    var onPhaseChanged: ((MonontoePhase) -> Void)?
    /// Fires when ground slam lands — scene spawns shockwave ring.
    var onGroundSlam: ((_ center: CGPoint) -> Void)?
    /// Fires during tail whip frame — scene checks if player is in range.
    var onTailWhipActive: (() -> Void)?

    // MARK: - Init

    init() {
        super.init(health: MonontoeConst.health,
                   sprite: MonontoeNode.buildMonontoeSprite())

        // Replace base physics with larger boss body
        let body = SKPhysicsBody(circleOfRadius: MonontoeConst.physicsRadius)
        body.categoryBitMask    = PhysicsCategory.enemy
        body.collisionBitMask   = PhysicsCategory.wall
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile
        body.allowsRotation     = false
        body.linearDamping      = 6
        physicsBody = body
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Damage (override for invincibility frames + boss death)

    override func takeDamage(_ amount: Int) {
        guard !isInvincible && !isDead && health > 0 else { return }
        health = max(0, health - amount)

        // Hurt flash
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.9, duration: 0.06),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.10)
        ])
        sprite.run(flash, withKey: "hurt")

        // Brief i-frames so player can't spam one attack
        isInvincible = true
        run(.sequence([.wait(forDuration: 0.35), .run { [weak self] in self?.isInvincible = false }]))

        if health <= 0 { die() }
    }

    override func knockback(from direction: CGVector) {
        // Boss takes only minor knockback
        guard let body = physicsBody else { return }
        let len = hypot(direction.dx, direction.dy)
        guard len > 0 else { return }
        body.applyImpulse(CGVector(dx: direction.dx / len * MonontoeConst.knockback,
                                   dy: direction.dy / len * MonontoeConst.knockback))
    }

    // MARK: - Update Loop (called by MonontoeScene via subclassUpdate)

    func update(deltaTime dt: TimeInterval) {
        guard !isDead, let player = playerRef, health > 0 else { return }

        // Phase transitions
        let newPhase: MonontoePhase
        if health > MonontoeConst.phase2Threshold       { newPhase = .phase1 }
        else if health > MonontoeConst.phase3Threshold  { newPhase = .phase2 }
        else                                             { newPhase = .phase3 }

        if newPhase != phase {
            phase = newPhase
            triggerPhaseTransition()
            onPhaseChanged?(phase)
        }

        let speedMult: CGFloat = phase == .phase3 ? MonontoeConst.phase3SpeedMult : 1.0

        switch phase {
        case .phase1: updatePhase1(dt: dt, player: player, speedMult: speedMult)
        case .phase2: updatePhase2(dt: dt, player: player, speedMult: speedMult)
        case .phase3: updatePhase3(dt: dt, player: player, speedMult: speedMult)
        }
    }

    // MARK: - Phase Updates

    private func updatePhase1(dt: TimeInterval, player: PlayerNode, speedMult: CGFloat) {
        guard !isInAction else { return }
        chargeTimer -= dt
        let dist = distanceTo(player)
        if dist < 220 { moveToward(player, speed: MonontoeConst.chaseSpeed * speedMult, dt: dt) }
        if chargeTimer <= 0 && dist < 290 {
            chargeTimer = MonontoeConst.chargeCooldown
            performCharge(toward: player.position)
        }
    }

    private func updatePhase2(dt: TimeInterval, player: PlayerNode, speedMult: CGFloat) {
        guard !isInAction else { return }
        chargeTimer   -= dt
        tailWhipTimer -= dt
        summonTimer   -= dt
        let dist = distanceTo(player)

        if dist < 240 { moveToward(player, speed: MonontoeConst.chaseSpeed * speedMult, dt: dt) }

        if tailWhipTimer <= 0 && dist < MonontoeConst.tailWhipRadius + 30 {
            tailWhipTimer = MonontoeConst.tailWhipCooldown
            performTailWhip()
        } else if chargeTimer <= 0 && dist < 290 {
            chargeTimer = MonontoeConst.chargeCooldown
            performCharge(toward: player.position)
        }

        if summonTimer <= 0 {
            summonTimer = MonontoeConst.summonCooldown
            let p1 = CGPoint(x: position.x - 90, y: position.y + 70)
            let p2 = CGPoint(x: position.x + 90, y: position.y + 70)
            onSummonKnights?([p1, p2])
        }
    }

    private func updatePhase3(dt: TimeInterval, player: PlayerNode, speedMult: CGFloat) {
        guard !isInAction else { return }
        chargeTimer      -= dt
        tailWhipTimer    -= dt
        groundSlamTimer  -= dt

        moveToward(player, speed: MonontoeConst.chaseSpeed * speedMult, dt: dt)

        if groundSlamTimer <= 0 {
            groundSlamTimer = MonontoeConst.groundSlamCooldown
            performGroundSlam()
        } else if tailWhipTimer <= 0 && distanceTo(player) < MonontoeConst.tailWhipRadius + 30 {
            tailWhipTimer = MonontoeConst.tailWhipCooldown * 0.7
            performTailWhip()
        } else if chargeTimer <= 0 && distanceTo(player) < 300 {
            chargeTimer = MonontoeConst.chargeCooldown * 0.75
            performCharge(toward: player.position)
        }
    }

    // MARK: - Attacks

    private func performCharge(toward target: CGPoint) {
        isInAction = true

        let dir = CGPoint(x: target.x - position.x, y: target.y - position.y)
        let len = hypot(dir.x, dir.y)
        guard len > 0 else { isInAction = false; return }
        let norm  = CGPoint(x: dir.x / len, y: dir.y / len)
        let endPos = CGPoint(x: position.x + norm.x * 260,
                             y: position.y + norm.y * 260)

        // Windup squish
        let windup  = SKAction.scale(to: CGSize(width: 0.7, height: 1.35), duration: 0.25)
        windup.timingMode = .easeIn
        let restore = SKAction.scale(to: CGSize(width: 1.0, height: 1.0),  duration: 0.18)
        let redden  = SKAction.colorize(with: Palette.monontoeRage, colorBlendFactor: 0.5, duration: 0.20)
        let unred   = SKAction.colorize(withColorBlendFactor: 0, duration: 0.30)

        sprite.run(.sequence([windup, redden]))

        let dash = SKAction.move(to: endPos, duration: MonontoeConst.chargeDuration)
        dash.timingMode = .easeOut

        run(.sequence([
            .wait(forDuration: 0.25),
            dash,
            .run { [weak self] in
                self?.sprite.run(.sequence([restore, unred]))
            },
            .wait(forDuration: 0.55),
            .run { [weak self] in self?.isInAction = false }
        ]), withKey: "charge")
    }

    private func performTailWhip() {
        isInAction = true

        // Full spin
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 0.45)
        spin.timingMode = .easeInEaseOut
        sprite.run(spin)

        // Notify scene at mid-spin so it can check player proximity
        run(.sequence([
            .wait(forDuration: 0.22),
            .run { [weak self] in self?.onTailWhipActive?() },
            .wait(forDuration: 0.50),
            .run { [weak self] in self?.isInAction = false }
        ]), withKey: "tailWhip")
    }

    private func performGroundSlam() {
        isInAction = true

        // Jump + slam animation
        let jumpUp   = SKAction.moveBy(x: 0, y: 44, duration: 0.28)
        jumpUp.timingMode = .easeOut
        let slamDown = SKAction.moveBy(x: 0, y: -44, duration: 0.18)
        slamDown.timingMode = .easeIn
        let squash  = SKAction.scale(to: CGSize(width: 1.6, height: 0.55), duration: 0.12)
        let restore = SKAction.scale(to: CGSize(width: 1.0, height: 1.0),  duration: 0.22)

        run(.sequence([
            jumpUp,
            slamDown,
            .run { [weak self] in
                guard let self = self else { return }
                self.sprite.run(.sequence([squash, restore]))
                self.onGroundSlam?(self.position)
            },
            .wait(forDuration: 0.80),
            .run { [weak self] in self?.isInAction = false }
        ]), withKey: "groundSlam")
    }

    // MARK: - Death

    private func die() {
        isDead = true
        physicsBody = nil
        removeAllActions()

        let flash = SKAction.repeat(
            .sequence([
                .colorize(with: Palette.monontoeRage, colorBlendFactor: 0.9, duration: 0.08),
                .colorize(withColorBlendFactor: 0, duration: 0.08)
            ]),
            count: 6
        )
        let shrink = SKAction.group([
            .scale(to: 0.05, duration: 0.55),
            .fadeOut(withDuration: 0.55)
        ])

        sprite.run(.sequence([flash, shrink, .removeFromParent()]))
        run(.wait(forDuration: 0.50)) { [weak self] in self?.onDied?() }
    }

    // MARK: - Phase Transition Flash

    private func triggerPhaseTransition() {
        isInvincible = true
        let flashColor: SKColor = phase == .phase3 ? Palette.monontoeRage : .white
        let flash = SKAction.repeat(
            .sequence([
                .colorize(with: flashColor, colorBlendFactor: 0.9, duration: 0.09),
                .colorize(withColorBlendFactor: 0, duration: 0.09)
            ]),
            count: 7
        )
        sprite.run(.sequence([flash, .run { [weak self] in self?.isInvincible = false }]))
    }

    // MARK: - Helpers

    private func distanceTo(_ player: PlayerNode) -> CGFloat {
        hypot(player.position.x - position.x, player.position.y - position.y)
    }

    private func moveToward(_ player: PlayerNode, speed: CGFloat, dt: TimeInterval) {
        let dx = player.position.x - position.x
        let dy = player.position.y - position.y
        let len = hypot(dx, dy)
        guard len > 12 else { return }
        position.x += (dx / len) * speed * dt
        position.y += (dy / len) * speed * dt
        sprite.xScale = dx > 0 ? 1 : -1
    }

    // MARK: - Sprite

    private static func buildMonontoeSprite() -> SKSpriteNode {
        let size = MonontoeConst.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            let w = size.width, h = size.height

            // Tail — thick, sweeping left (UIKit low y = SpriteKit visual bottom)
            c.setFillColor(Palette.monontoeAccent.cgColor)
            let tail = UIBezierPath()
            tail.move(to: CGPoint(x: w * 0.16, y: h * 0.14))
            tail.addQuadCurve(to: CGPoint(x: w * -0.12, y: h * 0.06),
                               controlPoint: CGPoint(x: w * 0.00, y: h * 0.24))
            tail.addLine(to: CGPoint(x: w * -0.06, y: h * 0.01))
            tail.addQuadCurve(to: CGPoint(x: w * 0.22, y: h * 0.05),
                               controlPoint: CGPoint(x: w * 0.08, y: h * 0.16))
            tail.close()
            c.addPath(tail.cgPath)
            c.fillPath()

            // Body — large dark teal round axolotl
            c.setFillColor(Palette.monontoeBody.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.06, y: h * 0.08, width: w * 0.88, height: h * 0.60))

            // Wide flat head
            c.fillEllipse(in: CGRect(x: w * 0.08, y: h * 0.50, width: w * 0.84, height: h * 0.44))

            // Head accent — lighter teal stripe
            c.setFillColor(Palette.monontoeAccent.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.20, y: h * 0.54, width: w * 0.60, height: h * 0.20))

            // Stubby powerful legs
            c.setFillColor(Palette.monontoeBody.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.00, y: h * 0.22, width: w * 0.20, height: h * 0.14))
            c.fillEllipse(in: CGRect(x: w * 0.80, y: h * 0.22, width: w * 0.20, height: h * 0.14))

            // Gill fronds — large, dramatic, 3 per side
            c.setFillColor(Palette.monontoeAccent.cgColor)
            // Left fronds
            c.fill(CGRect(x: w * 0.02, y: h * 0.76, width: w * 0.08, height: h * 0.18))
            c.fill(CGRect(x: w * 0.06, y: h * 0.83, width: w * 0.08, height: h * 0.16))
            c.fill(CGRect(x: w * 0.10, y: h * 0.89, width: w * 0.08, height: h * 0.14))
            c.fillEllipse(in: CGRect(x: w * -0.02, y: h * 0.88, width: w * 0.16, height: h * 0.14))
            c.fillEllipse(in: CGRect(x: w * 0.03, y: h * 0.93, width: w * 0.15, height: h * 0.12))
            c.fillEllipse(in: CGRect(x: w * 0.08, y: h * 0.97, width: w * 0.14, height: h * 0.10))
            // Right fronds (mirrored)
            c.fill(CGRect(x: w * 0.90, y: h * 0.76, width: w * 0.08, height: h * 0.18))
            c.fill(CGRect(x: w * 0.86, y: h * 0.83, width: w * 0.08, height: h * 0.16))
            c.fill(CGRect(x: w * 0.82, y: h * 0.89, width: w * 0.08, height: h * 0.14))
            c.fillEllipse(in: CGRect(x: w * 0.86, y: h * 0.88, width: w * 0.16, height: h * 0.14))
            c.fillEllipse(in: CGRect(x: w * 0.82, y: h * 0.93, width: w * 0.15, height: h * 0.12))
            c.fillEllipse(in: CGRect(x: w * 0.78, y: h * 0.97, width: w * 0.14, height: h * 0.10))

            // Menacing yellow eyes
            c.setFillColor(SKColor(red: 0.95, green: 0.88, blue: 0.18, alpha: 1).cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.20, y: h * 0.62, width: w * 0.20, height: h * 0.20))
            c.fillEllipse(in: CGRect(x: w * 0.60, y: h * 0.62, width: w * 0.20, height: h * 0.20))

            // Vertical slit pupils (reptilian)
            c.setFillColor(UIColor.black.cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.27, y: h * 0.63, width: w * 0.06, height: w * 0.14))
            c.fillEllipse(in: CGRect(x: w * 0.67, y: h * 0.63, width: w * 0.06, height: w * 0.14))

            // Wide angry mouth
            c.setStrokeColor(UIColor.black.cgColor)
            c.setLineWidth(2.5)
            c.move(to:    CGPoint(x: w * 0.20, y: h * 0.54))
            c.addQuadCurve(to: CGPoint(x: w * 0.80, y: h * 0.54),
                           control: CGPoint(x: w * 0.50, y: h * 0.62))
            c.strokePath()

            // Teeth — four white triangles
            c.setFillColor(UIColor.white.cgColor)
            for i in 0..<4 {
                let tx = w * 0.28 + CGFloat(i) * w * 0.14
                let tooth = CGMutablePath()
                tooth.move(to:    CGPoint(x: tx,            y: h * 0.54))
                tooth.addLine(to: CGPoint(x: tx + w * 0.06, y: h * 0.54))
                tooth.addLine(to: CGPoint(x: tx + w * 0.03, y: h * 0.60))
                tooth.closeSubpath()
                c.addPath(tooth)
                c.fillPath()
            }
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return SKSpriteNode(texture: tex, size: size)
    }
}
