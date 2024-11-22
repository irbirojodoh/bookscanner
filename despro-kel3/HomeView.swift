import SwiftUI
import AVFoundation

struct HomeView: View {
    @State private var bleManager = BLEManager()
    @State private var scannedImages: [UIImage] = []
    @State private var isShowingScanner = false
    @State private var isShowingAlert = false
    @State private var bleReceivedValue = ""
    @State private var timer: Timer?
    @State private var navigateToBleTestView = false
    @State private var couldScan = false  // Add state for scanning permission
    @State private var scanBlockedAlert = false  // Alert for when scanning is blocked
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                if scannedImages.isEmpty {
                    Image(systemName: "doc.plaintext")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("You don't have any document!")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 16)
                } else {
                    // Display the most recently scanned image
                    Image(uiImage: scannedImages[0])
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
                
                // Status indicator for IoT scanning permission
                Text(couldScan ? "Ready to scan" : "Waiting for document positioning...")
                    .foregroundColor(couldScan ? .green : .orange)
                    .padding()
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
//                        if !bleManager.isConnected {
//                            isShowingAlert = true
//                        } else
//                        if !couldScan {
//                            scanBlockedAlert = true
//                        } else {
                            isShowingScanner = true
//                        }
                    }) {
                        Image(systemName: "document.viewfinder.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                            .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitle("MEMORIES Scanner", displayMode: .inline)
            .navigationBarItems(trailing:
                Menu {
                    ScrollView {
                        VStack {
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
                            
                            NavigationLink(destination: BleTestView(bleManager: $bleManager)) {
                                Text("Go to BleTestView")
                                    .frame(maxWidth: .infinity)
                                    .font(.headline.weight(.semibold))
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            )
            .sheet(isPresented: $isShowingScanner) {
                DocumentScannerView(scannedImages: $scannedImages, couldScan: $couldScan) {
                    // Completion handler after scanning
                    if !scannedImages.isEmpty {
                        print("Successfully scanned \(scannedImages.count) pages")
                    }
                }
            }
            .alert(isPresented: $isShowingAlert) {
                Alert(
                    title: Text("Scanner is not connected"),
                    message: Text("Please connect to the scanner before capturing."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Waiting for Document", isPresented: $scanBlockedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please wait for the IoT device to position the document correctly before scanning.")
            }
        }
        .onAppear {
            startBLEScanTimer()
            setupBLECallbacks()
        }
        .onDisappear {
            stopBLEScanTimer()
        }
    }
    
    private func startBLEScanTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
            bleReceivedValue = "Updated at \(Date())"
        }
    }
    
    private func stopBLEScanTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Add this method to handle BLE callbacks
    private func setupBLECallbacks() {
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
}
