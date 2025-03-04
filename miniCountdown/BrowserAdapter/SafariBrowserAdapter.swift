import Foundation
import AppKit
import Cocoa
import ApplicationServices
import AXSwift

// Safari浏览器适配器
class SafariBrowserAdapter: BrowserAdapter {
    static var bundleIdentifiers: [String] = ["com.apple.Safari"]
    
    func getBrowserInfo() -> BrowserInfo? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              Self.bundleIdentifiers.contains(app.bundleIdentifier ?? "") else {
            return nil
        }
        
        // 提取URL和标题
        var url = ""
        var title = ""
        
        guard let uiApp = Application(app) else {
            NSLog("Accessibility API执行失败")
            return nil
        }
        
        do {
            if let focusedWindow: UIElement = try uiApp.attribute(.focusedWindow) {
                
                title = try BrowserHelper.str(focusedWindow, .title)
                
                let condition = { (e:UIElement) in
                    if try e.attributeIsSupported(.identifier),
                       let identifier:String = try e.attribute(.identifier),
                       identifier == "WEB_BROWSER_ADDRESS_AND_SEARCH_FIELD",
                       try e.attributeIsSupported(.identifier), //获取的value需要保证是String类型
                       let v:Any = try e.attribute(.value) , v is String {
                        
                        return true
                    }
                    return false
                }
                
                if let addressEle = try BrowserHelper.getURLTextElement(focusedWindow, condition) {
                    url = try BrowserHelper.str(addressEle, .value)
                    return BrowserInfo(url: url, title: title)
                }
            }
        } catch {
            NSLog("提取标题及URL异常:\(error.localizedDescription)")
            return nil
        }
        
        print("无法通过Accessibility API获取Safari信息")
        return nil
    }
}
