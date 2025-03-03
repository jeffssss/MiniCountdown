//
//  AppMonitorSettingsView.swift
//  WorkMind
//
//  Created by Feng Ji on 2025/3/3.
//

import SwiftUI

// 应用监控设置视图
struct AppMonitorSettingsView: View {
    @Binding var banList: [String]
    @Binding var timeout: String
    @Binding var showTimeoutError: Bool
    @Binding var selectedApp: AppInfo?
    @Binding var runningApps: [AppInfo]
    
    var body: some View {
        Form {
            Section(header: Text("应用监控设置").bold()) {
                HStack {
                    TextField("限制时间（秒）", text: $timeout)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 180)
                        .onChange(of: timeout) { oldValue, newValue in
                            if let timeoutValue = Int(newValue), timeoutValue > 0 {
                                showTimeoutError = false
                                AppMonitor.shared.timeout = timeoutValue
                            } else {
                                showTimeoutError = true
                            }
                        }
                    if showTimeoutError {
                        Text("请输入大于0的数字")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
                
                List {
                    ForEach(banList, id: \.self) { bundleId in
                        HStack {
                            Text(NSWorkspace.shared.runningApplications
                                .first { $0.bundleIdentifier == bundleId }?.localizedName ?? bundleId)
                            Spacer()
                            Button(action: {
                                AppMonitor.shared.removeFromBanList(bundleId)
                                banList = AppMonitor.shared.banList
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .frame(height: 100)
                
                Picker("添加应用", selection: $selectedApp) {
                    Text("选择应用").tag(nil as AppInfo?)
                    ForEach(runningApps) { app in
                        Text(app.name).tag(app as AppInfo?)
                    }
                }
                .onChange(of: selectedApp) { oldValue, newValue in
                    if let app = newValue {
                        AppMonitor.shared.addToBanList(app.bundleIdentifier)
                        banList = AppMonitor.shared.banList
                        selectedApp = nil
                    }
                }
                .onAppear {
                    runningApps = AppMonitor.shared.getRunningApplications()
                }
            }
        }
    }
}

