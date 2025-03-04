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
    
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
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
            }
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let selectedURL = urls.first {
                    // 开始访问安全作用域资源
                    guard selectedURL.startAccessingSecurityScopedResource() else {
                        // 通知父视图显示错误
                        errorMessage = "无法访问所选文件夹，请重新选择。"
                        showErrorAlert = true
                        return
                    }
                    
                    defer {
                        selectedURL.stopAccessingSecurityScopedResource()
                    }
                    
                    // 创建安全作用域书签
                    do {
                        let bookmarkData = try selectedURL.bookmarkData(
                            options: .withSecurityScope,
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )
                        
                        // 保存书签数据
                        UserDefaults.standard.set(bookmarkData, forKey: "screenshotFolderBookmark")
                        
                        // 更新保存路径
                        savePath = selectedURL.path
                        ScreenshotManager.shared.savePath = selectedURL.path
                    } catch {
                        errorMessage = "无法保存文件夹访问权限，请重新选择。"
                        showErrorAlert = true
                    }
                }
            case .failure(let error):
                errorMessage = "选择文件夹失败: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        .alert("错误", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}
