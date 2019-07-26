import CoreLocation
import MapKit
import UIKit
import CoreData
import Network

class MainViewController: UIViewController, BikeAndBusDelegate, UISearchBarDelegate {
    let monitor = NWPathMonitor()
    private var viewModel: MainMapViewModel!
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var autoUpdateButton: UISwitch!
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
        viewModel = MainMapViewModel(viewController: self)
        viewModel.onViewLoad()
        mainMapView.delegate = self
        searchBar.delegate = self
        MapManager.shared.manager.delegate = self
        // FIXME
        searchBar.inputAccessoryView = addTextViewInputAccessoryView()
        autoUpdateButton.addTarget(self, action: #selector(onAutoSwitchButtonPressed(_:)),
                                   for: .valueChanged)
        toggleSearchBarButton.addTarget(self, action: #selector(onToggleSearchBarButtonPressed(_:)),
                                        for: .touchUpInside)
        refreshButton.addTarget(self, action: #selector(onRefreshButtonPressed(_:)), for: .touchUpInside)
        locationButton.addTarget(self, action: #selector(onLocationButtonPressed(_:)), for: .touchUpInside)
    }

    //收起textView鍵盤的方法
    func addTextViewInputAccessoryView() -> UIToolbar {
        let textToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        textToolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                             target: nil, action: nil),
                             UIBarButtonItem(title: "return", style: .done,
                                             target: self, action: #selector(closeKeyboard))]

        return textToolbar
    }

    @objc func onRefreshButtonPressed(_ sender: UIBarButtonItem) {
        self.refreshButton.isEnabled = false
        self.loadingView.startAnimating()

        DispatchQueue.global().async {
            self.viewModel.updateUbikeData()
            DispatchQueue.main.async {
                self.updateAnnotations(annotations: self.viewModel.getRegionStations())
                self.loadingView.stopAnimating()
                self.refreshButton.isEnabled = true
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

    @objc func onToggleSearchBarButtonPressed(_ sender: UIButton) {
        viewModel.toggleSearchBarCollapsed()
    }

    // MARK: searchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.viewModel.searchLocation(text: searchBar.text!)
    }

    // MARK: BikeAndBusDelegate
    func setNavigationBarTitle(title: String) {
        navigationBar.topItem?.title = title
    }

    func setAutoUpdatedButton(enable: Bool) {
        autoUpdateButton.isOn = enable
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

    func setLocationButton(enable: Bool) {
        locationButton.isEnabled = enable
        viewModel.isLocation = enable
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

extension MainViewController: MKMapViewDelegate {

    //點擊圖標的動作
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
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

    // 移動結束才會執行
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.viewModel.updateStations()
    }
}

extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            MapManager.shared.manager.requestAlwaysAuthorization()
        case .denied:
            showAlertMessage(title: "定位權限已關閉",
                             message: "如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟",
                             actionTitle: "確認")
            setLocationButton(enable: false)
        default:
            MapManager.shared.manager.startUpdatingLocation()
            viewModel.setCenter(center: MapManager.shared.manager.location!.coordinate)
            mainMapView.userTrackingMode = .follow
            mainMapView.userTrackingMode = .none
            setLocationButton(enable: true)
        }
    }
}
