//
//  DocumentScannerView.swift
//  despro-kel3
//
//  Created by Luthfi Misbachul Munir on 22/11/24.
//

import SwiftUI
import AVFoundation
import VisionKit

// First, create a DocumentScannerView wrapper for VNDocumentCameraViewController
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var bleManager: BLEManager
    @Binding var scannedImages: [UIImage]
    @Binding var couldScan: Bool
    @Binding var pdfURL: URL?
    let completion: () -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        print("📷 Creating VNDocumentCameraViewController")
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // Remove this automatic dismissal as it might interfere with scanning
        // if !couldScan {
        //     uiViewController.dismiss(animated: true, completion: nil)
        // }
    }
    
    func makeCoordinator() -> Coordinator {
        print("📷 Creating Scanner Coordinator")
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
            super.init()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            print("📷 Scan completed with \(scan.pageCount) pages")
            
            // Only handle scans initiated by the user manually
            var newScannedImages: [UIImage] = []
            
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                newScannedImages.append(image)
                print("📷 Processed page \(pageIndex + 1)")
            }
            
            DispatchQueue.main.async {
                self.parent.scannedImages = newScannedImages
                print("📷 Updated scannedImages binding with \(newScannedImages.count) images")
                
                controller.dismiss(animated: true) {
                    print("📷 Scanner dismissed")
                    self.parent.completion()
                }
            }
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("❌ Document scanner failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                controller.dismiss(animated: true) {
                    self.parent.completion()
                }
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            print("📷 Scanner cancelled by user")
            DispatchQueue.main.async {
                controller.dismiss(animated: true) {
                    self.parent.completion()
                }
            }
        }
    }
}
