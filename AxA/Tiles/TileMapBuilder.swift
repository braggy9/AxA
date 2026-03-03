import SpriteKit

// MARK: - TileType

enum TileType: Int {
    case saltGround  = 0
    case saltSand    = 1
    case water       = 2
    case waterDeep   = 3
    case crystal     = 4
    case nonoTree    = 5
    case wall        = 6   // invisible barrier tile
    case bridgeWater = 7   // water with broken plank visual — still blocks
    case caveFloor   = 8
    case caveWall    = 9   // solid cave wall — blocks
    case caveRock    = 10  // dark decorative rock — blocks
    case saltRock    = 11  // outdoor blocking rock formation
}

// MARK: - TileMapBuilder
// Builds SKTileMapNode programmatically using coloured placeholder textures.
// When real tilesets arrive, swap makeTexture(for:) to load from Assets.xcassets.

enum TileMapBuilder {

    // MARK: - Layout Helpers

    /// Create outdoor beach-style base layout (water 2-deep border, sand edge, ground interior)
    private static func beachBase(cols: Int, rows: Int) -> [[TileType]] {
        var layout = Array(repeating: Array(repeating: TileType.saltGround, count: cols), count: rows)
        for r in 0..<rows {
            for c in 0..<cols {
                if r < 2 || r >= rows - 2 || c < 1 || c >= cols - 1 {
                    layout[r][c] = .water
                } else if r == 2 || r == rows - 3 || c == 1 || c == cols - 2 {
                    layout[r][c] = .saltSand
                }
            }
        }
        return layout
    }

    /// Set single tile, safe bounds check
    private static func set(_ type: TileType, col: Int, row: Int, in layout: inout [[TileType]]) {
        guard row >= 0 && row < layout.count && col >= 0 && col < layout[row].count else { return }
        layout[row][col] = type
    }

    /// Set multiple tiles
    private static func setMany(_ type: TileType, positions: [(col: Int, row: Int)], in layout: inout [[TileType]]) {
        for p in positions { set(type, col: p.col, row: p.row, in: &layout) }
    }

    /// Fill rectangle
    private static func fillRect(_ type: TileType, cols: ClosedRange<Int>, rows: ClosedRange<Int>, in layout: inout [[TileType]]) {
        for r in rows { for c in cols { set(type, col: c, row: r, in: &layout) } }
    }

    // MARK: - Spawn Beach (38 × 26)

    static func buildSpawnBeach() -> (ground: SKTileMapNode, walls: [SKNode]) {
        let tileSize = CGSize(width: World.tileSize, height: World.tileSize)
        let cols = World.spawnBeachCols
        let rows = World.spawnBeachRows

        var layout = beachBase(cols: cols, rows: rows)

        // Nono trees (T): 10 trees scattered for variety and light blockage
        let trees: [(col: Int, row: Int)] = [
            (5, 21), (10, 18), (18, 22), (25, 18), (32, 21),
            (8, 11), (20, 14), (30, 11), (14, 7),  (26, 7)
        ]
        setMany(.nonoTree, positions: trees, in: &layout)

        // Crystals (C): 12 crystals — rewarding exploration of the whole room
        let crystals: [(col: Int, row: Int)] = [
            (7, 19), (13, 19), (22, 19), (29, 19),
            (5, 14), (11, 14), (26, 14), (32, 14),
            (15, 9), (23, 9), (10, 5), (28, 5)
        ]
        setMany(.crystal, positions: crystals, in: &layout)

        // Salt rocks (K): rock formations for cover and interest
        let rocks: [(col: Int, row: Int)] = [
            (12, 21), (13, 21), (24, 21), (25, 21),
            (17, 12), (18, 12)
        ]
        setMany(.saltRock, positions: rocks, in: &layout)

        return buildMap(layout: layout, cols: cols, rows: rows, tileSize: tileSize)
    }

    // MARK: - Crystal Fields (44 × 28)

    static func buildCrystalFields() -> (ground: SKTileMapNode, walls: [SKNode]) {
        let tileSize = CGSize(width: World.tileSize, height: World.tileSize)
        let cols = World.crystalFieldsCols
        let rows = World.crystalFieldsRows

        var layout = beachBase(cols: cols, rows: rows)

        // Heavy crystal clusters in multiple groups
        let crystalPositions: [(col: Int, row: Int)] = [
            // Group 1 (bottom-left corner area)
            (4, 24), (5, 24), (4, 23), (5, 23),
            // Group 2
            (15, 24), (16, 24),
            // Group 3
            (28, 24), (29, 24), (28, 23),
            // Group 4 (bottom-right)
            (38, 24), (39, 24), (38, 23),
            // Group 5 (left mid)
            (4, 14), (5, 14), (4, 13),
            // Group 6 (centre)
            (20, 18), (21, 18), (20, 17), (21, 17),
            // Group 7 (right mid)
            (35, 14), (36, 14),
            // Group 8 (upper left)
            (10, 8), (11, 8), (10, 7),
            // Group 9 (upper centre)
            (25, 8), (26, 8), (25, 7),
            // Group 10 (upper right)
            (38, 8), (39, 8)
        ]
        setMany(.crystal, positions: crystalPositions, in: &layout)

        // Salt rocks: cover for combat and navigational texture
        let rockPositions: [(col: Int, row: Int)] = [
            (7, 24), (8, 24),
            (18, 21), (19, 21),
            (30, 18), (31, 18),
            (7, 11), (8, 11),
            (33, 11), (34, 11),
            (18, 5), (19, 5),
            (28, 5), (29, 5)
        ]
        setMany(.saltRock, positions: rockPositions, in: &layout)

        // Nono trees: a few for variety
        let trees: [(col: Int, row: Int)] = [
            (13, 24), (27, 21), (13, 11), (35, 7)
        ]
        setMany(.nonoTree, positions: trees, in: &layout)

        return buildMap(layout: layout, cols: cols, rows: rows, tileSize: tileSize)
    }

    // MARK: - Lake Shore East (40 × 24)

    static func buildLakeShoreEast() -> (ground: SKTileMapNode, walls: [SKNode]) {
        let tileSize = CGSize(width: World.tileSize, height: World.tileSize)
        let cols = World.lakeShoreEastCols
        let rows = World.lakeShoreEastRows

        var layout = beachBase(cols: cols, rows: rows)

        // Bridge water gap spanning most of the map vertically
        fillRect(.bridgeWater, cols: 14...24, rows: 3...20, in: &layout)

        // Crystals on right side (post-grapple reward)
        let rightCrystals: [(col: Int, row: Int)] = [
            (27, 18), (32, 14), (36, 10), (28, 8)
        ]
        setMany(.crystal, positions: rightCrystals, in: &layout)

        // Crystals on left side (pre-grapple reward)
        let leftCrystals: [(col: Int, row: Int)] = [
            (4, 18), (8, 14), (4, 8)
        ]
        setMany(.crystal, positions: leftCrystals, in: &layout)

        return buildMap(layout: layout, cols: cols, rows: rows, tileSize: tileSize)
    }

    // MARK: - Salt Cave (36 × 28)

    static func buildSaltCave() -> (ground: SKTileMapNode, walls: [SKNode]) {
        let tileSize = CGSize(width: World.tileSize, height: World.tileSize)
        let cols = World.saltCaveCols
        let rows = World.saltCaveRows

        // Start all walls
        var layout = Array(repeating: Array(repeating: TileType.caveWall, count: cols), count: rows)

        // Carve corridors
        // Main corridor (wide horizontal)
        fillRect(.caveFloor, cols: 1...34, rows: 10...16, in: &layout)
        // Upper corridor
        fillRect(.caveFloor, cols: 8...34, rows: 20...25, in: &layout)
        // Lower corridor
        fillRect(.caveFloor, cols: 1...34, rows: 3...7, in: &layout)
        // Left vertical connector
        fillRect(.caveFloor, cols: 1...6, rows: 7...20, in: &layout)
        // Right vertical connector
        fillRect(.caveFloor, cols: 29...34, rows: 14...21, in: &layout)
        // Junction: left connector to upper corridor
        fillRect(.caveFloor, cols: 5...9, rows: 18...21, in: &layout)

        // Cave rock decorations scattered in corridors
        let rockPositions: [(col: Int, row: Int)] = [
            (3, 13), (4, 13),    // left of main corridor
            (16, 12), (17, 12),  // mid-main
            (26, 15), (27, 15),  // right of main
            (10, 22), (11, 22),  // upper corridor
            (22, 23), (23, 23),  // upper corridor mid
            (3, 5), (4, 5),      // lower corridor
            (20, 6), (21, 6),    // lower corridor mid
            (30, 4), (31, 4)     // lower corridor right
        ]
        for pos in rockPositions {
            set(.caveRock, col: pos.col, row: pos.row, in: &layout)
        }

        return buildMap(layout: layout, cols: cols, rows: rows, tileSize: tileSize)
    }

    // MARK: - Shared Map Builder

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

    // MARK: - Physics Wall Nodes

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
                    || type == .saltRock
                guard isBlocking else { continue }

                let wallNode = SKNode()
                wallNode.position = map.centerOfTile(atColumn: colIndex, row: rowIndex)
                wallNode.zPosition = TileConst.groundZ

                let body = SKPhysicsBody(rectangleOf: tileSize)
                body.isDynamic = false
                let isWallType = type == .nonoTree || type == .caveWall || type == .caveRock || type == .saltRock
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

    // MARK: - Texture Generation
    // Generates placeholder coloured tiles at tileSize. Replace with real asset loading later.

    static func makeTexture(for type: TileType) -> SKTexture {
        let size = CGSize(width: World.tileSize, height: World.tileSize)
        let s = World.tileSize   // convenience shorthand
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            switch type {

            case .saltGround:
                c.setFillColor(Palette.saltGround.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Subtle noise dots
                c.setFillColor(UIColor(red: 0.85, green: 0.60, blue: 0.57, alpha: 0.5).cgColor)
                for _ in 0..<5 {
                    let x = CGFloat.random(in: 2..<s - 2)
                    let y = CGFloat.random(in: 2..<s - 2)
                    c.fillEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                }

            case .saltSand:
                c.setFillColor(Palette.saltSand.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Light ripple line
                c.setStrokeColor(UIColor(red: 0.92, green: 0.78, blue: 0.68, alpha: 0.6).cgColor)
                c.setLineWidth(1)
                c.move(to: CGPoint(x: 4, y: s * 0.4))
                c.addLine(to: CGPoint(x: s - 4, y: s * 0.4))
                c.strokePath()

            case .water:
                c.setFillColor(Palette.water.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Wave lines
                c.setStrokeColor(UIColor(white: 1, alpha: 0.3).cgColor)
                c.setLineWidth(1)
                c.move(to: CGPoint(x: 4, y: s * 0.5))
                c.addLine(to: CGPoint(x: s * 0.4, y: s * 0.38))
                c.addLine(to: CGPoint(x: s * 0.65, y: s * 0.5))
                c.addLine(to: CGPoint(x: s - 4, y: s * 0.38))
                c.strokePath()

            case .waterDeep:
                c.setFillColor(Palette.waterDeep.cgColor)
                c.fill(CGRect(origin: .zero, size: size))

            case .crystal:
                c.setFillColor(Palette.saltGround.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Pink crystal shape — larger for 32pt tile
                c.setFillColor(Palette.crystal.cgColor)
                let crystal = CGMutablePath()
                crystal.move(to:    CGPoint(x: s * 0.5,  y: s * 0.9))
                crystal.addLine(to: CGPoint(x: s * 0.3,  y: s * 0.55))
                crystal.addLine(to: CGPoint(x: s * 0.5,  y: s * 0.22))
                crystal.addLine(to: CGPoint(x: s * 0.7,  y: s * 0.55))
                crystal.closeSubpath()
                c.addPath(crystal)
                c.fillPath()
                c.setStrokeColor(UIColor(red: 1, green: 0.6, blue: 0.7, alpha: 0.8).cgColor)
                c.setLineWidth(1)
                c.addPath(crystal)
                c.strokePath()
                // Inner highlight
                c.setFillColor(UIColor(white: 1, alpha: 0.4).cgColor)
                c.fillEllipse(in: CGRect(x: s * 0.4, y: s * 0.5, width: s * 0.12, height: s * 0.12))

            case .nonoTree:
                // Ground under tree
                c.setFillColor(Palette.saltGround.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Trunk — proportionally scaled
                c.setFillColor(Palette.nonoTreeTrunk.cgColor)
                c.fill(CGRect(x: s * 0.36, y: s * 0.04, width: s * 0.28, height: s * 0.42))
                // Canopy — round green blob
                c.setFillColor(Palette.nonoTreeLeaf.cgColor)
                c.fillEllipse(in: CGRect(x: s * 0.1, y: s * 0.42, width: s * 0.8, height: s * 0.54))
                // Highlight on canopy
                c.setFillColor(UIColor(red: 0.4, green: 0.85, blue: 0.4, alpha: 0.55).cgColor)
                c.fillEllipse(in: CGRect(x: s * 0.28, y: s * 0.62, width: s * 0.22, height: s * 0.18))
                // Eyes — two small white dots in the canopy
                c.setFillColor(UIColor.white.cgColor)
                c.fillEllipse(in: CGRect(x: s * 0.28, y: s * 0.72, width: s * 0.12, height: s * 0.12))
                c.fillEllipse(in: CGRect(x: s * 0.54, y: s * 0.72, width: s * 0.12, height: s * 0.12))
                // Pupils
                c.setFillColor(UIColor.black.cgColor)
                c.fillEllipse(in: CGRect(x: s * 0.31, y: s * 0.74, width: s * 0.06, height: s * 0.06))
                c.fillEllipse(in: CGRect(x: s * 0.57, y: s * 0.74, width: s * 0.06, height: s * 0.06))
                // Worried mouth — small horizontal line with slight downward curve
                c.setStrokeColor(UIColor.black.cgColor)
                c.setLineWidth(1.2)
                c.move(to:    CGPoint(x: s * 0.35, y: s * 0.66))
                c.addLine(to: CGPoint(x: s * 0.50, y: s * 0.63))
                c.addLine(to: CGPoint(x: s * 0.65, y: s * 0.66))
                c.strokePath()

            case .wall:
                c.setFillColor(UIColor.clear.cgColor)
                c.fill(CGRect(origin: .zero, size: size))

            case .bridgeWater:
                c.setFillColor(Palette.bridgeWater.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Wave
                c.setStrokeColor(UIColor(white: 1, alpha: 0.25).cgColor)
                c.setLineWidth(1)
                c.move(to: CGPoint(x: 2, y: s * 0.55))
                c.addLine(to: CGPoint(x: s * 0.3, y: s * 0.43))
                c.addLine(to: CGPoint(x: s * 0.6, y: s * 0.55))
                c.addLine(to: CGPoint(x: s - 2, y: s * 0.43))
                c.strokePath()
                // Broken plank fragments
                c.setFillColor(SKColor(red: 0.45, green: 0.30, blue: 0.12, alpha: 0.8).cgColor)
                c.fill(CGRect(x: s * 0.06, y: s * 0.65, width: s * 0.35, height: s * 0.1))
                c.fill(CGRect(x: s * 0.55, y: s * 0.25, width: s * 0.28, height: s * 0.1))

            case .caveFloor:
                c.setFillColor(Palette.caveFloor.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Stone texture dots
                c.setFillColor(UIColor(white: 1, alpha: 0.06).cgColor)
                c.fillEllipse(in: CGRect(x: s * 0.12, y: s * 0.12, width: s * 0.1, height: s * 0.1))
                c.fillEllipse(in: CGRect(x: s * 0.55, y: s * 0.40, width: s * 0.08, height: s * 0.08))
                c.fillEllipse(in: CGRect(x: s * 0.32, y: s * 0.68, width: s * 0.1, height: s * 0.08))

            case .caveWall:
                c.setFillColor(Palette.caveWall.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Subtle highlight lines
                c.setStrokeColor(UIColor(white: 1, alpha: 0.08).cgColor)
                c.setLineWidth(0.5)
                c.move(to: CGPoint(x: 0, y: s * 0.25))
                c.addLine(to: CGPoint(x: s * 0.5, y: s * 0.25))
                c.move(to: CGPoint(x: s * 0.38, y: s * 0.62))
                c.addLine(to: CGPoint(x: s, y: s * 0.62))
                c.strokePath()

            case .caveRock:
                c.setFillColor(Palette.caveRock.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Rock outline
                c.setStrokeColor(UIColor(white: 0, alpha: 0.3).cgColor)
                c.setLineWidth(1)
                c.stroke(CGRect(x: 1, y: 1, width: s - 2, height: s - 2).insetBy(dx: 1, dy: 1))

            case .saltRock:
                // Ground background
                c.setFillColor(Palette.saltGround.cgColor)
                c.fill(CGRect(origin: .zero, size: size))
                // Main boulder — rounded rectangle
                c.setFillColor(Palette.saltRock.cgColor)
                let boulderRect = CGRect(x: s * 0.06, y: s * 0.06, width: s * 0.88, height: s * 0.82)
                let boulderPath = UIBezierPath(roundedRect: boulderRect, cornerRadius: s * 0.28)
                c.addPath(boulderPath.cgPath)
                c.fillPath()
                // Highlight — lighter upper-left
                c.setFillColor(UIColor(red: 0.90, green: 0.80, blue: 0.78, alpha: 0.7).cgColor)
                let highlightRect = CGRect(x: s * 0.14, y: s * 0.50, width: s * 0.42, height: s * 0.25)
                let highlightPath = UIBezierPath(roundedRect: highlightRect, cornerRadius: s * 0.12)
                c.addPath(highlightPath.cgPath)
                c.fillPath()
                // Dark outline
                c.setStrokeColor(UIColor(red: 0.55, green: 0.42, blue: 0.40, alpha: 0.7).cgColor)
                c.setLineWidth(1.2)
                c.addPath(boulderPath.cgPath)
                c.strokePath()
            }
        }
        return SKTexture(image: img)
    }
}

// MARK: - TileType + CaseIterable
extension TileType: CaseIterable {}
