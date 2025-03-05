import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    
    private init() {}
    
    // 所有设置的数据结构
    struct Settings: Codable {
        // 截图设置
        var screenshotSavePath: String
        var screenshotInterval: Int
        
        // AI服务设置
        var channelApiKeys: [String: String]
        var channelModelNames: [String: String]
        var inputPrompt: String
        var systemPrompt: String
        var apiChannel: Int
        var apiEndpoint: String
        var temperature: Double
        
        // 应用监控设置
        var appBanList: [String]
        var appTimeout: Int
        
        // 浏览器监控设置
        var urlBlacklist: [String]
        var browserTimeout: Int
    }
    
    // 导出设置
    func exportSettings() -> Settings {
        // 收集所有channel的apiKey和modelName
        var channelApiKeys: [String: String] = [:]
        var channelModelNames: [String: String] = [:]
        
        for channel in APIChannel.allCases {
            let currentChannel = AIService.shared.aiChannel
            AIService.shared.aiChannel = channel
            channelApiKeys[String(describing: channel)] = AIService.shared.apiKey
            channelModelNames[String(describing: channel)] = AIService.shared.modelName
            AIService.shared.aiChannel = currentChannel
        }
        
        return Settings(
            screenshotSavePath: ScreenshotManager.shared.savePath,
            screenshotInterval: Int(ScreenshotManager.shared.interval),
            channelApiKeys: channelApiKeys,
            channelModelNames: channelModelNames,
            inputPrompt: AIService.shared.inputPrompt,
            systemPrompt: AIService.shared.systemPrompt,
            apiChannel: AIService.shared.aiChannel.rawValue,
            apiEndpoint: AIService.shared.apiEndpoint,
            temperature: AIService.shared.temperature,
            appBanList: AppMonitor.shared.banList,
            appTimeout: AppMonitor.shared.timeout,
            urlBlacklist: BrowserMonitor.shared.urlBlacklist,
            browserTimeout: BrowserMonitor.shared.timeout
        )
    }
    
    // 导入设置
    func importSettings(_ settings: Settings) {
        // 更新截图设置
        ScreenshotManager.shared.savePath = settings.screenshotSavePath
        ScreenshotManager.shared.interval = Double(settings.screenshotInterval)
        
        // 更新AI服务设置
        for channel in APIChannel.allCases {
            AIService.shared.aiChannel = channel
            if let apiKey = settings.channelApiKeys[String(describing: channel)] {
                AIService.shared.apiKey = apiKey
            }
            if let modelName = settings.channelModelNames[String(describing: channel)] {
                AIService.shared.modelName = modelName
            }
        }
        AIService.shared.aiChannel = APIChannel(rawValue: settings.apiChannel) ?? .openAI
        AIService.shared.inputPrompt = settings.inputPrompt
        AIService.shared.systemPrompt = settings.systemPrompt
        AIService.shared.apiEndpoint = settings.apiEndpoint
        AIService.shared.temperature = settings.temperature
        
        // 更新应用监控设置
        AppMonitor.shared.banList = settings.appBanList
        AppMonitor.shared.timeout = settings.appTimeout
        
        // 更新浏览器监控设置
        BrowserMonitor.shared.urlBlacklist = settings.urlBlacklist
        BrowserMonitor.shared.timeout = settings.browserTimeout
    }
    
    // 导出设置到文件
    func exportToFile(url: URL) throws {
        let settings = exportSettings()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(settings)
        try data.write(to: url)
    }
    
    // 从文件导入设置
    func importFromFile(url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let settings = try decoder.decode(Settings.self, from: data)
        importSettings(settings)
    }
}
