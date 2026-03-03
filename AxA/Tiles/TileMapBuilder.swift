import SpriteKit

// MARK: - TileType

enum TileType: Int {
    case saltGround     = 0
    case saltSand       = 1
    case water          = 2
    case waterDeep      = 3
    case crystal        = 4
    case nonoTree       = 5
    case wall           = 6   // invisible barrier tile
    case bridgeWater    = 7   // water with broken plank visual — still blocks
    case caveFloor      = 8
    case caveWall       = 9   // solid cave wall — blocks
    case caveRock       = 10  // dark decorative rock — blocks
}

// MARK: - TileMapBuilder
// Builds SKTileMapNode programmatically using coloured placeholder textures.
// When real tilesets arrive, swap makeTexture(for:) to load from Assets.xcassets.

enum TileMapBuilder {

    /// Returns the ground tile map plus an array of invisible wall nodes.
    /// Add all returned nodes to the scene.
    static func buildSpawnBeach() -> (ground: SKTileMapNode, walls: [SKNode]) {
        let tileSize = CGSize(width: World.tileSize, height: World.tileSize)
        let cols = World.spawnBeachCols
        let rows = World.spawnBeachRows

        // Layout legend: ground layer
        // W = water, G = salt ground, S = sand, C = crystal, T = nono tree
        // Map is read top-to-bottom, left-to-right (row 0 = bottom)
        let groundLayout: [[TileType]] = [
            // Row 10 (top)
            [.water, .water, .water, .water, .water, .water, .water, .water, .water, .water,
             .water, .water, .water, .water, .water, .water, .water, .water, .water, .water],
            // Row 9
            [.water, .water, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand,
             .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .water, .water],
            // Row 8
            [.water, .saltSand, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .crystal, .saltGround,
             .saltGround, .crystal, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltSand, .saltSand, .water],
            // Row 7
            [.water, .saltSand, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltSand, .water],
            // Row 6
            [.water, .saltSand, .saltGround, .saltGround, .nonoTree, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .saltGround, .nonoTree, .saltGround, .saltGround, .saltGround, .saltGround, .saltSand, .water],
            // Row 5 (middle)
            [.water, .saltSand, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltSand, .water],
            // Row 4
            [.water, .saltSand, .saltGround, .saltGround, .saltGround, .saltGround, .crystal, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .crystal, .saltGround, .saltGround, .saltSand, .water],
            // Row 3
            [.water, .saltSand, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltSand, .water],
            // Row 2
            [.water, .saltSand, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltSand, .water],
            // Row 1
            [.water, .water, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand,
             .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .water, .water],
            // Row 0 (bottom)
            [.water, .water, .water, .water, .water, .water, .water, .water, .water, .water,
             .water, .water, .water, .water, .water, .water, .water, .water, .water, .water],
        ]

        // Build tile set from programmatic textures
        let tileGroups = TileType.allCases.map { type -> SKTileGroup in
            let tex = makeTexture(for: type)
            tex.filteringMode = .nearest
            let def = SKTileDefinition(texture: tex, size: tileSize)
            return SKTileGroup(tileDefinition: def)
        }

        let tileSet = SKTileSet(tileGroups: tileGroups)

        // Ground layer
        let groundMap = SKTileMapNode(tileSet: tileSet,
                                      columns: cols,
                                      rows: rows,
                                      tileSize: tileSize)
        groundMap.zPosition = TileConst.groundZ
        groundMap.enableAutomapping = false

        for (rowIndex, row) in groundLayout.enumerated() {
            for (colIndex, type) in row.enumerated() {
                let group = tileGroups[type.rawValue]
                groundMap.setTileGroup(group, forColumn: colIndex, row: rowIndex)
            }
        }

        // Build wall nodes for all blocking tiles
        let walls = buildWallNodes(from: groundLayout, map: groundMap, tileSize: tileSize)

        return (groundMap, walls)
    }

    // MARK: - Crystal Fields Map

    /// Builds the Crystal Fields room: open salt terrain, crystal clusters, 4 Salt Knights.
    /// 20 columns x 11 rows. Narrow water borders top/bottom, sand edges left/right.
    static func buildCrystalFields() -> (ground: SKTileMapNode, walls: [SKNode]) {
        let tileSize = CGSize(width: World.tileSize, height: World.tileSize)
        let cols = World.crystalFieldsCols
        let rows = World.crystalFieldsRows

        // Layout: mostly open salt ground for combat.
        // Crystal clusters (C) scattered in groups of 2-3.
        // Water border top/bottom (rows 10, 0), sand edges (rows 9, 1).
        let groundLayout: [[TileType]] = [
            // Row 10 (top)
            [.water, .water, .water, .water, .water, .water, .water, .water, .water, .water,
             .water, .water, .water, .water, .water, .water, .water, .water, .water, .water],
            // Row 9
            [.water, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand,
             .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .water],
            // Row 8 -- crystal cluster areas
            [.water, .saltSand, .saltGround, .crystal, .crystal, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .saltGround, .saltGround, .crystal, .crystal, .saltGround, .saltGround, .saltSand, .water],
            // Row 7
            [.water, .saltSand, .crystal, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .crystal, .saltGround, .saltGround, .saltSand, .water],
            // Row 6
            [.water, .saltSand, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltSand, .water],
            // Row 5 (middle -- wide open arena)
            [.water, .saltSand, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltSand, .water],
            // Row 4
            [.water, .saltSand, .saltGround, .saltGround, .saltGround, .crystal, .crystal, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .crystal, .crystal, .saltGround, .saltGround, .saltGround, .saltGround, .saltSand, .water],
            // Row 3
            [.water, .saltSand, .saltGround, .saltGround, .saltGround, .crystal, .saltGround, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .saltGround, .crystal, .saltGround, .saltGround, .saltGround, .saltGround, .saltSand, .water],
            // Row 2
            [.water, .saltSand, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround,
             .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltGround, .saltSand, .water],
            // Row 1
            [.water, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand,
             .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .saltSand, .water],
            // Row 0 (bottom)
            [.water, .water, .water, .water, .water, .water, .water, .water, .water, .water,
             .water, .water, .water, .water, .water, .water, .water, .water, .water, .water],
        ]

        let tileGroups = TileType.allCases.map { type -> SKTileGroup in
            let tex = makeTexture(for: type)
            tex.filteringMode = .nearest
            let def = SKTileDefinition(texture: tex, size: tileSize)
            return SKTileGroup(tileDefinition: def)
        }

        let tileSet = SKTileSet(tileGroups: tileGroups)

        let groundMap = SKTileMapNode(tileSet: tileSet,
                                      columns: cols,
                                      rows: rows,
                                      tileSize: tileSize)
        groundMap.zPosition = TileConst.groundZ
        groundMap.enableAutomapping = false

        for (rowIndex, row) in groundLayout.enumerated() {
            for (colIndex, type) in row.enumerated() {
                let group = tileGroups[type.rawValue]
                groundMap.setTileGroup(group, forColumn: colIndex, row: rowIndex)
            }
        }

        let walls = buildWallNodes(from: groundLayout, map: groundMap, tileSize: tileSize)

        return (groundMap, walls)
    }

    // MARK: - Lake Shore East

    static func buildLakeShoreEast() -> (ground: SKTileMapNode, walls: [SKNode]) {
        let tileSize = CGSize(width: World.tileSize, height: World.tileSize)
        let cols = World.lakeShoreEastCols
        let rows = World.lakeShoreEastRows
        // G=saltGround S=saltSand W=water B=bridgeWater
        // Cols 0-7: left safe zone | Cols 8-11: water gap with broken bridge | Cols 12-19: right zone
        let layout: [[TileType]] = [
            // Row 10 (top)
            [.water,.water,.water,.water,.water,.water,.water,.water,.water,.water,
             .water,.water,.water,.water,.water,.water,.water,.water,.water,.water],
            // Row 9
            [.water,.saltSand,.saltSand,.saltSand,.saltSand,.saltSand,.saltSand,.saltSand,.bridgeWater,.bridgeWater,
             .bridgeWater,.bridgeWater,.saltSand,.saltSand,.saltSand,.saltSand,.saltSand,.saltSand,.saltSand,.water],
            // Row 8
            [.water,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.bridgeWater,.bridgeWater,
             .bridgeWater,.bridgeWater,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.water],
            // Row 7
            [.water,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.water,.water,
             .water,.water,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.water],
            // Row 6
            [.water,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.water,.water,
             .water,.water,.saltSand,.saltGround,.saltGround,.crystal,.saltGround,.saltGround,.saltSand,.water],
            // Row 5 (middle)
            [.water,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.water,.water,
             .water,.water,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.water],
            // Row 4
            [.water,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.water,.water,
             .water,.water,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.water],
            // Row 3
            [.water,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.bridgeWater,.bridgeWater,
             .bridgeWater,.bridgeWater,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.water],
            // Row 2
            [.water,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.bridgeWater,.bridgeWater,
             .bridgeWater,.bridgeWater,.saltSand,.saltGround,.saltGround,.saltGround,.saltGround,.saltGround,.saltSand,.water],
            // Row 1
            [.water,.water,.saltSand,.saltSand,.saltSand,.saltSand,.saltSand,.saltSand,.bridgeWater,.bridgeWater,
             .bridgeWater,.bridgeWater,.saltSand,.saltSand,.saltSand,.saltSand,.saltSand,.saltSand,.water,.water],
            // Row 0 (bottom)
            [.water,.water,.water,.water,.water,.water,.water,.water,.water,.water,
             .water,.water,.water,.water,.water,.water,.water,.water,.water,.water],
        ]
        return buildMap(layout: layout, cols: cols, rows: rows, tileSize: tileSize)
    }

    // MARK: - Salt Cave

    static func buildSaltCave() -> (ground: SKTileMapNode, walls: [SKNode]) {
        let tileSize = CGSize(width: World.tileSize, height: World.tileSize)
        let cols = World.saltCaveCols
        let rows = World.saltCaveRows
        // F=caveFloor W=caveWall R=caveRock
        // Tight corridors with locked door alcove on right side
        let layout: [[TileType]] = [
            // Row 12 (top)
            [.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,
             .caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall],
            // Row 11
            [.caveWall,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveWall,.caveFloor,
             .caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveWall],
            // Row 10
            [.caveWall,.caveFloor,.caveRock,.caveRock,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveWall,.caveFloor,
             .caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveRock,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveWall],
            // Row 9 — upper corridor
            [.caveWall,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveWall,.caveFloor,
             .caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveWall],
            // Row 8 — wall separating corridors (gap in middle)
            [.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveFloor,.caveWall,.caveWall,.caveWall,.caveWall,
             .caveWall,.caveWall,.caveWall,.caveWall,.caveFloor,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall],
            // Row 7 — main corridor
            [.caveWall,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,
             .caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveWall],
            // Row 6
            [.caveWall,.caveFloor,.caveRock,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,
             .caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveRock,.caveFloor,.caveWall],
            // Row 5
            [.caveWall,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,
             .caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveWall],
            // Row 4 — wall separating corridors (gap on left + right)
            [.caveWall,.caveFloor,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,
             .caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveFloor,.caveWall],
            // Row 3 — lower corridor (hidden area with breakable walls)
            [.caveWall,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,
             .caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveWall],
            // Row 2
            [.caveWall,.caveFloor,.caveRock,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,
             .caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveRock,.caveFloor,.caveWall],
            // Row 1
            [.caveWall,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,
             .caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveFloor,.caveWall],
            // Row 0 (bottom)
            [.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,
             .caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall,.caveWall],
        ]
        return buildMap(layout: layout, cols: cols, rows: rows, tileSize: tileSize)
    }

    // MARK: - Shared map builder

    private static func buildMap(
        layout: [[TileType]],
        cols: Int,
        rows: Int,
        tileSize: CGSize
    ) -> (ground: SKTileMapNode, walls: [SKNode]) {
        let tileGroups = TileType.allCases.map { type -> SKTileGroup in
            let tex = makeTexture(for: type)
            tex.filteringMode = .nearest
            let def = SKTileDefinition(texture: tex, size: tileSize)
            return SKTileGroup(tileDefinition: def)
        }
        let tileSet = SKTileSet(tileGroups: tileGroups)
        let groundMap = SKTileMapNode(tileSet: tileSet, columns: cols, rows: rows, tileSize: tileSize)
        groundMap.zPosition = TileConst.groundZ
        groundMap.enableAutomapping = false
        for (rowIndex, row) in layout.enumerated() {
            for (colIndex, type) in row.enumerated() {
                groundMap.setTileGroup(tileGroups[type.rawValue], forColumn: colIndex, row: rowIndex)
            }
        }
        let walls = buildWallNodes(from: layout, map: groundMap, tileSize: tileSize)
        return (groundMap, walls)
    }

    // MARK: Physics
    // Each blocking tile gets its own invisible SKSpriteNode with a physics body.
    // Simple, reliable, and easy to debug.

    private static func buildWallNodes(
        from layout: [[TileType]],
        map: SKTileMapNode,
        tileSize: CGSize
    ) -> [SKNode] {
        var nodes: [SKNode] = []

        for (rowIndex, row) in layout.enumerated() {
            for (colIndex, type) in row.enumerated() {
                let isBlocking = type == .water || type == .waterDeep || type == .nonoTree
                    || type == .bridgeWater || type == .caveWall || type == .caveRock
                guard isBlocking else { continue }

                let wallNode = SKNode()
                wallNode.position = map.centerOfTile(atColumn: colIndex, row: rowIndex)
                wallNode.zPosition = TileConst.groundZ

                let body = SKPhysicsBody(rectangleOf: tileSize)
                body.isDynamic = false
                let isWallType = type == .nonoTree || type == .caveWall || type == .caveRock
                body.categoryBitMask    = isWallType ? PhysicsCategory.wall : PhysicsCategory.water
                body.collisionBitMask   = PhysicsCategory.player
                body.contactTestBitMask = PhysicsCategory.player
                body.restitution = 0
                wallNode.physicsBody = body

                nodes.append(wallNode)
            }
        }

        return nodes
    }

    // MARK: Texture Generation
    // Generates 16x16 placeholder coloured tiles. Replace with real asset loading later.

    static func makeTexture(for type: TileType) -> SKTexture {
        let size = CGSize(width: World.tileSize, height: World.tileSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            switch type {
            case .saltGround:
                c.setFillColor(Palette.saltGround.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Subtle noise dots
                c.setFillColor(UIColor(red: 0.85, green: 0.60, blue: 0.57, alpha: 0.5).cgColor)
                for _ in 0..<3 {
                    let x = CGFloat.random(in: 1..<15)
                    let y = CGFloat.random(in: 1..<15)
                    c.fillEllipse(in: CGRect(x: x, y: y, width: 1, height: 1))
                }
            case .saltSand:
                c.setFillColor(Palette.saltSand.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
            case .water:
                c.setFillColor(Palette.water.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Wave line
                c.setStrokeColor(UIColor(white: 1, alpha: 0.3).cgColor)
                c.setLineWidth(1)
                c.move(to: CGPoint(x: 2, y: 8))
                c.addLine(to: CGPoint(x: 6, y: 6))
                c.addLine(to: CGPoint(x: 10, y: 8))
                c.addLine(to: CGPoint(x: 14, y: 6))
                c.strokePath()
            case .waterDeep:
                c.setFillColor(Palette.waterDeep.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
            case .crystal:
                c.setFillColor(Palette.saltGround.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Pink crystal shape
                c.setFillColor(Palette.crystal.cgColor)
                let crystal = CGMutablePath()
                crystal.move(to: CGPoint(x: 8, y: 15))
                crystal.addLine(to: CGPoint(x: 5, y: 9))
                crystal.addLine(to: CGPoint(x: 8, y: 4))
                crystal.addLine(to: CGPoint(x: 11, y: 9))
                crystal.closeSubpath()
                c.addPath(crystal)
                c.fillPath()
                c.setStrokeColor(UIColor(red: 1, green: 0.6, blue: 0.7, alpha: 0.8).cgColor)
                c.setLineWidth(0.5)
                c.addPath(crystal)
                c.strokePath()
            case .nonoTree:
                // Ground under tree
                c.setFillColor(Palette.saltGround.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Trunk
                c.setFillColor(Palette.nonoTreeTrunk.cgColor)
                c.fill(CGRect(x: 6, y: 1, width: 4, height: 7))
                // Canopy
                c.setFillColor(Palette.nonoTreeLeaf.cgColor)
                c.fillEllipse(in: CGRect(x: 2, y: 7, width: 12, height: 9))
                // Highlight dot
                c.setFillColor(UIColor(red: 0.4, green: 0.85, blue: 0.4, alpha: 0.6).cgColor)
                c.fillEllipse(in: CGRect(x: 5, y: 10, width: 3, height: 3))
            case .wall:
                c.setFillColor(UIColor.clear.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
            case .bridgeWater:
                // Water with broken wooden plank remnants
                c.setFillColor(Palette.bridgeWater.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Wave
                c.setStrokeColor(UIColor(white: 1, alpha: 0.25).cgColor)
                c.setLineWidth(0.8)
                c.move(to: CGPoint(x: 1, y: 9)); c.addLine(to: CGPoint(x: 5, y: 7))
                c.addLine(to: CGPoint(x: 9, y: 9)); c.addLine(to: CGPoint(x: 13, y: 7))
                c.strokePath()
                // Broken plank fragments
                c.setFillColor(SKColor(red: 0.45, green: 0.30, blue: 0.12, alpha: 0.8).cgColor)
                c.fill(CGRect(x: 2, y: 11, width: 5, height: 2))
                c.fill(CGRect(x: 9, y: 4, width: 4, height: 2))
            case .caveFloor:
                c.setFillColor(Palette.caveFloor.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Stone texture dots
                c.setFillColor(UIColor(white: 1, alpha: 0.06).cgColor)
                c.fillEllipse(in: CGRect(x: 3, y: 3, width: 2, height: 2))
                c.fillEllipse(in: CGRect(x: 10, y: 8, width: 1.5, height: 1.5))
                c.fillEllipse(in: CGRect(x: 7, y: 12, width: 2, height: 1.5))
            case .caveWall:
                c.setFillColor(Palette.caveWall.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Subtle highlight
                c.setStrokeColor(UIColor(white: 1, alpha: 0.08).cgColor)
                c.setLineWidth(0.5)
                c.move(to: CGPoint(x: 0, y: 4)); c.addLine(to: CGPoint(x: 8, y: 4))
                c.move(to: CGPoint(x: 6, y: 10)); c.addLine(to: CGPoint(x: 16, y: 10))
                c.strokePath()
            case .caveRock:
                c.setFillColor(Palette.caveRock.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Rock outline
                c.setStrokeColor(UIColor(white: 0, alpha: 0.3).cgColor)
                c.setLineWidth(0.5)
                c.stroke(CGRect(x: 0.5, y: 0.5, width: size.width - 1, height: size.height - 1))
            }
        }
        return SKTexture(image: img)
    }
}

// MARK: - TileType + CaseIterable
extension TileType: CaseIterable {}
