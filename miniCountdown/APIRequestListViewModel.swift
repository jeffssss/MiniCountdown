import Foundation
import CoreData
import AppKit
import SwiftUI
import SwiftyJSON

class APIRequestListViewModel: ObservableObject {
    @Published var records: [APIRequestRecord] = []
    private var currentPage = 0
    private let pageSize = 20
    
    init() {
        loadRecords()
    }
    
    func refresh() {
        loadRecords()
    }
    
    func loadRecords() {
        let fetchRequest = APIRequestRecord.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \APIRequestRecord.requestTime, ascending: false)]
        fetchRequest.fetchLimit = pageSize
        fetchRequest.fetchOffset = 0
        
        records = WorkMindManager.shared.getAPIRequestRecords(page: 0, pageSize: pageSize)
        currentPage = 0
    }
    
    func loadNextPage() {
        currentPage += 1
        let fetchRequest = APIRequestRecord.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \APIRequestRecord.requestTime, ascending: false)]
        fetchRequest.fetchLimit = pageSize
        fetchRequest.fetchOffset = currentPage * pageSize
        
        let newRecords = WorkMindManager.shared.getAPIRequestRecords(page: currentPage, pageSize: pageSize)
        if !newRecords.isEmpty {
            records.append(contentsOf: newRecords)
        }
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "--" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    func formatDuration(_ duration: Float) -> String {
        return String(format: "%.2f毫秒", duration)
    }
    
    func formatTokens(_ tokens: Int32) -> String {
        return "\(tokens) tokens"
    }
    
    func parseScoreAndThreshold(_ output: String?) -> (Int?, Int?)? {
        guard let output = output else { return nil }
        
        guard let data = output.data(using: .utf8) else { return nil }
        
        let json = try? JSON(data: data)
        guard let content = json?["choices"].array?.first?["message"]["content"].string else { return nil }
        
        // 移除可能存在的 Markdown 代码块标记
        var processedContent = content
        if processedContent.hasPrefix("```json") && processedContent.hasSuffix("```") {
            processedContent = processedContent.replacingOccurrences(of: "```json", with: "")
            processedContent = processedContent.replacingOccurrences(of: "```", with: "")
        }
        
        guard let contentData = processedContent.data(using: .utf8) else { return nil }
        
        let contentJson = try? JSON(data: contentData)
        let score = contentJson?["score"].int
        let threshold = contentJson?["threshold"].int
        
        return (score, threshold)
    }
    
}
