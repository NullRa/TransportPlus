import Foundation
import CoreData
import UIKit

class UbikeStation: NSManagedObject {
    @NSManaged var number: String
    @NSManaged var name: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var cityName: String
}
