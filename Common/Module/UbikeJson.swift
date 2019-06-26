import Foundation
import CoreLocation
class UbikeJson{
    static let shared = UbikeJson()
    func getNewTaipeiUbikeData() -> [UbikeStation]? {
        guard let url = URL(string: "http://data.ntpc.gov.tw/api/v1/rest/datastore/382000000A-000352-001") else{
            assertionFailure("urlError")
            return nil
        }
        guard let ubData = try? Data(contentsOf: url) else{
            assertionFailure("ubDataError")
            return nil
        }
        let data = try? JSONSerialization.jsonObject(with: ubData, options: []) as? Dictionary<String,Any>
        var stations: [UbikeStation] = []
        guard let result = data?["result"] as? Dictionary<String,Any>,let recordsResults = result["records"] as? [Dictionary<String,String>] else{
            return nil
        }
        for i in 0..<recordsResults.count{
            let stationData = recordsResults[i]
            guard
                let stationLng = stationData["lng"],
                let stationLat = stationData["lat"],
                let currentLng = Double(stationLng.trimmingCharacters(in: .whitespaces)),
                let currentLat = Double(stationLat.trimmingCharacters(in: .whitespaces)),
                let stationSna = stationData["sna"],
                let stationSno = stationData["sno"] else{
                    assertionFailure("ubData save error!")
                    return nil
            }
            let station = UbikeStation();
            station.cityName = "新北市"
            station.no = stationSno;
            station.name = stationSna;
            station.latitude = currentLat;
            station.longitude = currentLng;
            stations.append(station)
        }
        return stations;
    }
    
    func getTaipeiUbikeData() -> [UbikeStation]? {
        guard let url = URL(string: "https://tcgbusfs.blob.core.windows.net/blobyoubike/YouBikeTP.gz") else{
            assertionFailure("urlError")
            return nil
        }
        guard let ubData = try? Data(contentsOf: url) else{
            assertionFailure("ubDataError")
            return nil
        }
        let data = try? JSONSerialization.jsonObject(with: ubData, options: []) as? Dictionary<String,Any>
        var stations: [UbikeStation] = []
        guard let retVal = data?["retVal"] as? Dictionary<String,Any> else{
            assertionFailure("can not get stations")
            return nil
        }
        for i in retVal {
            guard let retValNo = i.1 as? Dictionary<String,Any> else{
                assertionFailure("can not get stations")
                return nil
            }
            let station = UbikeStation();
            station.cityName = "台北市"
            for j in retValNo{
                let stationData = j.1 as! String
                if j.0 == "lng", let lng = Double(stationData.trimmingCharacters(in: .whitespaces)){
                    station.longitude = lng
                }
                if j.0 == "lat", let lat = Double(stationData.trimmingCharacters(in: .whitespaces)){
                    station.latitude =  lat
                }
                if j.0 == "sna"{
                    station.name = stationData
                }
                if j.0 == "sno"{
                    station.no = stationData
                }
            }
            stations.append(station)
        }
        return stations
    }
    
    func getNewTaipeiUbikeStationState(stationID:String) -> Dictionary<String,String>?{
        let requestUrl =  "http://data.ntpc.gov.tw/od/data/api/54DDDC93-589C-4858-9C95-18B2046CC1FC?$format=json&$filter=sno%20eq%20\(stationID)"
        guard let url = URL(string: requestUrl) else {
            assertionFailure("urlError")
            return nil
        }
        var tmpData : Data?
        do{
            tmpData = try Data(contentsOf: url)
        }catch{
            assertionFailure("can't get data")
        }
        guard let ubData = tmpData else{
            assertionFailure("tmpData == nil")
            return nil
        }
        var ubJsonData : [Dictionary<String,Any>]?
        do{
            ubJsonData = try JSONSerialization.jsonObject(with: ubData, options: []) as? [Dictionary<String,Any>]
        }catch{
            assertionFailure("can't get ubJsonData")
        }
        guard let data = ubJsonData else{
            assertionFailure("ubJsonData == nil")
            return nil
        }
        let result = data[0]
        return result as? Dictionary<String, String>
    }
    func getTaipeiUbikeStationState(stationID:String) -> Dictionary<String,String>? {
        guard let url = URL(string: "https://tcgbusfs.blob.core.windows.net/blobyoubike/YouBikeTP.gz") else{
            assertionFailure("urlError")
            return nil
        }
        guard let ubData = try? Data(contentsOf: url) else{
            assertionFailure("ubDataError")
            return nil
        }
        let data = try? JSONSerialization.jsonObject(with: ubData, options: []) as? Dictionary<String,Any>
        guard let retVal = data?["retVal"] as? Dictionary<String,Any> else{
            assertionFailure("can not get stations")
            return nil
        }
        for i in retVal {
            guard let retValNo = i.1 as? Dictionary<String,Any> else{
                assertionFailure("can not get stations")
                return nil
            }
            
            for j in retValNo{
                let stationData = j.1 as! String
                if j.0 == "sno", stationData == stationID{
                    return i.1 as? Dictionary<String, String>
                }
            }
        }
        return nil
    }
    func getUbikeStationState(cityName:String,stationID:String) -> Dictionary<String,String>? {
        switch cityName {
        case "新北市":
            return getNewTaipeiUbikeStationState(stationID: stationID)
        case "台北市":
            return getTaipeiUbikeStationState(stationID: stationID)
        default:
            assertionFailure("取不到單車資料")
        }
        return nil
    }
    
}
