`./Notification+Extentions.swift`:
```swift
//  Notification+Extentions.swift
//  Created by Larry Moore on 12/16/24.
//
import Foundation

extension Notification.Name {
    static let newMessageReceived = Notification.Name("newMessageReceived")
}
```

`ViewControllers/HomeViewController.swift`:
```swift
import UIKit
import CoreBluetooth
import UserNotifications

class HomeViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var isConnected = false
    
    // Dynamically updated based on saved settings
    private var targetDeviceName: String {
        UserDefaults.standard.string(forKey: "deviceName") ?? "LTA Thermometer"
    }
    private var targetServiceUUID: CBUUID {
        CBUUID(string: UserDefaults.standard.string(forKey: "serviceUUID") ?? "180A")
    }
    private var targetCharacteristicUUID: CBUUID {
        CBUUID(string: UserDefaults.standard.string(forKey: "characteristicUUID") ?? "2A29")
    }
    
    private let connectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Connect", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.layer.cornerRadius = 60
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.gray.cgColor
        button.backgroundColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupUI()
        setupBLE()
        requestNotificationPermissions()
        observeSettingsUpdates()
    }
    
    private func setupUI() {
        view.addSubview(connectButton)
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            connectButton.widthAnchor.constraint(equalToConstant: 120),
            connectButton.heightAnchor.constraint(equalToConstant: 120),
        ])
    }
    
    private func setupBLE() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func observeSettingsUpdates() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsUpdate), name: Notification.Name("SettingsUpdated"), object: nil)
    }
    
    @objc private func handleSettingsUpdate() {
        if isConnected {
            disconnectFromDevice()
        }
        resetConnectButton()
        startScanning() // Restart scanning with updated settings
    }
    
    @objc private func connectButtonTapped() {
        if isConnected {
            disconnectFromDevice()
        } else {
            connectButton.setTitle("Searching…", for: .normal)
            connectButton.layer.borderColor = UIColor.blue.cgColor
            startScanning()
        }
    }
    
    private func startScanning() {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    private func stopScanning() {
        centralManager.stopScan()
    }
    
    private func disconnectFromDevice() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        resetConnectButton()
    }
    
    private func resetConnectButton() {
        connectButton.setTitle("Connect", for: .normal)
        connectButton.layer.borderColor = UIColor.gray.cgColor
        isConnected = false
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            print("Bluetooth is not powered on")
            resetConnectButton()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name?.contains(targetDeviceName) == true {
            connectedPeripheral = peripheral
            centralManager.stopScan()
            centralManager.connect(peripheral, options: nil)
            connectButton.setTitle("Pairing…", for: .normal)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectedPeripheral = peripheral
        connectButton.setTitle("Connected", for: .normal)
        connectButton.layer.borderColor = UIColor.green.cgColor
        peripheral.delegate = self
        peripheral.discoverServices([targetServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        connectButton.setTitle("Failed", for: .normal)
        connectButton.layer.borderColor = UIColor.red.cgColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            self.resetConnectButton()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral")
        resetConnectButton()
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Service discovery failed: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == targetServiceUUID {
                peripheral.discoverCharacteristics([targetCharacteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Characteristic discovery failed: \(error.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == targetCharacteristicUUID {
                readCharacteristicValue(peripheral: peripheral, characteristic: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed to read characteristic value: \(error.localizedDescription)")
            return
        }
        if let value = characteristic.value {
            let hexString = value.map { String(format: "%02x", $0) }.joined()
            print("Characteristic value: \(hexString)")
            sendNotification(title: connectedPeripheral?.name ?? "BLE Device Found",
                             message: "Service: \(targetServiceUUID.uuidString), Characteristic: \(targetCharacteristicUUID.uuidString), Value: \(hexString)")
            saveMessage(hexString)
        }
    }
    
    private func readCharacteristicValue(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        peripheral.readValue(for: characteristic)
        scheduleNextRead(peripheral: peripheral, characteristic: characteristic)
    }
    
    private func scheduleNextRead(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            self.readCharacteristicValue(peripheral: peripheral, characteristic: characteristic)
        }
    }
    
    private func sendNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    private func saveMessage(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let fullMessage = "\(timestamp)\n\(message)"
        NotificationCenter.default.post(name: Notification.Name("newMessageReceived"), object: fullMessage)
    }
}
```

`ViewControllers/MessagesViewController.swift`:
```swift
import UIKit

class MessagesViewController: UIViewController {
    private var messages: [String] = []
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupTableView()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewMessage), name: Notification.Name("newMessageReceived"), object: nil)
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    @objc private func handleNewMessage(_ notification: Notification) {
        if let message = notification.object as? String {
            messages.insert(message, at: 0) // Insert at the top
            tableView.reloadData()
        }
    }
}

extension MessagesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        cell.textLabel?.text = messages[indexPath.row]
        cell.textLabel?.numberOfLines = 0 // Allow multiline messages
        return cell
    }
}
```

`ViewControllers/SettingsViewController.swift`:
```swift
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
```

`./AppDelegate.swift`:
```swift
import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set up the main window and root view controller
        let tabBarController = TabBarController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        // Request notification permissions
        requestNotificationPermissions()

        return true
    }

    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }

        // Set the delegate to handle notification actions
        center.delegate = self
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Called when a notification is delivered while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification as an alert and play sound
        completionHandler([.alert, .sound])
    }

    // Called when a notification is tapped or acted upon
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("Notification tapped with identifier: \(response.notification.request.identifier)")
        completionHandler()
    }
}
```

`./TabBarController.swift`:
```swift
import UIKit

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Home Tab
        let homeViewController = HomeViewController()
        homeViewController.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        // Messages Tab
        let messagesViewController = MessagesViewController()
        messagesViewController.tabBarItem = UITabBarItem(
            title: "Messages",
            image: UIImage(systemName: "book"),
            selectedImage: UIImage(systemName: "book.fill")
        )

        // Settings Tab
        let settingsViewController = SettingsViewController()
        settingsViewController.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        // Add Tabs
        self.viewControllers = [homeViewController, messagesViewController, settingsViewController]
    }
}
```

