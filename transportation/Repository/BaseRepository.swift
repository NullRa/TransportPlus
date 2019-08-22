import Foundation
import CoreData

class BaseRepository {
    let persistentContainer: PersistentContainer

    init(persistentContainer: PersistentContainer) {
        self.persistentContainer = persistentContainer
    }

    internal func getContext() -> NSManagedObjectContext {
        return self.persistentContainer.getContext()
    }

    internal func saveContext () {
        return self.persistentContainer.saveContext()
    }
}
