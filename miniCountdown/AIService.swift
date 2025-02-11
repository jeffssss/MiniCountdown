import Foundation
import SwiftyJSON
import Alamofire
import AppKit

class AIService {
    static let shared = AIService()
    private let baseURL = "https://aihubmix.com/v1/chat/completions"
    private var apiKey: String {
        return UserDefaults.standard.string(forKey: "aiServiceApiKey") ?? ""
    }
    
    func hasApiKey() -> Bool {
        return apiKey != ""
    }
    
    private init() {}
    
    func analyzeImage(image: NSImage, completion: @escaping (String?, Error?) -> Void) {
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
        
        let parameters: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "这是我电脑的截屏。请用100字以内描述我现在在做什么？"
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "low"
                            ]
                        ]
                    ]
                ]
            ],
        ]
        
        AF.request(baseURL,
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   headers: headers)
        .responseData { response in
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
                    if let content = json["choices"].array?.first?["message"]["content"].string {
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
                completion(nil, error)
            }
        }
    }
}
