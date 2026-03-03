// CrystalFieldsScene.swift
// AxA — World 1, Room 2: Crystal Fields
// Open combat arena with salt ground, crystal clusters, and 4 Salt Knight enemies.
// Left edge transitions back to Spawn Beach.

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
        // (overridden by playerStartEdge from room transition if player came from beach)
        let startCol = World.crystalFieldsCols / 2
        let startRow = World.crystalFieldsRows / 2
        playerStartPosition = groundMap.centerOfTile(atColumn: startCol, row: startRow)

        roomTransitions = [.left: .spawnBeach, .right: .lakeShoreEast]

        // 4 Salt Knights spread across the room
        enemySpawns = [
            (type: .saltKnight, col: 4,  row: 7),   // top-left quadrant
            (type: .saltKnight, col: 15, row: 7),    // top-right quadrant
            (type: .saltKnight, col: 4,  row: 3),    // bottom-left quadrant
            (type: .saltKnight, col: 15, row: 3),    // bottom-right quadrant
        ]
    }
}
