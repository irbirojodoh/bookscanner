//
//  PDFManager.swift
//  despro-kel3
//
//  Created by Luthfi Misbachul Munir on 22/11/24.
//

import SwiftUI
import AVFoundation
import VisionKit
import PDFKit

class PDFManager {
    // Add notification name for PDF save events
    static let pdfSavedNotification = Notification.Name("PDFSavedNotification")
    
    static func createPDF(from images: [UIImage], fileName: String) -> URL? {
        print("Starting PDF creation process for \(fileName)")
        
        // Input validation
        guard !images.isEmpty else {
            print("Error: No images provided for PDF creation")
            return nil
        }
        
        // Create PDF document
        let pdfDocument = PDFDocument()
        
        // Add each image as a page
        for (index, image) in images.enumerated() {
            guard let pdfPage = PDFPage(image: image) else {
                print("Failed to create PDF page for image at index \(index)")
                continue
            }
            pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
        }
        
        // Validate that pages were added
        guard pdfDocument.pageCount > 0 else {
            print("Error: No pages were added to the PDF")
            return nil
        }
        
        // Get documents directory path
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to get documents directory")
            return nil
        }
        
        // Create full file path with sanitized filename
        let sanitizedFileName = fileName.replacingOccurrences(of: "[^a-zA-Z0-9-_.]",
                                                            with: "_",
                                                            options: .regularExpression)
        let pdfPath = documentsPath.appendingPathComponent("\(sanitizedFileName).pdf")
        
        print("Attempting to save PDF at path: \(pdfPath.path)")
        
        // Save PDF to file
        if pdfDocument.write(to: pdfPath) {
            print("Successfully saved PDF at: \(pdfPath.path)")
            
            // Post notification that a new PDF was saved
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: pdfSavedNotification,
                                             object: nil,
                                             userInfo: ["url": pdfPath])
            }
            
            return pdfPath
        } else {
            print("Failed to write PDF to path")
            return nil
        }
    }
    
    static func getSavedPDFs() -> [URL] {
        let documentsPath = getDocumentsDirectory()
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            let pdfs = files.filter { $0.pathExtension.lowercased() == "pdf" }
            return pdfs.sorted { $0.lastPathComponent < $1.lastPathComponent }
        } catch {
            print("Error getting PDFs: \(error)")
            return []
        }
    }
    
    static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
