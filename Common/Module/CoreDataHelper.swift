import UIKit
import CoreData

class CoreDataHelper: NSObject {
    //Singleton在整個應用程式中只有一個物件(實體)
    static let shared = CoreDataHelper()
    
    override internal init() {
    }

    func managedObjectContext() -> NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TransportationPlus")//dataModel的名字
        let description = NSPersistentStoreDescription()
        //設定sqlite存放位置
        var sqlUrl = URL(fileURLWithPath: NSHomeDirectory())
        sqlUrl.appendPathComponent("Documents")
        sqlUrl.appendPathComponent("TransportationPLUS.sqlite")//最後資料庫產生的名字
        description.url = sqlUrl
        //如果要關閉journal mode，只產生一個sqlite檔案，可以打開這個選項
        //description.setOption(["journal_mode":"DELETE"] as NSDictionary, forKey: NSSQLitePragmasOption)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    func saveUbikes(stations: [UbikeStation]){
        for i in 0 ..< stations.count{
            let ubData = UbikeData(context: CoreDataHelper.shared.managedObjectContext())
            ubData.load(station: stations[i])
            saveContext ()
        }
    }
}
