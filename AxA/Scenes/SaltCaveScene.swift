// SaltCaveScene.swift
// AxA — World 1, Room 4: Salt Cave
// Tight cave corridors. Two Salt Protectors guard this room.
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

        playerStartPosition = groundMap.centerOfTile(atColumn: 2, row: 7)

        roomTransitions = [.left: .lakeShoreEast]

        // Two Salt Protectors in the main corridor
        enemySpawns = [
            (type: .saltProtector, col: 8,  row: 7),
            (type: .saltProtector, col: 14, row: 3),
        ]

        addBreakableWalls()
        addKeyAndDoor()
        addDigSpots()
    }

    private func addBreakableWalls() {
        let breakableCols = [13, 14, 15]
        for col in breakableCols {
            let wall = BreakableWallNode()
            wall.position = groundMap.centerOfTile(atColumn: col, row: 1)
            addChild(wall)
        }
    }

    private func addKeyAndDoor() {
        let key = KeyNode()
        key.position = groundMap.centerOfTile(atColumn: 17, row: 2)
        addChild(key)

        let door = LockedDoorNode()
        door.position = groundMap.centerOfTile(atColumn: 14, row: 9)
        door.onUnlocked = { [weak self] in
            self?.placeSnackBag()
        }
        addChild(door)
    }

    /// Called when the locked door opens — Bob's snack bag appears behind it.
    private func placeSnackBag() {
        let bag = SnackBagNode()
        bag.position = groundMap.centerOfTile(atColumn: 14, row: 10)
        addChild(bag)

        // Opening the bag unlocks Bob and switches to him
        bag.onOpened = { [weak self] in
            self?.playerUnlockedCharacter(.bob)
            self?.playCelebration()
        }
    }

    /// Brief celebration effect when Bob is unlocked.
    private func playCelebration() {
        // Screen flash
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
        // Two hidden dig spots around the cave — each yields 3 crystals
        let spotData: [(col: Int, row: Int)] = [
            (3,  2),    // lower-left corner nook
            (17, 8),    // far-right passage near the door area
        ]
        for data in spotData {
            let spot = SoftGroundNode()
            spot.hiddenCrystals = 3
            spot.position = groundMap.centerOfTile(atColumn: data.col, row: data.row)
            addChild(spot)
        }
    }
}
