//
//  WorkMindRecord.swift
//  miniCountdown
//
//  Created by Feng Ji on 2025/2/11.
//
import Foundation
import CoreData

final class WorkMindRecord : NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkMindRecord> {
        return NSFetchRequest<WorkMindRecord>(entityName: "WorkMindRecord")
    }

    @NSManaged public var duration: Int32
    @NSManaged public var endTime: Date?
    @NSManaged public var id: String
    @NSManaged public var startTime: Date
    @NSManaged public var status: Int16
    @NSManaged public var planId: String

}
