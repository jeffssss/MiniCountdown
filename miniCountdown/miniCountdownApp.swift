//
//  miniCountdownApp.swift
//  miniCountdown
//
//  Created by Feng Ji on 2024/12/11.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    var isCountdownRunning = false
    var window: NSWindow!
    var recordListWindow: NSWindow?
    
    @objc func openRecordList() {
        if let existingWindow = recordListWindow {
            if existingWindow.isVisible {
                existingWindow.orderOut(nil)
            } else {
                existingWindow.makeKeyAndOrderFront(nil)
            }
            return
        }
        
        let recordListView = RecordListView()
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.contentView = NSHostingView(rootView: recordListView)
        newWindow.title = "记录明细"
        newWindow.center()
        newWindow.delegate = self
        newWindow.makeKeyAndOrderFront(nil)
        recordListWindow = newWindow
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.regular)
        
        // 在应用启动时创建主窗口
        let contentView = ContentView()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate = self  // 只在这里设置一次 delegate
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window.makeKeyAndOrderFront(nil) // 重新显示窗口
        }
        return false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil) // 只隐藏窗口，不退出应用
        return false
    }
}

@main
struct miniCountdownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
        }
        .defaultSize(width: 500, height: 600)
        .commands {
            CommandMenu("查看") {
                Button("记录明细") {
                    NSApp.sendAction(#selector(AppDelegate.openRecordList), to: nil, from: nil)
                }
                .keyboardShortcut("l", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}
