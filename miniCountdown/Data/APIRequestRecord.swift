import Foundation
import CoreData


final class APIRequestRecord: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<APIRequestRecord> {
        return NSFetchRequest<APIRequestRecord>(entityName: "APIRequestRecord")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var requestTime: Date
    @NSManaged public var inputPrompt: String
    @NSManaged public var screenshotPath: String
    @NSManaged public var modelName: String
    @NSManaged public var output: String?
    @NSManaged public var totalTokens: Int32
    @NSManaged public var requestDuration: Float
}
