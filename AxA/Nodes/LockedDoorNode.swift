// LockedDoorNode.swift
// AxA — A wooden locked door that opens when the player has the cave key.

import SpriteKit

final class LockedDoorNode: SKNode {

    var onUnlocked: (() -> Void)?
    private let sprite: SKSpriteNode
    private var isOpen = false

    override init() {
        sprite = SKSpriteNode(texture: LockedDoorNode.makeTexture(locked: true),
                              size: CGSize(width: World.tileSize, height: World.tileSize * 2))
        sprite.zPosition = ZPos.object
        super.init()
        addChild(sprite)
        setupPhysics()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func tryUnlock(playerHasKey: Bool) {
        guard !isOpen, playerHasKey else { return }
        unlock()
    }

    private func unlock() {
        isOpen = true
        physicsBody = nil
        let openAnim = SKAction.sequence([
            SKAction.colorize(with: .yellow, colorBlendFactor: 0.8, duration: 0.12),
            SKAction.group([
                SKAction.scaleX(to: 0.05, duration: 0.25),
                SKAction.colorize(withColorBlendFactor: 0, duration: 0.25)
            ]),
            SKAction.removeFromParent()
        ])
        run(openAnim)
        onUnlocked?()
    }

    private func setupPhysics() {
        let size = CGSize(width: World.tileSize, height: World.tileSize * 2)
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = false
        body.categoryBitMask    = PhysicsCategory.door
        body.collisionBitMask   = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.player
        physicsBody = body
    }

    private static func makeTexture(locked: Bool) -> SKTexture {
        let size = CGSize(width: World.tileSize, height: World.tileSize * 2)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            // Door body
            c.setFillColor(Palette.lockedDoor.cgColor)
            c.fill(CGRect(origin: .zero, size: size))

            // Wood grain lines
            c.setStrokeColor(UIColor(white: 0, alpha: 0.25).cgColor)
            c.setLineWidth(0.5)
            for y in stride(from: 3, to: Int(size.height), by: 4) {
                c.move(to: CGPoint(x: 1, y: CGFloat(y)))
                c.addLine(to: CGPoint(x: size.width - 1, y: CGFloat(y)))
            }
            c.strokePath()

            // Frame
            c.setStrokeColor(UIColor(white: 0, alpha: 0.4).cgColor)
            c.setLineWidth(1)
            c.stroke(CGRect(x: 0.5, y: 0.5, width: size.width - 1, height: size.height - 1))

            // Lock icon (padlock shape)
            if locked {
                c.setFillColor(Palette.keyGold.cgColor)
                // Lock body
                c.fill(CGRect(x: 4, y: 12, width: 8, height: 6))
                // Lock shackle
                c.setStrokeColor(Palette.keyGold.cgColor)
                c.setLineWidth(2)
                let shacklePath = CGMutablePath()
                shacklePath.move(to: CGPoint(x: 5, y: 12))
                shacklePath.addArc(center: CGPoint(x: 8, y: 12), radius: 3,
                                   startAngle: .pi, endAngle: 0, clockwise: true)
                shacklePath.addLine(to: CGPoint(x: 11, y: 12))
                c.addPath(shacklePath)
                c.strokePath()
                // Keyhole
                c.setFillColor(UIColor(white: 0, alpha: 0.5).cgColor)
                c.fillEllipse(in: CGRect(x: 7, y: 13, width: 2, height: 2))
            }
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return tex
    }
}
