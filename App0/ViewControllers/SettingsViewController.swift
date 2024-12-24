import UIKit

class SettingsViewController: UIViewController {
    private let deviceNameField = UITextField()
    private let serviceUuidField = UITextField()
    private let characteristicUuidField = UITextField()
    private let saveButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupTextField(deviceNameField, placeholder: "Device Name")
        setupTextField(serviceUuidField, placeholder: "Service UUID")
        setupTextField(characteristicUuidField, placeholder: "Characteristic UUID")

        saveButton.setTitle("Save", for: .normal)
        saveButton.addTarget(self, action: #selector(saveSettings), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [deviceNameField, serviceUuidField, characteristicUuidField, saveButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
    }

    private func setupTextField(_ textField: UITextField, placeholder: String) {
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
    }

    @objc private func saveSettings() {
        print("Settings saved!")
    }
}
