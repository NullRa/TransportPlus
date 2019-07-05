import Foundation
import CoreLocation
class MapManager {
    static let shared = MapManager()
    let manager = CLLocationManager()

    func managerSetting() {
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
}
