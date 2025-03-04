import Foundation
import SwiftyJSON
import Alamofire
import AppKit

class AIService {
    static let shared = AIService()
    private let userDefaults = UserDefaults.standard
    private let defaultModelName = "gpt-4o-mini"
    private let temperatureKey = "apiTemperatureKey"
    
    private var baseURL: String {
        switch aiChannel {
        case .ollama:
            return apiEndpoint + "/api/chat"
        case .aiHubMix:
            return "https://aihubmix.com/v1/chat/completions"
        case .openAI:
            return "https://api.openai.com/v1/chat/completions"
        case .grok:
            return "https://api.x.ai/v1/chat/completions"
        }
    }
    
    private let apiKeyPrefix = "aiServiceApiKey_"
    private var apiKeyKey: String {
        return apiKeyPrefix + String(describing: aiChannel)
    }
    
    private let inputPromptKey = "aiServiceInputPrompt"
    private let systemPromptKey = "aiServiceSystemPrompt"
    
    private let apiChanelKey = "aiServiceChannel"
    private let apiEndpointKey = "aiServiceEndpoint"
    
    private let modelNamePrefix = "aiServiceModelName_"
    private var modelNameKey: String {
        return modelNamePrefix + String(describing: aiChannel)
    }
    
    var modelName: String {
        get { userDefaults.string(forKey: modelNameKey) ?? defaultModelName }
        set { userDefaults.set(newValue, forKey: modelNameKey) }
    }
    
    var inputPrompt: String {
        get { userDefaults.string(forKey: inputPromptKey) ?? defaultInputPrompt }
        set { userDefaults.set(newValue, forKey: inputPromptKey) }
    }
    
    var systemPrompt: String {
        get { userDefaults.string(forKey: systemPromptKey) ?? defaultSystemPrompt }
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
    
    var apiKey: String {
        get { userDefaults.string(forKey: apiKeyKey) ?? "" }
        set { userDefaults.set(newValue, forKey: apiKeyKey) }
    }
    
    var temperature: Double {
        get { userDefaults.double(forKey: temperatureKey) }
        set { userDefaults.set(newValue, forKey: temperatureKey) }
    }
    
    //    func getApiKey(for channel: APIChannel) -> String {
    //        return userDefaults.string(forKey: apiKeyPrefix + String(describing: channel)) ?? ""
    //    }
    
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
        let modelName = self.modelName
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
        //        print("参数:\(parameters)")
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
        switch aiChannel{
        case .aiHubMix, .openAI, .grok:
            return  [
                "model": modelName,
                "stream": false,
                "temperature": temperature,
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
        case .ollama:
            return  [
                "model": modelName,
                "messages":[
                    [
                        "role": "system",
                        "content": "请用json输出,如果我没有给你图片，请你也用json的方式告知我没有图片",
                    ],
                    [
                        "role": "user",
                        "content": "请描述图里的内容，不要编造",
                        "images": [base64Image],
                    ]
                ],
                "stream": false,
                "format": "json",
                //                "format": [
                //                    "type": "object",
                //                    "properties": [
                //                        "score":[
                //                            "type": "integer"
                //                        ],
                //                        "isWorking":[
                //                            "type": "boolean"
                //                        ],
                //                        "threshold":[
                //                            "type": "integer"
                //                        ],
                //                        "desc":[
                //                            "type": "string"
                //                        ],
                //                        "reason":[
                //                            "type": "string"
                //                        ],
                //                        "alert":[
                //                            "type": "string"
                //                        ]
                //                    ]
                //                ],
            ]
        }
    }
    
    private let defaultInputPrompt = """
判定阈值为60.
介绍：我是一名开发者，常用的软件包括VSCode、Xcode等代码编辑器
补充规则：
```
我正在工作的场景：
1. 在搜索引擎里搜索资料，或查阅相关领域的信息。
2. 在飞书、钉钉、Discord中与他人进行文字沟通
我不在工作的场景：
1. 正在浏览微博、抖音、爱奇艺、芒果TV等娱乐性网站
```
请使用中文进行回答。
"""
    
    private let defaultSystemPrompt = """
注意：仅json字符串的形式返回结果，不要包含md格式的代码框或者其他描述性语句。
你现在是监督我工作的管理员，需要根据我提供的信息以及屏幕截图，判断我是否在认真工作。
1. 我会输入判定阈值、我的背景介绍(比如我的职业、我工作用的一些软件、补充的判定条件)、以及我当前电脑的截屏。
2. 你需要对我进行打分：100代表我一定在认真工作，0代表我一定没有认真工作。
3. 基于我给到你的判定阈值，请你得出我是否在认真工作的结论：得分大于阈值，则认真工作；否则是没有认真工作。
4. 请你简要描述我目前在做的事；
5. 若判定我没有认真工作，请说明你判断的原因
6. 当判定我没有认真工作时，请你扮演管理员的角色，编写一两句督促我工作的话语(100字以内)。
7. 最终结果以json的形式输出。json字段包括：
* score：得分
* isWorking: 是否认真工作
* threshold: 判定阈值
* desc: 截图内容的描述
* reason：当判定没有认真工作时，判定的理由
* alert: 当判定没有认真工作时，提醒的话语
—
关于判断逻辑的补充：
* 优先判断屏幕中正在聚焦的窗口的内容，判断是否是在工作。
* 如果截图里是网页内容，请你识别网页里的较大部分的文字，再进行判断。如果网页中在播放视频，请你基于视频的图像，判断我是在娱乐还是在学习。
* 补充规则仅仅是一些高优先级的判定规则。如果我正在做的事情不在补充规则里，则需要你根据你的理解，自行判断。
* 只要判断我是否在工作状态即可，无需判断我的注意力是否在有效的工作上。
* 忽略截图底部的dock中的图标以及顶部的菜单栏的内容。
再次强调，使用JSON回答，不要包含除JSON外的其他内容。
"""
}
