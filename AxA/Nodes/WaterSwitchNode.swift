// WaterSwitchNode.swift
// AxA — Coloured crystal switch for the Lake Shore West water puzzle.
// Three switches (red=0, green=1, blue=2) must be activated in the correct order.
// Player walks into the switch's physics zone to activate it.

import SpriteKit

final class WaterSwitchNode: SKNode {

    let colorIndex: Int           // 0 = red, 1 = green, 2 = blue
    private let sprite: SKSpriteNode
    private(set) var isActivated: Bool = false

    /// Called by LakeShoreWestScene when the player makes contact.
    var onTouched: (() -> Void)?

    init(colorIndex: Int) {
        self.colorIndex = colorIndex
        self.sprite = SKSpriteNode(
            texture: WaterSwitchNode.makeTexture(colorIndex: colorIndex, activated: false),
            size: WaterSwitchConst.size
        )
        super.init()

        addChild(sprite)
        setupPhysics()
        zPosition = ZPos.object

        // Gentle idle float
        let up   = SKAction.moveBy(x: 0, y: 3, duration: 0.9)
        up.timingMode = .easeInEaseOut
        sprite.run(.repeatForever(.sequence([up, up.reversed()])), withKey: "float")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Contact Entry Point

    /// Called by BaseGameScene when player physics body contacts this switch.
    func playerTouched() {
        onTouched?()
    }

    // MARK: - State

    func activate() {
        guard !isActivated else { return }
        isActivated = true
        sprite.texture = WaterSwitchNode.makeTexture(colorIndex: colorIndex, activated: true)

        // Pop + glow burst
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.35, duration: 0.08),
            SKAction.scale(to: 1.00, duration: 0.18)
        ])
        sprite.run(pop)
    }

    func deactivate() {
        isActivated = false
        sprite.texture = WaterSwitchNode.makeTexture(colorIndex: colorIndex, activated: false)
        sprite.setScale(1.0)
    }

    // MARK: - Physics

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: WaterSwitchConst.size)
        body.isDynamic          = false
        body.affectedByGravity  = false
        body.categoryBitMask    = PhysicsCategory.waterSwitch
        body.collisionBitMask   = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player
        physicsBody = body
    }

    // MARK: - Texture

    private static func makeTexture(colorIndex: Int, activated: Bool) -> SKTexture {
        let size = WaterSwitchConst.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            let w = size.width, h = size.height

            let baseColor: SKColor
            switch colorIndex {
            case 0:  baseColor = Palette.switchRed
            case 1:  baseColor = Palette.switchGreen
            default: baseColor = Palette.switchBlue
            }
            let fillColor = activated ? Palette.switchGlow : baseColor

            // Crystal hexagon
            c.setFillColor(fillColor.cgColor)
            let hex = CGMutablePath()
            hex.move(to:    CGPoint(x: w * 0.50, y: h * 0.92))
            hex.addLine(to: CGPoint(x: w * 0.18, y: h * 0.74))
            hex.addLine(to: CGPoint(x: w * 0.18, y: h * 0.28))
            hex.addLine(to: CGPoint(x: w * 0.50, y: h * 0.08))
            hex.addLine(to: CGPoint(x: w * 0.82, y: h * 0.28))
            hex.addLine(to: CGPoint(x: w * 0.82, y: h * 0.74))
            hex.closeSubpath()
            c.addPath(hex)
            c.fillPath()

            // Outline
            c.setStrokeColor(baseColor.cgColor)
            c.setLineWidth(activated ? 2.2 : 1.4)
            c.addPath(hex)
            c.strokePath()

            // Inner highlight facets
            c.setFillColor(UIColor(white: 1, alpha: activated ? 0.65 : 0.25).cgColor)
            c.fillEllipse(in: CGRect(x: w * 0.34, y: h * 0.44, width: w * 0.20, height: h * 0.18))

            if activated {
                // Radial glow rays
                c.setStrokeColor(UIColor(white: 1, alpha: 0.5).cgColor)
                c.setLineWidth(1.0)
                for i in 0..<6 {
                    let angle = CGFloat(i) * .pi / 3
                    let r1: CGFloat = w * 0.42
                    let r2: CGFloat = w * 0.56
                    c.move(to: CGPoint(x: w * 0.5 + cos(angle) * r1,
                                       y: h * 0.5 + sin(angle) * r1))
                    c.addLine(to: CGPoint(x: w * 0.5 + cos(angle) * r2,
                                          y: h * 0.5 + sin(angle) * r2))
                }
                c.strokePath()
            }
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return tex
    }
}
