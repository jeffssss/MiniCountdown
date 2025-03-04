import Foundation
import AppKit
import Cocoa
import ApplicationServices

// Safari浏览器适配器
class SafariBrowserAdapter: BrowserAdapter {
    static var bundleIdentifiers: [String] = ["com.apple.Safari"]
    
    func getBrowserInfo() -> BrowserInfo? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              Self.bundleIdentifiers.contains(app.bundleIdentifier ?? "") else {
            return nil
        }
        
        // 使用Accessibility API获取Safari的URL和标题
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        // 获取窗口
        var value: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
        guard windowResult == .success, let windowsArray = value as? [AXUIElement], let window = windowsArray.first else {
            print("无法获取Safari窗口")
            return nil
        }
        
        // 获取工具栏
        var toolbarValue: CFTypeRef?
        let toolbarResult = AXUIElementCopyAttributeValue(window, "AXToolbar" as CFString, &toolbarValue)
        
        // 获取地址栏
        var url = ""
        if toolbarResult == .success {
            let toolbar = (toolbarValue as! AXUIElement)
            var addressValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(toolbar, "AXURLFieldText" as CFString, &addressValue) == .success,
               let urlString = addressValue as? String {
                url = urlString
            }
        }
        
        // 获取标题
        var titleValue: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
        var title = ""
        if titleResult == .success, let titleString = titleValue as? String {
            title = titleString.replacingOccurrences(of: " — Safari", with: "")
        }
        
        // 确保至少有URL或标题
        if !url.isEmpty || !title.isEmpty {
            return BrowserInfo(url: url, title: title)
        }
        
        print("无法通过Accessibility API获取Safari信息")
        return nil
    }
}
