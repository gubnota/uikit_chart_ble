import UIKit

class SettingsViewController: UIViewController {
    private let deviceNameField = UITextField()
    private let serviceUuidField = UITextField()
    private let characteristicUuidField = UITextField()
    private let saveButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupTextField(deviceNameField, placeholder: "Device Name")
        setupTextField(serviceUuidField, placeholder: "Service UUID")
        setupTextField(characteristicUuidField, placeholder: "Characteristic UUID")

        saveButton.setTitle("Save", for: .normal)
        saveButton.addTarget(self, action: #selector(saveSettings), for: .touchUpInside)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .blue
        saveButton.layer.cornerRadius = 8
        NSLayoutConstraint.activate([
            saveButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
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

        // Dismiss keyboard on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        loadSettings() // Load saved values or set defaults
    }

    private func setupTextField(_ textField: UITextField, placeholder: String) {
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 2
        textField.layer.borderColor = UIColor.black.cgColor
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.cornerRadius = 8
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: 44)])
    }

    @objc private func saveSettings() {
        let deviceName = deviceNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "LTA Thermometer"
        let serviceUuid = serviceUuidField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "180A"
        let characteristicUuid = characteristicUuidField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "2A29"

        // Save to UserDefaults
        UserDefaults.standard.set(deviceName, forKey: "deviceName")
        UserDefaults.standard.set(serviceUuid, forKey: "serviceUuid")
        UserDefaults.standard.set(characteristicUuid, forKey: "characteristicUuid")

        print("Settings saved: Device Name: \(deviceName), Service UUID: \(serviceUuid), Characteristic UUID: \(characteristicUuid)")

        // Show confirmation
        let alert = UIAlertController(title: "Success", message: "Settings have been saved!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func loadSettings() {
        // Load from UserDefaults or use defaults
        let deviceName = UserDefaults.standard.string(forKey: "deviceName") ?? "LTA Thermometer"
        let serviceUuid = UserDefaults.standard.string(forKey: "serviceUuid") ?? "180A"
        let characteristicUuid = UserDefaults.standard.string(forKey: "characteristicUuid") ?? "2A29"

        // Populate fields
        deviceNameField.text = deviceName
        serviceUuidField.text = serviceUuid
        characteristicUuidField.text = characteristicUuid
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
