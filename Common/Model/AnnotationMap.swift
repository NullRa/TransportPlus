import Foundation
import MapKit
class AnnotationMap {
    var dict = [MKPointAnnotation: Any]()

    func set(key: MKPointAnnotation, station: Any) {
        dict[key] = station
    }

    func get(key: MKPointAnnotation) -> Any? {
        return dict[key]
    }

    func reset() {
        dict.removeAll()
    }
}
