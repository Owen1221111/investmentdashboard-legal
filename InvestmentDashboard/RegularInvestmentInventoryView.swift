import SwiftUI
import CoreData

struct RegularInvestmentInventoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client?

    // FetchRequest 取得當前客戶的定期定額資料
    @FetchRequest private var regularInvestments: FetchedResults<RegularInvestment>

    @State private var showingAddInvestment = false
    @State private var showingSyncConfirmation = false
    @State private var showingSyncResult = false
    @State private var syncMessage = ""
    @State private var showingAutoInvestResult = false
    @State private var autoInvestMessage = ""

    // 匯率 AppStorage
    @AppStorage("exchangeRate") private var tempExchangeRate: String = "32"
    @AppStorage("eurRate") private var tempEURRate: String = ""
    @AppStorage("jpyRate") private var tempJPYRate: String = ""
    @AppStorage("gbpRate") private var tempGBPRate: String = ""
    @AppStorage("cnyRate") private var tempCNYRate: String = ""
    @AppStorage("audRate") private var tempAUDRate: String = ""
    @AppStorage("cadRate") private var tempCADRate: String = ""
    @AppStorage("chfRate") private var tempCHFRate: String = ""
    @AppStorage("hkdRate") private var tempHKDRate: String = ""
    @AppStorage("sgdRate") private var tempSGDRate: String = ""

    init(client: Client?) {
        self.client = client

        // 設定 FetchRequest 以取得該客戶的定期定額資料
        if let client = client {
            _regularInvestments = FetchRequest<RegularInvestment>(
                sortDescriptors: [NSSortDescriptor(keyPath: \RegularInvestment.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client),
                animation: .default
            )
        } else {
            _regularInvestments = FetchRequest<RegularInvestment>(
                sortDescriptors: [NSSortDescriptor(keyPath: \RegularInvestment.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 標題區域
                headerView

                Divider()

                // 持倉列表
                if regularInvestments.isEmpty {
                    emptyStateView
                } else {
                    investmentListView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // 功能選單
                        Menu {
                            // 同步到月度資產
                            Button(action: {
                                showingSyncConfirmation = true
                            }) {
                                Label("同步至月度資產", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .disabled(regularInvestments.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }

                        // 新增按鈕
                        Button(action: {
                            showingAddInvestment = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .alert("同步確認", isPresented: $showingSyncConfirmation) {
                Button("取消", role: .cancel) { }
                Button("確認") {
                    syncToMonthlyAsset()
                }
            } message: {
                Text("將定期定額數據同步到最新的月度資產記錄？")
            }
            .alert("同步結果", isPresented: $showingSyncResult) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(syncMessage)
            }
            .sheet(isPresented: $showingAddInvestment) {
                AddRegularInvestmentView(client: client)
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert("自動投入完成", isPresented: $showingAutoInvestResult) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(autoInvestMessage)
            }
            .onAppear {
                checkAndAutoInvest()
            }
        }
    }

    // MARK: - 自動投入檢查
    private func checkAndAutoInvest() {
        var investedCount = 0
        var totalInvested: Double = 0

        let calendar = Calendar.current
        let today = Date()

        for investment in regularInvestments {
            // 解析週期
            let cycle = investment.cycle ?? "每月1日"
            var cycleDay = 1

            // 提取日期數字
            for option in ["每週", "每兩週", "每月", "每季", "每半年", "每年"] {
                if cycle.hasPrefix(option) {
                    let dayStr = cycle.replacingOccurrences(of: option, with: "").replacingOccurrences(of: "日", with: "")
                    if let day = Int(dayStr) {
                        cycleDay = day
                    }
                    break
                }
            }

            // 檢查是否需要投入
            let lastInvestment = investment.lastInvestmentDate ?? investment.createdDate ?? Date.distantPast

            // 計算本月的投入日期
            var components = calendar.dateComponents([.year, .month], from: today)
            components.day = min(cycleDay, 28) // 避免超過月份天數
            guard let investmentDate = calendar.date(from: components) else { continue }

            // 如果今天 >= 投入日 且 上次投入在本月投入日之前
            let lastInvestmentMonth = calendar.dateComponents([.year, .month], from: lastInvestment)
            let currentMonth = calendar.dateComponents([.year, .month], from: today)

            let isNewMonth = lastInvestmentMonth.year != currentMonth.year || lastInvestmentMonth.month != currentMonth.month
            let isPastInvestmentDay = today >= investmentDate

            if isNewMonth && isPastInvestmentDay {
                // 執行自動投入
                let investmentAmount = Double(investment.investmentAmount ?? "0") ?? 0
                let currentCost = Double(investment.cost ?? "0") ?? 0
                let newCost = currentCost + investmentAmount

                investment.cost = String(format: "%.2f", newCost)
                investment.lastInvestmentDate = today

                // 重新計算損益和報酬率
                let marketValue = Double(investment.marketValue ?? "0") ?? 0
                let profitLoss = marketValue - newCost
                investment.profitLoss = String(format: "%.2f", profitLoss)

                if newCost > 0 {
                    let returnRate = (profitLoss / newCost) * 100
                    investment.returnRate = String(format: "%.2f", returnRate)
                }

                investedCount += 1
                totalInvested += investmentAmount
            }
        }

        // 保存並顯示結果
        if investedCount > 0 {
            do {
                try viewContext.save()
                PersistenceController.shared.save()

                autoInvestMessage = """
                已自動投入 \(investedCount) 個標的

                本次投入金額：$\(String(format: "%.2f", totalInvested))
                """
                showingAutoInvestResult = true
            } catch {
                print("自動投入保存失敗: \(error)")
            }
        }
    }

    // MARK: - 標題區域
    private var headerView: some View {
        VStack(spacing: 12) {
            // 統計數字
            HStack(spacing: 4) {
                // 總市值
                VStack(alignment: .center, spacing: 4) {
                    Text("總市值")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(getTotalMarketValue()))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)

                Divider()
                    .frame(height: 30)

                // 總成本
                VStack(alignment: .center, spacing: 4) {
                    Text("總成本")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(getTotalCost()))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)

                Divider()
                    .frame(height: 30)

                // 總損益
                VStack(alignment: .center, spacing: 4) {
                    Text("總損益")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(getTotalProfitLoss()))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(getTotalProfitLoss() >= 0 ? .green : .red)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)

                Divider()
                    .frame(height: 30)

                // 報酬率
                VStack(alignment: .center, spacing: 4) {
                    Text("報酬率")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatReturnRate(getTotalReturnRate()))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(getTotalReturnRate() >= 0 ? .green : .red)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - 空狀態視圖
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "arrow.triangle.2.circlepath.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("尚無定期定額明細")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("點擊右上角 ⊕ 新增定期定額標的")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: {
                showingAddInvestment = true
            }) {
                Text("新增標的")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 投資列表
    private var investmentListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(regularInvestments) { investment in
                    RegularInvestmentRowView(investment: investment, viewContext: viewContext)
                }
            }
            .padding()
        }
    }

    // MARK: - 計算函數
    private func getTotalMarketValue() -> Double {
        return regularInvestments.reduce(0) { total, investment in
            let marketValue = Double(investment.marketValue ?? "0") ?? 0
            return total + calculateConvertedToUSD(investment: investment, amount: marketValue)
        }
    }

    private func getTotalCost() -> Double {
        return regularInvestments.reduce(0) { total, investment in
            let cost = Double(investment.cost ?? "0") ?? 0
            return total + calculateConvertedToUSD(investment: investment, amount: cost)
        }
    }

    private func getTotalProfitLoss() -> Double {
        getTotalMarketValue() - getTotalCost()
    }

    private func getTotalReturnRate() -> Double {
        let cost = getTotalCost()
        guard cost > 0 else { return 0 }
        return (getTotalProfitLoss() / cost) * 100
    }

    // MARK: - 同步到月度資產
    private func syncToMonthlyAsset() {
        guard let client = client else {
            syncMessage = "無法找到客戶資料"
            showingSyncResult = true
            return
        }

        // 計算總市值和總成本
        let totalMarketValue = getTotalMarketValue()
        let totalCost = getTotalCost()

        // 獲取最新的月度資產記錄
        let fetchRequest: NSFetchRequest<MonthlyAsset> = MonthlyAsset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)

            guard let latestAsset = results.first else {
                syncMessage = "找不到月度資產記錄\n\n請先新增月度資產記錄"
                showingSyncResult = true
                return
            }

            // 保存舊值用於顯示
            let oldValue = Double(latestAsset.regularInvestment ?? "0") ?? 0
            let dateString = latestAsset.date ?? ""

            // 更新定期定額市值和成本
            latestAsset.regularInvestment = String(format: "%.2f", totalMarketValue)
            latestAsset.regularInvestmentCost = String(format: "%.2f", totalCost)

            // 重新計算總資產
            let cash = Double(latestAsset.cash ?? "0") ?? 0
            let usStock = Double(latestAsset.usStock ?? "0") ?? 0
            let bonds = Double(latestAsset.bonds ?? "0") ?? 0
            let structured = Double(latestAsset.structured ?? "0") ?? 0
            let taiwanStockFolded = Double(latestAsset.taiwanStockFolded ?? "0") ?? 0
            let twdToUsd = Double(latestAsset.twdToUsd ?? "0") ?? 0
            let fund = Double(latestAsset.fund ?? "0") ?? 0
            let insurance = Double(latestAsset.insurance ?? "0") ?? 0

            // 計算新的總資產
            let newTotalAssets = cash + usStock + totalMarketValue + bonds + taiwanStockFolded + twdToUsd + structured + fund + insurance
            latestAsset.totalAssets = String(format: "%.2f", newTotalAssets)

            // 保存更改
            try viewContext.save()
            PersistenceController.shared.save()

            // 顯示同步結果
            syncMessage = """
            同步成功！

            日期：\(dateString)
            定期定額：$\(String(format: "%.2f", oldValue)) → $\(String(format: "%.2f", totalMarketValue))
            定期定額成本：$\(String(format: "%.2f", totalCost))
            總資產：$\(String(format: "%.2f", newTotalAssets))
            """
            showingSyncResult = true

        } catch {
            syncMessage = "同步失敗\n\n\(error.localizedDescription)"
            showingSyncResult = true
        }
    }

    // MARK: - 格式化函數
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? "0.00")
    }

    private func formatReturnRate(_ value: Double) -> String {
        String(format: "%.2f%%", value)
    }

    // MARK: - 計算折合美金
    private func calculateConvertedToUSD(investment: RegularInvestment, amount: Double) -> Double {
        let currency = investment.currency ?? "TWD"

        // USD 不需要轉換
        if currency == "USD" {
            return amount
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
        return amount / rateValue
    }
}

// MARK: - 投資行視圖
struct RegularInvestmentRowView: View {
    @ObservedObject var investment: RegularInvestment
    let viewContext: NSManagedObjectContext

    @State private var isExpanded = false
    @State private var editedName: String
    @State private var editedTargetType: String
    @State private var editedCycleFrequency: String
    @State private var editedCycleDay: Int
    @State private var editedInvestmentAmount: String
    @State private var editedCost: String
    @State private var editedMarketValue: String
    @State private var editedComment: String
    @State private var showingDeleteConfirmation = false

    let targetTypes = ["台股", "美股", "基金"]
    let cycleOptions = ["每週", "每兩週", "每月", "每季", "每半年", "每年"]

    init(investment: RegularInvestment, viewContext: NSManagedObjectContext) {
        self.investment = investment
        self.viewContext = viewContext
        _editedName = State(initialValue: investment.name ?? "")
        _editedTargetType = State(initialValue: investment.targetType ?? "台股")

        // 解析週期字串，例如 "每月5日" -> frequency: "每月", day: 5
        let cycle = investment.cycle ?? "每月1日"
        var frequency = "每月"
        var day = 1
        for option in ["每週", "每兩週", "每月", "每季", "每半年", "每年"] {
            if cycle.hasPrefix(option) {
                frequency = option
                let dayStr = cycle.replacingOccurrences(of: option, with: "").replacingOccurrences(of: "日", with: "")
                if let parsedDay = Int(dayStr) {
                    day = parsedDay
                }
                break
            }
        }
        _editedCycleFrequency = State(initialValue: frequency)
        _editedCycleDay = State(initialValue: day)

        _editedInvestmentAmount = State(initialValue: investment.investmentAmount ?? "")
        _editedCost = State(initialValue: investment.cost ?? "")
        _editedMarketValue = State(initialValue: investment.marketValue ?? "")
        _editedComment = State(initialValue: investment.comment ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            // 主要資訊行
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(investment.name ?? "未命名")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)

                            // 標的類型標籤
                            Text(investment.targetType ?? "")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(getTypeColor(investment.targetType ?? ""))
                                .cornerRadius(4)
                        }

                        HStack(spacing: 8) {
                            Text("週期: \(investment.cycle ?? "-")")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("每期: $\(formatNumber(investment.investmentAmount))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(formatNumber(investment.marketValue))")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)

                        let returnRate = Double(investment.returnRate ?? "0") ?? 0
                        Text(formatReturnRate(returnRate))
                            .font(.caption)
                            .foregroundColor(returnRate >= 0 ? .green : .red)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(PlainButtonStyle())

            // 展開的詳細資訊
            if isExpanded {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.vertical, 8)

                    // 編輯欄位
                    VStack(spacing: 12) {
                        // 標的名稱
                        HStack {
                            Text("標的名稱")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("例如：0050", text: $editedName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: editedName) { newValue in
                                    investment.name = newValue
                                    saveChanges()
                                }
                        }

                        // 標的類型
                        HStack {
                            Text("標的類型")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            Picker("", selection: $editedTargetType) {
                                ForEach(targetTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: editedTargetType) { newValue in
                                investment.targetType = newValue
                                saveChanges()
                            }
                        }

                        // 週期
                        HStack {
                            Text("週期")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)

                            Spacer()

                            Picker("", selection: $editedCycleFrequency) {
                                ForEach(cycleOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: editedCycleFrequency) { _ in
                                updateCycle()
                            }

                            Picker("", selection: $editedCycleDay) {
                                ForEach(1...31, id: \.self) { day in
                                    Text("\(day)日").tag(day)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: editedCycleDay) { _ in
                                updateCycle()
                            }
                        }

                        // 每期投入金額
                        HStack {
                            Text("每期金額")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: $editedInvestmentAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: editedInvestmentAmount) { newValue in
                                    investment.investmentAmount = newValue
                                    saveChanges()
                                }
                        }

                        // 總成本
                        HStack {
                            Text("總成本")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: $editedCost)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: editedCost) { newValue in
                                    investment.cost = newValue
                                    recalculate()
                                }
                        }

                        // 市值
                        HStack {
                            Text("市值")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: $editedMarketValue)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: editedMarketValue) { newValue in
                                    investment.marketValue = newValue
                                    recalculate()
                                }
                        }

                        // 備註
                        HStack {
                            Text("備註")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("選填", text: $editedComment)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: editedComment) { newValue in
                                    investment.comment = newValue
                                    saveChanges()
                                }
                        }
                    }

                    // 刪除按鈕
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("刪除此標的")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, isExpanded ? 16 : 0)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                deleteInvestment()
            }
        } message: {
            Text("確定要刪除 \(investment.name ?? "此標的") 嗎？")
        }
    }

    private func getTypeColor(_ type: String) -> Color {
        switch type {
        case "台股":
            return .blue
        case "美股":
            return .green
        case "基金":
            return .orange
        default:
            return .gray
        }
    }

    private func updateCycle() {
        investment.cycle = "\(editedCycleFrequency)\(editedCycleDay)日"
        saveChanges()
    }

    private func recalculate() {
        let cost = Double(investment.cost ?? "0") ?? 0
        let marketValue = Double(investment.marketValue ?? "0") ?? 0

        // 計算損益
        let profitLoss = marketValue - cost
        investment.profitLoss = String(format: "%.2f", profitLoss)

        // 計算報酬率
        if cost > 0 {
            let returnRate = (profitLoss / cost) * 100
            investment.returnRate = String(format: "%.2f", returnRate)
        } else {
            investment.returnRate = "0"
        }

        saveChanges()
    }

    private func saveChanges() {
        do {
            try viewContext.save()
            PersistenceController.shared.save()
        } catch {
            print("保存失敗: \(error.localizedDescription)")
        }
    }

    private func deleteInvestment() {
        viewContext.delete(investment)
        saveChanges()
    }

    private func formatReturnRate(_ value: Double) -> String {
        String(format: "%.2f%%", value)
    }

    private func formatNumber(_ value: String?) -> String {
        guard let value = value, !value.isEmpty else { return "0" }
        if let number = Double(value) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: number)) ?? value
        }
        return value
    }
}

// MARK: - 新增定期定額視圖
struct AddRegularInvestmentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client?

    @State private var name = ""
    @State private var targetType = "台股"
    @State private var cycleFrequency = "每月"
    @State private var cycleDay = 1
    @State private var investmentAmount = ""
    @State private var cost = ""
    @State private var marketValue = ""
    @State private var comment = ""

    let targetTypes = ["台股", "美股", "基金"]
    let cycleOptions = ["每週", "每兩週", "每月", "每季", "每半年", "每年"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本資訊")) {
                    HStack {
                        Text("標的名稱")
                        TextField("例如：0050", text: $name)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker("標的類型", selection: $targetType) {
                        ForEach(targetTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }

                    HStack {
                        Text("週期")
                        Spacer()
                        Picker("", selection: $cycleFrequency) {
                            ForEach(cycleOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())

                        Picker("", selection: $cycleDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)日").tag(day)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }

                    HStack {
                        Text("每期投入金額")
                        TextField("0", text: $investmentAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("目前狀況")) {
                    HStack {
                        Text("總成本")
                        TextField("0", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("市值")
                        TextField("0", text: $marketValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("備註")) {
                    TextField("選填", text: $comment)
                }

                Section {
                    Button("新增標的") {
                        addInvestment()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("新增定期定額")
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

    private func addInvestment() {
        let newInvestment = RegularInvestment(context: viewContext)
        newInvestment.client = client
        newInvestment.name = name
        newInvestment.targetType = targetType
        newInvestment.cycle = "\(cycleFrequency)\(cycleDay)日"
        newInvestment.investmentAmount = investmentAmount
        newInvestment.cost = cost
        newInvestment.marketValue = marketValue
        newInvestment.comment = comment
        newInvestment.currency = targetType == "美股" ? "USD" : "TWD"
        newInvestment.createdDate = Date()

        // 計算損益和報酬率
        let costNum = Double(cost) ?? 0
        let marketValueNum = Double(marketValue) ?? 0
        let profitLoss = marketValueNum - costNum
        let returnRate = costNum > 0 ? (profitLoss / costNum) * 100 : 0

        newInvestment.profitLoss = String(format: "%.2f", profitLoss)
        newInvestment.returnRate = String(format: "%.2f", returnRate)

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            dismiss()
        } catch {
            print("新增失敗: \(error.localizedDescription)")
        }
    }
}
