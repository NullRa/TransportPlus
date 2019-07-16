import UIKit

class BusNumberViewController: UIViewController {
    var busStation: BusStation!
    var detailText = ""
    @IBOutlet weak var busNumberTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        busNumberTableView.dataSource=self
        busNumberTableView.delegate=self
    }

    @IBAction func returnBtnPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: UITableViewDataSource
extension BusNumberViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return busStation.busNumbers.count
    }
    //每一筆資料長得像什麼樣子(UITableViewCell)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "busNumberCell", for: indexPath)
        let busNumber = busStation.busNumbers[indexPath.row]
        if busNumber.busName == nil || busNumber.busID == nil {
            cell.textLabel?.text = "系統錯誤"
            cell.detailTextLabel?.text = "系統錯誤"
            return cell
        }
        cell.textLabel?.text = busNumber.busName
        let stationDetail = BusJson()
        do {
            let busState = try stationDetail.fetchStationStatus(stationID: busNumber.busID!,
                                                                cityName: busStation.cityName)
            guard let estimateTime = busState.EstimateTime else {
                cell.detailTextLabel?.text = "該車輛未提供即時資訊"
                return cell
            }
            switch busState.StopStatus {
            case 0: cell.detailTextLabel?.text = estimateTime/60 == 0 ? "即將到站" : "預計還有\(estimateTime/60)分鐘到站"
            case 1: cell.detailTextLabel?.text = "尚未發車"
            case 2: cell.detailTextLabel?.text = "交管不停靠"
            case 3: cell.detailTextLabel?.text = "末班車已過"
            case 4: cell.detailTextLabel?.text = "今日未營運"
            default:
                assertionFailure("error")
            }
        } catch {
            let alertCon = UIAlertController(title: ErrorCode.jsonDecodeError.alertTitle,
                                             message: ErrorCode.jsonDecodeError.alertMessage, preferredStyle: .alert)
            let alertActA = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertCon.addAction(alertActA)
            self.present(alertCon, animated: true, completion: nil)
        }
        return cell
    }
}

extension Notification.Name {
    static let alertMessage = Notification.Name("alertMessage")
}
