import Foundation
import CoreLocation
import CommonCrypto
import MapKit

// swiftlint:disable all
struct BusStateJson: Codable {
    var StopUID: String?
    var StopStatus: Int?
    var EstimateTime: Int?
}

struct BusStationJson: Codable {
    var StationUID: String
    var StationName: StationName
    var StationPosition: StationPosition
    var Stops: [Stops]
    struct StationName: Codable {
        var Zh_tw: String
    }
    struct StationPosition: Codable {
        var PositionLat: Double
        var PositionLon: Double
    }
    struct Stops: Codable {
        var StopUID: String
        var RouteName: RouteName
        struct RouteName: Codable {
            var Zh_tw: String
        }
    }
}
// swiftlint:enable all

class BusJson {
    let stationAPI: BusStationAPI

    init() {
        self.stationAPI = BusStationAPI()
    }

    func fetchStationList(type: CityType) throws -> [BusStation] {
        return try stationAPI.fetchStationList(stationType: type)
    }

    func fetchStationStatus(stationID: String, cityName: String) throws -> BusStateJson {
        let stationType: CityType = cityName == "NWT" ? CityType.newTaipei : CityType.taipei
        return try stationAPI.fetchStationStatus(stationType: stationType, stationID: stationID)
    }
}
