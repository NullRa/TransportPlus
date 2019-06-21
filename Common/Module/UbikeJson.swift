import Foundation

class UbikeJson{
    static func getNewTaipeiUbikeData2() -> [UbikeStation]? {
        var stations: [UbikeStation] = []
        guard let url = URL(string: "https://data.ntpc.gov.tw/api/v1/rest/datastore/382000000A-000352-001") else{
            assertionFailure("123")
            return nil
        }
        let request = URLRequest(url: url)
        let semaphore = DispatchSemaphore(value: 0)
        let dataTask = URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            let decoder = JSONDecoder()
            if let data = data, let dataList = try? decoder.decode(NewTaipeiBikeJson.self, from: data) {
                for stationData in dataList.result.records {
                    let station = UbikeStation()
                    station.longitude = Double(stationData.lng.trimmingCharacters(in: .whitespaces))
                    station.latitude = Double(stationData.lat.trimmingCharacters(in: .whitespaces))
                    station.name = stationData.sna
                    station.no = stationData.sno
                    stations.append(station)
                }
            } else {
                print("Error...")
            }
            CoreDataHelper.shared.saveUbikes(stations: stations)
            
            semaphore.signal()
        }) as URLSessionTask
        dataTask.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return stations
    }
    //    static func getTaipeiUbikeData() -> [UbikeStation]? {
    //        guard let url = URL(string: "https://tcgbusfs.blob.core.windows.net/blobyoubike/YouBikeTP.gz") else{
    //            assertionFailure("urlError")
    //            return nil
    //        }
    //        guard let ubData = try? Data(contentsOf: url) else{
    //            assertionFailure("ubDataError")
    //            return nil
    //        }
    //        let data = try? JSONSerialization.jsonObject(with: ubData, options: []) as? Dictionary<String,Any>
    //
    //        var stations: [UbikeStation] = []
    //
    //                let stationData = recordsResults[i]
    //        if let retVal = data?["retVal"] as? Dictionary<String,Any>{//0001...0404
    //            for i in 1 ... 404{//這邊hen奇怪
    //                let str = i < 10 ? "000\(i)" : ( i<100 ? "00\(i)" : "0\(i)" )
    //                if let stationData = retVal[str] as? Dictionary<String,String>{
    //                    guard
    //                        let stationLng = stationData["lng"],
    //                        let stationLat = stationData["lat"],
    //                        let currentLng = Double(stationLng.trimmingCharacters(in: .whitespaces)),
    //                        let currentLat = Double(stationLat.trimmingCharacters(in: .whitespaces)),
    //                        let stationSna = stationData["sna"],
    //                        let stationSno = stationData["sno"] else{
    //                            assertionFailure("ubData save error!")
    //                            return
    //                    }
    //                    let moc = CoreDataHelper.shared.managedObjectContext()
    //                    let ubData = UbikeData(context: moc)
    //                    ubData.sna = stationSna
    //                    ubData.sno = stationSno
    //                    ubData.lng = currentLng
    //                    ubData.lat = currentLat
    //                    saveToCoreData()
    //                }
    //            }
    //        }
    //    }
}
