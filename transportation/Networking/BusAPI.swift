import Foundation

class BusAPI: BaseAPI {

    func fetchStationList(cityCode: CityCode) throws {
        let apiURL = getStationListRequstURL(cityCode: cityCode)
        let data: Data = try self.fetchJsonData(apiURL: apiURL)
        let decoder = JSONDecoder()
        let dataList = try decoder.decode([BusStationStruct].self, from: data)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.busRepository?.saveBusStation(dataList: dataList)
        }

    }

    private func getStationListRequstURL(cityCode: CityCode ) -> String {
        let city = self.getCityCode(cityCode: cityCode)

        return "https://ptx.transportdata.tw/MOTC/v2/Bus/Station/City/\(city)?$format=JSON"
    }
}
