// BaseGameScene.swift
// AxA — Abstract base class for all room scenes.
// Handles: camera, player, HUD, joystick, attack button, touch routing,
// physics contacts, room transitions, enemy management.
//
// Subclasses must:
//   1. Set groundMap (SKTileMapNode) and call addChild(groundMap) + wall nodes
//   2. Set roomTransitions dictionary
//   3. Set enemySpawns array
//   4. Set playerStartPosition or playerStartEdge

import SpriteKit
import GameplayKit

class BaseGameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Subclass Configuration (set before super.didMove)

    var groundMap: SKTileMapNode!
    var mapCols: Int = 20
    var mapRows: Int = 11

    /// Which rooms connect from each edge of this room.
    var roomTransitions: [Edge: RoomID] = [:]

    /// Enemies to spawn: (type, column, row) in tile coordinates.
    var enemySpawns: [(type: EnemyType, col: Int, row: Int)] = []

    /// Player start position in scene coordinates. Subclass sets this in setupTileMap.
    var playerStartPosition: CGPoint = .zero

    /// Alternative: position player at an incoming edge. Takes priority if set.
    var playerStartEdge: Edge?

    // MARK: - Nodes

    private(set) var player: PlayerNode!
    private var joystick: VirtualJoystickNode!
    private var attackButton: AttackButtonNode!
    private(set) var cam: SKCameraNode!
    private var hud: HUDNode!

    private var enemies: [SaltKnightNode] = []

    // Crystal counter
    private var crystalCount: Int = 0 {
        didSet { hud.setCrystals(crystalCount) }
    }

    // Transition guard — prevent firing twice
    private var isTransitioning: Bool = false

    // dt tracking
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = Palette.water
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setupCamera()
        subclassSetup()          // subclass builds tile map and configures properties
        setupPlayer()
        setupEnemies()
        setupHUD()
        setupTransitionTriggers()
    }

    /// Override in subclass to build tile map, set mapCols/mapRows,
    /// roomTransitions, enemySpawns, playerStartPosition.
    func subclassSetup() {
        // no-op in base
    }

    // MARK: - Camera

    private func setupCamera() {
        cam = SKCameraNode()
        camera = cam
        addChild(cam)
    }

    func updateCamera() {
        guard let map = groundMap else { return }
        let target  = player.position
        let current = cam.position
        let smoothed = CGPoint(
            x: current.x + (target.x - current.x) * CameraConst.followSmoothing,
            y: current.y + (target.y - current.y) * CameraConst.followSmoothing
        )
        cam.position = clampCameraPosition(smoothed, map: map)
    }

    private func clampCameraPosition(_ pos: CGPoint, map: SKTileMapNode) -> CGPoint {
        let mapW = CGFloat(mapCols) * World.tileSize
        let mapH = CGFloat(mapRows) * World.tileSize
        let halfMapW = mapW / 2
        let halfMapH = mapH / 2
        let halfViewW = size.width  / 2
        let halfViewH = size.height / 2

        let minX = map.position.x - halfMapW + halfViewW
        let maxX = map.position.x + halfMapW - halfViewW
        let minY = map.position.y - halfMapH + halfViewH
        let maxY = map.position.y + halfMapH - halfViewH

        let clampedX = minX < maxX ? pos.x.clamped(to: minX...maxX) : map.position.x
        let clampedY = minY < maxY ? pos.y.clamped(to: minY...maxY) : map.position.y

        return CGPoint(x: clampedX, y: clampedY)
    }

    // MARK: - Player

    private func setupPlayer() {
        player = PlayerNode()

        if let edge = playerStartEdge {
            player.position = entryPosition(for: edge)
        } else {
            player.position = playerStartPosition
        }

        player.onHealthChanged = { [weak self] current, max in
            self?.hud.setHealth(current, max: max)
        }

        addChild(player)
    }

    /// Returns a position just inside the map edge.
    private func entryPosition(for edge: Edge) -> CGPoint {
        guard let map = groundMap else { return .zero }
        let mapW  = CGFloat(mapCols) * World.tileSize
        let mapH  = CGFloat(mapRows) * World.tileSize
        let halfW = mapW / 2
        let halfH = mapH / 2
        let inset: CGFloat = World.tileSize * 2

        switch edge {
        case .left:   return CGPoint(x: map.position.x - halfW + inset, y: map.position.y)
        case .right:  return CGPoint(x: map.position.x + halfW - inset, y: map.position.y)
        case .bottom: return CGPoint(x: map.position.x, y: map.position.y - halfH + inset)
        case .top:    return CGPoint(x: map.position.x, y: map.position.y + halfH - inset)
        }
    }

    // MARK: - HUD

    private func setupHUD() {
        hud = HUDNode()
        cam.addChild(hud)

        joystick = VirtualJoystickNode()
        cam.addChild(joystick)

        attackButton = AttackButtonNode()
        attackButton.onTap = { [weak self] in self?.player.performAttack() }
        cam.addChild(attackButton)

        layoutHUD()
        hud.setHealth(player.currentHealth, max: player.maxHealth)
        hud.setCrystals(crystalCount)
    }

    private func layoutHUD() {
        let halfW = size.width  / 2
        let halfH = size.height / 2
        attackButton.position = CGPoint(
            x:  halfW - ButtonConst.xOffsetFromRight,
            y: -halfH + ButtonConst.yOffsetFromBottom
        )
    }

    // MARK: - Enemies

    private func setupEnemies() {
        guard let map = groundMap else { return }
        for spawn in enemySpawns {
            switch spawn.type {
            case .saltKnight:
                let knight = SaltKnightNode()
                knight.position = map.centerOfTile(atColumn: spawn.col, row: spawn.row)
                knight.playerRef = player

                // Patrol between a point left and right of spawn
                let patrolOffset: CGFloat = World.tileSize * 3
                knight.patrolStart = CGPoint(x: knight.position.x - patrolOffset,
                                             y: knight.position.y)
                knight.patrolEnd   = CGPoint(x: knight.position.x + patrolOffset,
                                             y: knight.position.y)
                addChild(knight)
                enemies.append(knight)
            }
        }
    }

    // MARK: - Room Transitions

    private func setupTransitionTriggers() {
        guard let map = groundMap else { return }

        let mapW = CGFloat(mapCols) * World.tileSize
        let mapH = CGFloat(mapRows) * World.tileSize
        let cx   = map.position.x
        let cy   = map.position.y
        let tw   = RoomConst.transitionTriggerWidth

        let edgeData: [(Edge, CGPoint, CGSize)] = [
            (.left,   CGPoint(x: cx - mapW / 2,      y: cy),          CGSize(width: tw, height: mapH)),
            (.right,  CGPoint(x: cx + mapW / 2,      y: cy),          CGSize(width: tw, height: mapH)),
            (.bottom, CGPoint(x: cx, y: cy - mapH / 2),               CGSize(width: mapW, height: tw)),
            (.top,    CGPoint(x: cx, y: cy + mapH / 2),               CGSize(width: mapW, height: tw)),
        ]

        for (edge, pos, triggerSize) in edgeData {
            guard roomTransitions[edge] != nil else { continue }

            let trigger = SKSpriteNode(color: .clear, size: triggerSize)
            trigger.position = pos
            trigger.name = "trigger_\(edge)"
            trigger.zPosition = -1

            let body = SKPhysicsBody(rectangleOf: triggerSize)
            body.isDynamic = false
            body.affectedByGravity = false
            body.categoryBitMask    = PhysicsCategory.trigger
            body.collisionBitMask   = PhysicsCategory.none
            body.contactTestBitMask = PhysicsCategory.player
            trigger.physicsBody = body

            addChild(trigger)
        }
    }

    private func transitionToRoom(_ destination: RoomID, enteredFrom edge: Edge) {
        guard !isTransitioning else { return }
        isTransitioning = true

        let transition = SKTransition.fade(withDuration: RoomConst.transitionFadeDuration)

        let destScene: BaseGameScene
        switch destination {
        case .spawnBeach:
            destScene = SpawnBeachScene(size: size)
        case .crystalFields:
            destScene = CrystalFieldsScene(size: size)
        }

        destScene.scaleMode = scaleMode
        // Player enters from opposite edge in destination
        destScene.playerStartEdge = oppositeEdge(edge)

        // Pass crystal count across rooms
        destScene.crystalCount = crystalCount

        view?.presentScene(destScene, transition: transition)
    }

    private func oppositeEdge(_ edge: Edge) -> Edge {
        switch edge {
        case .left:   return .right
        case .right:  return .left
        case .top:    return .bottom
        case .bottom: return .top
        }
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        let dt: TimeInterval = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime

        if joystick.isActive {
            player.move(direction: joystick.direction, delta: dt)
        } else {
            player.move(direction: .zero, delta: dt)
        }

        for enemy in enemies {
            enemy.update(deltaTime: dt)
        }

        updateCamera()
    }

    // MARK: - Physics Contacts

    func didBegin(_ contact: SKPhysicsContact) {
        let catA = contact.bodyA.categoryBitMask
        let catB = contact.bodyB.categoryBitMask

        // Helper: find body matching a category
        func body(for category: UInt32) -> SKPhysicsBody? {
            if catA == category { return contact.bodyA }
            if catB == category { return contact.bodyB }
            return nil
        }

        // 1. Player ↔ Trigger → room transition
        if (catA == PhysicsCategory.player && catB == PhysicsCategory.trigger) ||
           (catA == PhysicsCategory.trigger && catB == PhysicsCategory.player) {
            let triggerBody = body(for: PhysicsCategory.trigger)
            if let triggerNode = triggerBody?.node,
               let name = triggerNode.name,
               let edge = edgeFromTriggerName(name),
               let destination = roomTransitions[edge] {
                transitionToRoom(destination, enteredFrom: edge)
            }
            return
        }

        // 2. Player ↔ Crystal → collect
        if (catA == PhysicsCategory.player && catB == PhysicsCategory.crystal) ||
           (catA == PhysicsCategory.crystal && catB == PhysicsCategory.player) {
            let crystalBody = body(for: PhysicsCategory.crystal)
            if let crystalNode = crystalBody?.node as? CrystalNode {
                crystalNode.onCollected = { [weak self] in
                    self?.crystalCount += 1
                }
                crystalNode.collect()
            }
            return
        }

        // 3. Attack hitbox ↔ Enemy → enemy takes damage
        if (catA == PhysicsCategory.projectile && catB == PhysicsCategory.enemy) ||
           (catA == PhysicsCategory.enemy && catB == PhysicsCategory.projectile) {
            let enemyBody = body(for: PhysicsCategory.enemy)
            if let enemyNode = enemyBody?.node as? EnemyNode {
                // Determine knockback direction: away from player
                let dir = CGVector(
                    dx: enemyNode.position.x - player.position.x,
                    dy: enemyNode.position.y - player.position.y
                )
                enemyNode.takeDamage(PlayerCombatConst.attackDamage)
                enemyNode.knockback(from: dir)
            }
            return
        }

        // 4. Enemy body ↔ Player body → player takes damage
        if (catA == PhysicsCategory.enemy && catB == PhysicsCategory.player) ||
           (catA == PhysicsCategory.player && catB == PhysicsCategory.enemy) {
            let enemyBody  = body(for: PhysicsCategory.enemy)
            let playerBody = body(for: PhysicsCategory.player)

            if let enemyNode = enemyBody?.node as? SaltKnightNode,
               let _ = playerBody?.node as? PlayerNode {
                // Only deal damage if not in hurt/dead state
                // We just check health > 0 on enemy — exact state check is internal
                if enemyNode.health > 0 {
                    let dir = CGVector(
                        dx: player.position.x - enemyNode.position.x,
                        dy: player.position.y - enemyNode.position.y
                    )
                    player.takeDamage(EnemyConst.saltKnightDamage, from: dir)
                }
            }
            return
        }
    }

    // MARK: - Helpers

    private func edgeFromTriggerName(_ name: String) -> Edge? {
        if name.hasSuffix("left")   { return .left }
        if name.hasSuffix("right")  { return .right }
        if name.hasSuffix("top")    { return .top }
        if name.hasSuffix("bottom") { return .bottom }
        return nil
    }

    // MARK: - Touch Forwarding

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: cam)
            if loc.x < 0 {
                joystick.touchesBegan([touch], with: event)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        joystick.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        joystick.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        joystick.touchesCancelled(touches, with: event)
    }
}

// MARK: - EnemyType

enum EnemyType {
    case saltKnight
    // more enemy types added in later stages
}
