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
    
    // MARK: - 工作计划相关方法
    
    // 创建新的工作计划
    func createWorkPlan(periodDays: Int, startDate: Date, targetHours: Float, workDays: Int, workDurationMinutes: Int) -> WorkPlanRecord? {
        // 计算结束日期：开始日期增加periodDays天后减去1秒
        guard let tempEndDate = Calendar.current.date(byAdding: .day, value: periodDays, to: startDate),
              let endDate = Calendar.current.date(byAdding: .second, value: -1, to: tempEndDate) else {
            return nil
        }
        
        // 检查日期重叠
        if WorkPlanRecord.hasOverlappingPlan(context: context, startDate: startDate, endDate: endDate) {
            return nil
        }
        
        // 创建新计划
        let plan = WorkPlanRecord(context: context)
        plan.id = UUID().uuidString
        plan.periodDays = Int32(periodDays)
        plan.startDate = Calendar.current.startOfDay(for: startDate)
        plan.endDate = endDate
        plan.targetHours = targetHours
        plan.workDays = Int32(workDays)
        plan.workDurationMinutes = Int32(workDurationMinutes)
        plan.isActive = 0
        
        do {
            try context.save()
            print("保存工作计划: \(plan.id) \(plan.startDate ) \(plan.periodDays)天 \(plan.targetHours)H")
            return plan
        } catch {
            print("保存工作计划失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 获取当前生效的工作计划
    func getCurrentActivePlan() -> WorkPlanRecord? {
        return WorkPlanRecord.getCurrentActivePlan(context: context)
    }
    
    // 分页获取工作计划列表
    func getWorkPlans(page: Int, pageSize: Int) -> [WorkPlanRecord] {
        let request: NSFetchRequest<WorkPlanRecord> = WorkPlanRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkPlanRecord.startDate, ascending: false)]
        request.fetchLimit = pageSize
        request.fetchOffset = page * pageSize
        
        do {
            return try context.fetch(request)
        } catch {
            print("分页加载工作计划失败: \(error.localizedDescription)")
            return []
        }
    }
    
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
        
        // 检查并关联当前生效的工作计划
        if let activePlan = getCurrentActivePlan() {
            record.planId = activePlan.id
        }
        
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
    
    // 分页获取记录
    func getRecordsByPage(page: Int, pageSize: Int) -> [WorkMindRecord] {
        let fetchRequest: NSFetchRequest<WorkMindRecord> = WorkMindRecord.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WorkMindRecord.startTime, ascending: false)]
        fetchRequest.fetchLimit = pageSize
        fetchRequest.fetchOffset = page * pageSize
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("加载记录失败: \(error.localizedDescription)")
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
    
    // 获取指定计划的已完成总时间（秒）
    func getCompletedTotalSeconds(planId: String) -> Int32 {
        let request: NSFetchRequest<WorkMindRecord> = WorkMindRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "planId == %@ AND status == %d",
            planId,
            CountdownStatus.completed.rawValue
        )
        
        do {
            let records = try context.fetch(request)
            return records.reduce(0) { $0 + $1.duration }
        } catch {
            print("获取计划完成时间失败: \(error.localizedDescription)")
            return 0
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
    
    // MARK: - API请求记录相关方法
    
    // 分页获取API请求记录
    func getAPIRequestRecords(page: Int, pageSize: Int) -> [APIRequestRecord] {
        let fetchRequest = APIRequestRecord.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \APIRequestRecord.requestTime, ascending: false)]
        fetchRequest.fetchLimit = pageSize
        fetchRequest.fetchOffset = page * pageSize
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("加载API请求记录失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // 创建新的API请求记录
    func createAPIRequestRecord(requestTime: Date, inputPrompt: String, modelName: String, screenshotPath: String) -> APIRequestRecord? {
        let record = APIRequestRecord(context: context)
        record.id = UUID()
        record.requestTime = requestTime
        record.inputPrompt = inputPrompt
        record.modelName = modelName
        record.screenshotPath = screenshotPath
        
        do {
            try context.save()
            return record
        } catch {
            print("创建API请求记录失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 更新API请求记录
    func updateAPIRequestRecord(_ record: APIRequestRecord, output: String?, totalTokens: Int32?, requestDuration: Float) {
        record.requestDuration = requestDuration
        record.output = output ?? ""
        record.totalTokens = totalTokens ?? 0
        
        do {
            try context.save()
        } catch {
            print("更新API请求记录失败: \(error.localizedDescription)")
        }
    }
}
