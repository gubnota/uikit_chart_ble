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
