import Foundation

class BusAPI: BaseAPI {

    func fetchStationList(cityCode: CityCode) throws {
        let apiURL = getStationListRequstURL(cityCode: cityCode)
        let data: Data = try self.fetchJsonData(apiURL: apiURL)
        let decoder = JSONDecoder()
        let dataList = try decoder.decode([BusStationJson].self, from: data)
        for busStation in dataList {
            let moc = CoreDataHelper.shared.managedObjectContext()
            let station = BusStation(context: moc)
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
    }

    private func getStationListRequstURL(cityCode: CityCode ) -> String {
        let city = self.getCityCode(cityCode: cityCode)

        return "https://ptx.transportdata.tw/MOTC/v2/Bus/Station/City/\(city)?$format=JSON"
    }
}
