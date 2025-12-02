import Foundation
import SwiftUI

// MARK: - Enhanced Client ViewModel with CloudKit Support
@MainActor
class ClientViewModelNew: ObservableObject {

    // MARK: - Data Manager
    private let dataManager: DataManager

    // MARK: - Published Properties
    @Published var selectedClient: Client?
    @Published var isLoading = false
    @Published var showingClientList = false
    @Published var showingAddClient = false
    @Published var showingEditClient = false
    @Published var errorMessage: String?
    @Published var showingOfflineAlert = false

    // 編輯相關狀態
    @Published var editingClient: Client?

    // MARK: - Computed Properties
    var clients: [Client] {
        dataManager.clients
    }

    var monthlyAssetRecords: [MonthlyAssetRecord] {
        guard let clientID = selectedClient?.id else { return [] }
        return dataManager.monthlyAssetRecords(for: clientID)
    }

    var bonds: [Bond] {
        guard let clientID = selectedClient?.id else { return [] }
        return dataManager.bonds(for: clientID)
    }

    var structuredProducts: [StructuredProduct] {
        guard let clientID = selectedClient?.id else { return [] }
        return dataManager.structuredProducts(for: clientID)
    }

    // MARK: - Status Properties
    var isOnline: Bool {
        dataManager.isOnline
    }

    var isSignedInToiCloud: Bool {
        dataManager.isSignedInToiCloud
    }

    var syncStatus: SyncStatus {
        dataManager.syncStatus
    }

    var statusDescription: String {
        dataManager.statusDescription
    }

    var hasDataToSync: Bool {
        dataManager.hasDataToSync
    }

    // MARK: - Initialization
    init(dataManager: DataManager = DataManager()) {
        self.dataManager = dataManager

        // 確保在主線程上執行初始化
        Task { @MainActor in
            // 先載入客戶資料
            await loadClients()

            // 設定預設客戶
            if let firstClient = self.dataManager.clients.first {
                self.selectedClient = firstClient
            }
        }
    }

    // MARK: - Client Management
    func loadClients() async {
        isLoading = true
        errorMessage = nil

        do {
            await dataManager.refreshData()

            // 如果沒有選擇的客戶，選擇第一個
            if selectedClient == nil, let firstClient = clients.first {
                selectedClient = firstClient
            }

        } catch {
            errorMessage = "載入客戶資料失敗: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func addClient(name: String, email: String = "") async {
        let newClient = Client(name: name, email: email)

        do {
            try await dataManager.saveClient(newClient)
            selectedClient = newClient
            showingAddClient = false
        } catch {
            if !isOnline {
                showingOfflineAlert = true
                // 離線時依然可以建立，會在上線時同步
                selectedClient = newClient
                showingAddClient = false
            } else {
                errorMessage = "新增客戶失敗: \(error.localizedDescription)"
            }
        }
    }

    func updateClient(_ client: Client) async {
        do {
            try await dataManager.saveClient(client)
            selectedClient = client
            showingEditClient = false
        } catch {
            if !isOnline {
                showingOfflineAlert = true
                selectedClient = client
                showingEditClient = false
            } else {
                errorMessage = "更新客戶失敗: \(error.localizedDescription)"
            }
        }
    }

    func deleteClient(_ client: Client) async {
        do {
            try await dataManager.deleteClient(client)

            if selectedClient?.id == client.id {
                selectedClient = clients.first
            }
        } catch {
            errorMessage = "刪除客戶失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - Monthly Asset Record Management
    func addMonthlyAssetRecord(_ record: MonthlyAssetRecord) async {
        do {
            try await dataManager.saveMonthlyAssetRecord(record)
        } catch {
            if !isOnline {
                showingOfflineAlert = true
            } else {
                errorMessage = "新增月度資產記錄失敗: \(error.localizedDescription)"
            }
        }
    }

    func deleteMonthlyAssetRecord(_ record: MonthlyAssetRecord) async {
        do {
            try await dataManager.deleteMonthlyAssetRecord(record)
        } catch {
            errorMessage = "刪除月度資產記錄失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - Bond Management
    func addBond(_ bond: Bond) async {
        do {
            try await dataManager.saveBond(bond)
        } catch {
            if !isOnline {
                showingOfflineAlert = true
            } else {
                errorMessage = "新增債券失敗: \(error.localizedDescription)"
            }
        }
    }

    func deleteBond(_ bond: Bond) async {
        do {
            try await dataManager.deleteBond(bond)
        } catch {
            errorMessage = "刪除債券失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - Structured Product Management
    func addStructuredProduct(_ product: StructuredProduct) async {
        do {
            try await dataManager.saveStructuredProduct(product)
        } catch {
            if !isOnline {
                showingOfflineAlert = true
            } else {
                errorMessage = "新增結構型商品失敗: \(error.localizedDescription)"
            }
        }
    }

    func markStructuredProductAsExited(_ product: StructuredProduct, exitDate: Date, exitAmount: Double, actualYield: Double) async {
        var updatedProduct = product
        updatedProduct.markAsExited(exitDate: exitDate, exitAmount: exitAmount, actualYield: actualYield)

        do {
            try await dataManager.saveStructuredProduct(updatedProduct)
        } catch {
            if !isOnline {
                showingOfflineAlert = true
            } else {
                errorMessage = "更新結構型商品失敗: \(error.localizedDescription)"
            }
        }
    }

    func deleteStructuredProduct(_ product: StructuredProduct) async {
        do {
            try await dataManager.deleteStructuredProduct(product)
        } catch {
            errorMessage = "刪除結構型商品失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - Migration Helper
    func migrateLegacyBondData(_ bondDataList: [[String]]) async {
        guard let clientID = selectedClient?.id else { return }

        do {
            try await dataManager.migrateLegacyData(bondStringArrays: bondDataList, clientID: clientID)
        } catch {
            errorMessage = "資料遷移失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - Sync Operations
    func forceSync() async {
        isLoading = true
        await dataManager.forceSync()
        isLoading = false
    }

    func retryOfflineChanges() async {
        isLoading = true
        await dataManager.forceSync()
        isLoading = false
    }

    // MARK: - Helper Methods
    private func createDefaultClientIfNeeded() {
        if dataManager.clients.isEmpty {
            Task {
                await addClient(name: "預設客戶")
            }
        }
    }

    // MARK: - Calculated Properties for UI

    /// 最新總資產 (從月度資產明細的最新一筆資料取得)
    var currentTotalAssets: String {
        guard let latestRecord = monthlyAssetRecords.first else {
            return "0"
        }
        return formatNumber(latestRecord.totalAssets)
    }

    /// 最新現金金額
    var currentCash: String {
        guard let latestRecord = monthlyAssetRecords.first else {
            return "0"
        }
        return formatNumber(latestRecord.cash)
    }

    /// 總損益計算
    var currentTotalPnL: String {
        guard let latestRecord = monthlyAssetRecords.first else {
            return "+0 (+0.00%)"
        }

        let pnl = latestRecord.totalPnL
        let percentage = latestRecord.totalPnLPercentage
        let sign = pnl >= 0 ? "+" : ""

        return "\(sign)\(formatNumber(abs(pnl))) (\(sign)\(String(format: "%.2f", percentage))%)"
    }

    /// 最新累積匯入金額
    var currentTotalDeposit: String {
        guard let latestRecord = monthlyAssetRecords.first else {
            return "0"
        }
        return formatNumber(latestRecord.deposit)
    }

    /// 美股百分比
    var usStockPercentage: Double {
        guard let latestRecord = monthlyAssetRecords.first,
              latestRecord.totalAssets > 0 else {
            return 45.0 // 預設值
        }
        return (latestRecord.usStock / latestRecord.totalAssets) * 100
    }

    /// 債券百分比
    var bondsPercentage: Double {
        guard let latestRecord = monthlyAssetRecords.first,
              latestRecord.totalAssets > 0 else {
            return 25.0 // 預設值
        }
        return (latestRecord.bonds / latestRecord.totalAssets) * 100
    }

    /// 現金百分比
    var cashPercentage: Double {
        guard let latestRecord = monthlyAssetRecords.first,
              latestRecord.totalAssets > 0 else {
            return 20.0 // 預設值
        }
        return (latestRecord.cash / latestRecord.totalAssets) * 100
    }

    /// 台股百分比
    var twStockPercentage: Double {
        guard let latestRecord = monthlyAssetRecords.first,
              latestRecord.totalAssets > 0 else {
            return 8.0 // 預設值
        }
        return (latestRecord.twStock / latestRecord.totalAssets) * 100
    }

    /// 結構型商品百分比
    var structuredPercentage: Double {
        guard let latestRecord = monthlyAssetRecords.first,
              latestRecord.totalAssets > 0 else {
            return 2.0 // 預設值
        }
        return (latestRecord.structuredProducts / latestRecord.totalAssets) * 100
    }

    /// 格式化數字
    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    // MARK: - Legacy Compatibility Methods

    /// 轉換為舊版月度資產陣列格式 (用於相容現有 UI)
    var monthlyAssetData: [[String]] {
        return monthlyAssetRecords.map { record in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM-dd"

            return [
                dateFormatter.string(from: record.date),
                String(format: "%.0f", record.cash / 1000),
                String(format: "%.2f", record.usStock / 1000),
                String(format: "%.2f", record.regularInvestment / 1000),
                String(format: "%.2f", record.bonds / 1000),
                String(format: "%.1f", record.structuredProducts / 1000),
                String(format: "%.1f", record.twStock / 1000),
                String(format: "%.0f", record.twStockConverted / 1000),
                String(format: "%.5f", record.confirmedInterest / 1000),
                String(format: "%.1f", record.deposit / 1000),
                String(format: "%.2f", record.cashCost / 1000),
                String(format: "%.2f", record.stockCost / 1000),
                String(format: "%.2f", record.bondCost / 1000),
                String(format: "%.1f", record.otherCost / 1000),
                record.notes,
                String(format: "%.2f", record.totalAssets / 1000)
            ]
        }
    }

    /// 轉換為舊版債券陣列格式 (用於相容現有 UI)
    var bondDataList: [[String]] {
        return bonds.map { $0.toStringArray() }
    }
}