import Foundation
import SwiftUI
import CloudKit

// MARK: - Client ViewModel (CloudKit整合版本)
@MainActor
class ClientViewModel: ObservableObject {

    // MARK: - CloudKit Properties
    private let container: CKContainer
    private let privateDatabase: CKDatabase

    // MARK: - Published Properties
    @Published var clients: [Client] = []
    @Published var monthlyAssetRecords: [MonthlyAssetRecord] = []
    @Published var selectedClient: Client?
    @Published var monthlyAssetData: [[String]] = [
        ["Sep-15", "3264", "3596", "0", "2739", "400", "0", "0", "164", "0", "3056", "0", "2906", "0", "最新記錄", "10163"]
    ]
    @Published var isLoading = false
    @Published var showingClientList = false
    @Published var showingAddClient = false
    @Published var showingEditClient = false
    @Published var errorMessage: String?
    @Published var isSignedInToiCloud = false
    @Published var isOnline = true

    // 編輯相關狀態
    @Published var editingClient: Client?

    // 防重複建立測試客戶
    private var hasCreatedTestClients = false

    // MARK: - Computed Properties
    var statusDescription: String {
        if !isSignedInToiCloud {
            return "未登入iCloud"
        } else if !isOnline {
            return "離線"
        } else if isLoading {
            return "同步中..."
        } else {
            return "已同步"
        }
    }

    private var filteredMonthlyRecords: [MonthlyAssetRecord] {
        guard let clientID = selectedClient?.id else { return [] }
        return monthlyAssetRecords.filter { $0.clientID == clientID }
    }

    // MARK: - Computed Asset Properties
    var currentTotalAssets: String {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 15,
              let totalAsset = Double(latestData[15]) else { return "NT$0" }
        return formatCurrency(totalAsset * 1000) // 轉換為實際金額
    }

    var currentCash: String {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 1,
              let cash = Double(latestData[1]) else { return "NT$0" }
        return formatCurrency(cash * 1000) // 轉換為實際金額
    }

    var currentTotalPnL: String {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 15,
              let totalAssets = Double(latestData[15]), // 總資產 (索引15)
              let usStockCost = Double(latestData[10]), // 美股成本
              let bondsCost = Double(latestData[12]) else { return "NT$0" }
        let totalCost = usStockCost + bondsCost
        let pnl = (totalAssets - totalCost) * 1000
        return formatCurrency(pnl)
    }

    var currentTotalReturnRate: String {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 15,
              let totalAssets = Double(latestData[15]), // 總資產 (索引15)
              let usStockCost = Double(latestData[10]), // 美股成本
              let bondsCost = Double(latestData[12]),
              bondsCost + usStockCost > 0 else { return "+0.0%" }
        let totalCost = usStockCost + bondsCost
        let returnRate = ((totalAssets - totalCost) / totalCost) * 100
        let sign = returnRate >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, returnRate)
    }

    // MARK: - Additional Computed Properties for UI
    var currentUSStockValue: String {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 2,
              let usStock = Double(latestData[2]) else { return "NT$0" }
        return formatCurrency(usStock * 1000) // 轉換為實際金額
    }

    var currentBondsValue: String {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 4,
              let bonds = Double(latestData[4]) else { return "NT$0" }
        return formatCurrency(bonds * 1000) // 轉換為實際金額
    }

    var currentTotalDeposit: String {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 9,
              let deposit = Double(latestData[9]) else { return "NT$0" }
        return formatCurrency(deposit * 1000) // 轉換為實際金額
    }

    // MARK: - Percentage Calculations
    var cashPercentage: Double {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 15,
              let cash = Double(latestData[1]),
              let totalAssets = Double(latestData[15]),
              totalAssets > 0 else { return 0 }
        return (cash / totalAssets) * 100
    }

    var usStockPercentage: Double {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 15,
              let usStock = Double(latestData[2]),
              let totalAssets = Double(latestData[15]),
              totalAssets > 0 else { return 0 }
        return (usStock / totalAssets) * 100
    }

    var bondsPercentage: Double {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 15,
              let bonds = Double(latestData[4]),
              let totalAssets = Double(latestData[15]),
              totalAssets > 0 else { return 0 }
        return (bonds / totalAssets) * 100
    }

    var twStockPercentage: Double {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 15,
              let twStock = Double(latestData[6]),
              let totalAssets = Double(latestData[15]),
              totalAssets > 0 else { return 0 }
        return (twStock / totalAssets) * 100
    }

    var structuredPercentage: Double {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 15,
              let structuredProducts = Double(latestData[5]),
              let totalAssets = Double(latestData[15]),
              totalAssets > 0 else { return 0 }
        return (structuredProducts / totalAssets) * 100
    }

    // MARK: - 投資報酬率計算 (根據 PROJECT.md 規範)
    var usStockReturnRate: String {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 15,
              let usStock = Double(latestData[2]), // 美股金額
              let usStockCost = Double(latestData[10]), // 美股成本
              usStockCost > 0 else { return "+0.0%" }
        let returnAmount = usStock - usStockCost
        let returnRate = (returnAmount / usStockCost) * 100
        let sign = returnRate >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", returnRate))%"
    }

    var bondsReturnRate: String {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 15,
              let bonds = Double(latestData[4]), // 債券金額
              let bondsCost = Double(latestData[12]), // 債券成本
              bondsCost > 0 else { return "+0.0%" }
        let returnAmount = bonds - bondsCost
        let returnRate = (returnAmount / bondsCost) * 100
        let sign = returnRate >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", returnRate))%"
    }

    var twStockReturnRate: String {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 15,
              let twStock = Double(latestData[6]), // 台股金額
              let twStockCost = Double(latestData[13]), // 台股成本
              twStockCost > 0 else { return "+0.0%" }
        let returnAmount = twStock - twStockCost
        let returnRate = (returnAmount / twStockCost) * 100
        let sign = returnRate >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", returnRate))%"
    }

    var regularInvestmentValue: String {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 3,
              let regularInvestment = Double(latestData[3]) else { return "NT$0" }
        return formatCurrency(regularInvestment * 1000)
    }

    var currentTWStockValue: String {
        guard let latestData = monthlyAssetData.first,
              latestData.count > 6,
              let twStock = Double(latestData[6]) else { return "NT$0" }
        return formatCurrency(twStock * 1000)
    }

    // MARK: - UI Properties
    var currentClientName: String {
        selectedClient?.name ?? "選擇客戶"
    }

    var hasClients: Bool {
        !clients.isEmpty
    }

    var clientCount: Int {
        clients.count
    }

    // MARK: - Initialization
    init(containerIdentifier: String = "iCloud.com.owen.InvestmentDashboard") {
        print("🚀🚀🚀 ClientViewModel 初始化開始 🚀🚀🚀")
        print("📦 CloudKit 容器 ID: \(containerIdentifier)")

        self.container = CKContainer(identifier: containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase

        print("☁️ CloudKit 容器和資料庫已設定")

        // 清理舊的本地快取，確保只從CloudKit讀取
        clearOldLocalCache()

        Task {
            print("🔄 開始非同步初始化流程...")
            print("🚀 App啟動 - 開始初始化客戶資料")

            await checkiCloudAccountStatus()

            if isSignedInToiCloud {
                print("✅ iCloud 可用，開始載入客戶資料")
                await loadClients()

                // 設定預設客戶
                if let firstClient = clients.first {
                    selectedClient = firstClient
                    print("🎯 設定預設客戶: \(firstClient.name)")
                } else {
                    print("⚠️ 沒有找到任何客戶，建立測試客戶")
                    await createTestClients()
                }
            } else {
                print("⚠️ 未登入iCloud，跳過載入客戶資料")
                // 當沒有登入 iCloud 時，建立本地測試客戶
                print("📝 未找到客戶資料，建立測試客戶")
                await createTestClients()
            }

            print("✅ 客戶資料初始化完成，共 \(clients.count) 位客戶")
            if clients.isEmpty {
                print("💡 用戶可以點擊漢堡按鈕選擇客戶")
            }
            print("✅ ClientViewModel 初始化完成")
        }
    }

    // MARK: - CloudKit Account Management
    private func checkiCloudAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                isSignedInToiCloud = (status == .available)
                print("📱 iCloud狀態檢查: \(status)")

                switch status {
                case .available:
                    print("✅ iCloud可用")
                case .noAccount:
                    print("❌ 設備未登入iCloud帳號")
                    errorMessage = "設備未登入iCloud帳號，請前往「設定」登入"
                case .restricted:
                    print("❌ iCloud受限制")
                    errorMessage = "iCloud功能受限制，請檢查設定"
                case .couldNotDetermine:
                    print("❌ 無法確定iCloud狀態")
                    errorMessage = "無法確定iCloud狀態，請稍後再試"
                case .temporarilyUnavailable:
                    print("⚠️ iCloud暫時無法使用")
                    errorMessage = "iCloud暫時無法使用，請稍後再試"
                @unknown default:
                    print("❓ 未知的iCloud狀態")
                    errorMessage = "未知的iCloud狀態"
                }
            }
        } catch {
            await MainActor.run {
                isSignedInToiCloud = false
                print("❌ 檢查iCloud狀態失敗: \(error)")
                errorMessage = "檢查iCloud狀態失敗: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Client Management
    func refreshData() async {
        print("🔄 手動刷新資料")
        await loadClients()
    }

    func loadClients() async {
        guard isSignedInToiCloud else {
            print("⚠️ 未登入iCloud，跳過載入客戶資料")
            return
        }

        print("🔄 開始載入客戶資料...")
        print("📋 目前本地客戶數量: \(clients.count)")
        isLoading = true
        errorMessage = nil

        do {
            try await fetchClients()
            try await fetchMonthlyAssetRecords()
            print("✅ 客戶資料載入完成，共 \(clients.count) 位客戶")

            // 詳細記錄每個客戶
            for (index, client) in clients.enumerated() {
                print("📝 客戶 \(index + 1): \(client.name) (ID: \(client.id.uuidString.prefix(8))..., 建立時間: \(client.createdDate))")
            }

            // 如果沒有選中的客戶，選擇第一個
            if selectedClient == nil, let firstClient = clients.first {
                selectedClient = firstClient
                print("🎯 自動選擇第一位客戶: \(firstClient.name)")
            }
        } catch {
            errorMessage = "載入客戶資料失敗: \(error.localizedDescription)"
            print("❌ 載入客戶資料失敗: \(error)")
            if let ckError = error as? CKError {
                print("❌ CloudKit錯誤詳情: \(ckError.code), \(ckError.localizedDescription)")
                print("❌ CloudKit錯誤類型: \(ckError.errorCode)")
                if let underlyingError = ckError.userInfo[NSUnderlyingErrorKey] {
                    print("❌ 底層錯誤: \(underlyingError)")
                }
            }

            // 不要清空客戶列表！因為可能已經從緩存載入了資料
            print("⚠️ 保留現有客戶列表，不重置為空")
        }

        isLoading = false
    }

    private func fetchClients() async throws {
        print("🔍 開始從 CloudKit 查詢客戶資料...")
        print("📦 使用容器: \(container.containerIdentifier ?? "未知")")
        print("🏛️ 使用資料庫: \(privateDatabase)")

        // 先測試容器連接
        do {
            let status = try await container.accountStatus()
            print("📱 CloudKit 帳號狀態: \(status)")
        } catch {
            print("❌ 無法檢查 CloudKit 帳號狀態: \(error)")
        }

        do {
            // 使用更簡單的 CloudKit 查詢方法 - 不依賴索引
            print("🔍 嘗試使用基本 CloudKit 查詢...")

            // 先嘗試直接查詢，如果失敗就跳過
            do {
                // 改用CKQueryOperation，不依賴records(matching:)
                let query = CKQuery(recordType: "Client", predicate: NSPredicate(format: "TRUEPREDICATE"))
                let operation = CKQueryOperation(query: query)
                var fetchedRecords: [CKRecord] = []

                operation.recordMatchedBlock = { (recordID, result) in
                    switch result {
                    case .success(let record):
                        fetchedRecords.append(record)
                    case .failure(let error):
                        print("❌ 記錄查詢失敗: \(error)")
                    }
                }

                try await withCheckedThrowingContinuation { continuation in
                    operation.queryResultBlock = { result in
                        switch result {
                        case .success(_):
                            print("🎉 CloudKit 查詢成功！找到 \(fetchedRecords.count) 個記錄")
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    privateDatabase.add(operation)
                }

                // 轉換為matchResults格式
                let matchResults = fetchedRecords.reduce(into: [CKRecord.ID: Result<CKRecord, Error>]()) { result, record in
                    result[record.recordID] = .success(record)
                }

                // 如果成功，處理結果
                await processQueryResults(matchResults: matchResults)
                return // 成功載入，直接返回

            } catch {
                print("❌ CloudKit 查詢失敗: \(error)")
                // 暫時跳過錯誤，繼續執行後續邏輯，讓App能正常運作
                print("⚠️ 繼續執行後續邏輯，不中斷App運作")
            }

            // 如果所有方法都失敗，使用空結果
            let matchResults: [CKRecord.ID: Result<CKRecord, Error>] = [:]
            let cursor: CKQueryOperation.Cursor? = nil
            print("📡 CloudKit 查詢完成，收到 \(matchResults.count) 個結果")

            if let cursor = cursor {
                print("📄 查詢結果有更多頁面，cursor: \(cursor)")
            }

            // 詳細檢查每個查詢結果
            print("🔍 詳細分析查詢結果:")
            for (index, (recordName, result)) in matchResults.enumerated() {
                print("  結果 \(index + 1): recordName=\(recordName)")
                switch result {
                case .success(let record):
                    print("    ✅ 記錄載入成功: \(record.recordID)")
                    print("    📝 記錄內容: \(record)")
                    if let name = record["name"] as? String {
                        print("    👤 客戶姓名: \(name)")
                    }
                    if let email = record["email"] as? String {
                        print("    📧 客戶信箱: \(email)")
                    }
                    if let createdDate = record["createdDate"] as? Date {
                        print("    📅 建立時間: \(createdDate)")
                    }
                case .failure(let error):
                    print("    ❌ 記錄載入失敗: \(error)")
                }
            }

            let fetchedClients = matchResults.compactMap { recordName, result in
                switch result {
                case .success(let record):
                    if let client = Client(from: record) {
                        print("✅ 成功轉換客戶物件: \(client.name) (ID: \(client.id))")
                        return client
                    } else {
                        print("❌ 無法轉換記錄為客戶物件 - recordName: \(recordName)")
                        // 詳細檢查為什麼轉換失敗
                        print("   記錄內容: name=\(record["name"] as? String ?? "nil"), email=\(record["email"] as? String ?? "nil"), createdDate=\(record["createdDate"] as? Date ?? Date())")
                        return nil
                    }
                case .failure(let error):
                    print("❌ 客戶記錄獲取失敗: \(recordName), 錯誤: \(error)")
                    return nil
                }
            }

            print("🔄 準備更新本地客戶列表...")
            await MainActor.run {
                // 只有當CloudKit查詢成功且有結果時才更新客戶列表
                if !fetchedClients.isEmpty {
                    self.clients = fetchedClients
                    print("📋 本地客戶列表已更新，共 \(fetchedClients.count) 個客戶")

                    // 驗證每個客戶資料
                    for (index, client) in fetchedClients.enumerated() {
                        print("✓ 客戶 \(index + 1): \(client.name), ID: \(client.id.uuidString.prefix(8))..., 時間: \(client.createdDate)")
                    }
                } else {
                    print("⚠️ CloudKit查詢結果為空，保留現有客戶列表 (共 \(self.clients.count) 個客戶)")
                }
            }
        } catch {
            print("❌ CloudKit查詢錯誤: \(error)")
            if let ckError = error as? CKError {
                print("❌ CloudKit詳細錯誤: code=\(ckError.code), message=\(ckError.localizedDescription)")
                print("❌ 錯誤 userInfo: \(ckError.userInfo)")

                // 檢查特定的 CloudKit 錯誤類型
                switch ckError.code {
                case .networkFailure:
                    print("🌐 網路連接失敗")
                case .serviceUnavailable:
                    print("☁️ CloudKit 服務不可用")
                case .requestRateLimited:
                    print("⏱️ 請求頻率過高")
                case .quotaExceeded:
                    print("💾 iCloud 儲存空間不足")
                case .unknownItem:
                    print("❓ 找不到記錄")
                case .invalidArguments:
                    print("📝 查詢參數無效")
                case .permissionFailure:
                    print("🔒 權限不足")
                case .badContainer:
                    print("📦 容器配置錯誤")
                case .missingEntitlement:
                    print("⚡ 缺少必要的 entitlements")
                default:
                    print("❓ 其他CloudKit錯誤: \(ckError.code)")
                }
            }

            // 如果是查詢錯誤，不要重置客戶列表
            print("📋 CloudKit查詢失敗，保留現有客戶列表")

            // 重新拋出錯誤，讓 loadClients 知道查詢失敗
            throw error
        }
    }

    private func fetchMonthlyAssetRecords() async throws {
        let query = CKQuery(recordType: "MonthlyAssetRecord", predicate: NSPredicate(format: "TRUEPREDICATE"))
        // 設定排序，但不使用需要索引的欄位
        query.sortDescriptors = []
        let (matchResults, _) = try await privateDatabase.records(matching: query)

        let fetchedRecords = matchResults.compactMap { _, result in
            switch result {
            case .success(let record):
                return MonthlyAssetRecord(from: record)
            case .failure(let error):
                print("月度記錄獲取失敗: \(error)")
                return nil
            }
        }

        await MainActor.run {
            self.monthlyAssetRecords = fetchedRecords.sorted { $0.date > $1.date }
            print("📊 載入 \(fetchedRecords.count) 個月度記錄")
        }
    }

    func addClient(name: String, email: String) async {
        print("🔥🔥🔥 addClient 被呼叫了！姓名：\(name), email：\(email) 🔥🔥🔥")

        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ 客戶姓名為空")
            errorMessage = "客戶姓名不能為空"
            return
        }

        guard isSignedInToiCloud else {
            print("❌ 未登入iCloud，isSignedInToiCloud = \(isSignedInToiCloud)")
            errorMessage = "請先登入iCloud"
            return
        }

        print("✅ iCloud 狀態檢查通過")

        isLoading = true
        errorMessage = nil

        let client = Client(name: name, email: email)

        do {
            let record = client.toCKRecord()
            print("🔄 準備保存客戶到CloudKit...")
            print("📝 客戶資料: 姓名=\(client.name), 信箱=\(client.email), ID=\(client.id.uuidString)")
            print("📝 CloudKit記錄: \(record)")

            let savedRecord = try await privateDatabase.save(record)
            print("✅ CloudKit保存成功，記錄ID: \(savedRecord.recordID)")
            print("📝 保存後的記錄詳情: \(savedRecord)")

            // 等待一小段時間確保CloudKit同步
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

            // 驗證保存是否成功 - 重新從CloudKit讀取
            print("🔍 驗證CloudKit記錄是否確實保存...")
            let verifyRecord = try await privateDatabase.record(for: savedRecord.recordID)
            print("✅ 驗證成功，CloudKit記錄確實存在: \(verifyRecord.recordID)")

            // 驗證記錄內容
            if let verifyName = verifyRecord["name"] as? String,
               let verifyEmail = verifyRecord["email"] as? String {
                print("📝 驗證記錄內容: 姓名=\(verifyName), 信箱=\(verifyEmail)")
            }

            await MainActor.run {
                clients.append(client)
                selectedClient = client
                showingAddClient = false
                print("✅ 本地客戶列表已更新: \(client.name) (ID: \(client.id))")
                print("📊 目前客戶總數: \(clients.count)")

                // 客戶已儲存到CloudKit，不需要本地快取

                // 發送通知，讓 ContentView 切換到主要投資面板頁籤
                NotificationCenter.default.post(name: .clientAdded, object: nil)
            }

            print("✅ 客戶新增完成，跳過立即重新載入以避免時序問題")

        } catch {
            errorMessage = "新增客戶失敗: \(error.localizedDescription)"
            print("❌ 新增客戶失敗: \(error)")
            if let ckError = error as? CKError {
                print("❌ CloudKit錯誤詳情: \(ckError.code), \(ckError.localizedDescription)")
            }
        }

        isLoading = false
    }

    func deleteClient(_ client: Client) async {
        guard isSignedInToiCloud else {
            errorMessage = "請先登入iCloud"
            return
        }

        do {
            _ = try await privateDatabase.deleteRecord(withID: client.recordID)

            await MainActor.run {
                clients.removeAll { $0.id == client.id }
                // 同時移除相關的月度記錄
                monthlyAssetRecords.removeAll { $0.clientID == client.id }

                if selectedClient?.id == client.id {
                    selectedClient = clients.first
                }
                print("✅ 成功刪除客戶: \(client.name)")
            }
        } catch {
            errorMessage = "刪除客戶失敗: \(error.localizedDescription)"
            print("❌ 刪除客戶失敗: \(error)")
        }
    }

    func updateClient(name: String, email: String) async {
        guard let editingClient = editingClient else {
            errorMessage = "沒有選擇要編輯的客戶"
            return
        }

        guard isSignedInToiCloud else {
            errorMessage = "請先登入iCloud"
            return
        }

        do {
            // 從 CloudKit 取得記錄
            let record = try await privateDatabase.record(for: editingClient.recordID)

            // 更新記錄
            record["name"] = name
            record["email"] = email

            // 儲存到 CloudKit
            let updatedRecord = try await privateDatabase.save(record)

            await MainActor.run {
                // 更新本地客戶列表
                if let index = clients.firstIndex(where: { $0.id == editingClient.id }),
                   let updatedClient = Client(from: updatedRecord) {
                    clients[index] = updatedClient
                }

                // 如果編輯的是當前選中的客戶，也要更新
                if selectedClient?.id == editingClient.id,
                   let updatedClient = Client(from: updatedRecord) {
                    selectedClient = updatedClient
                }

                print("✅ 成功更新客戶: \(name)")
                hideEditClient()
            }
        } catch {
            errorMessage = "更新客戶失敗: \(error.localizedDescription)"
            print("❌ 更新客戶失敗: \(error)")
        }
    }

    func createTestClients() async {
        // 防止重複建立測試客戶
        guard !hasCreatedTestClients else {
            print("⚠️ 測試客戶已建立，跳過重複建立")
            return
        }

        print("🧪 開始建立測試客戶")
        hasCreatedTestClients = true

        let testClients = [
            ("張三", "zhang@example.com"),
            ("李四", "li@example.com"),
            ("王五", "wang@example.com")
        ]

        // 如果沒有登入 iCloud，只在本地建立測試客戶
        if !isSignedInToiCloud {
            print("📝 未登入iCloud，建立本地測試客戶")
            await MainActor.run {
                for (name, email) in testClients {
                    let client = Client(name: name, email: email)
                    self.clients.append(client)
                    print("🧪 建立本地測試客戶: \(name)")
                }
                // 選擇第一個客戶
                if let firstClient = self.clients.first {
                    self.selectedClient = firstClient
                    print("🎯 設定預設客戶: \(firstClient.name)")
                }
            }
        } else {
            // 如果已登入 iCloud，則透過 addClient 方法
            for (name, email) in testClients {
                await addClient(name: name, email: email)
            }
        }

        print("✅ 測試客戶建立完成")
    }

    func addMonthlyAssetRecord(_ record: MonthlyAssetRecord) async {
        guard isSignedInToiCloud else {
            errorMessage = "請先登入iCloud"
            return
        }

        do {
            let ckRecord = record.toCKRecord()
            _ = try await privateDatabase.save(ckRecord)

            await MainActor.run {
                monthlyAssetRecords.append(record)
                monthlyAssetRecords.sort { $0.date > $1.date }
                print("✅ 成功新增月度記錄")
            }
        } catch {
            errorMessage = "新增資產記錄失敗: \(error.localizedDescription)"
            print("❌ 新增月度記錄失敗: \(error)")
        }
    }

    // MARK: - UI Actions
    func selectClient(_ client: Client) {
        selectedClient = client
        showingClientList = false
    }

    func showClientList() {
        showingClientList = true
    }

    func hideClientList() {
        showingClientList = false
    }

    func showAddClient() {
        showingAddClient = true
    }

    func showEditClient(_ client: Client) {
        editingClient = client
        showingEditClient = true
    }

    func hideEditClient() {
        showingEditClient = false
        editingClient = nil
    }

    func clearError() {
        errorMessage = nil
    }

    func recheckiCloudStatus() async {
        await checkiCloudAccountStatus()
    }

    // MARK: - Debug Methods
    func testCloudKitConnection() async {
        print("🧪 開始測試 CloudKit 連接...")

        do {
            // 1. 測試帳號狀態
            let accountStatus = try await container.accountStatus()
            print("📱 帳號狀態: \(accountStatus)")

            // 2. 測試建立一個簡單記錄
            let testRecord = CKRecord(recordType: "Client")
            testRecord["name"] = "測試客戶"
            testRecord["email"] = "test@test.com"
            testRecord["createdDate"] = Date()

            print("🔄 嘗試保存測試記錄...")
            let savedRecord = try await privateDatabase.save(testRecord)
            print("✅ 測試記錄保存成功: \(savedRecord.recordID)")

            // 3. 測試讀取記錄
            print("🔄 嘗試讀取測試記錄...")
            let readRecord = try await privateDatabase.record(for: savedRecord.recordID)
            print("✅ 測試記錄讀取成功: \(readRecord)")

            // 4. 刪除測試記錄
            print("🔄 刪除測試記錄...")
            try await privateDatabase.deleteRecord(withID: savedRecord.recordID)
            print("✅ 測試記錄刪除成功")

            print("🎉 CloudKit 連接測試完全成功！")

        } catch {
            print("❌ CloudKit 連接測試失敗: \(error)")
            if let ckError = error as? CKError {
                print("❌ CloudKit 錯誤詳情: \(ckError.code) - \(ckError.localizedDescription)")
            }
        }
    }

    // 新增：專門的 CloudKit 診斷方法
    func diagnoseCloudKitIssues() async {
        print("🔍 開始 CloudKit 診斷...")

        // 1. 檢查容器配置
        print("📦 容器 ID: \(container.containerIdentifier ?? "未設定")")

        // 2. 檢查帳號狀態
        do {
            let accountStatus = try await container.accountStatus()
            print("📱 帳號狀態: \(accountStatus)")

            switch accountStatus {
            case .available:
                print("✅ iCloud 帳號可用")
            case .noAccount:
                print("❌ 沒有 iCloud 帳號")
            case .restricted:
                print("❌ iCloud 功能受限")
            case .couldNotDetermine:
                print("❌ 無法確定 iCloud 狀態")
            case .temporarilyUnavailable:
                print("⚠️ iCloud 暫時無法使用")
            @unknown default:
                print("❓ 未知的 iCloud 狀態")
            }

            // 3. 使用本地客戶列表檢查 CloudKit 記錄
            print("🔍 檢查本地客戶列表中的 CloudKit 記錄...")
            print("📊 本地客戶數量: \(clients.count)")

            if clients.isEmpty {
                print("⚠️ 本地沒有客戶記錄")
            } else {
                // 直接通過 recordID 驗證 CloudKit 記錄
                for client in clients {
                    do {
                        let record = try await privateDatabase.record(for: client.recordID)
                        print("✅ CloudKit 記錄存在: \(client.name) - ID: \(client.id)")
                        print("   記錄內容: name=\(record["name"] as? String ?? ""), email=\(record["email"] as? String ?? "")")
                    } catch {
                        print("❌ CloudKit 記錄讀取失敗: \(client.name) - \(error)")
                    }
                }
            }

        } catch {
            print("❌ CloudKit 診斷失敗: \(error)")
        }
    }

    // MARK: - Local Cache Methods
    private func processQueryResults(matchResults: [CKRecord.ID: Result<CKRecord, Error>]) async {
        let fetchedClients = matchResults.compactMap { _, result in
            switch result {
            case .success(let record):
                return Client(from: record)
            case .failure(let error):
                print("❌ 客戶記錄解析失敗: \(error)")
                return nil
            }
        }

        await MainActor.run {
            self.clients = fetchedClients.sorted { $0.createdDate > $1.createdDate }
            print("✅ 成功載入 \(fetchedClients.count) 位客戶")

            // 資料已從CloudKit載入，不需要本地快取

            // 詳細記錄每個客戶
            for (index, client) in self.clients.enumerated() {
                print("📝 客戶 \(index + 1): \(client.name) (ID: \(client.id.uuidString.prefix(8))..., 建立時間: \(client.createdDate))")
            }

            // 如果沒有選中的客戶，選擇第一個
            if self.selectedClient == nil, let firstClient = self.clients.first {
                self.selectedClient = firstClient
                print("🎯 自動選擇第一位客戶: \(firstClient.name)")
            }
        }
    }

    // MARK: - Cache Cleanup
    private func clearOldLocalCache() {
        // 清理所有舊的本地快取，確保App只從CloudKit讀取資料
        UserDefaults.standard.removeObject(forKey: "CachedClients")
        print("🧹 已清理舊的本地快取，確保只從CloudKit讀取資料")
    }

    // MARK: - Helper Methods
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TWD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "NT$0"
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let clientDidChange = Notification.Name("clientDidChange")
    static let clientAdded = Notification.Name("clientAdded")
}
