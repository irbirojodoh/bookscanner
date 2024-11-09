//
//  BleTestView.swift
//  despro-kel3
//
//  Created by Ibrahim Rijal on 09/11/24.
//

import SwiftUI

struct BleTestView: View {
    @Binding var bleManager: BLEManager
    @State private var valueToWrite = ""

    
    var body: some View {
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
