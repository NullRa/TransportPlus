import Foundation

enum ErrorCode: Error {
    case UrlError
    case DataError
    case JsonDecodeError
    case CoreDataError
    var alertTitle: String {
        var result = ""
        switch self {
        case .UrlError: result = "UrlError"
        case .DataError: result = "DataError"
        case .JsonDecodeError: result = "JsonDecodeError"
        case .CoreDataError: result = "CoreDataError"
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
        }
        return result
    }
}
