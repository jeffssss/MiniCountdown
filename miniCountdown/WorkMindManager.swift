import Foundation
import CoreData

enum CountdownStatus: Int16 {
    case running = 0    // 计时中
    case completed = 1  // 倒计时结束
    case interrupted = 2 // 计时中断
}

class WorkMindManager {
    static let shared = WorkMindManager()
    
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    private init() {
        container = NSPersistentContainer(name: "WorkMind")
        container.loadPersistentStores { description, error in
            if let error = error {
                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                print("Core Data加载失败: \(error.localizedDescription)")
            }
        }
        context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
    }
    
    // 生成唯一ID：时间戳+随机数
    private func generateUniqueId() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "\(timestamp)_\(random)"
    }
    
    // 创建新的倒计时记录
    func createRecord(duration: Int32) -> WorkMindRecord {
        let record = WorkMindRecord(context: context)
        record.id = generateUniqueId()
        record.duration = duration
        record.startTime = Date()
        record.status = CountdownStatus.running.rawValue
        
        do {
            try context.save()
        } catch {
            print("保存记录失败: \(error.localizedDescription)")
        }
        
        return record
    }
    
    // 更新倒计时记录状态
    func updateRecord(_ record: WorkMindRecord, status: CountdownStatus) {
        record.status = status.rawValue
        
        // 只在完成或中断状态时更新结束时间
        if status == .completed || status == .interrupted {
            record.endTime = Date()
        }
        
        do {
            try context.save()
        } catch {
            print("更新记录失败: \(error.localizedDescription)")
        }
    }
    
    // 获取所有记录，按开始时间降序排列
    func getAllRecords() -> [WorkMindRecord] {
        let request: NSFetchRequest<WorkMindRecord> = WorkMindRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkMindRecord.startTime, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("获取记录失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // 获取指定时间范围内的记录
    func getRecords(from startDate: Date, to endDate: Date) -> [WorkMindRecord] {
        let request: NSFetchRequest<WorkMindRecord> = WorkMindRecord.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkMindRecord.startTime, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("获取记录失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // 删除记录
    func deleteRecord(_ record: WorkMindRecord) {
        context.delete(record)
        
        do {
            try context.save()
        } catch {
            print("删除记录失败: \(error.localizedDescription)")
        }
    }
    
    // 清空所有记录
    func deleteAllRecords() {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "WorkMindRecord")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try container.persistentStoreCoordinator.execute(deleteRequest, with: context)
        } catch {
            print("清空记录失败: \(error.localizedDescription)")
        }
    }
}
