import Foundation
import AppKit
import Cocoa
import AXSwift

///Chrome浏览器适配器
///当前思路：遍历所有UIElement，找到AXDOMClassList.Contains(OmniboxViewViews)的节点，这个节点就是存储URL的节点。
///Plan B: 如果后续Chrome版本修改导致上述逻辑行不通，可以考虑以下方案
///1. 找到所有 AXTextField ->
///2.  找到角色为 "AXWebArea" 的元素 ->
///3. 检查每个 AXTextField 的祖先列表，排除包含网页区域的元素，找到地址栏
class ChromeBrowserAdapter: BrowserAdapter {
    static var bundleIdentifiers: [String] = ["com.google.Chrome"]
    
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
                
                title = try str(focusedWindow, .title)
                
                if let addressEle = try getAddrTextEle(focusedWindow) {
                    url = try str(addressEle, .value)
                    return BrowserInfo(url: url, title: title)
                }
            }
        } catch {
            NSLog("提取标题及URL异常:\(error.localizedDescription)")
            return nil
        }
        
        print("无法通过Accessibility API获取Chrome信息")
        return nil
    }
    
    private func getAddrTextEle(_ ele:UIElement) throws -> UIElement? {
        
        if try ele.attributeIsSupported("AXDOMClassList") {
            if let domClass:[String] = try ele.arrayAttribute("AXDOMClassList"), domClass.contains("OmniboxViewViews") {
                return ele
            }
        }
        
        if try ele.attributeIsSupported(.children),
           let children:[UIElement] = try ele.arrayAttribute(.children){
            for c in children {
                if let result = try getAddrTextEle(c) {
                    return result
                }
            }
        }
        
        return nil
    }
    
    private func str(_ ele:UIElement, _ attr:Attribute) throws -> String {
        if let a:String =  try ele.attribute(attr) {
            return a
        }
        return "nil"
    }
    
    private func str(_ ele:UIElement, _ attr:String) throws -> String {
        if let a:String =  try ele.attribute(attr) {
            return a
        }
        return "nil"
    }
}
