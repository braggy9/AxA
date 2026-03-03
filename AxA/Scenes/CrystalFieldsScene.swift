// CrystalFieldsScene.swift
// AxA — World 1, Room 2: Crystal Fields
// Open combat arena with salt ground, crystal clusters, and 6 Salt Knight enemies.
// Contains the Wiz snack bag (second character unlock).
// Left edge → Spawn Beach | Right edge → Lake Shore East

import SpriteKit
import GameplayKit

final class CrystalFieldsScene: BaseGameScene {

    // MARK: - BaseGameScene Configuration

    override func subclassSetup() {
        mapCols = World.crystalFieldsCols
        mapRows = World.crystalFieldsRows

        // Build tile map
        let result = TileMapBuilder.buildCrystalFields()
        groundMap = result.ground
        groundMap.position = .zero
        addChild(groundMap)
        for wallNode in result.walls {
            addChild(wallNode)
        }

        // Default player start: centre of room
        let startCol = World.crystalFieldsCols / 2
        let startRow = World.crystalFieldsRows / 2
        playerStartPosition = groundMap.centerOfTile(atColumn: startCol, row: startRow)

        roomTransitions = [.left: .spawnBeach, .right: .lakeShoreEast]

        // 6 Salt Knights spread across the expanded room
        enemySpawns = [
            (type: .saltKnight, col: 5,  row: 22),   // front-left
            (type: .saltKnight, col: 20, row: 22),   // front-centre
            (type: .saltKnight, col: 37, row: 22),   // front-right
            (type: .saltKnight, col: 5,  row: 7),    // back-left
            (type: .saltKnight, col: 20, row: 12),   // back-centre
            (type: .saltKnight, col: 37, row: 7),    // back-right
        ]

        addWizSnackBag()
    }

    // MARK: - Wiz Unlock

    /// The Wiz snack bag — Wiz is the second character unlock, found in Crystal Fields.
    private func addWizSnackBag() {
        let bag = SnackBagNode()
        bag.position = groundMap.centerOfTile(atColumn: 40, row: 14)
        addChild(bag)

        bag.onOpened = { [weak self] in
            self?.playerUnlockedCharacter(.wiz)
            self?.playCelebration()
        }
    }

    private func playCelebration() {
        let flash = SKSpriteNode(color: Palette.celebSparkle,
                                 size: CGSize(width: size.width * 2, height: size.height * 2))
        flash.position  = .zero
        flash.zPosition = ZPos.ui - 1
        flash.alpha     = 0
        cam?.addChild(flash)

        flash.run(.sequence([
            .fadeAlpha(to: 0.5, duration: 0.08),
            .fadeOut(withDuration: 0.35),
            .removeFromParent()
        ]))
    }
}
