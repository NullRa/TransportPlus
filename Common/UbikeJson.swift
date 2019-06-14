import Foundation
class UbikeJson{
    static func getData(){
        print("getData!!!!!!!!!!!!!!!!!!")
        guard let url = URL(string: "http://data.ntpc.gov.tw/api/v1/rest/datastore/382000000A-000352-001") else{
            assertionFailure("urlError")
            return
        }
        
        guard let ubData = try? Data(contentsOf: url) else{
            assertionFailure("ubDataError")
            return
        }
        
        let data = try? JSONSerialization.jsonObject(with: ubData, options: []) as? Dictionary<String,Any>
        
        if let result = data?["result"] as? Dictionary<String,Any>,let recordsResults = result["records"] as? [Dictionary<String,Any>]{
            for i in 0..<recordsResults.count{
                let firstData = recordsResults[i]
                let firstSno = firstData["sno"]
                let firstSna = firstData["sna"]
                print("站點編號:\(firstSno!),站點名稱:\(firstSna!)")
                let firstLng = firstData["lng"]
                let firstLat = firstData["lat"]
                print("精度:\(firstLng!),緯度:\(firstLat!)")
            }
        }
    }
}
