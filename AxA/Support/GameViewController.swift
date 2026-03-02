import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else { return }

        // No anti-aliasing — we're doing 16-bit pixel art
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true

        let scene = SpawnBeachScene(size: view.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
    }

    override func loadView() {
        view = SKView(frame: UIScreen.main.bounds)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
}
