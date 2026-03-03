// BaseGameScene.swift
// AxA — Abstract base class for all room scenes.
// Handles: camera, player, HUD, joystick, buttons, touch routing,
// physics contacts, room transitions, enemy management, character system.
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

    var roomTransitions: [Edge: RoomID] = [:]
    var enemySpawns: [(type: EnemyType, col: Int, row: Int)] = []

    var playerStartPosition: CGPoint = .zero
    var playerStartEdge: Edge?

    // MARK: - Character State (passed between rooms)

    var activeCharacter: CharacterType = .babeee
    var unlockedCharacters: Set<CharacterType> = [.babeee]
    var babeeHealth: Int = BabeeConst.maxHealth
    var bobHealth: Int   = BobConst.maxHealth
    var wizHealth: Int   = PlayerCombatConst.maxHealth

    // Crystal counter (passed between rooms)
    var crystalCount: Int = 0 {
        didSet { hud?.setCrystals(crystalCount) }
    }

    // Key state (passed between rooms)
    var hasKey: Bool = false

    // MARK: - Nodes

    private(set) var player: PlayerNode!
    private var joystick: VirtualJoystickNode!
    private var attackButton: AttackButtonNode!
    private(set) var cam: SKCameraNode!
    private var hud: HUDNode!
    private var specialButton: SpecialButtonNode!

    private var saltKnights:    [SaltKnightNode]    = []
    private var saltProtectors: [SaltProtectorNode] = []

    // Grapple — set when player enters a grapple point's detection zone
    private var nearbyGrapplePoint: GrapplePointNode?
    private var isGrappling: Bool = false

    // Dig spot — set when Bob enters a soft ground detection zone
    private var nearbyDigSpot: SoftGroundNode?

    // Transition guard
    private var isTransitioning: Bool = false

    // dt tracking
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = Palette.water
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setupCamera()
        subclassSetup()
        setupPlayer()
        setupEnemies()
        setupHUD()
        setupTransitionTriggers()
    }

    func subclassSetup() { /* no-op in base */ }

    // MARK: - Camera

    private func setupCamera() {
        cam = SKCameraNode()
        camera = cam
        addChild(cam)
    }

    func updateCamera() {
        guard let map = groundMap else { return }
        let target   = player.position
        let current  = cam.position
        let smoothed = CGPoint(
            x: current.x + (target.x - current.x) * CameraConst.followSmoothing,
            y: current.y + (target.y - current.y) * CameraConst.followSmoothing
        )
        cam.position = clampCameraPosition(smoothed, map: map)
    }

    private func clampCameraPosition(_ pos: CGPoint, map: SKTileMapNode) -> CGPoint {
        let mapW   = CGFloat(mapCols) * World.tileSize
        let mapH   = CGFloat(mapRows) * World.tileSize
        let halfW  = mapW / 2
        let halfH  = mapH / 2
        let halfVW = size.width  / 2
        let halfVH = size.height / 2

        let minX = map.position.x - halfW + halfVW
        let maxX = map.position.x + halfW - halfVW
        let minY = map.position.y - halfH + halfVH
        let maxY = map.position.y + halfH - halfVH

        return CGPoint(
            x: minX < maxX ? pos.x.clamped(to: minX...maxX) : map.position.x,
            y: minY < maxY ? pos.y.clamped(to: minY...maxY) : map.position.y
        )
    }

    // MARK: - Player

    private func setupPlayer() {
        player = PlayerNode()

        // Restore character state from previous room
        player.activeCharacter    = activeCharacter
        player.unlockedCharacters = unlockedCharacters
        player.babeeHealth        = babeeHealth
        player.bobHealth          = bobHealth
        player.wizHealth          = wizHealth
        switch activeCharacter {
        case .babeee:
            player.maxHealth     = BabeeConst.maxHealth
            player.currentHealth = babeeHealth
        case .bob:
            player.maxHealth     = BobConst.maxHealth
            player.currentHealth = bobHealth
        case .wiz:
            player.maxHealth     = PlayerCombatConst.maxHealth
            player.currentHealth = wizHealth
        }

        if let edge = playerStartEdge {
            player.position = entryPosition(for: edge)
        } else {
            player.position = playerStartPosition
        }

        player.onHealthChanged = { [weak self] current, max in
            self?.hud?.setHealth(current, max: max)
        }
        player.onCharacterChanged = { [weak self] character in
            self?.hud?.setCharacter(character)
            self?.updateSpecialButtonHint()
        }

        addChild(player)
    }

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
        hud.setCharacter(player.activeCharacter)
        updateSpecialButtonHint()
    }

    private func layoutHUD() {
        let halfW = size.width  / 2
        let halfH = size.height / 2
        attackButton.position = CGPoint(x:  halfW - ButtonConst.xOffsetFromRight,
                                        y: -halfH + ButtonConst.yOffsetFromBottom)
        specialButton.position = CGPoint(x:  halfW - SpecialButtonConst.xOffsetFromRight,
                                         y: -halfH + SpecialButtonConst.yOffsetFromBottom)
    }

    // MARK: - Enemies

    private func setupEnemies() {
        guard let map = groundMap else { return }
        for spawn in enemySpawns {
            let spawnPos = map.centerOfTile(atColumn: spawn.col, row: spawn.row)
            switch spawn.type {
            case .saltKnight:
                let knight = SaltKnightNode()
                knight.position   = spawnPos
                knight.playerRef  = player
                let offset: CGFloat = World.tileSize * 3
                knight.patrolStart = CGPoint(x: spawnPos.x - offset, y: spawnPos.y)
                knight.patrolEnd   = CGPoint(x: spawnPos.x + offset, y: spawnPos.y)
                addChild(knight)
                saltKnights.append(knight)

            case .saltProtector:
                let protector = SaltProtectorNode()
                protector.position  = spawnPos
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

    // MARK: - Special Button

    private func updateSpecialButtonHint() {
        switch player.activeCharacter {
        case .babeee:
            specialButton.showPrompt("Rush!")
        case .wiz:
            if nearbyGrapplePoint != nil {
                specialButton.showPrompt("Grapple!")
            } else {
                specialButton.hidePrompt()
            }
        case .bob:
            if nearbyDigSpot != nil {
                specialButton.showPrompt("Dig!")
            } else {
                specialButton.showPrompt("Flutter!")
            }
        }
    }

    func useSpecial() {
        switch player.activeCharacter {
        case .babeee:
            player.performTinyRush()
        case .wiz:
            performGrapple()
        case .bob:
            if let digSpot = nearbyDigSpot, !digSpot.isDug {
                performDig(at: digSpot)
            } else {
                player.performFlutterDash()
            }
        }
    }

    // MARK: - Grapple Hook

    private func performGrapple() {
        guard let grapplePoint = nearbyGrapplePoint, !isGrappling else { return }
        isGrappling = true

        let targetPos = CGPoint(x: grapplePoint.position.x + grapplePoint.landingOffset.x,
                                y: grapplePoint.position.y + grapplePoint.landingOffset.y)

        let rope = SKShapeNode()
        let ropePath = CGMutablePath()
        ropePath.move(to: player.position)
        ropePath.addLine(to: grapplePoint.position)
        rope.path = ropePath
        rope.strokeColor = Palette.ropeColour
        rope.lineWidth = 1.5
        rope.zPosition = ZPos.player - 1
        addChild(rope)

        player.physicsBody?.velocity  = .zero
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

    // MARK: - Dig

    private func performDig(at spot: SoftGroundNode) {
        nearbyDigSpot = nil
        updateSpecialButtonHint()

        spot.dig()

        // Spawn crystals after the dig animation completes
        spot.onDug = { [weak self] worldPos in
            guard let self = self else { return }
            for i in 0..<spot.hiddenCrystals {
                let crystal = CrystalNode()
                let spread  = CGFloat(i) * 8 - CGFloat(spot.hiddenCrystals - 1) * 4
                crystal.position = CGPoint(x: worldPos.x + spread, y: worldPos.y + 6)
                self.addChild(crystal)
            }
        }
    }

    // MARK: - Character Switch (called from touch handler)

    private func switchNextCharacter() {
        let unlocked = CharacterType.allCases.filter { player.unlockedCharacters.contains($0) }
        guard unlocked.count > 1 else { return }
        let current   = unlocked.firstIndex(of: player.activeCharacter) ?? 0
        let nextChar  = unlocked[(current + 1) % unlocked.count]
        player.switchTo(character: nextChar)
        updateSpecialButtonHint()
    }

    // Called by subclass scenes when a snack bag unlock happens
    func playerUnlockedCharacter(_ character: CharacterType) {
        player.unlock(character)
        player.switchTo(character: character)
        updateSpecialButtonHint()
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
            (.left,   CGPoint(x: cx - mapW/2, y: cy), CGSize(width: tw, height: mapH)),
            (.right,  CGPoint(x: cx + mapW/2, y: cy), CGSize(width: tw, height: mapH)),
            (.bottom, CGPoint(x: cx, y: cy - mapH/2), CGSize(width: mapW, height: tw)),
            (.top,    CGPoint(x: cx, y: cy + mapH/2), CGSize(width: mapW, height: tw)),
        ]

        for (edge, pos, triggerSize) in edgeData {
            guard roomTransitions[edge] != nil else { continue }
            let trigger = SKSpriteNode(color: .clear, size: triggerSize)
            trigger.position = pos
            trigger.name     = "trigger_\(edge)"
            trigger.zPosition = -1
            let body = SKPhysicsBody(rectangleOf: triggerSize)
            body.isDynamic        = false
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

        // Snapshot current character state before leaving
        let act = player.activeCharacter
        let currentBabeeHP = act == .babeee ? player.currentHealth : player.babeeHealth
        let currentBobHP   = act == .bob    ? player.currentHealth : player.bobHealth
        let currentWizHP   = act == .wiz    ? player.currentHealth : player.wizHealth

        let transition = SKTransition.fade(withDuration: RoomConst.transitionFadeDuration)

        let destScene: BaseGameScene
        switch destination {
        case .spawnBeach:   destScene = SpawnBeachScene(size: size)
        case .crystalFields: destScene = CrystalFieldsScene(size: size)
        case .lakeShoreEast: destScene = LakeShoreEastScene(size: size)
        case .saltCave:     destScene = SaltCaveScene(size: size)
        }

        destScene.scaleMode          = scaleMode
        destScene.playerStartEdge    = oppositeEdge(edge)
        destScene.crystalCount       = crystalCount
        destScene.hasKey             = hasKey
        destScene.activeCharacter    = player.activeCharacter
        destScene.unlockedCharacters = player.unlockedCharacters
        destScene.babeeHealth        = currentBabeeHP
        destScene.bobHealth          = currentBobHP
        destScene.wizHealth          = currentWizHP

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

        player.move(direction: joystick.isActive ? joystick.direction : .zero, delta: dt)

        for knight    in saltKnights    { knight.update(deltaTime: dt) }
        for protector in saltProtectors { protector.update(deltaTime: dt) }

        updateCamera()
    }

    // MARK: - Physics Contacts

    func didBegin(_ contact: SKPhysicsContact) {
        let catA = contact.bodyA.categoryBitMask
        let catB = contact.bodyB.categoryBitMask

        func body(for category: UInt32) -> SKPhysicsBody? {
            if catA == category { return contact.bodyA }
            if catB == category { return contact.bodyB }
            return nil
        }

        // 1. Player ↔ Trigger → room transition
        if (catA == PhysicsCategory.player  && catB == PhysicsCategory.trigger) ||
           (catA == PhysicsCategory.trigger && catB == PhysicsCategory.player) {
            let triggerBody = body(for: PhysicsCategory.trigger)
            if let name = triggerBody?.node?.name,
               let edge = edgeFromTriggerName(name),
               let dest = roomTransitions[edge] {
                transitionToRoom(dest, enteredFrom: edge)
            }
            return
        }

        // 2. Player ↔ Crystal → collect
        if (catA == PhysicsCategory.player  && catB == PhysicsCategory.crystal) ||
           (catA == PhysicsCategory.crystal && catB == PhysicsCategory.player) {
            let cb = body(for: PhysicsCategory.crystal)
            if let node = cb?.node as? CrystalNode {
                node.onCollected = { [weak self] in self?.crystalCount += 1 }
                node.collect()
            }
            return
        }

        // 3. Attack hitbox ↔ Enemy → damage (with shield check for protectors)
        if (catA == PhysicsCategory.projectile && catB == PhysicsCategory.enemy) ||
           (catA == PhysicsCategory.enemy      && catB == PhysicsCategory.projectile) {
            let eb = body(for: PhysicsCategory.enemy)
            if let enemy = eb?.node as? EnemyNode {
                let dir = CGVector(dx: enemy.position.x - player.position.x,
                                   dy: enemy.position.y - player.position.y)
                if let protector = enemy as? SaltProtectorNode,
                   protector.isShielding(attackDirection: dir) {
                    let spark = SKAction.sequence([
                        SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05),
                        SKAction.colorize(withColorBlendFactor: 0, duration: 0.05)
                    ])
                    protector.sprite.run(spark)
                } else {
                    enemy.takeDamage(PlayerCombatConst.attackDamage)
                    enemy.knockback(from: dir)
                }
            }
            return
        }

        // 3b. Attack hitbox ↔ Breakable wall → shatter
        if (catA == PhysicsCategory.projectile   && catB == PhysicsCategory.breakableWall) ||
           (catA == PhysicsCategory.breakableWall && catB == PhysicsCategory.projectile) {
            let wb = body(for: PhysicsCategory.breakableWall)
            (wb?.node as? BreakableWallNode)?.takeDamage()
            return
        }

        // 4. Enemy body ↔ Player body → player takes damage
        if (catA == PhysicsCategory.enemy  && catB == PhysicsCategory.player) ||
           (catA == PhysicsCategory.player && catB == PhysicsCategory.enemy) {
            let eb = body(for: PhysicsCategory.enemy)
            if let enemy = eb?.node as? EnemyNode, enemy.health > 0 {
                let dir = CGVector(dx: player.position.x - enemy.position.x,
                                   dy: player.position.y - enemy.position.y)
                let dmg = (enemy is SaltProtectorNode) ? ProtectorConst.damage : EnemyConst.saltKnightDamage
                player.takeDamage(dmg, from: dir)
            }
            return
        }

        // 5. Enemy projectile ↔ Player → player takes damage
        if (catA == PhysicsCategory.enemyProjectile && catB == PhysicsCategory.player) ||
           (catA == PhysicsCategory.player           && catB == PhysicsCategory.enemyProjectile) {
            let pb = body(for: PhysicsCategory.enemyProjectile)
            let dir = CGVector(
                dx: player.position.x - (pb?.node?.position.x ?? 0),
                dy: player.position.y - (pb?.node?.position.y ?? 0)
            )
            player.takeDamage(ProtectorConst.damage, from: dir)
            pb?.node?.removeFromParent()
            return
        }

        // 6. Enemy projectile ↔ Wall → remove
        if (catA == PhysicsCategory.enemyProjectile && catB == PhysicsCategory.wall) ||
           (catA == PhysicsCategory.wall             && catB == PhysicsCategory.enemyProjectile) {
            body(for: PhysicsCategory.enemyProjectile)?.node?.removeFromParent()
            return
        }

        // 7. Player ↔ Grapple zone → show prompt
        if (catA == PhysicsCategory.player     && catB == PhysicsCategory.grappleZone) ||
           (catA == PhysicsCategory.grappleZone && catB == PhysicsCategory.player) {
            let zb = body(for: PhysicsCategory.grappleZone)
            if let grappleNode = zb?.node?.parent as? GrapplePointNode {
                nearbyGrapplePoint = grappleNode
                if player.activeCharacter == .wiz { specialButton.showPrompt("Grapple!") }
            }
            return
        }

        // 8. Player ↔ Key → collect
        if (catA == PhysicsCategory.player && catB == PhysicsCategory.key) ||
           (catA == PhysicsCategory.key    && catB == PhysicsCategory.player) {
            let kb = body(for: PhysicsCategory.key)
            if let keyNode = kb?.node as? KeyNode {
                keyNode.onCollected = { [weak self] in self?.hasKey = true }
                keyNode.collect()
            }
            return
        }

        // 9. Player ↔ Locked door → try unlock
        if (catA == PhysicsCategory.player && catB == PhysicsCategory.door) ||
           (catA == PhysicsCategory.door   && catB == PhysicsCategory.player) {
            let db = body(for: PhysicsCategory.door)
            (db?.node as? LockedDoorNode)?.tryUnlock(playerHasKey: hasKey)
            return
        }

        // 10. Player ↔ Snack bag → open
        if (catA == PhysicsCategory.player   && catB == PhysicsCategory.snackBag) ||
           (catA == PhysicsCategory.snackBag && catB == PhysicsCategory.player) {
            let sb = body(for: PhysicsCategory.snackBag)
            (sb?.node as? SnackBagNode)?.open()
            return
        }

        // 11. Player ↔ Soft ground → set nearby dig spot (Bob only)
        if (catA == PhysicsCategory.player     && catB == PhysicsCategory.softGround) ||
           (catA == PhysicsCategory.softGround && catB == PhysicsCategory.player) {
            let dgb = body(for: PhysicsCategory.softGround)
            if let digNode = dgb?.node as? SoftGroundNode, !digNode.isDug {
                nearbyDigSpot = digNode
                updateSpecialButtonHint()
            }
            return
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let catA = contact.bodyA.categoryBitMask
        let catB = contact.bodyB.categoryBitMask

        // Clear grapple point when player leaves zone
        if (catA == PhysicsCategory.player     && catB == PhysicsCategory.grappleZone) ||
           (catA == PhysicsCategory.grappleZone && catB == PhysicsCategory.player) {
            nearbyGrapplePoint = nil
            if player.activeCharacter == .wiz { specialButton.hidePrompt() }
        }

        // Clear dig spot when player leaves
        if (catA == PhysicsCategory.player     && catB == PhysicsCategory.softGround) ||
           (catA == PhysicsCategory.softGround && catB == PhysicsCategory.player) {
            nearbyDigSpot = nil
            updateSpecialButtonHint()
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

    // MARK: - Touch Routing

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: cam)

            // Portrait tap → switch character (checked before joystick routing)
            if let hud = hud, hud.portraitBounds.contains(loc) {
                switchNextCharacter()
                continue
            }

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
