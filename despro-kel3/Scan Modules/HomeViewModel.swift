//
//  HomeViewModel.swift
//  despro-kel3
//
//  Created by Luthfi Misbachul Munir on 01/12/24.
//

import Foundation
import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var bleManager = BLEManager()
    @Published var scannedImages: [UIImage] = []
    @Published var isShowingScanner = false
    @Published var isShowingAlert = false
    @Published var bleReceivedValue = ""
    @Published var timer: Timer?
    @Published var navigateToBleTestView = false
    @Published var couldScan = false
    @Published var scanBlockedAlert = false
    @Published var pdfURL: URL?
    @Published var showPDFPreview = false
    @Published var savedPDFs: [URL] = []
    @Published var showingSaveAlert = false
    @Published var saveSuccess = false
    @Published var customFileName = ""
    @Published var showingSaveDialog = false
    
    func savePDF() {
        guard !scannedImages.isEmpty else { return }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let fileName = customFileName.isEmpty ? "scanned_document_\(timestamp)" : customFileName
        pdfURL = documentsDirectory.appendingPathComponent("\(fileName).pdf")

        // Create PDF
        UIGraphicsBeginPDFContextToFile(pdfURL?.path ?? "", .zero, nil)

        for image in scannedImages {
            let imageSize = image.size
            UIGraphicsBeginPDFPageWithInfo(CGRect(origin: .zero, size: imageSize), nil)
            image.draw(in: CGRect(origin: .zero, size: imageSize))
        }

        UIGraphicsEndPDFContext()

        // Reset scanned images after saving
        scannedImages.removeAll()
        
        // Trigger save success alert
        showingSaveAlert = true
        saveSuccess = true
        
        // Load saved PDFs
        loadSavedPDFs()
    }
    
    func loadSavedPDFs() {
        savedPDFs = PDFManager.getSavedPDFs()
    }
    
    func startBLEScanTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
            self.bleReceivedValue = "Updated at \(Date())"
        }
    }
    
    func stopBLEScanTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Add this method to handle BLE callbacks
    func setupBLECallbacks() {
        // This is a placeholder - you'll need to implement the actual BLE callback
        // handling in your BLEManager class
        bleManager.onDataReceived = { data in
            // Assuming the IoT device sends a specific signal to allow scanning
            if let value = String(data: data, encoding: .utf8) {
                // Update couldScan based on the IoT device signal
                // This is an example - adjust the condition based on your IoT device's protocol
                if value.contains("SCAN_READY") {
                    self.couldScan = true
                } else if value.contains("SCAN_COMPLETE") {
                    self.couldScan = false
                }
            }
        }
    }
    
    func deletePDF(at offsets: IndexSet) {
        for index in offsets {
            let pdfURL = savedPDFs[index]
            do {
                try FileManager.default.removeItem(at: pdfURL)
                print("Successfully deleted PDF at: \(pdfURL.path)")
            } catch {
                print("Error deleting PDF: \(error)")
            }
        }
        loadSavedPDFs()
    }
}
