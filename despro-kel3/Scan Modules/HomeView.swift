import SwiftUI
import AVFoundation
import VisionKit

// Modified HomeView with Save Button and PDF handling
struct HomeView: View {
    @Binding var bleManager: BLEManager
    @EnvironmentObject var homeVM: HomeViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                // Show scanned images and save button
                if !homeVM.scannedImages.isEmpty {
                    // Display the most recently scanned image
                    Image(uiImage: homeVM.scannedImages[0])
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .padding()
                    
                    // Save Button
                    Button(action: {
                        homeVM.showingSaveDialog = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save as PDF")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(homeVM.scannedImages.isEmpty)
                    
                    // Cancel Button
                    Button(action: {
                        // Handle cancel logic here
                        homeVM.scannedImages.removeAll() // Clear the scanned images
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Cancel")
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                } else if homeVM.savedPDFs.isEmpty {
                    // Empty state UI
                    Image(systemName: "doc.plaintext")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("You don't have any document!")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 16)
                }
                
                // Show the Start Scanning button only when there are no scanned images
                if homeVM.scannedImages.isEmpty && bleManager.isConnected {
                    Button(action: {
                        bleManager.writeValue("2")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            homeVM.isShowingScanner = true
                        }
                    }) {
                        VStack {
                            Image(systemName: "scanner.fill")
                                .font(.title)
                                .foregroundStyle(.blue)
                                .padding()
                            
                            Text("Start Scanning")
                        }
                    }
                } else {
                    // Show a message if no connection is established
                    if !bleManager.isConnected {
                        Text("Bluetooth has not connected to the device.")
                            .font(.headline)
                            .bold()
                        
                        Button {
                            bleManager.connect()
                        } label: {
                            Text("Connect Bluetooth")
                                .font(.footnote)
                                .foregroundStyle(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue)
                                )
                        }
                    }
                }
                
                Spacer()
            }
            .navigationBarTitle("MEMORIES Scanner", displayMode: .inline)
            .navigationBarItems(trailing: Menu {
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
            })
            .sheet(isPresented: $homeVM.isShowingScanner) {
                DocumentScannerView(bleManager: $bleManager, scannedImages: $homeVM.scannedImages,
                                    couldScan: $homeVM.couldScan,
                                    pdfURL: $homeVM.pdfURL, isShowingScanner: $homeVM.isShowingScanner) {
                    print("📷 Scanner completion handler called")
                    print("📷 Current scanned images count: \(homeVM.scannedImages.count)")
                    if !homeVM.scannedImages.isEmpty {
                        print("📷 Has scanned images, loading saved PDFs")
                        homeVM.loadSavedPDFs()
                    } else {
                        print("📷 No scanned images available")
                    }
                }
            }
            .alert("Save PDF", isPresented: $homeVM.showingSaveDialog) {
                TextField("Enter file name", text: $homeVM.customFileName)
                Button("Cancel", role: .cancel) {
                    homeVM.customFileName = ""
                }
                Button("Save") {
                    homeVM.savePDF()
                }
            } message: {
                Text("Please enter a name for your PDF file")
            }
            .alert(isPresented: $homeVM.showingSaveAlert) {
                Alert(
                    title: Text(homeVM.saveSuccess ? "Success" : "Error"),
                    message: Text(homeVM.saveSuccess ? "PDF saved successfully" : "Failed to save PDF"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            homeVM.loadSavedPDFs()
            homeVM.startBLEScanTimer()
            homeVM.setupBLECallbacks()
            
            // Add notification observer
            NotificationCenter.default.addObserver(
                forName: PDFManager.pdfSavedNotification,
                object: nil,
                queue: .main
            ) { _ in
                homeVM.loadSavedPDFs()
            }
        }
    }
}
