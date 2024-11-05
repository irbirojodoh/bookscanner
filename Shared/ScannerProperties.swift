/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines dice color options.
*/


import CoreBluetooth

struct ScannerProperties {
    static var serviceUUID: CBUUID {
        return CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    }
    
    static var characteristicUUID: CBUUID {
        return CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    }

    static var displayName: String {
        return "Scanner"
    }

    static var scannerName: String {
        return ""
    }
}

