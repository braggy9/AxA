// SpecialButtonNode.swift
// AxA — "B" button for Wiz's special ability (grapple hook, future: Bob flutter jump).

import SpriteKit

final class SpecialButtonNode: SKNode {

    var onTap: (() -> Void)?

    private let circle: SKShapeNode
    private let label: SKLabelNode

    // MARK: - Prompt label shown when near a grapple point

    private let promptLabel: SKLabelNode

    override init() {
        let r = SpecialButtonConst.size / 2
        circle = SKShapeNode(circleOfRadius: r)
        circle.fillColor = SKColor(red: 0.25, green: 0.50, blue: 0.95, alpha: 0.75)
        circle.strokeColor = .white.withAlphaComponent(0.5)
        circle.lineWidth = 1.5

        label = SKLabelNode(text: "B")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 22
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        promptLabel = SKLabelNode(text: "")
        promptLabel.fontName = "AvenirNext-Bold"
        promptLabel.fontSize = 8
        promptLabel.fontColor = SKColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1)
        promptLabel.verticalAlignmentMode = .center
        promptLabel.horizontalAlignmentMode = .center
        promptLabel.position = CGPoint(x: 0, y: SpecialButtonConst.size / 2 + 8)

        super.init()
        isUserInteractionEnabled = true
        zPosition = SpecialButtonConst.zPosition
        addChild(circle)
        addChild(label)
        addChild(promptLabel)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func showPrompt(_ text: String) {
        promptLabel.text = text
        promptLabel.alpha = 1
    }

    func hidePrompt() {
        promptLabel.text = ""
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scale = SKAction.scale(to: 0.88, duration: 0.06)
        circle.run(scale)
        onTap?()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let restore = SKAction.scale(to: 1.0, duration: 0.1)
        circle.run(restore)
    }
}
