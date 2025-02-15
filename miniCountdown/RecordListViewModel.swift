import Foundation
import CoreData

class RecordListViewModel: ObservableObject {
    @Published var records: [WorkMindRecord] = []
    private var currentPage = 0
    private let pageSize = 20
    private var hasMoreData = true
    
    init() {
        loadNextPage()
    }
    
    func refresh() {
        records = []
        currentPage = 0
        hasMoreData = true
        loadNextPage()
    }
    
    func loadNextPage() {
        guard hasMoreData else { return }
        
        let newRecords = WorkMindManager.shared.getRecordsByPage(page: currentPage, pageSize: pageSize)
        if newRecords.count < pageSize {
            hasMoreData = false
        }
        records.append(contentsOf: newRecords)
        currentPage += 1
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "--" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "--" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm"
        return dateFormatter.string(from: date)
    }
    
    func formatTimeRange(_ startTime: Date?, _ endTime: Date?) -> String {
        let startStr = startTime != nil ? formatTime(startTime) : "--"
        let endStr = endTime != nil ? formatTime(endTime) : "--"
        return "\(startStr) ~ \(endStr)"
    }
    
    func calculateDuration(record: WorkMindRecord) -> String {
        switch record.status {
        case CountdownStatus.running.rawValue:
            return "--"
        case CountdownStatus.completed.rawValue:
            return "\(record.duration)秒"
        case CountdownStatus.interrupted.rawValue:
            if let endTime = record.endTime {
                let duration = Int(endTime.timeIntervalSince(record.startTime))
                return "\(duration)秒"
            }
            return "--"
        default:
            return "--"
        }
    }
    
    func getStatusName(status: Int16) -> String {
        switch status {
        case CountdownStatus.running.rawValue:
            return "进行中"
        case CountdownStatus.completed.rawValue:
            return "已完成"
        case CountdownStatus.interrupted.rawValue:
            return "已中断"
        default:
            return "未知"
        }
    }
}
