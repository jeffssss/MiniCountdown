import Foundation
import SwiftUI
import SwiftyJSON

class WorkMonitor {
    private let screenshotManager = ScreenshotManager.shared
    private let browserMonitor = BrowserMonitor.shared
    private var lastScreenshotTimeSinceStart: TimeInterval = 0
    
    typealias WorkStatusCallback = (String, String) -> Void
    
    func setLastScreenshotTime(_ time : TimeInterval) {
        lastScreenshotTimeSinceStart = time
    }
    
    func checkWorkStatus(timeSinceStart: TimeInterval, onCheckFail: WorkStatusCallback?) {
        // 检查应用监控状态
        let (appCheckResult, currentAppInfo) = AppMonitor.shared.checkWorkStatus()
        if !appCheckResult {
            DispatchQueue.main.async {
                if let onCheckFail = onCheckFail {
                    onCheckFail("认真工作啦！", "工作中不可长时间使用 <\(currentAppInfo?.name ?? "娱乐软件")>，请及时切换到工作相关的应用")
                }
            }
            return
        }
        
        //如果聚焦浏览器，则进行url检查
        if let currentAppInfo = currentAppInfo,
            browserMonitor.isBrowserApp(currentAppInfo) {
            
            let (browserCheckResult, browserInfo) = browserMonitor.checkBrowserStatus(currentAppInfo)
            if !browserCheckResult {
                DispatchQueue.main.async {
                    if let onCheckFail = onCheckFail {
                        onCheckFail("注意网页浏览！", "工作中不可长时间浏览当前网页")
                    }
                }
                return
            }
        }

        
        
        if timeSinceStart - lastScreenshotTimeSinceStart >= screenshotManager.interval {
            lastScreenshotTimeSinceStart = timeSinceStart
            //处理AI图像识别
            if AIService.shared.hasApiKey() {
                print("处理截图和识别逻辑")
                let screenshot = screenshotManager.takeScreenshot()
                if let image = screenshot.image, let screenshotPath = screenshot.path {
                    AIService.shared.analyzeImage(image: image, screenshotPath: screenshotPath) { result, error in
                        if let error = error {
                            print("AI分析失败: \(error.localizedDescription)")
                        } else if let result = result {
                            print("AI分析结果: \(result)")
                            if let jsonData = result.data(using: .utf8),
                               let json = try? JSON(data: jsonData) {
                                if !json["isWorking"].boolValue {
                                    DispatchQueue.main.async {
                                        if let onCheckFail = onCheckFail{
                                            onCheckFail(json["alert"].stringValue,
                                                        json["reason"].stringValue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
