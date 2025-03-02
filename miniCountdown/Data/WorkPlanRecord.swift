//
//  WorkPlanRecord.swift
//  miniCountdown
//
import Foundation
import CoreData

final class WorkPlanRecord : NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkPlanRecord> {
        return NSFetchRequest<WorkPlanRecord>(entityName: "WorkPlanRecord")
    }
    
    @NSManaged public var id: String
    @NSManaged public var periodDays: Int32
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var targetHours: Float
    @NSManaged public var workDays: Int32
    @NSManaged public var isActive: Int16
    @NSManaged public var workDurationMinutes: Int32 // 单次工作时长（分钟）
    
    // 已完成的工作时间（小时）
    public var completedHours: Float?
    
    // 检查日期范围是否与其他计划重叠
    static func hasOverlappingPlan(context: NSManagedObjectContext, startDate: Date, endDate: Date) -> Bool {
        let request: NSFetchRequest<WorkPlanRecord> = WorkPlanRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "isActive >= 0 AND NOT (endDate < %@ OR startDate > %@)",
            startDate as NSDate,
            endDate as NSDate
        )
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("检查重叠计划失败: \(error)")
            return false
        }
    }
    
    // 获取当前生效的工作计划
    static func getCurrentActivePlan(context: NSManagedObjectContext) -> WorkPlanRecord? {
        let request: NSFetchRequest<WorkPlanRecord> = WorkPlanRecord.fetchRequest()
        let now = Date()
        request.predicate = NSPredicate(
            format: "isActive >= 0 AND startDate <= %@ AND endDate >= %@",
            now as NSDate,
            now as NSDate
        )
        
        do {
            let plans = try context.fetch(request)
            return plans.first
        } catch {
            print("获取当前工作计划失败: \(error)")
            return nil
        }
    }
}