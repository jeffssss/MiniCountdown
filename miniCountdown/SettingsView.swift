import SwiftUI

struct SettingsView: View {
    // 截图设置
    @State private var savePath: String = ScreenshotManager.shared.savePath
    @State private var screenshotInterval: String = String(Int(ScreenshotManager.shared.interval))
    
    // AI服务设置
    @State private var apiKey: String = AIService.shared.apiKey
    @State private var modelName: String = AIService.shared.modelName
    @State private var inputPrompt: String = AIService.shared.inputPrompt
    @State private var systemPrompt: String = AIService.shared.systemPrompt
    @State private var apiChannel: APIChannel = AIService.shared.aiChannel
    @State private var apiEndpoint: String = AIService.shared.apiEndpoint
    @State private var temperature: Double = AIService.shared.temperature
    
    // 应用监控设置
    @State private var banList: [String] = AppMonitor.shared.banList
    @State private var timeout: String = String(AppMonitor.shared.timeout)
    @State private var showTimeoutError = false
    @State private var selectedApp: AppInfo? = nil
    @State private var runningApps: [AppInfo] = []
    
    @State private var showIntervalError = false
    @State private var showFolderPicker = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 截图设置标签页
            ScreenshotSettingsView(
                savePath: $savePath,
                screenshotInterval: $screenshotInterval,
                showIntervalError: $showIntervalError,
                showFolderPicker: $showFolderPicker
            )
            .tabItem {
                Image(systemName: "camera")
                Text("截图设置")
            }
            .tag(0)
            
            // AI设置标签页
            AISettingsView(
                apiKey: $apiKey,
                modelName: $modelName,
                inputPrompt: $inputPrompt,
                systemPrompt: $systemPrompt,
                apiChannel: $apiChannel,
                apiEndpoint: $apiEndpoint,
                temperature: $temperature
            )
            .tabItem {
                Image(systemName: "brain")
                Text("AI设置")
            }
            .tag(1)
            
            // 应用监控标签页
            AppMonitorSettingsView(
                banList: $banList,
                timeout: $timeout,
                showTimeoutError: $showTimeoutError,
                selectedApp: $selectedApp,
                runningApps: $runningApps
            )
            .tabItem {
                Image(systemName: "eye")
                Text("应用监控")
            }
            .tag(2)
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
