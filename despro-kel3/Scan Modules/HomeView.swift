import SwiftUI
import AVFoundation
import UIKit
import VisionKit
import PDFKit

// Modified HomeView with Save Button and PDF handling
struct HomeView: View {
    @ObservedObject var homeVM: HomeViewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if !homeVM.savedPDFs.isEmpty {
                    List {
                        ForEach(homeVM.savedPDFs, id: \.self) { url in
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.blue)
                                Text(url.lastPathComponent)
                                Spacer()
                                Button(action: {
                                    homeVM.pdfURL = url
                                    homeVM.showPDFPreview = true
                                }) {
                                    Image(systemName: "eye")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .onDelete(perform: homeVM.deletePDF)
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.3) // Limit list height
                }
                
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
                
                // Status indicator
                Text(homeVM.couldScan ? "Ready to scan" : "Waiting for document positioning...")
                    .foregroundColor(homeVM.couldScan ? .green : .orange)
                    .padding()
                
                Spacer()
                
                // Scan button
                HStack {
                    Spacer()
                    Button(action: {
                        homeVM.isShowingScanner = true
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
                            homeVM.bleManager.isConnected ? homeVM.bleManager.disconnect() : homeVM.bleManager.connect()
                        }) {
                            Text(homeVM.bleManager.isConnected ? "Disconnect" : "Connect")
                                .frame(maxWidth: .infinity)
                                .font(.headline.weight(.semibold))
                        }
                        .padding()
                        .background(homeVM.bleManager.isConnected ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        NavigationLink(destination: BleTestView(bleManager: $homeVM.bleManager)) {
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
            .sheet(isPresented: $homeVM.isShowingScanner) {
                DocumentScannerView(scannedImages: $homeVM.scannedImages,
                                    couldScan: $homeVM.couldScan,
                                    pdfURL: $homeVM.pdfURL) {
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
            .sheet(isPresented: $homeVM.showPDFPreview) {
                if let pdfURL = homeVM.pdfURL {
                    PDFPreviewView(pdfURL: pdfURL)
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
