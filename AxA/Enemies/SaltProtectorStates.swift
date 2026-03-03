// SaltProtectorStates.swift
// AxA — GKState subclasses for the Salt Protector AI state machine.

import GameplayKit
import SpriteKit

// MARK: - ProtectorIdleState

final class ProtectorIdleState: GKState {
    unowned let protector: SaltProtectorNode
    init(protector: SaltProtectorNode) { self.protector = protector }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == ProtectorPatrolState.self ||
        stateClass == ProtectorAimState.self    ||
        stateClass == ProtectorHurtState.self   ||
        stateClass == ProtectorDeadState.self
    }

    override func didEnter(from previousState: GKState?) {
        protector.physicsBody?.velocity = .zero
    }

    override func update(deltaTime seconds: TimeInterval) {
        guard let player = protector.playerRef else { return }
        let dist = hypot(player.position.x - protector.position.x,
                         player.position.y - protector.position.y)
        if dist < ProtectorConst.chaseRadius {
            stateMachine?.enter(ProtectorAimState.self)
        } else {
            stateMachine?.enter(ProtectorPatrolState.self)
        }
    }
}

// MARK: - ProtectorPatrolState

final class ProtectorPatrolState: GKState {
    unowned let protector: SaltProtectorNode
    private var timer: TimeInterval = 0
    private var direction: CGFloat = 1

    init(protector: SaltProtectorNode) { self.protector = protector }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == ProtectorIdleState.self ||
        stateClass == ProtectorAimState.self  ||
        stateClass == ProtectorHurtState.self ||
        stateClass == ProtectorDeadState.self
    }

    override func didEnter(from previousState: GKState?) { timer = 0 }

    override func update(deltaTime seconds: TimeInterval) {
        guard let player = protector.playerRef else { return }
        let dist = hypot(player.position.x - protector.position.x,
                         player.position.y - protector.position.y)
        if dist < ProtectorConst.chaseRadius {
            stateMachine?.enter(ProtectorAimState.self)
            return
        }
        // Slow side-to-side patrol
        timer += seconds
        if timer > 2.0 { timer = 0; direction *= -1 }
        protector.physicsBody?.velocity = CGVector(dx: direction * ProtectorConst.patrolSpeed, dy: 0)
    }
}

// MARK: - ProtectorAimState

final class ProtectorAimState: GKState {
    unowned let protector: SaltProtectorNode

    init(protector: SaltProtectorNode) { self.protector = protector }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == ProtectorPatrolState.self ||
        stateClass == ProtectorHurtState.self   ||
        stateClass == ProtectorDeadState.self
    }

    override func didEnter(from previousState: GKState?) {
        protector.shootTimer = 0
        protector.physicsBody?.velocity = .zero
    }

    override func update(deltaTime seconds: TimeInterval) {
        guard let player = protector.playerRef else {
            stateMachine?.enter(ProtectorPatrolState.self)
            return
        }
        let dist = hypot(player.position.x - protector.position.x,
                         player.position.y - protector.position.y)
        if dist > ProtectorConst.chaseRadius * 1.4 {
            stateMachine?.enter(ProtectorPatrolState.self)
            return
        }

        protector.shootTimer += seconds
        if protector.shootTimer >= ProtectorConst.shootInterval {
            protector.shootTimer = 0
            protector.shoot()
        }
    }
}

// MARK: - ProtectorHurtState

final class ProtectorHurtState: GKState {
    unowned let protector: SaltProtectorNode
    private var stunTimer: TimeInterval = 0
    private let stunDuration: TimeInterval = 0.4

    init(protector: SaltProtectorNode) { self.protector = protector }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == ProtectorAimState.self    ||
        stateClass == ProtectorPatrolState.self ||
        stateClass == ProtectorDeadState.self
    }

    override func didEnter(from previousState: GKState?) {
        stunTimer = 0
        protector.physicsBody?.velocity = .zero
    }

    override func update(deltaTime seconds: TimeInterval) {
        stunTimer += seconds
        if stunTimer >= stunDuration {
            stateMachine?.enter(ProtectorAimState.self)
        }
    }
}

// MARK: - ProtectorDeadState

final class ProtectorDeadState: GKState {
    unowned let protector: SaltProtectorNode

    init(protector: SaltProtectorNode) { self.protector = protector }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool { false }

    override func didEnter(from previousState: GKState?) {
        protector.physicsBody?.categoryBitMask    = PhysicsCategory.none
        protector.physicsBody?.collisionBitMask   = PhysicsCategory.none
        protector.physicsBody?.contactTestBitMask = PhysicsCategory.none
        protector.physicsBody?.velocity = .zero

        let die = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.1, duration: 0.35),
                SKAction.fadeOut(withDuration: 0.35)
            ]),
            SKAction.run { [unowned p = self.protector] in p.dropCrystals() },
            SKAction.removeFromParent()
        ])
        protector.run(die)
    }
}
