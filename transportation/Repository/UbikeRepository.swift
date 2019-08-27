import Foundation
import CoreData

class UbikeRepository: BaseRepository {
    func saveUbikeStation(dataList: [UbikeStationCodable]) {
        let context = getContext()
        for ubikeStation in dataList {
            let station = UbikeStation(context: context)
            station.cityName = ubikeStation.AuthorityID
            station.number = ubikeStation.StationUID
            station.name = ubikeStation.StationName.Zh_tw
            station.longitude = ubikeStation.StationPosition.PositionLon
            station.latitude = ubikeStation.StationPosition.PositionLat
        }
        saveContext()
    }

    func deleteAllUbikeData() throws {
        let context = getContext()
        let request = NSFetchRequest<UbikeStation>(entityName: "UbikeStation")
        let results = try context.fetch(request)
        for result in results {
            context.delete(result)
        }
    }

    func loadUbikeData(request: NSFetchRequest<NSFetchRequestResult>) throws -> [UbikeStation]? {
        let context = getContext()

        return try context.fetch(request) as? [UbikeStation]
    }
}
