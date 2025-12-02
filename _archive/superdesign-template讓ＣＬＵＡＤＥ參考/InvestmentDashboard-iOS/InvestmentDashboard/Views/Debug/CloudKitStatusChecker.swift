import SwiftUI
import CloudKit

// MARK: - 簡單的CloudKit狀態檢查器
// 用法：在Xcode中選擇這個檔案，點擊Preview或者創建一個臨時的ContentView來顯示
struct CloudKitStatusChecker: View {
    @StateObject private var dataManager = DataManager()
    @State private var statusInfo: [String] = []
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            List {
                Section("iCloud狀態") {
                    HStack {
                        Circle()
                            .fill(dataManager.isSignedInToiCloud ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Text("iCloud登入狀態")
                        Spacer()
                        Text(dataManager.isSignedInToiCloud ? "✅ 已登入" : "❌ 未登入")
                    }

                    HStack {
                        Circle()
                            .fill(dataManager.isOnline ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                        Text("網路狀態")
                        Spacer()
                        Text(dataManager.isOnline ? "✅ 線上" : "❌ 離線")
                    }
                }

                Section("資料統計") {
                    StatusRow(title: "客戶數量", count: dataManager.clients.count)
                    StatusRow(title: "月度資產記錄", count: dataManager.monthlyAssetRecords.count)
                    StatusRow(title: "債券記錄", count: dataManager.bonds.count)
                    StatusRow(title: "結構型商品", count: dataManager.structuredProducts.count)
                }

                if !statusInfo.isEmpty {
                    Section("詳細資訊") {
                        ForEach(statusInfo, id: \.self) { info in
                            Text(info)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("操作") {
                    Button("🔄 重新載入資料") {
                        Task {
                            isLoading = true
                            await dataManager.forceSyncFromCloudKit()
                            await updateStatusInfo()
                            isLoading = false
                        }
                    }
                    .disabled(isLoading)

                    Button("📊 檢查iCloud詳細狀態") {
                        Task {
                            await checkDetailediCloudStatus()
                        }
                    }

                    Button("🧪 建立測試客戶") {
                        Task {
                            await createTestClient()
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("CloudKit 狀態檢查")
            .onAppear {
                Task {
                    await updateStatusInfo()
                }
            }
            .refreshable {
                await dataManager.forceSyncFromCloudKit()
                await updateStatusInfo()
            }
        }
    }

    private func updateStatusInfo() async {
        var info: [String] = []

        await MainActor.run {
            info.append("Container: iCloud.com.owen.InvestmentDashboard")
            info.append("資料載入時間: \(Date().formatted())")

            if let latestClient = dataManager.clients.first {
                info.append("最新客戶: \(latestClient.name) (\(latestClient.createdDate.formatted()))")
            }

            if let latestRecord = dataManager.monthlyAssetRecords.first {
                info.append("最新資產記錄: \(latestRecord.date.formatted())")
            }

            statusInfo = info
        }
    }

    private func checkDetailediCloudStatus() async {
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
                statusInfo.append("詳細iCloud狀態: \(statusText)")
            }
        } catch {
            await MainActor.run {
                statusInfo.append("iCloud狀態檢查錯誤: \(error.localizedDescription)")
            }
        }
    }

    private func createTestClient() async {
        let testClient = Client(
            name: "測試客戶-\(Int(Date().timeIntervalSince1970))",
            email: "test@example.com"
        )

        do {
            try await dataManager.saveClient(testClient)
            await MainActor.run {
                statusInfo.append("✅ 測試客戶建立成功: \(testClient.name)")
            }
        } catch {
            await MainActor.run {
                statusInfo.append("❌ 建立測試客戶失敗: \(error.localizedDescription)")
            }
        }
    }
}

struct StatusRow: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(count)")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview (用於在Xcode中快速查看)
struct CloudKitStatusChecker_Previews: PreviewProvider {
    static var previews: some View {
        CloudKitStatusChecker()
    }
}

// MARK: - 快速測試用的ContentView (可以臨時使用)
struct TestCloudKitContentView: View {
    var body: some View {
        CloudKitStatusChecker()
    }
}