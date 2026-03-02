// AIStates.swift
// AxA — GKState subclasses for SaltKnight AI state machine.
// Each state holds an unowned reference to the SaltKnightNode to avoid retain cycles.

import GameplayKit
import SpriteKit

// MARK: - IdleState

final class IdleState: GKState {

    unowned let knight: SaltKnightNode

    init(knight: SaltKnightNode) {
        self.knight = knight
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == PatrolState.self ||
        stateClass == ChaseState.self  ||
        stateClass == HurtState.self   ||
        stateClass == DeadState.self
    }

    override func didEnter(from previousState: GKState?) {
        // Stop movement
        knight.physicsBody?.velocity = .zero
    }

    override func update(deltaTime seconds: TimeInterval) {
        guard let player = knight.playerRef else { return }
        let dist = hypot(player.position.x - knight.position.x,
                         player.position.y - knight.position.y)
        if dist < EnemyConst.saltKnightChaseRadius {
            stateMachine?.enter(ChaseState.self)
        } else {
            stateMachine?.enter(PatrolState.self)
        }
    }
}

// MARK: - PatrolState

final class PatrolState: GKState {

    unowned let knight: SaltKnightNode

    init(knight: SaltKnightNode) {
        self.knight = knight
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == IdleState.self   ||
        stateClass == ChaseState.self  ||
        stateClass == HurtState.self   ||
        stateClass == DeadState.self
    }

    override func didEnter(from previousState: GKState?) {
        // Direction is maintained by the knight's patrolForward flag
    }

    override func update(deltaTime seconds: TimeInterval) {
        guard let player = knight.playerRef else { return }

        // Switch to chase if player is close
        let dist = hypot(player.position.x - knight.position.x,
                         player.position.y - knight.position.y)
        if dist < EnemyConst.saltKnightChaseRadius {
            stateMachine?.enter(ChaseState.self)
            return
        }

        // Move toward current waypoint
        let target = knight.patrolForward ? knight.patrolEnd : knight.patrolStart
        let dx = target.x - knight.position.x
        let dy = target.y - knight.position.y
        let d  = hypot(dx, dy)

        if d < EnemyConst.saltKnightWaypointTolerance {
            // Reached waypoint — reverse
            knight.patrolForward.toggle()
        } else {
            let speed = EnemyConst.saltKnightPatrolSpeed
            knight.physicsBody?.velocity = CGVector(dx: dx / d * speed, dy: dy / d * speed)
        }
    }
}

// MARK: - ChaseState

final class ChaseState: GKState {

    unowned let knight: SaltKnightNode

    init(knight: SaltKnightNode) {
        self.knight = knight
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == PatrolState.self ||
        stateClass == HurtState.self   ||
        stateClass == DeadState.self   ||
        stateClass == IdleState.self
    }

    override func update(deltaTime seconds: TimeInterval) {
        guard let player = knight.playerRef else {
            stateMachine?.enter(PatrolState.self)
            return
        }

        let dx = player.position.x - knight.position.x
        let dy = player.position.y - knight.position.y
        let d  = hypot(dx, dy)

        if d > EnemyConst.saltKnightChaseRadius * 1.5 {
            // Player escaped — return to patrol
            stateMachine?.enter(PatrolState.self)
            return
        }

        if d > 0 {
            let speed = EnemyConst.saltKnightChaseSpeed
            knight.physicsBody?.velocity = CGVector(dx: dx / d * speed, dy: dy / d * speed)
        }
    }
}

// MARK: - HurtState

final class HurtState: GKState {

    unowned let knight: SaltKnightNode
    private var stunTimer: TimeInterval = 0
    private let stunDuration: TimeInterval = 0.3

    init(knight: SaltKnightNode) {
        self.knight = knight
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == PatrolState.self ||
        stateClass == ChaseState.self  ||
        stateClass == DeadState.self
    }

    override func didEnter(from previousState: GKState?) {
        stunTimer = 0
        // Stop movement during stun
        knight.physicsBody?.velocity = .zero
    }

    override func update(deltaTime seconds: TimeInterval) {
        stunTimer += seconds
        if stunTimer >= stunDuration {
            // Return to patrol (will immediately switch to chase if player is close)
            stateMachine?.enter(PatrolState.self)
        }
    }
}

// MARK: - DeadState

final class DeadState: GKState {

    unowned let knight: SaltKnightNode

    init(knight: SaltKnightNode) {
        self.knight = knight
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        // Terminal state — no valid transitions out
        false
    }

    override func didEnter(from previousState: GKState?) {
        // Disable physics so corpse doesn't interact
        knight.physicsBody?.categoryBitMask    = PhysicsCategory.none
        knight.physicsBody?.collisionBitMask   = PhysicsCategory.none
        knight.physicsBody?.contactTestBitMask = PhysicsCategory.none
        knight.physicsBody?.velocity = .zero

        // Death animation: shrink and fade, then drop crystals and remove
        let die = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.1, duration: 0.35),
                SKAction.fadeOut(withDuration: 0.35)
            ]),
            SKAction.run { [unowned knight = self.knight] in
                knight.dropCrystals()
            },
            SKAction.removeFromParent()
        ])
        knight.run(die)
    }
}
