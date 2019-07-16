import UIKit

class BusNumberTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        if let value = value {
            return try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
        }

        return nil
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let value = value {
            return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData((value as? Data)!)
        }

        return nil
    }
}
