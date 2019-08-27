import Foundation

// swiftlint:disable identifier_name
struct UbikeStationCodable: Codable {
    var StationUID: String
    var AuthorityID: String
    var StationName: StationName
    var StationPosition: StationPosition
    struct StationName: Codable {
        var Zh_tw: String
    }
    struct StationPosition: Codable {
        var PositionLat: Double
        var PositionLon: Double
    }
}
// swiftlint:enable identifier_name
