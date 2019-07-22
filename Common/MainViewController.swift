import CoreLocation
import MapKit
import UIKit
import CoreData

class MainViewController: UIViewController, BikeAndBusDelegate, UISearchBarDelegate {

    private var viewModel: MainMapViewModel!
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var autoUpdateButton: UISwitch!
    @IBOutlet weak var toggleSearchBarBtn: UIButton!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var navigationBar: UINavigationBar!

    @IBOutlet weak var toggleBtnConstraintTop: NSLayoutConstraint!
    @IBOutlet weak var labelConstraintTop: NSLayoutConstraint!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        checkPermission()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
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
        mainMapView.userTrackingMode = .follow
        mainMapView.userTrackingMode = .none
        mainMapView.delegate = self
        searchBar.delegate = self

        viewModel = MainMapViewModel(viewController: self, center: MapManager.shared.manager.location!.coordinate)

        // FIXME
        searchBar.inputAccessoryView = addTextViewInputAccessoryView()

        viewModel.onViewLoad()
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

    // MARK: permission check
    func checkPermission() {
        if CLLocationManager.authorizationStatus() == .denied {
            showAlertMessage(title: "定位權限已關閉",
                             message: "如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟",
                             actionTitle: "確認")
            return
        }
        if CLLocationManager.authorizationStatus() == .notDetermined {
            MapManager.shared.manager.requestAlwaysAuthorization()
        }
        MapManager.shared.manager.startUpdatingLocation()
    }

    @IBAction func onRefreshButtonPressed(_ sender: Any) {
        self.refreshButton.isEnabled = false
        self.loadingView.startAnimating()

        DispatchQueue.global().async {
            self.viewModel.updateUbikeData()
            DispatchQueue.main.async {
                self.viewModel.updateStations()
                self.loadingView.stopAnimating()
                self.refreshButton.isEnabled = true
            }
        }
    }

    @IBAction func onLocationButtonPressed(_ sender: Any) {
        mainMapView.userTrackingMode = .follow
        mainMapView.userTrackingMode = .none
    }

    @IBAction func onAutoSwitchButtonPressed(_ sender: UISwitch) {
        self.viewModel.toggleAutoUpdate()
    }

    @IBAction func onToggleSearchBarButtonPressed(_ sender: Any) {
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
        let annotation = view.annotation as? MKPointAnnotation
        annotation!.subtitle = viewModel.showStationStatus(annotation: annotation)
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
