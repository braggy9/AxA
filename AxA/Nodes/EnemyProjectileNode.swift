// EnemyProjectileNode.swift
// AxA — A crystal shard fired by the Salt Protector.

import SpriteKit

final class EnemyProjectileNode: SKNode {

    override init() {
        super.init()
        let sprite = SKSpriteNode(texture: EnemyProjectileNode.makeTexture(),
                                  size: EnemyProjectileConst.size)
        sprite.zPosition = ZPos.object
        addChild(sprite)
        setupPhysics()

        // Spin
        sprite.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 0.6)))

        // Auto-remove after lifetime
        run(.sequence([
            .wait(forDuration: EnemyProjectileConst.lifetime),
            .removeFromParent()
        ]))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 3)
        body.affectedByGravity = false
        body.linearDamping = 0
        body.categoryBitMask    = PhysicsCategory.enemyProjectile
        body.collisionBitMask   = PhysicsCategory.wall
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.wall
        physicsBody = body
    }

    func launch(velocity: CGVector) {
        physicsBody?.velocity = velocity
    }

    private static func makeTexture() -> SKTexture {
        let size = EnemyProjectileConst.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            c.setFillColor(Palette.crystal.cgColor)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 3, y: 0))
            path.addLine(to: CGPoint(x: 6, y: 3))
            path.addLine(to: CGPoint(x: 3, y: 6))
            path.addLine(to: CGPoint(x: 0, y: 3))
            path.closeSubpath()
            c.addPath(path)
            c.fillPath()
            c.setStrokeColor(UIColor(red: 1, green: 0.5, blue: 0.6, alpha: 0.9).cgColor)
            c.setLineWidth(0.5)
            c.addPath(path)
            c.strokePath()
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return tex
    }
}
