//BUS&UBIKE viewController
import CoreLocation
import MapKit
import UIKit
import CoreData

//客製化的用法
class StationAnnotation : MKPointAnnotation{
    var stationID = ""
}

class BikeAndBusViewController: UIViewController {
    var ubikeDatas : [UbikeData] = []
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var autoSwitchBtn: UISwitch!
    //    let controller: UIViewController;
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //        cleanUbData()
        //        getUbikeData()
        queryFromCoreData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        guard CLLocationManager.locationServicesEnabled() else{
            return
        }
        setDefaultView()
        MapManager.shared.managerSetting()
        mainMapView.delegate = self
        
    }
    //控制載入的範圍&畫面
    func setDefaultView(){
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Location", style: .done, target: self, action: #selector(locationPressed(_:)))
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
                print(ubikeDatas[i].sna)
                if(ubikeDatas[i].lng > minLng && ubikeDatas[i].lng < maxLng && ubikeDatas[i].lat > minLat && ubikeDatas[i].lat < maxLat ){
                    let annotation = StationAnnotation()
                    
                    annotation.coordinate.latitude = ubikeDatas[i].lat
                    annotation.coordinate.longitude = ubikeDatas[i].lng
                    annotation.title = ubikeDatas[i].sna
                    annotation.stationID = ubikeDatas[i].sno
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
        getNewTaipeiUbikeData()
        getTaipeiUbikeData()
    }
    
    func getNewTaipeiUbikeData(){
        guard let url = URL(string: "http://data.ntpc.gov.tw/api/v1/rest/datastore/382000000A-000352-001") else{
            assertionFailure("urlError")
            return
        }
        guard let ubData = try? Data(contentsOf: url) else{
            assertionFailure("ubDataError")
            return
        }
        let data = try? JSONSerialization.jsonObject(with: ubData, options: []) as? Dictionary<String,Any>
        
        if let result = data?["result"] as? Dictionary<String,Any>,let recordsResults = result["records"] as? [Dictionary<String,String>]{
            for i in 0..<recordsResults.count{
                let stationData = recordsResults[i]
                guard
                    let stationLng = stationData["lng"],
                    let stationLat = stationData["lat"],
                    let currentLng = Double(stationLng.trimmingCharacters(in: .whitespaces)),
                    let currentLat = Double(stationLat.trimmingCharacters(in: .whitespaces)),
                    let stationSna = stationData["sna"],
                    let stationSno = stationData["sno"] else{
                        assertionFailure("ubData save error!")
                        return
                }
                let moc = CoreDataHelper.shared.managedObjectContext()
                let ubData = UbikeData(context: moc)
                ubData.sna = stationSna
                ubData.sno = stationSno
                ubData.lng = currentLng
                ubData.lat = currentLat
                saveToCoreData()
            }
        }
    }
    func getTaipeiUbikeData(){
        guard let url = URL(string: "https://tcgbusfs.blob.core.windows.net/blobyoubike/YouBikeTP.gz") else{
            assertionFailure("urlError")
            return
        }
        guard let ubData = try? Data(contentsOf: url) else{
            assertionFailure("ubDataError")
            return
        }
        let data = try? JSONSerialization.jsonObject(with: ubData, options: []) as? Dictionary<String,Any>
        
        if let retVal = data?["retVal"] as? Dictionary<String,Any>{//0001...0404
            for i in 1 ... 404{
                let str = i < 10 ? "000\(i)" : ( i<100 ? "00\(i)" : "0\(i)" )
                if let stationData = retVal[str] as? Dictionary<String,String>{
                    guard
                        let stationLng = stationData["lng"],
                        let stationLat = stationData["lat"],
                        let currentLng = Double(stationLng.trimmingCharacters(in: .whitespaces)),
                        let currentLat = Double(stationLat.trimmingCharacters(in: .whitespaces)),
                        let stationSna = stationData["sna"],
                        let stationSno = stationData["sno"] else{
                            assertionFailure("ubData save error!")
                            return
                    }
                    let moc = CoreDataHelper.shared.managedObjectContext()
                    let ubData = UbikeData(context: moc)
                    ubData.sna = stationSna
                    ubData.sno = stationSno
                    ubData.lng = currentLng
                    ubData.lat = currentLat
                    saveToCoreData()
                }
            }
        }
    }
    
    @IBAction func autoSwitchBtnPressed(_ sender: Any) {
        showBikeStation()
    }
    @objc func locationPressed(_ sender: Any){
        mainMapView.userTrackingMode = .followWithHeading
    }
    @objc func closeKeyboard() {
        self.view.endEditing(true)
    }
    
    //判斷所在城市
    //for iOS 11.0
    func geocode(latitude: Double, longitude: Double, completion: @escaping (CLPlacemark?, Error?) -> ())  {
        //1
        let locale = Locale(identifier: "zh_TW")
        let loc: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
        if #available(iOS 11.0, *) {
            CLGeocoder().reverseGeocodeLocation(loc, preferredLocale: locale) { placemarks, error in
                guard let placemark = placemarks?.first, error == nil else {
                    UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                    completion(nil, error)
                    return
                }
                //                print("city:",     placemark.locality ?? "")
                completion(placemark, nil)
            }
        }
    }
}


extension BikeAndBusViewController : MKMapViewDelegate{
    //點擊圖標的動作,思考新增判斷網路
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        var cityStr :String = ""
        guard let annotation = view.annotation as? StationAnnotation else{
            assertionFailure("urlError")
            return
        }
        geocode(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude) { (placemark, error) in
            print("Start")
            guard let placemark = placemark, let str = placemark.subAdministrativeArea, error == nil else {
                assertionFailure("get city name error")
                return
            }
            cityStr = str
            print(cityStr)
        }
        
        let requestUrl =  "http://data.ntpc.gov.tw/od/data/api/54DDDC93-589C-4858-9C95-18B2046CC1FC?$format=json&$filter=sno%20eq%20\(annotation.stationID)"
        guard let url = URL(string: requestUrl) else {
            assertionFailure("urlError")
            return
        }
        var tmpData : Data?
        do{
            tmpData = try Data(contentsOf: url)
        }catch{
            assertionFailure("can't get data")
        }
        guard let ubData = tmpData else{
            assertionFailure("tmpData == nil")
            return
        }
        var ubJsonData : [Dictionary<String,Any>]?
        do{
            ubJsonData = try JSONSerialization.jsonObject(with: ubData, options: []) as? [Dictionary<String,Any>]
        }catch{
            assertionFailure("can't get ubJsonData")
        }
        guard let data = ubJsonData else{
            assertionFailure("ubJsonData == nil")
            return
        }
        let result = data[0]
        annotation.subtitle = result["act"] as! String == "0" ? "未營運" : "可借\(result["sbi"]!)台,可還\(result["bemp"]!)台"
    }
    
    // 移動結束才會執行
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("就決定是你了")
        showBikeStation()
//        geocode(latitude: 25.029264, longitude: 121.499358) { (placemark, error) in
//            //25.029264, 121.499358
//            print("Start")
//            guard let placemark = placemark, error == nil else {
//
//                return
//
//            }
//            let str = placemark.subAdministrativeArea
//        }
    }
}

