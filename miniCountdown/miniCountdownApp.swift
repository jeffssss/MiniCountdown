//
//  miniCountdownApp.swift
//  miniCountdown
//
//  Created by Feng Ji on 2024/12/11.
//

import SwiftUI

@main
struct miniCountdownApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
