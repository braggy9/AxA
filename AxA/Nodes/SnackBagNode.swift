// SnackBagNode.swift
// AxA — Gold snack bag with a white smiley face.
// Float-bobs until player touches it → open reveal animation → callback.

import SpriteKit

final class SnackBagNode: SKNode {

    // Set by the scene — called after open animation completes.
    var onOpened: (() -> Void)?

    private(set) var isOpened: Bool = false
    private let bagSprite: SKSpriteNode
    private let lightShaft: SKSpriteNode

    // MARK: - Init

    override init() {
        bagSprite = SKSpriteNode(texture: SnackBagNode.makeBagTexture(),
                                 size: SnackBagConst.size)
        bagSprite.zPosition = ZPos.object + 1

        // Light shaft — initially hidden, revealed during open animation
        let shaftSize = CGSize(width: 6, height: 40)
        lightShaft = SKSpriteNode(color: SKColor(white: 1, alpha: 0.45), size: shaftSize)
        lightShaft.anchorPoint = CGPoint(x: 0.5, y: 0)
        lightShaft.position = CGPoint(x: 0, y: SnackBagConst.size.height / 2)
        lightShaft.zPosition = ZPos.object
        lightShaft.alpha = 0

        super.init()

        zPosition = ZPos.object
        addChild(lightShaft)
        addChild(bagSprite)

        setupPhysics()
        startFloating()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Physics

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: SnackBagConst.size)
        body.isDynamic        = false
        body.affectedByGravity = false
        body.categoryBitMask    = PhysicsCategory.snackBag
        body.collisionBitMask   = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player
        physicsBody = body
    }

    // MARK: - Idle Animation

    private func startFloating() {
        let up   = SKAction.moveBy(x: 0, y: SnackBagConst.floatAmplitude,
                                   duration: SnackBagConst.floatDuration)
        let down = up.reversed()
        up.timingMode   = .easeInEaseOut
        down.timingMode = .easeInEaseOut
        bagSprite.run(.repeatForever(.sequence([up, down])), withKey: "float")
    }

    // MARK: - Open Sequence

    func open() {
        guard !isOpened else { return }
        isOpened = true

        // Remove physics so it can't be triggered again
        physicsBody = nil
        bagSprite.removeAction(forKey: "float")

        let dur = SnackBagConst.openAnimDuration

        // Bag wiggles then explodes open
        let wiggleLeft  = SKAction.rotate(byAngle:  0.3, duration: 0.06)
        let wiggleRight = SKAction.rotate(byAngle: -0.6, duration: 0.06)
        let wiggleBack  = SKAction.rotate(byAngle:  0.3, duration: 0.06)
        let scaleUp     = SKAction.scale(to: 1.5, duration: dur * 0.4)
        let fadeOut     = SKAction.fadeOut(withDuration: dur * 0.35)

        let shaftFadeIn  = SKAction.fadeIn(withDuration: dur * 0.25)
        let shaftFadeOut = SKAction.fadeOut(withDuration: dur * 0.5)
        let shaftScaleUp = SKAction.scaleY(to: 1.6, duration: dur * 0.55)

        let bagAnim = SKAction.sequence([
            .group([wiggleLeft, wiggleRight, wiggleBack]),
            .group([scaleUp, fadeOut])
        ])
        let shaftAnim = SKAction.sequence([
            shaftFadeIn,
            .group([shaftScaleUp, shaftFadeOut])
        ])

        bagSprite.run(bagAnim)
        lightShaft.run(shaftAnim)

        // Spawn sparkles around the bag
        spawnCelebrationSparkles()

        // Fire callback after animation
        run(.sequence([
            .wait(forDuration: dur),
            .run { [weak self] in self?.onOpened?() },
            .run { [weak self] in self?.removeFromParent() }
        ]))
    }

    // MARK: - Sparkles

    private func spawnCelebrationSparkles() {
        let colours: [SKColor] = [Palette.celebSparkle, .white, Palette.crystal]
        for i in 0..<8 {
            let angle = CGFloat(i) / 8.0 * .pi * 2
            let dist: CGFloat = 18
            let spark = SKSpriteNode(color: colours[i % colours.count],
                                     size: CGSize(width: 3, height: 3))
            spark.position = .zero
            spark.zPosition = ZPos.player + 1
            addChild(spark)

            let move = SKAction.moveBy(x: cos(angle) * dist,
                                       y: sin(angle) * dist,
                                       duration: SnackBagConst.openAnimDuration * 0.7)
            move.timingMode = .easeOut
            spark.run(.sequence([.group([move, .fadeOut(withDuration: SnackBagConst.openAnimDuration * 0.7)]),
                                 .removeFromParent()]))
        }
    }

    // MARK: - Texture

    private static func makeBagTexture() -> SKTexture {
        let size = SnackBagConst.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            let w = size.width, h = size.height

            // Bag body — gold rounded rect
            c.setFillColor(Palette.snackBagGold.cgColor)
            let bagRect = CGRect(x: 1, y: 0, width: w - 2, height: h - 3)
            let path = UIBezierPath(roundedRect: bagRect, cornerRadius: 3)
            c.addPath(path.cgPath)
            c.fillPath()

            // Bag top crinkle — darker gold stripe
            c.setFillColor(SKColor(red: 0.75, green: 0.58, blue: 0.08, alpha: 1).cgColor)
            c.fill(CGRect(x: 2, y: h - 5, width: w - 4, height: 3))

            // Smiley face — white circle
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: 3, y: 2, width: w - 6, height: w - 6))

            // Eyes — two black dots
            c.setFillColor(UIColor.black.cgColor)
            c.fillEllipse(in: CGRect(x: 5, y: 5, width: 2, height: 2))
            c.fillEllipse(in: CGRect(x: 9, y: 5, width: 2, height: 2))

            // Smile — arc
            c.setStrokeColor(UIColor.black.cgColor)
            c.setLineWidth(1.0)
            c.beginPath()
            c.addArc(center: CGPoint(x: 8, y: 6),
                     radius: 3,
                     startAngle: .pi * 0.15,
                     endAngle:   .pi * 0.85,
                     clockwise: true)
            c.strokePath()
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return tex
    }
}
