import Foundation

enum ErrorCode: Error {
    case UrlError
    case DataError
    case JsonDecodeError
    case CoreDataError
    case AddressRangeError
    case AddressError
    var alertTitle: String {
        var result = ""
        switch self {
        case .UrlError: result = "UrlError"
        case .DataError: result = "DataError"
        case .JsonDecodeError: result = "JsonDecodeError"
        case .CoreDataError: result = "CoreDataError"
        case .AddressRangeError: result = "超出範圍"
        case .AddressError: result = "查不到該地址"
        }
        return result
    }
    var alertMessage: String {
        var result = ""
        switch self {
        case .UrlError: result = "UrlError"
        case .DataError: result = "DataError"
        case .JsonDecodeError: result = "JsonDecodeError"
        case .CoreDataError: result = "CoreDataError"
        case .AddressRangeError: result = "請輸入台灣地址"
        case .AddressError: result = "請重新輸入"
        }
        return result
    }
}
