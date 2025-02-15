import SwiftUI

struct SettingsView: View {
    @State private var savePath: String = ScreenshotManager.shared.savePath
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "aiServiceApiKey") ?? ""
    @State private var screenshotInterval: String = String(Int(ScreenshotManager.shared.interval))
    @State private var modelName: String = AIService.shared.modelName
    @State private var inputPrompt: String = AIService.shared.inputPrompt
    @State private var showIntervalError = false
    @State private var showFolderPicker = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
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
            
            Section(header: Text("AI服务设置").bold()) {
                HStack {
                    TextField("模型名称", text: $modelName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: modelName) { oldValue, newValue in
                            AIService.shared.modelName = newValue
                        }
                }
                .padding(.vertical, 4)
                
                HStack {
                    TextField("API密钥", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: apiKey) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "aiServiceApiKey")
                        }
                }
                .padding(.vertical, 4)
                
                HStack(alignment: .top) {
                    
                    TextEditor(text: $inputPrompt)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))
                        .onChange(of: inputPrompt) { oldValue, newValue in
                            AIService.shared.inputPrompt = newValue
                        }.overlay(alignment: .topLeading, content: {
                            Text("分析Prompt")
                                .frame(width: 100, alignment: .leading).offset(CGSize(width: -80,height: 0))
                        })
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .frame(width: 500, height: 450)
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
