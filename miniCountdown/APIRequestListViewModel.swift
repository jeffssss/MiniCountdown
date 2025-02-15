import Foundation
import CoreData
import AppKit
import SwiftUI

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
}
