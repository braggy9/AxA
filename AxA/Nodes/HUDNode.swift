// HUDNode.swift
// AxA — In-game heads-up display: health bar + crystal counter.
// Attach to the camera so it stays screen-fixed.

import SpriteKit

final class HUDNode: SKNode {

    // MARK: Health Bar

    private let healthBarBG: SKSpriteNode
    private let healthBarFill: SKSpriteNode

    // MARK: Crystal Counter

    private let crystalIcon: SKSpriteNode
    private let crystalLabel: SKLabelNode

    // MARK: Init

    override init() {
        // --- Health bar background ---
        healthBarBG = SKSpriteNode(color: SKColor(white: 0, alpha: 0.5),
                                   size: CGSize(width: HUDConst.healthBarWidth,
                                                height: HUDConst.healthBarHeight))
        healthBarBG.anchorPoint = CGPoint(x: 0, y: 0.5)

        // --- Health bar fill (starts full) ---
        healthBarFill = SKSpriteNode(color: SKColor(red: 0.9, green: 0.2, blue: 0.3, alpha: 1),
                                     size: CGSize(width: HUDConst.healthBarWidth,
                                                  height: HUDConst.healthBarHeight - 2))
        healthBarFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        healthBarFill.position = CGPoint(x: 1, y: 0)

        // --- Crystal icon (small pink diamond drawn programmatically) ---
        crystalIcon = SKSpriteNode(texture: HUDNode.makeCrystalIconTexture(),
                                   size: CGSize(width: 8, height: 8))

        // --- Crystal counter label ---
        crystalLabel = SKLabelNode(text: "0")
        crystalLabel.fontName = "AvenirNext-Bold"
        crystalLabel.fontSize = 9
        crystalLabel.fontColor = .white
        crystalLabel.verticalAlignmentMode = .center
        crystalLabel.horizontalAlignmentMode = .left

        super.init()

        // Health bar group
        let healthGroup = SKNode()
        healthGroup.position = CGPoint(x: HUDConst.healthBarX, y: HUDConst.healthBarY)
        healthGroup.addChild(healthBarBG)
        healthGroup.addChild(healthBarFill)
        addChild(healthGroup)

        // Heart icon label
        let hpLabel = SKLabelNode(text: "HP")
        hpLabel.fontName = "AvenirNext-Bold"
        hpLabel.fontSize = 7
        hpLabel.fontColor = SKColor(red: 1, green: 0.8, blue: 0.8, alpha: 1)
        hpLabel.verticalAlignmentMode = .center
        hpLabel.horizontalAlignmentMode = .right
        hpLabel.position = CGPoint(x: HUDConst.healthBarX - 3, y: HUDConst.healthBarY)
        addChild(hpLabel)

        // Crystal counter group
        let crystalGroup = SKNode()
        crystalGroup.position = CGPoint(x: HUDConst.crystalCounterX, y: HUDConst.crystalCounterY)

        crystalIcon.anchorPoint = CGPoint(x: 0, y: 0.5)
        crystalIcon.position = .zero
        crystalGroup.addChild(crystalIcon)

        crystalLabel.position = CGPoint(x: 12, y: 0)
        crystalGroup.addChild(crystalLabel)

        addChild(crystalGroup)

        zPosition = ZPos.hud
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: Public Update Methods

    func setHealth(_ current: Int, max maxHP: Int) {
        let ratio = maxHP > 0 ? CGFloat(current) / CGFloat(maxHP) : 0
        let newWidth = HUDConst.healthBarWidth * Swift.max(ratio, 0)
        healthBarFill.size = CGSize(width: newWidth, height: HUDConst.healthBarHeight - 2)

        // Colour shifts red→orange→green based on health
        switch ratio {
        case 0..<0.34:
            healthBarFill.color = SKColor(red: 0.9, green: 0.15, blue: 0.15, alpha: 1)
        case 0.34..<0.67:
            healthBarFill.color = SKColor(red: 0.95, green: 0.55, blue: 0.1, alpha: 1)
        default:
            healthBarFill.color = SKColor(red: 0.25, green: 0.85, blue: 0.35, alpha: 1)
        }
    }

    func setCrystals(_ count: Int) {
        crystalLabel.text = "\(count)"
    }

    // MARK: Texture Generation

    private static func makeCrystalIconTexture() -> SKTexture {
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            c.setFillColor(Palette.crystal.cgColor)
            let diamond = CGMutablePath()
            diamond.move(to: CGPoint(x: 4, y: 7))
            diamond.addLine(to: CGPoint(x: 1, y: 4))
            diamond.addLine(to: CGPoint(x: 4, y: 1))
            diamond.addLine(to: CGPoint(x: 7, y: 4))
            diamond.closeSubpath()
            c.addPath(diamond)
            c.fillPath()
            c.setStrokeColor(UIColor(red: 1, green: 0.6, blue: 0.7, alpha: 0.9).cgColor)
            c.setLineWidth(0.5)
            c.addPath(diamond)
            c.strokePath()
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return tex
    }
}
