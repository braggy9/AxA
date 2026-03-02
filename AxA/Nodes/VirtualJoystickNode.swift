import SpriteKit

// MARK: - VirtualJoystickNode
// Floating-style joystick: appears where the thumb touches, not at a fixed position.
// Reports normalised direction (magnitude 0–1) and 8-directional snapping.

final class VirtualJoystickNode: SKNode {

    // MARK: Outputs

    /// Normalised movement vector. Zero when not active.
    private(set) var direction: CGVector = .zero

    /// True while a touch is held on the joystick.
    private(set) var isActive: Bool = false

    // MARK: Private

    private let base: SKShapeNode
    private let knob: SKShapeNode
    private var trackingTouch: UITouch?

    // MARK: Init

    override init() {
        base = SKShapeNode(circleOfRadius: JoystickConst.baseRadius)
        base.fillColor = JoystickConst.baseColour
        base.strokeColor = .white.withAlphaComponent(0.3)
        base.lineWidth = 1.5
        base.alpha = 0

        knob = SKShapeNode(circleOfRadius: JoystickConst.knobRadius)
        knob.fillColor = JoystickConst.knobColour
        knob.strokeColor = .white.withAlphaComponent(0.4)
        knob.lineWidth = 1
        knob.alpha = 0

        super.init()

        zPosition = JoystickConst.zPosition
        isUserInteractionEnabled = true
        addChild(base)
        addChild(knob)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard trackingTouch == nil, let touch = touches.first else { return }
        trackingTouch = touch
        isActive = true

        // Float the joystick to where the thumb lands
        let loc = touch.location(in: parent ?? self)
        position = loc

        base.alpha = JoystickConst.alpha
        knob.alpha = JoystickConst.alpha
        knob.position = .zero
        direction = .zero
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tracking = trackingTouch, touches.contains(tracking) else { return }
        let loc = tracking.location(in: parent ?? self)
        let delta = CGVector(dx: loc.x - position.x, dy: loc.y - position.y)
        let dist  = hypot(delta.dx, delta.dy)
        let clamp = min(dist, JoystickConst.maxDisplacement)
        let norm  = dist > 0 ? CGVector(dx: delta.dx / dist, dy: delta.dy / dist) : .zero

        knob.position = CGPoint(x: norm.dx * clamp, y: norm.dy * clamp)
        direction = CGVector(dx: norm.dx * (clamp / JoystickConst.maxDisplacement),
                             dy: norm.dy * (clamp / JoystickConst.maxDisplacement))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tracking = trackingTouch, touches.contains(tracking) else { return }
        releaseJoystick()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        releaseJoystick()
    }

    // MARK: Private

    private func releaseJoystick() {
        trackingTouch = nil
        isActive = false
        direction = .zero
        base.alpha = 0
        knob.alpha = 0
        knob.position = .zero
    }
}
