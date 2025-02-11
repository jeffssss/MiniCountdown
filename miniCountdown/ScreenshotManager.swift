import Foundation
import AppKit

class ScreenshotManager {
    static let shared = ScreenshotManager()
    private let userDefaults = UserDefaults.standard
    
    // 默认配置
    private let defaultInterval: TimeInterval = 5
    private let defaultSavePath = "/Users/fengji/Documents/WorkMind"
    
    // UserDefaults keys
    private let intervalKey = "screenshotInterval"
    private let savePathKey = "screenshotSavePath"
    private let bookmarkKey = "screenshotFolderBookmark"
    
    private var securityScopedURL: URL?
    
    private init() {
        // 确保保存目录存在
        createSaveDirectoryIfNeeded()
        // 尝试恢复书签访问权限
        resolveBookmark()
    }
    
    private func resolveBookmark() {
        guard let bookmarkData = userDefaults.data(forKey: bookmarkKey) else { return }
        
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData,
                             options: .withSecurityScope,
                             relativeTo: nil,
                             bookmarkDataIsStale: &isStale)
            
            if isStale {
                // 如果书签已过期，尝试重新创建
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    let newBookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                              includingResourceValuesForKeys: nil,
                                                              relativeTo: nil)
                    userDefaults.set(newBookmarkData, forKey: bookmarkKey)
                }
            }
            
            securityScopedURL = url
        } catch {
            print("恢复书签访问权限失败: \(error)")
            securityScopedURL = nil
        }
    }
    
    private func withSecurityScope<T>(_ operation: () throws -> T) throws -> T {
        if let url = securityScopedURL {
            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "ScreenshotManager", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "无法访问安全作用域资源"])
            }
            defer { url.stopAccessingSecurityScopedResource() }
            return try operation()
        }
        return try operation()
    }
    
    // 获取截图间隔时间（秒）
    var interval: TimeInterval {
        get { userDefaults.double(forKey: intervalKey) > 0 ? userDefaults.double(forKey: intervalKey) : defaultInterval }
        set { userDefaults.set(newValue, forKey: intervalKey) }
    }
    
    // 获取保存路径
    var savePath: String {
        get { userDefaults.string(forKey: savePathKey) ?? defaultSavePath }
        set { 
            userDefaults.set(newValue, forKey: savePathKey)
            createSaveDirectoryIfNeeded()
        }
    }
    
    // 执行截图
    public func takeScreenshot() {
        do {
            try withSecurityScope {
                let timestamp = Int(Date().timeIntervalSince1970)
                let fileURL = URL(fileURLWithPath: savePath).appendingPathComponent("\(timestamp).png")
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                process.arguments = ["-x", fileURL.path] // -x 表示无声截图
                
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    if let image = NSImage(contentsOfFile: fileURL.path) {
                        try self.resizeImage(image).write(to: fileURL)
                        print("截图已保存到: \(fileURL.path)")
                    }
                } else {
                    print("截图失败: 进程退出状态码 \(process.terminationStatus)")
                }
            }
        } catch {
            print("截图失败: \(error.localizedDescription)")
        }
    }
    
    // 调整图片大小并转换为PNG数据
    private func resizeImage(_ image: NSImage) -> Data {
        let originalSize = image.size
        let newSize = NSSize(width: originalSize.width * 0.5, height: originalSize.height * 0.5)
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: originalSize),
                  operation: .copy,
                  fraction: 1.0)
        resizedImage.unlockFocus()
        
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            fatalError("无法转换图片格式")
        }
        
        return pngData
    }
    
    // 确保保存目录存在
    private func createSaveDirectoryIfNeeded() {
        do {
            try withSecurityScope {
                let fileManager = FileManager.default
                let directoryURL = URL(fileURLWithPath: savePath)
                
                if !fileManager.fileExists(atPath: savePath) {
                    try fileManager.createDirectory(at: directoryURL,
                                                  withIntermediateDirectories: true,
                                                  attributes: nil)
                    print("成功创建目录: \(savePath)")
                } else {
                    var isDirectory: ObjCBool = false
                    if fileManager.fileExists(atPath: savePath, isDirectory: &isDirectory) {
                        if !isDirectory.boolValue {
                            print("错误：指定的路径存在但不是目录")
                        } else {
                            print("目录已存在: \(savePath)")
                        }
                    }
                }
            }
        } catch {
            print("创建目录失败: \(error.localizedDescription)")
        }
    }
}
