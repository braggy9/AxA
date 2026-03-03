// SaltCaveScene.swift
// AxA — World 1, Room 4: Salt Cave
// Winding cave corridors. Two Salt Protectors guard this room.
// Breakable salt crystal walls hide the golden key.
// Locked door blocks the snack bag that unlocks Bob the Chicken.
// Dig spots for Bob hidden around the cave.
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

        // Player enters from left — start in left corridor
        playerStartPosition = groundMap.centerOfTile(atColumn: 3, row: 13)

        roomTransitions = [.left: .lakeShoreEast]

        // Two Salt Protectors in the main corridor
        enemySpawns = [
            (type: .saltProtector, col: 14, row: 13),
            (type: .saltProtector, col: 24, row: 22),
        ]

        addBreakableWalls()
        addKeyAndDoor()
        addDigSpots()
    }

    // MARK: - Breakable walls (cols 21-23, row 3-5 area — blocks key access)

    private func addBreakableWalls() {
        // 3×3 cluster of breakable walls blocking the key alcove
        let positions: [(col: Int, row: Int)] = [
            (21, 3), (22, 3), (23, 3),
            (21, 4), (22, 4), (23, 4),
            (21, 5), (22, 5), (23, 5),
        ]
        for p in positions {
            let wall = BreakableWallNode()
            wall.position = groundMap.centerOfTile(atColumn: p.col, row: p.row)
            addChild(wall)
        }
    }

    private func addKeyAndDoor() {
        // Key is deep in the lower corridor (past breakable walls)
        let key = KeyNode()
        key.position = groundMap.centerOfTile(atColumn: 29, row: 5)
        addChild(key)

        // Door blocks the snack bag at the far end of the upper corridor
        let door = LockedDoorNode()
        door.position = groundMap.centerOfTile(atColumn: 8, row: 22)
        door.onUnlocked = { [weak self] in
            self?.placeSnackBag()
        }
        addChild(door)
    }

    /// Called when the locked door opens — Bob's snack bag appears behind it.
    private func placeSnackBag() {
        let bag = SnackBagNode()
        bag.position = groundMap.centerOfTile(atColumn: 15, row: 23)
        addChild(bag)

        bag.onOpened = { [weak self] in
            self?.playerUnlockedCharacter(.bob)
            self?.playCelebration()
        }
    }

    /// Brief celebration effect when a character is unlocked.
    private func playCelebration() {
        let flash = SKSpriteNode(color: Palette.celebSparkle,
                                 size: CGSize(width: size.width * 2, height: size.height * 2))
        flash.position  = .zero
        flash.zPosition = ZPos.ui - 1
        flash.alpha     = 0
        cam?.addChild(flash)

        flash.run(.sequence([
            .fadeAlpha(to: 0.55, duration: 0.08),
            .fadeOut(withDuration: 0.35),
            .removeFromParent()
        ]))
    }

    // MARK: - Dig Spots (Bob-only secrets)

    private func addDigSpots() {
        // Two hidden dig spots — each yields 3 crystals
        let spotData: [(col: Int, row: Int)] = [
            (3,  5),    // lower-left corridor nook
            (27, 4),    // lower-right near key area
        ]
        for data in spotData {
            let spot = SoftGroundNode()
            spot.hiddenCrystals = 3
            spot.position = groundMap.centerOfTile(atColumn: data.col, row: data.row)
            addChild(spot)
        }
    }
}
