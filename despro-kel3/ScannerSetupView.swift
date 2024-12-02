import SwiftUI

struct ScannerSetupView: View {
    @State private var bleManager = BLEManager()
    @State private var valueToWrite = ""
    @StateObject var homeVM = HomeViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if bleManager.pickerDismissed, let scanner = bleManager.currentScanner {
                    TabBarView(bleManager: $bleManager)
                } else {
                    setupView
                }
            }

        }
    }
    
    // Setup View for Initial Scanner Addition
    @ViewBuilder
    private var setupView: some View {
        VStack(spacing: 20) {
            Text("Setup BLE Scanner")
                .font(.largeTitle)
                .padding()
            
            Image(systemName: "scanner")
                .font(.system(size: 150, weight: .light, design: .default))
                .foregroundStyle(.gray)

            Text("Add a scanner to start testing BLE connections.")
                .multilineTextAlignment(.center)
                .padding()

            Button(action: {
                bleManager.presentPicker()
            }) {
                Text("Add Scanner")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }


}

// Preview Provider
struct ScannerSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerSetupView()
    }
}
