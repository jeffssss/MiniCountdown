import Foundation
import AppKit

class AppMonitor {
    static let shared = AppMonitor()
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults keys
    private let banListKey = "appMonitorBanList"
    private let timeoutKey = "appMonitorTimeout"
    
    // 默认配置
    private let defaultTimeout: Int = 30
    
    private var lastActiveApp: String? = nil
    private var lastActiveTime: Date? = nil
    
    var banList: [String] {
        get { userDefaults.stringArray(forKey: banListKey) ?? [] }
        set { userDefaults.set(newValue, forKey: banListKey) }
    }
    
    var timeout: Int {
        get { userDefaults.integer(forKey: timeoutKey) > 0 ? userDefaults.integer(forKey: timeoutKey) : defaultTimeout }
        set { userDefaults.set(newValue, forKey: timeoutKey) }
    }
    
    private init() {}
    
    func checkWorkStatus() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return true }
        let bundleIdentifier = frontmostApp.bundleIdentifier ?? ""
        
        // 如果应用在禁用列表中
        if banList.contains(bundleIdentifier) {
            // 如果是新切换到这个应用
            if lastActiveApp != bundleIdentifier {
                lastActiveApp = bundleIdentifier
                lastActiveTime = Date()
                return true
            }
            
            // 如果已经在使用这个应用
            if let lastTime = lastActiveTime {
                let duration = Date().timeIntervalSince(lastTime)
                if duration > Double(timeout) {
                    return false
                }
            }
        } else {
            // 如果切换到了其他应用，重置计时
            if lastActiveApp != bundleIdentifier {
                lastActiveApp = bundleIdentifier
                lastActiveTime = nil
            }
        }
        
        return true
    }
    
    func addToBanList(_ bundleIdentifier: String) {
        if !banList.contains(bundleIdentifier) {
            var newList = banList
            newList.append(bundleIdentifier)
            banList = newList
        }
    }
    
    func removeFromBanList(_ bundleIdentifier: String) {
        banList = banList.filter { $0 != bundleIdentifier }
    }
    
    func getRunningApplications() -> [AppInfo] {
        return NSWorkspace.shared.runningApplications
            .filter { $0.bundleIdentifier != nil && $0.localizedName != nil }
            .map { AppInfo(bundleIdentifier: $0.bundleIdentifier!, name: $0.localizedName!) }
    }
}