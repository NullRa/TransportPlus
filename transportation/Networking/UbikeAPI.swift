import Foundation

class UbikeAPI: BaseAPI {

    func fetchStationList(cityCode: CityCode) throws ->  [UbikeStationStruct] {
        let apiURL = getStationListRequstURL(cityCode: cityCode)
        let data: Data = try self.fetchJsonData(apiURL: apiURL)
        let decoder = JSONDecoder()
        let dataList = try decoder.decode([UbikeStationStruct].self, from: data)

        return dataList
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
}
