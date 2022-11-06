//
//  Pro_RollerApp.swift
//  Shared
//
//  Created by Jake Taylor on 7/29/22.
//

import SwiftUI
import GameKit
import GameKitUI


@main
struct Pro_RollerApp: App {
    @StateObject var gkManager = GKManager()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(gkManager)
        }
    }
}
