import Foundation
struct NewTaipeiBikeJson: Codable{
    var success: Bool
    var result: Result
    
    struct Result: Codable{
        var resource_id: String
        var limit: Int
        var total: Int
        var fields: [Fields]
        var records: [Records]
        
        struct Fields: Codable{
            var type: String
            var id: String
        }
        struct Records: Codable{
            var sno: String
            var sna: String
            var tot: String
            var sbi: String
            var sarea: String
            var mday: String
            var lat: String
            var lng: String
            var ar: String
            var sareaen: String
            var snaen: String
            var aren: String
            var bemp: String
            var act: String
        }
    }
}

//func takeNewTaipeiBikeData() -> [UbikeStation]? {
//    var stations: [UbikeStation] = []
//    guard let url = URL(string: "https://data.ntpc.gov.tw/api/v1/rest/datastore/382000000A-000352-001") else{
//        assertionFailure("123")
//        return nil
//    }
//    let task = URLSession.shared.dataTask(with: url) { (data, response , error) in
//        let decoder = JSONDecoder()
//        if let data = data, let dataList = try? decoder.decode(NewTaipeiBikeJson.self, from: data) {
//            for stationData in dataList.result.records {
//                let station = UbikeStation()
//                station.longitude = Double(stationData.lng.trimmingCharacters(in: .whitespaces))
//                station.latitude = Double(stationData.lat.trimmingCharacters(in: .whitespaces))
//                station.name = stationData.sna
//                station.no = stationData.sno
//                stations.append(station)
//            }
//        } else {
//            print("Error...")
//        }
//    }
//    task.resume()
//    return stations;
//}

