// LakeShoreWestScene.swift
// AxA — World 1, Room 5: Lake Shore West
// Water Level puzzle: three coloured crystal switches must be activated in
// the correct order (green → blue → red) to drain the flood and open the
// right passage to Nono Grove.
// Left edge → Salt Cave | Right edge → Nono Grove

import SpriteKit

final class LakeShoreWestScene: BaseGameScene {

    // MARK: - Puzzle State

    private var switches: [WaterSwitchNode] = []
    private var activationOrder: [Int] = []
    private var floodOverlays: [SKSpriteNode] = []
    private var puzzleSolved: Bool = false

    // MARK: - BaseGameScene Setup

    override func subclassSetup() {
        mapCols = World.lakeShoreWestCols
        mapRows = World.lakeShoreWestRows

        let result = TileMapBuilder.buildLakeShoreWest()
        groundMap          = result.ground
        groundMap.position = .zero
        addChild(groundMap)
        for wallNode in result.walls { addChild(wallNode) }

        playerStartPosition = groundMap.centerOfTile(atColumn: 3, row: 13)

        roomTransitions = [.left: .saltCave, .right: .nonoGrove]

        // No enemies in this puzzle room
        enemySpawns = []

        addFloodOverlays()
        addSwitches()
    }

    // MARK: - Flood Overlays

    /// Semi-transparent water tiles that cover the right zone until puzzle is solved.
    private func addFloodOverlays() {
        let ts = World.tileSize
        for r in 3...22 {
            for c in 20...40 {
                let overlay = SKSpriteNode(color: Palette.floodWater,
                                           size: CGSize(width: ts, height: ts))
                overlay.position  = groundMap.centerOfTile(atColumn: c, row: r)
                overlay.zPosition = ZPos.object + 1
                addChild(overlay)
                floodOverlays.append(overlay)

                // Also place an invisible wall to block player in the flooded zone
                let blocker = SKNode()
                blocker.position = overlay.position
                let body = SKPhysicsBody(rectangleOf: CGSize(width: ts, height: ts))
                body.isDynamic          = false
                body.categoryBitMask    = PhysicsCategory.water
                body.collisionBitMask   = PhysicsCategory.player
                body.contactTestBitMask = PhysicsCategory.none
                blocker.physicsBody = body
                blocker.name = "floodBlocker"
                addChild(blocker)
            }
        }
    }

    // MARK: - Switches

    private func addSwitches() {
        // green=1, blue=2, red=0 — placed in order so the visual hint helps
        let switchData: [(colorIndex: Int, col: Int, row: Int)] = [
            (1, 8, 20),   // green  — bottom
            (2, 8, 13),   // blue   — middle
            (0, 8,  6),   // red    — top
        ]
        for data in switchData {
            let sw = WaterSwitchNode(colorIndex: data.colorIndex)
            sw.position = groundMap.centerOfTile(atColumn: data.col, row: data.row)
            addChild(sw)
            switches.append(sw)

            sw.onTouched = { [weak self, weak sw] in
                guard let self = self, let sw = sw else { return }
                self.handleSwitchTouched(sw)
            }
        }
    }

    // MARK: - Puzzle Logic

    private func handleSwitchTouched(_ switchNode: WaterSwitchNode) {
        guard !puzzleSolved, !switchNode.isActivated else { return }

        activationOrder.append(switchNode.colorIndex)
        switchNode.activate()

        // Validate against correct order so far
        let correct = WaterSwitchConst.correctOrder
        for (i, colorIdx) in activationOrder.enumerated() {
            if colorIdx != correct[i] {
                // Wrong — flash red and reset
                run(.sequence([
                    .wait(forDuration: 0.6),
                    .run { [weak self] in self?.resetSwitches() }
                ]))
                return
            }
        }

        if activationOrder.count == correct.count {
            puzzleSolved = true
            drainFlood()
        }
    }

    private func resetSwitches() {
        activationOrder.removeAll()
        for sw in switches { sw.deactivate() }

        // Red screen flash to indicate mistake
        let flash = SKSpriteNode(color: SKColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 0.35),
                                  size: CGSize(width: size.width * 2, height: size.height * 2))
        flash.position  = .zero
        flash.zPosition = ZPos.ui - 2
        cam?.addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.45), .removeFromParent()]))
    }

    private func drainFlood() {
        // Remove invisible flood blockers
        children.filter { $0.name == "floodBlocker" }.forEach { $0.removeFromParent() }

        // Stagger the overlay fade-out for a wave-drain visual effect
        for (i, overlay) in floodOverlays.enumerated() {
            let delay = Double(i % 20) * 0.025
            overlay.run(.sequence([
                .wait(forDuration: delay),
                .fadeOut(withDuration: 0.55),
                .removeFromParent()
            ]))
        }

        // Blue celebration flash
        let flash = SKSpriteNode(color: Palette.switchBlue,
                                  size: CGSize(width: size.width * 2, height: size.height * 2))
        flash.position  = .zero
        flash.zPosition = ZPos.ui - 1
        flash.alpha     = 0
        cam?.addChild(flash)
        flash.run(.sequence([
            .fadeAlpha(to: 0.38, duration: 0.12),
            .fadeOut(withDuration: 0.50),
            .removeFromParent()
        ]))
    }
}
