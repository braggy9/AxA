// SoftGroundNode.swift
// AxA — A patch of soft ground Bob can dig in to uncover hidden crystals.
// Placed by room scenes. Player (Bob) entering detection zone sets nearbyDigSpot in scene.
// Dig once — marks itself as dug and fades.

import SpriteKit

final class SoftGroundNode: SKNode {

    /// Number of crystals to spawn when dug. Set by placing scene.
    var hiddenCrystals: Int = SoftGroundConst.crystalReward

    /// Called by the scene after the dig animation — scene spawns crystals here.
    var onDug: ((_ worldPosition: CGPoint) -> Void)?

    private(set) var isDug: Bool = false

    private let patchSprite: SKSpriteNode
    private let detectionZone: SKSpriteNode

    // MARK: - Init

    override init() {
        patchSprite = SKSpriteNode(texture: SoftGroundNode.makePatchTexture(),
                                   size: SoftGroundConst.size)
        patchSprite.zPosition = ZPos.ground + 0.5

        // Invisible detection zone slightly larger than patch
        let zoneSize = CGSize(width: SoftGroundConst.detectionRadius * 2,
                              height: SoftGroundConst.detectionRadius * 2)
        detectionZone = SKSpriteNode(color: .clear, size: zoneSize)
        detectionZone.name = "softGroundZone"

        super.init()
        zPosition = ZPos.ground + 0.5
        addChild(patchSprite)
        addChild(detectionZone)
        setupPhysics()

        // Subtle shimmer hint: small brightness pulse so player notices
        let shimmer = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.2, duration: 0.9),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.9)
        ])
        patchSprite.run(.repeatForever(shimmer), withKey: "shimmer")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Physics

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: SoftGroundConst.detectionRadius)
        body.isDynamic        = false
        body.affectedByGravity = false
        body.categoryBitMask    = PhysicsCategory.softGround
        body.collisionBitMask   = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player
        physicsBody = body
    }

    // MARK: - Dig

    func dig() {
        guard !isDug else { return }
        isDug = true
        physicsBody = nil
        patchSprite.removeAction(forKey: "shimmer")

        // Scrape animation: shake down then fade
        let digAnim = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: -2, duration: SoftGroundConst.digDuration * 0.4),
                SKAction.colorize(with: Palette.saltGround, colorBlendFactor: 0.8,
                                  duration: SoftGroundConst.digDuration * 0.4)
            ]),
            SKAction.fadeOut(withDuration: SoftGroundConst.digDuration * 0.5),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.onDug?(self.position)
                self.removeFromParent()
            }
        ])
        patchSprite.run(digAnim)
    }

    // MARK: - Texture

    private static func makePatchTexture() -> SKTexture {
        let size = SoftGroundConst.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            let w = size.width, h = size.height

            // Dark soil oval
            c.setFillColor(Palette.softDirt.cgColor)
            c.fillEllipse(in: CGRect(x: 1, y: 1, width: w - 2, height: h - 2))

            // Slightly lighter centre highlight
            c.setFillColor(SKColor(red: 0.50, green: 0.38, blue: 0.25, alpha: 0.6).cgColor)
            c.fillEllipse(in: CGRect(x: 3, y: 2, width: w - 6, height: h - 4))

            // Three small cross-hatch lines hinting at dug earth
            c.setStrokeColor(SKColor(red: 0.25, green: 0.18, blue: 0.10, alpha: 0.7).cgColor)
            c.setLineWidth(0.8)
            for i in 0..<3 {
                let xStart = 3.0 + CGFloat(i) * 3.5
                c.move(to: CGPoint(x: xStart, y: 2))
                c.addLine(to: CGPoint(x: xStart + 1.5, y: h - 2))
            }
            c.strokePath()
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return tex
    }
}
