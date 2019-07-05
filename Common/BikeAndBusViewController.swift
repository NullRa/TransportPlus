//BUS&UBIKE viewController
import CoreLocation
import MapKit
import UIKit
import CoreData

class BikeAndBusViewController: UIViewController {
    var ubikeDatas: [Station] = []
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
    }

    //收起textView鍵盤的方法
    func addTextViewInputAccessoryView() {
        let textToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        textToolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(title: "return", style: .done, target: self, action: #selector(closeKeyboard))]
        searchBar.inputAccessoryView = textToolbar
    }

    func showBikeStation() {
        if autoSwitchBtn.isOn {
            mainMapView.removeAnnotations(mainMapView.annotations)
            let maxLat = mainMapView.centerCoordinate.latitude + mainMapView.region.span.latitudeDelta/2
            let minLat = mainMapView.centerCoordinate.latitude - mainMapView.region.span.latitudeDelta/2
            let maxLng = mainMapView.centerCoordinate.longitude + mainMapView.region.span.longitudeDelta/2
            let minLng = mainMapView.centerCoordinate.longitude - mainMapView.region.span.longitudeDelta/2
            for i in 0 ..< ubikeDatas.count {
                if(ubikeDatas[i].longitude > minLng && ubikeDatas[i].longitude < maxLng && ubikeDatas[i].latitude > minLat && ubikeDatas[i].latitude < maxLat ) {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate.latitude = ubikeDatas[i].latitude
                    annotation.coordinate.longitude = ubikeDatas[i].longitude
                    annotation.title = ubikeDatas[i].name
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
            } catch is ErrorCode {
                errorAlert(title: ErrorCode.CoreDataError.alertTitle, message: ErrorCode.CoreDataError.alertMessage, actionTitle: "OK")
                ubikeDatas = []
            } catch {

            }
        }
    }

    //clean Data
    func cleanUbData() {
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<Station>(entityName: "Station")
        do {
            let results = try moc.fetch(request as! NSFetchRequest<NSFetchRequestResult>) as! [Station]
            for result in results {
                moc.delete(result)
            }
            saveToCoreData()
        } catch is ErrorCode {
            errorAlert(title: ErrorCode.CoreDataError.alertTitle, message: ErrorCode.CoreDataError.alertMessage, actionTitle: "OK")
            ubikeDatas = []
        } catch {

        }
    }

    //build ubikeData
    func getUbikeData() {
        let tmp = UbikeJson()

        do {
            let TPEStation = try tmp.fetchStationList(type: .Taipei)
            let NWTStation = try tmp.fetchStationList(type: .NewTaipei)
            CoreDataHelper.shared.saveUbikes(stations: (TPEStation + NWTStation))
        } catch is ErrorCode {
            errorAlert(title: ErrorCode.JsonDecodeError.alertTitle, message: ErrorCode.JsonDecodeError.alertMessage, actionTitle: "OK")
            ubikeDatas = []
        } catch {

        }
    }

    @IBAction func autoSwitchBtnPressed(_ sender: Any) {
        showBikeStation()
    }

    @objc func closeKeyboard() {
        self.view.endEditing(true)
    }

    @IBAction func locationBtnPressed(_ sender: Any) {
        mainMapView.userTrackingMode = .followWithHeading
    }
}

extension BikeAndBusViewController: MKMapViewDelegate {

    //點擊圖標的動作,思考新增判斷網路
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let tmp = UbikeJson()
        var cityName = ""
        var stationID = ""
        guard let annotation = view.annotation as? MKPointAnnotation else {
            errorAlert(title: "載入圖標失敗", message: "載入圖標失敗", actionTitle: "OK")
            return
        }
        for i in 0..<ubikeDatas.count {
            if ubikeDatas[i].longitude == annotation.coordinate.longitude && ubikeDatas[i].latitude == annotation.coordinate.latitude {
                cityName = ubikeDatas[i].cityName
                stationID = ubikeDatas[i].no
                break
            }
        }
        do {
            let ubState = try tmp.fetchStationStatus(stationID: stationID, cityName: cityName)
            annotation.subtitle = ubState.ServieAvailable == 0 ? "未營運" : "可借\(ubState.AvailableRentBikes)台,可還\(ubState.AvailableReturnBikes)台"
        } catch is ErrorCode {
            errorAlert(title: ErrorCode.JsonDecodeError.alertTitle, message: ErrorCode.JsonDecodeError.alertMessage, actionTitle: "OK")
            ubikeDatas = []
        } catch {
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
