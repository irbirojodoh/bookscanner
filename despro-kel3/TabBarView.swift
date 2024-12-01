//
//  TabBarView.swift
//  despro-kel3
//
//  Created by Ibrahim Rijal on 01/12/24.
//


//
//  TabBarView.swift
//  despro-kel3
//
//  Created by Luthfi Misbachul Munir on 01/12/24.
//

import SwiftUI

struct TabBarView: View {
    @Binding var bleManager: BLEManager
    @ObservedObject var homeVM = HomeViewModel()
    
    var body: some View {
        TabView {
            HomeView(bleManager: $bleManager)
                .environmentObject(homeVM)
                .tabItem {
                    Image(systemName: "document.viewfinder.fill")
                    Text("Scan")
                }
            
            ScanResultView()
                .environmentObject(homeVM)
                .tabItem {
                    Image(systemName: "tray.full.fill")
                    Text("Scan Result")
                }
        }
    }
}

#Preview {
    TabBarView(bleManager: .constant(BLEManager()))
}