//
//  ParkingInTaichungSwiftUIApp.swift
//  ParkingInTaichungSwiftUI
//
//  Created by @Ryan on 2022/10/24.
//

import SwiftUI
import GoogleMaps

class AppDelegate: NSObject, UIApplicationDelegate    {
     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
         GMSServices.provideAPIKey("AIzaSyAfiOkGK-CXt4SYKaIWRqX2Tqmhf8-XPBw")
         return true
     }
 }

@main
struct ParkingInTaichungSwiftUIApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(DataManager())
            
        }
    }
}
