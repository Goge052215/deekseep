//
//  deekseepApp.swift
//  deekseep
//
//  Created by Goge on 2025/4/12.
//

import SwiftUI

@main
struct deekseepApp: App {
    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            ContentView()
                .frame(width: 800, height: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        
        // Settings window
        Window("Settings", id: "settings") {
            SettingsView()
                .frame(width: 600, height: 450)
        }
        .defaultPosition(.center)
        .keyboardShortcut(",", modifiers: .command)
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
