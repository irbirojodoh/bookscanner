import SwiftUI
import AVFoundation

struct HomeView: View {
    @State private var bleManager = BLEManager()
    @State private var capturedImage: UIImage?
    @State private var isCapturing = false
    @State private var isShowingAlert = false  // To trigger the alert
    @State private var bleReceivedValue = ""
    @State private var timer: Timer?
    @State private var navigateToBleTestView = false  // State for triggering navigation

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Image(systemName: "doc.plaintext")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                Text("You don't have any document!")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .padding()
                }
                
                Text("Scan or add your document by clicking the + button below and save as MEMORIES format")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        if bleManager.isConnected {
                            isCapturing = true
                            // Only send the command to BLE if connected
                            bleManager.writeValue("1")  // Send value "1" to BLE device
                        } else {
                            // Show the alert if BLE is not connected
                            isShowingAlert = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.blue)
                            .padding()
                    }
                    .sheet(isPresented: $isCapturing) {
                        CameraViewWrapper(capturedImage: $capturedImage, isCapturing: $isCapturing, bleReceivedValue: $bleReceivedValue, bleManager:$bleManager)
                    }

                    Spacer()
                }
            }
            .navigationBarTitle("MEMORIES Scanner", displayMode: .inline)
            .navigationBarItems(trailing:
                    // First Menu (Connect/Disconnect)
                                Menu {
                                    ScrollView {
                                        VStack {
                                            // First Button (Connect/Disconnect)
                                            Button(action: {
                                                bleManager.isConnected ? bleManager.disconnect() : bleManager.connect()
                                            }) {
                                                Text(bleManager.isConnected ? "Disconnect" : "Connect")
                                                    .frame(maxWidth: .infinity)
                                                    .font(.headline.weight(.semibold))
                                            }
                                            .padding()
                                            .background(bleManager.isConnected ? Color.red : Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                            
                                            // Second Button with NavigationLink to BleTestView
                                            NavigationLink(destination: BleTestView(bleManager: $bleManager)) {
                                                Button(action: {
                                                    // Action if needed when the button is tapped
                                                }) {
                                                    Text("Go to BleTestView")
                                                        .frame(maxWidth: .infinity)
                                                        .font(.headline.weight(.semibold))
                                                }
                                            }
            

                                        }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                }

                    
                    // Second Menu (Navigate to BleTestView)
            )
            .alert(isPresented: $isShowingAlert) {
                Alert(title: Text("Scanner is not connected"), message: Text("Please connect to the scanner before capturing."), dismissButton: .default(Text("OK")))
            }
            
            // NavigationLink to BleTestView
        }
        .onAppear {
            // Optionally start BLE scan timer here if needed
            startBLEScanTimer()
        }
        .onDisappear {
            // Stop the BLE scan timer when the view disappears
            stopBLEScanTimer()
        }
    }
    
    // Start the BLE scan timer
    private func startBLEScanTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
            // Simulate updating the BLE received value
            bleReceivedValue = "Updated at \(Date())"
        }
    }
    
    // Stop the timer when the view disappears
    private func stopBLEScanTimer() {
        timer?.invalidate()
        timer = nil
    }
}
