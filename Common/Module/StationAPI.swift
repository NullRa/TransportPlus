import Foundation

class StationAPI {
    
    func fetchStationList(stationType:StationType) throws -> [Station] {
        let apiURL = getStationListRequstURL(stationType: stationType)
        let data:Data = try self.fetchJsonData(apiURL: apiURL);
        var stations: [Station] = []
        
        let decoder = JSONDecoder()
        
        if let dataList = try? decoder.decode([StationJsonStruct].self, from: data) {
            for ubikeStation in dataList {
                let moc = CoreDataHelper.shared.managedObjectContext()
                let station = Station(context: moc)
                station.cityName = ubikeStation.AuthorityID
                station.no = ubikeStation.StationUID
                station.name = ubikeStation.StationName.Zh_tw
                station.longitude = ubikeStation.StationPosition.PositionLon
                station.latitude = ubikeStation.StationPosition.PositionLat
                stations.append(station)
            }
        }
        return stations
    }
    
    func fetchStationStatus(stationType: StationType, stationID: String) throws -> UbikeStateJson{
        
        let apiURL = self.getStationStatusRequestURL(stationType: stationType, stationID: stationID)
        
        let data = try self.fetchJsonData(apiURL: apiURL)
        let decoder = JSONDecoder()
        let dataList = try decoder.decode([UbikeStateJson].self, from: data)
        if (dataList.count == 0) {
            throw ErrorCode.DataError
        }
        
        return dataList[0]
    }
    
    private func getCityCode(stationType: StationType) -> String {
        if (stationType == .Taipei) {
            return "Taipei"
        }
        else {
            return "NewTaipei"
        }
    }
    
    private func getStationStatusRequestURL(stationType: StationType, stationID: String) -> String  {
        let city = self.getCityCode(stationType: stationType)
        
        return "https://ptx.transportdata.tw/MOTC/v2/Bike/Availability/\(city)?$filter=StationUID%20eq%20'\(stationID)'&$top=30&$format=JSON"
    }
    
    private func getStationListRequstURL(stationType: StationType ) -> String {
        let city = self.getCityCode(stationType: stationType)
        
        return "https://ptx.transportdata.tw/MOTC/v2/Bike/Station/\(city)?$format=JSON"
    }
    
    
    private func getServerTime() -> String {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "EEE, dd MMM yyyy HH:mm:ww zzz"
        dateFormater.locale = Locale(identifier: "en_US")
        dateFormater.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormater.string(from: Date())
    }

    private func fetchJsonData(apiURL: String) throws -> Data  {
        let APP_ID = "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"
        let APP_KEY = "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"
        let xdate:String = getServerTime();
        let signDate = "x-date: " + xdate;
        let base64HmacStr = signDate.hmac(algorithm: .SHA1, key: APP_KEY)
        let authorization:String = "hmac username=\""+APP_ID+"\", algorithm=\"hmac-sha1\", headers=\"x-date\", signature=\""+base64HmacStr+"\""
        let url = URL(string: apiURL)
        
        var request = URLRequest(url: url!)
        request.setValue(xdate, forHTTPHeaderField: "x-date")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        let sema = DispatchSemaphore( value: 0)
        var currentData: Data = Data()
        let completionHandler = {(data:  Data?, response: URLResponse?, error: Error?) -> Void in
            currentData = data!
            sema.signal()
        }
        URLSession.shared.dataTask(with: request, completionHandler: completionHandler).resume()
        sema.wait();
        return currentData
    }
}
