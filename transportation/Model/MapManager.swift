import Foundation
import CoreLocation

class MapManager {
    static let shared = MapManager()
    let manager = CLLocationManager()

    func searchAction(searchText: String, completion: @escaping (CLLocationCoordinate2D?, Error?) -> Void) {
        let geoCoder = CLGeocoder()
        var longitude: Double = 0
        var latitude: Double = 0
        var center: CLLocationCoordinate2D?
        var funcError: Error?

        geoCoder.geocodeAddressString(searchText, completionHandler: { (placemarks: [CLPlacemark]?, error: Error?) in

            if error != nil {
                funcError = ErrorCode.addressError
            }

            if let addressPlacemarks = placemarks, let location = addressPlacemarks[0].location {
                longitude = location.coordinate.longitude
                latitude = location.coordinate.latitude
                if latitude < 22 || latitude > 27 || longitude < 118 || longitude > 122
                    && latitude != 0 && longitude != 0 {
                    funcError = ErrorCode.addressRangeError
                }
            }
            geoCoder.reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude),
                                            completionHandler: { (placemarks: [CLPlacemark]?, error: Error?) in
                UserDefaults.standard.set(["zh_TW"], forKey: "AppleLanguages")
                if error != nil && !(funcError is ErrorCode) {
                    funcError = ErrorCode.addressError
                }
                if let currentPlacemarks = placemarks, let subAdminArea = currentPlacemarks[0].subAdministrativeArea,
                    let locality = currentPlacemarks[0].locality, let name = currentPlacemarks[0].name {
                    //這邊拼湊轉回來的地址
                    let resultAddress = subAdminArea + locality + name
                    if resultAddress.contains(searchText) {
                        //搜尋的字都在回傳的結果之中,限制搜尋經緯度範圍
                        center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    }
                }
                completion(center, funcError)
            })
        })
    }
}
