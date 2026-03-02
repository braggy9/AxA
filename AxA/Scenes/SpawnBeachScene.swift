import SpriteKit
import GameplayKit

// MARK: - SpawnBeachScene
// World 1 — Room 1: Spawn Beach (safe starting area, tutorial hints)
// Subclass of BaseGameScene. No enemies. Right edge transitions to Crystal Fields.

final class SpawnBeachScene: BaseGameScene {

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        showTutorialHint()
    }

    // MARK: - BaseGameScene Configuration

    override func subclassSetup() {
        mapCols = World.spawnBeachCols
        mapRows = World.spawnBeachRows

        // Build tile map
        let result = TileMapBuilder.buildSpawnBeach()
        groundMap = result.ground
        groundMap.position = .zero
        addChild(groundMap)
        for wallNode in result.walls {
            addChild(wallNode)
        }

        // Player spawns near centre-bottom
        let startCol = World.spawnBeachCols / 2
        let startRow = 2
        playerStartPosition = groundMap.centerOfTile(atColumn: startCol, row: startRow)

        // Right edge → Crystal Fields
        roomTransitions = [.right: .crystalFields]

        // No enemies on Spawn Beach
        enemySpawns = []
    }

    // MARK: - Tutorial

    private func showTutorialHint() {
        let label = SKLabelNode(text: "Use the left side to move!")
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 10
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: size.height / 2 - 20)
        label.alpha = 0
        label.zPosition = ZPos.hud
        cam.addChild(label)

        let fade = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        label.run(fade)
    }
}

// MARK: - Comparable clamp helper (keep here for compilation — used by BaseGameScene)
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
