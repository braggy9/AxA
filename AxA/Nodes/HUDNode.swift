// HUDNode.swift
// AxA — In-game heads-up display: health bar, crystal counter, character portrait.
// Attach to the camera so it stays screen-fixed.
// Portrait tap → scene calls onPortraitTapped callback.

import SpriteKit

final class HUDNode: SKNode {

    // MARK: - Health Bar

    private let healthBarBG: SKSpriteNode
    private let healthBarFill: SKSpriteNode

    // MARK: - Crystal Counter

    private let crystalIcon: SKSpriteNode
    private let crystalLabel: SKLabelNode

    // MARK: - Character Portrait

    private let portraitFrame: SKSpriteNode
    private let portraitIcon: SKSpriteNode

    /// Bounds (in HUD/camera space) of the portrait for hit-testing in the scene.
    var portraitBounds: CGRect {
        let px = HUDConst.portraitX
        let py = HUDConst.portraitY
        let s  = HUDConst.portraitSize + 6   // include frame padding
        return CGRect(x: px - s/2, y: py - s/2, width: s, height: s)
    }

    // MARK: - Init

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

        // --- Crystal icon ---
        crystalIcon = SKSpriteNode(texture: HUDNode.makeCrystalIconTexture(),
                                   size: CGSize(width: 8, height: 8))

        // --- Crystal counter label ---
        crystalLabel = SKLabelNode(text: "0")
        crystalLabel.fontName = "AvenirNext-Bold"
        crystalLabel.fontSize = 9
        crystalLabel.fontColor = .white
        crystalLabel.verticalAlignmentMode   = .center
        crystalLabel.horizontalAlignmentMode = .left

        // --- Portrait frame (dark background square) ---
        let frameSize = CGSize(width: HUDConst.portraitSize + 4,
                               height: HUDConst.portraitSize + 4)
        portraitFrame = SKSpriteNode(color: SKColor(white: 0, alpha: 0.65), size: frameSize)
        portraitFrame.position = CGPoint(x: HUDConst.portraitX, y: HUDConst.portraitY)

        // --- Portrait icon (placeholder — same size as design, swapped per character) ---
        portraitIcon = SKSpriteNode(texture: HUDNode.makeWizPortraitTexture(),
                                    size: CGSize(width: HUDConst.portraitSize,
                                                 height: HUDConst.portraitSize))

        super.init()

        // Health bar group
        let healthGroup = SKNode()
        healthGroup.position = CGPoint(x: HUDConst.healthBarX, y: HUDConst.healthBarY)
        healthGroup.addChild(healthBarBG)
        healthGroup.addChild(healthBarFill)
        addChild(healthGroup)

        // HP label
        let hpLabel = SKLabelNode(text: "HP")
        hpLabel.fontName = "AvenirNext-Bold"
        hpLabel.fontSize = 7
        hpLabel.fontColor = SKColor(red: 1, green: 0.8, blue: 0.8, alpha: 1)
        hpLabel.verticalAlignmentMode   = .center
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

        // Portrait
        addChild(portraitFrame)
        portraitFrame.addChild(portraitIcon)

        // "TAP" hint under portrait
        let tapHint = SKLabelNode(text: "tap")
        tapHint.fontName = "AvenirNext-Bold"
        tapHint.fontSize = 5
        tapHint.fontColor = SKColor(white: 1, alpha: 0.55)
        tapHint.verticalAlignmentMode   = .top
        tapHint.horizontalAlignmentMode = .center
        tapHint.position = CGPoint(x: 0, y: -(HUDConst.portraitSize / 2 + 4))
        portraitFrame.addChild(tapHint)

        zPosition = ZPos.hud
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Public Update

    func setHealth(_ current: Int, max maxHP: Int) {
        let ratio    = maxHP > 0 ? CGFloat(current) / CGFloat(maxHP) : 0
        let newWidth = HUDConst.healthBarWidth * Swift.max(ratio, 0)
        healthBarFill.size = CGSize(width: newWidth, height: HUDConst.healthBarHeight - 2)

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

    func setCharacter(_ character: CharacterType) {
        let tex: SKTexture
        switch character {
        case .wiz: tex = HUDNode.makeWizPortraitTexture()
        case .bob: tex = HUDNode.makeBobPortraitTexture()
        }
        portraitIcon.texture = tex

        // Brief flash on portrait to confirm switch
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.9, duration: 0.07),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.15)
        ])
        portraitIcon.run(flash)
    }

    // MARK: - Texture Generation

    private static func makeCrystalIconTexture() -> SKTexture {
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            c.setFillColor(Palette.crystal.cgColor)
            let diamond = CGMutablePath()
            diamond.move(to:    CGPoint(x: 4, y: 7))
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

    private static func makeWizPortraitTexture() -> SKTexture {
        let s = HUDConst.portraitSize
        let size = CGSize(width: s, height: s)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            let w = size.width, h = size.height

            // Purple body
            c.setFillColor(Palette.wizBody.cgColor)
            c.fillEllipse(in: CGRect(x: 3, y: 2, width: w - 6, height: h - 8))

            // Hat
            c.setFillColor(Palette.wizHat.cgColor)
            let hat = CGMutablePath()
            hat.move(to:    CGPoint(x: w/2,     y: h - 1))
            hat.addLine(to: CGPoint(x: w/2 - 5, y: h * 0.55))
            hat.addLine(to: CGPoint(x: w/2 + 5, y: h * 0.55))
            hat.closeSubpath()
            c.addPath(hat)
            c.fillPath()

            // Eyes
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: 6,  y: h * 0.38, width: 3, height: 3))
            c.fillEllipse(in: CGRect(x: 11, y: h * 0.38, width: 3, height: 3))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return tex
    }

    private static func makeBobPortraitTexture() -> SKTexture {
        let s = HUDConst.portraitSize
        let size = CGSize(width: s, height: s)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            let w = size.width, h = size.height

            // Yellow body
            c.setFillColor(Palette.bobBody.cgColor)
            c.fillEllipse(in: CGRect(x: 3, y: 1, width: w - 6, height: h - 6))

            // Head
            c.fillEllipse(in: CGRect(x: 6, y: h - 10, width: 9, height: 9))

            // Comb
            c.setFillColor(Palette.bobComb.cgColor)
            c.fillEllipse(in: CGRect(x: 8, y: h - 8, width: 4, height: 5))

            // Beak
            c.setFillColor(Palette.bobBeak.cgColor)
            let beak = CGMutablePath()
            beak.move(to:    CGPoint(x: w - 5, y: h - 5))
            beak.addLine(to: CGPoint(x: w - 1, y: h - 7))
            beak.addLine(to: CGPoint(x: w - 5, y: h - 9))
            beak.closeSubpath()
            c.addPath(beak)
            c.fillPath()

            // Eye
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: 12, y: h - 8, width: 3, height: 3))
            c.setFillColor(UIColor.black.cgColor)
            c.fillEllipse(in: CGRect(x: 13, y: h - 7.5, width: 1.5, height: 1.5))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        return tex
    }
}
