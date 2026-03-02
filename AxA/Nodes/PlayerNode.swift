import SpriteKit

// MARK: - Direction

enum FacingDirection {
    case up, down, left, right

    /// Returns the direction closest to the given vector.
    static func from(vector: CGVector) -> FacingDirection {
        if abs(vector.dx) > abs(vector.dy) {
            return vector.dx > 0 ? .right : .left
        } else {
            return vector.dy > 0 ? .up : .down
        }
    }
}

// MARK: - PlayerNode
// Represents Wiz. Uses placeholder coloured shapes until real sprites arrive.
// Swap out `buildPlaceholderSprite()` with texture loading once assets exist.

final class PlayerNode: SKNode {

    // MARK: State

    private(set) var facing: FacingDirection = .down

    private let sprite: SKSpriteNode
    private var walkFrames: [SKTexture] = []
    private var idleFrames: [SKTexture] = []

    // MARK: Init

    override init() {
        sprite = PlayerNode.buildPlaceholderSprite()
        super.init()

        addChild(sprite)
        setupPhysics()
        zPosition = ZPos.player
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: Movement

    /// Call each frame from the scene's update loop.
    /// `delta` is time since last update. `direction` is normalised joystick vector.
    func move(direction: CGVector, delta: TimeInterval) {
        guard direction != .zero else {
            stopWalking()
            return
        }

        let dx = direction.dx * PlayerConst.walkSpeed * delta
        let dy = direction.dy * PlayerConst.walkSpeed * delta
        position = CGPoint(x: position.x + dx, y: position.y + dy)

        let newFacing = FacingDirection.from(vector: direction)
        if newFacing != facing {
            facing = newFacing
            updateSpriteOrientation()
        }

        startWalking()
    }

    // MARK: Animations

    private func startWalking() {
        guard sprite.action(forKey: "walk") == nil else { return }
        sprite.removeAction(forKey: "idle")
        // Placeholder: simple bob animation
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 1.5, duration: 0.1),
            SKAction.moveBy(x: 0, y: -1.5, duration: 0.1)
        ])
        sprite.run(.repeatForever(bob), withKey: "walk")
    }

    private func stopWalking() {
        guard sprite.action(forKey: "walk") != nil else { return }
        sprite.removeAction(forKey: "walk")
        sprite.position = .zero  // reset bob offset
    }

    private func updateSpriteOrientation() {
        // Flip sprite horizontally for left/right. Placeholder only — real sprites will
        // have directional frames.
        switch facing {
        case .right: sprite.xScale =  1
        case .left:  sprite.xScale = -1
        case .up, .down: sprite.xScale = 1
        }
    }

    // MARK: Physics

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: PlayerConst.physicsRadius)
        body.categoryBitMask    = PhysicsCategory.player
        body.collisionBitMask   = PhysicsCategory.wall | PhysicsCategory.water
        body.contactTestBitMask = PhysicsCategory.trigger | PhysicsCategory.interactable | PhysicsCategory.crystal
        body.allowsRotation = false
        body.linearDamping = 8
        physicsBody = body
    }

    // MARK: Placeholder Sprite
    // A purple axolotl-shaped blob with a tiny hat. Replace with real texture atlas later.

    private static func buildPlaceholderSprite() -> SKSpriteNode {
        let size = PlayerConst.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            // Body — purple oval
            c.setFillColor(Palette.wizBody.cgColor)
            c.fillEllipse(in: CGRect(x: 2, y: 2, width: 12, height: 10))

            // Hat — dark purple triangle on top
            c.setFillColor(Palette.wizHat.cgColor)
            let hat = CGMutablePath()
            hat.move(to: CGPoint(x: 8, y: 16))
            hat.addLine(to: CGPoint(x: 4, y: 8))
            hat.addLine(to: CGPoint(x: 12, y: 8))
            hat.closeSubpath()
            c.addPath(hat)
            c.fillPath()

            // Staff — gold line from tail (bottom right)
            c.setStrokeColor(Palette.wizStaff.cgColor)
            c.setLineWidth(1.5)
            c.move(to: CGPoint(x: 12, y: 2))
            c.addLine(to: CGPoint(x: 15, y: 6))
            c.strokePath()

            // Eyes — two white dots
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: 5, y: 6, width: 2, height: 2))
            c.fillEllipse(in: CGRect(x: 9, y: 6, width: 2, height: 2))
        }

        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest  // pixel art — no blur
        let node = SKSpriteNode(texture: tex, size: size)
        return node
    }
}
