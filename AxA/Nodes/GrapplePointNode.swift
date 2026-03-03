// GrapplePointNode.swift
// AxA — A wooden post with a brass ring. Wiz can hook his staff onto this
// to zip across the Broken Bridge gap in Lake Shore East.

import SpriteKit

final class GrapplePointNode: SKNode {

    // MARK: - Public

    /// Set by the scene. Player zips TO this position when grappling.
    let landingOffset: CGPoint   // offset from post centre where player lands

    // MARK: - Private

    private let sprite: SKSpriteNode
    private let detectionZone: SKNode

    // MARK: - Init

    init(landingOffset: CGPoint = CGPoint(x: 48, y: 0)) {
        self.landingOffset = landingOffset

        sprite = SKSpriteNode(texture: GrapplePointNode.makeTexture(),
                              size: CGSize(width: GrappleConst.postSize, height: GrappleConst.postSize))
        sprite.zPosition = ZPos.object

        detectionZone = SKNode()

        super.init()

        addChild(sprite)
        addChild(detectionZone)
        setupDetectionPhysics()

        // Gentle pulse to show it's interactive
        let pulseUp   = SKAction.scale(to: 1.1, duration: 0.7)
        let pulseDown = SKAction.scale(to: 0.95, duration: 0.7)
        pulseUp.timingMode  = .easeInEaseOut
        pulseDown.timingMode = .easeInEaseOut
        sprite.run(.repeatForever(.sequence([pulseUp, pulseDown])))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Physics

    private func setupDetectionPhysics() {
        let r = GrappleConst.detectionRadius
        let body = SKPhysicsBody(circleOfRadius: r)
        body.isDynamic = false
        body.affectedByGravity = false
        body.categoryBitMask    = PhysicsCategory.grappleZone
        body.collisionBitMask   = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player
        detectionZone.physicsBody = body
    }

    // MARK: - Texture

    private static func makeTexture() -> SKTexture {
        let s = GrappleConst.postSize
        let size = CGSize(width: s, height: s)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            // Post — vertical wooden plank
            c.setFillColor(Palette.grapplePost.cgColor)
            c.fill(CGRect(x: s * 0.38, y: 0, width: s * 0.24, height: s * 0.82))
            // Post shading
            c.setFillColor(UIColor(white: 0, alpha: 0.2).cgColor)
            c.fill(CGRect(x: s * 0.52, y: 0, width: s * 0.10, height: s * 0.82))

            // Ring — brass circle at top
            c.setStrokeColor(Palette.grappleRing.cgColor)
            c.setLineWidth(3)
            c.strokeEllipse(in: CGRect(x: s * 0.22, y: s * 0.60, width: s * 0.56, height: s * 0.36))

            // Ring highlight
            c.setStrokeColor(UIColor(white: 1, alpha: 0.5).cgColor)
            c.setLineWidth(1)
            c.strokeEllipse(in: CGRect(x: s * 0.28, y: s * 0.64, width: s * 0.28, height: s * 0.20))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return tex
    }
}
