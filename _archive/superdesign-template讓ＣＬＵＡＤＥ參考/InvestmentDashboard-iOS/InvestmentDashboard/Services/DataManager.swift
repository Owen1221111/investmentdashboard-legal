import Foundation
import SwiftUI
import Combine

// MARK: - Data Manager with CloudKit Integration
@MainActor
class DataManager: ObservableObject {

    // MARK: - CloudKit Manager
    private let cloudKitManager = CloudKitManager()

    // MARK: - Published Properties (代理到 CloudKitManager)
    var clients: [Client] {
        cloudKitManager.clients
    }

    var monthlyAssetRecords: [MonthlyAssetRecord] {
        cloudKitManager.monthlyAssetRecords
    }

    var bonds: [Bond] {
        cloudKitManager.bonds
    }

    var structuredProducts: [StructuredProduct] {
        cloudKitManager.structuredProducts
    }

    @Published var isOnline = true
    @Published var isSignedInToiCloud = false

    // MARK: - Sync Status Properties
    var syncStatus: SyncStatus {
        cloudKitManager.syncStatus
    }

    var statusDescription: String {
        cloudKitManager.syncStatus.description
    }

    var hasDataToSync: Bool {
        // 檢查是否有尚未同步的本地更改
        false // 簡化版本，不需要離線功能
    }

    // MARK: - Initialization
    init() {
        // 訂閱 CloudKitManager 的狀態變化
        bindToCloudKitManager()
    }

    private func bindToCloudKitManager() {
        // 監聽 CloudKit 狀態變化並更新本地狀態
        cloudKitManager.$isSignedInToiCloud
            .assign(to: &$isSignedInToiCloud)

        cloudKitManager.$isOnline
            .assign(to: &$isOnline)

        // 監聽資料變化以觸發 UI 更新
        cloudKitManager.$clients
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        cloudKitManager.$monthlyAssetRecords
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        cloudKitManager.$bonds
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        cloudKitManager.$structuredProducts
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        cloudKitManager.$syncStatus
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()


    // MARK: - Client Operations
    func saveClient(_ client: Client) async throws {
        try await cloudKitManager.save(client)
    }

    func deleteClient(_ client: Client) async throws {
        try await cloudKitManager.delete(client)
    }

    func saveMonthlyAssetRecord(_ record: MonthlyAssetRecord) async throws {
        try await cloudKitManager.save(record)
    }

    func deleteMonthlyAssetRecord(_ record: MonthlyAssetRecord) async throws {
        try await cloudKitManager.delete(record)
    }

    func saveBond(_ bond: Bond) async throws {
        try await cloudKitManager.save(bond)
    }

    func deleteBond(_ bond: Bond) async throws {
        try await cloudKitManager.delete(bond)
    }

    func saveStructuredProduct(_ product: StructuredProduct) async throws {
        try await cloudKitManager.save(product)
    }

    func deleteStructuredProduct(_ product: StructuredProduct) async throws {
        try await cloudKitManager.delete(product)
    }

    // MARK: - Query Methods
    func monthlyAssetRecords(for clientID: UUID) -> [MonthlyAssetRecord] {
        return monthlyAssetRecords.filter { $0.clientID == clientID }
    }

    func bonds(for clientID: UUID) -> [Bond] {
        return bonds.filter { $0.clientID == clientID }
    }

    func structuredProducts(for clientID: UUID) -> [StructuredProduct] {
        return structuredProducts.filter { $0.clientID == clientID }
    }

    func latestMonthlyAssetRecord(for clientID: UUID) -> MonthlyAssetRecord? {
        return monthlyAssetRecords(for: clientID).sorted { $0.date > $1.date }.first
    }

    // MARK: - Refresh and Sync Methods
    func refreshData() async {
        await cloudKitManager.forceRefreshData()
    }

    func forceSync() async {
        await cloudKitManager.forceRefreshData()
    }

    func forceSyncFromCloudKit() async {
        await cloudKitManager.forceRefreshData()
    }

    // MARK: - Migration Helper
    func migrateLegacyData(bondStringArrays: [[String]], clientID: UUID) async throws {
        // 將舊版債券字串陣列轉換為Bond物件並儲存
        for bondArray in bondStringArrays {
            if bondArray.count >= 14, // 確保有足夠的資料
               let purchaseDate = parseDate(from: bondArray[1]) {

                let bond = Bond(
                    clientID: clientID,
                    purchaseDate: purchaseDate,
                    bondName: bondArray[0],
                    couponRate: Double(bondArray[2]) ?? 0,
                    yieldRate: Double(bondArray[3]) ?? 0,
                    purchasePrice: Double(bondArray[4]) ?? 0,
                    purchaseAmount: Double(bondArray[5]) ?? 0,
                    holdingFaceValue: Double(bondArray[6]) ?? 0,
                    tradeAmount: Double(bondArray[7]) ?? 0,
                    currentValue: Double(bondArray[8]) ?? 0,
                    receivedInterest: Double(bondArray[9]) ?? 0,
                    dividendMonths: bondArray[10],
                    singleDividend: Double(bondArray[11]) ?? 0,
                    annualDividend: Double(bondArray[12]) ?? 0
                )

                try await saveBond(bond)
            }
        }
    }

    private func parseDate(from dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}