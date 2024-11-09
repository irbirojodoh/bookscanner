import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isCapturing: Bool
    @Binding var bleReceivedValue: String
    @State private var bleManager = BLEManager()

    private let captureSession = AVCaptureSession()
    private let output = AVCapturePhotoOutput()

    public init(capturedImage: Binding<UIImage?>, isCapturing: Binding<Bool>, bleReceivedValue: Binding<String>) {
        self._capturedImage = capturedImage
        self._isCapturing = isCapturing
        self._bleReceivedValue = bleReceivedValue
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        // Configure the capture session
        captureSession.sessionPreset = .photo
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Error: Unable to access the back camera!")
            return viewController
        }

        captureSession.addInput(input)
        captureSession.addOutput(output)

        // Set up the camera preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)

        // Start the capture session
        captureSession.startRunning()

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // If isCapturing is set to true, capture photo
        if isCapturing {
            capturePhoto()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Function to capture photo
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        
        // Ensure that output is properly set up before attempting to capture
        guard output.connection(with: .video) != nil else {
            print("Error: Unable to connect to capture output")
            return
        }
        
        output.capturePhoto(with: settings, delegate: makeCoordinator())
    }

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }
        

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                print("Error capturing photo: \(error.localizedDescription)")
                return
            }
            
            guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
                print("Error: Unable to process photo data")
                return
            }
            
            DispatchQueue.main.async {
                self.parent.capturedImage = image
                self.parent.isCapturing = false
            }
        }
    }
}

struct CameraViewWrapper: View {
    @Binding var capturedImage: UIImage?
    @Binding var isCapturing: Bool
    @Binding var bleReceivedValue: String
    @Binding  var bleManager : BLEManager

    var body: some View {
        ZStack {
            // Camera view that fills the entire screen
            CameraView(capturedImage: $capturedImage, isCapturing: $isCapturing, bleReceivedValue: $bleReceivedValue)
                .edgesIgnoringSafeArea(.all)  // Extend camera view to full screen

            // Overlay to display BLE received value
            if !bleManager.receivedValue.isEmpty {
                Text("Received: \(bleManager.receivedValue)")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 50)  // Position it at the top
            }

            // Button to capture photo
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // Handle capture photo when button is pressed
                        isCapturing = true  // Trigger camera capture
                        bleManager.writeValue("3")  // Send command to BLE when capture starts
                        
                        
                    }) {
                        Image(systemName: "camera")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    .padding(.bottom, 50)  // Position the button near the bottom of the screen
                }
            }
        }
    }
}
