import UIKit

class HomeViewController: UIViewController {
    private let connectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Connect", for: .normal)
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 4
        button.layer.cornerRadius = 50
        button.frame.size = CGSize(width: 100, height: 100)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        connectButton.center = view.center
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        view.addSubview(connectButton)
    }

    @objc private func connectButtonTapped() {
        connectButton.setTitle("Searching…", for: .normal)
        connectButton.layer.borderColor = UIColor.blue.cgColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.connectButton.setTitle("Connected", for: .normal)
            self.connectButton.layer.borderColor = UIColor.green.cgColor
        }
    }
}
