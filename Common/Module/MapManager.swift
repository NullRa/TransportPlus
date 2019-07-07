import Foundation
import CoreLocation

class MapManager{
    static let shared = MapManager()
    let manager = CLLocationManager()
    
    func managerSetting(){
        manager.requestAlwaysAuthorization()
        manager.allowsBackgroundLocationUpdates = true
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .automotiveNavigation
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
            if let tmpPlacemarks = placemarks,let location = tmpPlacemarks[0].location{
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
                if let tmpPlacemarks = placemarks,let subAdministrativeArea = tmpPlacemarks[0].subAdministrativeArea, let locality = tmpPlacemarks[0].locality,let name = tmpPlacemarks[0].name{
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

