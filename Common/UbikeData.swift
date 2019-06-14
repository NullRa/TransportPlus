import Foundation
import CoreData
import UIKit

class UbikeData: NSManagedObject{
    @NSManaged var sna : String
    @NSManaged var sno : String
    @NSManaged var lat : Double
    @NSManaged var lng : Double
    
    override func awakeFromInsert() {
        
    }
}
