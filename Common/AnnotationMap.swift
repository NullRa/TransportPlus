import Foundation
import MapKit
class AnnotationMap {
    var dict = [MKPointAnnotation: UbikeStation]()

    func set(key: MKPointAnnotation, station: UbikeStation) {
        dict[key] = station
    }

    func get(key: MKPointAnnotation) -> UbikeStation? {
        return dict[key]
    }

    func reset() {
        dict.removeAll()
    }
}
