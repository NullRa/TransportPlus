import Foundation
import CoreLocation
import CommonCrypto
import MapKit
//import Foundation

enum CryptoAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512

    var HMACAlgorithm: CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:      result = kCCHmacAlgMD5
        case .SHA1:     result = kCCHmacAlgSHA1
        case .SHA224:   result = kCCHmacAlgSHA224
        case .SHA256:   result = kCCHmacAlgSHA256
        case .SHA384:   result = kCCHmacAlgSHA384
        case .SHA512:   result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }

    var digestLength: Int {
        var result: Int32 = 0
        switch self {
        case .MD5:      result = CC_MD5_DIGEST_LENGTH
        case .SHA1:     result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:   result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:   result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:   result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    func hmac(algorithm: CryptoAlgorithm, key: String) -> String {
        let cKey = key.cString(using: String.Encoding.utf8)
        let cData = self.cString(using: String.Encoding.utf8)
        let digestLen = algorithm.digestLength
        var result = [CUnsignedChar](repeating: 0, count: digestLen)
        CCHmac(algorithm.HMACAlgorithm, cKey!, strlen(cKey!), cData!, strlen(cData!), &result)
        let hmacData: Data = Data(bytes: result, count: digestLen)
        let hmacBase64 = hmacData.base64EncodedString(options: .lineLength64Characters)
        return String(hmacBase64)
    }
}

struct UbikeStateJson: Codable {
    var StationUID: String
    var ServieAvailable: Int
    var AvailableReturnBikes: Int
    var AvailableRentBikes: Int
}

struct StationJsonStruct: Codable {
    var StationUID: String
    var StationID: String
    var AuthorityID: String
    var StationName: StationName
    var StationPosition: StationPosition
    struct StationName: Codable {
        var Zh_tw: String
        var En: String
    }
    struct StationPosition: Codable {
        var PositionLat: Double
        var PositionLon: Double
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class UbikeJson {
    let stationAPI: StationAPI

    init() {
        self.stationAPI = StationAPI()
    }

    func fetchStationList(type: StationType) throws -> [Station] {
        return try stationAPI.fetchStationList(stationType: type)
    }

    func fetchStationStatus(stationID: String, cityName: String) throws -> UbikeStateJson {
        let stationType: StationType = cityName == "NWT" ? StationType.NewTaipei : StationType.Taipei
        return try stationAPI.fetchStationStatus(stationType: stationType, stationID: stationID)
    }
}
