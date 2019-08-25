import Foundation

class BusAPI: BaseAPI {

    func fetchStationList(cityCode: CityCode) throws -> [BusStationStruct] {
        let apiURL = getStationListRequstURL(cityCode: cityCode)
        let data: Data = try self.fetchJsonData(apiURL: apiURL)
        let decoder = JSONDecoder()
        return try decoder.decode([BusStationStruct].self, from: data)
    }

    private func getStationListRequstURL(cityCode: CityCode ) -> String {
        let city = self.getCityCode(cityCode: cityCode)

        return "https://ptx.transportdata.tw/MOTC/v2/Bus/Station/City/\(city)?$format=JSON"
    }
}
