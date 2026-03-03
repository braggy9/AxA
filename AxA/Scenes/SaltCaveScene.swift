// SaltCaveScene.swift
// AxA — World 1, Room 4: Salt Cave
// Tight cave corridors. Two Salt Protectors guard this room.
// Breakable salt crystal walls hide the golden key.
// Locked door blocks the snack bag that unlocks Bob the Chicken.
// Left edge → Lake Shore East

import SpriteKit
import GameplayKit

final class SaltCaveScene: BaseGameScene {

    override func subclassSetup() {
        mapCols = World.saltCaveCols
        mapRows = World.saltCaveRows

        backgroundColor = Palette.caveWall

        let result = TileMapBuilder.buildSaltCave()
        groundMap = result.ground
        groundMap.position = .zero
        addChild(groundMap)
        for wallNode in result.walls { addChild(wallNode) }

        playerStartPosition = groundMap.centerOfTile(atColumn: 2, row: 7)

        roomTransitions = [.left: .lakeShoreEast]

        // Two Salt Protectors in the main corridor
        enemySpawns = [
            (type: .saltProtector, col: 8,  row: 7),
            (type: .saltProtector, col: 14, row: 3),
        ]

        addBreakableWalls()
        addKeyAndDoor()
    }

    private func addBreakableWalls() {
        // Three breakable walls in the lower corridor blocking the key alcove
        let breakableCols = [13, 14, 15]
        for col in breakableCols {
            let wall = BreakableWallNode()
            wall.position = groundMap.centerOfTile(atColumn: col, row: 1)
            addChild(wall)
        }
    }

    private func addKeyAndDoor() {
        // Key sits in the hidden alcove behind the breakable walls (col 16, row 1)
        let key = KeyNode()
        key.position = groundMap.centerOfTile(atColumn: 17, row: 2)
        addChild(key)

        // Locked door in the upper corridor guards the snack bag alcove
        let door = LockedDoorNode()
        door.position = groundMap.centerOfTile(atColumn: 14, row: 9)
        // Opening the door just removes it — the snack bag system comes in Stage 4
        door.onUnlocked = { /* Stage 4: reveal snack bag + Bob unlock */ }
        addChild(door)
    }
}
