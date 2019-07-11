import Foundation
import MapKit
class AnnotationMap {
    var dict = [MKPointAnnotation: Station]()

    func set(key: MKPointAnnotation, station: Station) {
        dict[key] = station
    }

    func get(key: MKPointAnnotation) -> Station? {
        return dict[key]
    }

    func reset() {
        dict.removeAll()
    }
}
