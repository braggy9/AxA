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

    private var saltKnights:    [SaltKnightNode]    = []
    private var saltProtectors: [SaltProtectorNode] = []

    // Crystal counter
    private var crystalCount: Int = 0 {
        didSet { hud.setCrystals(crystalCount) }
    }

    // Key state (passed between rooms)
    var hasKey: Bool = false

    // Grapple — set when player enters a grapple point's detection zone
    private var nearbyGrapplePoint: GrapplePointNode?
    private var isGrappling: Bool = false

    // Special button
    private var specialButton: SpecialButtonNode!

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

        specialButton = SpecialButtonNode()
        specialButton.onTap = { [weak self] in self?.useSpecial() }
        cam.addChild(specialButton)

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
        specialButton.position = CGPoint(
            x:  halfW - SpecialButtonConst.xOffsetFromRight,
            y: -halfH + SpecialButtonConst.yOffsetFromBottom
        )
    }

    // MARK: - Enemies

    private func setupEnemies() {
        guard let map = groundMap else { return }
        for spawn in enemySpawns {
            let spawnPos = map.centerOfTile(atColumn: spawn.col, row: spawn.row)
            switch spawn.type {
            case .saltKnight:
                let knight = SaltKnightNode()
                knight.position = spawnPos
                knight.playerRef = player
                let patrolOffset: CGFloat = World.tileSize * 3
                knight.patrolStart = CGPoint(x: spawnPos.x - patrolOffset, y: spawnPos.y)
                knight.patrolEnd   = CGPoint(x: spawnPos.x + patrolOffset, y: spawnPos.y)
                addChild(knight)
                saltKnights.append(knight)

            case .saltProtector:
                let protector = SaltProtectorNode()
                protector.position = spawnPos
                protector.playerRef = player
                protector.onFireProjectile = { [weak self, weak protector] velocity in
                    guard let self = self, let protector = protector else { return }
                    let proj = EnemyProjectileNode()
                    proj.position = protector.position
                    self.addChild(proj)
                    proj.launch(velocity: velocity)
                }
                addChild(protector)
                saltProtectors.append(protector)
            }
        }
    }

    // MARK: - Grapple Hook

    func useSpecial() {
        guard let grapplePoint = nearbyGrapplePoint, !isGrappling else { return }
        isGrappling = true

        let targetPos = CGPoint(
            x: grapplePoint.position.x + grapplePoint.landingOffset.x,
            y: grapplePoint.position.y + grapplePoint.landingOffset.y
        )

        // Draw rope
        let rope = SKShapeNode()
        let ropePath = CGMutablePath()
        ropePath.move(to: player.position)
        ropePath.addLine(to: grapplePoint.position)
        rope.path = ropePath
        rope.strokeColor = Palette.ropeColour
        rope.lineWidth = 1.5
        rope.zPosition = ZPos.player - 1
        addChild(rope)

        // Zip player across
        player.physicsBody?.velocity = .zero
        player.physicsBody?.isDynamic = false

        let zipAction = SKAction.sequence([
            SKAction.wait(forDuration: GrappleConst.ropeDrawDuration),
            SKAction.move(to: targetPos, duration: GrappleConst.zipDuration),
            SKAction.run { [weak self] in
                self?.player.physicsBody?.isDynamic = true
                self?.isGrappling = false
                self?.nearbyGrapplePoint = nil
                self?.specialButton.hidePrompt()
                rope.removeFromParent()
            }
        ])
        player.run(zipAction, withKey: "grapple")
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
        case .lakeShoreEast:
            destScene = LakeShoreEastScene(size: size)
        case .saltCave:
            destScene = SaltCaveScene(size: size)
        }

        destScene.scaleMode = scaleMode
        destScene.playerStartEdge = oppositeEdge(edge)
        destScene.crystalCount = crystalCount
        destScene.hasKey = hasKey

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

        for knight in saltKnights {
            knight.update(deltaTime: dt)
        }
        for protector in saltProtectors {
            protector.update(deltaTime: dt)
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

        // 3. Attack hitbox ↔ Enemy → enemy takes damage (with shield check for protectors)
        if (catA == PhysicsCategory.projectile && catB == PhysicsCategory.enemy) ||
           (catA == PhysicsCategory.enemy && catB == PhysicsCategory.projectile) {
            let enemyBody = body(for: PhysicsCategory.enemy)
            if let enemyNode = enemyBody?.node as? EnemyNode {
                let dir = CGVector(
                    dx: enemyNode.position.x - player.position.x,
                    dy: enemyNode.position.y - player.position.y
                )
                // Shield check for protectors
                if let protector = enemyNode as? SaltProtectorNode,
                   protector.isShielding(attackDirection: dir) {
                    // Attack blocked — shield spark
                    let spark = SKAction.sequence([
                        SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05),
                        SKAction.colorize(withColorBlendFactor: 0, duration: 0.05)
                    ])
                    protector.sprite.run(spark)
                } else {
                    enemyNode.takeDamage(PlayerCombatConst.attackDamage)
                    enemyNode.knockback(from: dir)
                }
            }
            return
        }

        // 3b. Attack hitbox ↔ Breakable wall → shatter
        if (catA == PhysicsCategory.projectile && catB == PhysicsCategory.breakableWall) ||
           (catA == PhysicsCategory.breakableWall && catB == PhysicsCategory.projectile) {
            let wallBody = body(for: PhysicsCategory.breakableWall)
            (wallBody?.node as? BreakableWallNode)?.takeDamage()
            return
        }

        // 4. Enemy body ↔ Player body → player takes damage
        if (catA == PhysicsCategory.enemy && catB == PhysicsCategory.player) ||
           (catA == PhysicsCategory.player && catB == PhysicsCategory.enemy) {
            let enemyBody = body(for: PhysicsCategory.enemy)
            if let enemyNode = enemyBody?.node as? EnemyNode, enemyNode.health > 0 {
                let dir = CGVector(
                    dx: player.position.x - enemyNode.position.x,
                    dy: player.position.y - enemyNode.position.y
                )
                let damage = (enemyNode is SaltProtectorNode)
                    ? ProtectorConst.damage
                    : EnemyConst.saltKnightDamage
                player.takeDamage(damage, from: dir)
            }
            return
        }

        // 5. Enemy projectile ↔ Player → player takes damage
        if (catA == PhysicsCategory.enemyProjectile && catB == PhysicsCategory.player) ||
           (catA == PhysicsCategory.player && catB == PhysicsCategory.enemyProjectile) {
            let projBody = body(for: PhysicsCategory.enemyProjectile)
            let dir = CGVector(
                dx: player.position.x - (projBody?.node?.position.x ?? 0),
                dy: player.position.y - (projBody?.node?.position.y ?? 0)
            )
            player.takeDamage(ProtectorConst.damage, from: dir)
            projBody?.node?.removeFromParent()
            return
        }

        // 6. Enemy projectile ↔ Wall → remove projectile
        if (catA == PhysicsCategory.enemyProjectile && catB == PhysicsCategory.wall) ||
           (catA == PhysicsCategory.wall && catB == PhysicsCategory.enemyProjectile) {
            let projBody = body(for: PhysicsCategory.enemyProjectile)
            projBody?.node?.removeFromParent()
            return
        }

        // 7. Player ↔ Grapple zone → show prompt
        if (catA == PhysicsCategory.player && catB == PhysicsCategory.grappleZone) ||
           (catA == PhysicsCategory.grappleZone && catB == PhysicsCategory.player) {
            let zoneBody = body(for: PhysicsCategory.grappleZone)
            if let grappleNode = zoneBody?.node?.parent as? GrapplePointNode {
                nearbyGrapplePoint = grappleNode
                specialButton.showPrompt("Grapple!")
            }
            return
        }

        // 8. Player ↔ Key → collect
        if (catA == PhysicsCategory.player && catB == PhysicsCategory.key) ||
           (catA == PhysicsCategory.key && catB == PhysicsCategory.player) {
            let keyBody = body(for: PhysicsCategory.key)
            if let keyNode = keyBody?.node as? KeyNode {
                keyNode.onCollected = { [weak self] in self?.hasKey = true }
                keyNode.collect()
            }
            return
        }

        // 9. Player ↔ Locked door → try unlock
        if (catA == PhysicsCategory.player && catB == PhysicsCategory.door) ||
           (catA == PhysicsCategory.door && catB == PhysicsCategory.player) {
            let doorBody = body(for: PhysicsCategory.door)
            (doorBody?.node as? LockedDoorNode)?.tryUnlock(playerHasKey: hasKey)
            return
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let catA = contact.bodyA.categoryBitMask
        let catB = contact.bodyB.categoryBitMask

        // Clear grapple point when player leaves detection zone
        if (catA == PhysicsCategory.player && catB == PhysicsCategory.grappleZone) ||
           (catA == PhysicsCategory.grappleZone && catB == PhysicsCategory.player) {
            nearbyGrapplePoint = nil
            specialButton.hidePrompt()
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
    case saltProtector
}
