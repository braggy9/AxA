// MonontoeScene.swift
// AxA — World 1, Room 7: Monontoe's Lair
// Three-phase boss fight. Post-defeat: ET snack bag appears as reward.
// Left edge → Nono Grove (always — player can flee or return)

import SpriteKit

final class MonontoeScene: BaseGameScene {

    // MARK: - Boss State

    private var monontoe: MonontoeNode?
    private var bossHealthBG: SKSpriteNode!
    private var bossHealthFill: SKSpriteNode!
    private var bossDefeated: Bool = false

    // MARK: - dt tracking for subclassUpdate

    private var lastSubclassUpdate: TimeInterval = 0

    // MARK: - BaseGameScene Setup

    override func subclassSetup() {
        mapCols = World.monontoeLairCols
        mapRows = World.monontoeLairRows

        backgroundColor = Palette.bossWall

        let result = TileMapBuilder.buildMonontoeLair()
        groundMap          = result.ground
        groundMap.position = .zero
        addChild(groundMap)
        for wallNode in result.walls { addChild(wallNode) }

        playerStartPosition = groundMap.centerOfTile(atColumn: 4, row: 17)

        // No exit until boss is defeated
        roomTransitions = [.left: .nonoGrove]

        enemySpawns = []

        spawnBoss()
    }

    // MARK: - Boss Spawning

    private func spawnBoss() {
        let boss = MonontoeNode()
        boss.position = groundMap.centerOfTile(atColumn: 22, row: 17)
        addChild(boss)
        monontoe = boss

        // Callbacks are wired in didMove after player is available
    }

    // MARK: - Post-Player Setup

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        // Wire up boss callbacks now that player exists
        guard let boss = monontoe else { return }
        boss.playerRef = player

        boss.onSummonKnights = { [weak self] positions in
            guard let self = self else { return }
            for pos in positions {
                let knight = SaltKnightNode()
                knight.position    = pos
                knight.playerRef   = self.player
                knight.patrolStart = CGPoint(x: pos.x - 80, y: pos.y)
                knight.patrolEnd   = CGPoint(x: pos.x + 80, y: pos.y)
                self.addChild(knight)
            }
        }

        boss.onTailWhipActive = { [weak self] in
            guard let self = self, let boss = self.monontoe else { return }
            let dist = hypot(self.player.position.x - boss.position.x,
                             self.player.position.y - boss.position.y)
            if dist < MonontoeConst.tailWhipRadius {
                let dir = CGVector(dx: self.player.position.x - boss.position.x,
                                   dy: self.player.position.y - boss.position.y)
                self.player.takeDamage(MonontoeConst.damage, from: dir)
            }
        }

        boss.onGroundSlam = { [weak self] center in
            self?.spawnShockwave(at: center)
        }

        boss.onPhaseChanged = { [weak self] phase in
            self?.handlePhaseChange(phase)
        }

        boss.onDied = { [weak self] in
            self?.handleBossDefeated()
        }

        setupBossHUD()
    }

    // MARK: - Boss HUD (health bar above screen centre)

    private func setupBossHUD() {
        let barW: CGFloat = 320
        let barH: CGFloat = 16

        bossHealthBG = SKSpriteNode(color: SKColor(white: 0, alpha: 0.55),
                                    size: CGSize(width: barW, height: barH))
        bossHealthBG.anchorPoint = CGPoint(x: 0, y: 0.5)
        bossHealthBG.position    = CGPoint(x: -barW / 2, y: size.height / 2 - 34)
        bossHealthBG.zPosition   = ZPos.hud
        cam?.addChild(bossHealthBG)

        bossHealthFill = SKSpriteNode(color: Palette.monontoeAccent,
                                      size: CGSize(width: barW - 2, height: barH - 3))
        bossHealthFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        bossHealthFill.position    = CGPoint(x: 1, y: 0)
        bossHealthBG.addChild(bossHealthFill)

        let bossLabel = SKLabelNode(text: "MONONTOE")
        bossLabel.fontName   = "AvenirNext-Bold"
        bossLabel.fontSize   = 10
        bossLabel.fontColor  = SKColor(red: 0.80, green: 0.90, blue: 0.95, alpha: 1)
        bossLabel.verticalAlignmentMode   = .bottom
        bossLabel.horizontalAlignmentMode = .center
        bossLabel.position   = CGPoint(x: barW / 2, y: barH / 2 + 2)
        bossHealthBG.addChild(bossLabel)
    }

    private func updateBossHealthBar() {
        guard let boss = monontoe else { return }
        let ratio = CGFloat(max(0, boss.health)) / CGFloat(MonontoeConst.health)
        let fullW: CGFloat = bossHealthBG.size.width - 2
        bossHealthFill.size = CGSize(width: fullW * ratio, height: bossHealthFill.size.height)

        switch ratio {
        case 0..<0.34: bossHealthFill.color = Palette.monontoeRage
        case 0.34..<0.67: bossHealthFill.color = SKColor(red: 0.85, green: 0.50, blue: 0.10, alpha: 1)
        default: bossHealthFill.color = Palette.monontoeAccent
        }
    }

    // MARK: - Frame Update

    override func subclassUpdate(_ dt: TimeInterval) {
        monontoe?.update(deltaTime: dt)
        if monontoe != nil { updateBossHealthBar() }
    }

    // MARK: - Phase Change

    private func handlePhaseChange(_ phase: MonontoePhase) {
        let flashColor: SKColor = phase == .phase3 ? Palette.monontoeRage : .white
        let flash = SKSpriteNode(color: flashColor,
                                  size: CGSize(width: size.width * 2, height: size.height * 2))
        flash.position  = .zero
        flash.zPosition = ZPos.ui - 1
        flash.alpha     = 0
        cam?.addChild(flash)
        flash.run(.sequence([
            .fadeAlpha(to: phase == .phase3 ? 0.45 : 0.30, duration: 0.10),
            .fadeOut(withDuration: 0.55),
            .removeFromParent()
        ]))
    }

    // MARK: - Ground Slam Shockwave

    private func spawnShockwave(at center: CGPoint) {
        // Expanding ring that damages the player if close enough
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.position     = center
        ring.strokeColor  = SKColor(red: 0.55, green: 0.85, blue: 1.00, alpha: 0.9)
        ring.lineWidth    = 3
        ring.fillColor    = .clear
        ring.zPosition    = ZPos.object + 2
        addChild(ring)

        let expand = SKAction.scale(to: MonontoeConst.groundSlamRadius / 10, duration: 0.45)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.35)

        ring.run(.sequence([.group([expand, fade]), .removeFromParent()]))

        // Check player distance at peak
        run(.sequence([.wait(forDuration: 0.22), .run { [weak self] in
            guard let self = self, let boss = self.monontoe else { return }
            let dist = hypot(self.player.position.x - boss.position.x,
                             self.player.position.y - boss.position.y)
            if dist < MonontoeConst.groundSlamRadius {
                let dir = CGVector(dx: self.player.position.x - boss.position.x,
                                   dy: self.player.position.y - boss.position.y)
                self.player.takeDamage(MonontoeConst.damage, from: dir)
            }
        }]))
    }

    // MARK: - Boss Defeat

    private func handleBossDefeated() {
        bossDefeated = true

        // Hide boss health bar
        bossHealthBG.run(.sequence([.fadeOut(withDuration: 0.5), .removeFromParent()]))

        // Delay, then spawn ET snack bag as reward
        run(.sequence([
            .wait(forDuration: 1.8),
            .run { [weak self] in self?.spawnETSnackBag() }
        ]))
    }

    private func spawnETSnackBag() {
        let bag = SnackBagNode()
        bag.position = groundMap.centerOfTile(atColumn: 22, row: 17)
        addChild(bag)

        bag.onOpened = { [weak self] in
            self?.playerUnlockedCharacter(.et)
            self?.playCelebration()
        }

        // Announcement label
        let label = SKLabelNode(text: "A reward awaits...")
        label.fontName  = "AvenirNext-Bold"
        label.fontSize  = 18
        label.fontColor = Palette.celebSparkle
        label.position  = CGPoint(x: 0, y: size.height / 2 - 60)
        label.zPosition = ZPos.hud
        label.alpha     = 0
        cam?.addChild(label)
        label.run(.sequence([
            .fadeIn(withDuration: 0.5),
            .wait(forDuration: 2.0),
            .fadeOut(withDuration: 0.5),
            .removeFromParent()
        ]))
    }

    private func playCelebration() {
        let flash = SKSpriteNode(color: Palette.celebSparkle,
                                  size: CGSize(width: size.width * 2, height: size.height * 2))
        flash.position  = .zero
        flash.zPosition = ZPos.ui - 1
        flash.alpha     = 0
        cam?.addChild(flash)
        flash.run(.sequence([
            .fadeAlpha(to: 0.55, duration: 0.08),
            .fadeOut(withDuration: 0.40),
            .removeFromParent()
        ]))
    }
}
