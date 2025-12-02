import Foundation
import CloudKit
import Combine
import UIKit

// MARK: - CloudKit Manager
@MainActor
class CloudKitManager: ObservableObject {

    // MARK: - Properties
    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase
    private var cancellables = Set<AnyCancellable>()

    @Published var isSignedInToiCloud = false
    @Published var isOnline = true
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?

    // MARK: - Auto Refresh Properties
    private var refreshTimer: Timer?
    private var foregroundObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?

    // MARK: - Published Data Collections
    @Published var clients: [Client] = []
    @Published var monthlyAssetRecords: [MonthlyAssetRecord] = []
    @Published var bonds: [Bond] = []
    @Published var structuredProducts: [StructuredProduct] = []

    // MARK: - Initialization
    init(containerIdentifier: String = "iCloud.com.owen.InvestmentDashboard") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.publicDatabase = container.publicCloudDatabase
        self.privateDatabase = container.privateCloudDatabase

        Task {
            await checkiCloudAccountStatus()
            if isSignedInToiCloud {
                await fetchAllData()
                startAutoRefresh()
            }
        }

        setupAppLifecycleObservers()
    }

    deinit {
        stopAutoRefresh()
        removeAppLifecycleObservers()
    }

    // MARK: - iCloud Account Management
    func checkiCloudAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                isSignedInToiCloud = (status == .available)
            }
        } catch {
            await MainActor.run {
                isSignedInToiCloud = false
            }
            print("iCloud 帳號狀態檢查失敗: \(error)")
        }
    }

    // MARK: - Data Fetching
    func fetchAllData() async {
        guard isSignedInToiCloud else {
            print("未登入iCloud，跳過資料同步")
            return
        }

        await MainActor.run {
            syncStatus = .fetching
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchClients() }
            group.addTask { await self.fetchMonthlyAssetRecords() }
            group.addTask { await self.fetchBonds() }
            group.addTask { await self.fetchStructuredProducts() }
        }

        await MainActor.run {
            lastSyncDate = Date()
            syncStatus = .completed
            print("✅ CloudKit資料同步完成")
        }
    }

    func fetchClients() async {
        do {
            let query = CKQuery(recordType: Client.recordType, predicate: NSPredicate(format: "TRUEPREDICATE"))
            let (matchResults, _) = try await privateDatabase.records(matching: query)

            let fetchedClients = matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return Client(from: record)
                case .failure(let error):
                    print("客戶記錄獲取失敗: \(error)")
                    return nil
                }
            }

            await MainActor.run {
                self.clients = fetchedClients.sorted { $0.createdDate > $1.createdDate }
                print("📋 載入 \(fetchedClients.count) 個客戶")
            }
        } catch {
            await handleFetchError(error, dataType: "客戶資料")
        }
    }

    func fetchMonthlyAssetRecords() async {
        do {
            let query = CKQuery(recordType: MonthlyAssetRecord.recordType, predicate: NSPredicate(format: "TRUEPREDICATE"))
            query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

            let (matchResults, _) = try await privateDatabase.records(matching: query)

            let fetchedRecords = matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return MonthlyAssetRecord(from: record)
                case .failure(let error):
                    print("月度資產記錄獲取失敗: \(error)")
                    return nil
                }
            }

            await MainActor.run {
                self.monthlyAssetRecords = fetchedRecords
                print("📊 載入 \(fetchedRecords.count) 個月度資產記錄")
            }
        } catch {
            await handleFetchError(error, dataType: "月度資產資料")
        }
    }

    func fetchBonds() async {
        do {
            let query = CKQuery(recordType: Bond.recordType, predicate: NSPredicate(format: "TRUEPREDICATE"))
            query.sortDescriptors = [NSSortDescriptor(key: "purchaseDate", ascending: false)]

            let (matchResults, _) = try await privateDatabase.records(matching: query)

            let fetchedBonds = matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return Bond(from: record)
                case .failure(let error):
                    print("債券記錄獲取失敗: \(error)")
                    return nil
                }
            }

            await MainActor.run {
                self.bonds = fetchedBonds
                print("🏦 載入 \(fetchedBonds.count) 個債券記錄")
            }
        } catch {
            await handleFetchError(error, dataType: "債券資料")
        }
    }

    func fetchStructuredProducts() async {
        do {
            let query = CKQuery(recordType: StructuredProduct.recordType, predicate: NSPredicate(format: "TRUEPREDICATE"))
            query.sortDescriptors = [NSSortDescriptor(key: "tradeDate", ascending: false)]

            let (matchResults, _) = try await privateDatabase.records(matching: query)

            let fetchedProducts = matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return StructuredProduct(from: record)
                case .failure(let error):
                    print("結構型商品記錄獲取失敗: \(error)")
                    return nil
                }
            }

            await MainActor.run {
                self.structuredProducts = fetchedProducts
                print("📈 載入 \(fetchedProducts.count) 個結構型商品記錄")
            }
        } catch {
            await handleFetchError(error, dataType: "結構型商品資料")
        }
    }

    // MARK: - Data Saving
    func save<T: CloudKitConvertible>(_ item: T) async throws {
        guard isSignedInToiCloud else {
            throw CloudKitError.accountNotFound
        }

        await MainActor.run {
            syncStatus = .saving
        }

        let record = item.toCKRecord()

        do {
            _ = try await privateDatabase.save(record)
            await MainActor.run {
                syncStatus = .completed
                lastSyncDate = Date()
            }

            // 更新本地資料
            await updateLocalData(item)
            print("✅ 成功儲存到iCloud: \(T.recordType)")

        } catch {
            await MainActor.run {
                syncStatus = .failed
            }
            print("❌ 儲存到iCloud失敗: \(error.localizedDescription)")
            throw CloudKitError.unknown(error)
        }
    }

    // MARK: - Data Deletion
    func delete<T: CloudKitConvertible>(_ item: T) async throws {
        guard isSignedInToiCloud else {
            throw CloudKitError.accountNotFound
        }

        await MainActor.run {
            syncStatus = .saving
        }

        do {
            _ = try await privateDatabase.deleteRecord(withID: item.recordID)
            await MainActor.run {
                syncStatus = .completed
                lastSyncDate = Date()
            }

            // 從本地資料中移除
            await removeFromLocalData(item)
            print("✅ 成功從iCloud刪除: \(T.recordType)")

        } catch {
            await MainActor.run {
                syncStatus = .failed
            }
            print("❌ 從iCloud刪除失敗: \(error.localizedDescription)")
            throw CloudKitError.unknown(error)
        }
    }

    // MARK: - Batch Operations
    func saveBatch<T: CloudKitConvertible>(_ items: [T]) async throws {
        guard isSignedInToiCloud else {
            throw CloudKitError.accountNotFound
        }

        await MainActor.run {
            syncStatus = .saving
        }

        let records = items.map { $0.toCKRecord() }

        do {
            let (saveResults, _) = try await privateDatabase.modifyRecords(saving: records, deleting: [])

            // 檢查結果
            for (recordID, result) in saveResults {
                switch result {
                case .success:
                    continue
                case .failure(let error):
                    print("記錄 \(recordID) 儲存失敗: \(error)")
                }
            }

            await MainActor.run {
                syncStatus = .completed
                lastSyncDate = Date()
            }

            // 批量更新本地資料
            for item in items {
                await updateLocalData(item)
            }

        } catch {
            await MainActor.run {
                syncStatus = .failed
            }
            throw CloudKitError.unknown(error)
        }
    }

    // MARK: - Helper Methods
    private func updateLocalData<T: CloudKitConvertible>(_ item: T) async {
        await MainActor.run {
            switch item {
            case let client as Client:
                if let index = clients.firstIndex(where: { $0.id == client.id }) {
                    clients[index] = client
                } else {
                    clients.append(client)
                    clients.sort { $0.createdDate > $1.createdDate }
                }

            case let record as MonthlyAssetRecord:
                if let index = monthlyAssetRecords.firstIndex(where: { $0.id == record.id }) {
                    monthlyAssetRecords[index] = record
                } else {
                    monthlyAssetRecords.append(record)
                    monthlyAssetRecords.sort { $0.date > $1.date }
                }

            case let bond as Bond:
                if let index = bonds.firstIndex(where: { $0.id == bond.id }) {
                    bonds[index] = bond
                } else {
                    bonds.append(bond)
                    bonds.sort { $0.purchaseDate > $1.purchaseDate }
                }

            case let product as StructuredProduct:
                if let index = structuredProducts.firstIndex(where: { $0.id == product.id }) {
                    structuredProducts[index] = product
                } else {
                    structuredProducts.append(product)
                    structuredProducts.sort { $0.tradeDate > $1.tradeDate }
                }

            default:
                break
            }
        }
    }

    private func removeFromLocalData<T: CloudKitConvertible>(_ item: T) async {
        await MainActor.run {
            switch item {
            case let client as Client:
                clients.removeAll { $0.id == client.id }
            case let record as MonthlyAssetRecord:
                monthlyAssetRecords.removeAll { $0.id == record.id }
            case let bond as Bond:
                bonds.removeAll { $0.id == bond.id }
            case let product as StructuredProduct:
                structuredProducts.removeAll { $0.id == product.id }
            default:
                break
            }
        }
    }

    // MARK: - Filtered Data Helper Methods
    func monthlyAssetRecords(for clientID: UUID) -> [MonthlyAssetRecord] {
        monthlyAssetRecords.filter { $0.clientID == clientID }
    }

    func bonds(for clientID: UUID) -> [Bond] {
        bonds.filter { $0.clientID == clientID }
    }

    func structuredProducts(for clientID: UUID) -> [StructuredProduct] {
        structuredProducts.filter { $0.clientID == clientID }
    }

    // MARK: - Error Handling
    private func handleFetchError(_ error: Error, dataType: String) async {
        await MainActor.run {
            syncStatus = .failed
            isOnline = false
        }

        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkFailure, .networkUnavailable:
                print("❌ 網路連線問題，無法同步\(dataType)")
                await MainActor.run {
                    isOnline = false
                }
            case .notAuthenticated:
                print("❌ iCloud認證失敗，請檢查登入狀態")
                await MainActor.run {
                    isSignedInToiCloud = false
                }
            case .quotaExceeded:
                print("❌ iCloud儲存空間不足")
            default:
                print("❌ \(dataType)獲取失敗: \(ckError.localizedDescription)")
            }
        } else {
            print("❌ \(dataType)獲取失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - Auto Refresh and App Lifecycle Management

    private func startAutoRefresh() {
        print("🔄 開始自動刷新 (每30秒)")
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchAllData()
            }
        }
    }

    private func stopAutoRefresh() {
        print("⏹️ 停止自動刷新")
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func setupAppLifecycleObservers() {
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 App進入前景，開始同步")
            Task { @MainActor in
                await self?.checkiCloudAccountStatus()
                if self?.isSignedInToiCloud == true {
                    await self?.fetchAllData()
                    self?.startAutoRefresh()
                }
            }
        }

        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 App進入背景，停止自動刷新")
            self?.stopAutoRefresh()
        }
    }

    private func removeAppLifecycleObservers() {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Manual Sync Methods

    func forceRefreshData() async {
        print("🔄 手動強制同步")
        await checkiCloudAccountStatus()
        if isSignedInToiCloud {
            await fetchAllData()
        }
    }
}

// MARK: - Sync Status
enum SyncStatus {
    case idle
    case fetching
    case saving
    case completed
    case failed

    var description: String {
        switch self {
        case .idle:
            return "待機中"
        case .fetching:
            return "同步中..."
        case .saving:
            return "儲存中..."
        case .completed:
            return "同步完成"
        case .failed:
            return "同步失敗"
        }
    }
}