import SwiftUI
import AVFoundation
import UIKit
import VisionKit
import PDFKit

// Modified HomeView with Save Button and PDF handling
struct HomeView: View {
    @State private var bleManager = BLEManager()
    @State private var scannedImages: [UIImage] = []
    @State private var isShowingScanner = false
    @State private var isShowingAlert = false
    @State private var bleReceivedValue = ""
    @State private var timer: Timer?
    @State private var navigateToBleTestView = false
    @State private var couldScan = false
    @State private var scanBlockedAlert = false
    @State private var pdfURL: URL?
    @State private var showPDFPreview = false
    @State private var savedPDFs: [URL] = []
    @State private var showingSaveAlert = false
    @State private var saveSuccess = false
    @State private var customFileName = ""
    @State private var showingSaveDialog = false
    
    var body: some View {
                NavigationView {
                    VStack {
                        // Show saved PDFs list
                        if !savedPDFs.isEmpty {
                            List {
                                ForEach(savedPDFs, id: \.self) { url in
                                    HStack {
                                        Image(systemName: "doc.fill")
                                            .foregroundColor(.blue)
                                        Text(url.lastPathComponent)
                                        Spacer()
                                        Button(action: {
                                            pdfURL = url
                                            showPDFPreview = true
                                        }) {
                                            Image(systemName: "eye")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .onDelete(perform: deletePDF)
                            }
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.3) // Limit list height
                        }
                        
                        Spacer()
                        
                        // Show scanned images and save button
                        if !scannedImages.isEmpty {
                            // Display the most recently scanned image
                            Image(uiImage: scannedImages[0])
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                                .padding()
                            
                            // Save Button
                            Button(action: {
                                showingSaveDialog = true
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
                            .disabled(scannedImages.isEmpty)
                        } else if savedPDFs.isEmpty {
                            // Empty state UI
                            Image(systemName: "doc.plaintext")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                            
                            Text("You don't have any document!")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.top, 16)
                        }
                        
                        // Status indicator
                        Text(couldScan ? "Ready to scan" : "Waiting for document positioning...")
                            .foregroundColor(couldScan ? .green : .orange)
                            .padding()
                        
                        Spacer()
                        
                        // Scan button
                        HStack {
                            Spacer()
                            Button(action: {
                                isShowingScanner = true
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
                DocumentScannerView(scannedImages: $scannedImages,
                                  couldScan: $couldScan,
                                  pdfURL: $pdfURL) {
                    print("📷 Scanner completion handler called")
                    print("📷 Current scanned images count: \(scannedImages.count)")
                    if !scannedImages.isEmpty {
                        print("📷 Has scanned images, loading saved PDFs")
                        loadSavedPDFs()
                    } else {
                        print("📷 No scanned images available")
                    }
                }
            }
            .sheet(isPresented: $showPDFPreview) {
                if let pdfURL = pdfURL {
                    PDFPreviewView(pdfURL: pdfURL)
                }
            }
            .alert("Save PDF", isPresented: $showingSaveDialog) {
                TextField("Enter file name", text: $customFileName)
                Button("Cancel", role: .cancel) {
                    customFileName = ""
                }
                Button("Save") {
                    savePDF()
                }
            } message: {
                Text("Please enter a name for your PDF file")
            }
            .alert(isPresented: $showingSaveAlert) {
                Alert(
                    title: Text(saveSuccess ? "Success" : "Error"),
                    message: Text(saveSuccess ? "PDF saved successfully" : "Failed to save PDF"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            loadSavedPDFs()
            startBLEScanTimer()
            setupBLECallbacks()
            
            // Add notification observer
            NotificationCenter.default.addObserver(
                forName: PDFManager.pdfSavedNotification,
                object: nil,
                queue: .main
            ) { _ in
                loadSavedPDFs()
            }
        }
    }
    
    private func savePDF() {
        print("💾 Starting PDF save process")
        print("💾 Number of images to save: \(scannedImages.count)")
        
        guard !scannedImages.isEmpty else {
            print("❌ No images to save")
            saveSuccess = false
            showingSaveAlert = true
            return
        }
        
        let fileName = customFileName.isEmpty ?
            "Scan_\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))" :
            customFileName
        
        print("💾 Saving with filename: \(fileName)")
        
        if let url = PDFManager.createPDF(from: scannedImages, fileName: fileName) {
            print("💾 Successfully created PDF at: \(url.path)")
            pdfURL = url
            saveSuccess = true
            scannedImages = [] // Clear the scanned images after successful save
        } else {
            print("❌ Failed to create PDF")
            saveSuccess = false
        }
        
        showingSaveAlert = true
        customFileName = ""
    }
    
    private func loadSavedPDFs() {
        savedPDFs = PDFManager.getSavedPDFs()
        print("Loaded PDFs: \(savedPDFs.count)")
    }
    
    private func deletePDF(at offsets: IndexSet) {
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

struct PDFPreviewView: UIViewRepresentable {
    let pdfURL: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: pdfURL) {
            uiView.document = document
        }
    }
}
