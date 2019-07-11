import CoreLocation
import MapKit
import UIKit
import CoreData

class BikeAndBusViewController: UIViewController {
    var ubikeDatas: [Station] = []
    var annotationMap = AnnotationMap()
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var autoSwitchBtn: UISwitch!
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        cleanUbData()
        print(NSHomeDirectory())
        getUbikeData()
        queryFromCoreData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard CLLocationManager.locationServicesEnabled() else {
            errorAlert(title: "載入地圖失敗", message: "載入地圖失敗", actionTitle: "OK")
            return
        }
        uploadDefaultView()
        MapManager.shared.managerSetting()
        mainMapView.delegate = self
        searchBar.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        let name = "Map Page"
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: name)
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject: AnyObject])
    }

    func errorAlert(title: String, message: String, actionTitle: String) {
        let alertCon = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertActA = UIAlertAction(title: actionTitle, style: .default, handler: nil)
        alertCon.addAction(alertActA)
        self.present(alertCon, animated: true, completion: nil)
    }

    //控制載入的範圍&畫面
    func uploadDefaultView() {
        //Get current location
        guard let location = MapManager.shared.manager.location else {
            assertionFailure("Location is not ready")
            errorAlert(title: "載入位置失敗", message: "確認定位功能已啟用", actionTitle: "OK")
            return
        }
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let regin = MKCoordinateRegion(center: location.coordinate, span: span)
        mainMapView.setRegion(regin, animated: true)
        autoSwitchBtn.setOn(true, animated: false)
        showBikeStation()
        addTextViewInputAccessoryView()
        mainMapView.userTrackingMode = .follow
        searchBar.placeholder = "Search"
    }

    //收起textView鍵盤的方法
    func addTextViewInputAccessoryView() {
        let textToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        // swiftlint:disable line_length
        textToolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                             UIBarButtonItem(title: "return", style: .done, target: self, action: #selector(closeKeyboard))]
        // swiftlint:enable line_length
        searchBar.inputAccessoryView = textToolbar
    }

    func showBikeStation() {
        if autoSwitchBtn.isOn {
            annotationMap.reset()
            mainMapView.removeAnnotations(mainMapView.annotations)
            let maxLat = mainMapView.centerCoordinate.latitude + mainMapView.region.span.latitudeDelta/2
            let minLat = mainMapView.centerCoordinate.latitude - mainMapView.region.span.latitudeDelta/2
            let maxLng = mainMapView.centerCoordinate.longitude + mainMapView.region.span.longitudeDelta/2
            let minLng = mainMapView.centerCoordinate.longitude - mainMapView.region.span.longitudeDelta/2
            for index in 0 ..< ubikeDatas.count {
                if ubikeDatas[index].longitude > minLng && ubikeDatas[index].longitude < maxLng
                    && ubikeDatas[index].latitude > minLat && ubikeDatas[index].latitude < maxLat {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate.latitude = ubikeDatas[index].latitude
                    annotation.coordinate.longitude = ubikeDatas[index].longitude
                    annotation.title = ubikeDatas[index].name
                    annotationMap.set(key: annotation, station: ubikeDatas[index])
                    mainMapView.addAnnotation(annotation)
                }
            }
        }
    }

    // MARK: CoreData
    //save
    func saveToCoreData() {
        CoreDataHelper.shared.saveContext()
    }
    //load
    func queryFromCoreData() {
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<Station>(entityName: "Station")
        moc.performAndWait {
            do {
                ubikeDatas = try moc.fetch(request)
            } catch {
                // swiftlint:disable line_length
                errorAlert(title: ErrorCode.coreDataError.alertTitle, message: ErrorCode.coreDataError.alertMessage, actionTitle: "OK")
                // swiftlint:enable line_length
                ubikeDatas = []
            }
        }
    }

    //clean Data
    func cleanUbData() {
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<Station>(entityName: "Station")
        do {
            let results = try moc.fetch(request)
            for result in results {
                moc.delete(result)
            }
            saveToCoreData()
        } catch {
            // swiftlint:disable line_length
            errorAlert(title: ErrorCode.coreDataError.alertTitle, message: ErrorCode.coreDataError.alertMessage, actionTitle: "OK")
            // swiftlint:enable line_length
            ubikeDatas = []
        }
    }

    //build ubikeData
    func getUbikeData() {
        let ubikeDefault = UbikeJson()

        do {
            let TPEStation = try ubikeDefault.fetchStationList(type: .taipei)
            let NWTStation = try ubikeDefault.fetchStationList(type: .newTaipei)
            CoreDataHelper.shared.saveUbikes(stations: (TPEStation + NWTStation))
        } catch {
            // swiftlint:disable line_length
            errorAlert(title: ErrorCode.jsonDecodeError.alertTitle, message: ErrorCode.jsonDecodeError.alertMessage, actionTitle: "OK")
            // swiftlint:enable line_length
            ubikeDatas = []
        }
    }

    @IBAction func autoSwitchBtnPressed(_ sender: Any) {
        showBikeStation()
    }

    @objc func closeKeyboard() {
        searchBar.text = ""
        self.view.endEditing(true)
    }

    @IBAction func locationBtnPressed(_ sender: Any) {
        mainMapView.userTrackingMode = .followWithHeading
    }
}

extension BikeAndBusViewController: MKMapViewDelegate {

    //點擊圖標的動作
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let ubkieDefault = UbikeJson()
        guard let annotation = view.annotation as? MKPointAnnotation,
            let station = annotationMap.get(key: annotation) else {
            errorAlert(title: "載入圖標失敗", message: "載入圖標失敗", actionTitle: "OK")
            return
        }
        do {
            let ubState = try ubkieDefault.fetchStationStatus(stationID: station.number, cityName: station.cityName)
            if ubState.ServieAvailable == 0 {
                annotation.subtitle = "未營運"
            } else {
                annotation.subtitle = "可借\(ubState.AvailableRentBikes)台,可還\(ubState.AvailableReturnBikes)台"
            }
        } catch {
            // swiftlint:disable line_length
            errorAlert(title: ErrorCode.jsonDecodeError.alertTitle, message: ErrorCode.jsonDecodeError.alertMessage, actionTitle: "OK")
            // swiftlint:enable line_length
            ubikeDatas = []
        }
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let annotation = view.annotation as? MKPointAnnotation else {
            return
        }
        annotation.subtitle = ""
    }

    // 移動結束才會執行
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        showBikeStation()
    }
}

// MASK:UISearchBar
extension BikeAndBusViewController: UISearchBarDelegate {
    //點擊鍵盤的search btn
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        MapManager.shared.searchAction(searchText: searchBar.text!) { (center, error) in
            if let currentError = error as? ErrorCode {
                self.errorAlert(title: currentError.alertTitle, message: currentError.alertMessage, actionTitle: "OK")
                return
            }
            if center != nil {
                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                let region = MKCoordinateRegion(center: center!, span: span)
                self.mainMapView.setRegion(region, animated: true)
                self.view.endEditing(true)
                searchBar.text = ""
            }
        }
    }
}
