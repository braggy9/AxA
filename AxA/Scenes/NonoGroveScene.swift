// NonoGroveScene.swift
// AxA — World 1, Room 6: Nono Grove
// Sacred ring of nono trees. Gate check: player must have unlocked both Bob
// and Wiz to proceed to Monontoe's Lair.
// Trees chant "NO! NO! NO!" if gate fails, "GO! GO! GO!" if gate passes.
// Left edge → Lake Shore West | Right edge → Monontoe's Lair (gate-gated)

import SpriteKit

final class NonoGroveScene: BaseGameScene {

    private var dialogue: DialogueNode!
    private var gatePassed: Bool = false
    private var dialogueShown: Bool = false

    // MARK: - BaseGameScene Setup

    override func subclassSetup() {
        mapCols = World.nonoGroveCols
        mapRows = World.nonoGroveRows

        let result = TileMapBuilder.buildNonoGrove()
        groundMap          = result.ground
        groundMap.position = .zero
        addChild(groundMap)
        for wallNode in result.walls { addChild(wallNode) }

        playerStartPosition = groundMap.centerOfTile(atColumn: 3, row: 16)

        // Gate check — right passage only opens when Bob and Wiz are unlocked
        gatePassed = unlockedCharacters.contains(.bob) && unlockedCharacters.contains(.wiz)
        if gatePassed {
            roomTransitions = [.left: .lakeShoreWest, .right: .monontoeLair]
        } else {
            roomTransitions = [.left: .lakeShoreWest]
        }

        enemySpawns = []
    }

    // MARK: - Post-Player Setup

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupDialogue()
        // Show dialogue after a short atmospheric delay
        run(.sequence([
            .wait(forDuration: 1.0),
            .run { [weak self] in self?.showTreeDialogue() }
        ]))
    }

    // MARK: - Dialogue

    private func setupDialogue() {
        dialogue = DialogueNode(sceneSize: size)
        cam?.addChild(dialogue)

        dialogue.onDismiss = { [weak self] in
            self?.dialogueShown = true
            if self?.gatePassed == true {
                self?.showGoEffect()
            }
        }
    }

    private func showTreeDialogue() {
        guard !dialogueShown else { return }

        if gatePassed {
            dialogue.show(text: "GO! GO! GO!\nThe way is open, brave adventurers.\nMonontoe awaits...")
        } else {
            dialogue.show(text: "NO! NO! NO!\nYou are not ready. Find your companions\nfirst — then return!")
        }
    }

    /// Touch anywhere on the scene advances dialogue.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !dialogue.isHidden {
            dialogue.advance()
            return
        }
        super.touchesBegan(touches, with: event)
    }

    // MARK: - Gate Pass Effect

    private func showGoEffect() {
        // Green celebration flash
        let flash = SKSpriteNode(color: Palette.groveFloor,
                                  size: CGSize(width: size.width * 2, height: size.height * 2))
        flash.position  = .zero
        flash.zPosition = ZPos.ui - 1
        flash.alpha     = 0
        cam?.addChild(flash)
        flash.run(.sequence([
            .fadeAlpha(to: 0.35, duration: 0.10),
            .fadeOut(withDuration: 0.50),
            .removeFromParent()
        ]))
    }
}
