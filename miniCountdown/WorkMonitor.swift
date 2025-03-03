import Foundation
import SwiftUI
import SwiftyJSON

class WorkMonitor {
    private let screenshotManager = ScreenshotManager.shared
    private var lastScreenshotTimeSinceStart: TimeInterval = 0
    
    typealias WorkStatusCallback = (String, String) -> Void
    
    func setLastScreenshotTime(_ time : TimeInterval) {
        lastScreenshotTimeSinceStart = time
    }
    
    func checkWorkStatus(timeSinceStart: TimeInterval, onCheckFail: WorkStatusCallback?) {
        // 检查应用监控状态
        if !AppMonitor.shared.checkWorkStatus() {
            DispatchQueue.main.async {
                if let onCheckFail = onCheckFail {
                    onCheckFail("禁用应用超过限制时间", "请及时切换到工作相关的应用")
                }
            }
            return
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
