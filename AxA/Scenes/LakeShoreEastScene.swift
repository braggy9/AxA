// LakeShoreEastScene.swift
// AxA — World 1, Room 3: Lake Shore East
// Broken bridge puzzle. Wiz uses his staff as a grappling hook to cross the water gap.
// Two Salt Knights patrol the right side (accessible only after grappling).
// Left edge → Crystal Fields | Right edge → Salt Cave

import SpriteKit
import GameplayKit

final class LakeShoreEastScene: BaseGameScene {

    override func subclassSetup() {
        mapCols = World.lakeShoreEastCols
        mapRows = World.lakeShoreEastRows

        let result = TileMapBuilder.buildLakeShoreEast()
        groundMap = result.ground
        groundMap.position = .zero
        addChild(groundMap)
        for wallNode in result.walls { addChild(wallNode) }

        // Player starts centre-left of room (right side of left zone)
        playerStartPosition = groundMap.centerOfTile(atColumn: 5, row: 5)

        roomTransitions = [.left: .crystalFields, .right: .saltCave]

        // Two knights on the right side (only reachable after grapple)
        enemySpawns = [
            (type: .saltKnight, col: 15, row: 7),
            (type: .saltKnight, col: 15, row: 3),
        ]

        // Grapple points at col 12 (right edge of gap), rows 8 and 2
        addGrapplePoints()
    }

    private func addGrapplePoints() {
        // The player stands on the left (col 7) and grapples to col 12.
        // Landing offset brings the player to col 13 (safely on solid ground).
        let landingOffset = CGPoint(x: World.tileSize * 1.5, y: 0)

        let topPost = GrapplePointNode(landingOffset: landingOffset)
        topPost.position = groundMap.centerOfTile(atColumn: 12, row: 8)
        addChild(topPost)

        let bottomPost = GrapplePointNode(landingOffset: landingOffset)
        bottomPost.position = groundMap.centerOfTile(atColumn: 12, row: 2)
        addChild(bottomPost)
    }
}
