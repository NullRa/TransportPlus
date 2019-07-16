import Foundation
import CoreData
class BusStationRepository {
    var busDtatas: [BusStation] = []
    func queryFromCoreData(datas: [BusStation]) throws -> [BusStation] {
        busDtatas = datas
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<BusStation>(entityName: "BusStation")
        moc.performAndWait {
            do {
                busDtatas = try moc.fetch(request)
            } catch {
                busDtatas = []
            }
        }
        return busDtatas
    }

    func saveToCoreData() {
        CoreDataHelper.shared.saveContext()
    }

    func cleanData() throws {
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<BusStation>(entityName: "BusStation")
        let results = try moc.fetch(request)
        for result in results {
            moc.delete(result)
        }
        saveToCoreData()
    }

    func getData() throws {
        let busDefault = BusJson()
        let TPEStation = try busDefault.fetchStationList(type: .taipei)
        let NWTStation = try busDefault.fetchStationList(type: .newTaipei)
        CoreDataHelper.shared.saveBus(stations: (TPEStation + NWTStation))
    }

}
