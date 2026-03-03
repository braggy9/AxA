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

        // Player starts centre-left of room (safe left zone)
        playerStartPosition = groundMap.centerOfTile(atColumn: 5, row: 12)

        roomTransitions = [.left: .crystalFields, .right: .saltCave]

        // Two knights on the right side (only reachable after grapple)
        enemySpawns = [
            (type: .saltKnight, col: 30, row: 17),
            (type: .saltKnight, col: 35, row: 7),
        ]

        addGrapplePoints()
    }

    private func addGrapplePoints() {
        // Gap is cols 14...24 (bridgeWater). Left ground: cols 2-13. Right ground: cols 25-38.
        // Posts sit at col 13 (left edge of gap). Player grapples to col 26 (right side of gap).
        // LandingOffset = (26 - 13) tiles * tileSize = 13 * 32 = 416pt
        let landingOffset = CGPoint(x: World.tileSize * 13, y: 0)

        let topPost = GrapplePointNode(landingOffset: landingOffset)
        topPost.position = groundMap.centerOfTile(atColumn: 13, row: 17)
        addChild(topPost)

        let bottomPost = GrapplePointNode(landingOffset: landingOffset)
        bottomPost.position = groundMap.centerOfTile(atColumn: 13, row: 7)
        addChild(bottomPost)
    }
}
