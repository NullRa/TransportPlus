import Foundation
import CoreData

class BusStation: NSManagedObject {
    @NSManaged var number: String
    @NSManaged var name: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var cityName: String
    @NSManaged var busNumbers: [BusNumber]
}
