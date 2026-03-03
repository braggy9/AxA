// KeyNode.swift
// AxA — A golden key collectible hidden behind breakable walls in the Salt Cave.

import SpriteKit

final class KeyNode: SKNode {

    var onCollected: (() -> Void)?
    private let sprite: SKSpriteNode

    override init() {
        sprite = SKSpriteNode(texture: KeyNode.makeTexture(),
                              size: CGSize(width: 10, height: 10))
        super.init()
        addChild(sprite)
        zPosition = ZPos.object
        setupPhysics()

        // Float + glow
        let floatUp   = SKAction.moveBy(x: 0, y: 2.5, duration: 0.6)
        let floatDown = SKAction.moveBy(x: 0, y: -2.5, duration: 0.6)
        floatUp.timingMode  = .easeInEaseOut
        floatDown.timingMode = .easeInEaseOut
        sprite.run(.repeatForever(.sequence([floatUp, floatDown])))

        let glowOn  = SKAction.colorize(with: .yellow, colorBlendFactor: 0.4, duration: 0.5)
        let glowOff = SKAction.colorize(withColorBlendFactor: 0, duration: 0.5)
        sprite.run(.repeatForever(.sequence([glowOn, glowOff])))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func collect() {
        physicsBody = nil
        let pop = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.8, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.12)
            ]),
            SKAction.removeFromParent()
        ])
        run(pop)
        onCollected?()
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 5)
        body.isDynamic = false
        body.affectedByGravity = false
        body.categoryBitMask    = PhysicsCategory.key
        body.collisionBitMask   = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player
        physicsBody = body
    }

    private static func makeTexture() -> SKTexture {
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            // Key head (circle)
            c.setFillColor(Palette.keyGold.cgColor)
            c.fillEllipse(in: CGRect(x: 1, y: 5, width: 5, height: 5))
            c.setStrokeColor(UIColor(red: 0.7, green: 0.55, blue: 0.1, alpha: 1).cgColor)
            c.setLineWidth(0.5)
            c.strokeEllipse(in: CGRect(x: 1, y: 5, width: 5, height: 5))

            // Key hole
            c.setFillColor(UIColor(white: 0, alpha: 0.4).cgColor)
            c.fillEllipse(in: CGRect(x: 2.5, y: 6.5, width: 2, height: 2))

            // Shaft
            c.setFillColor(Palette.keyGold.cgColor)
            c.fill(CGRect(x: 5, y: 7, width: 5, height: 1.5))

            // Teeth
            c.fill(CGRect(x: 7, y: 5.5, width: 1, height: 1.5))
            c.fill(CGRect(x: 9, y: 5.5, width: 1, height: 1.5))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return tex
    }
}
