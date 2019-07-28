import Foundation

class BusNumber: NSObject, NSCoding {
    var busName: String?
    var busID: String?
    var routeUID: String?

    override init() {
    }

    required init?(coder aDecoder: NSCoder) {
        busName = aDecoder.decodeObject(forKey: "busName") as? String
        busID = aDecoder.decodeObject(forKey: "busID") as? String
        routeUID = aDecoder.decodeObject(forKey: "routeUID") as? String
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(busName, forKey: "busName")
        aCoder.encode(busID, forKey: "busID")
        aCoder.encode(routeUID, forKey: "routeUID")
    }
}
