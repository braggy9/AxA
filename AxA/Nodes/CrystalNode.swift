// CrystalNode.swift
// AxA — Collectible salt crystal dropped by enemies.
// Floats gently in place. Player contact triggers collection.

import SpriteKit

final class CrystalNode: SKNode {

    // MARK: Callback

    /// Called when the player collects this crystal. Remove from scene after calling.
    var onCollected: (() -> Void)?

    // MARK: Private

    private let sprite: SKSpriteNode

    // MARK: Init

    override init() {
        sprite = SKSpriteNode(texture: CrystalNode.makeTexture(),
                              size: CGSize(width: 20, height: 20))
        super.init()

        addChild(sprite)
        zPosition = ZPos.object
        setupPhysics()
        startFloatAnimation()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: Collection

    func collect() {
        // Pop animation then remove
        let pop = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.6, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.1)
            ]),
            SKAction.removeFromParent()
        ])
        run(pop)
        onCollected?()
    }

    // MARK: Private — Physics

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 10)
        body.isDynamic = false
        body.affectedByGravity = false
        body.categoryBitMask    = PhysicsCategory.crystal
        body.collisionBitMask   = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player
        physicsBody = body
    }

    // MARK: Private — Animation

    private func startFloatAnimation() {
        let floatUp   = SKAction.moveBy(x: 0, y: 4, duration: 0.7)
        floatUp.timingMode = .easeInEaseOut
        let floatDown = SKAction.moveBy(x: 0, y: -4, duration: 0.7)
        floatDown.timingMode = .easeInEaseOut
        sprite.run(.repeatForever(.sequence([floatUp, floatDown])), withKey: "float")
    }

    // MARK: Private — Texture Generation

    private static func makeTexture() -> SKTexture {
        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            // Diamond shape
            c.setFillColor(Palette.crystal.cgColor)
            let diamond = CGMutablePath()
            diamond.move(to: CGPoint(x: 10, y: 19))
            diamond.addLine(to: CGPoint(x: 1,  y: 10))
            diamond.addLine(to: CGPoint(x: 10, y: 1))
            diamond.addLine(to: CGPoint(x: 19, y: 10))
            diamond.closeSubpath()
            c.addPath(diamond)
            c.fillPath()

            // Sparkle outline
            c.setStrokeColor(UIColor(red: 1, green: 0.6, blue: 0.7, alpha: 0.9).cgColor)
            c.setLineWidth(1)
            c.addPath(diamond)
            c.strokePath()

            // Inner facet lines
            c.setStrokeColor(UIColor(white: 1, alpha: 0.3).cgColor)
            c.setLineWidth(0.5)
            c.move(to: CGPoint(x: 10, y: 19))
            c.addLine(to: CGPoint(x: 10, y: 10))
            c.addLine(to: CGPoint(x: 1, y: 10))
            c.strokePath()

            // Highlight dot
            c.setFillColor(UIColor(white: 1, alpha: 0.8).cgColor)
            c.fillEllipse(in: CGRect(x: 7, y: 11, width: 4, height: 4))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return tex
    }
}
