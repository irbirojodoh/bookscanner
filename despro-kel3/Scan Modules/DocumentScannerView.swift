//
//  DocumentScannerView.swift
//  despro-kel3
//
//  Created by Luthfi Misbachul Munir on 22/11/24.
//

import SwiftUI
import AVFoundation
import PDFKit
import Vision
import UIKit

// A custom scanner with manual capture functionality using AVCaptureSession
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var bleManager: BLEManager
    @Binding var scannedImages: [UIImage]
    @Binding var couldScan: Bool
    @State private var capturedImages: [UIImage] = [] // To store captured images
    @Binding var pdfURL: URL? // To store the generated PDF URL
    var showDoneButton: Bool = true // Controls the visibility of the Done button
    let completion: () -> Void

    func makeUIViewController(context: Context) -> CustomCameraViewController {
        print("📷 Creating CustomCameraViewController")
        return CustomCameraViewController()
    }

    func updateUIViewController(_ uiViewController: CustomCameraViewController, context: Context) {
        // Implement updates if needed
    }
    
    class CustomCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var captureOutput: AVCapturePhotoOutput!
        var capturedImages: [UIImage] = []
        var captureButton: UIButton!
        var stackView: UIStackView! // For stacking preview images
        var imageCountBadge: UILabel! // For showing image count badge
        var doneButton: UIButton!


        override func viewDidLoad() {
            super.viewDidLoad()

            // Initialize the capture session
            captureSession = AVCaptureSession()

            guard let camera = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                print("❌ Failed to access the camera")
                return
            }

            // Add input to the session
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            // Set up photo output
            captureOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(captureOutput) {
                captureSession.addOutput(captureOutput)
            }

            // Set up preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            // Add a capture button
            captureButton = UIButton(type: .system)
            captureButton.setTitle("Capture", for: .normal)
            captureButton.backgroundColor = .systemBlue
            captureButton.setTitleColor(.white, for: .normal)
            captureButton.layer.cornerRadius = 25
            captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
            captureButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(captureButton)

            // Layout the capture button
            NSLayoutConstraint.activate([
                captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
                captureButton.widthAnchor.constraint(equalToConstant: 100),
                captureButton.heightAnchor.constraint(equalToConstant: 50)
            ])

            // Add a stack view for images
            stackView = UIStackView()
            stackView.axis = .vertical
            stackView.alignment = .center
            stackView.distribution = .equalSpacing
            stackView.spacing = -10 // Slight overlap for stacked appearance
            stackView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(stackView)

            // Layout the stack view
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            ])

            // Add a badge for the image count
            imageCountBadge = UILabel()
            imageCountBadge.backgroundColor = .systemRed
            imageCountBadge.textColor = .white
            imageCountBadge.font = UIFont.systemFont(ofSize: 14, weight: .bold)
            imageCountBadge.textAlignment = .center
            imageCountBadge.layer.cornerRadius = 15
            imageCountBadge.layer.masksToBounds = true
            imageCountBadge.isHidden = true // Initially hidden
            imageCountBadge.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageCountBadge)

            // Layout the badge
            NSLayoutConstraint.activate([
                imageCountBadge.centerXAnchor.constraint(equalTo: stackView.trailingAnchor),
                imageCountBadge.centerYAnchor.constraint(equalTo: stackView.topAnchor),
                imageCountBadge.widthAnchor.constraint(equalToConstant: 30),
                imageCountBadge.heightAnchor.constraint(equalToConstant: 30),
            ])

            // Start session in the background
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
            
            doneButton = UIButton(type: .system)
            doneButton.setTitle("Done", for: .normal)
            doneButton.backgroundColor = .systemGreen
            doneButton.setTitleColor(.white, for: .normal)
            doneButton.layer.cornerRadius = 25
            doneButton.isHidden = false
            doneButton.addTarget(self, action: #selector(processAndSavePDF), for: .touchUpInside)
            doneButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(doneButton)

            // Layout the done button
            NSLayoutConstraint.activate([
                doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                doneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
                doneButton.widthAnchor.constraint(equalToConstant: 100),
                doneButton.heightAnchor.constraint(equalToConstant: 50)
            ])
        }

        @objc func capturePhoto() {
            print("📷 Capture button pressed")
            let photoSettings = AVCapturePhotoSettings()
            captureOutput.capturePhoto(with: photoSettings, delegate: self)
        }
        
        
        @objc func processAndSavePDF() {
            print("📄 Generating PDF")
            // Create a PDF document
            let pdfDocument = PDFDocument()

            for image in capturedImages {
                let pdfPage = PDFPage(image: image)
                guard let page = pdfPage else {
                    print("Failed to unwrap")
                    return
                }
                pdfDocument.insert(page, at: pdfDocument.pageCount)

            }

            // Save the PDF to a file
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            // Get the current date and time
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())

            // Generate the file URL with the timestamp included
            let pdfURL = documentsDirectory.appendingPathComponent("scanned_document_\(timestamp).pdf")

            if pdfDocument.write(to: pdfURL) {
                print("✅ PDF saved successfully at \(pdfURL.path)")
                // Pass the URL to the parent view or perform further actions
            } else {
                print("❌ Failed to save PDF")
            }
        }
        

        
        // Handle detected document segmentation (cropping and rotation)

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                print("❌ Error capturing photo: \(error.localizedDescription)")
                return
            }

            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                print("❌ Failed to process photo data")
                return
            }

            // Append the captured image
            capturedImages.append(image)
            print("📷 Photo captured successfully: \(capturedImages.count) images in total")

            // Update the stack view and badge
            DispatchQueue.main.async {
                self.updatePreviewStack(with: image)
            }
        }

        func updatePreviewStack(with image: UIImage) {
            capturedImages.append(image) // Add the captured image to the array
            // Your logic to create the stack of images
            let imageView = UIImageView(image: image)
            let previewSize: CGFloat = 60 // Small preview size
            let stackOffset: CGFloat = CGFloat(capturedImages.count * 5) // Offset for stacking

            imageView.frame = CGRect(x: 20 + stackOffset, y: UIScreen.main.bounds.height - 100 - stackOffset, width: previewSize, height: previewSize)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 10
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.layer.borderWidth = 2

            // Add slight rotation for stacking
            let rotationAngle = CGFloat.random(in: -10...10) * .pi / 180
            imageView.transform = CGAffineTransform(rotationAngle: rotationAngle)

            if let keyWindow = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) {
                keyWindow.addSubview(imageView)
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            captureSession.stopRunning()
        }
    }

}
