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
        var longitude : Double = 0
        var latitude : Double = 0
        var center : CLLocationCoordinate2D?
        var funcError : Error? = nil
        
        geoCoder.geocodeAddressString(searchText, completionHandler: {
            (placemarks:[CLPlacemark]?,error:Error?) in
            if let _ = error {
                funcError = ErrorCode.AddressError
            }
            if let tmpPlacemarks = placemarks,let location = tmpPlacemarks[0].location{
                //placemark.location.coordinate 取得經緯度的參數
                longitude = location.coordinate.longitude
                latitude = location.coordinate.latitude
                if(latitude < 22 || latitude > 27 || longitude < 118 || longitude > 122 && latitude != 0 && longitude != 0){
                    funcError = ErrorCode.AddressRangeError
                }
            }
            geoCoder.reverseGeocodeLocation(CLLocation(latitude: latitude , longitude: longitude), completionHandler: {
                (placemarks:[CLPlacemark]?,error:Error?) in
                UserDefaults.standard.set(["zh_TW"], forKey: "AppleLanguages")
                if let _ = error, !(funcError is ErrorCode) {
                    funcError = ErrorCode.AddressError
                }
                if let tmpPlacemarks = placemarks,let subAdministrativeArea = tmpPlacemarks[0].subAdministrativeArea, let locality = tmpPlacemarks[0].locality,let name = tmpPlacemarks[0].name{
                    //這邊拼湊轉回來的地址
                    let resultAddress = subAdministrativeArea + locality + name
                    if resultAddress.contains(searchText){
                        //搜尋的字都在回傳的結果之中,限制搜尋經緯度範圍
                        center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    }
                }
                completion(center,funcError)
            })
        })
    }
}

