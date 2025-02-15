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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.regular)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate(_:)), name: NSApplication.willTerminateNotification, object: nil)
        
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
        print("applicationShouldTerminateAfterLastWindowClosed called")
        return false
    }

    @objc func appWillTerminate(_ notification: Notification) {
        print("App is about to terminate")
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
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        WindowGroup {
        }
        .defaultSize(width: 500, height: 600)
        .commands {
            CommandMenu("功能") {
                Button("记录明细") {
                    openWindow(id: "recordList")
                }
                .keyboardShortcut("l", modifiers: .command)
                
                Button("工作计划") {
                    openWindow(id: "workPlanList")
                }
                .keyboardShortcut("p", modifiers: .command)
                Divider()
                
                Button("创建工作计划") {
                    openWindow(id: "createWorkPlan")
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
        
        Window("工作计划列表", id: "workPlanList") {
            WorkPlanListView()
        }
        .defaultSize(width: 500, height: 600)
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        Window("记录明细", id: "recordList") {
            RecordListView()
        }
        .defaultSize(width: 500, height: 600)
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        Window("创建工作计划", id: "createWorkPlan") {
            WorkPlanView()
        }
        .defaultSize(width: 400, height: 400)
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
        }
    }
}
