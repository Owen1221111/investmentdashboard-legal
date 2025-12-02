import SwiftUI
import CloudKit

// MARK: - iCloud 同步測試視圖
struct iCloudTestView: View {
    @StateObject private var dataManager = DataManager()
    @State private var testClient: Client?
    @State private var isLoading = false
    @State private var statusMessage = ""
    @State private var testResults: [String] = []

    var body: some View {
        NavigationView {
            List {
                Section("iCloud 狀態") {
                    StatusRow(
                        title: "iCloud 登入狀態",
                        value: dataManager.isSignedInToiCloud ? "✅ 已登入" : "❌ 未登入",
                        color: dataManager.isSignedInToiCloud ? .green : .red
                    )

                    StatusRow(
                        title: "網路狀態",
                        value: dataManager.isOnline ? "✅ 線上" : "❌ 離線",
                        color: dataManager.isOnline ? .green : .orange
                    )

                    StatusRow(
                        title: "同步狀態",
                        value: dataManager.statusDescription,
                        color: .blue
                    )
                }

                Section("資料統計") {
                    StatusRow(title: "客戶數量", value: "\(dataManager.clients.count)", color: .primary)
                    StatusRow(title: "月度記錄", value: "\(dataManager.monthlyAssetRecords.count)", color: .primary)
                    StatusRow(title: "債券記錄", value: "\(dataManager.bonds.count)", color: .primary)
                    StatusRow(title: "結構型商品", value: "\(dataManager.structuredProducts.count)", color: .primary)
                }

                Section("測試操作") {
                    Button("🧪 創建測試客戶") {
                        Task {
                            await createTestClient()
                        }
                    }
                    .disabled(isLoading || !dataManager.isSignedInToiCloud)

                    Button("📊 添加測試資產記錄") {
                        Task {
                            await createTestAssetRecord()
                        }
                    }
                    .disabled(isLoading || testClient == nil || !dataManager.isSignedInToiCloud)

                    Button("🏦 添加測試債券") {
                        Task {
                            await createTestBond()
                        }
                    }
                    .disabled(isLoading || testClient == nil || !dataManager.isSignedInToiCloud)

                    Button("🔄 手動同步") {
                        Task {
                            await manualSync()
                        }
                    }
                    .disabled(isLoading)

                    Button("🗑️ 清除測試資料") {
                        Task {
                            await clearTestData()
                        }
                    }
                    .disabled(isLoading || !dataManager.isSignedInToiCloud)
                }

                if !testResults.isEmpty {
                    Section("測試結果") {
                        ForEach(testResults, id: \.self) { result in
                            Text(result)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if !statusMessage.isEmpty {
                    Section("狀態訊息") {
                        Text(statusMessage)
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("iCloud 同步測試")
            .onAppear {
                checkExistingTestClient()
            }
            .refreshable {
                await manualSync()
            }
        }
    }

    // MARK: - Test Methods
    private func createTestClient() async {
        isLoading = true
        statusMessage = "創建測試客戶中..."

        let client = Client(
            name: "測試客戶-\(Date().timeIntervalSince1970)",
            email: "test@example.com"
        )

        do {
            try await dataManager.saveClient(client)
            testClient = client
            await MainActor.run {
                testResults.append("✅ 成功創建測試客戶: \(client.name)")
                statusMessage = "測試客戶創建成功"
            }
        } catch {
            await MainActor.run {
                testResults.append("❌ 創建測試客戶失敗: \(error.localizedDescription)")
                statusMessage = "測試客戶創建失敗"
            }
        }

        isLoading = false
    }

    private func createTestAssetRecord() async {
        guard let client = testClient else { return }

        isLoading = true
        statusMessage = "創建測試資產記錄中..."

        let record = MonthlyAssetRecord(
            clientID: client.id,
            date: Date(),
            cash: 500000,
            usStock: 1000000,
            regularInvestment: 300000,
            bonds: 800000,
            structuredProducts: 200000,
            twStock: 400000,
            twStockConverted: 400000,
            confirmedInterest: 15000,
            deposit: 2000000,
            cashCost: 500000,
            stockCost: 950000,
            bondCost: 780000,
            otherCost: 50000,
            notes: "測試記錄"
        )

        do {
            try await dataManager.saveMonthlyAssetRecord(record)
            await MainActor.run {
                testResults.append("✅ 成功創建測試資產記錄")
                statusMessage = "測試資產記錄創建成功"
            }
        } catch {
            await MainActor.run {
                testResults.append("❌ 創建測試資產記錄失敗: \(error.localizedDescription)")
                statusMessage = "測試資產記錄創建失敗"
            }
        }

        isLoading = false
    }

    private func createTestBond() async {
        guard let client = testClient else { return }

        isLoading = true
        statusMessage = "創建測試債券中..."

        let bond = Bond(
            clientID: client.id,
            purchaseDate: Date(),
            bondName: "測試債券2025",
            couponRate: 3.0,
            yieldRate: 3.2,
            purchasePrice: 98.5,
            purchaseAmount: 985000,
            holdingFaceValue: 1000000,
            tradeAmount: 985000,
            currentValue: 1020000,
            receivedInterest: 15000,
            dividendMonths: "6,12",
            singleDividend: 15000,
            annualDividend: 30000
        )

        do {
            try await dataManager.saveBond(bond)
            await MainActor.run {
                testResults.append("✅ 成功創建測試債券")
                statusMessage = "測試債券創建成功"
            }
        } catch {
            await MainActor.run {
                testResults.append("❌ 創建測試債券失敗: \(error.localizedDescription)")
                statusMessage = "測試債券創建失敗"
            }
        }

        isLoading = false
    }

    private func manualSync() async {
        isLoading = true
        statusMessage = "手動同步中..."

        await dataManager.forceSync()

        await MainActor.run {
            testResults.append("🔄 手動同步完成 - \(Date().formatted())")
            statusMessage = "同步完成"
        }

        isLoading = false
    }

    private func clearTestData() async {
        guard let client = testClient else { return }

        isLoading = true
        statusMessage = "清除測試資料中..."

        do {
            // 刪除相關的資產記錄
            let clientRecords = dataManager.monthlyAssetRecords(for: client.id)
            for record in clientRecords {
                try await dataManager.deleteMonthlyAssetRecord(record)
            }

            // 刪除相關的債券
            let clientBonds = dataManager.bonds(for: client.id)
            for bond in clientBonds {
                try await dataManager.deleteBond(bond)
            }

            // 刪除客戶
            try await dataManager.deleteClient(client)

            await MainActor.run {
                testClient = nil
                testResults.append("🗑️ 已清除所有測試資料")
                statusMessage = "測試資料清除完成"
            }
        } catch {
            await MainActor.run {
                testResults.append("❌ 清除測試資料失敗: \(error.localizedDescription)")
                statusMessage = "清除測試資料失敗"
            }
        }

        isLoading = false
    }

    private func checkExistingTestClient() {
        // 檢查是否已有測試客戶
        if let existingTestClient = dataManager.clients.first(where: { $0.name.contains("測試客戶") }) {
            testClient = existingTestClient
            testResults.append("📋 找到現有測試客戶: \(existingTestClient.name)")
        }
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview
struct iCloudTestView_Previews: PreviewProvider {
    static var previews: some View {
        iCloudTestView()
    }
}