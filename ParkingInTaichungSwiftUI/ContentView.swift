//
//  ContentView.swift
//  ParkingInTaichungSwiftUI
//
//  Created by @Ryan on 2022/10/24.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        MapView()
            .edgesIgnoringSafeArea(.all)
            .environmentObject(dataManager)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
