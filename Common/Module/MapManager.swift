import Foundation
import CoreLocation

class MapManager{
    static let shared = MapManager()
    let manager = CLLocationManager()
    
    func managerSetting(){
        //instance
        manager.requestAlwaysAuthorization()
        //啟用背景功能
        manager.allowsBackgroundLocationUpdates = true
        //精確度設定
        manager.desiredAccuracy = kCLLocationAccuracyBest
        //活動種類
        manager.activityType = .automotiveNavigation
        //回報位置
        manager.startUpdatingLocation()
    }
    
    func searchAction(searchText:String,completion: @escaping (CLLocationCoordinate2D?,Error?)->()) {
        let geoCoder = CLGeocoder()
        var lon : Double = 0
        var lat : Double = 0
        var center : CLLocationCoordinate2D?
        var funcError : Error? = nil
        
        geoCoder.geocodeAddressString(searchText, completionHandler: {
            (placemarks:[CLPlacemark]?,error:Error?) in
            if let _ = error {
                funcError = ErrorCode.AddressError
            }
            if let addressPlacemarks = placemarks,let location = addressPlacemarks[0].location{
                //placemark.location.coordinate 取得經緯度的參數
                lon = location.coordinate.longitude
                lat = location.coordinate.latitude
                if(lat < 22 || lat > 27 || lon < 118 || lon > 122 && lat != 0 && lon != 0){
                    funcError = ErrorCode.AddressRangeError
                }
            }
            geoCoder.reverseGeocodeLocation(CLLocation(latitude: lat , longitude: lon), completionHandler: {
                (placemarks:[CLPlacemark]?,error:Error?) in
                UserDefaults.standard.set(["zh_TW"], forKey: "AppleLanguages")
                if let _ = error, !(funcError is ErrorCode) {
                    funcError = ErrorCode.AddressError
                }
                if let currentPlacemarks = placemarks,let subAdministrativeArea = currentPlacemarks[0].subAdministrativeArea, let locality = currentPlacemarks[0].locality,let name = currentPlacemarks[0].name{
                    //這邊拼湊轉回來的地址
                    let resultAddress = subAdministrativeArea + locality + name
                    if resultAddress.contains(searchText){
                        //搜尋的字都在回傳的結果之中,限制搜尋經緯度範圍
                        center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                }
                completion(center,funcError)
            })
        })
    }
}

