//
//  HomeViewModel.swift
//  despro-kel3
//
//  Created by Luthfi Misbachul Munir on 01/12/24.
//

import Foundation
import Vision
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
                        
                        // Draw the image
                        image.draw(in: CGRect(origin: .zero, size: imageSize))
                        
                        // Perform OCR on the image
                        let textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
                            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                                print("❌ OCR failed for image: \(error?.localizedDescription ?? "Unknown error")")
                                return
                            }
                            
                            for observation in observations {
                                if let recognizedText = observation.topCandidates(1).first?.string {
                                    // Convert normalized bounding box to image coordinates
                                    let boundingBox = observation.boundingBox
                                    let textRect = CGRect(
                                        x: boundingBox.minX * imageSize.width,
                                        y: (1 - boundingBox.maxY) * imageSize.height, // Flip Y-axis
                                        width: boundingBox.width * imageSize.width,
                                        height: boundingBox.height * imageSize.height
                                    )
                                    
                                    // Draw the recognized text
                                    let paragraphStyle = NSMutableParagraphStyle()
                                    paragraphStyle.alignment = .left
                                    
                                    let attributes: [NSAttributedString.Key: Any] = [
                                        .font: UIFont.systemFont(ofSize: 12),
                                        .paragraphStyle: paragraphStyle,
                                        .foregroundColor: UIColor.clear // Transparent text layer
                                    ]
                                    
                                    recognizedText.draw(in: textRect, withAttributes: attributes)
                                }
                            }
                        }
                        
                        // Run the OCR request
                        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
                        do {
                            try handler.perform([textRecognitionRequest])
                        } catch {
                            print("❌ Error performing OCR: \(error.localizedDescription)")
                        }
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
