import Foundation
import MapKit
import CoreData

class MainMapViewModel {
    var viewController: BikeAndBusDelegate
    var ubikeDatas: [UbikeStation] = []
    var busDatas: [BusStation] = []
    var annotationMap = AnnotationMap()
    var center: CLLocationCoordinate2D?
    var isAutoUpdate = true
    var isSearchBarCollapsed = true
    var mapType = MapType.ubike

    init(viewController: BikeAndBusDelegate) {
        self.viewController = viewController
    }

    func onViewLoad() {
        self.loadUbikeData()
        self.loadBusData()
        let annotations = getRegionStations()
        viewController.updateAnnotations(annotations: annotations)
        viewController.setNavigationBarTitle(mapType: mapType)
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
        updateBusCoreData()
        loadBusData()
    }

    func updateUbikeData() {
        updateUbikeCoreData()
        loadUbikeData()
    }

    func updateBusCoreData() {
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

    func loadBusData() {
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<BusStation>(entityName: "BusStation")
        moc.performAndWait {
            do {
                self.busDatas = try moc.fetch(request)
            } catch {
                self.viewController.showAlertMessage(title: ErrorCode.coreDataError.alertTitle,
                                                     message: ErrorCode.coreDataError.alertMessage,
                                                     actionTitle: "OK")
            }
        }
    }

    func updateUbikeCoreData() {
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

    func loadUbikeData() {
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<UbikeStation>(entityName: "UbikeStation")
        moc.performAndWait {
            do {
                 self.ubikeDatas = try moc.fetch(request)
            } catch {
                self.viewController.showAlertMessage(title: ErrorCode.coreDataError.alertTitle,
                                                     message: ErrorCode.coreDataError.alertMessage,
                                                     actionTitle: "OK")
            }
        }
    }

    func getRegionStations() -> [MKPointAnnotation] {
        annotationMap.reset()
        let center = self.viewController.getCenterCoordinate()
        let region = self.viewController.getRegion()
        let maxLat = center.latitude + region.span.latitudeDelta / 2
        let minLat = center.latitude - region.span.latitudeDelta / 2
        let maxLng = center.longitude + region.span.longitudeDelta / 2
        let minLng = center.longitude - region.span.longitudeDelta / 2
        var annotations: [MKPointAnnotation] = []
        //if mapType == .ubike early return. else do loading bus annotation for-roop
        if mapType == .ubike {
            for station in ubikeDatas {
                if station.longitude > minLng && station.longitude < maxLng
                    && station.latitude > minLat && station.latitude < maxLat {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate.latitude = station.latitude
                    annotation.coordinate.longitude = station.longitude
                    annotation.title = station.name
                    annotationMap.set(key: annotation, station: station)
                    annotations.append(annotation)
                }
            }
            return annotations
        }

        for station in busDatas {
            if station.longitude > minLng && station.longitude < maxLng
                && station.latitude > minLat && station.latitude < maxLat {
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = station.latitude
                annotation.coordinate.longitude = station.longitude
                annotation.title = station.name
                annotationMap.set(key: annotation, station: station)
                annotations.append(annotation)
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
