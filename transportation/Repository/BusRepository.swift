import Foundation
import CoreData

class BusRespository: BaseRepository {
    func saveBusStation(dataList: [BusStationCodable]) {
        let context = getContext()
        for busStation in dataList {
            let station = BusStation(context: context)
            station.number = busStation.StationUID
            station.cityName = String(station.number.prefix(3))
            station.name = busStation.StationName.Zh_tw
            station.longitude = busStation.StationPosition.PositionLon
            station.latitude = busStation.StationPosition.PositionLat
            for value in busStation.Stops {
                let busNumber = BusNumber()
                busNumber.busID = value.StopUID
                busNumber.busName = value.RouteName.Zh_tw
                busNumber.routeUID = value.RouteUID
                station.busNumbers.append(busNumber)
            }
        }

        saveContext()
    }

    func deleteAllBusData() throws {
        let context = getContext()
        let request = NSFetchRequest<BusStation>(entityName: "BusStation")
        let results = try context.fetch(request)
        for result in results {
            context.delete(result)
        }
    }

    func loadBusData(request: NSFetchRequest<NSFetchRequestResult>) throws -> [BusStation]? {
        let context = getContext()

        return try context.fetch(request) as? [BusStation]
    }
}
