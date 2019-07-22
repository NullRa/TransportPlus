import Foundation
import MapKit
import CoreData

class MainMapViewModel {
    var viewController: BikeAndBusDelegate
    var ubikeDatas: [Station] = []
    var annotationMap = AnnotationMap()
    var center: CLLocationCoordinate2D
    var isAutoUpdate = true
    var isSearchBarCollapsed = true

    init(viewController: BikeAndBusDelegate, center: CLLocationCoordinate2D) {
        self.viewController = viewController
        self.center = center
    }

    func onViewLoad() {
        self.loadUbikeData()
        let annotations = getRegionStations()
        viewController.updateAnnotations(annotations: annotations)
        viewController.moveMapCenter(center: center)
        viewController.setNavigationBarTitle(title: "Ubike Station")
        viewController.setAutoUpdatedButton(enable: isAutoUpdate)
        viewController.setSearchBarCollapsed(collapsed: isSearchBarCollapsed)
    }

    func toggleAutoUpdate() {
        isAutoUpdate = !isAutoUpdate
        viewController.setAutoUpdatedButton(enable: isAutoUpdate)
        updateStations()
    }

    func updateStations() {
        if isAutoUpdate {
            viewController.updateAnnotations(annotations: getRegionStations())
        }
    }

    func updateUbikeData() {
        updateUbikeCoreData()
        loadUbikeData()
    }

    func updateUbikeCoreData() {
        let ubikeDefault = UbikeJson()
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<Station>(entityName: "Station")
        do {
            let results = try moc.fetch(request)
            for result in results {
                moc.delete(result)
            }
            let TPEStation = try ubikeDefault.fetchStationList(type: .taipei)
            let NWTStation = try ubikeDefault.fetchStationList(type: .newTaipei)
            CoreDataHelper.shared.saveUbikes(stations: (TPEStation + NWTStation))
        } catch {
            viewController.showAlertMessage(title: ErrorCode.jsonDecodeError.alertTitle,
                                            message: ErrorCode.jsonDecodeError.alertMessage,
                                            actionTitle: "OK")
        }
    }

    func loadUbikeData() {
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<Station>(entityName: "Station")
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

        for index in 0 ..< ubikeDatas.count {
            if ubikeDatas[index].longitude > minLng && ubikeDatas[index].longitude < maxLng
                && ubikeDatas[index].latitude > minLat && ubikeDatas[index].latitude < maxLat {
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = ubikeDatas[index].latitude
                annotation.coordinate.longitude = ubikeDatas[index].longitude
                annotation.title = ubikeDatas[index].name
                annotationMap.set(key: annotation, station: ubikeDatas[index])
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
        let ubkieDefault = UbikeJson()
        var subTitle = "確認網路狀態"

        guard annotation != nil, let station = annotationMap.get(key: annotation!) else {
               viewController.showAlertMessage(title: "載入圖標失敗", message: "載入圖標失敗", actionTitle: "OK")
                return subTitle
        }

        do {
            let ubState = try ubkieDefault.fetchStationStatus(stationID: station.number, cityName: station.cityName)
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
    func setNavigationBarTitle(title: String)
    func setAutoUpdatedButton(enable: Bool)
    func setSearchBarCollapsed(collapsed: Bool)
    func showAlertMessage(title: String, message: String, actionTitle: String)
    func moveMapCenter(center: CLLocationCoordinate2D)
    func closeKeyboard()
    func clearSearchBarText()
    func getRegion() -> MKCoordinateRegion
    func getCenterCoordinate() -> CLLocationCoordinate2D
    func updateAnnotations(annotations: [MKPointAnnotation])
}