//
//  ScreenshotSettingsView.swift
//  WorkMind
//
//  Created by Feng Ji on 2025/3/3.
//
import SwiftUI

// 截图设置视图
struct ScreenshotSettingsView: View {
    @Binding var savePath: String
    @Binding var screenshotInterval: String
    @Binding var showIntervalError: Bool
    @Binding var showFolderPicker: Bool
    
    var body: some View {
        Form {
            Section(header: Text("截图设置").bold()) {
                HStack {
                    TextField("截图间隔（秒）", text: $screenshotInterval)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 180)
                        .onChange(of: screenshotInterval) { oldValue, newValue in
                            if let interval = Int(newValue), interval > 0 {
                                showIntervalError = false
                                ScreenshotManager.shared.interval = TimeInterval(interval)
                            } else {
                                showIntervalError = true
                            }
                        }
                    if showIntervalError {
                        Text("请输入大于0的数字")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
                
                HStack {
                    TextField("保存路径", text: $savePath)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .disabled(true)
                    
                    Spacer()
                    
                    Button("选择文件夹") {
                        showFolderPicker = true
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
