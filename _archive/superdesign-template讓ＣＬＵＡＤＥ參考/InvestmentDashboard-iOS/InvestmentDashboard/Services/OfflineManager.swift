import Foundation
import Network
import Combine

// MARK: - Offline Manager
@MainActor
class OfflineManager: ObservableObject {

    // MARK: - Properties
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var cancellables = Set<AnyCancellable>()

    @Published var isOnline = true
    @Published var pendingChanges: [PendingChange] = []

    private let userDefaults = UserDefaults.standard
    private let pendingChangesKey = "PendingChanges"

    // MARK: - Initialization
    init() {
        loadPendingChanges()
        startNetworkMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                if self?.isOnline == true {
                    Task {
                        await self?.processPendingChanges()
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }

    // MARK: - Pending Changes Management
    func addPendingChange<T: CloudKitConvertible>(_ item: T, operation: ChangeOperation) {
        let change = PendingChange(
            id: UUID(),
            recordID: item.recordID.recordName,
            recordType: T.recordType,
            operation: operation,
            data: try? JSONEncoder().encode(item),
            timestamp: Date()
        )

        pendingChanges.append(change)
        savePendingChanges()
    }

    func addPendingDelete(recordID: String, recordType: String) {
        let change = PendingChange(
            id: UUID(),
            recordID: recordID,
            recordType: recordType,
            operation: .delete,
            data: nil,
            timestamp: Date()
        )

        pendingChanges.append(change)
        savePendingChanges()
    }

    private func processPendingChanges() async {
        guard isOnline && !pendingChanges.isEmpty else { return }

        print("處理 \(pendingChanges.count) 個待處理的變更...")

        // 按時間順序處理變更
        let sortedChanges = pendingChanges.sorted { $0.timestamp < $1.timestamp }

        for change in sortedChanges {
            do {
                try await processChange(change)
                // 成功處理後移除
                if let index = pendingChanges.firstIndex(where: { $0.id == change.id }) {
                    pendingChanges.remove(at: index)
                }
            } catch {
                print("處理變更失敗: \(error)")
                // 失敗的變更保留，等下次重試
                break
            }
        }

        savePendingChanges()
    }

    private func processChange(_ change: PendingChange) async throws {
        // 這裡需要與 CloudKitManager 整合
        // 暫時只是記錄
        print("處理變更: \(change.recordType) - \(change.operation)")

        switch change.operation {
        case .create, .update:
            // 重新建立物件並儲存到 CloudKit
            if let data = change.data {
                try await processDataChange(data: data, recordType: change.recordType)
            }
        case .delete:
            // 執行刪除操作
            try await processDeleteChange(recordID: change.recordID, recordType: change.recordType)
        }
    }

    private func processDataChange(data: Data, recordType: String) async throws {
        // 根據記錄類型重新建立物件
        switch recordType {
        case Client.recordType:
            if let client = try? JSONDecoder().decode(Client.self, from: data) {
                // 儲存到 CloudKit
                print("離線同步: 儲存客戶資料 \(client.name)")
            }
        case MonthlyAssetRecord.recordType:
            if let record = try? JSONDecoder().decode(MonthlyAssetRecord.self, from: data) {
                print("離線同步: 儲存月度資產記錄")
            }
        case Bond.recordType:
            if let bond = try? JSONDecoder().decode(Bond.self, from: data) {
                print("離線同步: 儲存債券資料 \(bond.bondName)")
            }
        case StructuredProduct.recordType:
            if let product = try? JSONDecoder().decode(StructuredProduct.self, from: data) {
                print("離線同步: 儲存結構型商品 \(product.target)")
            }
        default:
            print("未知的記錄類型: \(recordType)")
        }
    }

    private func processDeleteChange(recordID: String, recordType: String) async throws {
        print("離線同步: 刪除記錄 \(recordID) (類型: \(recordType))")
        // 執行 CloudKit 刪除操作
    }

    // MARK: - Persistence
    private func savePendingChanges() {
        do {
            let data = try JSONEncoder().encode(pendingChanges)
            userDefaults.set(data, forKey: pendingChangesKey)
        } catch {
            print("儲存待處理變更失敗: \(error)")
        }
    }

    private func loadPendingChanges() {
        guard let data = userDefaults.data(forKey: pendingChangesKey),
              let changes = try? JSONDecoder().decode([PendingChange].self, from: data) else {
            return
        }
        self.pendingChanges = changes
    }

    // MARK: - Public Methods
    func clearPendingChanges() {
        pendingChanges.removeAll()
        savePendingChanges()
    }

    func retryPendingChanges() async {
        await processPendingChanges()
    }
}

// MARK: - Data Models
struct PendingChange: Codable, Identifiable {
    let id: UUID
    let recordID: String
    let recordType: String
    let operation: ChangeOperation
    let data: Data?
    let timestamp: Date
}

enum ChangeOperation: String, Codable {
    case create = "create"
    case update = "update"
    case delete = "delete"
}

// MARK: - Local Storage Manager
@MainActor
class LocalStorageManager: ObservableObject {

    private let userDefaults = UserDefaults.standard

    // MARK: - Keys
    private enum Keys {
        static let clients = "LocalClients"
        static let monthlyAssetRecords = "LocalMonthlyAssetRecords"
        static let bonds = "LocalBonds"
        static let structuredProducts = "LocalStructuredProducts"
        static let lastSyncDate = "LastSyncDate"
    }

    // MARK: - Local Data
    @Published var localClients: [Client] = []
    @Published var localMonthlyAssetRecords: [MonthlyAssetRecord] = []
    @Published var localBonds: [Bond] = []
    @Published var localStructuredProducts: [StructuredProduct] = []

    init() {
        loadLocalData()
    }

    // MARK: - Save Methods
    func saveClient(_ client: Client) {
        if let index = localClients.firstIndex(where: { $0.id == client.id }) {
            localClients[index] = client
        } else {
            localClients.append(client)
        }
        saveClients()
    }

    func saveMonthlyAssetRecord(_ record: MonthlyAssetRecord) {
        if let index = localMonthlyAssetRecords.firstIndex(where: { $0.id == record.id }) {
            localMonthlyAssetRecords[index] = record
        } else {
            localMonthlyAssetRecords.append(record)
        }
        localMonthlyAssetRecords.sort { $0.date > $1.date }
        saveMonthlyAssetRecords()
    }

    func saveBond(_ bond: Bond) {
        if let index = localBonds.firstIndex(where: { $0.id == bond.id }) {
            localBonds[index] = bond
        } else {
            localBonds.append(bond)
        }
        localBonds.sort { $0.purchaseDate > $1.purchaseDate }
        saveBonds()
    }

    func saveStructuredProduct(_ product: StructuredProduct) {
        if let index = localStructuredProducts.firstIndex(where: { $0.id == product.id }) {
            localStructuredProducts[index] = product
        } else {
            localStructuredProducts.append(product)
        }
        localStructuredProducts.sort { $0.tradeDate > $1.tradeDate }
        saveStructuredProducts()
    }

    // MARK: - Delete Methods
    func deleteClient(_ client: Client) {
        localClients.removeAll { $0.id == client.id }
        saveClients()
    }

    func deleteMonthlyAssetRecord(_ record: MonthlyAssetRecord) {
        localMonthlyAssetRecords.removeAll { $0.id == record.id }
        saveMonthlyAssetRecords()
    }

    func deleteBond(_ bond: Bond) {
        localBonds.removeAll { $0.id == bond.id }
        saveBonds()
    }

    func deleteStructuredProduct(_ product: StructuredProduct) {
        localStructuredProducts.removeAll { $0.id == product.id }
        saveStructuredProducts()
    }

    // MARK: - Private Save Methods
    private func saveClients() {
        save(localClients, forKey: Keys.clients)
    }

    private func saveMonthlyAssetRecords() {
        save(localMonthlyAssetRecords, forKey: Keys.monthlyAssetRecords)
    }

    private func saveBonds() {
        save(localBonds, forKey: Keys.bonds)
    }

    private func saveStructuredProducts() {
        save(localStructuredProducts, forKey: Keys.structuredProducts)
    }

    private func save<T: Codable>(_ items: [T], forKey key: String) {
        do {
            let data = try JSONEncoder().encode(items)
            userDefaults.set(data, forKey: key)
        } catch {
            print("儲存本地資料失敗 (\(key)): \(error)")
        }
    }

    // MARK: - Load Methods
    private func loadLocalData() {
        localClients = load([Client].self, forKey: Keys.clients) ?? []
        localMonthlyAssetRecords = load([MonthlyAssetRecord].self, forKey: Keys.monthlyAssetRecords) ?? []
        localBonds = load([Bond].self, forKey: Keys.bonds) ?? []
        localStructuredProducts = load([StructuredProduct].self, forKey: Keys.structuredProducts) ?? []

        // 排序
        localClients.sort { $0.createdDate > $1.createdDate }
        localMonthlyAssetRecords.sort { $0.date > $1.date }
        localBonds.sort { $0.purchaseDate > $1.purchaseDate }
        localStructuredProducts.sort { $0.tradeDate > $1.tradeDate }
    }

    private func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key),
              let items = try? JSONDecoder().decode(type, from: data) else {
            return nil
        }
        return items
    }

    // MARK: - Sync Management
    func updateLastSyncDate() {
        userDefaults.set(Date(), forKey: Keys.lastSyncDate)
    }

    func getLastSyncDate() -> Date? {
        return userDefaults.object(forKey: Keys.lastSyncDate) as? Date
    }

    func clearAllLocalData() {
        localClients.removeAll()
        localMonthlyAssetRecords.removeAll()
        localBonds.removeAll()
        localStructuredProducts.removeAll()

        userDefaults.removeObject(forKey: Keys.clients)
        userDefaults.removeObject(forKey: Keys.monthlyAssetRecords)
        userDefaults.removeObject(forKey: Keys.bonds)
        userDefaults.removeObject(forKey: Keys.structuredProducts)
        userDefaults.removeObject(forKey: Keys.lastSyncDate)
    }

    // MARK: - Helper Methods
    func monthlyAssetRecords(for clientID: UUID) -> [MonthlyAssetRecord] {
        return localMonthlyAssetRecords.filter { $0.clientID == clientID }
    }

    func bonds(for clientID: UUID) -> [Bond] {
        return localBonds.filter { $0.clientID == clientID }
    }

    func structuredProducts(for clientID: UUID) -> [StructuredProduct] {
        return localStructuredProducts.filter { $0.clientID == clientID }
    }
}