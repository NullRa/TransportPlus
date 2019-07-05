import Foundation
import CoreData
import UIKit

class Station: NSManagedObject {
    @NSManaged var no: String
    @NSManaged var name: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var cityName: String
}
