// BreakableWallNode.swift
// AxA — A salt crystal wall that shatters when attacked.
// Place over blocking tile positions in the Salt Cave.

import SpriteKit

final class BreakableWallNode: SKNode {

    var onShattered: (() -> Void)?

    private let sprite: SKSpriteNode
    private var hp = 1   // one hit to break

    override init() {
        sprite = SKSpriteNode(texture: BreakableWallNode.makeTexture(),
                              size: CGSize(width: World.tileSize, height: World.tileSize))
        sprite.zPosition = ZPos.object
        super.init()
        addChild(sprite)
        setupPhysics()

        // Faint shimmer so player notices it's different
        let shimmer = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.3, duration: 0.8),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.8)
        ])
        sprite.run(.repeatForever(shimmer))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func takeDamage() {
        hp -= 1
        if hp <= 0 { shatter() }
    }

    private func shatter() {
        physicsBody = nil   // remove collision immediately
        let shatterAnim = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.3, duration: 0.08),
                SKAction.colorize(with: .white, colorBlendFactor: 1, duration: 0.08)
            ]),
            SKAction.group([
                SKAction.scale(to: 0, duration: 0.18),
                SKAction.fadeOut(withDuration: 0.18)
            ]),
            SKAction.removeFromParent()
        ])
        run(shatterAnim)
        onShattered?()
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: CGSize(width: World.tileSize, height: World.tileSize))
        body.isDynamic = false
        body.categoryBitMask    = PhysicsCategory.breakableWall
        body.collisionBitMask   = PhysicsCategory.player | PhysicsCategory.enemy
        body.contactTestBitMask = PhysicsCategory.projectile  // player attack hitbox
        physicsBody = body
    }

    private static func makeTexture() -> SKTexture {
        let size = CGSize(width: World.tileSize, height: World.tileSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            // Base: pink crystal wall
            c.setFillColor(Palette.saltCrystalWall.cgColor)
            c.fill(CGRect(origin: .zero, size: size))

            // Crystal facets
            c.setStrokeColor(UIColor(white: 1, alpha: 0.4).cgColor)
            c.setLineWidth(0.5)

            // Diagonal cracks suggesting crystal structure
            c.move(to: CGPoint(x: 0, y: 6));  c.addLine(to: CGPoint(x: 6, y: 12))
            c.move(to: CGPoint(x: 4, y: 0));  c.addLine(to: CGPoint(x: 16, y: 10))
            c.move(to: CGPoint(x: 8, y: 2));  c.addLine(to: CGPoint(x: 2, y: 14))
            c.move(to: CGPoint(x: 12, y: 0)); c.addLine(to: CGPoint(x: 16, y: 6))
            c.strokePath()

            // Dark border
            c.setStrokeColor(UIColor(white: 0, alpha: 0.3).cgColor)
            c.setLineWidth(1)
            c.stroke(CGRect(x: 0.5, y: 0.5, width: size.width - 1, height: size.height - 1))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return tex
    }
}
