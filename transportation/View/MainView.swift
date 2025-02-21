import CoreLocation
import MapKit
import UIKit
import CoreData
import Network
import MBProgressHUD

class MainView: UIViewController, BikeAndBusDelegate, UISearchBarDelegate {

    let monitor = NWPathMonitor()
    private var viewModel: MainModel!
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var autoUpdateButton: UISwitch!
    @IBOutlet weak var mapTypeSegment: UISegmentedControl!
    @IBOutlet weak var toggleSearchBarButton: UIButton!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var toggleBtnConstraintTop: NSLayoutConstraint!
    @IBOutlet weak var labelConstraintTop: NSLayoutConstraint!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        monitor.start(queue: DispatchQueue.global())

        let name = "Map Page"
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: name)
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject: AnyObject])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard CLLocationManager.locationServicesEnabled() else {
            showAlertMessage(title: "載入地圖失敗", message: "載入地圖失敗", actionTitle: "OK")

            return
        }
        let busAPI = BusAPI()
        let ubikeAPI = UbikeAPI()
        let busRepository = (UIApplication.shared.delegate as? AppDelegate)!.getBusRepository()
        let ubikeRepository = (UIApplication.shared.delegate as? AppDelegate)!.getUbikeRepository()
        viewModel =
            MainModel(viewController: self,
                             ubikeAPI: ubikeAPI,
                             ubikeRepository: ubikeRepository,
                             busAPI: busAPI,
                             busRepository: busRepository)

        viewModel.onViewLoad()
        mainMapView.delegate = self
        searchBar.delegate = self
        MapManager.shared.manager.delegate = self
        autoUpdateButton.addTarget(self, action: #selector(onAutoSwitchButtonPressed(_:)),
                                   for: .valueChanged)
        toggleSearchBarButton.addTarget(self, action: #selector(onToggleSearchBarButtonPressed(_:)),
                                        for: .touchUpInside)
        refreshButton.addTarget(self, action: #selector(onRefreshButtonPressed(_:)), for: .touchUpInside)
        locationButton.addTarget(self, action: #selector(onLocationButtonPressed(_:)), for: .touchUpInside)
        mapTypeSegment.addTarget(self, action: #selector(onMapTypeSegmentChanged(_:)), for: .valueChanged)
        viewModel.onViewLoad()
    }

    @objc func onRefreshButtonPressed(_ sender: UIBarButtonItem) {
        let hub = MBProgressHUD.showAdded(to: self.view, animated: true)
        var stations: [Any]?
        DispatchQueue.global().async {
            do {
                stations = try self.viewModel.fetchStationArray()
            } catch {
                self.showAlertMessage(title: ErrorCode.jsonDecodeError.alertTitle,
                                     message: ErrorCode.jsonDecodeError.alertMessage,
                                     actionTitle: "OK")
            }
            DispatchQueue.main.async {
                do {
                    try self.viewModel.updateData(newStationArray: stations)
                } catch {
                    self.showAlertMessage(title: ErrorCode.coreDataError.alertTitle,
                                          message: ErrorCode.coreDataError.alertMessage,
                                          actionTitle: "OK")
                }
                self.updateAnnotations(annotations: self.viewModel.getRegionStations())
                hub.hide(animated: true)
            }
        }
    }

    @objc func onLocationButtonPressed(_ sender: UIBarButtonItem) {
        mainMapView.userTrackingMode = .follow
        mainMapView.userTrackingMode = .none
    }

    @objc func onAutoSwitchButtonPressed(_ sender: UISwitch) {
        viewModel.toggleAutoUpdate()
    }

    @objc func onMapTypeSegmentChanged(_ sender: UISegmentedControl) {
        viewModel.segmentUpdate()
    }

    @objc func onToggleSearchBarButtonPressed(_ sender: UIButton) {
        viewModel.toggleSearchBarCollapsed()
    }

    // MARK: searchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.viewModel.searchLocation(text: searchBar.text!)
    }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.endEditing(true)
    }

    // MARK: BikeAndBusDelegate
    func setNavigationBarTitle(mapType: MapType) {
        let title = mapType == .ubike ? "Ubike" : "Bus"
        navigationBar.topItem?.title = title
    }

    func setAutoUpdatedButton(enable: Bool) {
        viewModel.isAutoUpdate = enable
        autoUpdateButton.isOn = enable
    }

    func setMapTypeSegmentButton(type: MapType) {
        var index: Int {
            return type == .ubike ? 0 : 1
        }
        mapTypeSegment.selectedSegmentIndex = index
    }

    func setSearchBarCollapsed(collapsed: Bool) {
        if collapsed {
            toggleBtnConstraintTop.priority = UILayoutPriority(rawValue: 100)
            labelConstraintTop.priority = UILayoutPriority(rawValue: 100)
            DispatchQueue.main.async {
                self.searchBar.isHidden = false
                self.toggleSearchBarButton.titleLabel?.text = "收起"
            }
        } else {
            toggleBtnConstraintTop.priority = UILayoutPriority(rawValue: 900)
            labelConstraintTop.priority = UILayoutPriority(rawValue: 900)
            DispatchQueue.main.async {
                self.searchBar.isHidden = true
                self.toggleSearchBarButton.titleLabel?.text = "展開"
            }
        }
    }

    func showAlertMessage(title: String, message: String, actionTitle: String) {
        let alertCon = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertActA = UIAlertAction(title: actionTitle, style: .default, handler: nil)
        alertCon.addAction(alertActA)
        self.present(alertCon, animated: true, completion: nil)
    }

    func moveMapCenter(center: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: center, span: span)
        self.mainMapView.setRegion(region, animated: true)
    }

    @objc func closeKeyboard() {
        self.view.endEditing(true)
    }

    func clearSearchBarText() {
        searchBar.text = ""
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.endEditing(true)
    }

    func getRegion() -> MKCoordinateRegion {
        return mainMapView.region
    }

    func getCenterCoordinate() -> CLLocationCoordinate2D {
        return mainMapView.centerCoordinate
    }

    func updateAnnotations(annotations: [MKPointAnnotation]) {
        mainMapView.removeAnnotations(mainMapView.annotations)
        for annotation in annotations {
            mainMapView.addAnnotation(annotation)
        }
    }
}

extension MainView: MKMapViewDelegate {

    //點擊圖標的動作
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation?.coordinate.latitude == mainMapView.userLocation.coordinate.latitude &&
            view.annotation?.coordinate.longitude == mainMapView.userLocation.coordinate.longitude {
            return
        }
        if monitor.currentPath.status == .satisfied {
            let annotation = view.annotation as? MKPointAnnotation
            annotation!.subtitle = viewModel.showStationStatus(annotation: annotation)
            return
        }
        let annotation = view.annotation as? MKPointAnnotation
        annotation!.subtitle = "請確認網路"
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let annotation = view.annotation as? MKPointAnnotation {
            annotation.subtitle = ""
        }
    }

    //scrolling beginning do
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        viewModel.isSearchBarCollapsed = false
        setSearchBarCollapsed(collapsed: viewModel.isSearchBarCollapsed)
    }

    // 移動結束才會執行
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.viewModel.updateStations()
    }
}

extension MainView: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            MapManager.shared.manager.requestAlwaysAuthorization()
        case .denied:
            showAlertMessage(title: "定位權限已關閉",
                             message: "如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟",
                             actionTitle: "確認")
            locationButton.isEnabled = false
        default:
            MapManager.shared.manager.startUpdatingLocation()
            viewModel.setCenter(center: MapManager.shared.manager.location!.coordinate)
            mainMapView.userTrackingMode = .follow
            mainMapView.userTrackingMode = .none
            locationButton.isEnabled = true
        }
    }
}
