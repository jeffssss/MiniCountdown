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
            return formatDurationSeconds(Int(record.duration))
        case CountdownStatus.interrupted.rawValue:
            if let endTime = record.endTime {
                let duration = Int(endTime.timeIntervalSince(record.startTime))
                return formatDurationSeconds(duration)
            }
            return "--"
        default:
            return "--"
        }
    }
    
    private func formatDurationSeconds(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        var parts: [String] = []
        
        if hours > 0 {
            parts.append("\(hours)小时")
        }
        if minutes > 0 {
            parts.append("\(minutes)分")
        }
        if seconds > 0 || parts.isEmpty {
            parts.append("\(seconds)秒")
        }
        
        return parts.joined()
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
