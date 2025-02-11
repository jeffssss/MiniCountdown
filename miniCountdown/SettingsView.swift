import SwiftUI

struct SettingsView: View {
    @State private var savePath: String = ScreenshotManager.shared.savePath
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "aiServiceApiKey") ?? ""
    @State private var showFolderPicker = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("截图设置")) {
                HStack {
                    Text("保存路径：")
                    Text(savePath)
                        .truncationMode(.middle)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button("选择文件夹") {
                        showFolderPicker = true
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("AI服务设置")) {
                HStack {
                    Text("API密钥：")
                    SecureField("", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: apiKey) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "aiServiceApiKey")
                        }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .frame(width: 500, height: 300)
        .alert("错误", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
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
    }
}

#Preview {
    SettingsView()
}