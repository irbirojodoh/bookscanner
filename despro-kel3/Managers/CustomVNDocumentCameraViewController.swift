//
//  CustomVNDocumentCameraViewController.swift
//  despro-kel3
//
//  Created by Ibrahim Rijal on 06/12/24.
//


import UIKit
import AVFoundation
import Vision

class CustomVNDocumentCameraViewController: UIViewController {
    // MARK: - UI Components
    private lazy var previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Capture", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(captureDocument), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(cancelCapture), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Camera Capture Properties
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Document Scanning Properties
    private var scannedImages: [UIImage] = []
    
    // MARK: - Delegate
    weak var delegate: CustomVNDocumentCameraViewControllerDelegate?
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCaptureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCaptureSession()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(previewView)
        view.addSubview(captureButton)
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -20),
            
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            captureButton.widthAnchor.constraint(equalToConstant: 100),
            captureButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        guard let backCamera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            print("Unable to access back camera!")
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        
        if let captureSession = captureSession {
            captureSession.addInput(input)
            captureSession.addOutput(photoOutput!)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = previewView.bounds
            
            if let previewLayer = previewLayer {
                previewView.layer.addSublayer(previewLayer)
            }
        }
    }
    
    private func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
            DispatchQueue.main.async {
                self.previewLayer?.frame = self.previewView.bounds
            }
        }
    }
    
    private func stopCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.stopRunning()
        }
    }
    
    // MARK: - Capture Actions
    @objc private func captureDocument() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func cancelCapture() {
        delegate?.documentCameraViewControllerDidCancel(self)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Document Processing
    private func processScannedImage(_ image: UIImage) {
        // Perform document detection using Vision framework
        guard let cgImage = image.cgImage else { return }
        
        let request = VNDetectRectanglesRequest { [weak self] request, error in
            guard let results = request.results as? [VNRectangleObservation], !results.isEmpty else {
                // If no rectangles detected, use original image
                self?.scannedImages.append(image)
                self?.updateDelegate()
                return
            }
            
            // Get the first (largest) rectangle
            let observation = results.first!
            
            // Perform perspective correction
            if let correctedImage = self?.correctPerspective(image: image, observation: observation) {
                self?.scannedImages.append(correctedImage)
                self?.updateDelegate()
            }
        }
        
        // Configure request for document detection
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 3.0
        request.minimumSize = 0.5
        request.maximumObservations = 1
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
    private func correctPerspective(image: UIImage, observation: VNRectangleObservation) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // Transform points to image coordinates
        let topLeft = observation.topLeft
        let topRight = observation.topRight
        let bottomLeft = observation.bottomLeft
        let bottomRight = observation.bottomRight
        
        // Create perspective correction transform
        let transform = CGAffineTransform(translationX: 0, y: CGFloat(height))
        _ = transform.scaledBy(x: 1.0, y: -1.0)
        
        let points = [
            CGPoint(x: topLeft.x * CGFloat(width), y: topLeft.y * CGFloat(height)),
            CGPoint(x: topRight.x * CGFloat(width), y: topRight.y * CGFloat(height)),
            CGPoint(x: bottomLeft.x * CGFloat(width), y: bottomLeft.y * CGFloat(height)),
            CGPoint(x: bottomRight.x * CGFloat(width), y: bottomRight.y * CGFloat(height))
        ]
        
        // Perform perspective correction
        guard let correctedImage = UIImage.perspectiveCorrectedImage(from: cgImage, sourcePoints: points) else {
            return image
        }
        
        return correctedImage
    }
    
    private func updateDelegate() {
        DispatchQueue.main.async {
            self.delegate?.documentCameraViewController(self, didFinishWith: self.scannedImages)
            self.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CustomVNDocumentCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        processScannedImage(image)
    }
}

// MARK: - Delegate Protocol
protocol CustomVNDocumentCameraViewControllerDelegate: AnyObject {
    func documentCameraViewController(_ controller: CustomVNDocumentCameraViewController, didFinishWith images: [UIImage])
    func documentCameraViewControllerDidCancel(_ controller: CustomVNDocumentCameraViewController)
}

// MARK: - Perspective Correction Extension
extension UIImage {
    static func perspectiveCorrectedImage(from cgImage: CGImage, sourcePoints: [CGPoint]) -> UIImage? {
        guard sourcePoints.count == 4 else { return nil }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        let destPoints = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: width, y: 0),
            CGPoint(x: width, y: height),
            CGPoint(x: 0, y: height)
        ]
        
        // Create a CGContext for transformation
        guard let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        // Compute the transform matrix (requires custom implementation or external libraries)
        // For now, this is a placeholder for illustrative purposes
        let transform = CGAffineTransform.identity // Replace with actual calculation
        
        context.concatenate(transform)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Return the corrected image
        if let correctedCGImage = context.makeImage() {
            return UIImage(cgImage: correctedCGImage)
        }
        return nil
    }
}

// Usage Example
class DocumentScannerExample: UIViewController {
    func presentDocumentScanner() {
        let documentScanner = CustomVNDocumentCameraViewController()
        documentScanner.delegate = self
        present(documentScanner, animated: true)
    }
}

extension DocumentScannerExample: CustomVNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: CustomVNDocumentCameraViewController, didFinishWith images: [UIImage]) {
        // Handle scanned images
        for image in images {
            // Process or save the scanned document image
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: CustomVNDocumentCameraViewController) {
        // Handle cancellation
    }
}
