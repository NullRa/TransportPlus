import UIKit

class LaunchScreenViewController: ViewController {
    let logo = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        logo.image = UIImage(named: "AnimationIcon")
        logo.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
        logo.center = view.center
        view.backgroundColor = UIColor.white
        view.addSubview(logo)
    }

    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.logo.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
            self.logo.center = self.view.center
        }

        performSegue(withIdentifier: "openingSegue", sender: nil)
    }
}
