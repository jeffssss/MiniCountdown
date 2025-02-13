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
    @State private var isAlwaysOnTop: Bool = true
    @State private var isDarkMode: Bool = false
    @State private var currentPlan: WorkPlanRecord? = nil
    @State private var todayCompletedMinutes: Int = 0
    
    private var totalSeconds: Int {
        (Int(hours) ?? 0) * 3600 + (Int(minutes) ?? 0) * 60 + (Int(seconds) ?? 0)
    }
    
    private var dailyTargetHours: Float {
        guard let plan = currentPlan else { return 0 }
        return plan.targetHours / Float(plan.workDays)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("倒计时设置")
                .font(.title)
                .padding(.vertical, 10)
            
            if let plan = currentPlan {
                VStack(alignment: .leading, spacing: 8) {
                    Text("今日目标: \(String(format: "%.2g", dailyTargetHours))小时")
                        .font(.headline)
                    Text("已完成: \(String(format: "%.2g", Float(todayCompletedMinutes) / 60.0))小时")
                        .font(.headline)
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
            }
            
            HStack(spacing: 15) {
                TimeInputField(value: $hours, label: "小时")
                TimeInputField(value: $minutes, label: "分钟")
                TimeInputField(value: $seconds, label: "秒")
            }
            .padding(.horizontal)
            
            Toggle("窗口置顶", isOn: $isAlwaysOnTop)
                .padding(.horizontal)
            
            Toggle("深色模式", isOn: $isDarkMode)
                .padding(.horizontal)
            
            Button(action: {
                if totalSeconds > 0 {
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
            .padding(.vertical, 5)
        }
        .frame(width: 400, height: currentPlan != nil ? 350 : 300)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            print("ContentView onAppear")
            updatePlanInfo()
            
            // 添加工作计划创建成功的通知监听
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("WorkPlanCreated"),
                object: nil,
                queue: .main
            ) { _ in
                if currentPlan == nil {
                    updatePlanInfo()
                }
            }
        }
        
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeMainNotification)) { _ in
            updatePlanInfo(false)
        }
    }

    private func updatePlanInfo(_ modifyCountdown:Bool = true) {
        print("更新计划信息")
        let manager = WorkMindManager.shared
        currentPlan = manager.getCurrentActivePlan()
        
        // 如果有工作计划，自动填入单次工作时长
        if modifyCountdown, let plan = currentPlan {
            let totalMinutes = Int(plan.workDurationMinutes)
            hours = "\(totalMinutes / 60)"
            minutes = "\(totalMinutes % 60)"
            seconds = "0"
        }
        
        // 计算今日已完成时间
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let records = manager.getRecords(from: today, to: tomorrow)
        todayCompletedMinutes = records
            .filter { $0.status == CountdownStatus.completed.rawValue }
            .reduce(0) { $0 + Int($1.duration) / 60 }
    }
    
    private func hideMainWindow() {
        if let appDelegate = AppDelegate.shared {
            appDelegate.window.orderOut(nil)  // 使用AppDelegate中的window引用
            // 确保在窗口关闭后再设置状态
            DispatchQueue.main.async {
                appDelegate.isCountdownRunning = true
            }
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
