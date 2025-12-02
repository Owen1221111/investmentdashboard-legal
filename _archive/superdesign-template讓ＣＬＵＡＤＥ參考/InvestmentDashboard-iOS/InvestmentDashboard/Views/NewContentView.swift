import SwiftUI
import CloudKit

// MARK: - 新的ContentView (使用CloudKit DataManager)
struct NewContentView: View {
    @StateObject private var dataManager = DataManager()
    @StateObject private var clientViewModel = ClientViewModelNew()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 主要投資面板
            MainDashboardView()
                .environmentObject(clientViewModel)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("投資面板")
                }
                .tag(0)

            // 客戶管理
            ClientManagementView()
                .environmentObject(clientViewModel)
                .tabItem {
                    Image(systemName: "person.2")
                    Text("客戶管理")
                }
                .tag(1)

            // CloudKit狀態檢查
            CloudKitStatusView()
                .environmentObject(dataManager)
                .tabItem {
                    Image(systemName: "icloud")
                    Text("iCloud狀態")
                }
                .tag(2)
        }
        .onAppear {
            // App啟動時立即檢查iCloud狀態並同步
            Task {
                await clientViewModel.loadClients()
            }
        }
    }
}

// MARK: - 主要投資面板視圖
struct MainDashboardView: View {
    @EnvironmentObject var clientViewModel: ClientViewModelNew
    @State private var showingAddForm = false

    var body: some View {
        NavigationView {
            VStack {
                if clientViewModel.clients.isEmpty {
                    // 沒有客戶時的提示
                    VStack(spacing: 20) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("尚未有客戶資料")
                            .font(.title2)
                            .foregroundColor(.gray)

                        Text("請先新增客戶以開始使用")
                            .foregroundColor(.secondary)

                        Button("新增客戶") {
                            clientViewModel.showingAddClient = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    .padding()
                } else {
                    // 有客戶時顯示儀表板
                    DashboardContentView()
                        .environmentObject(clientViewModel)
                }
            }
            .navigationTitle("投資面板")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // iCloud狀態指示器
                    HStack {
                        Circle()
                            .fill(clientViewModel.isSignedInToiCloud ? Color.green : Color.red)
                            .frame(width: 8, height: 8)

                        Text(clientViewModel.isSignedInToiCloud ? "iCloud" : "離線")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新增資料") {
                        showingAddForm = true
                    }
                    .disabled(clientViewModel.selectedClient == nil)
                }
            }
            .sheet(isPresented: $showingAddForm) {
                AddDataFormView()
                    .environmentObject(clientViewModel)
            }
            .sheet(isPresented: $clientViewModel.showingAddClient) {
                AddClientFormView()
                    .environmentObject(clientViewModel)
            }
            .alert("錯誤", isPresented: .constant(clientViewModel.errorMessage != nil)) {
                Button("確定") {
                    clientViewModel.errorMessage = nil
                }
            } message: {
                Text(clientViewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - 儀表板內容視圖
struct DashboardContentView: View {
    @EnvironmentObject var clientViewModel: ClientViewModelNew

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 客戶選擇器
                ClientSelectorView()
                    .environmentObject(clientViewModel)

                // 總資產概覽
                AssetOverviewCard()
                    .environmentObject(clientViewModel)

                // 月度記錄列表
                MonthlyRecordsListView()
                    .environmentObject(clientViewModel)
            }
            .padding()
        }
        .refreshable {
            await clientViewModel.loadClients()
        }
    }
}

// MARK: - 客戶選擇器視圖
struct ClientSelectorView: View {
    @EnvironmentObject var clientViewModel: ClientViewModelNew

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("選擇客戶")
                .font(.headline)

            if clientViewModel.clients.isEmpty {
                Text("正在載入客戶資料...")
                    .foregroundColor(.secondary)
            } else {
                Picker("客戶", selection: $clientViewModel.selectedClient) {
                    ForEach(clientViewModel.clients, id: \.id) { client in
                        Text(client.name).tag(client as Client?)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - 資產概覽卡片
struct AssetOverviewCard: View {
    @EnvironmentObject var clientViewModel: ClientViewModelNew

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("資產概覽")
                .font(.headline)

            if let selectedClient = clientViewModel.selectedClient {
                VStack(spacing: 10) {
                    HStack {
                        Text("總資產：")
                        Spacer()
                        Text(clientViewModel.currentTotalAssets)
                            .fontWeight(.bold)
                    }

                    HStack {
                        Text("現金：")
                        Spacer()
                        Text(clientViewModel.currentCash)
                    }

                    HStack {
                        Text("總損益：")
                        Spacer()
                        Text(clientViewModel.currentTotalPnL)
                            .fontWeight(.semibold)
                    }
                }
            } else {
                Text("請選擇客戶以查看資產概覽")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// MARK: - 月度記錄列表視圖
struct MonthlyRecordsListView: View {
    @EnvironmentObject var clientViewModel: ClientViewModelNew

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("月度資產記錄")
                .font(.headline)

            if let selectedClient = clientViewModel.selectedClient {
                let records = clientViewModel.monthlyAssetRecords

                if records.isEmpty {
                    Text("尚無月度記錄")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(records.prefix(5), id: \.id) { record in
                        MonthlyRecordRow(record: record)
                    }
                }
            } else {
                Text("請選擇客戶以查看記錄")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// MARK: - 月度記錄行
struct MonthlyRecordRow: View {
    let record: MonthlyAssetRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                Spacer()
                Text(formatNumber(record.totalAssets))
                    .fontWeight(.bold)
            }

            HStack {
                Text("現金: \(formatNumber(record.cash))")
                Spacer()
                Text("美股: \(formatNumber(record.usStock))")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.3)),
            alignment: .bottom
        )
    }

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - 客戶管理視圖
struct ClientManagementView: View {
    @EnvironmentObject var clientViewModel: ClientViewModelNew

    var body: some View {
        NavigationView {
            List {
                ForEach(clientViewModel.clients, id: \.id) { client in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(client.name)
                            .font(.headline)
                        Text(client.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("建立於 \(client.createdDate.formatted())")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete(perform: deleteClients)
            }
            .navigationTitle("客戶管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新增客戶") {
                        clientViewModel.showingAddClient = true
                    }
                }
            }
            .sheet(isPresented: $clientViewModel.showingAddClient) {
                AddClientFormView()
                    .environmentObject(clientViewModel)
            }
            .refreshable {
                await clientViewModel.loadClients()
            }
        }
    }

    private func deleteClients(offsets: IndexSet) {
        for index in offsets {
            let client = clientViewModel.clients[index]
            Task {
                await clientViewModel.deleteClient(client)
            }
        }
    }
}

// MARK: - CloudKit狀態視圖
struct CloudKitStatusView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var statusInfo: [String] = []

    var body: some View {
        NavigationView {
            List {
                Section("iCloud狀態") {
                    StatusRowView(
                        title: "iCloud登入",
                        value: dataManager.isSignedInToiCloud ? "✅ 已登入" : "❌ 未登入",
                        color: dataManager.isSignedInToiCloud ? .green : .red
                    )

                    StatusRowView(
                        title: "網路狀態",
                        value: dataManager.isOnline ? "✅ 線上" : "❌ 離線",
                        color: dataManager.isOnline ? .green : .orange
                    )

                    StatusRowView(
                        title: "同步狀態",
                        value: dataManager.statusDescription,
                        color: .blue
                    )
                }

                Section("資料統計") {
                    StatusRowView(title: "客戶", value: "\(dataManager.clients.count)", color: .primary)
                    StatusRowView(title: "月度記錄", value: "\(dataManager.monthlyAssetRecords.count)", color: .primary)
                    StatusRowView(title: "債券", value: "\(dataManager.bonds.count)", color: .primary)
                    StatusRowView(title: "結構型商品", value: "\(dataManager.structuredProducts.count)", color: .primary)
                }

                Section("操作") {
                    Button("🔄 手動同步") {
                        Task {
                            await dataManager.forceSync()
                        }
                    }
                }
            }
            .navigationTitle("iCloud狀態")
            .refreshable {
                await dataManager.forceSync()
            }
        }
    }
}

struct StatusRowView: View {
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

// MARK: - 新增客戶表單
struct AddClientFormView: View {
    @EnvironmentObject var clientViewModel: ClientViewModelNew
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Form {
                Section("客戶資訊") {
                    TextField("姓名", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("新增客戶")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        Task {
                            isLoading = true
                            await clientViewModel.addClient(name: name, email: email)
                            isLoading = false
                            if clientViewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
    }
}

// MARK: - 新增資料表單
struct AddDataFormView: View {
    @EnvironmentObject var clientViewModel: ClientViewModelNew
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var cash = ""
    @State private var usStock = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Form {
                Section("基本資訊") {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }

                Section("資產明細") {
                    TextField("現金", text: $cash)
                        .keyboardType(.decimalPad)
                    TextField("美股", text: $usStock)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("新增月度記錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        Task {
                            await saveRecord()
                        }
                    }
                    .disabled(isLoading)
                }
            }
        }
    }

    private func saveRecord() async {
        guard let clientID = clientViewModel.selectedClient?.id else { return }

        isLoading = true

        let record = MonthlyAssetRecord(
            clientID: clientID,
            date: date,
            cash: Double(cash) ?? 0,
            usStock: Double(usStock) ?? 0,
            regularInvestment: 0,
            bonds: 0,
            structuredProducts: 0,
            twStock: 0,
            twStockConverted: 0,
            confirmedInterest: 0,
            deposit: 0,
            cashCost: 0,
            stockCost: 0,
            bondCost: 0,
            otherCost: 0,
            notes: ""
        )

        await clientViewModel.addMonthlyAssetRecord(record)
        isLoading = false

        if clientViewModel.errorMessage == nil {
            dismiss()
        }
    }
}

// MARK: - Preview
struct NewContentView_Previews: PreviewProvider {
    static var previews: some View {
        NewContentView()
    }
}