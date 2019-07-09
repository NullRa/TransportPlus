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
    @IBOutlet weak var toggleSearchBarBtn: UIButton!
    @IBOutlet weak var toggleBtnConstraintTop: NSLayoutConstraint!
    @IBOutlet weak var labelConstraintTop: NSLayoutConstraint!
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        cleanUbData()
        print(NSHomeDirectory())
        getUbikeData()
        queryFromCoreData()
        checkPermission()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard CLLocationManager.locationServicesEnabled() else {
            showAlertMessage(title: "載入地圖失敗", message: "載入地圖失敗", actionTitle: "OK")
            return
        }
        mainMapView.delegate = self
        searchBar.delegate = self
        MapManager.shared.manager.delegate = self
        uploadDefaultView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        let name = "Map Page"
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: name)
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject: AnyObject])
    }

    func showAlertMessage(title: String, message: String, actionTitle: String) {
        let alertCon = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertActA = UIAlertAction(title: actionTitle, style: .default, handler: nil)
        alertCon.addAction(alertActA)
        self.present(alertCon, animated: true, completion: nil)
    }

    //控制載入的範圍&畫面
    func uploadDefaultView() {
        //Get current location
        if MapManager.shared.manager.location == nil {
            errorAlert(title: "抓不到位置", message: "請檢查定位服務是否啟用", actionTitle: "OK")

            return
        }
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let regin = MKCoordinateRegion(center: MapManager.shared.manager.location!.coordinate, span: span)
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
                showAlertMessage(title: ErrorCode.coreDataError.alertTitle, message: ErrorCode.coreDataError.alertMessage, actionTitle: "OK")
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
            showAlertMessage(title: ErrorCode.coreDataError.alertTitle, message: ErrorCode.coreDataError.alertMessage, actionTitle: "OK")
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
            showAlertMessage(title: ErrorCode.jsonDecodeError.alertTitle, message: ErrorCode.jsonDecodeError.alertMessage, actionTitle: "OK")
            // swiftlint:enable line_length
            ubikeDatas = []
        }
    }
    // MARK: permission check
    func checkPermission() {
        if CLLocationManager.authorizationStatus() == .denied {
            let alertController = UIAlertController(
                title: "定位權限已關閉",
                message: "如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟",
                preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確認", style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        if CLLocationManager.authorizationStatus() == .notDetermined {
            MapManager.shared.manager.requestAlwaysAuthorization()
        }
        MapManager.shared.manager.startUpdatingLocation()
    }

    @IBAction func autoSwitchBtnPressed(_ sender: Any) {
        showBikeStation()
    }

    @objc func closeKeyboard() {
        searchBar.text = ""
        self.view.endEditing(true)
    }

    @IBAction func locationBtnPressed(_ sender: Any) {
        mainMapView.userTrackingMode = .follow
    }
    @IBAction func toggleSearchBarPressed(_ sender: Any) {
        if searchBar.isHidden {
            toggleBtnConstraintTop.priority = UILayoutPriority(rawValue: 100)
            labelConstraintTop.priority = UILayoutPriority(rawValue: 100)
            DispatchQueue.main.async {
                self.searchBar.isHidden = false
                self.toggleSearchBarBtn.titleLabel?.text = "收起"
            }
        } else {
            toggleBtnConstraintTop.priority = UILayoutPriority(rawValue: 900)
            labelConstraintTop.priority = UILayoutPriority(rawValue: 900)
            DispatchQueue.main.async {
                self.searchBar.isHidden = true
                self.toggleSearchBarBtn.titleLabel?.text = "展開"
            }
        }
    }
}

extension BikeAndBusViewController: MKMapViewDelegate {

    //點擊圖標的動作
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let ubkieDefault = UbikeJson()
        guard let annotation = view.annotation as? MKPointAnnotation,
            let station = annotationMap.get(key: annotation) else {
            showAlertMessage(title: "載入圖標失敗", message: "載入圖標失敗", actionTitle: "OK")
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
            showAlertMessage(title: ErrorCode.jsonDecodeError.alertTitle, message: ErrorCode.jsonDecodeError.alertMessage, actionTitle: "OK")
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
                self.showAlertMessage(title: currentError.alertTitle,
                                      message: currentError.alertMessage, actionTitle: "OK")
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

extension BikeAndBusViewController: CLLocationManagerDelegate {
    //授權完做動作
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.uploadDefaultView()
    }
}
