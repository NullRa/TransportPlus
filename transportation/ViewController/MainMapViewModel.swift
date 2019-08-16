import Foundation
import MapKit
import CoreData

class MainMapViewModel {
    var viewController: BikeAndBusDelegate
    var annotationMap = AnnotationMap()
    var center: CLLocationCoordinate2D?
    var isAutoUpdate = true
    var isSearchBarCollapsed = true
    var mapType = MapType.ubike

    init(viewController: BikeAndBusDelegate) {
        self.viewController = viewController
    }

    func onViewLoad() {
        let annotations = getRegionStations()
        viewController.updateAnnotations(annotations: annotations)
        viewController.setNavigationBarTitle(mapType: mapType)
        viewController.setAutoUpdatedButton(enable: isAutoUpdate)
        viewController.setMapTypeSegmentButton(type: mapType)
        viewController.setSearchBarCollapsed(collapsed: isSearchBarCollapsed)
    }

    func setCenter(center: CLLocationCoordinate2D) {
        self.center = center
        viewController.moveMapCenter(center: self.center!)
    }

    func toggleAutoUpdate() {
        isAutoUpdate = !isAutoUpdate
        viewController.setAutoUpdatedButton(enable: isAutoUpdate)
        updateStations()
    }

    func segmentUpdate() {
        if mapType == .ubike {
            mapType = .bus
        } else {
            mapType = .ubike
        }
        viewController.setNavigationBarTitle(mapType: mapType)
        viewController.setMapTypeSegmentButton(type: mapType)
        let annotations = getRegionStations()
        viewController.updateAnnotations(annotations: annotations)
    }

    func updateStations() {
        if isAutoUpdate {
            viewController.updateAnnotations(annotations: getRegionStations())
        }
    }

    func updateBusData() {
        let busDefault = BusAPI()
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<BusStation>(entityName: "BusStation")
        do {
            let results = try moc.fetch(request)
            for result in results {
                moc.delete(result)
            }
            try busDefault.fetchStationList(cityCode: .taipei)
            try busDefault.fetchStationList(cityCode: .newTaipei)
            CoreDataHelper.shared.saveContext()
        } catch {
            viewController.showAlertMessage(title: ErrorCode.jsonDecodeError.alertTitle,
                                            message: ErrorCode.jsonDecodeError.alertMessage,
                                            actionTitle: "OK")
        }
    }

    func updateUbikeData() {
        let ubikeDefault = UbikeAPI()
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<UbikeStation>(entityName: "UbikeStation")
        do {
            let results = try moc.fetch(request)
            for result in results {
                moc.delete(result)
            }
            try ubikeDefault.fetchStationList(cityCode: .taipei)
            try ubikeDefault.fetchStationList(cityCode: .newTaipei)
            CoreDataHelper.shared.saveContext()
        } catch {
            viewController.showAlertMessage(title: ErrorCode.jsonDecodeError.alertTitle,
                                            message: ErrorCode.jsonDecodeError.alertMessage,
                                            actionTitle: "OK")
        }
    }

    func getRegionStations() -> [MKPointAnnotation] {
        annotationMap.reset()
        let model = CoreDataHelper.shared.persistentContainer.managedObjectModel
        let center = self.viewController.getCenterCoordinate()
        let region = self.viewController.getRegion()
        let maxLat = center.latitude + region.span.latitudeDelta / 2
        let minLat = center.latitude - region.span.latitudeDelta / 2
        let maxLng = center.longitude + region.span.longitudeDelta / 2
        let minLng = center.longitude - region.span.longitudeDelta / 2

        if mapType == .ubike,
            let fetchRequest = model.fetchRequestFromTemplate(
                withName: "Fetch_ubike_by_region",
                substitutionVariables: ["maxLng": maxLng, "minLng": minLng,
                                        "maxLat": maxLat, "minLat": minLat]) {
            return loadUbikeData(request: fetchRequest)
        }
        if let fetchRequest =
            model.fetchRequestFromTemplate(
                withName: "Fetch_bus_by_region",
                substitutionVariables: ["maxLng": maxLng, "minLng": minLng,
                                        "maxLat": maxLat, "minLat": minLat]) {
            return loadBusData(request: fetchRequest)
        }
        return []
    }

    func loadUbikeData(request: NSFetchRequest<NSFetchRequestResult>) -> [MKPointAnnotation] {
        var annotations: [MKPointAnnotation] = []
        let moc = CoreDataHelper.shared.managedObjectContext()
        moc.performAndWait {
            do {
                let regionStations = try moc.fetch(request) as? [UbikeStation]
                for station in regionStations! {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate.latitude = station.latitude
                    annotation.coordinate.longitude = station.longitude
                    annotation.title = station.name
                    annotationMap.set(key: annotation, station: station)
                    annotations.append(annotation)
                }
            } catch {
                self.viewController.showAlertMessage(title: ErrorCode.coreDataError.alertTitle,
                                                     message: ErrorCode.coreDataError.alertMessage,
                                                     actionTitle: "OK")
            }
        }
        return annotations
    }

    func loadBusData(request: NSFetchRequest<NSFetchRequestResult>) -> [MKPointAnnotation] {
        var annotations: [MKPointAnnotation] = []
        let moc = CoreDataHelper.shared.managedObjectContext()
        moc.performAndWait {
            do {
                let regionStations = try moc.fetch(request) as? [BusStation]
                for station in regionStations! {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate.latitude = station.latitude
                    annotation.coordinate.longitude = station.longitude
                    annotation.title = station.name
                    annotationMap.set(key: annotation, station: station)
                    annotations.append(annotation)
                }
            } catch {
                self.viewController.showAlertMessage(title: ErrorCode.coreDataError.alertTitle,
                                                     message: ErrorCode.coreDataError.alertMessage,
                                                     actionTitle: "OK")
            }
        }
        return annotations
    }

    func toggleSearchBarCollapsed() {
        isSearchBarCollapsed = !isSearchBarCollapsed
        viewController.setSearchBarCollapsed(collapsed: isSearchBarCollapsed)
    }

    func searchLocation(text: String) {
        MapManager.shared.searchAction(searchText: text) { (center, error) in
            self.viewController.clearSearchBarText()
            if let currentError = error as? ErrorCode {
                self.viewController.showAlertMessage(title: currentError.alertTitle,
                                      message: currentError.alertMessage, actionTitle: "OK")
                return
            }

            if center != nil {
                self.viewController.moveMapCenter(center: center!)
                self.viewController.closeKeyboard()
            }
        }
    }

    func showStationStatus(annotation: MKPointAnnotation?) -> String {
        let ubkieDefault = UbikeAPI()
        var subTitle = "確認網路狀態"

        guard annotation != nil, let station = annotationMap.get(key: annotation!) as? UbikeStation else {
               viewController.showAlertMessage(title: "載入圖標失敗", message: "載入圖標失敗", actionTitle: "OK")
                return subTitle
        }

        do {
            let ubState = try ubkieDefault.fetchStationStatus(cityName: station.cityName, stationID: station.number)
            if ubState.ServieAvailable == 0 {
                subTitle = "未營運"
            } else {
                subTitle = "可借\(ubState.AvailableRentBikes)台,可還\(ubState.AvailableReturnBikes)台"
            }
        } catch {
            self.viewController.showAlertMessage(title:
                ErrorCode.jsonDecodeError.alertTitle, message:
                ErrorCode.jsonDecodeError.alertMessage, actionTitle: "OK")
        }
        return subTitle
    }
}

protocol BikeAndBusDelegate: class {
    func setNavigationBarTitle(mapType: MapType)
    func setAutoUpdatedButton(enable: Bool)
    func setSearchBarCollapsed(collapsed: Bool)
    func showAlertMessage(title: String, message: String, actionTitle: String)
    func moveMapCenter(center: CLLocationCoordinate2D)
    func closeKeyboard()
    func clearSearchBarText()
    func getRegion() -> MKCoordinateRegion
    func getCenterCoordinate() -> CLLocationCoordinate2D
    func updateAnnotations(annotations: [MKPointAnnotation])
    func setMapTypeSegmentButton(type: MapType)
}