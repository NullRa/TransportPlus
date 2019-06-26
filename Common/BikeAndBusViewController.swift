//BUS&UBIKE viewController
import CoreLocation
import MapKit
import UIKit
import CoreData

class BikeAndBusViewController: UIViewController {
    var ubikeDatas : [UbikeData] = []
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var autoSwitchBtn: UISwitch!
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        cleanUbData()
//        print(NSHomeDirectory())
//        getUbikeData()
        queryFromCoreData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        guard CLLocationManager.locationServicesEnabled() else{
            return
        }
        uploadDefaultView()
        MapManager.shared.managerSetting()
        mainMapView.delegate = self
    }
    //控制載入的範圍&畫面
    func uploadDefaultView(){
        //Get current location
        guard let location = MapManager.shared.manager.location else{
            assertionFailure("Location is not ready")
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
    func addTextViewInputAccessoryView(){
        let textToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        textToolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),UIBarButtonItem(title: "return", style: .done, target: self, action: #selector(closeKeyboard))]
        searchBar.inputAccessoryView = textToolbar
    }
    func showBikeStation(){
        if autoSwitchBtn.isOn{
            mainMapView.removeAnnotations(mainMapView.annotations)
            let maxLat = mainMapView.centerCoordinate.latitude + mainMapView.region.span.latitudeDelta/2
            let minLat = mainMapView.centerCoordinate.latitude - mainMapView.region.span.latitudeDelta/2
            let maxLng = mainMapView.centerCoordinate.longitude + mainMapView.region.span.longitudeDelta/2
            let minLng = mainMapView.centerCoordinate.longitude - mainMapView.region.span.longitudeDelta/2
            for i in 0 ..< ubikeDatas.count{
                if(ubikeDatas[i].lng > minLng && ubikeDatas[i].lng < maxLng && ubikeDatas[i].lat > minLat && ubikeDatas[i].lat < maxLat ){
                    let annotation = StationAnnotation()
                    annotation.coordinate.latitude = ubikeDatas[i].lat
                    annotation.coordinate.longitude = ubikeDatas[i].lng
                    annotation.title = ubikeDatas[i].sna
                    annotation.stationID = ubikeDatas[i].sno
                    annotation.cityName = ubikeDatas[i].cityName
                    mainMapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    //MARK:CoreData
    //save
    func saveToCoreData(){
        CoreDataHelper.shared.saveContext()
    }
    //load
    func queryFromCoreData(){
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<UbikeData>(entityName: "UbikeData")
        moc.performAndWait {
            do{
                ubikeDatas = try moc.fetch(request)
            }catch{
                print("error:\(error)")
                ubikeDatas = []
            }
        }
    }
    //clean Data
    func cleanUbData(){
        let moc = CoreDataHelper.shared.managedObjectContext()
        let request = NSFetchRequest<UbikeData>(entityName: "UbikeData")
        do {
            let results = try moc.fetch(request as! NSFetchRequest<NSFetchRequestResult>) as! [UbikeData]
            for result in results {
                moc.delete(result)
            }
            saveToCoreData()
        }catch{
            fatalError("Failed to fetch data: \(error)")
        }
    }
    
    //build ubikeData
    func getUbikeData(){
        guard let stations1 = UbikeJson.shared.getNewTaipeiUbikeData(),let stations2 = UbikeJson.shared.getTaipeiUbikeData() else{
            assertionFailure("can not get stations")
            return
        }
        let stations = stations1 + stations2
        CoreDataHelper.shared.saveUbikes(stations: stations)
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


extension BikeAndBusViewController : MKMapViewDelegate{
    //點擊圖標的動作,思考新增判斷網路
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? StationAnnotation,
            let result = UbikeJson.shared.getUbikeStationState(cityName: annotation.cityName, stationID: annotation.stationID) else {
                assertionFailure("urlError")
                return
        }
        annotation.subtitle = result["act"]  == "0" ? "未營運" : "可借\(result["sbi"]!)台,可還\(result["bemp"]!)台"
    }
    // 移動結束才會執行
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("就決定是你了")//移動玩過兩秒
        showBikeStation()
    }
}

