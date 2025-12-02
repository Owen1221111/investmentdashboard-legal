import SwiftUI

// MARK: - Debug版本的ContentView
// 這個版本包含了CloudKit Debug功能，方便開發和測試
struct DebugContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingDebugView = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 主要應用界面
            MainAppView()
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("投資儀表板")
                }
                .tag(0)

            // CloudKit Debug界面
            CloudKitDebugView()
                .tabItem {
                    Image(systemName: "ladybug")
                    Text("Debug")
                }
                .tag(1)
        }
        .environmentObject(dataManager)
    }
}

// MARK: - 主要應用視圖 (原本的ContentView功能)
struct MainAppView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedClient: Client?
    @State private var showingAddClientForm = false
    @State private var showingAddDataForm = false

    var body: some View {
        NavigationView {
            VStack {
                // 客戶選擇區域
                if dataManager.clients.isEmpty {
                    EmptyClientView(showingAddClientForm: $showingAddClientForm)
                } else {
                    ClientSelectionView(
                        clients: dataManager.clients,
                        selectedClient: $selectedClient,
                        showingAddClientForm: $showingAddClientForm
                    )

                    if let client = selectedClient {
                        ClientDataView(client: client, showingAddDataForm: $showingAddDataForm)
                    }
                }

                Spacer()
            }
            .navigationTitle("投資儀表板")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新增客戶") {
                        showingAddClientForm = true
                    }
                }

                if selectedClient != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("新增資料") {
                            showingAddDataForm = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddClientForm) {
            AddClientFormView()
        }
        .sheet(isPresented: $showingAddDataForm) {
            if let client = selectedClient {
                AddDataFormView(client: client)
            }
        }
        .onAppear {
            if let firstClient = dataManager.clients.first {
                selectedClient = firstClient
            }
        }
    }
}

// MARK: - 空客戶狀態視圖
struct EmptyClientView: View {
    @Binding var showingAddClientForm: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("尚未有客戶資料")
                .font(.title2)
                .foregroundColor(.gray)

            Text("請先新增客戶以開始使用")
                .font(.body)
                .foregroundColor(.secondary)

            Button("新增第一個客戶") {
                showingAddClientForm = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - 客戶選擇視圖
struct ClientSelectionView: View {
    let clients: [Client]
    @Binding var selectedClient: Client?
    @Binding var showingAddClientForm: Bool

    var body: some View {
        VStack {
            Text("選擇客戶")
                .font(.headline)
                .padding(.top)

            Picker("客戶", selection: $selectedClient) {
                ForEach(clients) { client in
                    Text(client.name).tag(client as Client?)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
        }
    }
}

// MARK: - 客戶資料視圖
struct ClientDataView: View {
    let client: Client
    @Binding var showingAddDataForm: Bool
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(client.name) 的資料")
                .font(.title2)
                .padding(.horizontal)

            // 月度資產記錄
            MonthlyAssetSectionView(
                client: client,
                records: dataManager.monthlyAssetRecords(for: client.id)
            )

            // 債券記錄
            BondSectionView(
                client: client,
                bonds: dataManager.bonds(for: client.id)
            )

            // 結構型商品記錄
            StructuredProductSectionView(
                client: client,
                products: dataManager.structuredProducts(for: client.id)
            )
        }
    }
}

// MARK: - 月度資產區塊視圖
struct MonthlyAssetSectionView: View {
    let client: Client
    let records: [MonthlyAssetRecord]

    var body: some View {
        VStack(alignment: .leading) {
            Text("月度資產記錄 (\(records.count))")
                .font(.headline)
                .padding(.horizontal)

            if records.isEmpty {
                Text("尚無資產記錄")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(records.prefix(5)) { record in
                            MonthlyAssetCardView(record: record)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - 月度資產卡片視圖
struct MonthlyAssetCardView: View {
    let record: MonthlyAssetRecord

    var totalAssets: Double {
        record.cash + record.usStock + record.bonds + record.twStock + record.structuredProducts
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)

            Text("總資產")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(totalAssets.formatted(.currency(code: "TWD")))
                .font(.headline)
                .fontWeight(.bold)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("現金: \(record.cash.formatted(.currency(code: "TWD")))")
                    Text("美股: \(record.usStock.formatted(.currency(code: "TWD")))")
                    Text("債券: \(record.bonds.formatted(.currency(code: "TWD")))")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .frame(width: 180)
    }
}

// MARK: - 債券區塊視圖
struct BondSectionView: View {
    let client: Client
    let bonds: [Bond]

    var body: some View {
        VStack(alignment: .leading) {
            Text("債券記錄 (\(bonds.count))")
                .font(.headline)
                .padding(.horizontal)

            if bonds.isEmpty {
                Text("尚無債券記錄")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(bonds.prefix(3)) { bond in
                    BondRowView(bond: bond)
                        .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - 債券行視圖
struct BondRowView: View {
    let bond: Bond

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bond.bondName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("購入: \(bond.purchaseDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(bond.purchaseAmount.formatted(.currency(code: "TWD")))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(bond.couponRate, specifier: "%.2f")%")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

// MARK: - 結構型商品區塊視圖
struct StructuredProductSectionView: View {
    let client: Client
    let products: [StructuredProduct]

    var body: some View {
        VStack(alignment: .leading) {
            Text("結構型商品 (\(products.count))")
                .font(.headline)
                .padding(.horizontal)

            if products.isEmpty {
                Text("尚無結構型商品記錄")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(products.prefix(3)) { product in
                    StructuredProductRowView(product: product)
                        .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - 結構型商品行視圖
struct StructuredProductRowView: View {
    let product: StructuredProduct

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.target)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("狀態: \(product.status.rawValue)")
                    .font(.caption)
                    .foregroundColor(product.status == .active ? .green : .orange)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(product.tradeAmount.formatted(.currency(code: "TWD")))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(product.yield, specifier: "%.2f")%")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

// MARK: - 新增客戶表單視圖
struct AddClientFormView: View {
    @EnvironmentObject var dataManager: DataManager
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
                            await saveClient()
                        }
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
        }
    }

    private func saveClient() async {
        isLoading = true

        let client = Client(name: name, email: email)

        do {
            try await dataManager.saveClient(client)
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("儲存客戶失敗: \(error)")
        }

        isLoading = false
    }
}

// MARK: - 新增資料表單視圖
struct AddDataFormView: View {
    let client: Client
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDataType = 0 // 0: 月度資產, 1: 債券, 2: 結構型商品

    var body: some View {
        NavigationView {
            VStack {
                Picker("資料類型", selection: $selectedDataType) {
                    Text("月度資產").tag(0)
                    Text("債券").tag(1)
                    Text("結構型商品").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                switch selectedDataType {
                case 0:
                    AddMonthlyAssetFormView(client: client)
                case 1:
                    AddBondFormView(client: client)
                case 2:
                    AddStructuredProductFormView(client: client)
                default:
                    EmptyView()
                }

                Spacer()
            }
            .navigationTitle("新增資料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 因為這些表單比較複雜，我暫時創建簡化版本
struct AddMonthlyAssetFormView: View {
    let client: Client

    var body: some View {
        Text("月度資產表單 (待實作)")
            .foregroundColor(.secondary)
    }
}

struct AddBondFormView: View {
    let client: Client

    var body: some View {
        Text("債券表單 (待實作)")
            .foregroundColor(.secondary)
    }
}

struct AddStructuredProductFormView: View {
    let client: Client

    var body: some View {
        Text("結構型商品表單 (待實作)")
            .foregroundColor(.secondary)
    }
}

// MARK: - Preview
struct DebugContentView_Previews: PreviewProvider {
    static var previews: some View {
        DebugContentView()
            .environmentObject(DataManager())
    }
}