import CoreData
import CloudKit

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    lazy var container: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "DataModel")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        // 基本的 CloudKit 設定
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }()

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
                print("資料已儲存到 iCloud")
            } catch {
                print("Save error: \(error)")
            }
        }
    }

    // 檢查 CloudKit 狀態
    func checkCloudKitStatus() {
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    print("iCloud 可用")
                case .noAccount:
                    print("未登錄 iCloud")
                case .restricted:
                    print("iCloud 受限")
                case .couldNotDetermine:
                    print("無法確定 iCloud 狀態")
                @unknown default:
                    print("未知的 iCloud 狀態")
                }

                if let error = error {
                    print("iCloud 狀態檢查錯誤: \(error)")
                }
            }
        }
    }
}
