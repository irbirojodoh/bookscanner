//
//  HomeViewModel.swift
//  despro-kel3
//
//  Created by Ibrahim Rijal on 01/12/24.
//


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
        print("💾 Starting PDF save process")
        print("💾 Number of images to save: \(scannedImages.count)")
        
        guard !scannedImages.isEmpty else {
            print("❌ No images to save")
            saveSuccess = false
            showingSaveAlert = true
            return
        }
        
        let fileName = customFileName.isEmpty ?
            "Scan_\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))" :
            customFileName
        
        print("💾 Saving with filename: \(fileName)")
        
        if let url = PDFManager.createPDF(from: scannedImages, fileName: fileName) {
            print("💾 Successfully created PDF at: \(url.path)")
            pdfURL = url
            saveSuccess = true
            scannedImages = [] // Clear the scanned images after successful save
        } else {
            print("❌ Failed to create PDF")
            saveSuccess = false
        }
        
        showingSaveAlert = true
        customFileName = ""
    }
    
    func loadSavedPDFs() {
        savedPDFs = PDFManager.getSavedPDFs()
        print("Loaded PDFs: \(savedPDFs.count)")
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