import CoreBluetooth
import SwiftUI
import AccessorySetupKit
import Foundation

@Observable
class BLEManager: NSObject, ObservableObject {
    var isConnected = false
    var statusMessage = "Initializing..."
    var receivedValue = ""
    var scannerState = ScannerState.IDLE
    var pickerDismissed = true
    var scannerConnected = false
    var currentScanner: ASAccessory?
    private var session = ASAccessorySession()
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var stateCharacteristic: CBCharacteristic?
    let characteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    
    
    private static let scanner: ASPickerDisplayItem = {
        let descriptor = ASDiscoveryDescriptor()
        descriptor.bluetoothServiceUUID = ScannerProperties.serviceUUID
        
        return ASPickerDisplayItem(
            name: ScannerProperties.displayName,
            productImage: UIImage(named: "scanner")!, // Replace "scanner" with the actual name of your im
            descriptor: descriptor
        )
    }()
    
    //handleSessionEvent Function ===========================================================
    override init() {
        super.init()
        self.session.activate(on: DispatchQueue.main, eventHandler: handleSessionEvent(event:))
    }
    
    func presentPicker() {
        session.showPicker(for: [Self.scanner]) { error in
            if let error {
                print("Failed to show picker due to: \(error.localizedDescription)")
            }
        }
    }
    
    func removeScanner() {
        guard let currentScanner else { return }
        
        if isConnected {
            disconnect()
        }
        
        session.removeAccessory(currentScanner) { _ in
            self.scannerState = ScannerState.IDLE
            self.currentScanner = nil
            self.centralManager = nil
        }
    }
    
    func connect() {
        guard let centralManager, centralManager.state == .poweredOn, let peripheral else { return }
        centralManager.connect(peripheral)
        DispatchQueue.main.async {
            self.isConnected = true
        }
    }
    
    func disconnect() {
        guard let peripheral, let centralManager else { return }
        centralManager.cancelPeripheralConnection(peripheral)
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    
    private func saveScanner(scanner: ASAccessory){
        currentScanner = scanner
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    private func handleSessionEvent(event: ASAccessoryEvent) {
        switch event.eventType {
        case .accessoryAdded, .accessoryChanged:
            guard let scanner = event.accessory else { return }
            saveScanner(scanner: scanner)
        case .activated:
            guard let scanner = session.accessories.first else { return }
            saveScanner(scanner: scanner)
        case .accessoryRemoved:
            self.currentScanner = nil
            self.centralManager = nil
        case .pickerDidPresent:
            pickerDismissed = false
        case .pickerDidDismiss:
            pickerDismissed = true
        default:
            print("Received event type \(event.eventType)")
        }
    }
    
    
    var onDataReceived: ((Data) -> Void)? {
        didSet {
            // Setup the callback in your actual BLE implementation
        }
    }
    
    func startScanning() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [serviceUUID])
            statusMessage = "Scanning for devices..."
        }
    }
    
    func readValue() {
        guard let characteristic = stateCharacteristic else {
            statusMessage = "Characteristic not found"
            return
        }
        peripheral?.readValue(for: characteristic)
    }
    
    func writeValue(_ text: String) {
        guard let characteristic = stateCharacteristic,
              let data = text.data(using: .utf8) else {
            statusMessage = "Invalid input or characteristic not found"
            return
        }
        peripheral?.writeValue(data, for: characteristic, type: .withResponse)
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if let peripheralUUID = currentScanner?.bluetoothIdentifier {
                peripheral = central.retrievePeripherals(withIdentifiers: [peripheralUUID]).first
                peripheral?.delegate = self
            }
        default:
            peripheral=nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Connected to peripheral: \(peripheral)")
        peripheral.delegate = self
        peripheral.discoverServices([ScannerProperties.serviceUUID])
        
        //scannerConnected = true
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        print("Failed to connect to peripheral: \(peripheral), error: \(error.debugDescription)")
    }
}


extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first else {
            statusMessage = "Service not found"
            return
        }
        
        statusMessage = "Service found. Discovering characteristics..."
        peripheral.discoverCharacteristics([ScannerProperties.characteristicUUID], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristic = service.characteristics?.first else {
            statusMessage = "Characteristic not found"
            return
        }
        
        stateCharacteristic = characteristic
        statusMessage = "Ready to read/write"
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            statusMessage = "Error reading value: \(error.localizedDescription)"
            return
        }
        
        if let data = characteristic.value,
           let string = String(data: data, encoding: .utf8) {
            receivedValue = string
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            statusMessage = "Error writing value: \(error.localizedDescription)"
        } else {
            statusMessage = "Value written successfully"
        }
    }
}
