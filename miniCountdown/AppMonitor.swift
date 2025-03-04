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
    
    func checkWorkStatus() -> (Bool, AppInfo?) {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return (true, nil)}
        let bundleIdentifier = frontmostApp.bundleIdentifier ?? ""
        let appName = frontmostApp.localizedName ?? "当前应用"
        
        // 如果应用在禁用列表中
        if banList.contains(bundleIdentifier) {
            // 如果是新切换到这个应用
            if lastActiveApp != bundleIdentifier {
                print("切换至: \(appName)(\(bundleIdentifier)) in ban list")
                lastActiveApp = bundleIdentifier
                lastActiveTime = Date()
                return (true, AppInfo(bundleIdentifier: bundleIdentifier,name: appName))
            }
            
            // 如果已经在使用这个应用
            if let lastTime = lastActiveTime {
                let duration = Date().timeIntervalSince(lastTime)
                if duration > Double(timeout) {
                    lastActiveTime = Date()
                    return (false, AppInfo(bundleIdentifier: bundleIdentifier,name: appName))
                }
            }
        } else {
            // 如果切换到了其他应用，重置计时
            if lastActiveApp != bundleIdentifier {
                print("切换至: \(appName)(\(bundleIdentifier))")
                lastActiveApp = bundleIdentifier
                lastActiveTime = nil
            }
        }
        
        return (true, AppInfo(bundleIdentifier: bundleIdentifier,name: appName))
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
        let apps = NSWorkspace.shared.runningApplications
            .filter { app in
                guard let bundleId = app.bundleIdentifier,
                      let name = app.localizedName,
                      app.activationPolicy == .regular else {
                    return false
                }
                return true
            }
        
        // 使用Dictionary来去除重复的应用，保留第一个出现的实例
        var uniqueApps: [String: NSRunningApplication] = [:]
        for app in apps {
            if let bundleId = app.bundleIdentifier,
               uniqueApps[bundleId] == nil {
                uniqueApps[bundleId] = app
            }
        }
        
        return uniqueApps.values
            .map { AppInfo(bundleIdentifier: $0.bundleIdentifier!, name: $0.localizedName!) }
    }
}
