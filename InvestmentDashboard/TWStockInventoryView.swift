import SwiftUI
import CoreData

struct TWStockInventoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client?

    // FetchRequest 取得當前客戶的台股資料
    @FetchRequest private var twStocks: FetchedResults<TWStock>

    @State private var isRefreshing = false
    @State private var showingRefreshConfirmation = false
    @State private var showingRefreshResult = false
    @State private var refreshMessage = ""
    @State private var editingStock: TWStock?
    @State private var showingAddStock = false
    @State private var showingSyncConfirmation = false
    @State private var showingSyncResult = false
    @State private var syncMessage = ""
    @State private var showingLoanSyncSelection = false
    @State private var showingLoanSyncResult = false
    @State private var loanSyncMessage = ""

    init(client: Client?) {
        self.client = client

        // 設定 FetchRequest 以取得該客戶的台股資料
        if let client = client {
            _twStocks = FetchRequest<TWStock>(
                sortDescriptors: [NSSortDescriptor(keyPath: \TWStock.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client),
                animation: .default
            )
        } else {
            _twStocks = FetchRequest<TWStock>(
                sortDescriptors: [NSSortDescriptor(keyPath: \TWStock.createdDate, ascending: false)],
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
                if twStocks.isEmpty {
                    emptyStateView
                } else {
                    stockListView
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
                            .disabled(twStocks.isEmpty)

                            // 貸款同步
                            Button(action: {
                                showingLoanSyncSelection = true
                            }) {
                                Label("同步至貸款", systemImage: "building.columns")
                            }
                            .disabled(twStocks.isEmpty)

                            Divider()

                            // 更新股價
                            Button(action: {
                                showingRefreshConfirmation = true
                            }) {
                                Label("更新股價", systemImage: "arrow.clockwise")
                            }
                            .disabled(twStocks.isEmpty || isRefreshing)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }

                        // 新增持股按鈕
                        Button(action: {
                            showingAddStock = true
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
                Text("將台股持倉數據同步到最新的月度資產記錄？")
            }
            .alert("更新確認", isPresented: $showingRefreshConfirmation) {
                Button("取消", role: .cancel) { }
                Button("確認") {
                    refreshStockPrices()
                }
            } message: {
                Text("將從網路獲取最新股價並更新持倉數據，是否繼續？")
            }
            .alert("同步結果", isPresented: $showingSyncResult) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(syncMessage)
            }
            .alert("更新結果", isPresented: $showingRefreshResult) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(refreshMessage)
            }
            .sheet(isPresented: $showingAddStock) {
                AddTWStockView(client: client)
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert("貸款同步結果", isPresented: $showingLoanSyncResult) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(loanSyncMessage)
            }
            .sheet(isPresented: $showingLoanSyncSelection) {
                if let client = client {
                    TWStockLoanSyncSelectionView(
                        client: client,
                        stocks: Array(twStocks),
                        onSync: { selectedStocks, loan in
                            syncToLoanMonthlyData(selectedStocks: selectedStocks, loan: loan)
                        }
                    )
                    .environment(\.managedObjectContext, viewContext)
                }
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

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("尚無庫存明細")
                .font(.headline)
                .foregroundColor(.secondary)

            // 如果有月度資產數據，顯示提示
            if getTotalMarketValue() > 0 || getTotalCost() > 0 {
                VStack(spacing: 8) {
                    Text("目前顯示月度資產明細數據")
                        .font(.subheadline)
                        .foregroundColor(.blue)

                    Text("建立庫存明細以記錄個別持股資訊")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            } else {
                Text("點擊右上角 ⊕ 新增持股")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Button(action: {
                showingAddStock = true
            }) {
                Text("新增持股")
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

    // MARK: - 持倉列表
    private var stockListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(twStocks) { stock in
                    StockRowView(stock: stock, viewContext: viewContext)
                }
            }
            .padding()
        }
    }

    // MARK: - 計算函數
    private func getTotalMarketValue() -> Double {
        // 如果有庫存明細，從庫存明細計算
        if !twStocks.isEmpty {
            return twStocks.reduce(0) { total, stock in
                total + (Double(stock.marketValue ?? "0") ?? 0)
            }
        }

        // 如果沒有庫存明細，從月度資產明細讀取
        return getMonthlyAssetValue(keyPath: \.taiwanStock)
    }

    private func getTotalCost() -> Double {
        // 如果有庫存明細，從庫存明細計算
        if !twStocks.isEmpty {
            return twStocks.reduce(0) { total, stock in
                total + (Double(stock.cost ?? "0") ?? 0)
            }
        }

        // 如果沒有庫存明細，從月度資產明細讀取
        return getMonthlyAssetValue(keyPath: \.taiwanStockCost)
    }

    private func getTotalProfitLoss() -> Double {
        getTotalMarketValue() - getTotalCost()
    }

    private func getTotalReturnRate() -> Double {
        let cost = getTotalCost()
        guard cost > 0 else { return 0 }
        return (getTotalProfitLoss() / cost) * 100
    }

    // 從月度資產明細讀取數據
    private func getMonthlyAssetValue(keyPath: KeyPath<MonthlyAsset, String?>) -> Double {
        guard let client = client else { return 0 }

        let fetchRequest: NSFetchRequest<MonthlyAsset> = MonthlyAsset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)
            if let latestAsset = results.first,
               let valueString = latestAsset[keyPath: keyPath] {
                return Double(valueString) ?? 0
            }
        } catch {
            print("❌ 讀取月度資產明細失敗: \(error)")
        }

        return 0
    }

    // 判斷是否使用月度資產數據
    private var isUsingMonthlyAssetData: Bool {
        return twStocks.isEmpty
    }

    // MARK: - 同步到月度資產
    private func syncToMonthlyAsset() {
        guard let client = client else {
            syncMessage = "❌ 無法找到客戶資料"
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
                syncMessage = "❌ 找不到月度資產記錄\n\n請先新增月度資產記錄"
                showingSyncResult = true
                return
            }

            // 保存舊值用於顯示
            let oldValue = Double(latestAsset.taiwanStock ?? "0") ?? 0
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM"
            let dateString = latestAsset.date ?? ""

            // 更新台股市值和成本
            latestAsset.taiwanStock = String(format: "%.2f", totalMarketValue)
            latestAsset.taiwanStockCost = String(format: "%.2f", totalCost)

            // 重新計算總資產（美金計價）
            // 總資產 = 美金 + 美股 + 定期定額 + 債券 + 台股折合 + 台幣折合美金 + 結構型 + 基金 + 保險
            let cash = Double(latestAsset.cash ?? "0") ?? 0
            let usStock = Double(latestAsset.usStock ?? "0") ?? 0
            let regularInvestment = Double(latestAsset.regularInvestment ?? "0") ?? 0
            let bonds = Double(latestAsset.bonds ?? "0") ?? 0
            let structured = Double(latestAsset.structured ?? "0") ?? 0
            let taiwanStockFolded = Double(latestAsset.taiwanStockFolded ?? "0") ?? 0
            let twdToUsd = Double(latestAsset.twdToUsd ?? "0") ?? 0
            let fund = Double(latestAsset.fund ?? "0") ?? 0
            let insurance = Double(latestAsset.insurance ?? "0") ?? 0

            // 重新計算台股折合（使用新的台股市值）
            let exchangeRate = Double(latestAsset.exchangeRate ?? "32") ?? 32
            let newTaiwanStockFolded = totalMarketValue / exchangeRate
            latestAsset.taiwanStockFolded = String(format: "%.2f", newTaiwanStockFolded)

            // 計算新的總資產
            let newTotalAssets = cash + usStock + regularInvestment + bonds + newTaiwanStockFolded + twdToUsd + structured + fund + insurance
            latestAsset.totalAssets = String(format: "%.2f", newTotalAssets)

            // 保存更改
            try viewContext.save()
            PersistenceController.shared.save()

            // 顯示同步結果
            syncMessage = """
            ✅ 同步成功！

            日期：\(dateString)
            台股市值：NT$\(String(format: "%.2f", oldValue)) → NT$\(String(format: "%.2f", totalMarketValue))
            台股成本：NT$\(String(format: "%.2f", totalCost))
            台股折合：$\(String(format: "%.2f", newTaiwanStockFolded))
            總資產：$\(String(format: "%.2f", newTotalAssets))
            """
            showingSyncResult = true

        } catch {
            syncMessage = "❌ 同步失敗\n\n\(error.localizedDescription)"
            showingSyncResult = true
        }
    }

    // MARK: - 貸款同步功能
    private func syncToLoanMonthlyData(selectedStocks: [TWStock], loan: Loan) {
        guard let client = client else {
            loanSyncMessage = "無法同步：沒有選中的客戶"
            showingLoanSyncResult = true
            return
        }

        // 計算選中股票的總市值和總成本(台幣)
        var totalMarketValue: Double = 0
        var totalCost: Double = 0

        for stock in selectedStocks {
            totalMarketValue += Double(stock.marketValue ?? "0") ?? 0
            totalCost += Double(stock.cost ?? "0") ?? 0
        }

        // 獲取該客戶最新的貸款月度數據記錄
        let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)

            let loanMonthlyData: LoanMonthlyData
            let isNewRecord: Bool

            if let latestData = results.first {
                loanMonthlyData = latestData
                isNewRecord = false
            } else {
                // 沒有記錄,創建新的
                loanMonthlyData = LoanMonthlyData(context: viewContext)
                loanMonthlyData.client = client
                loanMonthlyData.createdDate = Date()

                // 設置日期為今天
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                loanMonthlyData.date = dateFormatter.string(from: Date())

                isNewRecord = true
            }

            // 格式化日期以顯示給用戶
            let dateString = loanMonthlyData.date ?? "未知日期"

            // 保存舊值用於顯示
            let oldTaiwanStock = Double(loanMonthlyData.taiwanStock ?? "0") ?? 0
            let oldTaiwanStockCost = Double(loanMonthlyData.taiwanStockCost ?? "0") ?? 0

            // 更新台股市值和成本(台幣)
            loanMonthlyData.taiwanStock = String(format: "%.2f", totalMarketValue)
            loanMonthlyData.taiwanStockCost = String(format: "%.2f", totalCost)

            // 獲取匯率(預設32)
            let exchangeRate = Double(loanMonthlyData.exchangeRate ?? "32") ?? 32

            // 計算美股加債券折合台幣 = (美股 + 債券) * 匯率
            let usStock = Double(loanMonthlyData.usStock ?? "0") ?? 0
            let bonds = Double(loanMonthlyData.bonds ?? "0") ?? 0
            let usStockBondsInTwd = (usStock + bonds) * exchangeRate
            loanMonthlyData.usStockBondsInTwd = String(format: "%.2f", usStockBondsInTwd)

            // 計算投資總額(台幣) = 台股 + 美股加債券折合台幣
            let totalInvestment = totalMarketValue + usStockBondsInTwd
            loanMonthlyData.totalInvestment = String(format: "%.2f", totalInvestment)

            // 保存更改
            try viewContext.save()
            PersistenceController.shared.save()

            // 顯示同步結果
            loanSyncMessage = """
            ✅ 同步成功！

            同步至：貸款/投資月度管理
            日期：\(dateString)

            已選擇 \(selectedStocks.count) 個標的
            台股市值：NT$\(String(format: "%.2f", oldTaiwanStock)) → NT$\(String(format: "%.2f", totalMarketValue))
            台股成本：NT$\(String(format: "%.2f", oldTaiwanStockCost)) → NT$\(String(format: "%.2f", totalCost))

            美股加債券折合台幣：NT$\(String(format: "%.2f", usStockBondsInTwd))
            投資總額(台幣)：NT$\(String(format: "%.2f", totalInvestment))
            """
            showingLoanSyncResult = true

            print("✅ 已同步台股數據到貸款月度數據")
            print("   日期：\(dateString)")
            print("   市值：\(totalMarketValue)")
            print("   成本：\(totalCost)")
            print("   投資總額(台幣)：\(totalInvestment)")

        } catch {
            loanSyncMessage = "同步失敗：\(error.localizedDescription)"
            showingLoanSyncResult = true
            print("❌ 同步失敗: \(error)")
        }
    }

    // MARK: - 更新股價
    private func refreshStockPrices() {
        // 如果沒有股票，提示用戶
        guard !twStocks.isEmpty else {
            refreshMessage = "目前沒有持股數據"
            showingRefreshResult = true
            return
        }

        isRefreshing = true

        Task {
            // 收集所有股票代碼（從 name 欄位），並添加 .TW 後綴
            let symbols = twStocks.compactMap { stock -> String? in
                guard let symbol = stock.name?.trimmingCharacters(in: .whitespaces), !symbol.isEmpty else {
                    return nil
                }
                // 台股代號需要加上 .TW 或 .TWO 後綴才能在 Yahoo Finance 查詢
                // 優先使用 .TW（上市），如果失敗可能是上櫃股票
                return symbol.contains(".") ? symbol : "\(symbol).TW"
            }

            guard !symbols.isEmpty else {
                await MainActor.run {
                    isRefreshing = false
                    refreshMessage = "沒有有效的股票代碼"
                    showingRefreshResult = true
                }
                return
            }

            // 批量獲取股價和股票名稱
            let stockInfos = await StockPriceService.shared.fetchMultipleStockInfos(symbols: symbols)

            // 在主線程更新 UI
            await MainActor.run {
                var successCount = 0
                var failCount = 0
                var latestMarketTime: Date? = nil

                // 更新每個股票的現價和名稱
                for stock in twStocks {
                    guard let baseSymbol = stock.name?.trimmingCharacters(in: .whitespaces),
                          !baseSymbol.isEmpty else {
                        continue
                    }

                    // 嘗試不同的後綴（.TW 上市、.TWO 上櫃）
                    let symbolTW = baseSymbol.contains(".") ? baseSymbol : "\(baseSymbol).TW"
                    let symbolTWO = baseSymbol.contains(".") ? baseSymbol : "\(baseSymbol).TWO"

                    var stockInfo: (price: String, name: String, marketTime: Date?)? = nil

                    // 優先嘗試 .TW
                    if let info = stockInfos[symbolTW] {
                        stockInfo = info
                    }
                    // 如果 .TW 失敗，嘗試 .TWO
                    else if let info = stockInfos[symbolTWO] {
                        stockInfo = info
                    }

                    if let info = stockInfo {
                        // 更新現價
                        stock.currentPrice = info.price
                        // 更新股票名稱
                        stock.stockName = info.name
                        // 重新計算市值、損益、報酬率
                        recalculateStock(stock: stock)
                        successCount += 1

                        // 記錄最新的市場時間
                        if let time = info.marketTime {
                            if latestMarketTime == nil || time > latestMarketTime! {
                                latestMarketTime = time
                            }
                        }
                    } else {
                        failCount += 1
                    }
                }

                // 保存到 Core Data
                if successCount > 0 {
                    do {
                        try viewContext.save()
                        PersistenceController.shared.save()
                        print("✅ 成功更新 \(successCount) 個台股的價格")

                        // 記錄股價更新時間（用於小卡顯示邏輯）
                        if let client = client {
                            let key = "twStockPriceUpdateTime_\(client.objectID.uriRepresentation().absoluteString)"
                            UserDefaults.standard.set(Date(), forKey: key)
                            print("✅ 已記錄台股價更新時間")

                            // 更新即時快照的台股數字
                            updateLiveSnapshotTWStock()

                            // 發送通知，通知 CustomerDetailView 刷新
                            NotificationCenter.default.post(
                                name: NSNotification.Name("TWStockPriceUpdated"),
                                object: nil,
                                userInfo: ["clientID": client.objectID.uriRepresentation().absoluteString]
                            )
                        }
                    } catch {
                        print("❌ 保存失敗: \(error)")
                    }
                }

                // 顯示結果
                isRefreshing = false
                if successCount > 0 {
                    var message = "成功更新 \(successCount) 個股票\(failCount > 0 ? "，\(failCount) 個失敗" : "")"

                    // 顯示股價日期時間
                    if let marketTime = latestMarketTime {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy/MM/dd HH:mm"
                        formatter.timeZone = TimeZone(identifier: "Asia/Taipei")
                        let timeString = formatter.string(from: marketTime)
                        message += "\n\n股價時間：\(timeString)"
                    }

                    refreshMessage = message
                } else {
                    refreshMessage = "更新失敗，請檢查股票代碼是否正確\n\n提示：台股代碼請輸入4位數字（如：2330）"
                }
                showingRefreshResult = true
            }
        }
    }

    // 重新計算股票數據
    private func recalculateStock(stock: TWStock) {
        let shares = Double(stock.shares ?? "0") ?? 0
        let costPerShare = Double(stock.costPerShare ?? "0") ?? 0
        let currentPrice = Double(stock.currentPrice ?? "0") ?? 0

        // 計算成本
        let cost = shares * costPerShare
        stock.cost = String(format: "%.2f", cost)

        // 計算市值
        let marketValue = shares * currentPrice
        stock.marketValue = String(format: "%.2f", marketValue)

        // 計算損益
        let profitLoss = marketValue - cost
        stock.profitLoss = String(format: "%.2f", profitLoss)

        // 計算報酬率
        if cost > 0 {
            let returnRate = (profitLoss / cost) * 100
            stock.returnRate = String(format: "%.2f", returnRate)
        } else {
            stock.returnRate = "0"
        }
    }

    // MARK: - 更新即時快照的台股數字
    private func updateLiveSnapshotTWStock() {
        guard let client = client else { return }

        // 查找即時快照
        let fetchRequest: NSFetchRequest<MonthlyAsset> = MonthlyAsset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@ AND isLiveSnapshot == YES", client)
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)

            if let liveSnapshot = results.first {
                // 計算台股總市值
                let totalMarketValue = getTotalMarketValue()
                let totalCost = getTotalCost()

                // 更新即時快照的台股欄位
                liveSnapshot.taiwanStock = String(format: "%.2f", totalMarketValue)
                liveSnapshot.taiwanStockCost = String(format: "%.2f", totalCost)
                liveSnapshot.createdDate = Date()

                // 重新計算台股折合（台股總市值 / 匯率）
                let exchangeRate = Double(liveSnapshot.exchangeRate ?? "32") ?? 32
                if exchangeRate != 0 {
                    let taiwanStockFolded = totalMarketValue / exchangeRate
                    liveSnapshot.taiwanStockFolded = String(format: "%.2f", taiwanStockFolded)
                }

                // 重新計算總資產
                let twd = Double(liveSnapshot.twdCash ?? "0") ?? 0
                let usd = Double(liveSnapshot.cash ?? "0") ?? 0
                let usStock = Double(liveSnapshot.usStock ?? "0") ?? 0
                let regularInvestment = Double(liveSnapshot.regularInvestment ?? "0") ?? 0
                let bonds = Double(liveSnapshot.bonds ?? "0") ?? 0
                let taiwanStockFolded = Double(liveSnapshot.taiwanStockFolded ?? "0") ?? 0
                let structured = Double(liveSnapshot.structured ?? "0") ?? 0
                let fund = Double(liveSnapshot.fund ?? "0") ?? 0
                let insurance = Double(liveSnapshot.insurance ?? "0") ?? 0

                let totalAssets = twd + usd + usStock + regularInvestment + bonds + taiwanStockFolded + structured + fund + insurance
                liveSnapshot.totalAssets = String(format: "%.2f", totalAssets)

                // 儲存
                try viewContext.save()
                PersistenceController.shared.save()

                print("✅ 已更新即時快照台股數字: NT$\(String(format: "%.2f", totalMarketValue))")
            }
        } catch {
            print("❌ 更新即時快照失敗: \(error)")
        }
    }

    // MARK: - 格式化函數
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "NT$" + (formatter.string(from: NSNumber(value: value)) ?? "0.00")
    }

    private func formatReturnRate(_ value: Double) -> String {
        String(format: "%.2f%%", value)
    }
}

// MARK: - 持股行視圖
struct StockRowView: View {
    @ObservedObject var stock: TWStock
    let viewContext: NSManagedObjectContext

    @State private var isExpanded = false
    @State private var editedName: String
    @State private var editedShares: String
    @State private var editedCostPerShare: String
    @State private var editedCurrentPrice: String
    @State private var editedComment: String
    @State private var showingDeleteConfirmation = false

    init(stock: TWStock, viewContext: NSManagedObjectContext) {
        self.stock = stock
        self.viewContext = viewContext
        _editedName = State(initialValue: stock.name ?? "")
        _editedShares = State(initialValue: stock.shares ?? "")
        _editedCostPerShare = State(initialValue: stock.costPerShare ?? "")
        _editedCurrentPrice = State(initialValue: stock.currentPrice ?? "")
        _editedComment = State(initialValue: stock.comment ?? "")
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
                            Text(stock.stockName?.isEmpty == false ? stock.stockName! : (stock.name ?? "未知"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)

                            if let currency = stock.currency, !currency.isEmpty {
                                Text(currency)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }

                        HStack(spacing: 8) {
                            Text("股數: \(formatNumber(stock.shares))")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("成本: NT$\(formatNumber(stock.cost))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("NT$\(formatNumber(stock.marketValue))")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)

                        let returnRate = Double(stock.returnRate ?? "0") ?? 0
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
                        // 股票代碼
                        HStack {
                            Text("股票代碼")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("例如：2330", text: $editedName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: editedName) { newValue in
                                    stock.name = newValue
                                    saveChanges()
                                }
                        }

                        // 股數
                        HStack {
                            Text("股數")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: $editedShares)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: editedShares) { newValue in
                                    stock.shares = newValue
                                    recalculate()
                                }
                        }

                        // 成本單價
                        HStack {
                            Text("成本單價")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: $editedCostPerShare)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: editedCostPerShare) { newValue in
                                    stock.costPerShare = newValue
                                    recalculate()
                                }
                        }

                        // 現價（唯讀）
                        HStack {
                            Text("現價")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: $editedCurrentPrice)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(true)
                                .background(Color(.systemGray6))
                        }

                        // 備註
                        HStack {
                            Text("備註")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("選填", text: $editedComment)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: editedComment) { newValue in
                                    stock.comment = newValue
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
                            Text("刪除此持股")
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
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                deleteStock()
            }
        } message: {
            Text("確定要刪除 \(stock.name ?? "此持股") 嗎？")
        }
    }

    private func recalculate() {
        let shares = Double(stock.shares ?? "0") ?? 0
        let costPerShare = Double(stock.costPerShare ?? "0") ?? 0
        let currentPrice = Double(stock.currentPrice ?? "0") ?? 0

        // 計算成本
        let cost = shares * costPerShare
        stock.cost = String(format: "%.2f", cost)

        // 計算市值
        let marketValue = shares * currentPrice
        stock.marketValue = String(format: "%.2f", marketValue)

        // 計算損益
        let profitLoss = marketValue - cost
        stock.profitLoss = String(format: "%.2f", profitLoss)

        // 計算報酬率
        if cost > 0 {
            let returnRate = (profitLoss / cost) * 100
            stock.returnRate = String(format: "%.2f", returnRate)
        } else {
            stock.returnRate = "0"
        }

        saveChanges()
    }

    private func saveChanges() {
        do {
            try viewContext.save()
            PersistenceController.shared.save()
        } catch {
            print("❌ 保存失敗: \(error.localizedDescription)")
        }
    }

    private func deleteStock() {
        viewContext.delete(stock)
        saveChanges()
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "NT$" + (formatter.string(from: NSNumber(value: value)) ?? "0.00")
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

// MARK: - 新增台股視圖
struct AddTWStockView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client?

    @State private var name = ""
    @State private var shares = ""
    @State private var costPerShare = ""
    @State private var currentPrice = ""
    @State private var comment = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本資訊")) {
                    HStack {
                        Text("股票代碼")
                        TextField("例如：2330", text: $name)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("股數")
                        TextField("0", text: $shares)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("成本單價")
                        TextField("0", text: $costPerShare)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("現價")
                        TextField("0", text: $currentPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("備註")) {
                    TextField("選填", text: $comment)
                }

                Section {
                    Button("新增持股") {
                        addStock()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("新增台股")
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

    private func addStock() {
        let newStock = TWStock(context: viewContext)
        newStock.client = client
        newStock.name = name
        newStock.shares = shares
        newStock.costPerShare = costPerShare
        newStock.currentPrice = currentPrice
        newStock.comment = comment
        newStock.currency = "TWD"
        newStock.createdDate = Date()

        // 計算成本、市值、損益、報酬率
        let sharesValue = Double(shares) ?? 0
        let costPerShareValue = Double(costPerShare) ?? 0
        let currentPriceValue = Double(currentPrice) ?? 0

        let cost = sharesValue * costPerShareValue
        let marketValue = sharesValue * currentPriceValue
        let profitLoss = marketValue - cost
        let returnRate = cost > 0 ? (profitLoss / cost) * 100 : 0

        newStock.cost = String(format: "%.2f", cost)
        newStock.marketValue = String(format: "%.2f", marketValue)
        newStock.profitLoss = String(format: "%.2f", profitLoss)
        newStock.returnRate = String(format: "%.2f", returnRate)

        // 自動獲取股票名稱
        Task {
            await fetchStockName(for: newStock)
        }

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            dismiss()
        } catch {
            print("❌ 新增失敗: \(error.localizedDescription)")
        }
    }

    // 自動獲取股票名稱
    private func fetchStockName(for stock: TWStock) async {
        guard let baseSymbol = stock.name?.trimmingCharacters(in: .whitespaces),
              !baseSymbol.isEmpty else {
            return
        }

        // 嘗試 .TW 後綴（上市股票）
        let symbolTW = baseSymbol.contains(".") ? baseSymbol : "\(baseSymbol).TW"

        do {
            let info = try await StockPriceService.shared.fetchStockInfo(symbol: symbolTW)

            await MainActor.run {
                stock.stockName = info.name

                // 保存更新
                do {
                    try viewContext.save()
                    PersistenceController.shared.save()
                    print("✅ 成功獲取股票名稱: \(info.name)")
                } catch {
                    print("❌ 保存股票名稱失敗: \(error)")
                }
            }
        } catch {
            // 如果 .TW 失敗，嘗試 .TWO（上櫃股票）
            let symbolTWO = baseSymbol.contains(".") ? baseSymbol : "\(baseSymbol).TWO"

            do {
                let info = try await StockPriceService.shared.fetchStockInfo(symbol: symbolTWO)

                await MainActor.run {
                    stock.stockName = info.name

                    // 保存更新
                    do {
                        try viewContext.save()
                        PersistenceController.shared.save()
                        print("✅ 成功獲取股票名稱: \(info.name)")
                    } catch {
                        print("❌ 保存股票名稱失敗: \(error)")
                    }
                }
            } catch {
                print("❌ 獲取股票名稱失敗: \(error.localizedDescription)")
            }
        }
    }
}
