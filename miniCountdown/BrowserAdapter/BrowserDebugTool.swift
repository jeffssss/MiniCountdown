//
//  BrowserDebugTool.swift
//  WorkMind
//
//  Created by Feng Ji on 2025/3/5.
//
import Foundation
import AppKit
import Cocoa
import ApplicationServices
import AXSwift

///临时测试用
class BrowserDebugTool {
    
    static func printAllNode(bundleId:String) {

        guard let uiApp = Application.allForBundleID(bundleId).first else {
            NSLog("Accessibility API执行失败")
            return
        }
        
        do {
            if let focusedWindow: UIElement = try uiApp.attribute(.focusedWindow) {
                NSLog("focusedWindow:\(focusedWindow)")
                try printChild(focusedWindow, "")
            }
        } catch {
            NSLog("异常:\(error.localizedDescription)")
        }
    }
    
    static func printChild(_ ele:UIElement, _ prefix: String) throws {
        NSLog("--------------------")
        NSLog("\(prefix):\(ele)")
        NSLog("attribute:\(try ele.attributesAsStrings())")
        if try ele.attributeIsSupported(.value), let value:Any = try ele.attribute(.value) {
            NSLog("value:\(value)")
            if value is String, (value as! String) == "https://www.baidu.com" {
                try printAllAttr(ele)
            }
        }
        
        if try ele.attributeIsSupported(.children), let children:[UIElement] = try ele.arrayAttribute(.children){
            for (index,c) in children.enumerated() {
                try printChild(c, "\(prefix).\(index+1)")
            }
        }
    }
    
    static func printAllAttr(_ ele:UIElement) throws {
        for attr in try ele.attributes() {
            if let a:Any = try ele.attribute(attr) {
                NSLog("\(attr) -> \(a)")
            }
        }
    }
}
