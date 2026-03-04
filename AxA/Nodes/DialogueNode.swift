// DialogueNode.swift
// AxA — Screen-bottom dialogue box with typewriter effect.
// Attach to the camera node so it stays screen-fixed.
// Portrait on left, text on right. Tap to advance.

import SpriteKit

final class DialogueNode: SKNode {

    // MARK: - Nodes

    private let bg: SKSpriteNode
    private let label: SKLabelNode
    private let tapHint: SKLabelNode

    // MARK: - State

    private var fullText: String = ""
    private var displayedCount: Int = 0
    private(set) var isTyping: Bool = false

    /// Called when the player dismisses the dialogue (taps after text is full).
    var onDismiss: (() -> Void)?

    // MARK: - Init

    /// - Parameter sceneSize: The SKScene's `size` property (960 × 640 in AxA).
    init(sceneSize: CGSize) {
        let bgW = sceneSize.width - 40
        let bgH: CGFloat = 88
        bg = SKSpriteNode(
            color: SKColor(red: 0.04, green: 0.04, blue: 0.10, alpha: 0.90),
            size: CGSize(width: bgW, height: bgH)
        )
        // Position: near bottom of the camera space
        bg.position = CGPoint(x: 0, y: -sceneSize.height / 2 + bgH / 2 + 14)

        label = SKLabelNode(fontNamed: "Courier-Bold")
        label.fontSize      = 15
        label.fontColor     = .white
        label.numberOfLines = 3
        label.preferredMaxLayoutWidth = bgW - 24
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode   = .center
        label.position = CGPoint(x: -(bgW / 2 - 14), y: 4)

        tapHint = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tapHint.fontSize      = 9
        tapHint.fontColor     = SKColor(white: 1, alpha: 0.55)
        tapHint.text          = "tap ▶"
        tapHint.horizontalAlignmentMode = .right
        tapHint.verticalAlignmentMode   = .bottom
        tapHint.position = CGPoint(x: bgW / 2 - 8, y: -bgH / 2 + 4)
        tapHint.isHidden = true

        super.init()

        addChild(bg)
        bg.addChild(label)
        bg.addChild(tapHint)

        zPosition = ZPos.ui - 4
        isHidden  = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Public API

    /// Show the dialogue box and begin typewriter animation.
    func show(text: String) {
        fullText       = text
        displayedCount = 0
        label.text     = ""
        tapHint.isHidden = true
        isHidden  = false
        isTyping  = true
        scheduleNextChar()
    }

    /// Called by the scene on tap/touch. Advances or dismisses.
    func advance() {
        if isTyping {
            // Skip to full text immediately
            isTyping = false
            removeAllActions()
            label.text = fullText
            displayedCount = fullText.count
            tapHint.isHidden = false
        } else {
            // Dismiss
            isHidden = true
            onDismiss?()
        }
    }

    // MARK: - Typewriter

    private func scheduleNextChar() {
        guard isTyping else { return }

        if displayedCount >= fullText.count {
            isTyping = false
            tapHint.isHidden = false
            return
        }

        run(.sequence([
            .wait(forDuration: 0.038),
            .run { [weak self] in
                guard let self = self, self.isTyping else { return }
                self.displayedCount += 1
                let endIdx = self.fullText.index(self.fullText.startIndex,
                                                  offsetBy: self.displayedCount)
                self.label.text = String(self.fullText[..<endIdx])
                self.scheduleNextChar()
            }
        ]))
    }
}
