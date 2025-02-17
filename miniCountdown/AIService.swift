import Foundation
import SwiftyJSON
import Alamofire
import AppKit

class AIService {
    static let shared = AIService()
    private let userDefaults = UserDefaults.standard
    private let baseURL = "https://aihubmix.com/v1/chat/completions"
    private let defaultModelName = "gpt-4o-mini"
    private let modelNameKey = "aiServiceModelName"
    
    private let apiKeyKey = "aiServiceApiKey"
    
    private let defaultInputPrompt = "这是我电脑的截屏。请用100字以内描述我现在在做什么？"
    private let inputPromptKey = "aiServiceInputPrompt"
    private let systemPromptKey = "aiServiceSystemPrompt"

    private let apiChanelKey = "aiServiceChannel"
    private let apiEndpointKey = "aiServiceEndpoint"
    
    var modelName: String {
        get { userDefaults.string(forKey: modelNameKey) ?? defaultModelName }
        set { userDefaults.set(newValue, forKey: modelNameKey) }
    }
    
    var inputPrompt: String {
        get { userDefaults.string(forKey: inputPromptKey) ?? defaultInputPrompt }
        set { userDefaults.set(newValue, forKey: inputPromptKey) }
    }
    
    var systemPrompt: String {
        get { userDefaults.string(forKey: systemPromptKey) ?? "" }
        set { userDefaults.set(newValue, forKey: systemPromptKey) }
    }

    var aiChannel: APIChannel {
        get { APIChannel(rawValue: userDefaults.integer(forKey: apiChanelKey)) ?? .ollama}
        set { userDefaults.set(newValue.rawValue, forKey: apiChanelKey) }
    }

    var apiEndpoint: String {
        get { userDefaults.string(forKey: apiEndpointKey) ?? "http://localhost:11434" }
        set { userDefaults.set(newValue, forKey: apiEndpointKey) }
    }

    var apiKey : String{
        get { userDefaults.string(forKey: apiKeyKey) ?? "" }
        set { userDefaults.set(newValue, forKey: apiKeyKey) }
    }
    
    func hasApiKey() -> Bool {
        return apiKey != ""
    }
    
    private init() {}
    
    func analyzeImage(image: NSImage, screenshotPath: String, completion: @escaping (String?, Error?) -> Void) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            completion(nil, NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "图片转换失败"]))
            return
        }
        
        let base64Image = jpegData.base64EncodedString()
        let modelName = UserDefaults.standard.string(forKey: modelNameKey) ?? defaultModelName
        let requestStartTime = Date()
        var apiRecord: APIRequestRecord? = nil
        
        // 创建API请求记录
        apiRecord = WorkMindManager.shared.createAPIRequestRecord(
            requestTime: requestStartTime,
            inputPrompt: self.inputPrompt + "\n" + self.systemPrompt,
            modelName: modelName,
            screenshotPath: screenshotPath
        )
        
        let parameters = getRequestParam(modelName: modelName, base64Image: base64Image)
        
        AF.request(baseURL,
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   headers: headers)
        .responseData { response in
            let requestEndTime = Date()
            let duration = Float(requestEndTime.timeIntervalSince(requestStartTime) * 1000) // 转换为毫秒
            
            // 添加详细的错误信息打印
            if let error = response.error {
                print("网络请求错误详情：")
                print("Error Code: \(error._code)")
                print("Error Description: \(error.localizedDescription)")
                print("Error Debug Description: \(error.errorDescription ?? "")")
                print("Underlying Error: \(String(describing: (error.underlyingError)))")
            }
            
            switch response.result {
            case .success(let data):
                print("AI请求response：\(String(data: data, encoding: .utf8) ?? "Unknown")")
                do {
                    let json = try JSON(data: data)
                    // 更新API请求记录
                    if let record = apiRecord {
                        WorkMindManager.shared.updateAPIRequestRecord(
                            record,
                            output: String(data: data, encoding: .utf8) ?? "Unknown",
                            totalTokens: json["usage"]["total_tokens"].exists() ? json["usage"]["total_tokens"].int32Value : nil,
                            requestDuration: duration
                        )
                    }
                    
                    if var content = json["choices"].array?.first?["message"]["content"].string {
                        // 移除可能存在的 Markdown 代码块标记
                        if content.hasPrefix("```json") && content.hasSuffix("```") {
                            content = content.replacingOccurrences(of: "```json", with: "")
                            content = content.replacingOccurrences(of: "```", with: "")
                        }
                        completion(content, nil)
                    } else {
                        completion(nil, NSError(domain: "AIService",
                                                code: -1,
                                                userInfo: [NSLocalizedDescriptionKey: "解析响应失败"]))
                    }
                } catch {
                    completion(nil, error)
                }
            case .failure(let error):
                if let record = apiRecord {
                    WorkMindManager.shared.updateAPIRequestRecord(
                        record,
                        output: error.localizedDescription,
                        totalTokens: nil,
                        requestDuration: duration
                    )
                }
                completion(nil, error)
            }
        }
    }
    
    func getRequestParam(modelName:String, base64Image: String) -> [String: Any] {
        return  [
            "model": modelName,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": self.inputPrompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "low"
                            ]
                        ]
                    ]
                ],
                [
                    "role": "system",
                    "content": self.systemPrompt
                ]
            ],
        ]
    }
}
