import CoreLocation
import MapKit
import UIKit

class MainViewController: UIViewController {
    var ubikeDatas: [UbikeStation] = []
    var busDatas: [BusStation] = []

    var annotationMap = AnnotationMap()
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var autoSwitchBtn: UISwitch!
    @IBOutlet weak var toggleSearchBarBtn: UIButton!
    @IBOutlet weak var toggleBtnConstraintTop: NSLayoutConstraint!
    @IBOutlet weak var labelConstraintTop: NSLayoutConstraint!
    @IBOutlet weak var stationSegment: UISegmentedControl!
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard CLLocationManager.locationServicesEnabled() else {
            showAlertMessage(title: "載入地圖失敗", message: "載入地圖失敗", actionTitle: "OK")
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

    func loadData() {
        do {
            let busEntity = BusStationRepository()
            let ubikeEntity = UbikeStationRepository()
            //            try ubikeEntity.cleanData()
            //            try ubikeEntity.getData()
            try ubikeDatas = ubikeEntity.queryFromCoreData(datas: ubikeDatas)
            //            try busEntity.cleanData()
            //            try busEntity.getData()
            try busDatas = busEntity.queryFromCoreData(datas: busDatas)
        } catch {
            showAlertMessage(title: ErrorCode.jsonDecodeError.alertTitle,
                       message: ErrorCode.jsonDecodeError.alertMessage, actionTitle: "OK")
            ubikeDatas = []
        }
    }
    @objc func showAlertMessage(title: String, message: String, actionTitle: String) {
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
            showAlertMessage(title: "載入位置失敗", message: "確認定位功能已啟用", actionTitle: "OK")
            return
        }
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let regin = MKCoordinateRegion(center: location.coordinate, span: span)
        mainMapView.setRegion(regin, animated: true)
        autoSwitchBtn.setOn(true, animated: false)
        addTextViewInputAccessoryView()
        mainMapView.userTrackingMode = .follow
        searchBar.placeholder = "Search"
        showStation(modNumber: stationSegment.selectedSegmentIndex)
    }

    //收起textView鍵盤的方法
    func addTextViewInputAccessoryView() {
        let textToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        textToolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                             UIBarButtonItem(title: "return", style: .done,
                                             target: self, action: #selector(closeKeyboard))]
        searchBar.inputAccessoryView = textToolbar
    }

    func showStation(modNumber: Int) {
        if autoSwitchBtn.isOn {
            annotationMap.reset()
            mainMapView.removeAnnotations(mainMapView.annotations)
            let maxLat = mainMapView.centerCoordinate.latitude + mainMapView.region.span.latitudeDelta/2
            let minLat = mainMapView.centerCoordinate.latitude - mainMapView.region.span.latitudeDelta/2
            let maxLng = mainMapView.centerCoordinate.longitude + mainMapView.region.span.longitudeDelta/2
            let minLng = mainMapView.centerCoordinate.longitude - mainMapView.region.span.longitudeDelta/2
            if modNumber == 0 {
                for value in ubikeDatas {
                    if value.longitude > minLng && value.longitude < maxLng
                        && value.latitude > minLat && value.latitude < maxLat {
                        let annotation = MKPointAnnotation()
                        annotation.coordinate.latitude = value.latitude
                        annotation.coordinate.longitude = value.longitude
                        annotation.title = value.name
                        annotationMap.set(key: annotation, station: value)
                        mainMapView.addAnnotation(annotation)
                    }
                }
                return
            }
            for value in busDatas {
                if value.longitude > minLng && value.longitude < maxLng
                    && value.latitude > minLat && value.latitude < maxLat {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate.latitude = value.latitude
                    annotation.coordinate.longitude = value.longitude
                    annotation.title = value.name
                    annotationMap.set(key: annotation, station: value)
                    mainMapView.addAnnotation(annotation)
                }
            }
        }
    }

    // MARK: permission check
    func checkPermission() {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            MapManager.shared.manager.requestWhenInUseAuthorization()
            MapManager.shared.manager.startUpdatingLocation()
            return
        }
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
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            MapManager.shared.manager.startUpdatingLocation()
        }
    }

    @IBAction func autoSwitchBtnPressed(_ sender: Any) {
        showStation(modNumber: stationSegment.selectedSegmentIndex)
    }

    @objc func closeKeyboard() {
        searchBar.text = ""
        self.view.endEditing(true)
    }

    @IBAction func locationBtnPressed(_ sender: Any) {
        mainMapView.userTrackingMode = .followWithHeading
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
    @IBAction func stationSegmentAction(_ sender: Any) {
        loadData()
        showStation(modNumber: stationSegment.selectedSegmentIndex)
    }
}

extension MainViewController: MKMapViewDelegate {

    //點擊圖標的動作
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if stationSegment.selectedSegmentIndex == 0 {
            let stationDetail = UbikeJson()
            guard let annotation = view.annotation as? MKPointAnnotation,
                let station = annotationMap.get(key: annotation) as? UbikeStation else {
                    showAlertMessage(title: "載入圖標失敗", message: "載入圖標失敗", actionTitle: "OK")
                    return
            }
            do {
                let ubState = try stationDetail.fetchStationStatus(stationID: station.number,
                                                                   cityName: station.cityName)
                if ubState.ServieAvailable == 0 {
                    annotation.subtitle = "未營運"
                } else {
                    annotation.subtitle = "可借\(ubState.AvailableRentBikes)台,可還\(ubState.AvailableReturnBikes)台"
                }
            } catch {
                showAlertMessage(title: ErrorCode.jsonDecodeError.alertTitle,
                           message: ErrorCode.jsonDecodeError.alertMessage, actionTitle: "OK")
                ubikeDatas = []
            }
        } else {
            guard let annotation = view.annotation as? MKPointAnnotation,
                let station = annotationMap.get(key: annotation) as? BusStation else {
                    showAlertMessage(title: "載入圖標失敗", message: "載入圖標失敗", actionTitle: "OK")
                    return
            }

            if let busNumberVC =
                storyboard?.instantiateViewController(withIdentifier: "busNumberViewID") as? BusNumberViewController,
                let busIndex = busDatas.firstIndex(of: station) {
                busNumberVC.busStation = busDatas[busIndex]
                self.present(busNumberVC, animated: true, completion: nil)
            }
            view.isSelected = false
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
        showStation(modNumber: stationSegment.selectedSegmentIndex)
    }
}

// MASK:UISearchBar
extension MainViewController: UISearchBarDelegate {
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
