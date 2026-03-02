import SpriteKit

// MARK: - AttackButtonNode
// A simple circular attack button for the right side of the screen.
// Minimum 44pt touch target per CLAUDE.md.

final class AttackButtonNode: SKNode {

    var onTap: (() -> Void)?

    private let circle: SKShapeNode
    private let label: SKLabelNode

    override init() {
        let r = ButtonConst.size / 2
        circle = SKShapeNode(circleOfRadius: r)
        circle.fillColor = SKColor(red: 0.95, green: 0.30, blue: 0.30, alpha: 0.75)
        circle.strokeColor = .white.withAlphaComponent(0.5)
        circle.lineWidth = 1.5

        label = SKLabelNode(text: "A")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 22
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        super.init()

        isUserInteractionEnabled = true
        zPosition = ButtonConst.zPosition
        addChild(circle)
        addChild(label)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

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
