import SwiftUI
import CoreData

struct ClientDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let client: Client?

    @State private var showingEditClient = false
    @State private var selectedPeriod = "ALL"
    @State private var selectedCurrency = "美金" // 新增：選擇的幣別
    @State private var showingAddMonthlyData = false
    @State private var monthlyAssetData: [[String]] = [] // 保留用於向後相容，但不再使用

    // 走勢圖互動
    @State private var selectedDataPointIndex: Int? = nil
    @State private var selectedDataPointValue: Double? = nil
    @State private var selectedDataPointDate: String? = nil
    @State private var hideDataPointWorkItem: DispatchWorkItem? = nil

    // 債券每月配息懸停互動
    @State private var hoveredMonth: Int? = nil

    // 債券配息幣別切換
    @State private var selectedBondCurrencyIndex: Int = 0

    // 美股持倉明細彈出視圖控制
    @State private var showingUSStockInventory = false

    // 台股持倉明細彈出視圖控制
    @State private var showingTWStockInventory = false

    // 定期定額明細彈出視圖控制
    @State private var showingRegularInvestmentInventory = false

    // 債券明細彈出視圖控制
    @State private var showingCorporateBondsDetail = false

    // 結構型商品庫存彈出視圖控制
    @State private var showingStructuredInventory = false

    // 股價更新刷新觸發器
    @State private var refreshTrigger = UUID()

    // 債券編輯模式和批次更新資料（⭐️ 使用 UserDefaults 實現跨視圖同步）
    @State private var bondEditModeRawValue: String = BondEditMode.individualUpdate.rawValue
    @State private var bondsTotalValue: String = ""
    @State private var bondsTotalInterest: String = ""

    // 匯率資料（全域共用，保持 @AppStorage）
    @AppStorage("exchangeRate") private var exchangeRate: String = ""
    @AppStorage("eurRate") private var eurRate: String = ""
    @AppStorage("jpyRate") private var jpyRate: String = ""
    @AppStorage("gbpRate") private var gbpRate: String = ""
    @AppStorage("cnyRate") private var cnyRate: String = ""
    @AppStorage("audRate") private var audRate: String = ""
    @AppStorage("cadRate") private var cadRate: String = ""
    @AppStorage("chfRate") private var chfRate: String = ""
    @AppStorage("hkdRate") private var hkdRate: String = ""
    @AppStorage("sgdRate") private var sgdRate: String = ""

    private var bondEditMode: BondEditMode {
        get { BondEditMode(rawValue: bondEditModeRawValue) ?? .batchUpdate }
        set { bondEditModeRawValue = newValue.rawValue }
    }

    private var bondEditModeBinding: Binding<BondEditMode> {
        Binding(
            get: { self.bondEditMode },
            set: { newValue in
                self.bondEditModeRawValue = newValue.rawValue
                // 同步到 UserDefaults
                self.saveClientSpecificBondData()
                // 發送通知，通知其他視圖模式已變更
                NotificationCenter.default.post(name: .init("BondEditModeDidChange"), object: nil)
                print("✅ 儀表板：債券編輯模式已變更為：\(newValue.rawValue)")
            }
        )
    }

    // MARK: - 客戶專屬儲存鍵值
    private var clientSpecificBondEditModeKey: String {
        guard let clientID = client?.objectID.uriRepresentation().absoluteString else {
            return "bondEditMode_default"
        }
        return "bondEditMode_\(clientID)"
    }

    private var clientSpecificBondsTotalValueKey: String {
        guard let clientID = client?.objectID.uriRepresentation().absoluteString else {
            return "bondsTotalValue_default"
        }
        return "bondsTotalValue_\(clientID)"
    }

    private var clientSpecificBondsTotalInterestKey: String {
        guard let clientID = client?.objectID.uriRepresentation().absoluteString else {
            return "bondsTotalInterest_default"
        }
        return "bondsTotalInterest_\(clientID)"
    }

    // MARK: - 客戶專屬資料載入與儲存
    private func loadClientSpecificBondData() {
        bondEditModeRawValue = UserDefaults.standard.string(forKey: clientSpecificBondEditModeKey) ?? BondEditMode.individualUpdate.rawValue
        bondsTotalValue = UserDefaults.standard.string(forKey: clientSpecificBondsTotalValueKey) ?? ""
        bondsTotalInterest = UserDefaults.standard.string(forKey: clientSpecificBondsTotalInterestKey) ?? ""
    }

    private func saveClientSpecificBondData() {
        UserDefaults.standard.set(bondEditModeRawValue, forKey: clientSpecificBondEditModeKey)
        UserDefaults.standard.set(bondsTotalValue, forKey: clientSpecificBondsTotalValueKey)
        UserDefaults.standard.set(bondsTotalInterest, forKey: clientSpecificBondsTotalInterestKey)
    }

    // FetchRequest 取得當前客戶的月度資產（按日期降序）
    @FetchRequest private var monthlyAssets: FetchedResults<MonthlyAsset>

    // FetchRequest 取得當前客戶的公司債（排除橘色行）
    @FetchRequest private var corporateBonds: FetchedResults<CorporateBond>

    // FetchRequest 取得當前客戶的債券更新記錄
    @FetchRequest private var bondUpdateRecords: FetchedResults<BondUpdateRecord>

    // FetchRequest 取得當前客戶的美股
    @FetchRequest private var usStocks: FetchedResults<USStock>

    // FetchRequest 取得當前客戶的結構型商品
    @FetchRequest private var structuredProducts: FetchedResults<StructuredProduct>

    init(client: Client?) {
        self.client = client

        if let client = client {
            _monthlyAssets = FetchRequest<MonthlyAsset>(
                sortDescriptors: [NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@ AND isLiveSnapshot == NO", client),
                animation: .default
            )
            _corporateBonds = FetchRequest<CorporateBond>(
                sortDescriptors: [NSSortDescriptor(keyPath: \CorporateBond.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@ AND bondName != %@", client, "__BATCH_UPDATE__"),
                animation: .default
            )
            _bondUpdateRecords = FetchRequest<BondUpdateRecord>(
                sortDescriptors: [NSSortDescriptor(keyPath: \BondUpdateRecord.recordDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client),
                animation: .default
            )
            _usStocks = FetchRequest<USStock>(
                sortDescriptors: [NSSortDescriptor(keyPath: \USStock.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client),
                animation: .default
            )
            _structuredProducts = FetchRequest<StructuredProduct>(
                sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@ AND isExited == NO", client),
                animation: .default
            )
        } else {
            _monthlyAssets = FetchRequest<MonthlyAsset>(
                sortDescriptors: [NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
            _corporateBonds = FetchRequest<CorporateBond>(
                sortDescriptors: [NSSortDescriptor(keyPath: \CorporateBond.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
            _bondUpdateRecords = FetchRequest<BondUpdateRecord>(
                sortDescriptors: [NSSortDescriptor(keyPath: \BondUpdateRecord.recordDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
            _usStocks = FetchRequest<USStock>(
                sortDescriptors: [NSSortDescriptor(keyPath: \USStock.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
            _structuredProducts = FetchRequest<StructuredProduct>(
                sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }

    // 債券配息可用幣別（USD 優先）
    private var availableBondCurrencies: [String] {
        let currencies = Array(Set(corporateBonds.compactMap { $0.currency ?? "USD" }))
        // USD 排第一，其他按字母排序
        return currencies.sorted { c1, c2 in
            if c1 == "USD" { return true }
            if c2 == "USD" { return false }
            return c1 < c2
        }
    }

    // 當前選中的債券配息幣別
    private var selectedBondCurrency: String {
        guard selectedBondCurrencyIndex < availableBondCurrencies.count else {
            return availableBondCurrencies.first ?? "USD"
        }
        return availableBondCurrencies[selectedBondCurrencyIndex]
    }

    // 幣別顏色對應
    private func bondCurrencyColor(for currency: String) -> Color {
        switch currency {
        case "USD": return Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0))
        case "TWD": return .blue
        case "EUR": return .purple
        case "JPY": return .orange
        case "GBP": return .pink
        case "CNY": return .red
        case "AUD": return .yellow
        case "CAD": return .mint
        case "CHF": return .indigo
        case "HKD": return .cyan
        case "SGD": return .teal
        default: return Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0))
        }
    }

    var body: some View {
        if let client = client {
            TabView {
                // 第一頁：原始的投資儀表板
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 20) {
                            // 根據螢幕寬度決定佈局
                            if geometry.size.width > 600 {
                                iPadLayout
                            } else {
                                iPhoneLayout
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .background(Color(.systemGroupedBackground))
                }
                .sheet(isPresented: $showingUSStockInventory) {
                    USStockInventoryView(client: client)
                        .environment(\.managedObjectContext, viewContext)
                }
                .sheet(isPresented: $showingTWStockInventory) {
                    TWStockInventoryView(client: client)
                        .environment(\.managedObjectContext, viewContext)
                }
                .sheet(isPresented: $showingRegularInvestmentInventory) {
                    RegularInvestmentInventoryView(client: client)
                        .environment(\.managedObjectContext, viewContext)
                }
                .sheet(isPresented: $showingStructuredInventory) {
                    CrossClientStructuredProductView(client: client)
                        .environment(\.managedObjectContext, viewContext)
                }
                .sheet(isPresented: $showingCorporateBondsDetail, onDismiss: {
                    // ⭐️ 債券庫存視圖關閉時,重新載入客戶專屬的債券資料
                    loadClientSpecificBondData()
                }) {
                    CorporateBondsInventoryView(client: client)
                        .environment(\.managedObjectContext, viewContext)
                        .id(client.objectID) // ⭐️ 強制在客戶變更時重新建立 view，避免快取問題
                }

                // 第二頁：快速更新介面
                QuickUpdateView(client: client)
                    .environment(\.managedObjectContext, viewContext)
                    .id(client.objectID) // ⭐️ 強制在客戶變更時重新建立 view，避免快取問題
            }
            .id(client.objectID) // ⭐️ 強制整個 TabView 在客戶變更時重建，避免頁面快取問題
            .tabViewStyle(.page(indexDisplayMode: .never)) // 隱藏頁面指示器
            .ignoresSafeArea(.all, edges: .bottom) // 讓 TabView 填滿整個螢幕
            // ⭐️ 載入客戶專屬的債券資料
            .onAppear {
                loadClientSpecificBondData()
            }
            // ⭐️ 監聽客戶切換,重新載入該客戶的債券資料
            .onChange(of: client.objectID) { _ in
                loadClientSpecificBondData()
            }
            // ⭐️ 當債券資料改變時，儲存到客戶專屬的 UserDefaults
            .onChange(of: bondEditModeRawValue) { _ in
                saveClientSpecificBondData()
            }
            .onChange(of: bondsTotalValue) { _ in
                saveClientSpecificBondData()
            }
            .onChange(of: bondsTotalInterest) { _ in
                saveClientSpecificBondData()
            }
            // ⭐️ 監聽債券模式變更通知（其他視圖可能改變模式）
            .onReceive(NotificationCenter.default.publisher(for: .init("BondEditModeDidChange"))) { _ in
                bondEditModeRawValue = UserDefaults.standard.string(forKey: clientSpecificBondEditModeKey) ?? BondEditMode.batchUpdate.rawValue
                print("✅ 儀表板：收到模式變更通知，已同步為：\(bondEditModeRawValue)")
            }
            // ⭐️ 將通知監聽移到 TabView 外層，確保無論在哪一頁都能接收通知
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TWStockPriceUpdated"))) { notification in
                // 檢查是否是當前客戶的更新
                if let userInfo = notification.userInfo,
                   let updatedClientID = userInfo["clientID"] as? String,
                   updatedClientID == client.objectID.uriRepresentation().absoluteString {
                    // 觸發視圖刷新
                    refreshTrigger = UUID()
                    print("🔄 收到台股價更新通知，刷新視圖")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("USStockPriceUpdated"))) { notification in
                // 檢查是否是當前客戶的更新
                if let userInfo = notification.userInfo,
                   let updatedClientID = userInfo["clientID"] as? String,
                   updatedClientID == client.objectID.uriRepresentation().absoluteString {
                    // 觸發視圖刷新
                    refreshTrigger = UUID()
                    print("🔄 收到美股價更新通知，刷新視圖")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MonthlyAssetUpdated"))) { notification in
                // 檢查是否是當前客戶的更新
                if let userInfo = notification.userInfo,
                   let updatedClientID = userInfo["clientID"] as? String,
                   updatedClientID == client.objectID.uriRepresentation().absoluteString {
                    // 觸發視圖刷新
                    refreshTrigger = UUID()
                    print("🔄 收到月度資產更新通知，刷新視圖")
                }
            }
        } else {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("選擇一個客戶")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("從漢堡按鈕選擇客戶以查看投資儀表板")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - iPad 佈局
    private var iPadLayout: some View {
        VStack(spacing: 20) {
            // 主要統計卡片 - 全寬
            mainStatsCardForDesktop

            // 中間區域：其他卡片
            HStack(alignment: .top, spacing: 16) {
                // 左側：資產配置卡片
                assetAllocationCard
                    .frame(maxWidth: 380, maxHeight: 585)

                // 右側：投資卡片組
                VStack(spacing: 16) {
                    usStockCard
                    twStockCard
                    bondsCard
                    simpleBondDividendCard
                }
            }

            // 表格區域 - 按新順序排列：月度資產 → 公司債 → 結構型明細 → 美股明細 → 台股明細 → 損益表
            VStack(spacing: 16) {
                // 1. 月度資產明細
                MonthlyAssetDetailView(monthlyData: $monthlyAssetData, client: client)

                // 2. 公司債明細
                CorporateBondsDetailView(client: client)

                // 3. 結構型明細
                StructuredProductsDetailView(client: client)

                // 4. 美股明細
                USStockDetailView(client: client)

                // 5. 台股明細
                TWStockDetailView(client: client)

                // 6. 損益表
                ProfitLossTableView(client: client)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - iPhone 佈局
    private var iPhoneLayout: some View {
        VStack(spacing: 16) {
            // 主要統計卡片
            mainStatsCard

            // 其他卡片
            assetAllocationCard

            // 投資卡片組
            usStockCard
            twStockCard
            bondsCard
            simpleBondDividendCard

            // 表格區域 - 按新順序排列：月度資產 → 公司債 → 結構型明細 → 美股明細 → 台股明細 → 損益表
            VStack(spacing: 16) {
                // 1. 月度資產明細
                MonthlyAssetDetailView(monthlyData: $monthlyAssetData, client: client)

                // 2. 公司債明細
                CorporateBondsDetailView(client: client)

                // 3. 結構型明細
                StructuredProductsDetailView(client: client)

                // 4. 美股明細
                USStockDetailView(client: client)

                // 5. 台股明細
                TWStockDetailView(client: client)

                // 6. 損益表
                ProfitLossTableView(client: client)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - 主要統計卡片 (iPhone)
    private var mainStatsCard: some View {
        VStack(spacing: 16) {
            // 總資產標題和數值
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("總資產")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)

                    // 幣別切換按鈕
                    HStack(spacing: 0) {
                        Button("美金") {
                            selectedCurrency = "美金"
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(selectedCurrency == "美金" ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.clear)
                        .foregroundColor(selectedCurrency == "美金" ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))

                        Button("台幣") {
                            selectedCurrency = "台幣"
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(selectedCurrency == "台幣" ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.clear)
                        .foregroundColor(selectedCurrency == "台幣" ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                    }
                    .background(Color(.init(red: 0.95, green: 0.95, blue: 0.96, alpha: 0.6)))
                    .clipShape(Capsule())

                    Spacer()
                }

                Text(formatCurrency(getTotalAssets()))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 總損益
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("總損益: \(formatPnL(getTotalPnL()))")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(getTotalPnL() >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : Color(.init(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)))

                // 較上次變化百分比
                if monthlyAssets.count >= 2 {
                    let changePercentage = getPnLChangePercentage()
                    Text(formatChangePercentage(changePercentage))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(getChangeColor(changePercentage))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(getChangeColor(changePercentage).opacity(0.15))
                        )
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 時間按鈕
            HStack(spacing: 6) {
                ForEach(["ALL", "7D", "1M", "3M", "1Y"], id: \.self) { period in
                    Button(period) {
                        selectedPeriod = period
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(period == selectedPeriod ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.gray.opacity(0.2))
                    .foregroundColor(period == selectedPeriod ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 2x2 統計小卡片
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                statsCard(title: "總匯入", value: formatCurrency(getTotalDeposit()), isHighlight: false)
                statsCard(title: "總額報酬率", value: formatReturnRate(getTotalReturnRate()), isHighlight: true)
                statsCard(title: "現金", value: formatCurrency(getCash()), isHighlight: false)
                statsCard(title: "本月收益", value: formatCurrency(getMonthlyIncome()), isHighlight: false)
            }

            // 走勢圖區域
            simpleTrendChart
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .id(refreshTrigger)
    }

    // MARK: - 桌面版主統計卡片 (iPad)
    private var mainStatsCardForDesktop: some View {
        VStack(spacing: 16) {
            // 頂部區域：總資產 + 右上角整合卡片
            HStack(alignment: .top, spacing: 24) {
                // 左側：總資產區域
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 10) {
                        Text("總資產")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)

                        // 幣別切換按鈕
                        HStack(spacing: 0) {
                            Button("美金") {
                                selectedCurrency = "美金"
                            }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(selectedCurrency == "美金" ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.clear)
                            .foregroundColor(selectedCurrency == "美金" ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))

                            Button("台幣") {
                                selectedCurrency = "台幣"
                            }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(selectedCurrency == "台幣" ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.clear)
                            .foregroundColor(selectedCurrency == "台幣" ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                        }
                        .background(Color(.init(red: 0.95, green: 0.95, blue: 0.96, alpha: 0.6)))
                        .clipShape(Capsule())

                        Spacer()
                    }
                    .padding(.bottom, 12)

                    Text(formatCurrency(getTotalAssets()))
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)

                    Spacer()

                    Text("總損益: \(formatPnL(getTotalPnL()))")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(getTotalPnL() >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : Color(.init(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)))

                    Spacer()

                    // 時間按鈕（與右側卡片底部對齊）
                    HStack(spacing: 8) {
                        ForEach(["ALL", "7D", "1M", "3M", "1Y"], id: \.self) { period in
                            Button(period) {
                                selectedPeriod = period
                            }
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(period == selectedPeriod ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.gray.opacity(0.2))
                            .foregroundColor(period == selectedPeriod ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                            .clipShape(Capsule())
                        }
                    }
                }

                // 右上角：2x2 統計小卡片群組
                miniStatsCardGroup
                    .frame(width: 392) // 增加40%: 280 * 1.4 = 392
            }

            // 走勢圖
            simpleTrendChart
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - 整合統計卡片
    private var integratedStatsCard: some View {
        VStack(spacing: 0) {
            // 上半部：總匯入
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("總匯入")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)))
                    Text(formatCurrency(getTotalDeposit()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                }
                Spacer()
            }
            .padding(20)
            .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

            // 分隔線
            Rectangle()
                .fill(Color(.init(red: 0.92, green: 0.92, blue: 0.93, alpha: 1.0)))
                .frame(height: 1)

            // 下半部：現金 + 總額報酬率
            HStack(spacing: 1) {
                // 左側：現金（佔60%）
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("現金")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(.init(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)))
                        Text(formatCurrency(getCash()))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(.init(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)))

                Rectangle()
                    .fill(Color(.init(red: 0.92, green: 0.92, blue: 0.93, alpha: 1.0)))
                    .frame(width: 1)

                // 右側：總額報酬率（縮小20%）
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("總額報酬率")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        Text(formatReturnRate(getTotalReturnRate()))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity * 0.8)
                .padding(16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),
                            Color(.init(red: 0.20, green: 0.40, blue: 0.30, alpha: 1.0))
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        }
        .frame(width: 360, height: 160)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: - 總匯入小卡片（基於 PROJECT.md 規範）
    private var totalDepositMiniCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("總匯入")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(.init(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)))

            Text(formatCurrency(getTotalDeposit()))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
        }
        .frame(width: 140, height: 60)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: - 總額報酬率小卡片（基於 PROJECT.md 規範）
    private var totalReturnRateMiniCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("總額報酬率")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatReturnRate(getTotalReturnRate()))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("較上次")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Text(formatChangePercentage(getAssetChangePercentage()))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(getChangeColor(getAssetChangePercentage()))
                }
            }
        }
        .frame(width: 140, height: 60)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),
                            Color(.init(red: 0.20, green: 0.40, blue: 0.30, alpha: 1.0))
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: - 小卡片群組（不對稱佈局）
    private var miniStatsCardGroup: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // 左側：總匯入和現金垂直排列
            VStack(alignment: .leading, spacing: 12) {
                // 總匯入 - 純文字顯示
                VStack(alignment: .leading, spacing: 8) {
                    Text("總匯入")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))

                    Text(formatCurrencyWithoutSymbol(getTotalDeposit()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.label))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)

                // 現金卡片 - 白色背景
                VStack(alignment: .leading, spacing: 8) {
                    Text("現金")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))

                    Text(formatCurrencyWithoutSymbol(getCash()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.label))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
            }
            .frame(width: 156) // 左側寬度

            // 右側：總額報酬率大卡片
            miniStatsCard(
                title: "總額報酬率",
                value: formatReturnRate(getTotalReturnRate()),
                isHighlight: true,
                isCompact: false
            )
            .frame(width: 160) // 右側寬度: 352(可用空間) - 156(左側) - 16(間距) - 20(調整) = 160
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - 小統計卡片組件
    private func miniStatsCard(title: String, value: String, isHighlight: Bool, isCompact: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 4 : 8) {
            Text(title)
                .font(.system(size: isCompact ? 20 : 16, weight: .medium))
                .foregroundColor(isHighlight ? .white : Color(.secondaryLabel))
                .lineLimit(2)

            if isHighlight && !isCompact {
                // 大卡片額外資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    HStack {
                        Text("較上次")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Text(formatChangePercentage(getAssetChangePercentage()))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(getChangeColor(getAssetChangePercentage()))
                        Spacer()
                    }
                }
            } else {
                Text(value)
                    .font(.system(size: isCompact ? 17 : 24, weight: .bold))
                    .foregroundColor(isHighlight ? .white : Color(.label))
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: isCompact ? 120 : 140, height: isCompact ? 80 : 120) // 增加40%寬度: 100 * 1.4 = 140
        .padding(isCompact ? 8 : 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlight ?
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),
                            Color(.init(red: 0.20, green: 0.40, blue: 0.30, alpha: 1.0))
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(gradient: Gradient(colors: [Color(.tertiarySystemBackground)]), startPoint: .top, endPoint: .bottom)
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    // MARK: - 統計小卡片
    private func statsCard(title: String, value: String, isHighlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isHighlight ? .white : Color(.secondaryLabel))

            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(isHighlight ? .white : Color(.label))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlight ?
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),
                            Color(.init(red: 0.20, green: 0.40, blue: 0.30, alpha: 1.0))
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(gradient: Gradient(colors: [Color(.tertiarySystemBackground)]), startPoint: .top, endPoint: .bottom)
                )
        )
    }

    // MARK: - 簡化走勢圖
    private var simpleTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("投資走勢")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            // 真實數據走勢線
            GeometryReader { geometry in
                ZStack {
                    // 漸層填充區域（線條下方）
                    trendFillArea(in: geometry.size)

                    // 粉紅色趨勢線
                    trendLine(in: geometry.size)

                    // 選中點的標記和數值
                    if let index = selectedDataPointIndex,
                       let value = selectedDataPointValue,
                       let date = selectedDataPointDate {
                        let points = getTrendDataPoints(in: geometry.size)

                        if index < points.count {
                            let point = points[index]
                            let changeValue = getTrendChangeValue()
                            let baseColor = changeValue >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : Color.red

                            ZStack {
                                // 垂直指示線
                                Path { path in
                                    path.move(to: CGPoint(x: point.x, y: 0))
                                    path.addLine(to: CGPoint(x: point.x, y: geometry.size.height))
                                }
                                .stroke(baseColor.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

                                // 選中點的圓圈
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(baseColor, lineWidth: 2)
                                    )
                                    .position(x: point.x, y: point.y)

                                // 數值標籤（顯示在點的上方）
                                VStack(spacing: 2) {
                                    Text(date)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                    Text(formatCurrency(value))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(baseColor.opacity(0.95))
                                )
                                .position(x: point.x, y: max(point.y - 40, 20))
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gestureValue in
                            // 取消之前的隱藏任務
                            hideDataPointWorkItem?.cancel()

                            // 內聯處理觸摸事件
                            let location = gestureValue.location

                            // 獲取按日期排序的月度資產數據
                            let sortedAssets = monthlyAssets.sorted { asset1, asset2 in
                                (asset1.createdDate ?? Date.distantPast) < (asset2.createdDate ?? Date.distantPast)
                            }

                            guard !sortedAssets.isEmpty else { return }

                            // 根據選擇的時間範圍篩選資料
                            let filteredAssets: [MonthlyAsset]
                            switch selectedPeriod {
                            case "ALL":
                                filteredAssets = sortedAssets
                            case "7D":
                                filteredAssets = Array(sortedAssets.suffix(7))
                            case "1M":
                                filteredAssets = Array(sortedAssets.suffix(1))
                            case "3M":
                                filteredAssets = Array(sortedAssets.suffix(3))
                            case "1Y":
                                filteredAssets = Array(sortedAssets.suffix(12))
                            default:
                                filteredAssets = sortedAssets
                            }

                            guard !filteredAssets.isEmpty else { return }

                            // 計算觸摸位置對應的數據點索引
                            let count = filteredAssets.count
                            let stepX = geometry.size.width / CGFloat(max(count - 1, 1))
                            let index = Int(round(location.x / stepX))

                            // 確保索引在範圍內
                            guard index >= 0 && index < filteredAssets.count else { return }

                            let asset = filteredAssets[index]

                            // 取得總資產值（根據選擇的幣別）
                            let totalAssets: Double
                            if selectedCurrency == "美金" {
                                guard let totalStr = asset.totalAssets, let value = Double(totalStr) else { return }
                                totalAssets = value
                            } else {
                                // 台幣：需要重新計算
                                let cash = Double(asset.cash ?? "0") ?? 0
                                let usStock = Double(asset.usStock ?? "0") ?? 0
                                let regularInvestment = Double(asset.regularInvestment ?? "0") ?? 0
                                let bonds = Double(asset.bonds ?? "0") ?? 0
                                let structured = Double(asset.structured ?? "0") ?? 0
                                let taiwanStockFolded = Double(asset.taiwanStockFolded ?? "0") ?? 0
                                let twdToUsd = Double(asset.twdToUsd ?? "0") ?? 0
                                let exchangeRate = Double(asset.exchangeRate ?? "32") ?? 32
                                let twdCash = Double(asset.twdCash ?? "0") ?? 0
                                let taiwanStock = Double(asset.taiwanStock ?? "0") ?? 0

                                totalAssets = ((cash + usStock + regularInvestment + bonds + structured - taiwanStockFolded - twdToUsd) * exchangeRate) + twdCash + taiwanStock
                            }

                            // 格式化日期
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy/MM"
                            let dateString = dateFormatter.string(from: asset.createdDate ?? Date())

                            selectedDataPointIndex = index
                            selectedDataPointValue = totalAssets
                            selectedDataPointDate = dateString
                        }
                        .onEnded { _ in
                            // 5秒後自動隱藏數據點
                            let workItem = DispatchWorkItem {
                                withAnimation {
                                    selectedDataPointIndex = nil
                                    selectedDataPointValue = nil
                                    selectedDataPointDate = nil
                                }
                            }
                            hideDataPointWorkItem = workItem
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)
                        }
                )
            }
            .frame(height: 203) // 再增加30%: 156 * 1.3 = 203
        }
        .padding(.top, 8)
    }

    // 走勢圖填充區域
    private func trendFillArea(in size: CGSize) -> some View {
        let points = getTrendDataPoints(in: size)
        let changeValue = getTrendChangeValue()
        let baseColor = changeValue >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : Color.red

        var path = Path()
        if !points.isEmpty {
            path.move(to: CGPoint(x: points[0].x, y: size.height))
            path.addLine(to: points[0])

            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            path.addLine(to: CGPoint(x: points.last!.x, y: size.height))
            path.closeSubpath()
        }

        return path.fill(
            LinearGradient(
                gradient: Gradient(colors: [
                    baseColor.opacity(0.3),
                    baseColor.opacity(0.02)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // 走勢圖線條
    private func trendLine(in size: CGSize) -> some View {
        let points = getTrendDataPoints(in: size)
        let changeValue = getTrendChangeValue()
        let baseColor = changeValue >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : Color.red

        var path = Path()
        if !points.isEmpty {
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }

        return path.stroke(
            LinearGradient(
                gradient: Gradient(colors: [
                    baseColor,
                    baseColor.opacity(0.7)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            lineWidth: 2.5
        )
    }

    // 計算走勢圖數據點
    private func getTrendDataPoints(in size: CGSize) -> [CGPoint] {
        // 獲取按日期排序的月度資產數據（使用 createdDate 欄位，從舊到新）
        let sortedAssets = monthlyAssets.sorted { asset1, asset2 in
            (asset1.createdDate ?? Date.distantPast) < (asset2.createdDate ?? Date.distantPast)
        }

        guard !sortedAssets.isEmpty else { return [] }

        // 根據選擇的時間範圍篩選資料
        let filteredAssets: [MonthlyAsset]
        switch selectedPeriod {
        case "ALL":
            filteredAssets = sortedAssets
        case "7D":
            // 取最近7筆資料
            filteredAssets = Array(sortedAssets.suffix(7))
        case "1M":
            // 取最近1筆資料（代表最近一個月）
            filteredAssets = Array(sortedAssets.suffix(1))
        case "3M":
            // 取最近3筆資料（代表最近三個月）
            filteredAssets = Array(sortedAssets.suffix(3))
        case "1Y":
            // 取最近12筆資料（代表最近一年）
            filteredAssets = Array(sortedAssets.suffix(12))
        default:
            filteredAssets = sortedAssets
        }

        // 提取總資產數值
        let values = filteredAssets.compactMap { asset -> Double? in
            guard let totalStr = asset.totalAssets else { return nil }
            return Double(totalStr)
        }

        guard !values.isEmpty else { return [] }

        // 找出最大最小值用於歸一化
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let range = maxValue - minValue

        // 計算每個點的座標
        let count = values.count
        let stepX = size.width / CGFloat(max(count - 1, 1))

        return values.enumerated().map { index, value in
            let x = CGFloat(index) * stepX
            // 歸一化到 0.1 ~ 0.9 之間（留出上下邊距）
            let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
            let y = size.height * (1 - (normalizedValue * 0.8 + 0.1))
            return CGPoint(x: x, y: y)
        }
    }

    // 計算走勢變化百分比
    private func getTrendChangePercentage() -> String {
        let change = getTrendChangeValue()
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change))%"
    }

    private func getTrendChangeValue() -> Double {
        let sortedAssets = monthlyAssets.sorted { asset1, asset2 in
            (asset1.createdDate ?? Date.distantPast) < (asset2.createdDate ?? Date.distantPast)
        }

        guard !sortedAssets.isEmpty else { return 0.0 }

        // 根據選擇的時間範圍篩選資料
        let filteredAssets: [MonthlyAsset]
        switch selectedPeriod {
        case "ALL":
            filteredAssets = sortedAssets
        case "7D":
            filteredAssets = Array(sortedAssets.suffix(7))
        case "1M":
            filteredAssets = Array(sortedAssets.suffix(1))
        case "3M":
            filteredAssets = Array(sortedAssets.suffix(3))
        case "1Y":
            filteredAssets = Array(sortedAssets.suffix(12))
        default:
            filteredAssets = sortedAssets
        }

        guard filteredAssets.count >= 2,
              let firstAssetStr = filteredAssets.first?.totalAssets,
              let lastAssetStr = filteredAssets.last?.totalAssets,
              let firstValue = Double(firstAssetStr),
              let lastValue = Double(lastAssetStr),
              firstValue > 0 else {
            return 0.0
        }

        return ((lastValue - firstValue) / firstValue) * 100
    }

    // MARK: - 資產配置卡片
    @State private var selectedAssetPage = 0

    private var assetAllocationCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text(getAssetAllocationTitle())
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                // 頁面指示器圓點
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == selectedAssetPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }

            // 圓餅圖區域 - TabView實現左滑切換
            TabView(selection: $selectedAssetPage) {
                // 頁面0: 總覽
                assetOverviewView.tag(0)

                // 頁面1: 美股詳細
                usStockDetailView.tag(1)

                // 頁面2: 債券詳細
                bondsDetailView.tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 455)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveCardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .id(refreshTrigger)
    }

    // MARK: - 資產配置標題
    private func getAssetAllocationTitle() -> String {
        switch selectedAssetPage {
        case 0: return "資產配置"
        case 1: return "美股詳細"
        case 2: return "債券詳細"
        default: return "資產配置"
        }
    }

    // MARK: - 資產總覽頁面
    private var assetOverviewView: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 20)
                    .frame(width: 140, height: 140)

                // 美股
                Circle()
                    .trim(from: 0, to: getUSStockPercentage() / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)),
                                Color(.init(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 債券
                Circle()
                    .trim(from: getUSStockPercentage() / 100, to: (getUSStockPercentage() + getBondsPercentage()) / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)),
                                Color(.init(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 現金
                Circle()
                    .trim(from: (getUSStockPercentage() + getBondsPercentage()) / 100, to: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage()) / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)),
                                Color(.init(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 台幣
                Circle()
                    .trim(from: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage()) / 100, to: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage()) / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.75, green: 0.35, blue: 0.75, alpha: 1.0)),
                                Color(.init(red: 0.85, green: 0.45, blue: 0.85, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 其他貨幣
                Circle()
                    .trim(from: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage()) / 100, to: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage() + getOtherCurrenciesPercentage()) / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.3, green: 0.7, blue: 0.9, alpha: 1.0)),
                                Color(.init(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 台股
                Circle()
                    .trim(from: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage() + getOtherCurrenciesPercentage()) / 100, to: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage() + getOtherCurrenciesPercentage() + getTWStockPercentage()) / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)),
                                Color(.init(red: 0.3, green: 0.9, blue: 0.3, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 結構型
                Circle()
                    .trim(from: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage() + getOtherCurrenciesPercentage() + getTWStockPercentage()) / 100, to: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage() + getOtherCurrenciesPercentage() + getTWStockPercentage() + getStructuredPercentage()) / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)),
                                Color(.init(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 基金
                Circle()
                    .trim(from: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage() + getOtherCurrenciesPercentage() + getTWStockPercentage() + getStructuredPercentage()) / 100, to: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage() + getOtherCurrenciesPercentage() + getTWStockPercentage() + getStructuredPercentage() + getFundPercentage()) / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)),
                                Color(.init(red: 1.0, green: 0.6, blue: 0.1, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 保險
                Circle()
                    .trim(from: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage() + getOtherCurrenciesPercentage() + getTWStockPercentage() + getStructuredPercentage() + getFundPercentage()) / 100, to: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage() + getOtherCurrenciesPercentage() + getTWStockPercentage() + getStructuredPercentage() + getFundPercentage() + getInsurancePercentage()) / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.4, green: 0.2, blue: 0.6, alpha: 1.0)),
                                Color(.init(red: 0.5, green: 0.3, blue: 0.7, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 中心文字 - 智能顯示最高佔比資產
                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", getHighestAssetPercentage().percentage))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    Text(getHighestAssetPercentage().name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // 圖例
            VStack(alignment: .leading, spacing: 8) {
                if getUSStockPercentage() > 0 {
                    simpleLegendItem(color: Color(.init(red: 0.9, green: 0.25, blue: 0.25, alpha: 1.0)), title: "美股", percentage: formatPercentage(getUSStockPercentage()))
                }
                if getBondsPercentage() > 0 {
                    simpleLegendItem(color: Color(.init(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)), title: "債券", percentage: formatPercentage(getBondsPercentage()))
                }
                if getCashPercentage() > 0 {
                    simpleLegendItem(color: Color(.init(red: 1.0, green: 0.65, blue: 0.1, alpha: 1.0)), title: "美金", percentage: formatPercentage(getCashPercentage()))
                }
                if getTWDPercentage() > 0 {
                    simpleLegendItem(color: Color(.init(red: 0.8, green: 0.4, blue: 0.8, alpha: 1.0)), title: "台幣", percentage: formatPercentage(getTWDPercentage()))
                }
                if getOtherCurrenciesPercentage() > 0 {
                    simpleLegendItem(color: Color(.init(red: 0.35, green: 0.75, blue: 0.95, alpha: 1.0)), title: "其他貨幣", percentage: formatPercentage(getOtherCurrenciesPercentage()))
                }
                if getTWStockPercentage() > 0 {
                    simpleLegendItem(color: Color(.init(red: 0.25, green: 0.8, blue: 0.25, alpha: 1.0)), title: "台股", percentage: formatPercentage(getTWStockPercentage()))
                }
                if getStructuredPercentage() > 0 {
                    simpleLegendItem(color: Color(.init(red: 0.25, green: 0.45, blue: 0.9, alpha: 1.0)), title: "結構型", percentage: formatPercentage(getStructuredPercentage()))
                }
                if getFundPercentage() > 0 {
                    simpleLegendItem(color: Color(.init(red: 1.0, green: 0.55, blue: 0.05, alpha: 1.0)), title: "基金", percentage: formatPercentage(getFundPercentage()))
                }
                if getInsurancePercentage() > 0 {
                    simpleLegendItem(color: Color(.init(red: 0.45, green: 0.25, blue: 0.65, alpha: 1.0)), title: "保險", percentage: formatPercentage(getInsurancePercentage()))
                }
            }
        }
    }

    // MARK: - 美股詳細頁面
    private var usStockDetailView: some View {
        VStack(spacing: 15) {
            // 如果沒有美股資料，顯示提示
            if usStocks.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("尚無美股資料")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 40)
            } else {
                let stocksAndOthers = getTopStocksAndOthers(limit: 3)
                let topStocks = stocksAndOthers.topStocks
                let othersPercentage = stocksAndOthers.othersPercentage

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 20)
                        .frame(width: 140, height: 140)

                    // 動態繪製圓餅圖
                    usStockPieChart(stocks: topStocks, othersPercentage: othersPercentage)

                    // 中心顯示最大持股
                    if let topStock = topStocks.first {
                        VStack(spacing: 2) {
                            Text(String(format: "%.0f%%", getStockPercentage(stock: topStock)))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)
                            Text(topStock.name ?? "")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 美股詳細圖例
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(topStocks.enumerated()), id: \.offset) { index, stock in
                        simpleLegendItem(
                            color: getStockColor(index: index),
                            title: stock.name ?? "",
                            percentage: String(format: "%.0f%%", getStockPercentage(stock: stock))
                        )
                    }
                    if othersPercentage > 0 {
                        simpleLegendItem(
                            color: Color.purple,
                            title: "其他",
                            percentage: String(format: "%.0f%%", othersPercentage)
                        )
                    }
                }
            }
        }
    }

    // 繪製美股圓餅圖
    private func usStockPieChart(stocks: [USStock], othersPercentage: Double) -> some View {
        var startAngle: Double = 0

        return ZStack {
            ForEach(Array(stocks.enumerated()), id: \.offset) { index, stock in
                let percentage = getStockPercentage(stock: stock)
                let endAngle = startAngle + (percentage / 100)
                let _ = { startAngle = endAngle }()

                Circle()
                    .trim(from: startAngle - (percentage / 100), to: startAngle)
                    .stroke(getStockColor(index: index), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
            }

            // 其他
            if othersPercentage > 0 {
                let endAngle = startAngle + (othersPercentage / 100)

                Circle()
                    .trim(from: startAngle, to: endAngle)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
            }
        }
    }

    // 取得股票顏色（根據索引）
    private func getStockColor(index: Int) -> Color {
        let colors: [Color] = [
            Color.blue,
            Color.green,
            Color.orange,
            Color.red,
            Color.cyan
        ]
        return colors[index % colors.count]
    }

    // MARK: - 債券詳細頁面
    private var bondsDetailView: some View {
        VStack(spacing: 15) {
            let bonds = getBondsByName()
            let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan]

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 20)
                    .frame(width: 140, height: 140)

                // 動態繪製每個債券的扇形
                ForEach(Array(bonds.enumerated()), id: \.offset) { index, bond in
                    let startPercentage = bonds[0..<index].reduce(0.0) { $0 + $1.percentage }
                    let endPercentage = startPercentage + bond.percentage

                    Circle()
                        .trim(from: startPercentage / 100, to: endPercentage / 100)
                        .stroke(colors[index % colors.count], style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                }

                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", getTopBond().percentage))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    Text(getTopBond().name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            // 債券詳細圖例 - 顯示客戶輸入的債券名稱
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(bonds.prefix(6).enumerated()), id: \.offset) { index, bond in
                    simpleLegendItem(
                        color: colors[index % colors.count],
                        title: bond.name,
                        percentage: String(format: "%.0f%%", bond.percentage)
                    )
                }
            }
        }
    }

    // MARK: - 簡化圖例項目
    private func simpleLegendItem(color: Color, title: String, percentage: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            Text(percentage)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
        }
    }

    // MARK: - 圖例項目
    private func legendItem(color: Color, title: String, percentage: String, amount: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Text(formatCurrency(Double(amount) ?? 0))
                    .font(.system(size: 14))
                    .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
            }

            Spacer()

            Text(percentage)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.1))
                )
        }
    }

    // MARK: - 美股投資卡片（左滑功能）
    @State private var selectedUSStockPage = 0

    private var usStockCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text(getUSStockCardTitle())
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == selectedUSStockPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            TabView(selection: $selectedUSStockPage) {
                // 頁面0: 美股
                usStockDetailCardView.tag(0)
                // 頁面1: 結構型商品
                structuredProductDetailView.tag(1)
                // 頁面2: 基金
                fundDetailView.tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 70)
        }
        .padding(20)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveCardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .id(refreshTrigger)
    }

    private func getUSStockCardTitle() -> String {
        switch selectedUSStockPage {
        case 0: return "美股"
        case 1: return "結構型商品"
        case 2: return "基金"
        default: return "美股"
        }
    }

    private var usStockDetailCardView: some View {
        Button(action: {
            showingUSStockInventory = true
        }) {
            HStack(spacing: 16) {
                // 左側：金額和報酬率（佔50%）
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatCurrency(getUSStockValue()))
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.primary)

                    Text("報酬率: \(formatReturnRate(getUSStockReturnRate()))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(getUSStockReturnRate() >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 右側：折線圖（佔50%）
                LineChartView(
                    color: getUSStockReturnRate() >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red,
                    dataPoints: getUSStockTrendData()
                )
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 基金詳細頁面
    private var fundDetailView: some View {
        HStack(spacing: 16) {
            // 左側：金額和報酬率（佔50%）
            VStack(alignment: .leading, spacing: 6) {
                Text(formatCurrency(getFundValue()))
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.primary)

                Text("報酬率: \(formatReturnRate(getFundReturnRate()))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(getFundReturnRate() >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 右側：折線圖（佔50%）
            LineChartView(
                color: getFundReturnRate() >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red,
                dataPoints: getFundTrendData()
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 結構型商品詳細頁面
    private var structuredProductDetailView: some View {
        Button(action: {
            showingStructuredInventory = true
        }) {
            HStack(spacing: 16) {
                // 左側：金額和平均利率（佔50%）
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatCurrency(getStructuredProductValue()))
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.primary)

                    Text("平均利率: \(formatReturnRate(getStructuredProductAverageRate()))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 右側：商品數量統計
                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(structuredProducts.count)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(red: 0x19/255.0, green: 0x72/255.0, blue: 0x78/255.0))
                    Text("商品數量")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 台股投資卡片（左滑功能）
    @State private var selectedTwStockPage = 0

    private var twStockCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text(getTwStockCardTitle())
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i == selectedTwStockPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            TabView(selection: $selectedTwStockPage) {
                // 頁面0: 台股
                twStockDetailView.tag(0)
                // 頁面1: 結構型商品
                structuredProductDetailView.tag(1)
                // 頁面2: 定期定額
                regularInvestmentDetailView.tag(2)
                // 頁面3: 基金
                fundDetailView.tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 70)
        }
        .padding(20)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveCardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .id(refreshTrigger)
    }

    private func getTwStockCardTitle() -> String {
        switch selectedTwStockPage {
        case 0: return "台股"
        case 1: return "結構型商品"
        case 2: return "定期定額"
        case 3: return "基金"
        default: return "台股"
        }
    }

    private var twStockDetailView: some View {
        Button(action: {
            showingTWStockInventory = true
        }) {
            HStack(spacing: 16) {
                // 左側：金額和報酬率（佔50%）
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatCurrency(getTWStockValue()))
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.primary)

                    Text("報酬率: \(formatReturnRate(getTWStockReturnRate()))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(getTWStockReturnRate() >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 右側：折線圖（佔50%）
                LineChartView(
                    color: getTWStockReturnRate() >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red,
                    dataPoints: getTWStockTrendData()
                )
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var regularInvestmentDetailView: some View {
        Button(action: {
            showingRegularInvestmentInventory = true
        }) {
            HStack(spacing: 16) {
                // 左側：金額和報酬率（佔50%）
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatCurrency(getRegularInvestmentValue()))
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.primary)

                    Text("報酬率: \(formatReturnRate(getRegularInvestmentReturnRate()))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(getRegularInvestmentReturnRate() >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 右側：折線圖（佔50%）
                LineChartView(
                    color: getRegularInvestmentReturnRate() >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red,
                    dataPoints: getRegularInvestmentTrendData()
                )
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 債券投資卡片（左滑功能）
    @State private var selectedBondsPage = 0

    private var bondsCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text(getBondsCardTitle())
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i == selectedBondsPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            TabView(selection: $selectedBondsPage) {
                // 頁面0: 債券
                bondsDetailCardView.tag(0)
                // 頁面1: 結構型商品
                structuredProductDetailView.tag(1)
                // 頁面2: 定期定額
                regularInvestmentDetailView.tag(2)
                // 頁面3: 基金
                fundDetailView.tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 70)
        }
        .padding(20)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveCardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .id(refreshTrigger)
    }

    private func getBondsCardTitle() -> String {
        switch selectedBondsPage {
        case 0: return "債券"
        case 1: return "結構型商品"
        case 2: return "定期定額"
        case 3: return "基金"
        default: return "債券"
        }
    }

    private var bondsDetailCardView: some View {
        Button(action: {
            showingCorporateBondsDetail = true
        }) {
            HStack(spacing: 16) {
                // 左側：金額和報酬率（佔50%）
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatCurrency(getBondsValue()))
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.primary)

                    Text("報酬率: \(formatReturnRate(getBondsReturnRate()))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(getBondsReturnRate() >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 右側：折線圖（佔50%）
                LineChartView(
                    color: getBondsReturnRate() >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red,
                    dataPoints: getBondsTrendData()
                )
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 債券每月配息卡片
    private var simpleBondDividendCard: some View {
        VStack(spacing: 8) {
            // 多幣別時顯示 TabView
            if availableBondCurrencies.count > 1 {
                TabView(selection: $selectedBondCurrencyIndex) {
                    ForEach(0..<availableBondCurrencies.count, id: \.self) { index in
                        let currency = availableBondCurrencies[index]
                        bondDividendCardContent(for: currency)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 140)

                // 幣別指示器
                HStack(spacing: 6) {
                    ForEach(0..<availableBondCurrencies.count, id: \.self) { index in
                        Circle()
                            .fill(selectedBondCurrencyIndex == index ? bondCurrencyColor(for: availableBondCurrencies[index]) : Color(.systemGray4))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 8)
            } else {
                // 單一幣別直接顯示
                bondDividendCardContent(for: availableBondCurrencies.first ?? "USD")
                    .frame(height: 140)
            }
        }
    }

    // 債券配息卡片內容（根據幣別）
    private func bondDividendCardContent(for currency: String) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("債券每月配息")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(hoveredMonth == nil ? "年配息" : "\(hoveredMonth!)月配息")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    HStack(spacing: 6) {
                        // 顯示幣別標籤在金額左邊（多幣別或單一非美金幣別時顯示）
                        if availableBondCurrencies.count > 1 || currency != "USD" {
                            Text(currency)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(bondCurrencyColor(for: currency))
                                .cornerRadius(4)
                        }
                        Text(hoveredMonth == nil ? formatCurrency(getTotalAnnualDividend(for: currency)) : formatCurrency(getMonthlyDividends(for: currency)[hoveredMonth! - 1]))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
            }

            // 12個月長條圖
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(1...12, id: \.self) { month in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(hoveredMonth == month ? bondCurrencyColor(for: currency).opacity(0.7) : bondCurrencyColor(for: currency))
                            .frame(height: getMonthHeight(month, for: currency))
                            .frame(maxWidth: .infinity)

                        Text("\(month)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(hoveredMonth == month ? .primary : .secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if hoveredMonth == month {
                            hoveredMonth = nil
                        } else {
                            hoveredMonth = month
                        }
                    }
                }
            }
        }
        .padding(20)
    }

    // MARK: - 佔位符卡片
    private func placeholderCard(title: String, height: CGFloat) -> some View {
        VStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
            Text("即將推出")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - 數據計算函數（從 Core Data 月度資產讀取）
    private func getTotalAssets() -> Double {
        guard let latestAsset = monthlyAssets.first else {
            return 0.0
        }

        // 如果選擇美金，直接讀取總資產
        if selectedCurrency == "美金" {
            guard let totalAssetsStr = latestAsset.totalAssets,
                  let totalAssets = Double(totalAssetsStr) else {
                return 0.0
            }
            return totalAssets
        }

        // 選擇台幣時，重新計算
        // 總資產 = ((美金 + 美股 + 定期定額 + 債券 + 結構型 - 台股折合 - 台幣折合美金) * 匯率) + 台幣 + 台股
        let cash = Double(latestAsset.cash ?? "0") ?? 0
        let usStock = Double(latestAsset.usStock ?? "0") ?? 0
        let regularInvestment = Double(latestAsset.regularInvestment ?? "0") ?? 0
        let bonds = Double(latestAsset.bonds ?? "0") ?? 0
        let structured = Double(latestAsset.structured ?? "0") ?? 0
        let taiwanStockFolded = Double(latestAsset.taiwanStockFolded ?? "0") ?? 0
        let twdToUsd = Double(latestAsset.twdToUsd ?? "0") ?? 0
        let twdCash = Double(latestAsset.twdCash ?? "0") ?? 0
        let taiwanStock = Double(latestAsset.taiwanStock ?? "0") ?? 0
        let exchangeRate = getLatestExchangeRate()

        // 美金部分資產（扣除已經包含的台股折合和台幣折合美金）
        let usdAssets = cash + usStock + regularInvestment + bonds + structured - taiwanStockFolded - twdToUsd

        // 轉換為台幣並加上原本的台幣資產
        return (usdAssets * exchangeRate) + twdCash + taiwanStock
    }

    // ⭐️ 計算總資產（使用即時債券值）
    private func getTotalAssetsWithRealTimeBonds() -> Double {
        guard let latestAsset = monthlyAssets.first else {
            // 如果沒有月度資產,只返回債券值
            return getBondsValue()
        }

        // 讀取其他資產（美金、美股、結構型等）
        let cash = Double(latestAsset.cash ?? "0") ?? 0
        let usStock = Double(latestAsset.usStock ?? "0") ?? 0
        let regularInvestment = Double(latestAsset.regularInvestment ?? "0") ?? 0
        // ⭐️ bonds 不再從月度資產讀取,改用即時計算
        let bonds = getBondsValue()
        let structured = Double(latestAsset.structured ?? "0") ?? 0
        let fund = Double(latestAsset.fund ?? "0") ?? 0
        let insurance = Double(latestAsset.insurance ?? "0") ?? 0

        // 多幣別現金折合美金
        let eurToUsd = Double(latestAsset.eurToUsd ?? "0") ?? 0
        let jpyToUsd = Double(latestAsset.jpyToUsd ?? "0") ?? 0
        let gbpToUsd = Double(latestAsset.gbpToUsd ?? "0") ?? 0
        let cnyToUsd = Double(latestAsset.cnyToUsd ?? "0") ?? 0
        let audToUsd = Double(latestAsset.audToUsd ?? "0") ?? 0
        let cadToUsd = Double(latestAsset.cadToUsd ?? "0") ?? 0
        let chfToUsd = Double(latestAsset.chfToUsd ?? "0") ?? 0
        let hkdToUsd = Double(latestAsset.hkdToUsd ?? "0") ?? 0
        let sgdToUsd = Double(latestAsset.sgdToUsd ?? "0") ?? 0

        // 計算總資產（美金）
        let totalAssets = cash + usStock + regularInvestment + bonds + structured + fund + insurance +
                         eurToUsd + jpyToUsd + gbpToUsd + cnyToUsd + audToUsd +
                         cadToUsd + chfToUsd + hkdToUsd + sgdToUsd

        return totalAssets
    }

    private func getTotalPnL() -> Double {
        // 總損益 = 總資產 - 匯入累積
        guard let latestAsset = monthlyAssets.first,
              let totalAssetsStr = latestAsset.totalAssets,
              let depositAccStr = latestAsset.depositAccumulated,
              let totalAssets = Double(totalAssetsStr),
              let depositAcc = Double(depositAccStr) else {
            return 0.0
        }

        let pnl = totalAssets - depositAcc

        // 如果選擇台幣，乘以匯率
        if selectedCurrency == "台幣" {
            let exchangeRate = getLatestExchangeRate()
            return pnl * exchangeRate
        }

        return pnl
    }

    private func getTotalDeposit() -> Double {
        // 從最新一筆月度資產讀取匯入累積
        guard let latestAsset = monthlyAssets.first,
              let depositAccStr = latestAsset.depositAccumulated,
              let depositAcc = Double(depositAccStr) else {
            return 0.0
        }

        // 如果選擇台幣，乘以匯率
        if selectedCurrency == "台幣" {
            let exchangeRate = getLatestExchangeRate()
            return depositAcc * exchangeRate
        }

        return depositAcc
    }

    // 取得最新匯率
    private func getLatestExchangeRate() -> Double {
        guard let latestAsset = monthlyAssets.first,
              let exchangeRateStr = latestAsset.exchangeRate,
              let exchangeRate = Double(exchangeRateStr) else {
            return 32.0 // 預設匯率
        }
        return exchangeRate
    }

    private func getTotalReturnRate() -> Double {
        // 總額報酬率 = (總資產 - 匯入累積) / 匯入累積 * 100
        guard let latestAsset = monthlyAssets.first,
              let totalAssetsStr = latestAsset.totalAssets,
              let depositAccStr = latestAsset.depositAccumulated,
              let totalAssets = Double(totalAssetsStr),
              let depositAcc = Double(depositAccStr),
              depositAcc > 0 else {
            return 0.0
        }
        return ((totalAssets - depositAcc) / depositAcc) * 100
    }

    /// 計算較上次的總資產變化百分比
    private func getAssetChangePercentage() -> Double {
        // 需要至少兩筆資料才能計算
        guard monthlyAssets.count >= 2 else {
            return 0.0
        }

        let latestAsset = monthlyAssets[0]
        let previousAsset = monthlyAssets[1]

        // 根據選擇的幣別計算總資產
        let currentTotal = calculateTotalAssets(for: latestAsset)
        let previousTotal = calculateTotalAssets(for: previousAsset)

        // 避免除以零
        guard previousTotal > 0 else {
            return 0.0
        }

        // 計算變化百分比：(當前 - 上次) / 上次 * 100
        return ((currentTotal - previousTotal) / previousTotal) * 100
    }

    /// 計算較上次的總損益變化百分比
    private func getPnLChangePercentage() -> Double {
        // 需要至少兩筆資料才能計算
        guard monthlyAssets.count >= 2 else {
            return 0.0
        }

        let latestAsset = monthlyAssets[0]
        let previousAsset = monthlyAssets[1]

        // 計算當前總損益
        let currentPnL = calculatePnL(for: latestAsset)
        // 計算上次總損益
        let previousPnL = calculatePnL(for: previousAsset)

        // 避免除以零或負數損益的特殊情況
        guard abs(previousPnL) > 0 else {
            return 0.0
        }

        // 計算變化百分比：(當前 - 上次) / 上次 * 100
        return ((currentPnL - previousPnL) / abs(previousPnL)) * 100
    }

    /// 計算指定月度資產的總損益（根據選擇的幣別）
    private func calculatePnL(for asset: MonthlyAsset) -> Double {
        guard let totalAssetsStr = asset.totalAssets,
              let depositAccStr = asset.depositAccumulated,
              let totalAssets = Double(totalAssetsStr),
              let depositAcc = Double(depositAccStr) else {
            return 0.0
        }

        let pnl = totalAssets - depositAcc

        // 如果選擇台幣，乘以匯率
        if selectedCurrency == "台幣" {
            let exchangeRate = Double(asset.exchangeRate ?? "32") ?? 32
            return pnl * exchangeRate
        }

        return pnl
    }

    /// 計算指定月度資產的總資產（根據選擇的幣別）
    private func calculateTotalAssets(for asset: MonthlyAsset) -> Double {
        // 如果選擇美金，直接讀取總資產
        if selectedCurrency == "美金" {
            guard let totalAssetsStr = asset.totalAssets,
                  let totalAssets = Double(totalAssetsStr) else {
                return 0.0
            }
            return totalAssets
        }

        // 選擇台幣時，重新計算
        let cash = Double(asset.cash ?? "0") ?? 0
        let usStock = Double(asset.usStock ?? "0") ?? 0
        let regularInvestment = Double(asset.regularInvestment ?? "0") ?? 0
        let bonds = Double(asset.bonds ?? "0") ?? 0
        let structured = Double(asset.structured ?? "0") ?? 0
        let taiwanStockFolded = Double(asset.taiwanStockFolded ?? "0") ?? 0
        let twdToUsd = Double(asset.twdToUsd ?? "0") ?? 0
        let twdCash = Double(asset.twdCash ?? "0") ?? 0
        let taiwanStock = Double(asset.taiwanStock ?? "0") ?? 0
        let exchangeRate = Double(asset.exchangeRate ?? "32") ?? 32

        // 美金部分資產
        let usdAssets = cash + usStock + regularInvestment + bonds + structured - taiwanStockFolded - twdToUsd

        // 轉換為台幣並加上原本的台幣資產
        return (usdAssets * exchangeRate) + twdCash + taiwanStock
    }

    /// 格式化資產變化百分比（帶正負號和顏色）
    private func formatChangePercentage(_ percentage: Double) -> String {
        let sign = percentage >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, percentage)
    }

    /// 取得資產變化的顏色
    private func getChangeColor(_ percentage: Double) -> Color {
        return percentage >= 0 ? .white : .red
    }

    private func getCash() -> Double {
        // 從最新一筆月度資產讀取：美金現金 + 台幣折合美金 + 所有多幣別折合美金
        guard let latestAsset = monthlyAssets.first else {
            return 0.0
        }

        let cash = Double(latestAsset.cash ?? "0") ?? 0.0
        let twdToUsd = Double(latestAsset.twdToUsd ?? "0") ?? 0.0

        // 多幣別折合美金
        let eurToUsd = Double(latestAsset.eurToUsd ?? "0") ?? 0.0
        let jpyToUsd = Double(latestAsset.jpyToUsd ?? "0") ?? 0.0
        let gbpToUsd = Double(latestAsset.gbpToUsd ?? "0") ?? 0.0
        let cnyToUsd = Double(latestAsset.cnyToUsd ?? "0") ?? 0.0
        let audToUsd = Double(latestAsset.audToUsd ?? "0") ?? 0.0
        let cadToUsd = Double(latestAsset.cadToUsd ?? "0") ?? 0.0
        let chfToUsd = Double(latestAsset.chfToUsd ?? "0") ?? 0.0
        let hkdToUsd = Double(latestAsset.hkdToUsd ?? "0") ?? 0.0
        let sgdToUsd = Double(latestAsset.sgdToUsd ?? "0") ?? 0.0

        return cash + twdToUsd + eurToUsd + jpyToUsd + gbpToUsd + cnyToUsd + audToUsd + cadToUsd + chfToUsd + hkdToUsd + sgdToUsd
    }

    private func getMonthlyIncome() -> Double {
        // 本月收益（目前使用已確認利息）
        guard let latestAsset = monthlyAssets.first,
              let confirmedInterestStr = latestAsset.confirmedInterest,
              let confirmedInterest = Double(confirmedInterestStr) else {
            return 0.0
        }
        return confirmedInterest
    }

    // MARK: - 資產配置計算函數

    // 智能格式化百分比：>= 1% 顯示整數，< 1% 顯示小數點後兩位
    private func formatPercentage(_ percentage: Double) -> String {
        if percentage >= 1.0 {
            return String(format: "%.0f%%", percentage)
        } else if percentage > 0 {
            return String(format: "%.2f%%", percentage)
        } else {
            return "0%"
        }
    }

    private func getHighestAssetPercentage() -> (name: String, percentage: Double) {
        let assets = [
            ("美股", getUSStockPercentage()),
            ("債券", getBondsPercentage()),
            ("美金", getCashPercentage()),
            ("台幣", getTWDPercentage()),
            ("其他貨幣", getOtherCurrenciesPercentage()),
            ("台股", getTWStockPercentage()),
            ("結構型", getStructuredPercentage()),
            ("基金", getFundPercentage()),
            ("保險", getInsurancePercentage())
        ]

        let highest = assets.max(by: { $0.1 < $1.1 }) ?? ("", 0.0)
        return highest
    }

    private func getCashPercentage() -> Double {
        guard let latestAsset = monthlyAssets.first,
              let cashStr = latestAsset.cash,
              let totalStr = latestAsset.totalAssets,
              let cash = Double(cashStr),
              let total = Double(totalStr),
              total > 0 else {
            return 0.0
        }
        // 只計算純 USD 現金
        return (cash / total) * 100
    }

    private func getBondsPercentage() -> Double {
        // ⭐️ 資產配置仍然讀取月度資產明細
        guard let latestAsset = monthlyAssets.first,
              let bondsStr = latestAsset.bonds,
              let totalStr = latestAsset.totalAssets,
              let bonds = Double(bondsStr),
              let total = Double(totalStr),
              total > 0 else {
            return 0.0
        }
        return (bonds / total) * 100
    }

    private func getUSStockPercentage() -> Double {
        guard let latestAsset = monthlyAssets.first,
              let usStockStr = latestAsset.usStock,
              let totalStr = latestAsset.totalAssets,
              let usStock = Double(usStockStr),
              let total = Double(totalStr),
              total > 0 else {
            return 0.0
        }
        return (usStock / total) * 100
    }

    private func getTWStockPercentage() -> Double {
        guard let latestAsset = monthlyAssets.first,
              let twStockStr = latestAsset.taiwanStockFolded,
              let totalStr = latestAsset.totalAssets,
              let twStock = Double(twStockStr),
              let total = Double(totalStr),
              total > 0 else {
            return 0.0
        }
        return (twStock / total) * 100
    }

    private func getStructuredPercentage() -> Double {
        guard let latestAsset = monthlyAssets.first,
              let structuredStr = latestAsset.structured,
              let totalStr = latestAsset.totalAssets,
              let structured = Double(structuredStr),
              let total = Double(totalStr),
              total > 0 else {
            return 0.0
        }
        return (structured / total) * 100
    }

    private func getTWDPercentage() -> Double {
        guard let latestAsset = monthlyAssets.first,
              let twdToUsdStr = latestAsset.twdToUsd,
              let totalStr = latestAsset.totalAssets,
              let twdToUsd = Double(twdToUsdStr),
              let total = Double(totalStr),
              total > 0 else {
            return 0.0
        }
        return (twdToUsd / total) * 100
    }

    private func getOtherCurrenciesPercentage() -> Double {
        guard let latestAsset = monthlyAssets.first,
              let totalStr = latestAsset.totalAssets,
              let total = Double(totalStr),
              total > 0 else {
            return 0.0
        }

        // 計算所有其他貨幣折合美金的總和
        let eurToUsd = Double(latestAsset.eurToUsd ?? "0") ?? 0
        let jpyToUsd = Double(latestAsset.jpyToUsd ?? "0") ?? 0
        let gbpToUsd = Double(latestAsset.gbpToUsd ?? "0") ?? 0
        let cnyToUsd = Double(latestAsset.cnyToUsd ?? "0") ?? 0
        let audToUsd = Double(latestAsset.audToUsd ?? "0") ?? 0
        let cadToUsd = Double(latestAsset.cadToUsd ?? "0") ?? 0
        let chfToUsd = Double(latestAsset.chfToUsd ?? "0") ?? 0
        let hkdToUsd = Double(latestAsset.hkdToUsd ?? "0") ?? 0
        let sgdToUsd = Double(latestAsset.sgdToUsd ?? "0") ?? 0

        let otherCurrenciesTotal = eurToUsd + jpyToUsd + gbpToUsd + cnyToUsd + audToUsd +
                                  cadToUsd + chfToUsd + hkdToUsd + sgdToUsd

        return (otherCurrenciesTotal / total) * 100
    }

    private func getFundPercentage() -> Double {
        guard let latestAsset = monthlyAssets.first,
              let fundStr = latestAsset.fund,
              let totalStr = latestAsset.totalAssets,
              let fund = Double(fundStr),
              let total = Double(totalStr),
              total > 0 else {
            return 0.0
        }
        return (fund / total) * 100
    }

    private func getInsurancePercentage() -> Double {
        guard let latestAsset = monthlyAssets.first,
              let insuranceStr = latestAsset.insurance,
              let totalStr = latestAsset.totalAssets,
              let insurance = Double(insuranceStr),
              let total = Double(totalStr),
              total > 0 else {
            return 0.0
        }
        return (insurance / total) * 100
    }

    // MARK: - 投資卡片計算函數
    private func getUSStockValue() -> Double {
        // ⭐️ 小卡顯示的數字完全從即時持倉計算
        return getUSStockValueFromInventory()
    }

    // 從持倉明細計算美股即時市值
    private func getUSStockValueFromInventory() -> Double {
        guard let client = client else { return 0.0 }

        let fetchRequest: NSFetchRequest<USStock> = USStock.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        guard let usStocks = try? viewContext.fetch(fetchRequest) else {
            return 0.0
        }

        var totalMarketValue = 0.0
        for stock in usStocks {
            if let marketValueStr = stock.marketValue,
               let marketValue = Double(marketValueStr) {
                totalMarketValue += marketValue
            }
        }

        return totalMarketValue
    }

    private func getUSStockReturnRate() -> Double {
        // ⭐️ 報酬率完全從即時持倉計算
        return getUSStockReturnRateFromInventory()
    }

    // 從持倉明細計算美股即時報酬率
    private func getUSStockReturnRateFromInventory() -> Double {
        guard let client = client else { return 0.0 }

        // 獲取該客戶的所有美股持倉
        let fetchRequest: NSFetchRequest<USStock> = USStock.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        guard let usStocks = try? viewContext.fetch(fetchRequest) else {
            return 0.0
        }

        // 計算總市值和總成本
        var totalMarketValue = 0.0
        var totalCost = 0.0

        for stock in usStocks {
            if let marketValueStr = stock.marketValue,
               let costStr = stock.cost,
               let marketValue = Double(marketValueStr),
               let cost = Double(costStr) {
                totalMarketValue += marketValue
                totalCost += cost
            }
        }

        // 計算報酬率
        guard totalCost > 0 else { return 0.0 }
        return ((totalMarketValue - totalCost) / totalCost) * 100
    }

    private func getTWStockValue() -> Double {
        // ⭐️ 小卡顯示的數字完全從即時持倉計算
        return getTWStockValueFromInventory()
    }

    // 從持倉明細計算台股即時市值
    private func getTWStockValueFromInventory() -> Double {
        guard let client = client else { return 0.0 }

        let fetchRequest: NSFetchRequest<TWStock> = TWStock.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        guard let twStocks = try? viewContext.fetch(fetchRequest) else {
            return 0.0
        }

        var totalMarketValue = 0.0
        for stock in twStocks {
            if let marketValueStr = stock.marketValue,
               let marketValue = Double(marketValueStr) {
                totalMarketValue += marketValue
            }
        }

        return totalMarketValue
    }

    private func getTWStockReturnRate() -> Double {
        // ⭐️ 報酬率完全從即時持倉計算
        return getTWStockReturnRateFromInventory()
    }

    // 從持倉明細計算台股即時報酬率
    private func getTWStockReturnRateFromInventory() -> Double {
        guard let client = client else { return 0.0 }

        // 獲取該客戶的所有台股持倉
        let fetchRequest: NSFetchRequest<TWStock> = TWStock.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        guard let twStocks = try? viewContext.fetch(fetchRequest) else {
            return 0.0
        }

        // 計算總市值和總成本
        var totalMarketValue = 0.0
        var totalCost = 0.0

        for stock in twStocks {
            if let marketValueStr = stock.marketValue,
               let costStr = stock.cost,
               let marketValue = Double(marketValueStr),
               let cost = Double(costStr) {
                totalMarketValue += marketValue
                totalCost += cost
            }
        }

        // 計算報酬率
        guard totalCost > 0 else { return 0.0 }
        return ((totalMarketValue - totalCost) / totalCost) * 100
    }

    // MARK: - 結構型商品投資計算函數
    private func getStructuredProductValue() -> Double {
        // 從持倉明細計算結構型商品總額
        return structuredProducts.reduce(0.0) { total, product in
            let transactionAmount = Double(product.transactionAmount?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
            return total + transactionAmount
        }
    }

    private func getStructuredProductAverageRate() -> Double {
        // 計算平均利率
        guard !structuredProducts.isEmpty else { return 0.0 }

        let totalRate = structuredProducts.reduce(0.0) { total, product in
            let rate = Double(product.interestRate?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
            return total + rate
        }

        return totalRate / Double(structuredProducts.count)
    }

    // MARK: - 基金投資計算函數
    private func getFundValue() -> Double {
        // 基金金額
        guard let latestAsset = monthlyAssets.first,
              let fundStr = latestAsset.fund,
              let fund = Double(fundStr) else {
            return 0.0
        }
        return fund
    }

    private func getFundReturnRate() -> Double {
        // 基金報酬率 = (基金 - 基金成本) / 基金成本 * 100
        guard let latestAsset = monthlyAssets.first,
              let fundStr = latestAsset.fund,
              let fundCostStr = latestAsset.fundCost,
              let fund = Double(fundStr),
              let fundCost = Double(fundCostStr),
              fundCost > 0 else {
            return 0.0
        }
        return ((fund - fundCost) / fundCost) * 100
    }

    private func getFundTrendData() -> [Double] {
        // 基金趨勢資料（取最近6筆的報酬率）
        let recentAssets = Array(monthlyAssets.prefix(6).reversed())
        return recentAssets.map { asset in
            guard let fundStr = asset.fund,
                  let fundCostStr = asset.fundCost,
                  let fund = Double(fundStr),
                  let fundCost = Double(fundCostStr),
                  fundCost > 0 else {
                return 0.0
            }
            return ((fund - fundCost) / fundCost) * 100
        }
    }

    // MARK: - 保險投資計算函數
    private func getInsuranceValue() -> Double {
        // 保險金額
        guard let latestAsset = monthlyAssets.first,
              let insuranceStr = latestAsset.insurance,
              let insurance = Double(insuranceStr) else {
            return 0.0
        }
        return insurance
    }

    private func getRegularInvestmentValue() -> Double {
        // 定期定額金額
        guard let latestAsset = monthlyAssets.first,
              let regularStr = latestAsset.regularInvestment,
              let regular = Double(regularStr) else {
            return 0.0
        }
        return regular
    }

    private func getRegularInvestmentReturnRate() -> Double {
        // 定期定額報酬率 = (定期定額 - 定期定額成本) / 定期定額成本 * 100
        guard let latestAsset = monthlyAssets.first,
              let regularStr = latestAsset.regularInvestment,
              let regularCostStr = latestAsset.regularInvestmentCost,
              let regular = Double(regularStr),
              let regularCost = Double(regularCostStr),
              regularCost > 0 else {
            return 0.0
        }
        return ((regular - regularCost) / regularCost) * 100
    }

    private func getBondsValue() -> Double {
        // ⭐️ 根據編輯模式選擇資料來源
        if bondEditMode == .batchUpdate {
            // 批次更新模式：優先使用最新的 BondUpdateRecord
            if let latestRecord = bondUpdateRecords.first {
                return Double(removeCommas(latestRecord.totalCurrentValue ?? "0")) ?? 0
            } else {
                // 如果沒有歷史記錄，嘗試從 UserDefaults 讀取（向下兼容）
                let valueStr = getBatchTotalValue()
                return Double(removeCommas(valueStr)) ?? 0
            }
        }

        // 逐一更新模式：從持倉計算（含貨幣轉換）
        return getBondsTotalCurrentValue()
    }

    private func getBondsReturnRate() -> Double {
        // ⭐️ 根據編輯模式選擇資料來源並計算報酬率
        return getBondsTotalReturnRate()
    }

    // 計算公司債總成本（交易金額，含貨幣轉換）
    private func getBondsTotalCost() -> Double {
        return corporateBonds.reduce(0.0) { total, bond in
            let currency = bond.currency ?? "USD"
            let cost = Double(removeCommas(bond.transactionAmount ?? "0")) ?? 0

            // USD 債券直接使用成本
            if currency == "USD" {
                return total + cost
            }

            // 非 USD 債券需要轉換
            guard let rateString = getExchangeRate(for: currency),
                  !rateString.isEmpty,
                  let rateValue = Double(rateString),
                  rateValue > 0 else {
                return total
            }

            // 計算折合美金 = 成本 ÷ 匯率
            let convertedUSD = cost / rateValue
            return total + convertedUSD
        }
    }

    // 計算公司債總現值（含貨幣轉換）
    private func getBondsTotalCurrentValue() -> Double {
        return corporateBonds.reduce(0.0) { total, bond in
            let currency = bond.currency ?? "USD"
            let currentValue = Double(removeCommas(bond.currentValue ?? "0")) ?? 0

            // USD 債券直接使用現值
            if currency == "USD" {
                return total + currentValue
            }

            // 非 USD 債券需要轉換
            guard let rateString = getExchangeRate(for: currency),
                  !rateString.isEmpty,
                  let rateValue = Double(rateString),
                  rateValue > 0 else {
                return total
            }

            // 計算折合美金 = 現值 ÷ 匯率
            let convertedUSD = currentValue / rateValue
            return total + convertedUSD
        }
    }

    // 計算公司債總已領利息（含貨幣轉換）
    private func getBondsTotalReceivedInterest() -> Double {
        return corporateBonds.reduce(0.0) { total, bond in
            let currency = bond.currency ?? "USD"
            let receivedInterest = Double(removeCommas(bond.receivedInterest ?? "0")) ?? 0

            // USD 債券直接使用已領利息
            if currency == "USD" {
                return total + receivedInterest
            }

            // 非 USD 債券需要轉換
            guard let rateString = getExchangeRate(for: currency),
                  !rateString.isEmpty,
                  let rateValue = Double(rateString),
                  rateValue > 0 else {
                return total
            }

            // 計算折合美金 = 已領利息 ÷ 匯率
            let convertedUSD = receivedInterest / rateValue
            return total + convertedUSD
        }
    }

    // MARK: - 批次更新資料（UserDefaults）⭐️ 新方案：類似合計行，簡單穩定
    private func getBatchTotalValue() -> String {
        guard let client = client else { return "" }
        let clientID = client.objectID.uriRepresentation().absoluteString
        let key = "bondsTotalValue_\(clientID)"
        return UserDefaults.standard.string(forKey: key) ?? ""
    }

    private func getBatchTotalInterest() -> String {
        guard let client = client else { return "" }
        let clientID = client.objectID.uriRepresentation().absoluteString
        let key = "bondsTotalInterest_\(clientID)"
        return UserDefaults.standard.string(forKey: key) ?? ""
    }

    // 計算公司債總報酬率（根據模式選擇資料來源）
    private func getBondsTotalReturnRate() -> Double {
        let totalCost = getBondsTotalCost()
        guard totalCost > 0 else { return 0 }

        let totalCurrentValue: Double
        let totalReceivedInterest: Double

        // 根據債券編輯模式決定使用的數據源
        if bondEditMode == .batchUpdate {
            // ⭐️ 使用最新的 BondUpdateRecord（如果有的話）
            if let latestRecord = bondUpdateRecords.first {
                totalCurrentValue = Double(removeCommas(latestRecord.totalCurrentValue ?? "0")) ?? 0
                totalReceivedInterest = Double(removeCommas(latestRecord.totalInterest ?? "0")) ?? 0
            } else {
                // 如果沒有歷史記錄，嘗試從 UserDefaults 讀取（向下兼容）
                let valueStr = getBatchTotalValue()
                let interestStr = getBatchTotalInterest()
                totalCurrentValue = Double(removeCommas(valueStr)) ?? 0
                totalReceivedInterest = Double(removeCommas(interestStr)) ?? 0
            }
        } else {
            // 從債券資料計算(已折合美金)
            totalCurrentValue = getBondsTotalCurrentValue()
            totalReceivedInterest = getBondsTotalReceivedInterest()
        }

        return ((totalCurrentValue - totalCost + totalReceivedInterest) / totalCost) * 100
    }

    // MARK: - 獲取匯率
    private func getExchangeRate(for currency: String) -> String? {
        switch currency {
        case "TWD": return exchangeRate
        case "EUR": return eurRate
        case "JPY": return jpyRate
        case "GBP": return gbpRate
        case "CNY": return cnyRate
        case "AUD": return audRate
        case "CAD": return cadRate
        case "CHF": return chfRate
        case "HKD": return hkdRate
        case "SGD": return sgdRate
        default: return nil
        }
    }

    // MARK: - 債券分類計算函數（按債券名稱分組）
    private func getBondsByName() -> [(name: String, value: Double, percentage: Double)] {
        // 計算總額（使用申購金額）
        let totalValue = corporateBonds
            .compactMap { bond -> Double? in
                if let amountStr = bond.subscriptionAmount, !amountStr.isEmpty,
                   let amount = Double(amountStr), amount > 0 {
                    return amount
                }
                return nil
            }
            .reduce(0, +)

        guard totalValue > 0 else { return [] }

        // 按債券名稱分組並計算每個債券的總值
        var bondGroups: [String: Double] = [:]
        for bond in corporateBonds {
            let name = bond.bondName ?? "未命名"
            let value = Double(bond.subscriptionAmount ?? "0") ?? 0
            bondGroups[name, default: 0] += value
        }

        // 轉換成陣列並計算百分比，按金額降序排列
        return bondGroups.map { (name: $0.key, value: $0.value, percentage: ($0.value / totalValue) * 100) }
            .sorted { $0.value > $1.value }
    }

    private func getTopBond() -> (name: String, percentage: Double) {
        let bonds = getBondsByName()
        guard let top = bonds.first else { return ("", 0.0) }
        return (top.name, top.percentage)
    }

    // MARK: - 投資走勢數據函數
    private func getUSStockTrendData() -> [Double] {
        let sortedAssets = monthlyAssets
            .sorted { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }

        // 根據選擇的時間範圍篩選資料
        let filteredAssets = filterAssetsByPeriod(sortedAssets)

        return filteredAssets.compactMap { asset -> Double? in
            guard let valueStr = asset.usStock else { return nil }
            return Double(valueStr)
        }
    }

    private func getTWStockTrendData() -> [Double] {
        let sortedAssets = monthlyAssets
            .sorted { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }

        // 根據選擇的時間範圍篩選資料
        let filteredAssets = filterAssetsByPeriod(sortedAssets)

        return filteredAssets.compactMap { asset -> Double? in
            guard let valueStr = asset.taiwanStockFolded else { return nil }
            return Double(valueStr)
        }
    }

    private func getRegularInvestmentTrendData() -> [Double] {
        let sortedAssets = monthlyAssets
            .sorted { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }

        // 根據選擇的時間範圍篩選資料
        let filteredAssets = filterAssetsByPeriod(sortedAssets)

        return filteredAssets.compactMap { asset -> Double? in
            guard let valueStr = asset.regularInvestment else { return nil }
            return Double(valueStr)
        }
    }

    private func getBondsTrendData() -> [Double] {
        // ⭐️ 走勢圖仍然讀取月度資產明細
        let sortedAssets = monthlyAssets
            .sorted { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }

        // 根據選擇的時間範圍篩選資料
        let filteredAssets = filterAssetsByPeriod(sortedAssets)

        return filteredAssets.compactMap { asset -> Double? in
            guard let valueStr = asset.bonds else { return nil }
            return Double(valueStr)
        }
    }

    // 根據時間範圍篩選資料的共用函數
    private func filterAssetsByPeriod(_ assets: [MonthlyAsset]) -> [MonthlyAsset] {
        switch selectedPeriod {
        case "ALL":
            return assets
        case "7D":
            return Array(assets.suffix(7))
        case "1M":
            return Array(assets.suffix(1))
        case "3M":
            return Array(assets.suffix(3))
        case "1Y":
            return Array(assets.suffix(12))
        default:
            return assets
        }
    }

    // MARK: - 債券每月配息計算函數
    private func getMonthlyDividends(for currency: String? = nil) -> [Double] {
        // 初始化 12 個月的配息陣列
        var monthlyDividends: [Double] = Array(repeating: 0.0, count: 12)

        // 遍歷所有公司債
        for bond in corporateBonds {
            // 如果指定幣別，則篩選
            if let currency = currency {
                let bondCurrency = bond.currency ?? "USD"
                if bondCurrency != currency {
                    continue
                }
            }
            // 讀取配息月份（例如："1,3,6,9" 或 "1,2,3,4,5,6,7,8,9,10,11,12"）
            guard let dividendMonthsStr = bond.dividendMonths, !dividendMonthsStr.isEmpty else {
                continue
            }

            // 讀取單次配息金額
            guard let singleDividendStr = bond.singleDividend, !singleDividendStr.isEmpty,
                  let singleDividend = Double(singleDividendStr) else {
                continue
            }

            // 解析配息月份（支援多種格式）
            // 格式1: "1,3,6,9" 或 "1, 3, 6, 9"
            // 格式2: "1月/7月" 或 "3月/9月"
            // 格式3: "1月、7月" 或 "3月、9月"（頓號格式）
            // 格式4: "Jan/Jul" 或 "March/September"

            var months: [Int] = []

            // 先嘗試用逗號或頓號分隔
            if dividendMonthsStr.contains(",") || dividendMonthsStr.contains("、") {
                // 統一替換頓號為逗號
                let normalized = dividendMonthsStr.replacingOccurrences(of: "、", with: ",")
                months = normalized.split(separator: ",")
                    .compactMap { part -> Int? in
                        let cleaned = part.trimmingCharacters(in: .whitespaces)
                            .replacingOccurrences(of: "月", with: "")
                        return Int(cleaned)
                    }
                    .filter { $0 >= 1 && $0 <= 12 }
            }
            // 嘗試用斜線分隔（例如："1月/7月"）
            else if dividendMonthsStr.contains("/") {
                months = dividendMonthsStr.split(separator: "/")
                    .compactMap { part -> Int? in
                        let cleaned = part.trimmingCharacters(in: .whitespaces)
                            .replacingOccurrences(of: "月", with: "")
                        return Int(cleaned)
                    }
                    .filter { $0 >= 1 && $0 <= 12 }
            }
            // 單一數字
            else if let month = Int(dividendMonthsStr.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "月", with: "")) {
                if month >= 1 && month <= 12 {
                    months = [month]
                }
            }

            // 將配息加到對應月份
            for month in months {
                monthlyDividends[month - 1] += singleDividend
            }
        }

        return monthlyDividends
    }

    private func getTotalAnnualDividend(for currency: String? = nil) -> Double {
        return getMonthlyDividends(for: currency).reduce(0, +)
    }

    private func getMonthHeight(_ month: Int, for currency: String? = nil) -> CGFloat {
        let dividends = getMonthlyDividends(for: currency)
        let dividend = dividends[month - 1]

        // 如果該月沒有配息，返回 0（不顯示長條）
        guard dividend > 0 else {
            return 0
        }

        let maxDividend = dividends.max() ?? 1.0

        // 如果沒有任何配息，返回 0
        guard maxDividend > 0 else {
            return 0
        }

        // 根據配息金額計算高度（最小 10，最大 80）
        let normalizedHeight = (dividend / maxDividend) * 60 + 10
        return CGFloat(normalizedHeight)
    }

    // MARK: - 格式化函數
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? "0"

        // 根據選擇的幣別顯示不同的符號
        if selectedCurrency == "台幣" {
            return "$\(formattedNumber)"
        } else {
            return "$\(formattedNumber)"
        }
    }

    private func formatCurrencyWithoutSymbol(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    private func formatPnL(_ amount: Double) -> String {
        let sign = amount >= 0 ? "+" : ""
        return "\(sign)\(formatCurrency(abs(amount)))"
    }

    private func formatReturnRate(_ rate: Double) -> String {
        let sign = rate >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", rate))%"
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - 美股詳細資料計算

    // 計算美股總市值
    private func getTotalUSStockMarketValue() -> Double {
        var total: Double = 0.0
        for stock in usStocks {
            if let marketValueStr = stock.marketValue,
               let marketValue = Double(removeCommas(marketValueStr)) {
                total += marketValue
            }
        }
        return total
    }

    // 計算每支股票的市值比例
    private func getStockPercentage(stock: USStock) -> Double {
        let totalMarketValue = getTotalUSStockMarketValue()
        guard totalMarketValue > 0,
              let marketValueStr = stock.marketValue,
              let marketValue = Double(removeCommas(marketValueStr)) else {
            return 0.0
        }
        return (marketValue / totalMarketValue) * 100
    }

    // 取得美股列表（按市值降序排列）
    private func getSortedUSStocks() -> [USStock] {
        return usStocks.sorted { stock1, stock2 in
            let value1 = Double(removeCommas(stock1.marketValue ?? "0")) ?? 0
            let value2 = Double(removeCommas(stock2.marketValue ?? "0")) ?? 0
            return value1 > value2
        }
    }

    // 取得前N支股票和其他
    private func getTopStocksAndOthers(limit: Int = 5) -> (topStocks: [USStock], othersPercentage: Double) {
        let sortedStocks = getSortedUSStocks()
        let topStocks = Array(sortedStocks.prefix(limit))
        let othersStocks = Array(sortedStocks.dropFirst(limit))

        var othersTotal: Double = 0.0
        for stock in othersStocks {
            othersTotal += getStockPercentage(stock: stock)
        }

        return (topStocks, othersTotal)
    }

    // 移除千分位逗號的輔助函數
    private func removeCommas(_ value: String) -> String {
        return value.replacingOccurrences(of: ",", with: "")
    }
}

// MARK: - 折線圖組件
struct LineChartView: View {
    let color: Color
    let dataPoints: [Double]  // 新增：接收真實數據

    init(color: Color, dataPoints: [Double] = []) {
        self.color = color
        self.dataPoints = dataPoints
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let points = generatePoints(width: width, height: height)

            ZStack {
                // 漸層填充區域（線條下方）
                fillArea(points: points, height: height)

                // 漸層線條
                gradientLine(points: points)
            }
        }
    }

    // 填充區域
    private func fillArea(points: [CGPoint], height: CGFloat) -> some View {
        var path = Path()
        if !points.isEmpty {
            path.move(to: CGPoint(x: points[0].x, y: height))
            path.addLine(to: points[0])

            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            path.addLine(to: CGPoint(x: points.last!.x, y: height))
            path.closeSubpath()
        }

        return path.fill(
            LinearGradient(
                gradient: Gradient(colors: [
                    color.opacity(0.3),
                    color.opacity(0.02)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // 漸層線條
    private func gradientLine(points: [CGPoint]) -> some View {
        var path = Path()
        if !points.isEmpty {
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }

        return path.stroke(
            LinearGradient(
                gradient: Gradient(colors: [
                    color,
                    color.opacity(0.7)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            lineWidth: 2.5
        )
    }

    private func generatePoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        // 如果有真實數據，使用真實數據；否則使用模擬數據
        let values: [CGFloat]
        if !dataPoints.isEmpty {
            // 歸一化真實數據到 0-1 範圍
            let minVal = dataPoints.min() ?? 0
            let maxVal = dataPoints.max() ?? 1
            let range = maxVal - minVal

            values = dataPoints.map { value in
                if range > 0 {
                    return CGFloat((value - minVal) / range)
                } else {
                    return 0.5
                }
            }
        } else {
            // 模擬數據（保持原有邏輯）
            values = [0.3, 0.7, 0.4, 0.8, 0.6, 0.9, 0.5, 0.8, 0.7, 0.6, 0.9, 0.8]
        }

        let stepX = width / CGFloat(max(values.count - 1, 1))

        return values.enumerated().map { index, value in
            CGPoint(
                x: CGFloat(index) * stepX,
                y: height - (value * height)
            )
        }
    }

}

// MARK: - 自適應顏色擴展
extension Color {
    /// 卡片和表格背景色：淺色模式為白色，深色模式為深灰色
    static var adaptiveCardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)  // 深色模式：深灰色
                : UIColor.white  // 淺色模式：白色
        })
    }
}
