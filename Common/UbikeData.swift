import Foundation
import CoreData
import UIKit

class UbikeData: NSManagedObject{
    @NSManaged var sna : String
    @NSManaged var sno : String
    @NSManaged var lat : Double
    @NSManaged var lng : Double
    @NSManaged var cityName: String
    
    override func awakeFromInsert() {
        
    }
    
    public func load(station: UbikeStation) {
        self.sno = station.no
        self.sna = station.name
        self.lat = station.latitude
        self.lng = station.longitude
        self.cityName = station.cityName
    }
}
