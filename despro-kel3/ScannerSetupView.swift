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

    // BLE Test View with Connection, Disconnection, and Read/Write Functionality
    @ViewBuilder
    private var bleTestView: some View {
        VStack(spacing: 20) {
            // Status Message Display
            Text(bleManager.statusMessage)
                .padding()
                .multilineTextAlignment(.center)
                .foregroundColor(bleManager.isConnected ? .green : .red)

            // Display Received Value if available
            if !bleManager.receivedValue.isEmpty {
                Text("Received: \(bleManager.receivedValue)")
                    .padding()
            }
            
            // Button to Scan for Devices
            Button {
                bleManager.isConnected ? bleManager.disconnect() : bleManager.connect()
            } label: {
                Text(bleManager.isConnected ? "Disconnect" : "Connect")
                    .frame(maxWidth: .infinity)
                    .font(Font.headline.weight(.semibold))
            }
            .padding()
            .background(bleManager.isConnected ? Color.red : Color.blue) // Change color based on connection status
            .foregroundColor(.white)
            .cornerRadius(8)


  
            
            // Button to Present Picker
            Button(action: {
                bleManager.presentPicker()
            }) {
                Text("Select Scanner")
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
     
            
            // Text Field to Input Value to Write
            TextField("Value to write", text: $valueToWrite)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // Button to Write Value
            Button(action: {
                bleManager.writeValue(valueToWrite)
                valueToWrite = ""
            }) {
                Text("Write Value")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!bleManager.isConnected)
            
            // Button to Read Value
            Button(action: {
                bleManager.readValue()
            }) {
                Text("Read Value")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!bleManager.isConnected)
            
            // Button to Remove Scanner
            Button(action: {
                bleManager.removeScanner()
            }) {
                Text("Remove Scanner")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!bleManager.isConnected)
            
            
        }
    }
}

// Preview Provider
struct ScannerSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerSetupView()
    }
}
