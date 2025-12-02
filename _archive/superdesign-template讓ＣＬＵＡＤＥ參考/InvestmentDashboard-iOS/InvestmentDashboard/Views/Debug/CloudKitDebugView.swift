import SwiftUI
import CloudKit

// MARK: - CloudKit Debug View
struct CloudKitDebugView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0
    @State private var debugInfo: [String] = []
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var recordCounts: RecordCounts = RecordCounts()

    var body: some View {
        NavigationView {
            VStack {
                // Status Header
                StatusHeaderView(dataManager: dataManager, recordCounts: recordCounts)

                // Tab Selection
                Picker("Debug Options", selection: $selectedTab) {
                    Text("狀態").tag(0)
                    Text("客戶").tag(1)
                    Text("資產記錄").tag(2)
                    Text("債券").tag(3)
                    Text("結構型商品").tag(4)
                    Text("操作").tag(5)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Tab Content
                TabView(selection: $selectedTab) {
                    StatusTabView(debugInfo: debugInfo)
                        .tag(0)

                    ClientsTabView(clients: dataManager.clients)
                        .tag(1)

                    MonthlyRecordsTabView(records: dataManager.monthlyAssetRecords)
                        .tag(2)

                    BondsTabView(bonds: dataManager.bonds)
                        .tag(3)

                    StructuredProductsTabView(products: dataManager.structuredProducts)
                        .tag(4)

                    OperationsTabView(
                        dataManager: dataManager,
                        isLoading: $isLoading,
                        showingAlert: $showingAlert,
                        alertMessage: $alertMessage
                    )
                    .tag(5)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("CloudKit Debug")
            .onAppear {
                refreshDebugInfo()
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Debug Info"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func refreshDebugInfo() {
        Task {
            await updateRecordCounts()
            await updateDebugInfo()
        }
    }

    @MainActor
    private func updateRecordCounts() async {
        recordCounts = RecordCounts(
            clients: dataManager.clients.count,
            monthlyRecords: dataManager.monthlyAssetRecords.count,
            bonds: dataManager.bonds.count,
            structuredProducts: dataManager.structuredProducts.count
        )
    }

    @MainActor
    private func updateDebugInfo() async {
        var info: [String] = []

        // CloudKit 基本資訊
        info.append("=== CloudKit 狀態 ===")
        info.append("Container ID: iCloud.com.owen.InvestmentDashboard")
        info.append("iCloud 登入狀態: \(dataManager.isSignedInToiCloud ? "✅ 已登入" : "❌ 未登入")")
        info.append("網路狀態: \(dataManager.isOnline ? "✅ 線上" : "❌ 離線")")
        info.append("")

        // 資料統計
        info.append("=== 資料統計 ===")
        info.append("客戶數量: \(dataManager.clients.count)")
        info.append("月度資產記錄: \(dataManager.monthlyAssetRecords.count)")
        info.append("債券記錄: \(dataManager.bonds.count)")
        info.append("結構型商品: \(dataManager.structuredProducts.count)")
        info.append("")

        // 最新記錄時間
        info.append("=== 最新記錄時間 ===")
        if let latestClient = dataManager.clients.first {
            info.append("最新客戶: \(latestClient.createdDate.formatted())")
        }
        if let latestRecord = dataManager.monthlyAssetRecords.first {
            info.append("最新資產記錄: \(latestRecord.date.formatted())")
        }
        if let latestBond = dataManager.bonds.first {
            info.append("最新債券: \(latestBond.purchaseDate.formatted())")
        }
        if let latestProduct = dataManager.structuredProducts.first {
            info.append("最新結構型商品: \(latestProduct.tradeDate.formatted())")
        }

        debugInfo = info
    }
}

// MARK: - Record Counts
struct RecordCounts {
    var clients: Int = 0
    var monthlyRecords: Int = 0
    var bonds: Int = 0
    var structuredProducts: Int = 0
}

// MARK: - Status Header View
struct StatusHeaderView: View {
    let dataManager: DataManager
    let recordCounts: RecordCounts

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                StatusIndicator(
                    title: "iCloud",
                    isActive: dataManager.isSignedInToiCloud,
                    color: dataManager.isSignedInToiCloud ? .green : .red
                )

                StatusIndicator(
                    title: "網路",
                    isActive: dataManager.isOnline,
                    color: dataManager.isOnline ? .green : .orange
                )

                Spacer()
            }

            HStack {
                DataCountBadge(title: "客戶", count: recordCounts.clients)
                DataCountBadge(title: "資產", count: recordCounts.monthlyRecords)
                DataCountBadge(title: "債券", count: recordCounts.bonds)
                DataCountBadge(title: "商品", count: recordCounts.structuredProducts)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let title: String
    let isActive: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption)
                .foregroundColor(color)
        }
    }
}

// MARK: - Data Count Badge
struct DataCountBadge: View {
    let title: String
    let count: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Status Tab View
struct StatusTabView: View {
    let debugInfo: [String]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(debugInfo, id: \.self) { line in
                    Text(line)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(line.hasPrefix("===") ? .primary : .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }
}

// MARK: - Clients Tab View
struct ClientsTabView: View {
    let clients: [Client]

    var body: some View {
        List(clients) { client in
            VStack(alignment: .leading, spacing: 4) {
                Text(client.name)
                    .font(.headline)
                Text("ID: \(client.id.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Email: \(client.email)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("建立時間: \(client.createdDate.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Monthly Records Tab View
struct MonthlyRecordsTabView: View {
    let records: [MonthlyAssetRecord]

    var body: some View {
        List(records) { record in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("ID: \(record.id.uuidString.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(record.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("客戶ID: \(record.clientID.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    VStack(alignment: .leading) {
                        Text("現金: \(record.cash, specifier: "%.0f")")
                        Text("美股: \(record.usStock, specifier: "%.0f")")
                        Text("債券: \(record.bonds, specifier: "%.0f")")
                    }
                    .font(.caption)

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("台股: \(record.twStock, specifier: "%.0f")")
                        Text("定投: \(record.regularInvestment, specifier: "%.0f")")
                        Text("結構: \(record.structuredProducts, specifier: "%.0f")")
                    }
                    .font(.caption)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Bonds Tab View
struct BondsTabView: View {
    let bonds: [Bond]

    var body: some View {
        List(bonds) { bond in
            VStack(alignment: .leading, spacing: 4) {
                Text(bond.bondName)
                    .font(.headline)
                Text("ID: \(bond.id.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("客戶ID: \(bond.clientID.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("購入日期: \(bond.purchaseDate.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Text("票面利率: \(bond.couponRate, specifier: "%.2f")%")
                    Spacer()
                    Text("購入金額: \(bond.purchaseAmount, specifier: "%.0f")")
                }
                .font(.caption)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Structured Products Tab View
struct StructuredProductsTabView: View {
    let products: [StructuredProduct]

    var body: some View {
        List(products) { product in
            VStack(alignment: .leading, spacing: 4) {
                Text(product.target)
                    .font(.headline)
                Text("ID: \(product.id.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("客戶ID: \(product.clientID.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("交易日期: \(product.tradeDate.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Text("狀態: \(product.status.rawValue)")
                    Spacer()
                    Text("交易金額: \(product.tradeAmount, specifier: "%.0f")")
                }
                .font(.caption)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Operations Tab View
struct OperationsTabView: View {
    let dataManager: DataManager
    @Binding var isLoading: Bool
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String

    var body: some View {
        VStack(spacing: 20) {
            Button("🔄 強制同步") {
                Task {
                    isLoading = true
                    await dataManager.forceSyncFromCloudKit()
                    isLoading = false
                    alertMessage = "同步完成"
                    showingAlert = true
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Button("📊 檢查iCloud狀態") {
                Task {
                    await checkiCloudStatus()
                }
            }
            .buttonStyle(.bordered)

            Button("🧪 建立測試客戶") {
                Task {
                    await createTestClient()
                }
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)

            Button("🗑️ 清除所有測試資料 (危險!)") {
                alertMessage = "此操作將刪除所有名稱包含'測試'的資料，確定要繼續嗎？"
                showingAlert = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .disabled(isLoading)

            if isLoading {
                ProgressView("處理中...")
                    .padding()
            }

            Spacer()
        }
        .padding()
    }

    private func checkiCloudStatus() async {
        let container = CKContainer(identifier: "iCloud.com.owen.InvestmentDashboard")

        do {
            let status = try await container.accountStatus()
            let statusText = switch status {
            case .available: "✅ 可用"
            case .noAccount: "❌ 未登入iCloud"
            case .restricted: "⚠️ 受限制"
            case .couldNotDetermine: "❓ 無法確定"
            case .temporarilyUnavailable: "⏳ 暫時不可用"
            @unknown default: "❓ 未知狀態"
            }

            await MainActor.run {
                alertMessage = "iCloud帳號狀態: \(statusText)"
                showingAlert = true
            }
        } catch {
            await MainActor.run {
                alertMessage = "檢查iCloud狀態失敗: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    private func createTestClient() async {
        let testClient = Client(
            name: "測試客戶-\(Date().timeIntervalSince1970)",
            email: "test@example.com"
        )

        do {
            try await dataManager.saveClient(testClient)
            await MainActor.run {
                alertMessage = "測試客戶建立成功: \(testClient.name)"
                showingAlert = true
            }
        } catch {
            await MainActor.run {
                alertMessage = "建立測試客戶失敗: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

// MARK: - Preview
struct CloudKitDebugView_Previews: PreviewProvider {
    static var previews: some View {
        CloudKitDebugView()
            .environmentObject(DataManager())
    }
}