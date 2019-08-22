import Foundation

// swiftlint:disable all
struct BusStationStruct: Codable {
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
        var RouteUID: String
        var RouteName: RouteName
        struct RouteName: Codable {
            var Zh_tw: String
        }
    }
}
// swiftlint:enable all
