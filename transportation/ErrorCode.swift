import Foundation

enum ErrorCode: Error {
    case urlError
    case dataError
    case jsonDecodeError
    case coreDataError
    case addressRangeError
    case addressError
    var alertTitle: String {
        var result = ""
        switch self {
        case .urlError: result = "UrlError"
        case .dataError: result = "DataError"
        case .jsonDecodeError: result = "JsonDecodeError"
        case .coreDataError: result = "CoreDataError"
        case .addressRangeError: result = "超出範圍"
        case .addressError: result = "查不到該地址"
        }
        return result
    }
    var alertMessage: String {
        var result = ""
        switch self {
        case .urlError: result = "UrlError"
        case .dataError: result = "DataError"
        case .jsonDecodeError: result = "JsonDecodeError"
        case .coreDataError: result = "CoreDataError"
        case .addressRangeError: result = "請輸入台灣地址"
        case .addressError: result = "請重新輸入"
        }
        return result
    }
}
