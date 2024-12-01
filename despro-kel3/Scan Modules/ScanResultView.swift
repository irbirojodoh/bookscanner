//
//  ScanResultView.swift
//  despro-kel3
//
//  Created by Luthfi Misbachul Munir on 01/12/24.
//

import SwiftUI
import UIKit
import PDFKit
import UniformTypeIdentifiers

struct ScanResultView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @State private var selectedPDFURL: URL?
    
    var body: some View {
        NavigationView {
            VStack {
                if homeVM.savedPDFs.isEmpty {
                    VStack {
                        Text("No Scan Results")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .padding()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(homeVM.savedPDFs, id: \.self) { url in
                            NavigationLink(destination: PDFDetailView(pdfURL: url)) {
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.blue)
                                    Text(url.lastPathComponent)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                        }
                        .onDelete(perform: homeVM.deletePDF)
                    }
                }
            }
            .navigationTitle("Scan Results")
        }
    }
}

struct PDFDetailView: View {
    let pdfURL: URL
    @State private var isShareSheetPresented = false
    
    var body: some View {
        PDFPreviewView(pdfURL: pdfURL)
            .navigationTitle(pdfURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                Button(action: {
                    isShareSheetPresented = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            )
            .sheet(isPresented: $isShareSheetPresented) {
                ActivityViewController(activityItems: [pdfURL])
            }
    }
}

// UIViewControllerRepresentable for sharing files
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PDFPreviewView: UIViewRepresentable {
    let pdfURL: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: pdfURL) {
            uiView.document = document
        }
    }
}

#Preview {
    ScanResultView()
        .environmentObject(HomeViewModel())
}
