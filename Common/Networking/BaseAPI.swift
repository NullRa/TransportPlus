import Foundation

class BaseAPI {
    internal func getServerTime() -> String {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "EEE, dd MMM yyyy HH:mm:ww zzz"
        dateFormater.locale = Locale(identifier: "en_US")
        dateFormater.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormater.string(from: Date())
    }

    internal func fetchJsonData(apiURL: String) throws -> Data {
        // swiftlint:disable all
        let src = Bundle.main.path(forResource: "SecretKey", ofType: "plist")
        guard let plist = NSMutableDictionary(contentsOfFile: src!),
            let APP_ID = plist["ptxAPPID"] as? String,
            let APP_KEY = plist["ptxAPPKey"] as? String else {
                throw ErrorCode.dataError
        }
        // swiftlint:enable all

        let xdate: String = getServerTime()
        let signDate = "x-date: " + xdate
        let base64HmacStr = signDate.hmac(algorithm: .SHA1, key: APP_KEY)
        // swiftlint:disable line_length
        let authorization: String = "hmac username=\""+APP_ID+"\", algorithm=\"hmac-sha1\", headers=\"x-date\", signature=\""+base64HmacStr+"\""
        // swiftlint:enable line_length
        let url = URL(string: apiURL)
        var request = URLRequest(url: url!)
        request.setValue(xdate, forHTTPHeaderField: "x-date")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        let sema = DispatchSemaphore( value: 0)

        var currentData: Data = Data()
        let completionHandler = {(data: Data?, response: URLResponse?, error: Error?) -> Void in
            currentData = data!
            sema.signal()
        }
        URLSession.shared.dataTask(with: request, completionHandler: completionHandler).resume()
        sema.wait()

        return currentData
    }

    internal func getCityCode(cityCode: CityCode) -> String {
        if cityCode == .taipei {
            return "Taipei"
        } else {
            return "NewTaipei"
        }
    }

}
