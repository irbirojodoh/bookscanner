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
import CoreImage
import Combine

// A custom scanner with manual capture functionality using AVCaptureSession
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding public var bleManager: BLEManager
    @Binding var scannedImages: [UIImage]
    @Binding var couldScan: Bool
    @State private var capturedImages: [UIImage] = [] // To store captured images
    @Binding var pdfURL: URL? // To store the generated PDF URL
    var showDoneButton: Bool = true // Controls the visibility of the Done button
    let completion: () -> Void
    
    func makeUIViewController(context: Context) -> CustomCameraViewController {
        print("📷 Creating CustomCameraViewController")
        let viewController = CustomCameraViewController()
        viewController.coordinator = context.coordinator // Assign coordinator
        return viewController
    }
    func makeCoordinator() -> Coordinator {
        return Coordinator(bleManager: $bleManager)
    }

    func updateUIViewController(_ uiViewController: CustomCameraViewController, context: Context) {
        // Implement updates if needed
    }
    class Coordinator: NSObject {
        @Binding var bleManager: BLEManager

        init(bleManager: Binding<BLEManager>) {
            _bleManager = bleManager
        }
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
        var coordinator: Coordinator? // Reference to the coordinator
        private var cancellable: AnyCancellable? // Store the subscription

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
            previewLayer.videoGravity = .resizeAspect // Use .resizeAspect to maintain the aspect ratio
            previewLayer.frame = view.bounds // Make the preview fill the view bounds
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
            
            // Observe changes to `receivedValue` in BLEManager
            observeReceivedValue()
        }
        
        private func observeReceivedValue() {
            // Check if coordinator and bleManager are available
            guard let bleManager = coordinator?.bleManager else { return }
            
            // Subscribe to the receivedValue publisher
            cancellable = bleManager.$receivedValue
                .sink { [weak self] newValue in
                    // This block will execute when receivedValue changes
                    self?.handleReceivedValueChange(newValue)
                }
        }
        
        func handleReceivedValueChange(_ newValue: String) {
            guard !newValue.isEmpty else {
                print("⚠️ Received value is empty, skipping action.")
                return
            }
            
            print("📲 Received value changed: \(newValue)")
            
            // Trigger photo capture if the value matches a condition
            if newValue == "capture" {
                capturePhoto()
            }
        }
    

        @objc func capturePhoto() {
            print("📷 Capture button pressed")
            coordinator?.bleManager.writeValue("3")
            let photoSettings = AVCapturePhotoSettings()
            captureOutput.capturePhoto(with: photoSettings, delegate: self)
        }
        
        
        func cropImageToDetectedDocument(_ image: UIImage, completion: @escaping (UIImage?) -> Void) {
            guard let cgImage = image.cgImage else {
                print("❌ Failed to get CGImage from UIImage")
                completion(nil)
                return
            }

            // Create a document segmentation request
            let request = VNDetectDocumentSegmentationRequest { request, error in
                if let error = error {
                    print("❌ Error detecting document: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                // Retrieve the first detected document observation
                guard let observations = request.results as? [VNRectangleObservation],
                      let document = observations.first else {
                    print("⚠️ No document detected")
                    completion(nil)
                    return
                }

                // Convert Vision coordinates to CoreGraphics coordinates
                let imageWidth = CGFloat(cgImage.width)
                let imageHeight = CGFloat(cgImage.height)

                let boundingBox = document.boundingBox
                let croppingRect = CGRect(
                    x: boundingBox.origin.x * imageWidth,
                    y: (1 - boundingBox.origin.y - boundingBox.height) * imageHeight,
                    width: boundingBox.width * imageWidth,
                    height: boundingBox.height * imageHeight
                )

                // Crop the image based on the detected document rect
                if let croppedCgImage = cgImage.cropping(to: croppingRect) {
                    let croppedImage = UIImage(cgImage: croppedCgImage)
                    completion(croppedImage)
                } else {
                    print("❌ Failed to crop CGImage")
                    completion(nil)
                }
            }

            // Run the request in the background
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try requestHandler.perform([request])
                } catch {
                    print("❌ Error performing VNDetectDocumentSegmentationRequest: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
        
        func processImageForLegibility(_ image: UIImage) -> UIImage? {
            // Convert UIImage to CIImage for processing
            guard let ciImage = CIImage(image: image) else {
                print("❌ Failed to convert UIImage to CIImage")
                return nil
            }
            
            // Step 1: Apply brightness and contrast adjustment
            let whitenFilter = CIFilter(name: "CIColorControls")
            whitenFilter?.setValue(ciImage, forKey: kCIInputImageKey)
            
            // Adjust contrast and brightness:
            whitenFilter?.setValue(1.5, forKey: kCIInputContrastKey)  // Increase contrast to make text more legible
            whitenFilter?.setValue(0.3, forKey: kCIInputBrightnessKey) // Lighten the image to make paper appear whiter
            
            guard let whitenedImage = whitenFilter?.outputImage else {
                print("❌ Failed to apply whiten filter")
                return nil
            }

            // Step 2: Convert back to UIImage
            let context = CIContext()
            if let cgImage = context.createCGImage(whitenedImage, from: whitenedImage.extent) {
                let processedImage = UIImage(cgImage: cgImage)
                return processedImage
            }
            
            return nil
        }
        
        
        
        @objc func processAndSavePDF() {
            print("📄 Generating PDF")
            
            // Get the URL for the PDF file
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let pdfURL = documentsDirectory.appendingPathComponent("scanned_document_\(timestamp).pdf")

            // Start the PDF context
            UIGraphicsBeginPDFContextToFile(pdfURL.path, .zero, nil)

            for image in capturedImages {
                // Get the image size
                let imageSize = image.size
                // Set the page size to match the image size
                UIGraphicsBeginPDFPageWithInfo(CGRect(origin: .zero, size: imageSize), nil)
                // Draw the image onto the PDF page
                image.draw(in: CGRect(origin: .zero, size: imageSize))
            }

            // End the PDF context
            UIGraphicsEndPDFContext()

            // Check if the PDF was successfully created and saved
            if FileManager.default.fileExists(atPath: pdfURL.path) {
                print("✅ PDF saved successfully at \(pdfURL.path)")
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

            // Deteksi dan potong dokumen
            cropImageToDetectedDocument(image) { croppedImage in
                guard let croppedImage = croppedImage else {
                    print("⚠️ No document detected, using original image")
                    DispatchQueue.main.async {
                        self.updatePreviewStack(with: image)
                    }
                    return
                }

                // Apply image processing (whiten paper and enhance text)
                if let processedImage = self.processImageForLegibility(croppedImage) {
                    // Add the processed image to the stack
                    DispatchQueue.main.async {
                        self.capturedImages.append(processedImage)
                        print("📷 Processed photo added: \(self.capturedImages.count) images in total")
                        self.updatePreviewStack(with: processedImage)
                    }
                } else {
                    print("❌ Failed to process the image for legibility")
                }
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
        
//        deinit {
//            NotificationCenter.default.removeObserver(self, name: .bleManagerReceivedValueChanged, object: nil)
//        }
        
        
    }


}
extension Notification.Name {
    static let bleManagerReceivedValueChanged = Notification.Name("bleManagerReceivedValueChanged")
}