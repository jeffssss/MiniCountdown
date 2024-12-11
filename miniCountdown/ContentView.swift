//
//  ContentView.swift
//  miniCountdown
//
//  Created by Feng Ji on 2024/12/11.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var hours: String = "0"
    @State private var minutes: String = "0"
    @State private var seconds: String = "0"
    @State private var isAlwaysOnTop: Bool = false
    @State private var isDarkMode: Bool = false
    @State private var showingCountdown: Bool = false
    
    private var totalSeconds: Int {
        (Int(hours) ?? 0) * 3600 + (Int(minutes) ?? 0) * 60 + (Int(seconds) ?? 0)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("倒计时设置")
                .font(.title)
                .padding()
            
            HStack(spacing: 15) {
                TimeInputField(value: $hours, label: "小时")
                TimeInputField(value: $minutes, label: "分钟")
                TimeInputField(value: $seconds, label: "秒")
            }
            .padding()
            
            Toggle("窗口置顶", isOn: $isAlwaysOnTop)
                .padding(.horizontal)
            
            Toggle("深色模式", isOn: $isDarkMode)
                .padding(.horizontal)
            
            Button(action: {
                if totalSeconds > 0 {
                    showingCountdown = true
                    hideMainWindow()
                    openCountdownWindow()
                }
            }) {
                Text("开始倒计时")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
        }
        .frame(width: 400, height: 300)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    private func hideMainWindow() {
        if let window = NSApplication.shared.windows.first {
            window.close()
        }
    }
    
    private func openCountdownWindow() {
        let countdownView = CountdownView(
            totalSeconds: totalSeconds,
            isAlwaysOnTop: isAlwaysOnTop,
            isDarkMode: isDarkMode
        )
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.hasShadow = true
        window.minSize = NSSize(width: 30, height: 10)
        
        window.contentView = NSHostingView(rootView: countdownView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        if isAlwaysOnTop {
            window.level = .statusBar
        }
    }
}

struct TimeInputField: View {
    @Binding var value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(label)
            TextField("0", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 60)
                .multilineTextAlignment(.center)
                .onChange(of: value) { newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        value = filtered
                    }
                    if let intValue = Int(filtered) {
                        if intValue > 59 && label != "小时" {
                            value = "59"
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
