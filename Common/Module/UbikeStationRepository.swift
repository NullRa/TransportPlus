import Foundation
import CoreData
class UbikeStationRepository {
    var ubikeDatas: [UbikeStation] = []
    func queryFromCoreData(datas: [UbikeStation]) throws -> [UbikeStation] {
        ubikeDatas = datas
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<UbikeStation>(entityName: "UbikeStation")
        moc.performAndWait {
            do {
                ubikeDatas = try moc.fetch(request)
            } catch {
                ubikeDatas = []
            }
        }
        return ubikeDatas
    }

    func cleanData() throws {
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<UbikeStation>(entityName: "UbikeStation")
        let results = try moc.fetch(request)
        for result in results {
            moc.delete(result)
        }
        saveToCoreData()
    }

    func saveToCoreData() {
        CoreDataHelper.shared.saveContext()
    }

    func getData() throws {
        let ubikeDefault = UbikeJson()
        let TPEStation = try ubikeDefault.fetchStationList(type: .taipei)
        let NWTStation = try ubikeDefault.fetchStationList(type: .newTaipei)
        CoreDataHelper.shared.saveUbikes(stations: (TPEStation + NWTStation))
    }
}
