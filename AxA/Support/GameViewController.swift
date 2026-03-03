import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else { return }

        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true

        // Fixed design resolution — makes everything visually larger on iPad
        let scene = SpawnBeachScene(size: CGSize(width: 960, height: 640))
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
    }

    override func loadView() {
        view = SKView(frame: UIScreen.main.bounds)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
}
