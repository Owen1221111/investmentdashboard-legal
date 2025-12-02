import SwiftUI
import CoreData

struct AddMonthlyDataView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    let onSave: ([String], Date) -> Void // 修改：新增 Date 參數
    let client: Client? // 修改：直接傳入 Client 物件
    let editingBond: CorporateBond? // ⭐️ 可選：正在編輯的債券

    // 欄位配置管理器
    @ObservedObject var configManager = FieldConfigurationManager.shared

    // FetchRequest 取得前一筆月度資產資料
    @FetchRequest private var monthlyAssets: FetchedResults<MonthlyAsset>

    @State private var selectedTab = 0 // 0: 資產明細, 1: 公司債
    @State private var selectedDate = Date()
    @State private var fund = ""
    @State private var fundCost = ""
    @State private var insurance = ""
    @State private var twdCash = ""
    @State private var cash = ""
    @State private var usStock = ""
    @State private var regularInvestment = ""
    @State private var bonds = ""
    @State private var taiwanStock = ""
    @State private var taiwanStockFoldRate32 = ""
    @State private var twdToUsd = ""
    @State private var structured = ""
    @State private var confirmedInterest = ""
    // totalAssets 改為計算屬性，不再是 @State
    @State private var exchangeRate = "32"
    @State private var usStockCost = ""

    // 其他貨幣
    @State private var eurCash = ""
    @State private var jpyCash = ""
    @State private var gbpCash = ""
    @State private var cnyCash = ""
    @State private var audCash = ""
    @State private var cadCash = ""
    @State private var chfCash = ""
    @State private var hkdCash = ""
    @State private var sgdCash = ""

    // 匯率
    @State private var eurRate = ""
    @State private var jpyRate = ""
    @State private var gbpRate = ""
    @State private var cnyRate = ""
    @State private var audRate = ""
    @State private var cadRate = ""
    @State private var chfRate = ""
    @State private var hkdRate = ""
    @State private var sgdRate = ""

    // 計算屬性：自動計算台股折合和台幣折合美金
    private var calculatedTaiwanStockFolded: String {
        let taiwanStockValue = Double(removeCommas(taiwanStock)) ?? 0
        let exchangeRateValue = Double(removeCommas(exchangeRate)) ?? 32
        guard exchangeRateValue != 0 else { return "0" }
        let result = taiwanStockValue / exchangeRateValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    private var calculatedTwdToUsd: String {
        let twdCashValue = Double(removeCommas(twdCash)) ?? 0
        let exchangeRateValue = Double(removeCommas(exchangeRate)) ?? 32
        guard exchangeRateValue != 0 else { return "0" }
        let result = twdCashValue / exchangeRateValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    // 其他貨幣折合美金的計算屬性
    private var calculatedEurToUsd: String {
        let eurValue = Double(removeCommas(eurCash)) ?? 0
        let rateValue = Double(removeCommas(eurRate)) ?? 0
        guard rateValue != 0 else { return "0" }
        let result = eurValue / rateValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    private var calculatedJpyToUsd: String {
        let jpyValue = Double(removeCommas(jpyCash)) ?? 0
        let rateValue = Double(removeCommas(jpyRate)) ?? 0
        guard rateValue != 0 else { return "0" }
        let result = jpyValue / rateValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    private var calculatedGbpToUsd: String {
        let gbpValue = Double(removeCommas(gbpCash)) ?? 0
        let rateValue = Double(removeCommas(gbpRate)) ?? 0
        guard rateValue != 0 else { return "0" }
        let result = gbpValue / rateValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    private var calculatedCnyToUsd: String {
        let cnyValue = Double(removeCommas(cnyCash)) ?? 0
        let rateValue = Double(removeCommas(cnyRate)) ?? 0
        guard rateValue != 0 else { return "0" }
        let result = cnyValue / rateValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    private var calculatedAudToUsd: String {
        let audValue = Double(removeCommas(audCash)) ?? 0
        let rateValue = Double(removeCommas(audRate)) ?? 0
        guard rateValue != 0 else { return "0" }
        let result = audValue / rateValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    private var calculatedCadToUsd: String {
        let cadValue = Double(removeCommas(cadCash)) ?? 0
        let rateValue = Double(removeCommas(cadRate)) ?? 0
        guard rateValue != 0 else { return "0" }
        let result = cadValue / rateValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    private var calculatedChfToUsd: String {
        let chfValue = Double(removeCommas(chfCash)) ?? 0
        let rateValue = Double(removeCommas(chfRate)) ?? 0
        guard rateValue != 0 else { return "0" }
        let result = chfValue / rateValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    private var calculatedHkdToUsd: String {
        let hkdValue = Double(removeCommas(hkdCash)) ?? 0
        let rateValue = Double(removeCommas(hkdRate)) ?? 0
        guard rateValue != 0 else { return "0" }
        let result = hkdValue / rateValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    private var calculatedSgdToUsd: String {
        let sgdValue = Double(removeCommas(sgdCash)) ?? 0
        let rateValue = Double(removeCommas(sgdRate)) ?? 0
        guard rateValue != 0 else { return "0" }
        let result = sgdValue / rateValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    // 計算屬性：自動計算總資產
    private var calculatedTotalAssets: String {
        let cashValue = Double(removeCommas(cash)) ?? 0
        let usStockValue = Double(removeCommas(usStock)) ?? 0
        let regularInvestmentValue = Double(removeCommas(regularInvestment)) ?? 0
        let bondsValue = Double(removeCommas(bonds)) ?? 0
        let taiwanStockFoldedValue = Double(removeCommas(calculatedTaiwanStockFolded)) ?? 0
        let twdToUsdValue = Double(removeCommas(calculatedTwdToUsd)) ?? 0
        let structuredValue = Double(removeCommas(structured)) ?? 0
        let fundValue = Double(removeCommas(fund)) ?? 0
        let insuranceValue = Double(removeCommas(insurance)) ?? 0

        // 其他貨幣折合美金
        let eurToUsdValue = Double(removeCommas(calculatedEurToUsd)) ?? 0
        let jpyToUsdValue = Double(removeCommas(calculatedJpyToUsd)) ?? 0
        let gbpToUsdValue = Double(removeCommas(calculatedGbpToUsd)) ?? 0
        let cnyToUsdValue = Double(removeCommas(calculatedCnyToUsd)) ?? 0
        let audToUsdValue = Double(removeCommas(calculatedAudToUsd)) ?? 0
        let cadToUsdValue = Double(removeCommas(calculatedCadToUsd)) ?? 0
        let chfToUsdValue = Double(removeCommas(calculatedChfToUsd)) ?? 0
        let hkdToUsdValue = Double(removeCommas(calculatedHkdToUsd)) ?? 0
        let sgdToUsdValue = Double(removeCommas(calculatedSgdToUsd)) ?? 0

        let total = cashValue + usStockValue + regularInvestmentValue + bondsValue +
                    taiwanStockFoldedValue + twdToUsdValue + structuredValue + fundValue + insuranceValue +
                    eurToUsdValue + jpyToUsdValue + gbpToUsdValue + cnyToUsdValue + audToUsdValue +
                    cadToUsdValue + chfToUsdValue + hkdToUsdValue + sgdToUsdValue

        return formatWithCommas(String(format: "%.2f", total))
    }

    @State private var regularInvestmentCost = ""
    @State private var bondsCost = ""
    @State private var taiwanStockCost = ""
    @State private var deposit = ""
    @State private var notes = ""
    @State private var showingFieldConfig = false // 控制欄位配置視圖顯示

    // 公司債欄位
    @State private var subscriptionDate = Date()
    @State private var bondName = ""
    @State private var maturityDate = Date()  // 債券到期日
    @State private var bondCurrency = "USD" // 幣別，預設美金
    @State private var couponRate = ""
    @State private var yieldRate = ""
    @State private var subscriptionPrice = ""
    @State private var subscriptionAmount = ""
    @State private var holdingFaceValue = ""
    @State private var previousHandInterest = "" // 新增：前手息
    @State private var transactionAmount = ""
    @State private var currentValue = ""
    @State private var receivedInterest = ""
    @State private var profitLossWithInterest = ""
    @State private var returnRate = ""
    @State private var dividendMonths = "1月、7月" // 改為預設值
    @State private var singleDividend = ""
    @State private var annualDividend = ""

    // 庫存明細視圖控制
    @State private var showingUSStockInventory = false
    @State private var showingTWStockInventory = false
    @State private var showingRegularInvestmentInventory = false
    @State private var showingCorporateBondsInventory = false
    @State private var showingStructuredProductsInventory = false

    // 更新提示
    @State private var showingUpdateAlert = false
    @State private var updateAlertMessage = ""
    @State private var isUpdatingPrices = false // 追蹤是否正在更新股價

    // 計算屬性：申購金額 = 申購價格 × 持有面額 / 100
    private var calculatedSubscriptionAmount: String {
        let price = Double(removeCommas(subscriptionPrice)) ?? 0
        let faceValue = Double(removeCommas(holdingFaceValue)) ?? 0
        let result = price * faceValue / 100
        return formatWithCommas(String(format: "%.2f", result))
    }

    // 計算屬性：交易金額 = 申購金額 + 前手息
    private var calculatedTransactionAmount: String {
        let subscriptionAmt = Double(removeCommas(calculatedSubscriptionAmount)) ?? 0
        let previousInterest = Double(removeCommas(previousHandInterest)) ?? 0
        let result = subscriptionAmt + previousInterest
        return formatWithCommas(String(format: "%.2f", result))
    }

    // 計算屬性：年度配息 = 票面利率 × 持有面額
    private var calculatedAnnualDividend: String {
        let couponRateStr = removeCommas(couponRate).replacingOccurrences(of: "%", with: "")
        let couponRateValue = Double(couponRateStr) ?? 0
        let faceValue = Double(removeCommas(holdingFaceValue)) ?? 0
        let result = (couponRateValue / 100) * faceValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    // 計算屬性：單次配息 = 年度配息 / 配息次數
    private var calculatedSingleDividend: String {
        let annualDividendValue = Double(removeCommas(calculatedAnnualDividend)) ?? 0
        let paymentCount = countDividendPayments(dividendMonths)
        guard paymentCount > 0 else { return "0.00" }
        let result = annualDividendValue / Double(paymentCount)
        return formatWithCommas(String(format: "%.2f", result))
    }

    // 計算配息次數
    private func countDividendPayments(_ dividendMonthsStr: String) -> Int {
        guard !dividendMonthsStr.isEmpty else { return 2 } // 預設半年配

        var months: [Int] = []

        // 統一替換頓號為逗號
        let normalized = dividendMonthsStr.replacingOccurrences(of: "、", with: ",")

        // 先嘗試用逗號分隔
        if normalized.contains(",") {
            months = normalized.split(separator: ",")
                .compactMap { part -> Int? in
                    let cleaned = part.trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "月", with: "")
                    return Int(cleaned)
                }
                .filter { $0 >= 1 && $0 <= 12 }
        }
        // 嘗試用斜線分隔
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

        return months.isEmpty ? 2 : months.count
    }

    // 計算屬性：殖利率 = 年度配息 / 交易金額
    private var calculatedYieldRate: String {
        let annualDividend = Double(removeCommas(calculatedAnnualDividend)) ?? 0
        let transactionAmount = Double(removeCommas(calculatedTransactionAmount)) ?? 0

        guard transactionAmount > 0 else { return "0.00%" }

        let result = (annualDividend / transactionAmount) * 100
        return String(format: "%.2f%%", result)
    }

    var hideTabSelector: Bool = false  // 新增參數：是否隱藏分頁選擇器
    var customTitle: String?  // 新增參數：自訂標題

    init(onSave: @escaping ([String], Date) -> Void, client: Client?, initialTab: Int = 0, hideTabSelector: Bool = false, customTitle: String? = nil, editingBond: CorporateBond? = nil) {
        self.onSave = onSave
        self.client = client
        self.hideTabSelector = hideTabSelector
        self.customTitle = customTitle
        self.editingBond = editingBond
        _selectedTab = State(initialValue: initialTab)

        // ⭐️ 如果是編輯模式,預填債券資料
        if let bond = editingBond {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            _bondName = State(initialValue: bond.bondName ?? "")
            _bondCurrency = State(initialValue: bond.currency ?? "USD")
            _couponRate = State(initialValue: bond.couponRate ?? "")
            _subscriptionPrice = State(initialValue: bond.subscriptionPrice ?? "")
            _holdingFaceValue = State(initialValue: bond.holdingFaceValue ?? "")
            _previousHandInterest = State(initialValue: bond.previousHandInterest ?? "")
            _dividendMonths = State(initialValue: bond.dividendMonths ?? "")
            _currentValue = State(initialValue: bond.currentValue ?? "")
            _receivedInterest = State(initialValue: bond.receivedInterest ?? "")
            _profitLossWithInterest = State(initialValue: bond.profitLossWithInterest ?? "")
            _returnRate = State(initialValue: bond.returnRate ?? "")

            // 日期欄位
            if let subDateStr = bond.subscriptionDate, let subDate = dateFormatter.date(from: subDateStr) {
                _subscriptionDate = State(initialValue: subDate)
            }
            if let matDateStr = bond.maturityDate, let matDate = dateFormatter.date(from: matDateStr) {
                _maturityDate = State(initialValue: matDate)
            }
        }

        // 設定 FetchRequest 以取得前一筆資料
        if let client = client {
            _monthlyAssets = FetchRequest<MonthlyAsset>(
                sortDescriptors: [NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@ AND isLiveSnapshot == NO", client),
                animation: .default
            )
        } else {
            _monthlyAssets = FetchRequest<MonthlyAsset>(
                sortDescriptors: [NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 頂部導航列
            topNavigationBar

            // 分頁選擇（可選）
            if !hideTabSelector {
                tabSelector
            }

            // 內容區域
            ScrollView {
                VStack(spacing: 0) {
                    if selectedTab == 0 {
                        // 資產明細分頁
                        basicInfoSection
                        assetInfoSection
                        depositInfoSection
                        notesSection
                    } else {
                        // 公司債分頁
                        corporateBondFormSection
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadPreviousData()
        }
        .sheet(isPresented: $showingFieldConfig) {
            AssetFieldConfigurationView()
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
        .sheet(isPresented: $showingCorporateBondsInventory) {
            if let client = client {
                CorporateBondsInventoryView(client: client)
                    .environment(\.managedObjectContext, viewContext)
                    .id(client.objectID) // ⭐️ 強制在客戶變更時重新建立 view，避免快取問題
            }
        }
        .sheet(isPresented: $showingStructuredProductsInventory) {
            StructuredProductsDetailView(client: client)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("提示", isPresented: $showingUpdateAlert) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(updateAlertMessage)
        }
    }

    // MARK: - 頂部導航列
    private var topNavigationBar: some View {
        HStack {
            Button("取消") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.system(size: 17))
            .foregroundColor(.blue)

            Spacer()

            Text(customTitle ?? "新增資產記錄")
                .font(.system(size: 17, weight: .semibold))

            Spacer()

            // 欄位設定按鈕
            Button(action: {
                showingFieldConfig = true
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17))
                    .foregroundColor(.blue)
            }
            .padding(.trailing, 8)

            Button("保存") {
                saveData()
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator))
                .offset(y: 50)
        )
    }

    // MARK: - 分頁選擇器
    private var tabSelector: some View {
        HStack(spacing: 0) {
            Button(action: { selectedTab = 0 }) {
                VStack(spacing: 8) {
                    Text("資產明細")
                        .font(.system(size: 16, weight: selectedTab == 0 ? .semibold : .regular))
                        .foregroundColor(selectedTab == 0 ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedTab == 0 ? Color(.systemBackground) : Color.clear)
                        .shadow(color: selectedTab == 0 ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { selectedTab = 1 }) {
                VStack(spacing: 8) {
                    Text("公司債")
                        .font(.system(size: 16, weight: selectedTab == 1 ? .semibold : .regular))
                        .foregroundColor(selectedTab == 1 ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedTab == 1 ? Color(.systemBackground) : Color.clear)
                        .shadow(color: selectedTab == 1 ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    // MARK: - 基本資訊區塊
    private var basicInfoSection: some View {
        VStack(spacing: 0) {
            sectionHeader("基本資訊")

            VStack(spacing: 0) {
                formRow(label: "當前客戶", value: client?.name ?? "未知客戶", isReadOnly: true)
                formDivider()
                dateFormRow(label: "選擇日期", date: $selectedDate)
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - 資產資訊區塊
    private var assetInfoSection: some View {
        VStack(spacing: 16) {
            // 一般資產欄位（排除成本、匯率換算、外幣匯率和折合美金，但保留外幣現金）
            let generalFields = configManager.visibleFields.filter { field in
                ![.fundCost, .usStockCost, .regularInvestmentCost, .bondsCost, .taiwanStockCost,
                  .exchangeRate, .taiwanStockFolded, .twdToUsd,
                  // 排除所有外幣折合美金欄位
                  .eurToUsd, .jpyToUsd, .gbpToUsd, .cnyToUsd, .audToUsd, .cadToUsd, .chfToUsd, .hkdToUsd, .sgdToUsd,
                  // 排除所有外幣匯率欄位
                  .eurRate, .jpyRate, .gbpRate, .cnyRate, .audRate, .cadRate, .chfRate, .hkdRate, .sgdRate
                ].contains(field.type)
            }

            if !generalFields.isEmpty {
                VStack(spacing: 0) {
                    sectionHeader("資產資訊")

                    VStack(spacing: 0) {
                        ForEach(Array(generalFields.enumerated()), id: \.element.id) { index, config in
                            if index > 0 {
                                formDivider()
                            }
                            fieldRow(for: config.type)
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)
            }

            // 投資成本分组
            let costFields = configManager.visibleFields.filter { field in
                [.fundCost, .usStockCost, .regularInvestmentCost, .bondsCost, .taiwanStockCost].contains(field.type)
            }

            if !costFields.isEmpty {
                VStack(spacing: 0) {
                    sectionHeader("投資成本")

                    VStack(spacing: 0) {
                        ForEach(Array(costFields.enumerated()), id: \.element.id) { index, config in
                            if index > 0 {
                                formDivider()
                            }
                            fieldRow(for: config.type)
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)
            }

            // 美金匯率換算分组
            let exchangeFields = configManager.visibleFields.filter { field in
                [.exchangeRate, .taiwanStockFolded, .twdToUsd].contains(field.type)
            }

            if !exchangeFields.isEmpty {
                VStack(spacing: 0) {
                    sectionHeader("美金匯率換算")

                    VStack(spacing: 0) {
                        ForEach(Array(exchangeFields.enumerated()), id: \.element.id) { index, config in
                            if index > 0 {
                                formDivider()
                            }
                            fieldRow(for: config.type)
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)
            }

            // 其他貨幣換算區域
            currencyExchangeSection(currency: "歐元", cashType: .eurCash, rateType: .eurRate, convertType: .eurToUsd)
            currencyExchangeSection(currency: "日圓", cashType: .jpyCash, rateType: .jpyRate, convertType: .jpyToUsd)
            currencyExchangeSection(currency: "英鎊", cashType: .gbpCash, rateType: .gbpRate, convertType: .gbpToUsd)
            currencyExchangeSection(currency: "人民幣", cashType: .cnyCash, rateType: .cnyRate, convertType: .cnyToUsd)
            currencyExchangeSection(currency: "澳幣", cashType: .audCash, rateType: .audRate, convertType: .audToUsd)
            currencyExchangeSection(currency: "加幣", cashType: .cadCash, rateType: .cadRate, convertType: .cadToUsd)
            currencyExchangeSection(currency: "瑞士法郎", cashType: .chfCash, rateType: .chfRate, convertType: .chfToUsd)
            currencyExchangeSection(currency: "港幣", cashType: .hkdCash, rateType: .hkdRate, convertType: .hkdToUsd)
            currencyExchangeSection(currency: "新加坡幣", cashType: .sgdCash, rateType: .sgdRate, convertType: .sgdToUsd)
        }
        .padding(.bottom, 16)
    }

    // MARK: - 貨幣換算區域（只顯示匯率和折合美金，現金在資產資訊中）
    @ViewBuilder
    private func currencyExchangeSection(currency: String, cashType: AssetFieldType, rateType: AssetFieldType, convertType: AssetFieldType) -> some View {
        // 只檢查匯率和折合美金欄位（現金欄位在資產資訊中）
        let currencyFields = configManager.visibleFields.filter { field in
            [rateType, convertType].contains(field.type)
        }

        if !currencyFields.isEmpty {
            VStack(spacing: 0) {
                sectionHeader("\(currency)換算")

                VStack(spacing: 0) {
                    ForEach(Array(currencyFields.enumerated()), id: \.element.id) { index, config in
                        if index > 0 {
                            formDivider()
                        }
                        fieldRow(for: config.type)
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 根據欄位類型生成對應的表單行
    @ViewBuilder
    private func fieldRow(for fieldType: AssetFieldType) -> some View {
        switch fieldType {
        case .twdCash:
            formRow(label: fieldType.displayName, value: $twdCash, placeholder: fieldType.displayName)
        case .cash:
            formRow(label: fieldType.displayName, value: $cash, placeholder: fieldType.displayName)
        case .usStock:
            formRowWithActions(label: fieldType.displayName, value: $usStock, placeholder: fieldType.displayName,
                             onRefresh: { updateUSStockFromInventory() },
                             onViewInventory: { showingUSStockInventory = true })
        case .regularInvestment:
            formRowWithActions(label: fieldType.displayName, value: $regularInvestment, placeholder: fieldType.displayName,
                             onRefresh: { updateRegularInvestmentFromInventory() },
                             onViewInventory: { showingRegularInvestmentInventory = true })
        case .bonds:
            formRowWithActions(label: fieldType.displayName, value: $bonds, placeholder: fieldType.displayName,
                             onRefresh: { updateBondsFromCorporateBonds() },
                             onViewInventory: { showingCorporateBondsInventory = true })
        case .taiwanStock:
            formRowWithActions(label: fieldType.displayName, value: $taiwanStock, placeholder: fieldType.displayName,
                             onRefresh: { updateTWStockFromInventory() },
                             onViewInventory: { showingTWStockInventory = true })
        case .taiwanStockFolded:
            formRow(label: fieldType.displayName, value: calculatedTaiwanStockFolded, isReadOnly: true)
        case .twdToUsd:
            formRow(label: fieldType.displayName, value: calculatedTwdToUsd, isReadOnly: true)
        case .structured:
            formRowWithActions(label: fieldType.displayName, value: $structured, placeholder: fieldType.displayName,
                             onRefresh: { updateStructuredFromInventory() },
                             onViewInventory: { showingStructuredProductsInventory = true })
        case .confirmedInterest:
            formRow(label: fieldType.displayName, value: $confirmedInterest, placeholder: fieldType.displayName)
        case .totalAssets:
            formRow(label: fieldType.displayName, value: calculatedTotalAssets, isReadOnly: true)
        case .fund:
            formRow(label: fieldType.displayName, value: $fund, placeholder: fieldType.displayName)
        case .insurance:
            formRow(label: fieldType.displayName, value: $insurance, placeholder: fieldType.displayName)
        case .exchangeRate:
            formRow(label: fieldType.displayName, value: $exchangeRate, placeholder: fieldType.displayName)
        case .fundCost:
            formRow(label: fieldType.displayName, value: $fundCost, placeholder: fieldType.displayName)
        case .usStockCost:
            formRowWithActions(label: fieldType.displayName, value: $usStockCost, placeholder: fieldType.displayName,
                             onRefresh: { updateUSStockFromInventory() },
                             onViewInventory: { showingUSStockInventory = true })
        case .regularInvestmentCost:
            formRow(label: fieldType.displayName, value: $regularInvestmentCost, placeholder: fieldType.displayName)
        case .bondsCost:
            formRow(label: fieldType.displayName, value: $bondsCost, placeholder: fieldType.displayName)
        case .taiwanStockCost:
            formRowWithActions(label: fieldType.displayName, value: $taiwanStockCost, placeholder: fieldType.displayName,
                             onRefresh: { updateTWStockFromInventory() },
                             onViewInventory: { showingTWStockInventory = true })

        // 其他貨幣
        case .eurCash:
            formRow(label: fieldType.displayName, value: $eurCash, placeholder: fieldType.displayName)
        case .jpyCash:
            formRow(label: fieldType.displayName, value: $jpyCash, placeholder: fieldType.displayName)
        case .gbpCash:
            formRow(label: fieldType.displayName, value: $gbpCash, placeholder: fieldType.displayName)
        case .cnyCash:
            formRow(label: fieldType.displayName, value: $cnyCash, placeholder: fieldType.displayName)
        case .audCash:
            formRow(label: fieldType.displayName, value: $audCash, placeholder: fieldType.displayName)
        case .cadCash:
            formRow(label: fieldType.displayName, value: $cadCash, placeholder: fieldType.displayName)
        case .chfCash:
            formRow(label: fieldType.displayName, value: $chfCash, placeholder: fieldType.displayName)
        case .hkdCash:
            formRow(label: fieldType.displayName, value: $hkdCash, placeholder: fieldType.displayName)
        case .sgdCash:
            formRow(label: fieldType.displayName, value: $sgdCash, placeholder: fieldType.displayName)

        // 匯率換算欄位（唯讀）
        case .eurToUsd:
            formRow(label: fieldType.displayName, value: calculatedEurToUsd, isReadOnly: true)
        case .jpyToUsd:
            formRow(label: fieldType.displayName, value: calculatedJpyToUsd, isReadOnly: true)
        case .gbpToUsd:
            formRow(label: fieldType.displayName, value: calculatedGbpToUsd, isReadOnly: true)
        case .cnyToUsd:
            formRow(label: fieldType.displayName, value: calculatedCnyToUsd, isReadOnly: true)
        case .audToUsd:
            formRow(label: fieldType.displayName, value: calculatedAudToUsd, isReadOnly: true)
        case .cadToUsd:
            formRow(label: fieldType.displayName, value: calculatedCadToUsd, isReadOnly: true)
        case .chfToUsd:
            formRow(label: fieldType.displayName, value: calculatedChfToUsd, isReadOnly: true)
        case .hkdToUsd:
            formRow(label: fieldType.displayName, value: calculatedHkdToUsd, isReadOnly: true)
        case .sgdToUsd:
            formRow(label: fieldType.displayName, value: calculatedSgdToUsd, isReadOnly: true)

        // 匯率欄位
        case .eurRate:
            formRow(label: fieldType.displayName, value: $eurRate, placeholder: fieldType.displayName)
        case .jpyRate:
            formRow(label: fieldType.displayName, value: $jpyRate, placeholder: fieldType.displayName)
        case .gbpRate:
            formRow(label: fieldType.displayName, value: $gbpRate, placeholder: fieldType.displayName)
        case .cnyRate:
            formRow(label: fieldType.displayName, value: $cnyRate, placeholder: fieldType.displayName)
        case .audRate:
            formRow(label: fieldType.displayName, value: $audRate, placeholder: fieldType.displayName)
        case .cadRate:
            formRow(label: fieldType.displayName, value: $cadRate, placeholder: fieldType.displayName)
        case .chfRate:
            formRow(label: fieldType.displayName, value: $chfRate, placeholder: fieldType.displayName)
        case .hkdRate:
            formRow(label: fieldType.displayName, value: $hkdRate, placeholder: fieldType.displayName)
        case .sgdRate:
            formRow(label: fieldType.displayName, value: $sgdRate, placeholder: fieldType.displayName)

        // 月度資產明細特有欄位（在其他區塊處理，這裡返回空視圖）
        case .date:
            EmptyView()
        case .deposit:
            EmptyView()
        case .depositAccumulated:
            EmptyView()
        case .notes:
            EmptyView()
        }
    }

    // MARK: - 匯入資訊區塊
    private var depositInfoSection: some View {
        VStack(spacing: 0) {
            sectionHeader("匯入資訊")

            VStack(spacing: 0) {
                formRow(label: "匯入", value: $deposit, placeholder: "匯入")
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - 備註區塊
    private var notesSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                formRow(label: "備註", value: $notes, placeholder: "備註")
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    // MARK: - 公司債表單區塊
    private var corporateBondFormSection: some View {
        VStack(spacing: 0) {
            // 基本資訊
            sectionHeader("基本資訊")
            VStack(spacing: 0) {
                formRow(label: "當前客戶", value: client?.name ?? "未知客戶", isReadOnly: true)
                formDivider()
                dateFormRow(label: "申購日", date: $subscriptionDate)
                formDivider()
                formRow(label: "債券名稱", value: $bondName, placeholder: "債券名稱")
                formDivider()
                dateFormRow(label: "到期日", date: $maturityDate)
                formDivider()
                currencyPickerRow
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            // 利率資訊
            sectionHeader("利率資訊")
            VStack(spacing: 0) {
                formRow(label: "票面利率", value: $couponRate, placeholder: "票面利率")
                formDivider()
                formRow(label: "殖利率", value: calculatedYieldRate, isReadOnly: true)
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            // 申購資訊
            sectionHeader("申購資訊")
            VStack(spacing: 0) {
                formRow(label: "申購價", value: $subscriptionPrice, placeholder: "申購價")
                formDivider()
                formRow(label: "持有面額", value: $holdingFaceValue, placeholder: "持有面額")
                formDivider()
                formRow(label: "申購金額", value: calculatedSubscriptionAmount, isReadOnly: true)
                formDivider()
                formRow(label: "前手息", value: $previousHandInterest, placeholder: "前手息")
                formDivider()
                formRow(label: "交易金額", value: calculatedTransactionAmount, isReadOnly: true)
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            // 配息資訊
            sectionHeader("配息資訊")
            VStack(spacing: 0) {
                dividendMonthsPicker
                formDivider()
                formRow(label: "單次配息", value: calculatedSingleDividend, isReadOnly: true)
                formDivider()
                formRow(label: "年度配息", value: calculatedAnnualDividend, isReadOnly: true)
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            // ⭐️ 當前狀態（選填）
            currentStatusSection
        }
    }

    // MARK: - 當前狀態區塊（選填）
    private var currentStatusSection: some View {
        VStack(spacing: 0) {
            // 標題區域
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0))
                Text("當前狀態")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("選填")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // 說明文字
            Text("新增舊有債券時可直接填寫當前現值和已領利息，若不填寫現值則預設等於交易金額")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // 輸入欄位
            VStack(spacing: 0) {
                formRow(label: "現值", value: $currentValue, placeholder: "留空自動填入")
                formDivider()
                formRow(label: "已領利息", value: $receivedInterest, placeholder: "例如: 1500")
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - 配息月份選擇器
    private var dividendMonthsPicker: some View {
        HStack {
            Text("配息月份")
                .font(.system(size: 17))
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)

            Spacer()

            Picker("", selection: $dividendMonths) {
                // 半年配息
                Text("1月、7月").tag("1月、7月")
                Text("2月、8月").tag("2月、8月")
                Text("3月、9月").tag("3月、9月")
                Text("4月、10月").tag("4月、10月")
                Text("5月、11月").tag("5月、11月")
                Text("6月、12月").tag("6月、12月")
                // 季配息
                Text("1、4、7、10月").tag("1、4、7、10月")
                Text("2、5、8、11月").tag("2、5、8、11月")
                Text("3、6、9、12月").tag("3、6、9、12月")
            }
            .pickerStyle(MenuPickerStyle())
            .tint(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 幣別選擇器
    private var currencyPickerRow: some View {
        HStack {
            Text("幣別")
                .font(.system(size: 17))
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)

            Spacer()

            Picker("", selection: $bondCurrency) {
                Text("USD 美金").tag("USD")
                Text("TWD 台幣").tag("TWD")
                Text("EUR 歐元").tag("EUR")
                Text("JPY 日圓").tag("JPY")
                Text("GBP 英鎊").tag("GBP")
                Text("CNY 人民幣").tag("CNY")
                Text("AUD 澳幣").tag("AUD")
                Text("CAD 加幣").tag("CAD")
                Text("CHF 瑞士法郎").tag("CHF")
                Text("HKD 港幣").tag("HKD")
                Text("SGD 新加坡幣").tag("SGD")
            }
            .pickerStyle(MenuPickerStyle())
            .tint(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 輔助組件
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func formRow(label: String, value: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17))
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)

            Spacer()

            TextField(placeholder, text: value)
                .font(.system(size: 17))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .keyboardType(isTextFieldLabel(label) ? .default : .decimalPad)
                .onChange(of: value.wrappedValue) { _ in
                    // 不再自動計算總資產
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // 帶有操作按鈕的表單行
    private func formRowWithActions(label: String, value: Binding<String>, placeholder: String, onRefresh: @escaping () -> Void, onViewInventory: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                    .frame(width: 80, alignment: .leading)

                // 更新現值按鈕
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.systemGray))
                        .frame(width: 24, height: 24)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                // 查看庫存按鈕
                Button(action: onViewInventory) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.systemGray))
                        .frame(width: 24, height: 24)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()

            TextField(placeholder, text: value)
                .font(.system(size: 17))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // 判斷是否為文字輸入欄位
    private func isTextFieldLabel(_ label: String) -> Bool {
        return ["債券名稱", "備註"].contains(label)
    }

    private func formRow(label: String, value: String, isReadOnly: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17))
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)

            Spacer()

            Text(value)
                .font(.system(size: 17))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func dateFormRow(label: String, date: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17))
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)

            Spacer()

            DatePicker("", selection: date, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func formDivider() -> some View {
        Rectangle()
            .frame(height: 0.5)
            .foregroundColor(Color(.separator))
            .padding(.leading, 16)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: selectedDate)
    }

    // MARK: - 載入前一筆資料
    private func loadPreviousData() {
        guard let previousAsset = monthlyAssets.first else {
            print("📋 沒有前一筆資料可載入")
            return
        }

        // 載入前一筆的資產數據（加上千分位）
        fund = formatWithCommas(previousAsset.fund ?? "")
        insurance = formatWithCommas(previousAsset.insurance ?? "")
        twdCash = formatWithCommas(previousAsset.twdCash ?? "")
        cash = formatWithCommas(previousAsset.cash ?? "")
        usStock = formatWithCommas(previousAsset.usStock ?? "")
        regularInvestment = formatWithCommas(previousAsset.regularInvestment ?? "")
        bonds = formatWithCommas(previousAsset.bonds ?? "")
        confirmedInterest = formatWithCommas(previousAsset.confirmedInterest ?? "")
        structured = formatWithCommas(previousAsset.structured ?? "")
        taiwanStock = formatWithCommas(previousAsset.taiwanStock ?? "")
        exchangeRate = formatWithCommas(previousAsset.exchangeRate ?? "")
        // 台股折合和台幣折合美金會自動計算，不需要載入

        // 載入成本數據（加上千分位）
        fundCost = formatWithCommas(previousAsset.fundCost ?? "")
        usStockCost = formatWithCommas(previousAsset.usStockCost ?? "")
        regularInvestmentCost = formatWithCommas(previousAsset.regularInvestmentCost ?? "")
        bondsCost = formatWithCommas(previousAsset.bondsCost ?? "")
        taiwanStockCost = formatWithCommas(previousAsset.taiwanStockCost ?? "")

        // 載入其他貨幣數據（加上千分位）
        eurCash = formatWithCommas(previousAsset.eurCash ?? "")
        jpyCash = formatWithCommas(previousAsset.jpyCash ?? "")
        gbpCash = formatWithCommas(previousAsset.gbpCash ?? "")
        cnyCash = formatWithCommas(previousAsset.cnyCash ?? "")
        audCash = formatWithCommas(previousAsset.audCash ?? "")
        cadCash = formatWithCommas(previousAsset.cadCash ?? "")
        chfCash = formatWithCommas(previousAsset.chfCash ?? "")
        hkdCash = formatWithCommas(previousAsset.hkdCash ?? "")
        sgdCash = formatWithCommas(previousAsset.sgdCash ?? "")

        // 載入匯率數據（加上千分位）
        eurRate = formatWithCommas(previousAsset.eurRate ?? "")
        jpyRate = formatWithCommas(previousAsset.jpyRate ?? "")
        gbpRate = formatWithCommas(previousAsset.gbpRate ?? "")
        cnyRate = formatWithCommas(previousAsset.cnyRate ?? "")
        audRate = formatWithCommas(previousAsset.audRate ?? "")
        cadRate = formatWithCommas(previousAsset.cadRate ?? "")
        chfRate = formatWithCommas(previousAsset.chfRate ?? "")
        hkdRate = formatWithCommas(previousAsset.hkdRate ?? "")
        sgdRate = formatWithCommas(previousAsset.sgdRate ?? "")

        // 總資產和匯率換算會自動計算，不需要載入

        // 匯入和備註設為空（不複製）
        deposit = ""
        notes = ""

        print("📋 已載入前一筆資料：日期=\(previousAsset.date ?? "")")
    }


    // MARK: - 千分位格式化
    private func formatWithCommas(_ value: String) -> String {
        guard !value.isEmpty else { return "" }

        // 移除現有的逗號
        let cleanValue = value.replacingOccurrences(of: ",", with: "")

        // 如果可以轉換成數字，加上千分位
        if let number = Double(cleanValue) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            return formatter.string(from: NSNumber(value: number)) ?? cleanValue
        }

        return cleanValue
    }

    private func removeCommas(_ value: String) -> String {
        return value.replacingOccurrences(of: ",", with: "")
    }

    private func saveData() {
        guard let client = client else {
            print("❌ 無法儲存：沒有選中的客戶")
            return
        }

        if selectedTab == 0 {
            // 儲存月度資產
            saveMonthlyAsset(for: client)
        } else {
            // 儲存公司債
            saveCorporateBond(for: client)
        }

        presentationMode.wrappedValue.dismiss()
    }

    private func saveMonthlyAsset(for client: Client) {
        // 計算匯入累積 = 前一筆的匯入累積 + 本次匯入
        let previousDepositAccumulated = Double(monthlyAssets.first?.depositAccumulated ?? "0") ?? 0
        let currentDeposit = Double(removeCommas(deposit)) ?? 0
        let depositAccumulated = previousDepositAccumulated + currentDeposit

        let newData = [
            dateString,
            twdCash.isEmpty ? "0" : removeCommas(twdCash),
            cash.isEmpty ? "0" : removeCommas(cash),
            usStock.isEmpty ? "0" : removeCommas(usStock),
            regularInvestment.isEmpty ? "0" : removeCommas(regularInvestment),
            bonds.isEmpty ? "0" : removeCommas(bonds),
            confirmedInterest.isEmpty ? "0" : removeCommas(confirmedInterest),
            structured.isEmpty ? "0" : removeCommas(structured),
            taiwanStock.isEmpty ? "0" : removeCommas(taiwanStock),
            removeCommas(calculatedTaiwanStockFolded), // 使用自動計算的值
            removeCommas(calculatedTwdToUsd), // 使用自動計算的值
            removeCommas(calculatedTotalAssets), // 使用自動計算的值
            exchangeRate.isEmpty ? "32" : removeCommas(exchangeRate),
            deposit.isEmpty ? "0" : removeCommas(deposit),
            String(format: "%.2f", depositAccumulated),
            usStockCost.isEmpty ? "0" : removeCommas(usStockCost),
            regularInvestmentCost.isEmpty ? "0" : removeCommas(regularInvestmentCost),
            bondsCost.isEmpty ? "0" : removeCommas(bondsCost),
            taiwanStockCost.isEmpty ? "0" : removeCommas(taiwanStockCost),
            notes,
            fund.isEmpty ? "0" : removeCommas(fund),
            fundCost.isEmpty ? "0" : removeCommas(fundCost),
            insurance.isEmpty ? "0" : removeCommas(insurance),
            // 其他貨幣現金
            eurCash.isEmpty ? "0" : removeCommas(eurCash),
            jpyCash.isEmpty ? "0" : removeCommas(jpyCash),
            gbpCash.isEmpty ? "0" : removeCommas(gbpCash),
            cnyCash.isEmpty ? "0" : removeCommas(cnyCash),
            audCash.isEmpty ? "0" : removeCommas(audCash),
            cadCash.isEmpty ? "0" : removeCommas(cadCash),
            chfCash.isEmpty ? "0" : removeCommas(chfCash),
            hkdCash.isEmpty ? "0" : removeCommas(hkdCash),
            sgdCash.isEmpty ? "0" : removeCommas(sgdCash),
            // 貨幣折合美金（自動計算）
            removeCommas(calculatedEurToUsd),
            removeCommas(calculatedJpyToUsd),
            removeCommas(calculatedGbpToUsd),
            removeCommas(calculatedCnyToUsd),
            removeCommas(calculatedAudToUsd),
            removeCommas(calculatedCadToUsd),
            removeCommas(calculatedChfToUsd),
            removeCommas(calculatedHkdToUsd),
            removeCommas(calculatedSgdToUsd),
            // 匯率
            eurRate.isEmpty ? "0" : removeCommas(eurRate),
            jpyRate.isEmpty ? "0" : removeCommas(jpyRate),
            gbpRate.isEmpty ? "0" : removeCommas(gbpRate),
            cnyRate.isEmpty ? "0" : removeCommas(cnyRate),
            audRate.isEmpty ? "0" : removeCommas(audRate),
            cadRate.isEmpty ? "0" : removeCommas(cadRate),
            chfRate.isEmpty ? "0" : removeCommas(chfRate),
            hkdRate.isEmpty ? "0" : removeCommas(hkdRate),
            sgdRate.isEmpty ? "0" : removeCommas(sgdRate)
        ]

        print("💾 即將為客戶 '\(client.name ?? "")' 儲存月度資產：\(newData)")
        onSave(newData, selectedDate) // 修改：傳遞使用者選擇的日期
    }

    private func saveCorporateBond(for client: Client) {
        // ⭐️ 判斷是更新還是新增
        let bond: CorporateBond
        if let existingBond = editingBond {
            // 編輯模式：更新現有債券
            bond = existingBond
            print("📝 編輯模式：更新債券 '\(bondName)'")
        } else {
            // 新增模式：創建新債券
            bond = CorporateBond(context: viewContext)
            bond.client = client
            bond.createdDate = Date()
            print("➕ 新增模式：創建債券 '\(bondName)'")
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        bond.subscriptionDate = dateFormatter.string(from: subscriptionDate)

        bond.bondName = bondName.isEmpty ? "" : bondName
        bond.maturityDate = dateFormatter.string(from: maturityDate)  // 儲存到期日
        bond.currency = bondCurrency // 儲存幣別
        bond.couponRate = couponRate.isEmpty ? "" : couponRate
        bond.yieldRate = calculatedYieldRate // 儲存計算後的值
        bond.subscriptionPrice = subscriptionPrice.isEmpty ? "" : removeCommas(subscriptionPrice)
        bond.subscriptionAmount = removeCommas(calculatedSubscriptionAmount) // 儲存計算後的值
        bond.holdingFaceValue = holdingFaceValue.isEmpty ? "" : removeCommas(holdingFaceValue)
        bond.previousHandInterest = previousHandInterest.isEmpty ? "" : removeCommas(previousHandInterest) // 新增：前手息
        bond.transactionAmount = removeCommas(calculatedTransactionAmount) // 儲存計算後的值

        // ⭐️ 如果現值為空，自動使用交易金額
        let cleanedCurrentValue = removeCommas(currentValue)
        if cleanedCurrentValue.isEmpty || (Double(cleanedCurrentValue) ?? 0) == 0 {
            bond.currentValue = removeCommas(calculatedTransactionAmount)
            print("✅ 現值為空，自動使用交易金額：\(bond.currentValue ?? "")")
        } else {
            bond.currentValue = cleanedCurrentValue
        }

        bond.receivedInterest = receivedInterest.isEmpty ? "" : removeCommas(receivedInterest)
        bond.profitLossWithInterest = profitLossWithInterest.isEmpty ? "" : profitLossWithInterest
        bond.returnRate = returnRate.isEmpty ? "" : returnRate
        bond.dividendMonths = dividendMonths.isEmpty ? "" : dividendMonths
        bond.singleDividend = removeCommas(calculatedSingleDividend) // 儲存計算後的值
        bond.annualDividend = removeCommas(calculatedAnnualDividend) // 儲存計算後的值

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            if editingBond != nil {
                print("✅ 成功更新公司債：\(bondName)")
            } else {
                print("✅ 成功為客戶 '\(client.name ?? "")' 新增公司債：\(bondName)")
            }
        } catch {
            print("❌ 儲存公司債失敗: \(error)")
        }
    }

    // MARK: - 從庫存明細更新現值功能
    private func updateUSStockFromInventory() {
        guard let client = client else {
            updateAlertMessage = "無法更新：沒有選中的客戶"
            showingUpdateAlert = true
            return
        }

        // 獲取該客戶的所有美股持倉
        let fetchRequest: NSFetchRequest<USStock> = USStock.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        do {
            let usStocks = try viewContext.fetch(fetchRequest)

            if usStocks.isEmpty {
                updateAlertMessage = "目前沒有美股庫存明細\n\n💡 點擊右邊的 👁️ 按鈕可以新增美股持股記錄"
                showingUpdateAlert = true
                return
            }

            // 標記正在更新
            isUpdatingPrices = true

            // 先更新股價
            Task {
                // 收集所有股票代碼
                let symbols = usStocks.compactMap { stock -> String? in
                    let symbol = stock.name?.trimmingCharacters(in: .whitespaces).uppercased()
                    return (symbol?.isEmpty == false) ? symbol : nil
                }

                guard !symbols.isEmpty else {
                    await MainActor.run {
                        isUpdatingPrices = false
                        updateAlertMessage = "沒有有效的股票代碼"
                        showingUpdateAlert = true
                    }
                    return
                }

                // 批量獲取股價
                let prices = await StockPriceService.shared.fetchMultipleStockPrices(symbols: symbols)

                // 在主線程更新 UI
                await MainActor.run {
                    var successCount = 0
                    var failCount = 0

                    // 更新每個股票的現價
                    for stock in usStocks {
                        guard let symbol = stock.name?.trimmingCharacters(in: .whitespaces).uppercased(),
                              !symbol.isEmpty else {
                            continue
                        }

                        if let newPrice = prices[symbol] {
                            // 更新現價
                            stock.currentPrice = newPrice
                            // 重新計算市值、損益、報酬率
                            recalculateStock(stock: stock)
                            successCount += 1
                        } else {
                            failCount += 1
                        }
                    }

                    // 保存到 Core Data
                    if successCount > 0 {
                        do {
                            try viewContext.save()
                            PersistenceController.shared.save()
                        } catch {
                            print("❌ 儲存失敗: \(error)")
                        }
                    }

                    // 計算總市值和總成本
                    var totalMarketValue: Double = 0
                    var totalCost: Double = 0

                    for stock in usStocks {
                        totalMarketValue += Double(removeCommas(stock.marketValue ?? "0")) ?? 0
                        totalCost += Double(removeCommas(stock.cost ?? "0")) ?? 0
                    }

                    // 更新美股和美股成本欄位
                    usStock = formatWithCommas(String(format: "%.2f", totalMarketValue))
                    usStockCost = formatWithCommas(String(format: "%.2f", totalCost))

                    isUpdatingPrices = false

                    // 顯示結果
                    if successCount > 0 {
                        updateAlertMessage = """
                        ✅ 更新成功！

                        股價更新：成功 \(successCount) 支\(failCount > 0 ? "，失敗 \(failCount) 支" : "")

                        美股市值：$\(formatWithCommas(String(format: "%.2f", totalMarketValue)))
                        美股成本：$\(formatWithCommas(String(format: "%.2f", totalCost)))
                        """
                    } else {
                        updateAlertMessage = "股價更新失敗\n請檢查網路連線和股票代碼"
                    }
                    showingUpdateAlert = true

                    print("✅ 已更新美股股價並填入：市值=\(totalMarketValue), 成本=\(totalCost)")
                }
            }
        } catch {
            updateAlertMessage = "讀取美股庫存失敗：\(error.localizedDescription)"
            showingUpdateAlert = true
        }
    }

    // 重新計算股票的市值、損益、報酬率
    private func recalculateStock(stock: USStock) {
        let shares = Double(removeCommas(stock.shares ?? "0")) ?? 0
        let costPerShare = Double(removeCommas(stock.costPerShare ?? "0")) ?? 0
        let currentPrice = Double(removeCommas(stock.currentPrice ?? "0")) ?? 0

        // 計算市值 = 現價 × 股數
        let marketValue = currentPrice * shares
        stock.marketValue = String(format: "%.2f", marketValue)

        // 計算成本 = 成本單價 × 股數
        let cost = costPerShare * shares
        stock.cost = String(format: "%.2f", cost)

        // 計算損益 = 市值 - 成本
        let profitLoss = marketValue - cost
        stock.profitLoss = String(format: "%.2f", profitLoss)

        // 計算報酬率 = 損益 / 成本 × 100
        if cost > 0 {
            let returnRate = (profitLoss / cost) * 100
            stock.returnRate = String(format: "%.2f%%", returnRate)
        } else {
            stock.returnRate = "0.00%"
        }
    }

    private func updateTWStockFromInventory() {
        guard let client = client else {
            updateAlertMessage = "無法更新：沒有選中的客戶"
            showingUpdateAlert = true
            return
        }

        // 獲取該客戶的所有台股持倉
        let fetchRequest: NSFetchRequest<TWStock> = TWStock.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        do {
            let twStocks = try viewContext.fetch(fetchRequest)

            if twStocks.isEmpty {
                updateAlertMessage = "目前沒有台股庫存明細\n\n💡 點擊右邊的 👁️ 按鈕可以新增台股持股記錄"
                showingUpdateAlert = true
                return
            }

            // 標記正在更新
            isUpdatingPrices = true

            // 先更新股價
            Task {
                // 收集所有股票代碼
                let symbols = twStocks.compactMap { stock -> String? in
                    let symbol = stock.name?.trimmingCharacters(in: .whitespaces)
                    return (symbol?.isEmpty == false) ? symbol : nil
                }

                guard !symbols.isEmpty else {
                    await MainActor.run {
                        isUpdatingPrices = false
                        updateAlertMessage = "沒有有效的股票代碼"
                        showingUpdateAlert = true
                    }
                    return
                }

                // 批量獲取股價（台股使用同一個方法，代碼通常是 XXXX.TW 格式）
                let prices = await StockPriceService.shared.fetchMultipleStockPrices(symbols: symbols)

                // 在主線程更新 UI
                await MainActor.run {
                    var successCount = 0
                    var failCount = 0

                    // 更新每個股票的現價
                    for stock in twStocks {
                        guard let symbol = stock.name?.trimmingCharacters(in: .whitespaces),
                              !symbol.isEmpty else {
                            continue
                        }

                        if let newPrice = prices[symbol] {
                            // 更新現價
                            stock.currentPrice = newPrice
                            // 重新計算市值、損益、報酬率
                            recalculateTWStock(stock: stock)
                            successCount += 1
                        } else {
                            failCount += 1
                        }
                    }

                    // 保存到 Core Data
                    if successCount > 0 {
                        do {
                            try viewContext.save()
                            PersistenceController.shared.save()
                        } catch {
                            print("❌ 儲存失敗: \(error)")
                        }
                    }

                    // 計算總市值和總成本
                    var totalMarketValue: Double = 0
                    var totalCost: Double = 0

                    for stock in twStocks {
                        totalMarketValue += Double(removeCommas(stock.marketValue ?? "0")) ?? 0
                        totalCost += Double(removeCommas(stock.cost ?? "0")) ?? 0
                    }

                    // 更新台股和台股成本欄位
                    taiwanStock = formatWithCommas(String(format: "%.2f", totalMarketValue))
                    taiwanStockCost = formatWithCommas(String(format: "%.2f", totalCost))

                    isUpdatingPrices = false

                    // 顯示結果
                    if successCount > 0 {
                        updateAlertMessage = """
                        ✅ 更新成功！

                        股價更新：成功 \(successCount) 支\(failCount > 0 ? "，失敗 \(failCount) 支" : "")

                        台股市值：NT$\(formatWithCommas(String(format: "%.2f", totalMarketValue)))
                        台股成本：NT$\(formatWithCommas(String(format: "%.2f", totalCost)))
                        """
                    } else {
                        updateAlertMessage = "股價更新失敗\n請檢查網路連線和股票代碼"
                    }
                    showingUpdateAlert = true

                    print("✅ 已更新台股股價並填入：市值=\(totalMarketValue), 成本=\(totalCost)")
                }
            }
        } catch {
            updateAlertMessage = "讀取台股庫存失敗：\(error.localizedDescription)"
            showingUpdateAlert = true
        }
    }

    // 重新計算台股的市值、損益、報酬率
    private func recalculateTWStock(stock: TWStock) {
        let shares = Double(removeCommas(stock.shares ?? "0")) ?? 0
        let costPerShare = Double(removeCommas(stock.costPerShare ?? "0")) ?? 0
        let currentPrice = Double(removeCommas(stock.currentPrice ?? "0")) ?? 0

        // 計算市值 = 現價 × 股數
        let marketValue = currentPrice * shares
        stock.marketValue = String(format: "%.2f", marketValue)

        // 計算成本 = 成本單價 × 股數
        let cost = costPerShare * shares
        stock.cost = String(format: "%.2f", cost)

        // 計算損益 = 市值 - 成本
        let profitLoss = marketValue - cost
        stock.profitLoss = String(format: "%.2f", profitLoss)

        // 計算報酬率 = 損益 / 成本 × 100
        if cost > 0 {
            let returnRate = (profitLoss / cost) * 100
            stock.returnRate = String(format: "%.2f%%", returnRate)
        } else {
            stock.returnRate = "0.00%"
        }
    }

    // MARK: - 定期定額更新功能
    private func updateRegularInvestmentFromInventory() {
        guard let client = client else {
            updateAlertMessage = "無法更新：沒有選中的客戶"
            showingUpdateAlert = true
            return
        }

        // 獲取該客戶的定期定額持倉
        let fetchRequest: NSFetchRequest<RegularInvestment> = RegularInvestment.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        do {
            let investments = try viewContext.fetch(fetchRequest)

            if investments.isEmpty {
                updateAlertMessage = "目前沒有定期定額庫存明細\n\n💡 點擊右邊的 👁️ 按鈕可以新增定期定額記錄"
                showingUpdateAlert = true
                return
            }

            // 計算總市值和總成本
            var totalMarketValue: Double = 0
            var totalCost: Double = 0

            for investment in investments {
                totalMarketValue += Double(removeCommas(investment.marketValue ?? "0")) ?? 0
                totalCost += Double(removeCommas(investment.cost ?? "0")) ?? 0
            }

            // 更新定期定額和定期定額成本欄位
            regularInvestment = formatWithCommas(String(format: "%.2f", totalMarketValue))
            regularInvestmentCost = formatWithCommas(String(format: "%.2f", totalCost))

            // 顯示成功提示
            updateAlertMessage = """
            ✅ 更新成功！

            定期定額市值：$\(formatWithCommas(String(format: "%.2f", totalMarketValue)))
            定期定額成本：$\(formatWithCommas(String(format: "%.2f", totalCost)))
            """
            showingUpdateAlert = true

            print("✅ 已從庫存明細更新定期定額：市值=\(totalMarketValue), 成本=\(totalCost)")
        } catch {
            updateAlertMessage = "讀取定期定額庫存失敗：\(error.localizedDescription)"
            showingUpdateAlert = true
        }
    }

    // MARK: - 債券更新功能（從公司債明細）
    private func updateBondsFromCorporateBonds() {
        guard let client = client else {
            updateAlertMessage = "無法更新：沒有選中的客戶"
            showingUpdateAlert = true
            return
        }

        // 獲取該客戶的公司債明細
        let fetchRequest: NSFetchRequest<CorporateBond> = CorporateBond.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        do {
            let corporateBonds = try viewContext.fetch(fetchRequest)

            if corporateBonds.isEmpty {
                updateAlertMessage = "目前沒有公司債明細\n\n💡 點擊右邊的 👁️ 按鈕可以新增公司債記錄"
                showingUpdateAlert = true
                return
            }

            // 計算總現值和總成本
            var totalCurrentValue: Double = 0
            var totalCost: Double = 0
            var bondCount = 0

            for bond in corporateBonds {
                // 現值（如果沒有現值，使用交易金額）
                let currentValue = Double(removeCommas(bond.currentValue ?? "0")) ?? 0
                let transactionAmount = Double(removeCommas(bond.transactionAmount ?? "0")) ?? 0
                let valueToUse = currentValue > 0 ? currentValue : transactionAmount

                totalCurrentValue += valueToUse
                totalCost += transactionAmount
                bondCount += 1
            }

            // 更新債券和債券成本欄位
            bonds = formatWithCommas(String(format: "%.2f", totalCurrentValue))
            bondsCost = formatWithCommas(String(format: "%.2f", totalCost))

            // 顯示成功提示
            updateAlertMessage = """
            ✅ 更新成功！

            已加總 \(bondCount) 檔公司債

            債券現值：$\(formatWithCommas(String(format: "%.2f", totalCurrentValue)))
            債券成本：$\(formatWithCommas(String(format: "%.2f", totalCost)))
            """
            showingUpdateAlert = true

            print("✅ 已從公司債明細更新債券：現值=\(totalCurrentValue), 成本=\(totalCost)")
        } catch {
            updateAlertMessage = "讀取公司債明細失敗：\(error.localizedDescription)"
            showingUpdateAlert = true
        }
    }

    // MARK: - 結構型商品更新功能
    private func updateStructuredFromInventory() {
        guard let client = client else {
            updateAlertMessage = "無法更新：沒有選中的客戶"
            showingUpdateAlert = true
            return
        }

        // 獲取該客戶的結構型商品明細（只計算未退出的）
        let fetchRequest: NSFetchRequest<StructuredProduct> = StructuredProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@ AND isExited == NO", client)

        do {
            let products = try viewContext.fetch(fetchRequest)

            if products.isEmpty {
                updateAlertMessage = "目前沒有結構型商品庫存明細\n\n💡 點擊右邊的 👁️ 按鈕可以新增結構型商品記錄"
                showingUpdateAlert = true
                return
            }

            // 計算總交易金額
            var totalAmount: Double = 0
            var productCount = 0

            for product in products {
                let amount = Double(removeCommas(product.transactionAmount ?? "0")) ?? 0
                totalAmount += amount
                productCount += 1
            }

            // 更新結構型商品欄位
            structured = formatWithCommas(String(format: "%.2f", totalAmount))

            // 顯示成功提示
            updateAlertMessage = """
            ✅ 更新成功！

            已加總 \(productCount) 檔結構型商品（未退出）

            總交易金額：$\(formatWithCommas(String(format: "%.2f", totalAmount)))
            """
            showingUpdateAlert = true

            print("✅ 已從結構型商品明細更新：總金額=\(totalAmount), 商品數=\(productCount)")
        } catch {
            updateAlertMessage = "讀取結構型商品明細失敗：\(error.localizedDescription)"
            showingUpdateAlert = true
        }
    }
}

#Preview {
    AddMonthlyDataView(onSave: { _, _ in }, client: nil)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}