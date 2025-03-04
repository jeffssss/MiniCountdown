import SwiftUI

struct SettingsView: View {
    // 导入导出设置
    @State private var showImportPicker = false
    @State private var showExportPicker = false
    
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
    
    // 浏览器监控设置
    @State private var urlBlacklist: [String] = BrowserMonitor.shared.urlBlacklist
    @State private var browserTimeout: String = String(BrowserMonitor.shared.timeout)
    @State private var showBrowserTimeoutError = false
    
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
            
            // 浏览器监控标签页
            BrowserMonitorSettingsView(
                urlBlacklist: $urlBlacklist,
                timeout: $browserTimeout,
                showTimeoutError: $showBrowserTimeoutError
            )
            .tabItem {
                Image(systemName: "globe")
                Text("浏览器监控")
            }
            .tag(3)
            
            // 导入导出设置标签页
            ImportExportSettingsView(
                showImportPicker: $showImportPicker,
                showExportPicker: $showExportPicker,
                errorMessage: $errorMessage,
                showErrorAlert: $showErrorAlert,
                onSettingsUpdated: updateAllSettings
            )
            .tabItem {
                Image(systemName: "gearshape.2")
                Text("配置文件")
            }
            .tag(4)
        }
        .padding(20)
        .frame(width: 500, height: 450, alignment: .top)
        .alert("错误", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // 导入设置文件处理
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                do {
                    try SettingsManager.shared.importFromFile(url: url)
                    // 更新所有状态变量
                    savePath = ScreenshotManager.shared.savePath
                    screenshotInterval = String(Int(ScreenshotManager.shared.interval))
                    apiKey = AIService.shared.apiKey
                    modelName = AIService.shared.modelName
                    inputPrompt = AIService.shared.inputPrompt
                    systemPrompt = AIService.shared.systemPrompt
                    apiChannel = AIService.shared.aiChannel
                    apiEndpoint = AIService.shared.apiEndpoint
                    temperature = AIService.shared.temperature
                    banList = AppMonitor.shared.banList
                    timeout = String(AppMonitor.shared.timeout)
                    urlBlacklist = BrowserMonitor.shared.urlBlacklist
                    browserTimeout = String(BrowserMonitor.shared.timeout)
                } catch {
                    errorMessage = "导入设置失败: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        case .failure(let error):
            errorMessage = "选择文件失败: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    // 更新所有设置状态变量
    private func updateAllSettings() {
        // 更新所有状态变量
        savePath = ScreenshotManager.shared.savePath
        screenshotInterval = String(Int(ScreenshotManager.shared.interval))
        apiKey = AIService.shared.apiKey
        modelName = AIService.shared.modelName
        inputPrompt = AIService.shared.inputPrompt
        systemPrompt = AIService.shared.systemPrompt
        apiChannel = AIService.shared.aiChannel
        apiEndpoint = AIService.shared.apiEndpoint
        temperature = AIService.shared.temperature
        banList = AppMonitor.shared.banList
        timeout = String(AppMonitor.shared.timeout)
        urlBlacklist = BrowserMonitor.shared.urlBlacklist
        browserTimeout = String(BrowserMonitor.shared.timeout)
    }
}

#Preview {
    SettingsView()
}
