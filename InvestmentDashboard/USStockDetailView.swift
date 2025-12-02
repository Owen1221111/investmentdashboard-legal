import SwiftUI
import CoreData

struct USStockDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isExpanded = false
    @State private var showingColumnReorder = false
    @State private var columnOrder: [String] = []
    @State private var isRefreshing = false  // 刷新状态
    @State private var showingRefreshAlert = false  // 刷新结果提示
    @State private var refreshMessage = ""  // 刷新结果消息
    @State private var sortField: String? = nil
    @State private var sortAscending: Bool = true

    let client: Client?

    // FetchRequest 取得當前客戶的美股資料
    @FetchRequest private var usStocks: FetchedResults<USStock>

    init(client: Client?) {
        self.client = client

        // 設定 FetchRequest 以取得該客戶的美股資料
        if let client = client {
            _usStocks = FetchRequest<USStock>(
                sortDescriptors: [NSSortDescriptor(keyPath: \USStock.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client),
                animation: .default
            )
        } else {
            _usStocks = FetchRequest<USStock>(
                sortDescriptors: [NSSortDescriptor(keyPath: \USStock.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }

    private let headers = ["日期", "股票名稱", "股數", "成本", "成本單價", "現價", "市值", "損益", "報酬率", "幣別", "評論"]

    var body: some View {
        VStack(spacing: 0) {
            // 標題區域（含縮放功能）
            tableHeader

            // 表格內容（可縮放）
            if isExpanded {
                usStockTable
            }
        }
        .background(
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                    : UIColor.white
            })
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .sheet(isPresented: $showingColumnReorder) {
            ColumnReorderView(
                headers: headers,
                initialOrder: columnOrder.isEmpty ? headers : columnOrder,
                onSave: { newOrder in
                    columnOrder = newOrder
                    // 儲存到 UserDefaults
                    UserDefaults.standard.set(newOrder, forKey: "USStock_ColumnOrder")
                }
            )
        }
        .onAppear {
            // 從 UserDefaults 讀取欄位排序
            if let savedOrder = UserDefaults.standard.array(forKey: "USStock_ColumnOrder") as? [String], !savedOrder.isEmpty {
                columnOrder = savedOrder
            } else if columnOrder.isEmpty {
                columnOrder = headers
            }
        }
        .alert("股價更新", isPresented: $showingRefreshAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(refreshMessage)
        }
    }

    // MARK: - 標題區域（含縮放功能）
    private var tableHeader: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                        Text("美股明細")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                    Text("⚠️ 成本不含手續費")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    // 縮放按鈕
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }

                    // 刷新股價按鈕（排序按鈕左邊）
                    Button(action: {
                        refreshAllStockPrices()
                    }) {
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                                .frame(width: 30, height: 30)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                                .padding(8)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .disabled(isRefreshing)

                    Button(action: {
                        showingColumnReorder = true
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        // TODO: 匯入功能
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        addNewRow()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if isExpanded {
                Divider()
            }
        }
    }

    // MARK: - 美股表格
    private var usStockTable: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                // 表頭
                HStack(spacing: 0) {
                    // 刪除按鈕欄位
                    Text("")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(width: 40, alignment: .center)

                    ForEach(currentColumnOrder, id: \.self) { header in
                        if isSortableField(header) {
                            // 可排序欄位
                            Button(action: {
                                handleSort(for: header)
                            }) {
                                HStack(spacing: 4) {
                                    Text(header)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                                    if sortField == header {
                                        Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 14)
                                .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // 不可排序欄位
                            Text(header)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 14)
                                .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                        }
                    }

                    // 詳細資料按鈕欄位
                    Text("詳細資料")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 14)
                        .frame(width: 90, alignment: .center)
                }
                .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

                // 分隔線
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)

                // 資料行容器
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(sortedStocks.enumerated()), id: \.offset) { index, stock in
                            HStack(spacing: 0) {
                                // 刪除按鈕（移到最左邊）
                                Button(action: {
                                    deleteStock(stock)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 8)
                                .frame(width: 40, alignment: .center)

                                ForEach(Array(currentColumnOrder.enumerated()), id: \.offset) { colIndex, header in
                                    if isAutoCalculatedField(header) {
                                        // 自動計算欄位顯示為唯讀（灰色背景）
                                        Text(bindingForStock(stock, header: header).wrappedValue)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(header == "報酬率" ? getReturnRateColor(stock) : Color(.secondaryLabel))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                            .background(Color(.tertiarySystemBackground))
                                    } else {
                                        TextField("", text: bindingForStock(stock, header: header))
                                            .font(.system(size: 15, weight: .medium))
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                            .background(Color.clear)
                                    }
                                }

                                // 詳細資料按鈕
                                Button(action: {
                                    // TODO: 顯示詳細資料
                                }) {
                                    Text("詳細")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray)
                                        .cornerRadius(4)
                                }
                                .frame(width: 90, alignment: .center)
                            }
                            .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.02))
                            .overlay(
                                VStack {
                                    Spacer()
                                    Divider()
                                        .opacity(0.3)
                                }
                            )
                        }

                        // 加總行
                        summaryRow
                    }
                }
                .frame(maxHeight: 400)
            }
        }
    }

    // MARK: - 加總行
    private var summaryRow: some View {
        HStack(spacing: 0) {
            // 刪除按鈕欄位（空白）
            Text("")
                .frame(width: 40, alignment: .center)

            ForEach(Array(currentColumnOrder.enumerated()), id: \.offset) { colIndex, header in
                Group {
                    if header == "股票名稱" {
                        Text("合計")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                    } else if header == "成本" {
                        VStack(spacing: 0) {
                            Text(formatNumberWithCommas(getTotalCost()))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                                .lineLimit(1)

                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 2)
                                .padding(.top, 2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                    } else if header == "市值" {
                        VStack(spacing: 0) {
                            Text(formatNumberWithCommas(getTotalMarketValue()))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                                .lineLimit(1)

                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 2)
                                .padding(.top, 2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                    } else if header == "損益" {
                        VStack(spacing: 0) {
                            Text(formatNumberWithCommas(getTotalProfitLoss()))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                                .lineLimit(1)

                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 2)
                                .padding(.top, 2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                    } else if header == "報酬率" {
                        VStack(spacing: 0) {
                            Text(String(format: "%.2f%%", getTotalReturnRate()))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(getTotalReturnRate() >= 0 ? .green : .red)
                                .lineLimit(1)

                            Rectangle()
                                .fill(getTotalReturnRate() >= 0 ? Color.green : Color.red)
                                .frame(height: 2)
                                .padding(.top, 2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                    } else {
                        // 其他欄位空白
                        Text("")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                    }
                }
            }

            // 詳細資料按鈕欄位（空白）
            Text("")
                .frame(width: 90, alignment: .center)
        }
        .background(Color.blue.opacity(0.08))
        .overlay(
            VStack {
                Divider()
                    .background(Color.blue.opacity(0.3))
                Spacer()
            }
        )
    }

    // MARK: - 計算屬性
    private var currentColumnOrder: [String] {
        return columnOrder.isEmpty ? headers : columnOrder
    }

    // 排序後的美股列表
    private var sortedStocks: [USStock] {
        guard let sortField = sortField else {
            return Array(usStocks)
        }

        return usStocks.sorted { stock1, stock2 in
            let value1 = getNumericValue(stock: stock1, header: sortField)
            let value2 = getNumericValue(stock: stock2, header: sortField)

            if sortAscending {
                return value1 < value2
            } else {
                return value1 > value2
            }
        }
    }

    // 判斷是否為可排序欄位
    private func isSortableField(_ header: String) -> Bool {
        return ["市值", "報酬率", "成本", "損益"].contains(header)
    }

    // 處理排序點擊
    private func handleSort(for header: String) {
        if sortField == header {
            // 同一個欄位，切換升降序
            sortAscending.toggle()
        } else {
            // 不同欄位，重設為升序
            sortField = header
            sortAscending = true
        }
    }

    // 獲取數字值（用於排序）
    private func getNumericValue(stock: USStock, header: String) -> Double {
        let stringValue: String
        switch header {
        case "市值":
            stringValue = stock.marketValue ?? ""
        case "報酬率":
            stringValue = stock.returnRate ?? ""
        case "成本":
            stringValue = stock.cost ?? ""
        case "損益":
            stringValue = stock.profitLoss ?? ""
        default:
            return 0
        }

        // 移除 % 符號和逗號
        let cleanValue = removeCommas(stringValue)
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Double(cleanValue) ?? 0
    }

    // MARK: - 欄位寬度
    private func getColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "日期": return 120
        case "股票名稱": return 120
        case "股數": return 100
        case "成本": return 120
        case "成本單價": return 120
        case "現價": return 120
        case "市值": return 120
        case "損益": return 120
        case "報酬率": return 100
        case "幣別": return 80
        case "評論": return 200
        default: return 100
        }
    }

    // MARK: - 資料綁定
    private func bindingForStock(_ stock: USStock, header: String) -> Binding<String> {
        Binding<String>(
            get: {
                let rawValue: String
                switch header {
                case "日期": rawValue = stock.market ?? ""
                case "股票名稱": rawValue = stock.name ?? ""
                case "股數": rawValue = stock.shares ?? ""
                case "成本": rawValue = stock.cost ?? ""
                case "成本單價": rawValue = stock.costPerShare ?? ""
                case "現價": rawValue = stock.currentPrice ?? ""
                case "市值": rawValue = stock.marketValue ?? ""
                case "損益": rawValue = stock.profitLoss ?? ""
                case "報酬率": rawValue = stock.returnRate ?? ""
                case "幣別": rawValue = stock.currency ?? ""
                case "評論": rawValue = stock.comment ?? ""
                default: rawValue = ""
                }

                // 如果是數字欄位，加上千分位
                return isNumberField(header) ? formatNumberWithCommas(rawValue) : rawValue
            },
            set: { newValue in
                // 移除千分位後儲存
                let cleanValue = isNumberField(header) ? removeCommas(newValue) : newValue

                switch header {
                case "日期": stock.market = cleanValue
                case "股票名稱": stock.name = cleanValue
                case "股數":
                    stock.shares = cleanValue
                    recalculateStock(stock: stock)
                case "成本":
                    // 成本為自動計算，不允許手動修改
                    break
                case "成本單價":
                    stock.costPerShare = cleanValue
                    recalculateStock(stock: stock)
                case "現價":
                    stock.currentPrice = cleanValue
                    recalculateStock(stock: stock)
                case "市值":
                    // 市值為自動計算，不允許手動修改
                    break
                case "損益":
                    // 損益為自動計算，不允許手動修改
                    break
                case "報酬率":
                    // 報酬率為自動計算，不允許手動修改
                    break
                case "幣別": stock.currency = cleanValue
                case "評論": stock.comment = cleanValue
                default: break
                }

                // 自動儲存變更
                do {
                    try viewContext.save()
                    PersistenceController.shared.save()
                } catch {
                    print("❌ 儲存失敗: \(error)")
                }
            }
        )
    }

    // MARK: - 格式化輔助函數
    private func formatNumberWithCommas(_ value: String?) -> String {
        guard let value = value, !value.isEmpty else { return "" }

        // 移除現有的逗號
        let cleanValue = value.replacingOccurrences(of: ",", with: "")

        // 如果可以轉換成數字，加上千分位
        if let number = Double(cleanValue) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: number)) ?? cleanValue
        }

        return cleanValue
    }

    private func removeCommas(_ value: String) -> String {
        return value.replacingOccurrences(of: ",", with: "")
    }

    // 計算成本總和
    private func getTotalCost() -> Double {
        return usStocks.reduce(0.0) { sum, stock in
            let amount = Double(removeCommas(stock.cost ?? "")) ?? 0
            return sum + amount
        }
    }

    // 計算市值總和
    private func getTotalMarketValue() -> Double {
        return usStocks.reduce(0.0) { sum, stock in
            let amount = Double(removeCommas(stock.marketValue ?? "")) ?? 0
            return sum + amount
        }
    }

    // 計算損益總和
    private func getTotalProfitLoss() -> Double {
        return usStocks.reduce(0.0) { sum, stock in
            let amount = Double(removeCommas(stock.profitLoss ?? "")) ?? 0
            return sum + amount
        }
    }

    // 計算總報酬率
    private func getTotalReturnRate() -> Double {
        let totalCost = getTotalCost()
        guard totalCost > 0 else { return 0 }

        let totalProfitLoss = getTotalProfitLoss()
        return (totalProfitLoss / totalCost) * 100
    }

    // 格式化數字（加千分位）
    private func formatNumberWithCommas(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    // 判斷是否為數字欄位
    private func isNumberField(_ header: String) -> Bool {
        let textFields = ["日期", "股票名稱", "幣別", "評論"]
        return !textFields.contains(header)
    }

    // 判斷是否為自動計算欄位
    private func isAutoCalculatedField(_ header: String) -> Bool {
        let autoFields = ["成本", "市值", "損益", "報酬率"]
        return autoFields.contains(header)
    }

    // 取得報酬率顏色
    private func getReturnRateColor(_ stock: USStock) -> Color {
        let returnRateStr = stock.returnRate ?? "0%"
        let cleanValue = returnRateStr.replacingOccurrences(of: "%", with: "")
        let returnRate = Double(cleanValue) ?? 0
        return returnRate >= 0 ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red
    }

    // MARK: - 自動計算
    private func recalculateStock(stock: USStock) {
        // 移除千分位並轉換為數字
        let shares = Double(removeCommas(stock.shares ?? "")) ?? 0
        let costPerShare = Double(removeCommas(stock.costPerShare ?? "")) ?? 0
        let currentPrice = Double(removeCommas(stock.currentPrice ?? "")) ?? 0

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

    // MARK: - 資料操作
    private func addNewRow() {
        guard let client = client else {
            print("❌ 無法新增美股：沒有選中的客戶")
            return
        }

        withAnimation {
            let newStock = USStock(context: viewContext)
            newStock.client = client
            newStock.market = ""
            newStock.name = ""
            newStock.shares = ""
            newStock.cost = ""
            newStock.costPerShare = ""
            newStock.currentPrice = ""
            newStock.marketValue = ""
            newStock.profitLoss = ""
            newStock.returnRate = ""
            newStock.currency = ""
            newStock.comment = ""
            newStock.createdDate = Date()

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("✅ 新增空白美股並同步到 iCloud")
            } catch {
                print("❌ 新增失敗: \(error)")
            }
        }
    }

    private func deleteStock(_ stock: USStock) {
        withAnimation {
            viewContext.delete(stock)
            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("✅ 刪除美股並同步到 iCloud")
            } catch {
                print("❌ 刪除失敗: \(error)")
            }
        }
    }

    // MARK: - 刷新股價功能
    private func refreshAllStockPrices() {
        // 如果沒有股票，提示用戶
        guard !usStocks.isEmpty else {
            refreshMessage = "目前沒有股票數據"
            showingRefreshAlert = true
            return
        }

        // 設置刷新狀態
        isRefreshing = true

        // 使用異步任務獲取股價
        Task {
            // 收集所有股票代碼（從 name 欄位）
            let symbols = usStocks.compactMap { stock -> String? in
                let symbol = stock.name?.trimmingCharacters(in: .whitespaces).uppercased()
                return (symbol?.isEmpty == false) ? symbol : nil
            }

            guard !symbols.isEmpty else {
                await MainActor.run {
                    isRefreshing = false
                    refreshMessage = "沒有有效的股票代碼"
                    showingRefreshAlert = true
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
                        print("✅ 成功更新 \(successCount) 個股票的價格")
                    } catch {
                        print("❌ 保存失敗: \(error)")
                    }
                }

                // 顯示結果
                isRefreshing = false
                if successCount > 0 {
                    refreshMessage = "成功更新 \(successCount) 個股票\(failCount > 0 ? "，\(failCount) 個失敗" : "")"
                } else {
                    refreshMessage = "更新失敗，請檢查股票代碼是否正確"
                }
                showingRefreshAlert = true
            }
        }
    }
}

#Preview {
    USStockDetailView(client: nil)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .padding()
}
