import Foundation
import CoreData
import UIKit

class BusStation: NSManagedObject {
    @NSManaged var number: String
    @NSManaged var name: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var cityName: String
    @NSManaged var busNumbers: [BusNumber]
}
class BusNumber: NSObject, NSCoding {
    var busName: String?
    var busID: String?

    override init() {
    }

    required init?(coder aDecoder: NSCoder) {
        busName = aDecoder.decodeObject(forKey: "busName") as? String
        busID = aDecoder.decodeObject(forKey: "busID") as? String
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(busName, forKey: "busName")
        aCoder.encode(busID, forKey: "busID")
    }
}
