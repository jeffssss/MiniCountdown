import Foundation
import AppKit
import AXSwift

// 导入浏览器适配器
// import "BrowserAdapter/BrowserAdapter.swift"
// import "BrowserAdapter/SafariBrowserAdapter.swift"
// import "BrowserAdapter/ChromeBrowserAdapter.swift"

class BrowserMonitor {
    static let shared = BrowserMonitor()
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults keys
    private let urlBlacklistKey = "browserMonitorUrlBlacklist"
    private let timeoutKey = "browserMonitorTimeout"
    
    // 默认配置
    private let defaultTimeout: Int = 30
    
    private var lastActiveUrl: String? = nil
    private var lastActiveTime: Date? = nil
    
    // 浏览器适配器映射表
    private var browserAdapterList: [BrowserAdapter] = [
        SafariBrowserAdapter(),
        ChromeBrowserAdapter()
    ]

    var urlBlacklist: [String] {
        get { userDefaults.stringArray(forKey: urlBlacklistKey) ?? [] }
        set { userDefaults.set(newValue, forKey: urlBlacklistKey) }
    }
    
    var timeout: Int {
        get { userDefaults.integer(forKey: timeoutKey) > 0 ? userDefaults.integer(forKey: timeoutKey) : defaultTimeout }
        set { userDefaults.set(newValue, forKey: timeoutKey) }
    }
    
    private init() {
    }
    
    func isBrowserApp(_ appInfo: AppInfo) -> Bool {
        return (getAdapterByBundleId(appInfo.bundleIdentifier) != nil)
    }
    
    func getAdapterByBundleId(_ bundleId:String) -> BrowserAdapter? {
        for adapter in browserAdapterList {
            if type(of: adapter).bundleIdentifiers.contains(bundleId) {
                return adapter
            }
        }
        return nil
    }
    
    func checkBrowserStatus(_ appInfo:AppInfo) -> (Bool, BrowserInfo?) {
        
        guard UIElement.isProcessTrusted(withPrompt: true) else {
            NSLog("No accessibility API permission, exiting")
            return (true, nil)
        }
        
        guard let adapter = getAdapterByBundleId(appInfo.bundleIdentifier),
              let browserInfo = adapter.getBrowserInfo() else {
            return (true, nil)
        }

//        print("checkBrowserStatus \(browserInfo.url) - \(browserInfo.title)" )
        
        // 检查URL是否在黑名单中
        let isBlocked = urlBlacklist.contains { pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
            let range = NSRange(location: 0, length: browserInfo.url.utf16.count)
            return regex.firstMatch(in: browserInfo.url, range: range) != nil
        }
        
        if isBlocked {
            // 如果是新的URL
            if lastActiveUrl != browserInfo.url {
                lastActiveUrl = browserInfo.url
                lastActiveTime = Date()
                return (true, browserInfo)
            }
            
            // 如果已经在访问这个URL
            if let lastTime = lastActiveTime {
                let duration = Date().timeIntervalSince(lastTime)
                if duration > Double(timeout) {
                    lastActiveTime = Date()
                    return (false, browserInfo)
                }
            }
        } else {
            // 如果切换到了其他URL，重置计时
            if lastActiveUrl != browserInfo.url {
                lastActiveUrl = browserInfo.url
                lastActiveTime = nil
            }
        }
        
        return (true, browserInfo)
    }
    
    func addToBlacklist(_ pattern: String) {
        if !urlBlacklist.contains(pattern) {
            var newList = urlBlacklist
            newList.append(pattern)
            urlBlacklist = newList
        }
    }
    
    func removeFromBlacklist(_ pattern: String) {
        urlBlacklist = urlBlacklist.filter { $0 != pattern }
    }
}

// 浏览器信息结构体
struct BrowserInfo {
    let url: String
    let title: String
}

// 浏览器适配器协议
protocol BrowserAdapter {
    func getBrowserInfo() -> BrowserInfo?
    static var bundleIdentifiers: [String] { get }
}
