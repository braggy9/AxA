import SpriteKit
import GameplayKit

// MARK: - SpawnBeachScene
// World 1 — Room 1: Spawn Beach (safe starting area, tutorial hints)
// Stage 1 scope: tile map + Wiz walking + virtual joystick + camera.

final class SpawnBeachScene: SKScene, SKPhysicsContactDelegate {

    // MARK: Nodes

    private var player: PlayerNode!
    private var joystick: VirtualJoystickNode!
    private var attackButton: AttackButtonNode!
    private var cam: SKCameraNode!

    // Ground tile map (needed for camera clamping)
    private var groundMap: SKTileMapNode!

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = Palette.water   // fallback bg colour
        physicsWorld.gravity = .zero       // top-down — no gravity
        physicsWorld.contactDelegate = self

        setupCamera()
        setupTileMap()
        setupPlayer()
        setupHUD()

        showTutorialHint()
    }

    // MARK: Setup

    private func setupCamera() {
        cam = SKCameraNode()
        camera = cam
        addChild(cam)
    }

    private func setupTileMap() {
        let result = TileMapBuilder.buildSpawnBeach()
        groundMap = result.ground
        groundMap.position = .zero
        addChild(groundMap)

        // Wall nodes share the same origin as the tile map
        for wallNode in result.walls {
            addChild(wallNode)
        }
    }

    private func setupPlayer() {
        player = PlayerNode()
        // Spawn near the centre-bottom of Spawn Beach
        let startCol = World.spawnBeachCols / 2
        let startRow = 2
        player.position = tilePosition(col: startCol, row: startRow)
        addChild(player)
    }

    private func setupHUD() {
        // Joystick — lives on camera so it stays screen-fixed
        joystick = VirtualJoystickNode()
        joystick.position = .zero   // will float to touch; start offscreen-ish
        cam.addChild(joystick)

        // Attack button — bottom right
        attackButton = AttackButtonNode()
        attackButton.onTap = { [weak self] in self?.handleAttack() }
        cam.addChild(attackButton)

        layoutHUD()
    }

    private func layoutHUD() {
        // Position HUD elements relative to camera (which is centred at 0,0)
        let halfW = size.width / 2
        let halfH = size.height / 2

        // Attack button: bottom-right corner
        attackButton.position = CGPoint(
            x:  halfW - ButtonConst.xOffsetFromRight,
            y: -halfH + ButtonConst.yOffsetFromBottom
        )
    }

    // MARK: Tutorial

    private func showTutorialHint() {
        let label = SKLabelNode(text: "Use the left side to move!")
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 10
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: size.height / 2 - 20)
        label.alpha = 0
        label.zPosition = ZPos.hud
        cam.addChild(label)

        let fade = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        label.run(fade)
    }

    // MARK: Game Loop

    override func update(_ currentTime: TimeInterval) {
        // dt capping: if the game was backgrounded, don't let a huge dt explode things
        let dt: TimeInterval = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime

        if joystick.isActive {
            player.move(direction: joystick.direction, delta: dt)
        } else {
            player.move(direction: .zero, delta: dt)
        }

        updateCamera()
    }

    private var lastUpdateTime: TimeInterval = 0

    // MARK: Camera

    private func updateCamera() {
        // Smooth follow
        let target = player.position
        let current = cam.position
        let smoothed = CGPoint(
            x: current.x + (target.x - current.x) * CameraConst.followSmoothing,
            y: current.y + (target.y - current.y) * CameraConst.followSmoothing
        )
        cam.position = clampCameraPosition(smoothed)
    }

    private func clampCameraPosition(_ pos: CGPoint) -> CGPoint {
        guard let map = groundMap else { return pos }

        let mapW = CGFloat(World.spawnBeachCols) * World.tileSize
        let mapH = CGFloat(World.spawnBeachRows) * World.tileSize
        let halfMapW = mapW / 2
        let halfMapH = mapH / 2
        let halfViewW = size.width / 2
        let halfViewH = size.height / 2

        // Map is centred at map.position (which is .zero)
        let minX = map.position.x - halfMapW + halfViewW
        let maxX = map.position.x + halfMapW - halfViewW
        let minY = map.position.y - halfMapH + halfViewH
        let maxY = map.position.y + halfMapH - halfViewH

        // If the viewport is wider/taller than the map, just centre it
        let clampedX = minX < maxX ? pos.x.clamped(to: minX...maxX) : map.position.x
        let clampedY = minY < maxY ? pos.y.clamped(to: minY...maxY) : map.position.y

        return CGPoint(x: clampedX, y: clampedY)
    }

    // MARK: Actions

    private func handleAttack() {
        // Placeholder flash — real attack animation in Stage 2
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.colorize(with: .clear, colorBlendFactor: 0, duration: 0.1)
        ])
        player.children.first?.run(flash)
    }

    // MARK: Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        // Stage 1: no enemies — nothing to handle yet
    }

    // MARK: Touch Forwarding
    // The joystick is on the camera. Touches from the left half of the screen
    // are forwarded to it. Right half goes to buttons.
    // We use camera coordinates (not scene coordinates) for the left/right split
    // so it stays correct even as the camera scrolls.

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: cam)  // screen space: (0,0) = screen centre
            if loc.x < 0 {
                // Left half of screen → joystick
                joystick.touchesBegan([touch], with: event)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        joystick.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        joystick.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        joystick.touchesCancelled(touches, with: event)
    }

    // MARK: Helpers

    private func tilePosition(col: Int, row: Int) -> CGPoint {
        guard let map = groundMap else { return .zero }
        return map.centerOfTile(atColumn: col, row: row)
    }
}

// MARK: - Comparable clamp helper
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
