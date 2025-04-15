//
//  deekseepApp.swift
//  deekseep
//
//  Created by Goge on 2025/4/12.
//

import SwiftUI

@main
struct DeekseepApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 700, height: 600)

        WindowGroup(id: "settings") {
            SettingsView()
            .frame(width: 500, height:300)
        }
        .defaultSize(width: 500, height: 300)
    }
}
