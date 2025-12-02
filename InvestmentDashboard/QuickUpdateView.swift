import SwiftUI
import CoreData

// MARK: - 自定義環境變數：卡片強調色
private struct CardAccentColorKey: EnvironmentKey {
    static let defaultValue: Color = .primary
}

extension EnvironmentValues {
    var cardAccentColor: Color {
        get { self[CardAccentColorKey.self] }
        set { self[CardAccentColorKey.self] = newValue }
    }
}

// MARK: - 債券編輯模式
enum BondEditMode: String, CaseIterable {
    case batchUpdate = "更新總額、總利息"
    case individualUpdate = "逐一更新現值、已領息"
}

struct QuickUpdateView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager  // ⭐️ 訂閱管理器
    let client: Client

    // FetchRequest 取得當前客戶的月度資產（按日期降序，取最新一筆）
    @FetchRequest private var monthlyAssets: FetchedResults<MonthlyAsset>

    // FetchRequest 取得當前客戶的美股
    @FetchRequest private var usStocks: FetchedResults<USStock>

    // FetchRequest 取得當前客戶的台股
    @FetchRequest private var taiwanStocks: FetchedResults<TWStock>

    // FetchRequest 取得當前客戶的公司債
    @FetchRequest private var corporateBonds: FetchedResults<CorporateBond>

    // FetchRequest 取得當前客戶的債券更新記錄
    @FetchRequest private var bondUpdateRecords: FetchedResults<BondUpdateRecord>

    // FetchRequest 取得當前客戶的結構型商品
    @FetchRequest private var structuredProducts: FetchedResults<StructuredProduct>

    // FetchRequest 取得當前客戶的定期定額
    @FetchRequest private var regularInvestments: FetchedResults<RegularInvestment>

    // FetchRequest 取得當前客戶的投資群組
    @FetchRequest private var usStockGroups: FetchedResults<InvestmentGroup>
    @FetchRequest private var twStockGroups: FetchedResults<InvestmentGroup>
    @FetchRequest private var bondGroups: FetchedResults<InvestmentGroup>
    @FetchRequest private var structuredGroups: FetchedResults<InvestmentGroup>

    // FetchRequest 取得所有客戶（用於批次新增）
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.sortOrder, ascending: true)],
        animation: .default
    )
    private var allClients: FetchedResults<Client>

    // 展開狀態
    @State private var expandedSections: Set<String> = []

    // 彈出視圖控制
    @State private var showingUSStockInventory = false
    @State private var showingTWStockInventory = false
    @State private var showingAddMonthlyData = false
    @State private var showingCurrencyPicker = false
    @State private var selectedCurrency: String? = nil
    @State private var showingCurrencyInput = false
    @State private var currencyInputValue = ""
    @State private var currencyInputType = "cash" // "cash" 或 "rate"

    // 股價更新狀態
    @State private var isUpdatingUSStock = false
    @State private var isUpdatingTWStock = false
    @State private var isUpdatingAllStocks = false
    @State private var showUpdateAlert = false
    @State private var updateAlertTitle = ""
    @State private var updateAlertMessage = ""

    // 匯率更新狀態
    @State private var isUpdatingExchangeRate = false

    // 債券編輯相關狀態（⭐️ 使用 UserDefaults 實現跨視圖同步）
    @State private var showingBondEditSheet = false
    @State private var showingBondBatchInput = false // ⭐️ 批次輸入畫面
    @State private var bondEditModeRawValue: String = BondEditMode.individualUpdate.rawValue
    @State private var isUpdatingBonds = false
    @State private var tempBondsTotalValue: String = ""
    @State private var tempBondsTotalInterest: String = ""
    @State private var isLoadingBondData: Bool = false // ⭐️ 防止載入時觸發儲存
    @State private var showingSaveSuccessAlert = false // ⭐️ 儲存成功提醒
    @State private var saveSuccessMessage = "" // ⭐️ 儲存成功訊息

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
                UserDefaults.standard.set(newValue.rawValue, forKey: self.clientSpecificBondEditModeKey)
                // 發送通知，通知其他視圖模式已變更
                NotificationCenter.default.post(name: .init("BondEditModeDidChange"), object: nil)
                print("✅ 左滑輸入區：債券編輯模式已變更為：\(newValue.rawValue)")
            }
        )
    }

    // MARK: - 客戶專屬儲存鍵值
    private var clientSpecificBondEditModeKey: String {
        let clientID = client.objectID.uriRepresentation().absoluteString
        return "bondEditMode_\(clientID)"
    }

    // MARK: - 客戶特定的 UserDefaults Key
    private var clientSpecificTotalValueKey: String {
        let clientID = client.objectID.uriRepresentation().absoluteString
        return "bondsTotalValue_\(clientID)"
    }

    private var clientSpecificTotalInterestKey: String {
        let clientID = client.objectID.uriRepresentation().absoluteString
        return "bondsTotalInterest_\(clientID)"
    }

    // 從 UserDefaults 載入數據
    private func loadBatchData() {
        isLoadingBondData = true // ⭐️ 設定載入中標記，防止觸發 onChange 儲存

        // 載入債券編輯模式
        bondEditModeRawValue = UserDefaults.standard.string(forKey: clientSpecificBondEditModeKey) ?? BondEditMode.individualUpdate.rawValue

        // ⭐️ 優先從 BondUpdateRecord 載入（CoreData）
        if let latestRecord = bondUpdateRecords.first {
            tempBondsTotalValue = latestRecord.totalCurrentValue ?? ""
            tempBondsTotalInterest = latestRecord.totalInterest ?? ""
            print("✅ 載入批次數據（從 CoreData），客戶: \(client.name ?? "Unknown"), 模式: \(bondEditModeRawValue), 總現值: \(tempBondsTotalValue), 總利息: \(tempBondsTotalInterest)")
        } else {
            // 沒有歷史記錄，清空輸入框
            tempBondsTotalValue = ""
            tempBondsTotalInterest = ""
            print("✅ 載入批次數據（無記錄），客戶: \(client.name ?? "Unknown"), 模式: \(bondEditModeRawValue)")
        }

        isLoadingBondData = false // ⭐️ 載入完成，解除標記
    }

    // ⭐️ 保存數據到 CoreData 的 BondUpdateRecord
    private func saveBatchData() {
        // 檢查是否有值需要保存
        guard !tempBondsTotalValue.isEmpty || !tempBondsTotalInterest.isEmpty else {
            print("⚠️ 批次數據為空，不保存")
            return
        }

        // ⭐️ 每次都創建新的歷史記錄（與債券小卡行為一致）
        let newRecord = BondUpdateRecord(context: viewContext)
        newRecord.recordDate = Date()
        newRecord.totalCurrentValue = tempBondsTotalValue
        newRecord.totalInterest = tempBondsTotalInterest
        newRecord.createdDate = Date()
        newRecord.client = client

        // 儲存到 CoreData
        do {
            try viewContext.save()
            print("✅ 保存批次數據到 CoreData（新記錄），客戶: \(client.name ?? "Unknown"), 日期: \(Date()), 總現值: \(tempBondsTotalValue), 總利息: \(tempBondsTotalInterest)")

            // ⭐️ 設置成功提醒訊息
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
            let dateString = dateFormatter.string(from: Date())

            let totalValue = formatCurrency(tempBondsTotalValue)
            let totalInterest = formatCurrency(tempBondsTotalInterest)

            saveSuccessMessage = "儲存成功！\n\n日期：\(dateString)\n總現值：\(totalValue)\n總已領息：\(totalInterest)"
            showingSaveSuccessAlert = true
        } catch {
            print("❌ 保存批次數據失敗：\(error)")
            saveSuccessMessage = "儲存失敗：\(error.localizedDescription)"
            showingSaveSuccessAlert = true
        }
    }

    // ⭐️ 格式化貨幣顯示
    private func formatCurrency(_ value: String) -> String {
        guard let number = Double(value.replacingOccurrences(of: ",", with: "")) else {
            return "$0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return "$\(formatter.string(from: NSNumber(value: number)) ?? "0")"
    }

    // 臨時現金輸入數據（從前一筆月度資產載入）
    @State private var tempTWDCash: String = ""
    @State private var tempUSDCash: String = ""
    @AppStorage("exchangeRate") private var tempExchangeRate: String = "32"
    @State private var showingTWDInput = false
    @State private var showingUSDInput = false

    // 多幣別現金數據
    @State private var addedCurrencies: Set<String> = []
    @State private var expandedCurrencies: Set<String> = [] // 追蹤哪些幣別卡片是展開的
    @State private var tempEURCash: String = ""
    @State private var tempJPYCash: String = ""
    @State private var tempGBPCash: String = ""
    @State private var tempCNYCash: String = ""
    @State private var tempAUDCash: String = ""
    @State private var tempCADCash: String = ""
    @State private var tempCHFCash: String = ""
    @State private var tempHKDCash: String = ""
    @State private var tempSGDCash: String = ""

    // 多幣別匯率數據（使用 @AppStorage 以便跨視圖同步）
    @AppStorage("eurRate") private var tempEURRate: String = ""
    @AppStorage("jpyRate") private var tempJPYRate: String = ""
    @AppStorage("gbpRate") private var tempGBPRate: String = ""
    @AppStorage("cnyRate") private var tempCNYRate: String = ""
    @AppStorage("audRate") private var tempAUDRate: String = ""
    @AppStorage("cadRate") private var tempCADRate: String = ""
    @AppStorage("chfRate") private var tempCHFRate: String = ""
    @AppStorage("hkdRate") private var tempHKDRate: String = ""
    @AppStorage("sgdRate") private var tempSGDRate: String = ""

    // 可選項目的顯示狀態和數據
    @State private var showRegularInvestment = false
    @State private var showFund = false
    @State private var showInsurance = false
    @State private var tempRegularInvestment: String = ""
    @State private var tempFund: String = ""
    @State private var tempInsurance: String = ""
    @AppStorage("fundCurrency") private var tempFundCurrency: String = "TWD"
    @State private var showingAddItemPicker = false

    // 群組管理
    @State private var showingAddGroupDialog = false
    @State private var newGroupName = ""
    @State private var currentGroupType: String? = nil
    @State private var showingEditGroup: InvestmentGroup? = nil
    @State private var showingBondInventory = false
    @State private var showingStructuredInventory = false
    @State private var showingAddBond = false
    @State private var selectedBondForEdit: CorporateBond? = nil
    @State private var showingAddStructured = false  // 使用 BatchAddStructuredProductView
    @State private var showingStructuredDetail = false  // ⭐️ 顯示結構型商品詳細頁面

    init(client: Client) {
        self.client = client

        _monthlyAssets = FetchRequest<MonthlyAsset>(
            sortDescriptors: [NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)],
            predicate: NSPredicate(format: "client == %@ AND isLiveSnapshot == NO", client),
            animation: .default
        )

        _usStocks = FetchRequest<USStock>(
            sortDescriptors: [NSSortDescriptor(keyPath: \USStock.createdDate, ascending: false)],
            predicate: NSPredicate(format: "client == %@", client),
            animation: .default
        )

        _taiwanStocks = FetchRequest<TWStock>(
            sortDescriptors: [NSSortDescriptor(keyPath: \TWStock.createdDate, ascending: false)],
            predicate: NSPredicate(format: "client == %@", client),
            animation: .default
        )

        _corporateBonds = FetchRequest<CorporateBond>(
            sortDescriptors: [NSSortDescriptor(keyPath: \CorporateBond.createdDate, ascending: false)],
            predicate: NSPredicate(format: "client == %@ AND bondName != %@", client, "__BATCH_UPDATE__"),
            animation: .default
        )

        _bondUpdateRecords = FetchRequest<BondUpdateRecord>(
            sortDescriptors: [NSSortDescriptor(keyPath: \BondUpdateRecord.createdDate, ascending: false)],
            predicate: NSPredicate(format: "client == %@", client),
            animation: .default
        )

        _structuredProducts = FetchRequest<StructuredProduct>(
            sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
            predicate: NSPredicate(format: "client == %@", client),
            animation: .default
        )

        _regularInvestments = FetchRequest<RegularInvestment>(
            sortDescriptors: [NSSortDescriptor(keyPath: \RegularInvestment.createdDate, ascending: false)],
            predicate: NSPredicate(format: "client == %@", client),
            animation: .default
        )

        // 初始化群組 FetchRequest
        _usStockGroups = FetchRequest<InvestmentGroup>(
            sortDescriptors: [NSSortDescriptor(keyPath: \InvestmentGroup.orderIndex, ascending: true)],
            predicate: NSPredicate(format: "client == %@ AND groupType == %@", client, "usStock"),
            animation: .default
        )

        _twStockGroups = FetchRequest<InvestmentGroup>(
            sortDescriptors: [NSSortDescriptor(keyPath: \InvestmentGroup.orderIndex, ascending: true)],
            predicate: NSPredicate(format: "client == %@ AND groupType == %@", client, "twStock"),
            animation: .default
        )

        _bondGroups = FetchRequest<InvestmentGroup>(
            sortDescriptors: [NSSortDescriptor(keyPath: \InvestmentGroup.orderIndex, ascending: true)],
            predicate: NSPredicate(format: "client == %@ AND groupType == %@", client, "bond"),
            animation: .default
        )

        _structuredGroups = FetchRequest<InvestmentGroup>(
            sortDescriptors: [NSSortDescriptor(keyPath: \InvestmentGroup.orderIndex, ascending: true)],
            predicate: NSPredicate(format: "client == %@ AND groupType == %@", client, "structured"),
            animation: .default
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 頂部：總資產數字（非卡片）
                totalAssetsHeader

                // 可展開的卡片
                expandableCards
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 400)  // ⭐️ 添加底部 padding，避免鍵盤遮擋下方卡片
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingUSStockInventory) {
            USStockInventoryView(client: client)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingTWStockInventory) {
            TWStockInventoryView(client: client)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingAddMonthlyData) {
            AddMonthlyDataView(onSave: { _, _ in
                showingAddMonthlyData = false
            }, client: client)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("新增群組", isPresented: $showingAddGroupDialog) {
            TextField("群組名稱", text: $newGroupName)
            Button("取消", role: .cancel) {
                newGroupName = ""
                currentGroupType = nil
            }
            Button("新增") {
                if !newGroupName.isEmpty, let groupType = currentGroupType {
                    createNewGroup(name: newGroupName, groupType: groupType)
                    newGroupName = ""
                    currentGroupType = nil
                }
            }
        } message: {
            Text("請輸入群組名稱")
        }
        .sheet(item: $showingEditGroup) { group in
            GroupEditSheetView(group: group, groupType: groupTypeForGroup(group))
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingUSStockInventory) {
            USStockInventoryView(client: client)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingTWStockInventory) {
            TWStockInventoryView(client: client)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingBondInventory) {
            CorporateBondsInventoryView(client: client)
                .environment(\.managedObjectContext, viewContext)
                .id(client.objectID) // ⭐️ 強制在客戶變更時重新建立 view，避免快取問題
        }
        .sheet(isPresented: $showingStructuredInventory) {
            StructuredProductsInventoryView(client: client)
                .environment(\.managedObjectContext, viewContext)
                .id(client.objectID) // ⭐️ 強制在客戶變更時重新建立 view，避免快取問題
        }
        .sheet(isPresented: $showingAddBond) {
            AddMonthlyDataView(onSave: { _, _ in
                showingAddBond = false
            }, client: client, initialTab: 1, hideTabSelector: true, customTitle: "新增公司債")
            .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedBondForEdit) { bond in
            NavigationView {
                BondInventoryRow(
                    bond: bond,
                    onUpdate: {
                        saveContext()
                    },
                    onDelete: {
                        deleteBond(bond)
                        selectedBondForEdit = nil
                    }
                )
                .navigationTitle("編輯債券")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            selectedBondForEdit = nil
                        }
                    }
                }
            }
            .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingAddStructured) {
            BatchAddStructuredProductView(preselectedClient: client)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingStructuredDetail) {
            // ⭐️ 使用 CrossClientStructuredProductView，預設顯示「按客戶」模式
            CrossClientStructuredProductView(client: client)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("選擇幣別", isPresented: $showingCurrencyPicker) {
            Button("歐元 (EUR)") { addCurrency("EUR") }
            Button("日圓 (JPY)") { addCurrency("JPY") }
            Button("英鎊 (GBP)") { addCurrency("GBP") }
            Button("人民幣 (CNY)") { addCurrency("CNY") }
            Button("澳幣 (AUD)") { addCurrency("AUD") }
            Button("加幣 (CAD)") { addCurrency("CAD") }
            Button("瑞士法郎 (CHF)") { addCurrency("CHF") }
            Button("港幣 (HKD)") { addCurrency("HKD") }
            Button("新加坡幣 (SGD)") { addCurrency("SGD") }
            Button("取消", role: .cancel) {}
        } message: {
            Text("選擇要新增的幣別")
        }
        .alert("輸入\(getCurrencyName(selectedCurrency ?? ""))\(currencyInputType == "cash" ? "金額" : "匯率")", isPresented: $showingCurrencyInput) {
            TextField(currencyInputType == "cash" ? "金額" : "匯率", text: $currencyInputValue)
                .keyboardType(.decimalPad)
            Button("取消", role: .cancel) {
                selectedCurrency = nil
                currencyInputValue = ""
            }
            Button("確定") {
                if let currency = selectedCurrency, !currencyInputValue.isEmpty {
                    if currencyInputType == "cash" {
                        // 儲存現金金額
                        setCurrencyValue(currency, value: currencyInputValue)
                    } else {
                        // 儲存匯率
                        setCurrencyRate(currency, value: currencyInputValue)
                    }
                    // 清空並關閉
                    currencyInputValue = ""
                    selectedCurrency = nil
                }
            }
        } message: {
            Text("請輸入\(getCurrencyName(selectedCurrency ?? ""))\(currencyInputType == "cash" ? "金額" : "匯率")")
        }
        // 移除自動彈出輸入視窗的邏輯，改為點擊卡片各行來編輯
        .onAppear {
            loadInitialCashValues()
            loadBatchData()  // ⭐️ 從 UserDefaults 載入債券資料
        }
        // ⭐️ 監聽模式變更通知（其他視圖可能改變模式）
        .onReceive(NotificationCenter.default.publisher(for: .init("BondEditModeDidChange"))) { _ in
            isLoadingBondData = true // 防止觸發儲存
            bondEditModeRawValue = UserDefaults.standard.string(forKey: clientSpecificBondEditModeKey) ?? BondEditMode.batchUpdate.rawValue
            print("✅ 左滑輸入區：收到模式變更通知，已同步為：\(bondEditModeRawValue)")
            isLoadingBondData = false
        }
        // ⭐️ 移除模式切換時的自動儲存（避免切換到逐一更新時也儲存）
        // .onChange(of: bondEditModeRawValue) { _ in
        //     if !isLoadingBondData {
        //         saveBatchData()
        //     }
        // }
        // ⭐️ 移除自動儲存，改為手動按鈕儲存
        // .onChange(of: tempBondsTotalValue) { _ in
        //     if !isLoadingBondData {
        //         saveBatchData()
        //     }
        // }
        // .onChange(of: tempBondsTotalInterest) { _ in
        //     if !isLoadingBondData {
        //         saveBatchData()
        //     }
        // }
        .alert(selectedCurrency != nil ? "輸入\(selectedCurrency!)金額" : "輸入金額", isPresented: $showingCurrencyInput) {
            TextField("金額", text: $currencyInputValue)
                .keyboardType(.decimalPad)
            Button("取消", role: .cancel) {
                selectedCurrency = nil
            }
            Button("確定") {
                if let currency = selectedCurrency, !currencyInputValue.isEmpty {
                    addNewCurrency(currency, amount: currencyInputValue)
                }
                selectedCurrency = nil
            }
        } message: {
            Text("請輸入金額（美金）")
        }
        .alert("選擇項目", isPresented: $showingAddItemPicker) {
            if !showRegularInvestment {
                Button("定期定額") {
                    showRegularInvestment = true
                    tempRegularInvestment = "0"
                }
            }
            if !showFund {
                Button("基金") {
                    showFund = true
                    tempFund = "0"
                }
            }
            if !showInsurance {
                Button("保險") {
                    showInsurance = true
                    tempInsurance = "0"
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("選擇要新增的項目")
        }
        .alert(updateAlertTitle, isPresented: $showUpdateAlert) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(updateAlertMessage)
        }
        .alert("債券記錄", isPresented: $showingSaveSuccessAlert) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(saveSuccessMessage)
        }
        .sheet(isPresented: $showingBondEditSheet) {
            bondEditSheetView
        }
        .sheet(isPresented: $showingBondBatchInput) {
            bondBatchInputView
        }
    }

    // MARK: - 總資產標題
    private var totalAssetsHeader: some View {
        VStack(spacing: 4) {
            Text("總資產")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text(totalAssetsValue)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)

            Text("USD")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // 計算總資產（即時計算，不讀取已儲存的值）
    private var totalAssetsValue: String {
        // 計算各類資產總額
        let cashTotal = calculateCashTotalValue()
        let usStockTotal = calculateUSStockTotal()
        let twStockTotal = calculateTWStockTotal()
        let bondsTotal = calculateBondsTotal()
        let structuredTotal = calculateStructuredTotal()

        // 台股換算成美金（台股是台幣計價）
        let exchangeRate = Double(removeCommas(tempExchangeRate)) ?? 32
        let twStockInUSD = exchangeRate != 0 ? twStockTotal / exchangeRate : 0

        // 可選項目（如果顯示則計入總資產）
        let regularInvestmentTotal = calculateRegularInvestmentTotal()
        let fundTotal = showFund ? calculateFundTotal() : 0
        let insuranceTotal = showInsurance ? (Double(removeCommas(tempInsurance)) ?? 0) : 0

        // 加總所有資產（全部換算成美金）
        let total = cashTotal + usStockTotal + twStockInUSD + bondsTotal + structuredTotal + regularInvestmentTotal + fundTotal + insuranceTotal

        return formatCurrency(total)
    }

    // 計算現金總額（數值）- 使用臨時變數並換算成美金
    private func calculateCashTotalValue() -> Double {
        // 使用臨時變數計算現金總額（美金計價）
        let usd = Double(removeCommas(tempUSDCash)) ?? 0
        let twd = Double(removeCommas(tempTWDCash)) ?? 0
        let rate = Double(removeCommas(tempExchangeRate)) ?? 32

        // 台幣換算成美金
        let twdToUsd = rate != 0 ? twd / rate : 0

        // 計算所有多幣別折合美金
        var foreignCurrenciesTotal = 0.0
        for currency in addedCurrencies {
            let toUsd = Double(calculateCurrencyToUsd(currency: currency)) ?? 0
            foreignCurrenciesTotal += toUsd
        }

        // 現金總額 = 美金 + 台幣折合美金 + 所有多幣別折合美金
        return usd + twdToUsd + foreignCurrenciesTotal
    }

    // MARK: - 可展開的卡片
    private var expandableCards: some View {
        VStack(spacing: 12) {
            // 現金卡片（帶左側匯率更新按鈕）
            HStack(spacing: 8) {
                // 左側：匯率更新按鈕
                Button(action: {
                    Task {
                        await updateExchangeRates()
                    }
                }) {
                    VStack(spacing: 6) {
                        if isUpdatingExchangeRate {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: "dollarsign.arrow.circlepath")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(width: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.teal,
                            Color.teal.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(12)
                .disabled(isUpdatingExchangeRate)

                // 右側：現金卡片
                ExpandableCard(
                    title: "現金",
                    amount: calculateCashTotal(),
                    updateDate: getLatestUpdateDate(),
                    accentColor: .teal,  // 與保險對調
                    isExpanded: expandedSections.contains("cash"),
                    useAccentColorWhenExpanded: true
                ) {
                    toggleSection("cash")
                } content: {
                    cashContent
                }
                .opacity(isUpdatingExchangeRate ? 0.6 : 1.0)
            }

            // 美股 + 台股（帶長條更新按鈕）
            HStack(spacing: 8) {
                // 左側：長條更新按鈕（橫跨兩個卡片）
                Button(action: {
                    Task {
                        await updateAllStockPrices()
                    }
                }) {
                    VStack(spacing: 6) {
                        if isUpdatingAllStocks {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(width: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),
                            Color(.init(red: 0.20, green: 0.40, blue: 0.30, alpha: 1.0))
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(12)
                .disabled(isUpdatingAllStocks)

                // 右側：美股 + 台股 + 結構型商品卡片
                VStack(spacing: 12) {
                    // 美股卡片（移除個別更新按鈕）
                    ExpandableCard(
                        title: "美股",
                        amount: formatAmount(calculateUSStockTotal()),
                        updateDate: getLatestUpdateDate(),
                        accentColor: .blue,
                        isExpanded: expandedSections.contains("usStock"),
                        customExpandedColor: Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),  // 展開時使用綠色背景
                        onTap: {
                            toggleSection("usStock")
                        },
                        content: {
                            usStockContent
                        }
                    )
                    .opacity(isUpdatingUSStock ? 0.6 : 1.0)

                    // 台股卡片（移除個別更新按鈕）
                    ExpandableCard(
                        title: "台股",
                        amount: formatAmount(calculateTWStockTotal()),
                        updateDate: getLatestUpdateDate(),
                        accentColor: .orange,
                        isExpanded: expandedSections.contains("twStock"),
                        customExpandedColor: Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),  // 展開時使用綠色背景
                        onTap: {
                            toggleSection("twStock")
                        },
                        content: {
                            twStockContent
                        }
                    )
                    .opacity(isUpdatingTWStock ? 0.6 : 1.0)

                    // 結構型商品卡片
                    ExpandableCard(
                        title: "結構型商品",
                        amount: formatAmount(calculateStructuredTotal()),
                        updateDate: getLatestUpdateDate(),
                        accentColor: Color(red: 0x19/255.0, green: 0x72/255.0, blue: 0x78/255.0),  // #197278 Stormy Teal
                        isExpanded: expandedSections.contains("structured"),
                        useAccentColorWhenExpanded: true,
                        customExpandedColor: Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),  // 展開時使用綠色背景
                        onTap: {
                            toggleSection("structured")
                        },
                        content: {
                            structuredContent
                        }
                    )
                    .opacity(isUpdatingAllStocks ? 0.6 : 1.0)
                }
            }

            // 債券卡片（帶左側編輯按鈕）
            HStack(spacing: 8) {
                // 左側：編輯按鈕（⭐️ 直接打開債券小卡頁面）
                Button(action: {
                    showingBondInventory = true
                }) {
                    VStack(spacing: 6) {
                        if isUpdatingBonds {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(width: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0),
                            Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0).opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(12)
                .disabled(isUpdatingBonds)

                // 右側：債券卡片
                ExpandableCard(
                    title: "債券",
                    amount: formatAmount(calculateBondsTotal()),
                    updateDate: getLatestUpdateDate(),
                    accentColor: Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0),  // #C44536 Tomato Jam（與基金對調）
                    isExpanded: expandedSections.contains("bonds"),
                    useAccentColorWhenExpanded: true,
                    onTap: {
                        toggleSection("bonds")
                    },
                    content: {
                        bondsContent
                    }
                )
                .opacity(isUpdatingBonds ? 0.6 : 1.0)
            }

            // 定期定額卡片
            if showRegularInvestment {
                ExpandableCard(
                    title: "定期定額",
                    amount: formatAmount(calculateRegularInvestmentTotal()),
                    updateDate: getLatestUpdateDate(),
                    accentColor: Color(red: 0x77/255.0, green: 0x2E/255.0, blue: 0x25/255.0),  // #772E25 Chestnut
                    isExpanded: expandedSections.contains("regularInvestment"),
                    useAccentColorWhenExpanded: true
                ) {
                    toggleSection("regularInvestment")
                } content: {
                    regularInvestmentContent
                }
            }

            // 基金卡片（可選）
            if showFund {
                ExpandableCard(
                    title: "基金",
                    amount: formatAmount(calculateFundTotal()),
                    updateDate: getLatestUpdateDate(),
                    accentColor: Color(red: 0x28/255.0, green: 0x3D/255.0, blue: 0x3B/255.0),  // #283D3B Dark Slate Grey（與債券對調）
                    isExpanded: expandedSections.contains("fund"),
                    useAccentColorWhenExpanded: true
                ) {
                    toggleSection("fund")
                } content: {
                    fundContent
                }
            }

            // 保險卡片（可選）
            if showInsurance {
                ExpandableCard(
                    title: "保險",
                    amount: formatAmount(Double(removeCommas(tempInsurance)) ?? 0),
                    updateDate: getLatestUpdateDate(),
                    accentColor: Color(red: 0xED/255.0, green: 0xDD/255.0, blue: 0xD4/255.0),  // #EDDDD4 Powder Petal（與現金對調）
                    isExpanded: expandedSections.contains("insurance"),
                    useAccentColorWhenExpanded: true
                ) {
                    toggleSection("insurance")
                } content: {
                    insuranceContent
                }
            }

            // 底部按鈕區域
            VStack(spacing: 12) {
                // 新增項目按鈕（只有藍色+按鈕）
                Button(action: {
                    showingAddItemPicker = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

                // 保存按鈕
                Button(action: {
                    Task {
                        await saveToMonthlyAsset()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("保存至月度資產")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),
                                Color(.init(red: 0.20, green: 0.40, blue: 0.30, alpha: 1.0))
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - 卡片內容

    // 現金內容
    private var cashContent: some View {
        VStack(spacing: 12) {
            // 台幣卡片（點擊顯示詳細輸入）
            Button(action: {
                showingTWDInput.toggle()
            }) {
                HStack(alignment: .center, spacing: 12) {
                    Text("台幣 (NT)")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("NT\(formatTWDNumber(tempTWDCash))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.teal)
                    Image(systemName: showingTWDInput ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())

            // 台幣詳細輸入（展開時顯示）
            if showingTWDInput {
                VStack(spacing: 12) {
                    // 台幣金額
                    HStack {
                        Text("台幣金額")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        TextField("0", text: $tempTWDCash)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 匯率
                    HStack {
                        Text("匯率")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        TextField("32", text: $tempExchangeRate)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 折合美金（自動計算，唯讀）
                    HStack {
                        Text("折合美金")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        Text("\(calculateTWDToUSD())")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .id("\(tempTWDCash)-\(tempExchangeRate)")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4)
            }

            // 美金卡片（點擊顯示輸入）
            Button(action: {
                showingUSDInput.toggle()
            }) {
                HStack(alignment: .center, spacing: 12) {
                    Text("美金 (USD)")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(formatNumber(tempUSDCash))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.teal)
                    Image(systemName: showingUSDInput ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())

            // 美金輸入（展開時顯示）
            if showingUSDInput {
                VStack(spacing: 12) {
                    HStack {
                        Text("美金金額")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        TextField("0", text: $tempUSDCash)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4)
            }

            // 已添加的其他幣別
            ForEach(Array(addedCurrencies).sorted(), id: \.self) { currency in
                currencyCard(for: currency)
            }

            // 新增幣別按鈕
            Button(action: {
                showingCurrencyPicker = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("新增其他幣別")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.teal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.teal.opacity(0.08))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // 幣別卡片（跟台幣一樣的實現方式）
    @ViewBuilder
    private func currencyCard(for currency: String) -> some View {
        let currencyName = getCurrencyName(currency)
        let isExpanded = expandedCurrencies.contains(currency)

        VStack(spacing: 0) {
            // 卡片標題（可點擊展開/收起）
            Button(action: {
                withAnimation {
                    if expandedCurrencies.contains(currency) {
                        expandedCurrencies.remove(currency)
                    } else {
                        expandedCurrencies.insert(currency)
                    }
                }
            }) {
                HStack(alignment: .center, spacing: 12) {
                    Text(currencyName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(currency)\(formatNumber(getCurrencyValue(currency)))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.teal)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())

            // 展開的詳細輸入區域
            if isExpanded {
                VStack(spacing: 12) {
                    // 現金金額
                    HStack {
                        Text("現金")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        TextField("0", text: bindingForCurrencyValue(currency))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 匯率
                    HStack {
                        Text("匯率")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        TextField("0", text: bindingForCurrencyRate(currency))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 折合美金（自動計算，唯讀）
                    HStack {
                        Text("折合美金")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        Text("$\(calculateCurrencyToUsd(currency: currency))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .id("\(getCurrencyValue(currency))-\(getCurrencyRate(currency))")

                    // 移除按鈕
                    Button(action: {
                        addedCurrencies.remove(currency)
                        expandedCurrencies.remove(currency)
                        // 自動隱藏該幣別的欄位
                        hideCurrencyFields(for: currency)
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("移除此幣別")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4)
            }
        }
    }

    // 獲取幣別名稱
    private func getCurrencyName(_ currency: String) -> String {
        switch currency {
        case "EUR": return "歐元 (EUR)"
        case "JPY": return "日圓 (JPY)"
        case "GBP": return "英鎊 (GBP)"
        case "CNY": return "人民幣 (CNY)"
        case "AUD": return "澳幣 (AUD)"
        case "CAD": return "加幣 (CAD)"
        case "CHF": return "瑞士法郎 (CHF)"
        case "HKD": return "港幣 (HKD)"
        case "SGD": return "新加坡幣 (SGD)"
        default: return currency
        }
    }

    // 獲取幣別值
    private func getCurrencyValue(_ currency: String) -> String {
        switch currency {
        case "EUR": return tempEURCash
        case "JPY": return tempJPYCash
        case "GBP": return tempGBPCash
        case "CNY": return tempCNYCash
        case "AUD": return tempAUDCash
        case "CAD": return tempCADCash
        case "CHF": return tempCHFCash
        case "HKD": return tempHKDCash
        case "SGD": return tempSGDCash
        default: return "0"
        }
    }

    // 獲取幣別匯率
    private func getCurrencyRate(_ currency: String) -> String {
        switch currency {
        case "EUR": return tempEURRate
        case "JPY": return tempJPYRate
        case "GBP": return tempGBPRate
        case "CNY": return tempCNYRate
        case "AUD": return tempAUDRate
        case "CAD": return tempCADRate
        case "CHF": return tempCHFRate
        case "HKD": return tempHKDRate
        case "SGD": return tempSGDRate
        default: return "0"
        }
    }

    // 計算幣別折合美金
    private func calculateCurrencyToUsd(currency: String) -> String {
        let cashValue = Double(removeCommas(getCurrencyValue(currency))) ?? 0
        let rateValue = Double(removeCommas(getCurrencyRate(currency))) ?? 0
        guard rateValue != 0 else { return "0.00" }
        let result = cashValue / rateValue
        return String(format: "%.2f", result)
    }

    // 添加幣別（直接加入，不彈出輸入視窗）
    private func addCurrency(_ currency: String) {
        if !addedCurrencies.contains(currency) {
            // 直接加入幣別，初始值為 0
            setCurrencyValue(currency, value: "0")
            setCurrencyRate(currency, value: "0")

            // 自動顯示該幣別的三個欄位（現金、匯率、折合美金）
            showCurrencyFields(for: currency)
        }
    }

    // 自動顯示多幣別欄位
    private func showCurrencyFields(for currency: String) {
        let fieldIds: [String]
        switch currency {
        case "EUR": fieldIds = ["歐元", "歐元兌美金匯率", "歐元折合美金"]
        case "JPY": fieldIds = ["日圓", "日圓兌美金匯率", "日圓折合美金"]
        case "GBP": fieldIds = ["英鎊", "英鎊兌美金匯率", "英鎊折合美金"]
        case "CNY": fieldIds = ["人民幣", "人民幣兌美金匯率", "人民幣折合美金"]
        case "AUD": fieldIds = ["澳幣", "澳幣兌美金匯率", "澳幣折合美金"]
        case "CAD": fieldIds = ["加幣", "加幣兌美金匯率", "加幣折合美金"]
        case "CHF": fieldIds = ["瑞士法郎", "瑞士法郎兌美金匯率", "瑞士法郎折合美金"]
        case "HKD": fieldIds = ["港幣", "港幣兌美金匯率", "港幣折合美金"]
        case "SGD": fieldIds = ["新加坡幣", "新加坡幣兌美金匯率", "新加坡幣折合美金"]
        default: return
        }

        // 顯示這三個欄位
        for fieldId in fieldIds {
            if let index = FieldConfigurationManager.shared.fieldConfigurations.firstIndex(where: { $0.id == fieldId }) {
                if !FieldConfigurationManager.shared.fieldConfigurations[index].isVisible {
                    FieldConfigurationManager.shared.fieldConfigurations[index].isVisible = true
                }
            }
        }

        // 儲存變更
        FieldConfigurationManager.shared.saveConfigurations()
    }

    // 自動隱藏多幣別欄位
    private func hideCurrencyFields(for currency: String) {
        let fieldIds: [String]
        switch currency {
        case "EUR": fieldIds = ["歐元", "歐元兌美金匯率", "歐元折合美金"]
        case "JPY": fieldIds = ["日圓", "日圓兌美金匯率", "日圓折合美金"]
        case "GBP": fieldIds = ["英鎊", "英鎊兌美金匯率", "英鎊折合美金"]
        case "CNY": fieldIds = ["人民幣", "人民幣兌美金匯率", "人民幣折合美金"]
        case "AUD": fieldIds = ["澳幣", "澳幣兌美金匯率", "澳幣折合美金"]
        case "CAD": fieldIds = ["加幣", "加幣兌美金匯率", "加幣折合美金"]
        case "CHF": fieldIds = ["瑞士法郎", "瑞士法郎兌美金匯率", "瑞士法郎折合美金"]
        case "HKD": fieldIds = ["港幣", "港幣兌美金匯率", "港幣折合美金"]
        case "SGD": fieldIds = ["新加坡幣", "新加坡幣兌美金匯率", "新加坡幣折合美金"]
        default: return
        }

        // 隱藏這三個欄位
        for fieldId in fieldIds {
            if let index = FieldConfigurationManager.shared.fieldConfigurations.firstIndex(where: { $0.id == fieldId }) {
                if FieldConfigurationManager.shared.fieldConfigurations[index].isVisible {
                    FieldConfigurationManager.shared.fieldConfigurations[index].isVisible = false
                }
            }
        }

        // 儲存變更
        FieldConfigurationManager.shared.saveConfigurations()
    }

    // 設置幣別現金值
    private func setCurrencyValue(_ currency: String, value: String) {
        switch currency {
        case "EUR": tempEURCash = value
        case "JPY": tempJPYCash = value
        case "GBP": tempGBPCash = value
        case "CNY": tempCNYCash = value
        case "AUD": tempAUDCash = value
        case "CAD": tempCADCash = value
        case "CHF": tempCHFCash = value
        case "HKD": tempHKDCash = value
        case "SGD": tempSGDCash = value
        default: break
        }
        addedCurrencies.insert(currency)
    }

    // 設置幣別匯率值
    private func setCurrencyRate(_ currency: String, value: String) {
        switch currency {
        case "EUR": tempEURRate = value
        case "JPY": tempJPYRate = value
        case "GBP": tempGBPRate = value
        case "CNY": tempCNYRate = value
        case "AUD": tempAUDRate = value
        case "CAD": tempCADRate = value
        case "CHF": tempCHFRate = value
        case "HKD": tempHKDRate = value
        case "SGD": tempSGDRate = value
        default: break
        }
    }

    // 為幣別現金值創建 Binding（用於 TextField）
    private func bindingForCurrencyValue(_ currency: String) -> Binding<String> {
        switch currency {
        case "EUR": return $tempEURCash
        case "JPY": return $tempJPYCash
        case "GBP": return $tempGBPCash
        case "CNY": return $tempCNYCash
        case "AUD": return $tempAUDCash
        case "CAD": return $tempCADCash
        case "CHF": return $tempCHFCash
        case "HKD": return $tempHKDCash
        case "SGD": return $tempSGDCash
        default: return .constant("")
        }
    }

    // 為幣別匯率值創建 Binding（用於 TextField）
    private func bindingForCurrencyRate(_ currency: String) -> Binding<String> {
        switch currency {
        case "EUR": return $tempEURRate
        case "JPY": return $tempJPYRate
        case "GBP": return $tempGBPRate
        case "CNY": return $tempCNYRate
        case "AUD": return $tempAUDRate
        case "CAD": return $tempCADRate
        case "CHF": return $tempCHFRate
        case "HKD": return $tempHKDRate
        case "SGD": return $tempSGDRate
        default: return .constant("")
        }
    }

    // 計算台幣折合美金
    private func calculateTWDToUSD() -> String {
        let twd = Double(removeCommas(tempTWDCash)) ?? 0
        let rate = Double(removeCommas(tempExchangeRate)) ?? 32
        guard rate != 0 else { return "0.00" }
        let usd = twd / rate
        return String(format: "%.2f", usd)
    }

    // 計算債券折合美金
    private func calculateBondConvertedToUSD(bond: CorporateBond) -> String? {
        let currency = bond.currency ?? "USD"

        // USD 不需要轉換
        if currency == "USD" {
            return nil
        }

        // 取得匯率
        let rate: String
        switch currency {
        case "TWD": rate = tempExchangeRate
        case "EUR": rate = tempEURRate
        case "JPY": rate = tempJPYRate
        case "GBP": rate = tempGBPRate
        case "CNY": rate = tempCNYRate
        case "AUD": rate = tempAUDRate
        case "CAD": rate = tempCADRate
        case "CHF": rate = tempCHFRate
        case "HKD": rate = tempHKDRate
        case "SGD": rate = tempSGDRate
        default: return nil
        }

        guard !rate.isEmpty, let rateValue = Double(rate), rateValue > 0 else {
            return nil
        }

        // 取得現值
        let currentValueString = removeCommas(bond.currentValue ?? "")
        guard let currentValue = Double(currentValueString), currentValue > 0 else {
            return nil
        }

        // 計算折合美金 = 現值 ÷ 匯率
        let convertedUSD = currentValue / rateValue
        return String(format: "%.2f", convertedUSD)
    }

    // 計算結構型商品折合美金
    private func calculateStructuredProductConvertedToUSD(product: StructuredProduct) -> String? {
        let currency = product.currency ?? "USD"

        // USD 不需要轉換
        if currency == "USD" {
            return nil
        }

        // 取得匯率
        let rate: String
        switch currency {
        case "TWD": rate = tempExchangeRate
        case "EUR": rate = tempEURRate
        case "JPY": rate = tempJPYRate
        case "GBP": rate = tempGBPRate
        case "CNY": rate = tempCNYRate
        case "AUD": rate = tempAUDRate
        case "CAD": rate = tempCADRate
        case "CHF": rate = tempCHFRate
        case "HKD": rate = tempHKDRate
        case "SGD": rate = tempSGDRate
        default: return nil
        }

        guard !rate.isEmpty, let rateValue = Double(rate), rateValue > 0 else {
            return nil
        }

        // 取得交易金額
        let amountString = removeCommas(product.transactionAmount ?? "")
        guard let amount = Double(amountString), amount > 0 else {
            return nil
        }

        // 計算折合美金 = 交易金額 ÷ 匯率
        let convertedUSD = amount / rateValue
        return String(format: "%.2f", convertedUSD)
    }

    // 計算現金總額（美金計價）= 美金 + 台幣折合美金 + 所有多幣別折合美金
    private func calculateTotalCash() -> String {
        let usd = Double(removeCommas(tempUSDCash)) ?? 0
        let twd = Double(removeCommas(tempTWDCash)) ?? 0
        let rate = Double(removeCommas(tempExchangeRate)) ?? 32

        let twdToUsd = rate != 0 ? twd / rate : 0

        // 計算所有多幣別折合美金
        var foreignCurrenciesTotal = 0.0
        for currency in addedCurrencies {
            let toUsd = Double(calculateCurrencyToUsd(currency: currency)) ?? 0
            foreignCurrenciesTotal += toUsd
        }

        let total = usd + twdToUsd + foreignCurrenciesTotal

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: total)) ?? "0.00"
    }

    // 格式化數字顯示
    private func formatNumber(_ value: String) -> String {
        let number = Double(removeCommas(value)) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? "0.00"
    }

    // 格式化台幣顯示（只到個位數，不顯示小數點）
    private func formatTWDNumber(_ value: String) -> String {
        let number = Double(removeCommas(value)) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }

    // 美股內容
    private var usStockContent: some View {
        VStack(spacing: 12) {
            // 新增群組按鈕
            Button(action: {
                currentGroupType = "usStock"
                showingAddGroupDialog = true
            }) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14))
                    Text("新增群組")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.08))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            // 群組列表
            ForEach(Array(usStockGroups), id: \.objectID) { group in
                InvestmentGroupRowView(
                    group: group,
                    groupType: .usStock,
                    isParentExpanded: expandedSections.contains("usStock"),
                    onEdit: {
                        showingEditGroup = group
                    },
                    onDropItem: { item in
                        addItemToGroup(item: item, group: group)
                    },
                    onUpdate: {
                        saveContext()
                    },
                    onDeleteItem: { item in
                        if let stock = item as? USStock {
                            deleteStock(stock)
                        }
                    }
                )
            }

            // 所有未分組的個股
            let ungroupedStocks = usStocks.filter { stock in
                let groups = stock.groups as? Set<InvestmentGroup> ?? []
                return groups.isEmpty
            }

            // 未分組區域（可接收從群組拖出的項目）
            VStack(spacing: 12) {
                ForEach(Array(ungroupedStocks), id: \.objectID) { stock in
                ExpandableStockRow(
                    stock: stock,
                    color: Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),
                    currencyPrefix: "",
                    isUSStock: true,
                    titleColor: expandedSections.contains("usStock") ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .primary,
                    onUpdate: {
                        saveContext()
                    },
                    onDelete: {
                        deleteStock(stock as! USStock)
                    }
                )
            }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground).opacity(0.01))
            .onDrop(of: [.text], isTargeted: nil) { providers in
                handleDropToRemoveFromGroup(providers: providers)
            }

            if usStocks.isEmpty {
                Text("尚無美股持倉")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding()
            }

            // 新增按鈕
            Button(action: {
                addNewUSStock()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("新增持倉")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.08))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // 台股內容
    private var twStockContent: some View {
        VStack(spacing: 12) {
            // 新增群組按鈕
            Button(action: {
                currentGroupType = "twStock"
                showingAddGroupDialog = true
            }) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14))
                    Text("新增群組")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.08))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            // 顯示所有群組
            ForEach(Array(twStockGroups), id: \.objectID) { group in
                InvestmentGroupRowView(
                    group: group,
                    groupType: .twStock,
                    isParentExpanded: expandedSections.contains("twStock"),
                    onEdit: {
                        showingEditGroup = group
                    },
                    onDropItem: { item in
                        addItemToGroup(item: item, group: group)
                    },
                    onUpdate: {
                        saveContext()
                    },
                    onDeleteItem: { item in
                        if let stock = item as? TWStock {
                            deleteStock(stock)
                        }
                    }
                )
            }

            // 所有未分組的個股
            let ungroupedStocks = taiwanStocks.filter { stock in
                let groups = stock.groups as? Set<InvestmentGroup> ?? []
                return groups.isEmpty
            }

            // 未分組的個股列表（含 drop zone）
            VStack(spacing: 12) {
                ForEach(Array(ungroupedStocks), id: \.objectID) { stock in
                    ExpandableStockRow(
                        stock: stock,
                        color: Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),
                        currencyPrefix: "NT ",
                        isUSStock: false,
                        titleColor: expandedSections.contains("twStock") ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .primary,
                        onUpdate: {
                            saveContext()
                        },
                        onDelete: {
                            deleteStock(stock)
                        }
                    )
                    .onDrag {
                        // 震動回饋
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        return NSItemProvider(object: stock.objectID.uriRepresentation().absoluteString as NSString)
                    }
                }

                // 如果沒有台股，顯示提示
                if taiwanStocks.isEmpty {
                    Text("尚無台股持倉")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .onDrop(of: [.text], isTargeted: nil) { providers in
                handleDropToRemoveFromGroup(providers: providers)
            }

            // 新增按鈕
            Button(action: {
                addNewTWStock()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("新增持倉")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.08))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // 債券內容
    private var bondsContent: some View {
        VStack(spacing: 12) {
            // ⭐️ 根據債券編輯模式顯示不同內容
            if bondEditMode == .batchUpdate {
                // 批次更新模式：顯示總現值和總已領利息輸入欄位
                bondsBatchUpdateContent
            } else {
                // 逐一更新模式：顯示債券列表
                bondsIndividualUpdateContent
            }
        }
    }

    // 批次更新模式內容
    private var bondsBatchUpdateContent: some View {
        VStack(spacing: 12) {
            // ⭐️ 模式切換器
            Picker("債券編輯模式", selection: bondEditModeBinding) {
                ForEach(BondEditMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            // 提示訊息
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                Text("直接輸入總額和總利息")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)

            // 總現值輸入
            HStack(alignment: .center, spacing: 12) {
                Text("總現值 (USD)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                TextField("0", text: $tempBondsTotalValue)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .padding(10)
                    .background(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0).opacity(0.08))
                    .cornerRadius(8)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4)

            // 總已領利息輸入
            HStack(alignment: .center, spacing: 12) {
                Text("總已領利息 (USD)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                TextField("0", text: $tempBondsTotalInterest)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .padding(10)
                    .background(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0).opacity(0.08))
                    .cornerRadius(8)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4)

            // ⭐️ 儲存紀錄按鈕
            Button(action: {
                saveBatchData()
                // 震動回饋
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 16))
                    Text("儲存紀錄")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0),
                            Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0).opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // 逐一更新模式內容
    private var bondsIndividualUpdateContent: some View {
        VStack(spacing: 12) {
            // ⭐️ 模式切換器
            Picker("債券編輯模式", selection: bondEditModeBinding) {
                ForEach(BondEditMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            // 提示訊息
            HStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                Text("點選債券可更新現值和已領利息")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)

            // 已領利息卡片
            HStack {
                Text("已領利息加總")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Text(formatAmount(calculateBondsReceivedInterest()))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0))
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4)

            // 群組列表
            ForEach(Array(bondGroups), id: \.objectID) { group in
                InvestmentGroupRowView(
                    group: group,
                    groupType: .bond,
                    onEdit: {
                        showingEditGroup = group
                    },
                    onDropItem: { item in
                        addItemToGroup(item: item, group: group)
                    },
                    onUpdate: {
                        saveContext()
                    },
                    onDeleteItem: { item in
                        if let bond = item as? CorporateBond {
                            deleteBond(bond)
                        }
                    }
                )
            }

            // 未分組區域
            VStack(spacing: 8) {
                ForEach(corporateBonds.filter { bond in
                    let groups = bond.groups as? Set<InvestmentGroup> ?? []
                    return groups.isEmpty
                }, id: \.objectID) { bond in
                    let currentValue = Double(removeCommas(bond.currentValue ?? "0")) ?? 0
                    let couponRate = Double(removeCommas(bond.couponRate ?? "0")) ?? 0
                    let maturityDate = bond.maturityDate ?? ""
                    let currency = bond.currency ?? "USD"

                    // 計算顯示金額：非美金債券顯示折合美金，美金債券顯示原值
                    let displayAmount: Double = {
                        if currency == "USD" {
                            return currentValue
                        } else {
                            if let convertedUSD = calculateBondConvertedToUSD(bond: bond) {
                                return Double(convertedUSD) ?? 0
                            }
                            return 0
                        }
                    }()

                    // 建立 subtitle：非美金債券顯示幣別和原值，美金債券只顯示基本資訊
                    let subtitleText: String = {
                        var text = "\(String(format: "%.2f", couponRate))% | \(maturityDate)"
                        if currency != "USD" {
                            text += " | \(currency) \(formatAmount(currentValue))"
                        }
                        return text
                    }()

                    SmallCard(
                        title: bond.bondName ?? "",
                        subtitle: subtitleText,
                        amount: formatAmount(displayAmount),
                        color: Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0)
                    )
                    .onTapGesture {
                        // ⭐️ 點擊債券，打開批次輸入畫面
                        showingBondBatchInput = true
                    }
                    .onDrag {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        return NSItemProvider(object: bond.objectID.uriRepresentation().absoluteString as NSString)
                    }
                }

                if corporateBonds.isEmpty {
                    Text("尚無債券持倉")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground).opacity(0.01))
            .onDrop(of: [.text], isTargeted: nil) { providers in
                handleDropToRemoveFromGroup(providers: providers)
            }

            // 新增按鈕
            Button(action: {
                showingAddBond = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("新增持倉")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0).opacity(0.08))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // 結構型商品內容
    private var structuredContent: some View {
        VStack(spacing: 12) {
            // 新增群組按鈕
            Button(action: {
                currentGroupType = "structured"
                showingAddGroupDialog = true
            }) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14))
                    Text("新增群組")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.08))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            // 群組列表
            ForEach(Array(structuredGroups), id: \.objectID) { group in
                InvestmentGroupRowView(
                    group: group,
                    groupType: .structured,
                    onEdit: {
                        showingEditGroup = group
                    },
                    onDropItem: { item in
                        addItemToGroup(item: item, group: group)
                    },
                    onUpdate: {
                        saveContext()
                    },
                    onDeleteItem: { item in
                        if let product = item as? StructuredProduct {
                            deleteStructuredProduct(product)
                        }
                    }
                )
            }

            // 所有未分組的結構型商品
            let activeProducts = Array(structuredProducts).filter { !$0.isExited }
            let ungroupedProducts = activeProducts.filter { product in
                let groups = product.groups as? Set<InvestmentGroup> ?? []
                return groups.isEmpty
            }

            // 未分組區域
            VStack(spacing: 8) {
                ForEach(ungroupedProducts, id: \.self) { product in
                    let transactionAmount = Double(removeCommas(product.transactionAmount ?? "0")) ?? 0
                    let interestRate = Double(removeCommas(product.interestRate ?? "0")) ?? 0
                    let currency = product.currency ?? "USD"

                    // 計算顯示金額：所有商品都顯示折合美金（USD 商品直接顯示原值）
                    let displayAmount: Double = {
                        if currency == "USD" {
                            return transactionAmount
                        } else {
                            if let convertedUSD = calculateStructuredProductConvertedToUSD(product: product) {
                                return Double(convertedUSD) ?? 0
                            }
                            return 0
                        }
                    }()

                    // subtitle 只顯示利率信息
                    let subtitleText = "\(String(format: "%.2f", interestRate))%"

                    SmallCard(
                        title: product.productCode ?? "",
                        subtitle: subtitleText,
                        amount: formatAmount(displayAmount),
                        color: Color(red: 0x19/255.0, green: 0x72/255.0, blue: 0x78/255.0)
                    )
                    .onTapGesture {
                        // ⭐️ 點擊結構型商品，打開按客戶分類的詳細頁面
                        showingStructuredDetail = true
                    }
                    .onDrag {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        return NSItemProvider(object: product.objectID.uriRepresentation().absoluteString as NSString)
                    }
                }

                if activeProducts.isEmpty {
                    Text("尚無結構型商品")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground).opacity(0.01))
            .onDrop(of: [.text], isTargeted: nil) { providers in
                handleDropToRemoveFromGroup(providers: providers)
            }

            // 新增按鈕
            Button(action: {
                showingAddStructured = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("新增持倉")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.08))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // 定期定額內容
    private var regularInvestmentContent: some View {
        VStack(spacing: 12) {
            HStack {
                Text("定期定額金額")
                    .frame(width: 100, alignment: .leading)
                    .foregroundColor(.secondary)
                TextField("0", text: $tempRegularInvestment)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // 移除按鈕
            Button(action: {
                withAnimation {
                    showRegularInvestment = false
                    tempRegularInvestment = "0"
                }
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("移除此項目")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.08))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }

    // 基金內容
    private var fundContent: some View {
        VStack(spacing: 12) {
            HStack {
                Text("幣別")
                    .frame(width: 100, alignment: .leading)
                    .foregroundColor(.secondary)
                Picker("幣別", selection: $tempFundCurrency) {
                    Text("TWD").tag("TWD")
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                    Text("JPY").tag("JPY")
                    Text("GBP").tag("GBP")
                    Text("CNY").tag("CNY")
                    Text("AUD").tag("AUD")
                    Text("CAD").tag("CAD")
                    Text("CHF").tag("CHF")
                    Text("HKD").tag("HKD")
                    Text("SGD").tag("SGD")
                }
                .pickerStyle(MenuPickerStyle())
            }

            HStack {
                Text("基金金額")
                    .frame(width: 100, alignment: .leading)
                    .foregroundColor(.secondary)
                TextField("0", text: $tempFund)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // 移除按鈕
            Button(action: {
                withAnimation {
                    showFund = false
                    tempFund = "0"
                    tempFundCurrency = "USD"
                }
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("移除此項目")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.08))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }

    // 保險內容
    private var insuranceContent: some View {
        VStack(spacing: 12) {
            HStack {
                Text("保險金額")
                    .frame(width: 100, alignment: .leading)
                    .foregroundColor(.secondary)
                TextField("0", text: $tempInsurance)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // 移除按鈕
            Button(action: {
                withAnimation {
                    showInsurance = false
                    tempInsurance = "0"
                }
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("移除此項目")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.08))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }

    // MARK: - 債券編輯頁面
    private var bondEditSheetView: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 頂部分段選擇器
                Picker("編輯模式", selection: bondEditModeBinding) {
                    ForEach(BondEditMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color(.systemGray6))

                // 根據選擇的模式顯示對應的視圖
                if bondEditMode == .batchUpdate {
                    batchUpdateBondsContentView
                } else {
                    individualUpdateBondsContentView
                }
            }
            .navigationBarTitle("債券編輯", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    showingBondEditSheet = false
                },
                trailing: Button("完成") {
                    saveContext()
                    showingBondEditSheet = false
                }
            )
        }
    }

    // MARK: - 債券批次更新內容視圖
    private var batchUpdateBondsContentView: some View {
        let totalCost = calculateBondsTotalCost()
        let totalValue = Double(removeCommas(tempBondsTotalValue)) ?? 0
        let totalInterest = Double(removeCommas(tempBondsTotalInterest)) ?? 0
        let totalValueWithInterest = totalValue + totalInterest
        let profitLoss = totalValueWithInterest - totalCost
        let returnRate = totalCost > 0 ? (profitLoss / totalCost * 100) : 0

        return ScrollView {
            VStack(spacing: 16) {
                // 警語
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                    Text("不會更新所有庫存現值，僅更新債券總額")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 8)

                // 債券總成本（自動帶入）
                VStack(alignment: .leading, spacing: 8) {
                    Text("債券總成本 (USD)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatAmount(totalCost))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                // 債券總現值輸入
                VStack(alignment: .leading, spacing: 8) {
                    Text("債券總現值 (USD)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("請輸入總現值", text: $tempBondsTotalValue)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 18))
                }
                .padding(.horizontal)

                // 總已領利息輸入
                VStack(alignment: .leading, spacing: 8) {
                    Text("總已領利息 (USD)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("請輸入總已領利息", text: $tempBondsTotalInterest)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 18))
                }
                .padding(.horizontal)

                // 現值總額（總現值 + 總已領利息）
                VStack(alignment: .leading, spacing: 8) {
                    Text("現值總額 (USD)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatAmount(totalValueWithInterest))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                // 損益
                VStack(alignment: .leading, spacing: 8) {
                    Text("損益 (USD)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatAmount(profitLoss))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(profitLoss >= 0 ? .green : .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                // 總報酬率
                VStack(alignment: .leading, spacing: 8) {
                    Text("總報酬率")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f%%", returnRate))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(returnRate >= 0 ? .green : .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .padding(.bottom, 20)
        }
    }

    // MARK: - 債券逐一更新內容視圖
    private var individualUpdateBondsContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 警語
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                    Text("總額會是用每個標的現值去加總")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 8)

                if corporateBonds.isEmpty {
                    Text("尚無債券")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(Array(corporateBonds), id: \.objectID) { bond in
                        BondUpdateRow(bond: bond)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - 債券批次輸入視圖
    private var bondBatchInputView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 提示訊息
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        Text("一次更新所有債券的現值和已領利息")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if corporateBonds.isEmpty {
                        Text("尚無債券")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(Array(corporateBonds), id: \.objectID) { bond in
                            BondBatchInputRow(bond: bond)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitle("更新債券現值", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    showingBondBatchInput = false
                },
                trailing: Button("完成") {
                    saveContext()
                    showingBondBatchInput = false
                }
            )
        }
    }

    // MARK: - Helper Functions
    // 已移除即時快照功能

    // 計算定期定額折合美金總額
    private func calculateRegularInvestmentTotal() -> Double {
        return regularInvestments.reduce(0.0) { total, investment in
            let marketValue = Double(investment.marketValue ?? "0") ?? 0
            let currency = investment.currency ?? "TWD"

            // USD 不需要轉換
            if currency == "USD" {
                return total + marketValue
            }

            // 取得匯率
            let rate: String
            switch currency {
            case "TWD": rate = tempExchangeRate
            case "EUR": rate = tempEURRate
            case "JPY": rate = tempJPYRate
            case "GBP": rate = tempGBPRate
            case "CNY": rate = tempCNYRate
            case "AUD": rate = tempAUDRate
            case "CAD": rate = tempCADRate
            case "CHF": rate = tempCHFRate
            case "HKD": rate = tempHKDRate
            case "SGD": rate = tempSGDRate
            default: return total
            }

            guard !rate.isEmpty, let rateValue = Double(rate), rateValue > 0 else {
                return total
            }

            // 計算折合美金 = 市值 ÷ 匯率
            let convertedUSD = marketValue / rateValue
            return total + convertedUSD
        }
    }

    // 計算基金折合美金總額
    private func calculateFundTotal() -> Double {
        let fundAmount = Double(removeCommas(tempFund)) ?? 0
        let currency = tempFundCurrency

        // USD 不需要轉換
        if currency == "USD" {
            return fundAmount
        }

        // 取得匯率
        let rate: String
        switch currency {
        case "TWD": rate = tempExchangeRate
        case "EUR": rate = tempEURRate
        case "JPY": rate = tempJPYRate
        case "GBP": rate = tempGBPRate
        case "CNY": rate = tempCNYRate
        case "AUD": rate = tempAUDRate
        case "CAD": rate = tempCADRate
        case "CHF": rate = tempCHFRate
        case "HKD": rate = tempHKDRate
        case "SGD": rate = tempSGDRate
        default: return 0
        }

        guard !rate.isEmpty, let rateValue = Double(rate), rateValue > 0 else {
            return 0
        }

        // 計算折合美金 = 金額 ÷ 匯率
        return fundAmount / rateValue
    }

    // MARK: - 群組管理函數

    // 將項目添加到群組
    private func addItemToGroup(item: NSManagedObject, group: InvestmentGroup) {
        if let stock = item as? USStock {
            var groups = stock.groups as? Set<InvestmentGroup> ?? Set()
            groups.insert(group)
            stock.groups = groups as NSSet
        } else if let stock = item as? TWStock {
            var groups = stock.groups as? Set<InvestmentGroup> ?? Set()
            groups.insert(group)
            stock.groups = groups as NSSet
        } else if let bond = item as? CorporateBond {
            var groups = bond.groups as? Set<InvestmentGroup> ?? Set()
            groups.insert(group)
            bond.groups = groups as NSSet
        } else if let product = item as? StructuredProduct {
            var groups = product.groups as? Set<InvestmentGroup> ?? Set()
            groups.insert(group)
            product.groups = groups as NSSet
        }

        saveContext()
    }

    // 處理拖放到新建群組區域
    private func handleDropToCreateGroup(providers: [NSItemProvider], groupType: String) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            guard let data = data as? Data,
                  let objectIDString = String(data: data, encoding: .utf8),
                  let url = URL(string: objectIDString),
                  let coordinator = self.viewContext.persistentStoreCoordinator else {
                return
            }

            if let objectID = coordinator.managedObjectID(forURIRepresentation: url),
               let object = try? self.viewContext.existingObject(with: objectID) as? NSManagedObject {
                DispatchQueue.main.async {
                    // 彈出輸入群組名稱的對話框
                    self.currentGroupType = groupType
                    self.showingAddGroupDialog = true

                    // 暫存拖曳的項目，稍後創建群組時加入
                    // 這裡簡化處理：直接創建一個默認名稱的群組
                    self.createGroupAndAddItem(item: object, groupType: groupType, name: "新群組")
                }
            }
        }

        return true
    }

    // 創建群組並添加項目
    private func createGroupAndAddItem(item: NSManagedObject, groupType: String, name: String) {
        let newGroup = InvestmentGroup(context: viewContext)
        newGroup.id = UUID()
        newGroup.name = name
        newGroup.groupType = groupType
        newGroup.createdDate = Date()
        newGroup.orderIndex = Int16((usStockGroups.count + twStockGroups.count + bondGroups.count + structuredGroups.count))
        newGroup.client = client

        // 添加項目到群組
        addItemToGroup(item: item, group: newGroup)
    }

    // 創建新群組
    private func createNewGroup(name: String, groupType: String) {
        let newGroup = InvestmentGroup(context: viewContext)
        newGroup.id = UUID()
        newGroup.name = name
        newGroup.groupType = groupType
        newGroup.createdDate = Date()
        newGroup.orderIndex = Int16((usStockGroups.count + twStockGroups.count + bondGroups.count + structuredGroups.count))
        newGroup.client = client

        saveContext()
    }

    // 處理拖放到未分組區域（移除所有群組關聯）
    private func handleDropToRemoveFromGroup(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            guard let data = data as? Data,
                  let objectIDString = String(data: data, encoding: .utf8),
                  let url = URL(string: objectIDString),
                  let coordinator = self.viewContext.persistentStoreCoordinator else {
                return
            }

            if let objectID = coordinator.managedObjectID(forURIRepresentation: url),
               let object = try? self.viewContext.existingObject(with: objectID) as? NSManagedObject {
                DispatchQueue.main.async {
                    // 從所有群組中移除該項目
                    self.removeItemFromAllGroups(item: object)
                }
            }
        }

        return true
    }

    // 從所有群組中移除項目
    private func removeItemFromAllGroups(item: NSManagedObject) {
        if let stock = item as? USStock {
            stock.groups = NSSet()
        } else if let stock = item as? TWStock {
            stock.groups = NSSet()
        } else if let bond = item as? CorporateBond {
            bond.groups = NSSet()
        } else if let product = item as? StructuredProduct {
            product.groups = NSSet()
        }

        saveContext()
    }

    // 獲取群組類型
    private func groupTypeForGroup(_ group: InvestmentGroup) -> InvestmentGroupRowView.GroupType {
        switch group.groupType {
        case "usStock": return .usStock
        case "twStock": return .twStock
        case "bond": return .bond
        case "structured": return .structured
        default: return .usStock
        }
    }

    // 更新現金數值
    private func updateCashValue(asset: MonthlyAsset, field: String, value: String) {
        guard let newValue = Double(value) else { return }

        switch field {
        case "twdCash":
            asset.twdCash = String(format: "%.2f", newValue)
        case "cash":
            asset.cash = String(format: "%.2f", newValue)
        case "eurCash":
            asset.eurCash = String(format: "%.2f", newValue)
        case "jpyCash":
            asset.jpyCash = String(format: "%.2f", newValue)
        case "gbpCash":
            asset.gbpCash = String(format: "%.2f", newValue)
        case "cnyCash":
            asset.cnyCash = String(format: "%.2f", newValue)
        case "audCash":
            asset.audCash = String(format: "%.2f", newValue)
        case "cadCash":
            asset.cadCash = String(format: "%.2f", newValue)
        default:
            break
        }

        // 重新計算總資產
        recalculateTotalAssets(for: asset)

        // 保存變更
        do {
            try viewContext.save()
            print("✅ 已更新現金數值")
        } catch {
            print("❌ 更新現金數值失敗：\(error)")
        }
    }

    // 更新股票數值（持股數量和價格）
    private func updateStockValues(stock: NSManagedObject, shares: String, price: String) {
        if let sharesValue = Double(shares) {
            stock.setValue(String(format: "%.2f", sharesValue), forKey: "shares")
        }

        if let priceValue = Double(price) {
            stock.setValue(String(format: "%.2f", priceValue), forKey: "currentPrice")
        }

        // 保存變更
        do {
            try viewContext.save()
            print("✅ 已更新股票數值")
        } catch {
            print("❌ 更新股票數值失敗：\(error)")
        }
    }

    // 保存上下文
    private func saveContext() {
        do {
            try viewContext.save()
            print("✅ 已保存變更")
        } catch {
            print("❌ 保存失敗：\(error)")
        }
    }

    // 刪除股票
    private func deleteStock(_ stock: NSManagedObject) {
        withAnimation {
            viewContext.delete(stock)
            do {
                try viewContext.save()
                print("✅ 已刪除股票")
            } catch {
                print("❌ 刪除股票失敗：\(error)")
            }
        }
    }

    private func deleteBond(_ bond: CorporateBond) {
        withAnimation {
            viewContext.delete(bond)
            do {
                try viewContext.save()
                print("✅ 已刪除債券")
            } catch {
                print("❌ 刪除債券失敗：\(error)")
            }
        }
    }

    private func deleteStructuredProduct(_ product: StructuredProduct) {
        withAnimation {
            viewContext.delete(product)
            do {
                try viewContext.save()
                print("✅ 已刪除結構型商品")
            } catch {
                print("❌ 刪除結構型商品失敗：\(error)")
            }
        }
    }

    // 重新計算總資產
    private func recalculateTotalAssets(for asset: MonthlyAsset) {
        let twd = Double(removeCommas(asset.twdCash ?? "0")) ?? 0
        let usd = Double(removeCommas(asset.cash ?? "0")) ?? 0
        let usStock = Double(removeCommas(asset.usStock ?? "0")) ?? 0
        let regularInvestment = Double(removeCommas(asset.regularInvestment ?? "0")) ?? 0
        let bonds = Double(removeCommas(asset.bonds ?? "0")) ?? 0
        let taiwanStock = Double(removeCommas(asset.taiwanStock ?? "0")) ?? 0
        let structured = Double(removeCommas(asset.structured ?? "0")) ?? 0
        let fund = Double(removeCommas(asset.fund ?? "0")) ?? 0
        let insurance = Double(removeCommas(asset.insurance ?? "0")) ?? 0

        let total = twd + usd + usStock + regularInvestment + bonds + taiwanStock + structured + fund + insurance
        asset.totalAssets = String(format: "%.2f", total)
    }

    // 新增幣別金額
    private func addNewCurrency(_ currency: String, amount: String) {
        guard let amountValue = Double(amount) else { return }

        // 獲取或創建最新的 MonthlyAsset
        let asset: MonthlyAsset
        if let latestAsset = monthlyAssets.first {
            asset = latestAsset
        } else {
            // 如果沒有資產記錄，創建新的
            asset = MonthlyAsset(context: viewContext)
            asset.client = client
            asset.createdDate = Date()
        }

        // 根據幣別更新對應的現金欄位
        let formattedAmount = String(format: "%.2f", amountValue)
        switch currency {
        case "EUR":
            asset.eurCash = formattedAmount
        case "JPY":
            asset.jpyCash = formattedAmount
        case "GBP":
            asset.gbpCash = formattedAmount
        case "CNY":
            asset.cnyCash = formattedAmount
        case "AUD":
            asset.audCash = formattedAmount
        case "CAD":
            asset.cadCash = formattedAmount
        default:
            break
        }

        // 重新計算總資產
        recalculateTotalAssets(for: asset)

        // 保存變更
        do {
            try viewContext.save()
            print("✅ 已新增 \(currency) 金額：\(formattedAmount)")
            // 自動展開現金卡片以顯示更新
            expandedSections.insert("cash")
        } catch {
            print("❌ 新增幣別失敗：\(error)")
        }
    }

    // 新增美股
    private func addNewUSStock() {
        withAnimation {
            let newStock = USStock(context: viewContext)
            newStock.client = client
            newStock.market = ""
            newStock.name = ""
            newStock.shares = "0"
            newStock.cost = "0"
            newStock.costPerShare = "0"
            newStock.currentPrice = "0"
            newStock.marketValue = "0"
            newStock.profitLoss = "0"
            newStock.returnRate = "0.00%"
            newStock.currency = "USD"
            newStock.comment = ""
            newStock.createdDate = Date()

            do {
                try viewContext.save()
                print("✅ 已新增空白美股")
                // 自動展開美股卡片
                expandedSections.insert("usStock")
            } catch {
                print("❌ 新增美股失敗：\(error)")
            }
        }
    }

    // 新增台股
    private func addNewTWStock() {
        withAnimation {
            let newStock = TWStock(context: viewContext)
            newStock.client = client
            newStock.name = ""
            newStock.shares = "0"
            newStock.cost = "0"
            newStock.costPerShare = "0"
            newStock.currentPrice = "0"
            newStock.marketValue = "0"
            newStock.profitLoss = "0"
            newStock.returnRate = "0.00%"
            newStock.currency = "NT"
            newStock.comment = ""
            newStock.createdDate = Date()

            do {
                try viewContext.save()
                print("✅ 已新增空白台股")
                // 自動展開台股卡片
                expandedSections.insert("twStock")
            } catch {
                print("❌ 新增台股失敗：\(error)")
            }
        }
    }

    private func toggleSection(_ section: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if expandedSections.contains(section) {
                // ⭐️ 債券卡片縮回時，如果是批次更新模式，自動儲存數據
                if section == "bonds" && bondEditMode == .batchUpdate {
                    saveBatchData()
                    print("✅ 債券卡片縮回，已自動儲存批次更新數據")
                }
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }

    // 計算現金總額（用於卡片標題）- 使用臨時變數
    private func calculateCashTotal() -> String {
        // 使用臨時變數計算現金總額
        let usd = Double(removeCommas(tempUSDCash)) ?? 0
        let twd = Double(removeCommas(tempTWDCash)) ?? 0
        let rate = Double(removeCommas(tempExchangeRate)) ?? 32

        let twdToUsd = rate != 0 ? twd / rate : 0

        // 計算所有多幣別折合美金
        var foreignCurrenciesTotal = 0.0
        for currency in addedCurrencies {
            let toUsd = Double(calculateCurrencyToUsd(currency: currency)) ?? 0
            foreignCurrenciesTotal += toUsd
        }

        let total = usd + twdToUsd + foreignCurrenciesTotal

        return formatCurrency(total)
    }

    // 獲取最後更新日期
    private func getLatestUpdateDate() -> String {
        guard let latestAsset = monthlyAssets.first,
              let date = latestAsset.createdDate else {
            return "未更新"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: date) + " 更新"
    }

    // 計算美股總市值
    private func calculateUSStockTotal() -> Double {
        return usStocks.reduce(0.0) { total, stock in
            let priceString = removeCommas(stock.currentPrice ?? "0")
            let sharesString = removeCommas(stock.shares ?? "0")
            let currentPrice: Double = Double(priceString) ?? 0.0
            let shares: Double = Double(sharesString) ?? 0.0
            return total + (currentPrice * shares)
        }
    }

    // 計算台股總市值
    private func calculateTWStockTotal() -> Double {
        return taiwanStocks.reduce(0.0) { total, stock in
            let priceString = removeCommas(stock.currentPrice ?? "0")
            let sharesString = removeCommas(stock.shares ?? "0")
            let currentPrice: Double = Double(priceString) ?? 0.0
            let shares: Double = Double(sharesString) ?? 0.0
            return total + (currentPrice * shares)
        }
    }

    // 計算債券總市值（使用折合美金）
    private func calculateBondsTotal() -> Double {
        // 如果選擇批次更新模式且有手動輸入,使用手動輸入的總額
        if bondEditMode == .batchUpdate && !tempBondsTotalValue.isEmpty, let manualTotal = Double(removeCommas(tempBondsTotalValue)) {
            return manualTotal
        }

        // 否則計算債券庫存的加總
        return calculateBondsTableTotal()
    }

    // 計算債券總成本（使用折合美金）
    private func calculateBondsTotalCost() -> Double {
        return corporateBonds.reduce(0.0) { total, bond in
            let currency = bond.currency ?? "USD"
            let cost = Double(removeCommas(bond.subscriptionAmount ?? "0")) ?? 0

            // USD 債券直接使用成本
            if currency == "USD" {
                return total + cost
            }

            // 非 USD 債券需要轉換
            let rate: String
            switch currency {
            case "TWD": rate = tempExchangeRate
            case "EUR": rate = tempEURRate
            case "JPY": rate = tempJPYRate
            case "GBP": rate = tempGBPRate
            case "CNY": rate = tempCNYRate
            case "AUD": rate = tempAUDRate
            case "CAD": rate = tempCADRate
            case "CHF": rate = tempCHFRate
            case "HKD": rate = tempHKDRate
            case "SGD": rate = tempSGDRate
            default: return total
            }

            guard !rate.isEmpty, let rateValue = Double(rate), rateValue > 0 else {
                return total
            }

            // 計算折合美金 = 成本 ÷ 匯率
            let convertedUSD = cost / rateValue
            return total + convertedUSD
        }
    }

    // 計算債券已領利息總和（使用折合美金）
    private func calculateBondsReceivedInterest() -> Double {
        // 如果選擇批次更新模式且有手動輸入,使用手動輸入的總已領利息
        if bondEditMode == .batchUpdate && !tempBondsTotalInterest.isEmpty, let manualInterest = Double(removeCommas(tempBondsTotalInterest)) {
            return manualInterest
        }

        // 否則計算債券庫存的加總
        return calculateBondsTableInterest()
    }

    // 計算債券表格的總現值（純粹從表格計算，不考慮手動輸入）
    private func calculateBondsTableTotal() -> Double {
        return corporateBonds.reduce(0.0) { total, bond in
            let currency = bond.currency ?? "USD"

            // USD 債券直接使用現值
            if currency == "USD" {
                let currentValue = Double(removeCommas(bond.currentValue ?? "0")) ?? 0
                return total + currentValue
            }

            // 非 USD 債券使用折合美金
            if let convertedUSD = calculateBondConvertedToUSD(bond: bond) {
                return total + (Double(convertedUSD) ?? 0)
            }

            return total
        }
    }

    // 計算債券表格的總已領利息（純粹從表格計算，不考慮手動輸入）
    private func calculateBondsTableInterest() -> Double {
        return corporateBonds.reduce(0.0) { total, bond in
            let currency = bond.currency ?? "USD"
            let receivedInterest = Double(removeCommas(bond.receivedInterest ?? "0")) ?? 0

            // USD 債券直接使用已領利息
            if currency == "USD" {
                return total + receivedInterest
            }

            // 非 USD 債券需要轉換
            let rate: String
            switch currency {
            case "TWD": rate = tempExchangeRate
            case "EUR": rate = tempEURRate
            case "JPY": rate = tempJPYRate
            case "GBP": rate = tempGBPRate
            case "CNY": rate = tempCNYRate
            case "AUD": rate = tempAUDRate
            case "CAD": rate = tempCADRate
            case "CHF": rate = tempCHFRate
            case "HKD": rate = tempHKDRate
            case "SGD": rate = tempSGDRate
            default: return total
            }

            guard !rate.isEmpty, let rateValue = Double(rate), rateValue > 0 else {
                return total
            }

            // 計算折合美金 = 已領利息 ÷ 匯率
            let convertedUSD = receivedInterest / rateValue
            return total + convertedUSD
        }
    }

    // 計算結構型商品總額（使用折合美金）
    private func calculateStructuredTotal() -> Double {
        return structuredProducts.filter { !$0.isExited }.reduce(0.0) { total, product in
            let currency = product.currency ?? "USD"
            let transactionAmount = Double(removeCommas(product.transactionAmount ?? "0")) ?? 0

            // USD 直接使用交易金額
            if currency == "USD" {
                return total + transactionAmount
            }

            // 非 USD 使用折合美金
            if let convertedUSD = calculateStructuredProductConvertedToUSD(product: product) {
                return total + (Double(convertedUSD) ?? 0)
            }

            return total
        }
    }


    // MARK: - 保存至月度資產
    private func saveToMonthlyAsset() async {
        print("📊 準備保存快速更新資料至月度資產")

        // 計算各項數值
        let twd = Double(removeCommas(tempTWDCash)) ?? 0
        let usd = Double(removeCommas(tempUSDCash)) ?? 0
        let exchangeRate = Double(removeCommas(tempExchangeRate)) ?? 32

        let usStockTotal = calculateUSStockTotal()
        let twStockTotal = calculateTWStockTotal()
        let bondsTotal = calculateBondsTotal()
        let structuredTotal = calculateStructuredTotal()

        let regularInvestment = showRegularInvestment ? (Double(removeCommas(tempRegularInvestment)) ?? 0) : 0
        let fund = showFund ? (Double(removeCommas(tempFund)) ?? 0) : 0
        let insurance = showInsurance ? (Double(removeCommas(tempInsurance)) ?? 0) : 0

        // 計算台股折合美金
        let twStockFolded = exchangeRate != 0 ? twStockTotal / exchangeRate : 0

        // 計算台幣折合美金
        let twdToUsd = exchangeRate != 0 ? twd / exchangeRate : 0

        // 計算多幣別折合美金
        let eurToUsdValue = Double(calculateCurrencyToUsd(currency: "EUR")) ?? 0
        let jpyToUsdValue = Double(calculateCurrencyToUsd(currency: "JPY")) ?? 0
        let gbpToUsdValue = Double(calculateCurrencyToUsd(currency: "GBP")) ?? 0
        let cnyToUsdValue = Double(calculateCurrencyToUsd(currency: "CNY")) ?? 0
        let audToUsdValue = Double(calculateCurrencyToUsd(currency: "AUD")) ?? 0
        let cadToUsdValue = Double(calculateCurrencyToUsd(currency: "CAD")) ?? 0
        let chfToUsdValue = Double(calculateCurrencyToUsd(currency: "CHF")) ?? 0
        let hkdToUsdValue = Double(calculateCurrencyToUsd(currency: "HKD")) ?? 0
        let sgdToUsdValue = Double(calculateCurrencyToUsd(currency: "SGD")) ?? 0

        // 計算總資產（美金）- 包含所有貨幣折合美金
        let totalAssets = usd + twdToUsd + usStockTotal + twStockFolded + bondsTotal + structuredTotal + regularInvestment + fund + insurance +
                         eurToUsdValue + jpyToUsdValue + gbpToUsdValue + cnyToUsdValue + audToUsdValue +
                         cadToUsdValue + chfToUsdValue + hkdToUsdValue + sgdToUsdValue

        print("💰 總資產計算明細：")
        print("   美金現金: \(usd)")
        print("   台幣折美金: \(twdToUsd)")
        print("   美股: \(usStockTotal)")
        print("   台股折美金: \(twStockFolded)")
        print("   債券: \(bondsTotal)")
        print("   結構型: \(structuredTotal)")
        print("   定期定額: \(regularInvestment)")
        print("   基金: \(fund)")
        print("   保險: \(insurance)")
        print("   歐元→美金: \(eurToUsdValue)")
        print("   日圓→美金: \(jpyToUsdValue)")
        print("   英鎊→美金: \(gbpToUsdValue)")
        print("   人民幣→美金: \(cnyToUsdValue)")
        print("   澳幣→美金: \(audToUsdValue)")
        print("   加幣→美金: \(cadToUsdValue)")
        print("   瑞郎→美金: \(chfToUsdValue)")
        print("   港幣→美金: \(hkdToUsdValue)")
        print("   新幣→美金: \(sgdToUsdValue)")
        print("   ===========================")
        print("   總資產合計: \(totalAssets)")

        // 計算成本（從庫存中累加）
        let usStockCost = usStocks.reduce(0.0) { sum, stock in
            let shares = Double(stock.shares ?? "0") ?? 0
            let costPerShare = Double(stock.costPerShare ?? "0") ?? 0
            return sum + (shares * costPerShare)
        }

        let twStockCost = taiwanStocks.reduce(0.0) { sum, stock in
            let shares = Double(stock.shares ?? "0") ?? 0
            let costPerShare = Double(stock.costPerShare ?? "0") ?? 0
            return sum + (shares * costPerShare)
        }

        var bondsCost = 0.0
        for bond in corporateBonds {
            let transactionAmount = Double(removeCommas(bond.transactionAmount ?? "0")) ?? 0
            bondsCost += transactionAmount
        }

        // 創建新的月度資產記錄
        await MainActor.run {
            let newAsset = MonthlyAsset(context: viewContext)
            newAsset.client = client

            // 日期格式化
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            newAsset.date = dateFormatter.string(from: Date())

            // 現金
            newAsset.twdCash = formatNumberWithoutDollarSign(twd)
            newAsset.cash = formatNumberWithoutDollarSign(usd)

            // 多幣別現金
            newAsset.eurCash = formatNumberWithoutDollarSign(Double(removeCommas(tempEURCash)) ?? 0)
            newAsset.jpyCash = formatNumberWithoutDollarSign(Double(removeCommas(tempJPYCash)) ?? 0)
            newAsset.gbpCash = formatNumberWithoutDollarSign(Double(removeCommas(tempGBPCash)) ?? 0)
            newAsset.cnyCash = formatNumberWithoutDollarSign(Double(removeCommas(tempCNYCash)) ?? 0)
            newAsset.audCash = formatNumberWithoutDollarSign(Double(removeCommas(tempAUDCash)) ?? 0)
            newAsset.cadCash = formatNumberWithoutDollarSign(Double(removeCommas(tempCADCash)) ?? 0)
            newAsset.chfCash = formatNumberWithoutDollarSign(Double(removeCommas(tempCHFCash)) ?? 0)
            newAsset.hkdCash = formatNumberWithoutDollarSign(Double(removeCommas(tempHKDCash)) ?? 0)
            newAsset.sgdCash = formatNumberWithoutDollarSign(Double(removeCommas(tempSGDCash)) ?? 0)

            // 多幣別匯率
            newAsset.eurRate = formatNumberWithoutDollarSign(Double(removeCommas(tempEURRate)) ?? 0)
            newAsset.jpyRate = formatNumberWithoutDollarSign(Double(removeCommas(tempJPYRate)) ?? 0)
            newAsset.gbpRate = formatNumberWithoutDollarSign(Double(removeCommas(tempGBPRate)) ?? 0)
            newAsset.cnyRate = formatNumberWithoutDollarSign(Double(removeCommas(tempCNYRate)) ?? 0)
            newAsset.audRate = formatNumberWithoutDollarSign(Double(removeCommas(tempAUDRate)) ?? 0)
            newAsset.cadRate = formatNumberWithoutDollarSign(Double(removeCommas(tempCADRate)) ?? 0)
            newAsset.chfRate = formatNumberWithoutDollarSign(Double(removeCommas(tempCHFRate)) ?? 0)
            newAsset.hkdRate = formatNumberWithoutDollarSign(Double(removeCommas(tempHKDRate)) ?? 0)
            newAsset.sgdRate = formatNumberWithoutDollarSign(Double(removeCommas(tempSGDRate)) ?? 0)

            // 多幣別折合美金（自動計算）
            newAsset.eurToUsd = formatNumberWithoutDollarSign(Double(calculateCurrencyToUsd(currency: "EUR")) ?? 0)
            newAsset.jpyToUsd = formatNumberWithoutDollarSign(Double(calculateCurrencyToUsd(currency: "JPY")) ?? 0)
            newAsset.gbpToUsd = formatNumberWithoutDollarSign(Double(calculateCurrencyToUsd(currency: "GBP")) ?? 0)
            newAsset.cnyToUsd = formatNumberWithoutDollarSign(Double(calculateCurrencyToUsd(currency: "CNY")) ?? 0)
            newAsset.audToUsd = formatNumberWithoutDollarSign(Double(calculateCurrencyToUsd(currency: "AUD")) ?? 0)
            newAsset.cadToUsd = formatNumberWithoutDollarSign(Double(calculateCurrencyToUsd(currency: "CAD")) ?? 0)
            newAsset.chfToUsd = formatNumberWithoutDollarSign(Double(calculateCurrencyToUsd(currency: "CHF")) ?? 0)
            newAsset.hkdToUsd = formatNumberWithoutDollarSign(Double(calculateCurrencyToUsd(currency: "HKD")) ?? 0)
            newAsset.sgdToUsd = formatNumberWithoutDollarSign(Double(calculateCurrencyToUsd(currency: "SGD")) ?? 0)

            // 投資項目
            newAsset.usStock = formatNumberWithoutDollarSign(usStockTotal)
            newAsset.taiwanStock = formatNumberWithoutDollarSign(twStockTotal)
            newAsset.bonds = formatNumberWithoutDollarSign(bondsTotal)
            newAsset.structured = formatNumberWithoutDollarSign(structuredTotal)
            newAsset.regularInvestment = formatNumberWithoutDollarSign(regularInvestment)
            newAsset.fund = formatNumberWithoutDollarSign(fund)
            newAsset.insurance = formatNumberWithoutDollarSign(insurance)

            // 成本
            newAsset.usStockCost = formatNumberWithoutDollarSign(usStockCost)
            newAsset.taiwanStockCost = formatNumberWithoutDollarSign(twStockCost)
            newAsset.bondsCost = formatNumberWithoutDollarSign(bondsCost)
            newAsset.regularInvestmentCost = "0"
            newAsset.fundCost = "0"

            // 匯率和換算
            newAsset.exchangeRate = tempExchangeRate
            newAsset.taiwanStockFolded = formatNumberWithoutDollarSign(twStockFolded)
            newAsset.twdToUsd = formatNumberWithoutDollarSign(twdToUsd)

            // 總資產
            newAsset.totalAssets = formatNumberWithoutDollarSign(totalAssets)

            // 匯入相關（從前一筆繼承）
            if let previousAsset = monthlyAssets.first {
                newAsset.depositAccumulated = previousAsset.depositAccumulated ?? "0"
            } else {
                newAsset.depositAccumulated = "0"
            }
            newAsset.deposit = "0"

            // 其他
            newAsset.confirmedInterest = "0"
            newAsset.notes = ""
            newAsset.createdDate = Date()

            do {
                // 先確保所有待處理的變更都被處理
                viewContext.processPendingChanges()

                try viewContext.save()
                print("✅ 成功保存至月度資產到 viewContext")

                // ⭐️ 關鍵修復：強制刷新所有物件
                viewContext.refreshAllObjects()
                print("✅ 已刷新所有 Core Data 物件")

                PersistenceController.shared.save()
                print("✅ 月度資產已同步到 iCloud")
                print("   總資產: $\(formatNumberWithoutDollarSign(totalAssets))")
            } catch {
                print("❌ 保存失敗：\(error)")
                updateAlertTitle = "保存失敗"
                updateAlertMessage = "❌ 無法保存：\(error.localizedDescription)"
                showUpdateAlert = true
                return
            }
        }

        // 給 Core Data 一點時間完成保存和刷新
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒

        await MainActor.run {
            // 發送通知讓儀表板刷新
            let clientKey = client.objectID.uriRepresentation().absoluteString
            NotificationCenter.default.post(
                name: NSNotification.Name("MonthlyAssetUpdated"),
                object: nil,
                userInfo: ["clientID": clientKey]
            )
            print("✅ 已發送月度資產更新通知")

            // 顯示成功提示
            updateAlertTitle = "保存成功"
            updateAlertMessage = "✅ 已成功保存至月度資產明細\n總資產: $\(formatCurrency(totalAssets))"
            showUpdateAlert = true
        }
    }

    // MARK: - 美股股價更新
    func updateUSStockPrices() async {
        await MainActor.run {
            isUpdatingUSStock = true
        }

        var successCount = 0
        var failCount = 0

        for stock in usStocks {
            guard let stockName = stock.name?.trimmingCharacters(in: .whitespaces), !stockName.isEmpty else {
                continue
            }

            do {
                let price = try await StockPriceService.shared.fetchStockPrice(symbol: stockName)
                await MainActor.run {
                    stock.currentPrice = String(format: "%.2f", price)
                    successCount += 1
                    print("✅ 成功更新 \(stockName) 股價: $\(price)")
                }
            } catch {
                failCount += 1
                print("❌ 更新 \(stockName) 股價失敗: \(error.localizedDescription)")
            }
        }

        // 儲存更新
        await MainActor.run {
            do {
                try viewContext.save()

                // 顯示結果
                updateAlertTitle = "美股價格更新完成"
                if failCount == 0 {
                    updateAlertMessage = "✅ 成功更新 \(successCount) 個美股的價格"
                } else {
                    updateAlertMessage = "✅ 成功: \(successCount) 個\n❌ 失敗: \(failCount) 個"
                }
                showUpdateAlert = true
            } catch {
                updateAlertTitle = "儲存失敗"
                updateAlertMessage = "❌ 無法儲存更新：\(error.localizedDescription)"
                showUpdateAlert = true
            }
            isUpdatingUSStock = false
        }
    }

    // MARK: - 台股股價更新
    func updateTWStockPrices() async {
        await MainActor.run {
            isUpdatingTWStock = true
        }

        var successCount = 0
        var failCount = 0

        for stock in taiwanStocks {
            guard let stockName = stock.name?.trimmingCharacters(in: .whitespaces), !stockName.isEmpty else {
                continue
            }

            // 加上 .TW 後綴
            let symbol = stockName.hasSuffix(".TW") ? stockName : "\(stockName).TW"

            do {
                let price = try await StockPriceService.shared.fetchStockPrice(symbol: symbol)
                await MainActor.run {
                    stock.currentPrice = String(format: "%.2f", price)
                    successCount += 1
                    print("✅ 成功更新 \(stockName) 股價: $\(price)")
                }
            } catch {
                failCount += 1
                print("❌ 更新 \(stockName) 股價失敗: \(error.localizedDescription)")
            }
        }

        // 儲存更新
        await MainActor.run {
            do {
                try viewContext.save()

                // 顯示結果
                updateAlertTitle = "台股價格更新完成"
                if failCount == 0 {
                    updateAlertMessage = "✅ 成功更新 \(successCount) 個台股的價格"
                } else {
                    updateAlertMessage = "✅ 成功: \(successCount) 個\n❌ 失敗: \(failCount) 個"
                }
                showUpdateAlert = true
            } catch {
                updateAlertTitle = "儲存失敗"
                updateAlertMessage = "❌ 無法儲存更新：\(error.localizedDescription)"
                showUpdateAlert = true
            }
            isUpdatingTWStock = false
        }
    }

    // MARK: - 更新全部股票（美股 + 台股）
    func updateAllStockPrices() async {
        await MainActor.run {
            isUpdatingAllStocks = true
        }

        var totalSuccess = 0
        var totalFail = 0

        // 1. 先更新美股
        await MainActor.run {
            isUpdatingUSStock = true
        }

        for stock in usStocks {
            guard let stockName = stock.name?.trimmingCharacters(in: .whitespaces), !stockName.isEmpty else {
                continue
            }

            do {
                let fetchedPrice = try await StockPriceService.shared.fetchStockPrice(symbol: stockName)
                await MainActor.run {
                    // ⭐️ 更新股價
                    stock.currentPrice = fetchedPrice

                    // ⭐️ 重新計算市值、損益、報酬率
                    let sharesString = stock.shares ?? "0"
                    let costPerShareString = stock.costPerShare ?? "0"
                    let shares: Double = Double(sharesString) ?? 0.0
                    let costPerShare: Double = Double(costPerShareString) ?? 0.0
                    let priceDouble: Double = Double(fetchedPrice) ?? 0.0
                    let marketValue = shares * priceDouble
                    let cost = shares * costPerShare
                    let profitLoss = marketValue - cost
                    let returnRate = cost > 0 ? (profitLoss / cost) * 100.0 : 0.0

                    stock.marketValue = String(format: "%.2f", marketValue)
                    stock.cost = String(format: "%.2f", cost)
                    stock.profitLoss = String(format: "%.2f", profitLoss)
                    stock.returnRate = String(format: "%.2f", returnRate)

                    totalSuccess += 1
                    print("✅ 成功更新美股 \(stockName): $\(fetchedPrice)")
                }
            } catch {
                totalFail += 1
                print("❌ 更新美股 \(stockName) 失敗: \(error.localizedDescription)")
            }
        }

        await MainActor.run {
            isUpdatingUSStock = false
        }

        // 2. 再更新台股
        await MainActor.run {
            isUpdatingTWStock = true
        }

        for stock in taiwanStocks {
            guard let stockName = stock.name?.trimmingCharacters(in: .whitespaces), !stockName.isEmpty else {
                continue
            }

            let symbol = stockName.hasSuffix(".TW") ? stockName : "\(stockName).TW"

            do {
                let fetchedPrice = try await StockPriceService.shared.fetchStockPrice(symbol: symbol)
                await MainActor.run {
                    // ⭐️ 更新股價
                    stock.currentPrice = fetchedPrice

                    // ⭐️ 重新計算市值、損益、報酬率
                    let sharesString = stock.shares ?? "0"
                    let costPerShareString = stock.costPerShare ?? "0"
                    let shares: Double = Double(sharesString) ?? 0.0
                    let costPerShare: Double = Double(costPerShareString) ?? 0.0
                    let priceDouble: Double = Double(fetchedPrice) ?? 0.0
                    let marketValue = shares * priceDouble
                    let cost = shares * costPerShare
                    let profitLoss = marketValue - cost
                    let returnRate = cost > 0 ? (profitLoss / cost) * 100.0 : 0.0

                    stock.marketValue = String(format: "%.2f", marketValue)
                    stock.cost = String(format: "%.2f", cost)
                    stock.profitLoss = String(format: "%.2f", profitLoss)
                    stock.returnRate = String(format: "%.2f", returnRate)

                    totalSuccess += 1
                    print("✅ 成功更新台股 \(stockName): $\(fetchedPrice)")
                }
            } catch {
                totalFail += 1
                print("❌ 更新台股 \(stockName) 失敗: \(error.localizedDescription)")
            }
        }

        await MainActor.run {
            isUpdatingTWStock = false
        }

        // 3. 儲存並顯示結果
        await MainActor.run {
            do {
                // 先確保所有待處理的變更都被處理
                viewContext.processPendingChanges()

                try viewContext.save()
                print("✅ 股價已儲存到 viewContext")

                // ⭐️ 關鍵修復：強制刷新所有物件
                viewContext.refreshAllObjects()
                print("✅ 已刷新所有 Core Data 物件")

                PersistenceController.shared.save()
                print("✅ 股價已同步到 iCloud")

                // 更新股價更新時間戳（美股和台股）
                let now = Date()
                let clientKey = client.objectID.uriRepresentation().absoluteString
                UserDefaults.standard.set(now, forKey: "usStockPriceUpdateTime_\(clientKey)")
                UserDefaults.standard.set(now, forKey: "twStockPriceUpdateTime_\(clientKey)")
                print("✅ 已更新股價時間戳：\(now)")
            } catch {
                updateAlertTitle = "儲存失敗"
                updateAlertMessage = "❌ 無法儲存更新：\(error.localizedDescription)"
                showUpdateAlert = true
                isUpdatingAllStocks = false
                return
            }
        }

        // 給 Core Data 一點時間完成保存和刷新
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒

        await MainActor.run {
            // 發送通知讓儀表板刷新
            let clientKey = client.objectID.uriRepresentation().absoluteString
            NotificationCenter.default.post(
                name: NSNotification.Name("USStockPriceUpdated"),
                object: nil,
                userInfo: ["clientID": clientKey]
            )
            NotificationCenter.default.post(
                name: NSNotification.Name("TWStockPriceUpdated"),
                object: nil,
                userInfo: ["clientID": clientKey]
            )
            print("✅ 已發送股價更新通知")

            updateAlertTitle = "全部股價更新完成"
            if totalFail == 0 {
                updateAlertMessage = "✅ 成功更新 \(totalSuccess) 個股票的價格"
            } else {
                updateAlertMessage = "✅ 成功: \(totalSuccess) 個\n❌ 失敗: \(totalFail) 個"
            }
            showUpdateAlert = true
            isUpdatingAllStocks = false
        }
    }

    // MARK: - 匯率更新功能

    /// 收集當前客戶實際使用的幣別
    private func collectUsedCurrencies() -> Set<String> {
        var usedCurrencies: Set<String> = ["TWD"] // 台幣一定要更新

        // 1. 檢查現金多幣別
        for currency in addedCurrencies {
            usedCurrencies.insert(currency)
        }

        // 2. 檢查公司債
        for bond in corporateBonds {
            if let currency = bond.currency, !currency.isEmpty, currency != "USD" {
                usedCurrencies.insert(currency)
            }
        }

        // 3. 檢查結構型商品
        for product in structuredProducts {
            if let currency = product.currency, !currency.isEmpty, currency != "USD" {
                usedCurrencies.insert(currency)
            }
        }

        // 4. 檢查定期定額（如果有幣別欄位）
        // 注意：需要確認 RegularInvestment 是否有 currency 欄位
        // for investment in regularInvestments {
        //     if let currency = investment.currency, !currency.isEmpty, currency != "USD" {
        //         usedCurrencies.insert(currency)
        //     }
        // }

        print("📊 當前客戶使用的幣別: \(usedCurrencies)")
        return usedCurrencies
    }

    func updateExchangeRates() async {
        // 🔍 先收集當前客戶實際使用的幣別
        let usedCurrencies = await MainActor.run {
            collectUsedCurrencies()
        }

        await MainActor.run {
            isUpdatingExchangeRate = true
        }

        // 調用匯率服務
        guard let result = await ExchangeRateService.shared.fetchExchangeRates() else {
            await MainActor.run {
                updateAlertTitle = "匯率更新失敗"
                updateAlertMessage = "❌ 無法取得匯率資料\n請檢查網路連線後再試"
                showUpdateAlert = true
                isUpdatingExchangeRate = false
            }
            return
        }

        let (rates, source, date) = result

        // 更新各個幣別的匯率（只更新使用到的幣別）
        await MainActor.run {
            var updatedCount = 0

            // 更新台幣對美金匯率（一定更新）
            if let twdUsdRate = rates["TWD/USD"] {
                tempExchangeRate = String(format: "%.4f", twdUsdRate)
                print("✅ 更新台幣匯率: \(tempExchangeRate)")
                updatedCount += 1
            }

            // ⚡️ 只更新當前客戶實際使用的幣別（智能化更新）
            if usedCurrencies.contains("EUR"), let eurRate = rates["EUR/USD"] {
                tempEURRate = String(format: "%.4f", eurRate)
                print("✅ 更新歐元匯率: \(tempEURRate)")
                updatedCount += 1
            }
            if usedCurrencies.contains("JPY"), let jpyRate = rates["JPY/USD"] {
                tempJPYRate = String(format: "%.4f", jpyRate)
                print("✅ 更新日圓匯率: \(tempJPYRate)")
                updatedCount += 1
            }
            if usedCurrencies.contains("GBP"), let gbpRate = rates["GBP/USD"] {
                tempGBPRate = String(format: "%.4f", gbpRate)
                print("✅ 更新英鎊匯率: \(tempGBPRate)")
                updatedCount += 1
            }
            if usedCurrencies.contains("CNY"), let cnyRate = rates["CNY/USD"] {
                tempCNYRate = String(format: "%.4f", cnyRate)
                print("✅ 更新人民幣匯率: \(tempCNYRate)")
                updatedCount += 1
            }
            if usedCurrencies.contains("AUD"), let audRate = rates["AUD/USD"] {
                tempAUDRate = String(format: "%.4f", audRate)
                print("✅ 更新澳幣匯率: \(tempAUDRate)")
                updatedCount += 1
            }
            if usedCurrencies.contains("CAD"), let cadRate = rates["CAD/USD"] {
                tempCADRate = String(format: "%.4f", cadRate)
                print("✅ 更新加幣匯率: \(tempCADRate)")
                updatedCount += 1
            }
            if usedCurrencies.contains("CHF"), let chfRate = rates["CHF/USD"] {
                tempCHFRate = String(format: "%.4f", chfRate)
                print("✅ 更新瑞士法郎匯率: \(tempCHFRate)")
                updatedCount += 1
            }
            if usedCurrencies.contains("HKD"), let hkdRate = rates["HKD/USD"] {
                tempHKDRate = String(format: "%.4f", hkdRate)
                print("✅ 更新港幣匯率: \(tempHKDRate)")
                updatedCount += 1
            }
            if usedCurrencies.contains("SGD"), let sgdRate = rates["SGD/USD"] {
                tempSGDRate = String(format: "%.4f", sgdRate)
                print("✅ 更新新加坡幣匯率: \(tempSGDRate)")
                updatedCount += 1
            }

            print("⚡️ 智能更新：只更新 \(updatedCount) 個使用中的幣別")

            // 顯示更新結果
            let message = ExchangeRateService.shared.formatUpdateMessage(rates: rates, source: source, date: date)
            updateAlertTitle = "匯率更新成功"
            updateAlertMessage = message
            showUpdateAlert = true
            isUpdatingExchangeRate = false

            print("✅ 匯率更新完成")
        }
    }

    // 清除所有資料（切換客戶時使用）
    private func clearAllData() {
        // 清除現金資料
        tempTWDCash = "0"
        tempUSDCash = "0"
        tempExchangeRate = "32"

        // 清除可選項目
        tempRegularInvestment = "0"
        tempFund = "0"
        tempInsurance = "0"
        showRegularInvestment = false
        showFund = false
        showInsurance = false

        // 清除所有多幣別現金
        tempEURCash = "0"
        tempJPYCash = "0"
        tempGBPCash = "0"
        tempCNYCash = "0"
        tempAUDCash = "0"
        tempCADCash = "0"
        tempCHFCash = "0"
        tempHKDCash = "0"
        tempSGDCash = "0"

        // 清除所有多幣別匯率
        tempEURRate = "0"
        tempJPYRate = "0"
        tempGBPRate = "0"
        tempCNYRate = "0"
        tempAUDRate = "0"
        tempCADRate = "0"
        tempCHFRate = "0"
        tempHKDRate = "0"
        tempSGDRate = "0"

        // 清除幣別集合
        addedCurrencies.removeAll()
        expandedCurrencies.removeAll()

        print("🧹 已清除所有快速更新資料")
    }

    // 從前一筆月度資產明細載入初始現金數據
    private func loadInitialCashValues() {
        // 查找前一筆歷史記錄（非即時快照）
        let historicalAssets = monthlyAssets.filter { !$0.isLiveSnapshot }

        if let previousAsset = historicalAssets.first {
            // 載入台幣和美金現金
            tempTWDCash = previousAsset.twdCash ?? "0"
            tempUSDCash = previousAsset.cash ?? "0"
            tempExchangeRate = previousAsset.exchangeRate ?? "32"

            // 載入可選項目（如果有值就顯示）
            let regularInvestment = previousAsset.regularInvestment ?? "0"
            let fund = previousAsset.fund ?? "0"
            let insurance = previousAsset.insurance ?? "0"

            if Double(regularInvestment) ?? 0 > 0 {
                tempRegularInvestment = regularInvestment
                showRegularInvestment = true
            }
            if Double(fund) ?? 0 > 0 {
                tempFund = fund
                showFund = true
            }
            if Double(insurance) ?? 0 > 0 {
                tempInsurance = insurance
                showInsurance = true
            }

            // 載入多幣別現金
            loadCurrencyIfExists("EUR", value: previousAsset.eurCash ?? "0")
            loadCurrencyIfExists("JPY", value: previousAsset.jpyCash ?? "0")
            loadCurrencyIfExists("GBP", value: previousAsset.gbpCash ?? "0")
            loadCurrencyIfExists("CNY", value: previousAsset.cnyCash ?? "0")
            loadCurrencyIfExists("AUD", value: previousAsset.audCash ?? "0")
            loadCurrencyIfExists("CAD", value: previousAsset.cadCash ?? "0")
            loadCurrencyIfExists("CHF", value: previousAsset.chfCash ?? "0")
            loadCurrencyIfExists("HKD", value: previousAsset.hkdCash ?? "0")
            loadCurrencyIfExists("SGD", value: previousAsset.sgdCash ?? "0")

            // 載入多幣別匯率
            loadCurrencyRate("EUR", rate: previousAsset.eurRate ?? "0")
            loadCurrencyRate("JPY", rate: previousAsset.jpyRate ?? "0")
            loadCurrencyRate("GBP", rate: previousAsset.gbpRate ?? "0")
            loadCurrencyRate("CNY", rate: previousAsset.cnyRate ?? "0")
            loadCurrencyRate("AUD", rate: previousAsset.audRate ?? "0")
            loadCurrencyRate("CAD", rate: previousAsset.cadRate ?? "0")
            loadCurrencyRate("CHF", rate: previousAsset.chfRate ?? "0")
            loadCurrencyRate("HKD", rate: previousAsset.hkdRate ?? "0")
            loadCurrencyRate("SGD", rate: previousAsset.sgdRate ?? "0")

            print("✅ 已從前一筆記錄載入數據")
            print("   台幣: \(tempTWDCash)")
            print("   美金: \(tempUSDCash)")
            print("   匯率: \(tempExchangeRate)")
            print("   定期定額: \(tempRegularInvestment)")
            print("   基金: \(tempFund)")
            print("   保險: \(tempInsurance)")
            print("   已載入幣別: \(addedCurrencies)")
        } else {
            // 如果沒有歷史記錄，使用預設值
            tempTWDCash = "0"
            tempUSDCash = "0"
            tempExchangeRate = "32"
            tempRegularInvestment = "0"
            tempFund = "0"
            tempInsurance = "0"
        }
    }

    // 載入幣別（如果有值）
    private func loadCurrencyIfExists(_ currency: String, value: String) {
        if Double(value) ?? 0 > 0 {
            setCurrencyValue(currency, value: value)
        }
    }

    // 載入幣別匯率（不檢查是否大於0，因為匯率需要保留）
    private func loadCurrencyRate(_ currency: String, rate: String) {
        if Double(rate) ?? 0 > 0 {
            setCurrencyRate(currency, value: rate)
        }
    }

    // 格式化數字（不含 $ 符號，用於儲存）
    private func formatNumberWithoutDollarSign(_ value: Double) -> String {
        // ⭐️ 修復：不添加千分位逗號,因為 Core Data 讀取時使用 Double(string) 無法解析包含逗號的字串
        return String(format: "%.2f", value)
    }

    // 格式化數字
    private func removeCommas(_ string: String) -> String {
        return string.replacingOccurrences(of: ",", with: "")
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? "0.00")
    }

    // 格式化金額（不含 $ 符號）
    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0.00"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - 可展開卡片組件
struct ExpandableCard<Content: View>: View {
    let title: String
    let amount: String
    let updateDate: String
    let accentColor: Color
    let isExpanded: Bool
    var useAccentColorWhenExpanded: Bool = false  // 展開時使用強調色作為背景色
    var customExpandedColor: Color? = nil  // 自訂展開時的顏色（優先於 accentColor）
    let onTap: () -> Void
    @ViewBuilder let content: Content

    // 計算展開時的背景色
    private var expandedBackgroundColor: Color {
        if let customColor = customExpandedColor {
            return customColor  // 不透明
        } else if useAccentColorWhenExpanded {
            return accentColor  // 不透明
        } else {
            return Color(.systemGray6)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 卡片標題 - 整個區域可點擊
            HStack(spacing: 12) {
                // 左側：標題
                Text(title)
                    .font(.system(size: 21, weight: .semibold))  // 放大30%
                    .foregroundColor(.primary)

                Spacer()

                // 右側：金額和日期
                VStack(alignment: .trailing, spacing: 4) {
                    Text(amount)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Text(updateDate)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(isExpanded ? expandedBackgroundColor : Color(.systemBackground))  // 只有標題行有顏色背景
            .cornerRadius(12)  // 表頭保持四角圓潤
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }

            // 展開內容
            if isExpanded {
                content
                    .padding(12)
                    .background(Color(.systemGroupedBackground))  // 內容區域使用灰色背景
                    .cornerRadius(12)  // 內容區域也保持圓潤
                    .padding(.top, 8)  // 表頭和內容區域之間的間距
                    .environment(\.cardAccentColor, currentAccentColor)  // 傳遞強調色給內容
            }
        }
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // 計算當前使用的強調色
    private var currentAccentColor: Color {
        if let customColor = customExpandedColor, isExpanded {
            return customColor
        } else if useAccentColorWhenExpanded, isExpanded {
            return accentColor
        } else {
            return accentColor
        }
    }
}

// MARK: - 帶有更新按鈕的卡片包裝
struct CardWithUpdateButton<Content: View>: View {
    let title: String
    let amount: String
    let updateDate: String
    let accentColor: Color
    let isExpanded: Bool
    let isUpdating: Bool
    let onTap: () -> Void
    let onUpdate: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 8) {
            // 左側：更新按鈕
            Button(action: onUpdate) {
                if isUpdating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.9)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 24, height: 24)
                }
            }
            .foregroundColor(accentColor)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .buttonStyle(PlainButtonStyle())
            .disabled(isUpdating)

            // 右側：卡片本身
            ExpandableCard(
                title: title,
                amount: amount,
                updateDate: updateDate,
                accentColor: accentColor,
                isExpanded: isExpanded,
                onTap: onTap,
                content: {
                    content
                }
            )
        }
    }
}

// MARK: - 小卡片組件
struct SmallCard: View {
    let title: String
    var subtitle: String? = nil
    let amount: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(amount)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
}

// MARK: - 可編輯小卡片組件
struct EditableSmallCard: View {
    let title: String
    var subtitle: String? = nil
    let amount: String
    let color: Color
    let onEdit: (String) -> Void

    @State private var showingEditAlert = false
    @State private var editingValue = ""

    var body: some View {
        Button(action: {
            // 移除貨幣符號和逗號，只保留數字
            editingValue = amount.replacingOccurrences(of: "$", with: "")
                                .replacingOccurrences(of: ",", with: "")
                                .replacingOccurrences(of: "NT ", with: "")
                                .trimmingCharacters(in: .whitespaces)
            showingEditAlert = true
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(amount)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("編輯 \(title)", isPresented: $showingEditAlert) {
            TextField("輸入數值", text: $editingValue)
                .keyboardType(.decimalPad)
            Button("取消", role: .cancel) {}
            Button("確定") {
                if !editingValue.isEmpty {
                    onEdit(editingValue)
                }
            }
        } message: {
            Text("請輸入新的數值")
        }
    }
}

// MARK: - 可編輯股票卡片組件
struct EditableStockCard: View {
    let title: String
    let shares: Double
    let price: Double
    let color: Color
    var currencyPrefix: String = ""
    var titleColor: Color = .primary  // 新增：標題顏色，預設為主要顏色
    let onEdit: (String, String) -> Void

    @State private var showingEditAlert = false
    @State private var editingShares = ""
    @State private var editingPrice = ""

    private var marketValue: Double {
        let result: Double = shares * price
        return result
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let valueString = formatter.string(from: NSNumber(value: marketValue)) ?? "0.00"
        return currencyPrefix + "$" + valueString
    }

    var body: some View {
        Button(action: {
            editingShares = String(format: "%.2f", shares)
            editingPrice = String(format: "%.2f", price)
            showingEditAlert = true
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(titleColor)

                    Text("\(String(format: "%.0f", shares)) 股 @ $\(String(format: "%.2f", price))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(formattedAmount)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("編輯 \(title)", isPresented: $showingEditAlert) {
            TextField("持股數量", text: $editingShares)
                .keyboardType(.decimalPad)
            TextField("當前價格", text: $editingPrice)
                .keyboardType(.decimalPad)
            Button("取消", role: .cancel) {}
            Button("確定") {
                if !editingShares.isEmpty && !editingPrice.isEmpty {
                    onEdit(editingShares, editingPrice)
                }
            }
        } message: {
            Text("請輸入持股數量和當前價格")
        }
    }
}

// MARK: - 新增按鈕組件
struct AddButton: View {
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 可展開股票編輯組件
struct ExpandableStockRow: View {
    @ObservedObject var stock: NSManagedObject
    let color: Color
    let currencyPrefix: String
    let isUSStock: Bool
    var titleColor: Color = .primary  // 新增：標題顏色，預設為主要顏色
    let onUpdate: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false

    private var stockName: String {
        stock.value(forKey: "name") as? String ?? ""
    }

    private var shares: String {
        stock.value(forKey: "shares") as? String ?? "0"
    }

    private var currentPrice: String {
        stock.value(forKey: "currentPrice") as? String ?? "0"
    }

    private var costPerShare: String {
        stock.value(forKey: "costPerShare") as? String ?? "0"
    }

    private var currency: String {
        stock.value(forKey: "currency") as? String ?? (isUSStock ? "USD" : "NT")
    }

    private var comment: String {
        stock.value(forKey: "comment") as? String ?? ""
    }

    private var marketValue: Double {
        let priceString = removeCommas(currentPrice)
        let qtyString = removeCommas(shares)
        let price: Double = Double(priceString) ?? 0.0
        let qty: Double = Double(qtyString) ?? 0.0
        return price * qty
    }

    private func removeCommas(_ string: String) -> String {
        return string.replacingOccurrences(of: ",", with: "")
    }

    private func formatCurrencyValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0.00"
    }

    var body: some View {
        VStack(spacing: 0) {
            // 摺疊狀態的卡片標題
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stockName.isEmpty ? "未命名股票" : stockName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(titleColor)

                        Text("\(String(format: "%.0f", Double(removeCommas(shares)) ?? 0)) 股 @ \(currencyPrefix)\(String(format: "%.2f", Double(removeCommas(currentPrice)) ?? 0))")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text(currencyPrefix + "\(formatCurrencyValue(marketValue))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(color)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            .onDrag {
                // 震動回饋
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                return NSItemProvider(object: stock.objectID.uriRepresentation().absoluteString as NSString)
            }

            // 展開的編輯區域
            if isExpanded {
                VStack(spacing: 12) {
                    // 股票代號
                    HStack(spacing: 8) {
                        Text("代號")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)

                        TextField("例如: AAPL", text: Binding(
                            get: { stockName },
                            set: { newValue in
                                stock.setValue(newValue, forKey: "name")
                                onUpdate()
                            }
                        ))
                        .font(.system(size: 14))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 持股數量
                    HStack(spacing: 8) {
                        Text("股數")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)

                        TextField("0", text: Binding(
                            get: { shares },
                            set: { newValue in
                                stock.setValue(newValue, forKey: "shares")
                                onUpdate()
                            }
                        ))
                        .font(.system(size: 14))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 成本單價
                    HStack(spacing: 8) {
                        Text("成本單價")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)

                        TextField("0", text: Binding(
                            get: { costPerShare },
                            set: { newValue in
                                stock.setValue(newValue, forKey: "costPerShare")
                                onUpdate()
                            }
                        ))
                        .font(.system(size: 14))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 現價（僅顯示）
                    HStack(spacing: 8) {
                        Text("現價")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)

                        Text("\(currencyPrefix)$\(String(format: "%.2f", Double(removeCommas(currentPrice)) ?? 0))")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(5)
                    }

                    // 幣別
                    HStack(spacing: 8) {
                        Text("幣別")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)

                        TextField("USD", text: Binding(
                            get: { currency },
                            set: { newValue in
                                stock.setValue(newValue, forKey: "currency")
                                onUpdate()
                            }
                        ))
                        .font(.system(size: 14))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 備註
                    HStack(spacing: 8) {
                        Text("備註")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)

                        TextField("備註", text: Binding(
                            get: { comment },
                            set: { newValue in
                                stock.setValue(newValue, forKey: "comment")
                                onUpdate()
                            }
                        ))
                        .font(.system(size: 14))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 刪除按鈕
                    Button(action: onDelete) {
                        HStack {
                            Image(systemName: "trash")
                            Text("刪除")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
                .padding(12)
                .background(Color.white)
            }
        }
    }
}

// MARK: - 債券更新列組件
struct BondUpdateRow: View {
    @ObservedObject var bond: CorporateBond
    @State private var currentValueText: String = ""
    @State private var receivedInterestText: String = ""

    init(bond: CorporateBond) {
        self.bond = bond
        _currentValueText = State(initialValue: bond.currentValue ?? "0")
        _receivedInterestText = State(initialValue: bond.receivedInterest ?? "0")
    }

    private func removeCommas(_ string: String) -> String {
        return string.replacingOccurrences(of: ",", with: "")
    }

    var body: some View {
        let cost = Double(removeCommas(bond.subscriptionAmount ?? "0")) ?? 0
        let currentValue = Double(removeCommas(currentValueText)) ?? 0
        let receivedInterest = Double(removeCommas(receivedInterestText)) ?? 0
        let valueWithInterest = currentValue + receivedInterest
        let profitLoss = valueWithInterest - cost
        let returnRate = cost > 0 ? (profitLoss / cost * 100) : 0

        return VStack(alignment: .leading, spacing: 12) {
            // 債券名稱
            Text(bond.bondName ?? "未命名債券")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            // 幣別和成本
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("幣別")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(bond.currency ?? "USD")
                        .font(.system(size: 14, weight: .medium))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("成本")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", cost))
                        .font(.system(size: 14, weight: .medium))
                }
            }

            Divider()

            // 現值輸入
            VStack(alignment: .leading, spacing: 4) {
                Text("現值")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                TextField("請輸入現值", text: $currentValueText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: currentValueText) { newValue in
                        bond.currentValue = newValue
                    }
            }

            // 已領利息輸入
            VStack(alignment: .leading, spacing: 4) {
                Text("已領利息")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                TextField("請輸入已領利息", text: $receivedInterestText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: receivedInterestText) { newValue in
                        bond.receivedInterest = newValue
                    }
            }

            Divider()

            // 計算結果
            VStack(spacing: 8) {
                // 現值+已領息
                HStack {
                    Text("現值+已領息")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", valueWithInterest))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }

                // 損益
                HStack {
                    Text("損益")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", profitLoss))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(profitLoss >= 0 ? .green : .red)
                }

                // 報酬率
                HStack {
                    Text("報酬率")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f%%", returnRate))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(returnRate >= 0 ? .green : .red)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
        .padding(.horizontal)
    }
}

// MARK: - 債券批次輸入列組件
struct BondBatchInputRow: View {
    @ObservedObject var bond: CorporateBond
    @State private var currentValueText: String = ""
    @State private var receivedInterestText: String = ""
    @State private var isEditingCurrentValue = false // ⭐️ 追蹤是否正在編輯
    @State private var isEditingReceivedInterest = false // ⭐️ 追蹤是否正在編輯

    init(bond: CorporateBond) {
        self.bond = bond

        // ⭐️ 如果現值為空或為 0，自動使用申購金額（transactionAmount）
        var currentValue = bond.currentValue ?? "0"
        let currentValueNum = Double(currentValue.replacingOccurrences(of: ",", with: "")) ?? 0
        if currentValueNum == 0 {
            // 使用申購金額作為初始現值
            let transactionAmount = bond.transactionAmount ?? "0"
            let transactionAmountNum = Double(transactionAmount.replacingOccurrences(of: ",", with: "")) ?? 0
            if transactionAmountNum > 0 {
                currentValue = transactionAmount
                print("✅ 批次輸入：現值為空，使用申購金額 \(transactionAmount) 作為初始現值")
            }
        }

        let receivedInterest = bond.receivedInterest ?? "0"
        _currentValueText = State(initialValue: Self.formatNumberWithCommas(currentValue))
        _receivedInterestText = State(initialValue: Self.formatNumberWithCommas(receivedInterest))
    }

    // 格式化數字加千分位
    private static func formatNumberWithCommas(_ value: String) -> String {
        let cleanValue = value.replacingOccurrences(of: ",", with: "")
        guard let number = Double(cleanValue) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    // 移除千分位
    private func removeCommas(_ value: String) -> String {
        return value.replacingOccurrences(of: ",", with: "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 債券名稱和幣別
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bond.bondName ?? "未命名債券")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    // ⭐️ 只有非美金才顯示幣別
                    if let currency = bond.currency, currency != "USD" {
                        Text(currency)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }

            // 現值輸入（橫向排列）
            HStack(alignment: .center, spacing: 12) {
                Text("現值")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 70, alignment: .leading)

                TextField("0", text: $currentValueText, onEditingChanged: { editing in
                    isEditingCurrentValue = editing
                    if !editing {
                        // ⭐️ 編輯結束時，儲存並格式化
                        let cleanValue = removeCommas(currentValueText)
                        bond.currentValue = cleanValue
                        if !cleanValue.isEmpty {
                            currentValueText = Self.formatNumberWithCommas(cleanValue)
                        }
                    }
                })
                .keyboardType(.decimalPad)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0))
                .multilineTextAlignment(.trailing)
                .padding(10)
                .background(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0).opacity(0.08))
                .cornerRadius(8)
            }

            // 已領利息輸入（橫向排列）
            HStack(alignment: .center, spacing: 12) {
                Text("已領利息")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 70, alignment: .leading)

                TextField("0", text: $receivedInterestText, onEditingChanged: { editing in
                    isEditingReceivedInterest = editing
                    if !editing {
                        // ⭐️ 編輯結束時，儲存並格式化
                        let cleanValue = removeCommas(receivedInterestText)
                        bond.receivedInterest = cleanValue
                        if !cleanValue.isEmpty {
                            receivedInterestText = Self.formatNumberWithCommas(cleanValue)
                        }
                    }
                })
                .keyboardType(.decimalPad)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0))
                .multilineTextAlignment(.trailing)
                .padding(10)
                .background(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0).opacity(0.08))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
        .padding(.horizontal)
    }
}
