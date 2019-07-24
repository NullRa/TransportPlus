import Foundation

class UbikeAPI {

    func fetchStationList(cityCode: CityCode) throws {
        let apiURL = getStationListRequstURL(cityCode: cityCode)
        let data: Data = try self.fetchJsonData(apiURL: apiURL)
        let decoder = JSONDecoder()
        let dataList = try decoder.decode([UbikeStationStruct].self, from: data)
        for ubikeStation in dataList {
            let moc = CoreDataHelper.shared.managedObjectContext()
            let station = UbikeStation(context: moc)
            station.cityName = ubikeStation.AuthorityID
            station.number = ubikeStation.StationUID
            station.name = ubikeStation.StationName.Zh_tw
            station.longitude = ubikeStation.StationPosition.PositionLon
            station.latitude = ubikeStation.StationPosition.PositionLat
        }
    }

    func fetchStationStatus(cityName: String, stationID: String) throws -> UbikeStatusStruct {
        let cityCode: CityCode = cityName == "NWT" ? CityCode.newTaipei : CityCode.taipei
        let apiURL = self.getStationStatusRequestURL(cityCode: cityCode, stationID: stationID)
        let data = try self.fetchJsonData(apiURL: apiURL)
        let decoder = JSONDecoder()
        let dataList = try decoder.decode([UbikeStatusStruct].self, from: data)

        if dataList.count == 0 {
            throw ErrorCode.dataError
        }

        return dataList[0]
    }

    private func getCityCode(cityCode: CityCode) -> String {
        if cityCode == .taipei {
            return "Taipei"
        } else {
            return "NewTaipei"
        }
    }

    private func getStationStatusRequestURL(cityCode: CityCode, stationID: String) -> String {
        let city = self.getCityCode(cityCode: cityCode)
        // swiftlint:disable line_length
        return "https://ptx.transportdata.tw/MOTC/v2/Bike/Availability/\(city)?$filter=StationUID%20eq%20'\(stationID)'&$top=30&$format=JSON"
        // swiftlint:enable line_length
    }

    private func getStationListRequstURL(cityCode: CityCode ) -> String {
        let city = self.getCityCode(cityCode: cityCode)

        return "https://ptx.transportdata.tw/MOTC/v2/Bike/Station/\(city)?$format=JSON"
    }

    private func getServerTime() -> String {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "EEE, dd MMM yyyy HH:mm:ww zzz"
        dateFormater.locale = Locale(identifier: "en_US")
        dateFormater.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormater.string(from: Date())
    }

    private func fetchJsonData(apiURL: String) throws -> Data {
        // swiftlint:disable all
        let src = Bundle.main.path(forResource: "SecretKey", ofType: "plist")
        guard let plist = NSMutableDictionary(contentsOfFile: src!),
            let APP_ID = plist["ptxAPPID"] as? String,
            let APP_KEY = plist["ptxAPPKey"] as? String else {
                throw ErrorCode.dataError
        }
        // swiftlint:enable all
        let xdate: String = getServerTime()
        let signDate = "x-date: " + xdate
        let base64HmacStr = signDate.hmac(algorithm: .SHA1, key: APP_KEY)
        // swiftlint:disable line_length
        let authorization: String = "hmac username=\""+APP_ID+"\", algorithm=\"hmac-sha1\", headers=\"x-date\", signature=\""+base64HmacStr+"\""
        // swiftlint:enable line_length
        let url = URL(string: apiURL)
        var request = URLRequest(url: url!)
        request.setValue(xdate, forHTTPHeaderField: "x-date")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        let sema = DispatchSemaphore( value: 0)

        var currentData: Data = Data()
        let completionHandler = {(data: Data?, response: URLResponse?, error: Error?) -> Void in
            currentData = data!
            sema.signal()
        }
        URLSession.shared.dataTask(with: request, completionHandler: completionHandler).resume()
        sema.wait()

        return currentData
    }
}