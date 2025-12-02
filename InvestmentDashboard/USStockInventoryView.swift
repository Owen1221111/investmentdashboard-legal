import SwiftUI
import CoreData

struct USStockInventoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client?

    // FetchRequest 取得當前客戶的美股資料
    @FetchRequest private var usStocks: FetchedResults<USStock>

    @State private var isRefreshing = false
    @State private var showingRefreshConfirmation = false
    @State private var showingRefreshResult = false
    @State private var refreshMessage = ""
    @State private var editingStock: USStock?
    @State private var showingAddStock = false
    @State private var showingSyncConfirmation = false
    @State private var showingSyncResult = false
    @State private var syncMessage = ""
    @State private var showingLoanSyncSelection = false
    @State private var showingLoanSyncResult = false
    @State private var loanSyncMessage = ""

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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 標題區域
                headerView

                Divider()

                // 持倉列表
                if usStocks.isEmpty {
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
                            .disabled(usStocks.isEmpty)

                            // 貸款同步
                            Button(action: {
                                showingLoanSyncSelection = true
                            }) {
                                Label("同步至貸款", systemImage: "building.columns")
                            }
                            .disabled(usStocks.isEmpty)

                            Divider()

                            // 更新股價
                            Button(action: {
                                showingRefreshConfirmation = true
                            }) {
                                Label("更新股價", systemImage: "arrow.clockwise")
                            }
                            .disabled(isRefreshing || usStocks.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }

                        // 新增按鈕
                        Button(action: {
                            addNewStock()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .confirmationDialog("確認更新", isPresented: $showingRefreshConfirmation, titleVisibility: .visible) {
                Button("更新股價") {
                    refreshAllStockPrices()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("將從網路獲取最新股價並更新持倉數據，是否繼續？")
            }
            .confirmationDialog("確認同步", isPresented: $showingSyncConfirmation, titleVisibility: .visible) {
                Button("同步到月度資產") {
                    syncToMonthlyAsset()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("將當前美股持倉的總市值和總成本同步到最新的月度資產記錄，是否繼續？")
            }
            .alert("更新結果", isPresented: $showingRefreshResult) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(refreshMessage)
            }
            .alert("同步結果", isPresented: $showingSyncResult) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(syncMessage)
            }
            .alert("貸款同步結果", isPresented: $showingLoanSyncResult) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(loanSyncMessage)
            }
            .sheet(isPresented: $showingLoanSyncSelection) {
                if let client = client {
                    USStockLoanSyncSelectionView(
                        client: client,
                        stocks: Array(usStocks),
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
            // 總計信息
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
            .padding(.horizontal, 8)
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
                .foregroundColor(.gray.opacity(0.5))

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
                Text("點擊右上角 + 按鈕新增持股")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Button(action: {
                addNewStock()
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
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 持倉列表
    private var stockListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(usStocks, id: \.self) { stock in
                    StockInventoryRow(
                        stock: stock,
                        onUpdate: {
                            saveContext()
                        },
                        onDelete: {
                            deleteStock(stock)
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - 計算總計
    private func getTotalMarketValue() -> Double {
        // 如果有庫存明細，從庫存明細計算
        if !usStocks.isEmpty {
            return usStocks.reduce(0.0) { total, stock in
                let marketValue = Double(stock.marketValue ?? "0") ?? 0
                return total + marketValue
            }
        }

        // 如果沒有庫存明細，從月度資產明細讀取
        return getMonthlyAssetValue(keyPath: \.usStock)
    }

    private func getTotalCost() -> Double {
        // 如果有庫存明細，從庫存明細計算
        if !usStocks.isEmpty {
            return usStocks.reduce(0.0) { total, stock in
                let cost = Double(stock.cost ?? "0") ?? 0
                return total + cost
            }
        }

        // 如果沒有庫存明細，從月度資產明細讀取
        return getMonthlyAssetValue(keyPath: \.usStockCost)
    }

    private func getTotalProfitLoss() -> Double {
        return getTotalMarketValue() - getTotalCost()
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
        return usStocks.isEmpty
    }

    // MARK: - 格式化輔助函數
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return "$\(formatter.string(from: NSNumber(value: value)) ?? "0.00")"
    }

    private func formatReturnRate(_ value: Double) -> String {
        return String(format: "%+.2f%%", value)
    }

    // MARK: - 數據操作
    private func addNewStock() {
        guard let client = client else {
            print("❌ 無法新增美股：沒有選中的客戶")
            return
        }

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

            saveContext()
        }
    }

    private func deleteStock(_ stock: USStock) {
        withAnimation {
            viewContext.delete(stock)
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 美股持倉已儲存並同步到 iCloud")
        } catch {
            print("❌ 儲存失敗: \(error)")
        }
    }

    // MARK: - 刷新股價功能
    private func refreshAllStockPrices() {
        guard !usStocks.isEmpty else {
            refreshMessage = "目前沒有持股數據"
            showingRefreshResult = true
            return
        }

        isRefreshing = true

        Task {
            // 收集所有股票代碼
            let symbols = usStocks.compactMap { stock -> String? in
                let symbol = stock.name?.trimmingCharacters(in: .whitespaces).uppercased()
                return (symbol?.isEmpty == false) ? symbol : nil
            }

            guard !symbols.isEmpty else {
                await MainActor.run {
                    isRefreshing = false
                    refreshMessage = "沒有有效的股票代碼"
                    showingRefreshResult = true
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
                    saveContext()

                    // 記錄股價更新時間（用於小卡顯示邏輯）
                    if let client = client {
                        let key = "usStockPriceUpdateTime_\(client.objectID.uriRepresentation().absoluteString)"
                        UserDefaults.standard.set(Date(), forKey: key)
                        print("✅ 已記錄美股價更新時間")

                        // 更新即時快照的美股數字
                        updateLiveSnapshotUSStock()

                        // 發送通知，通知 CustomerDetailView 刷新
                        NotificationCenter.default.post(
                            name: NSNotification.Name("USStockPriceUpdated"),
                            object: nil,
                            userInfo: ["clientID": client.objectID.uriRepresentation().absoluteString]
                        )
                    }
                }

                // 顯示結果
                isRefreshing = false
                if successCount > 0 {
                    refreshMessage = "成功更新 \(successCount) 個股票\(failCount > 0 ? "，\(failCount) 個失敗" : "")"
                } else {
                    refreshMessage = "更新失敗，請檢查股票代碼是否正確"
                }
                showingRefreshResult = true
            }
        }
    }

    private func recalculateStock(stock: USStock) {
        let shares = Double(stock.shares ?? "0") ?? 0
        let costPerShare = Double(stock.costPerShare ?? "0") ?? 0
        let currentPrice = Double(stock.currentPrice ?? "0") ?? 0

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

    // MARK: - 同步到月度資產功能
    private func syncToMonthlyAsset() {
        guard let client = client else {
            syncMessage = "無法同步：沒有選中的客戶"
            showingSyncResult = true
            return
        }

        // 計算當前持倉的總市值和總成本
        let totalMarketValue = getTotalMarketValue()
        let totalCost = getTotalCost()

        // 獲取該客戶最新的月度資產記錄
        let fetchRequest: NSFetchRequest<MonthlyAsset> = MonthlyAsset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)

            guard let latestAsset = results.first else {
                syncMessage = "無法同步：找不到月度資產記錄\n請先在月度資產明細中新增一筆記錄"
                showingSyncResult = true
                return
            }

            // 格式化日期以顯示給用戶
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            let dateString = latestAsset.createdDate.map { dateFormatter.string(from: $0) } ?? latestAsset.date ?? "未知日期"

            // 更新美股市值和成本
            let oldValue = Double(latestAsset.usStock ?? "0") ?? 0
            let oldCost = Double(latestAsset.usStockCost ?? "0") ?? 0
            let oldTotalAssets = Double(latestAsset.totalAssets ?? "0") ?? 0

            latestAsset.usStock = String(format: "%.2f", totalMarketValue)
            latestAsset.usStockCost = String(format: "%.2f", totalCost)

            // 重新計算總資產（美金計價）
            // 總資產 = 美金 + 美股 + 定期定額 + 債券 + 台股折合 + 台幣折合美金 + 結構型 + 基金 + 保險
            let cash = Double(latestAsset.cash ?? "0") ?? 0
            let regularInvestment = Double(latestAsset.regularInvestment ?? "0") ?? 0
            let bonds = Double(latestAsset.bonds ?? "0") ?? 0
            let structured = Double(latestAsset.structured ?? "0") ?? 0
            let taiwanStockFolded = Double(latestAsset.taiwanStockFolded ?? "0") ?? 0
            let twdToUsd = Double(latestAsset.twdToUsd ?? "0") ?? 0
            let fund = Double(latestAsset.fund ?? "0") ?? 0
            let insurance = Double(latestAsset.insurance ?? "0") ?? 0

            // 計算新的總資產
            let newTotalAssets = cash + totalMarketValue + regularInvestment + bonds + taiwanStockFolded + twdToUsd + structured + fund + insurance
            latestAsset.totalAssets = String(format: "%.2f", newTotalAssets)

            // 保存更改
            try viewContext.save()
            PersistenceController.shared.save()

            // 顯示同步結果
            syncMessage = """
            ✅ 同步成功！

            日期：\(dateString)
            美股市值：$\(String(format: "%.2f", oldValue)) → $\(String(format: "%.2f", totalMarketValue))
            美股成本：$\(String(format: "%.2f", oldCost)) → $\(String(format: "%.2f", totalCost))
            總資產：$\(String(format: "%.2f", oldTotalAssets)) → $\(String(format: "%.2f", newTotalAssets))
            """
            showingSyncResult = true

            print("✅ 已同步美股數據到月度資產")
            print("   日期：\(dateString)")
            print("   市值：\(totalMarketValue)")
            print("   成本：\(totalCost)")
            print("   總資產：\(newTotalAssets)")

        } catch {
            syncMessage = "同步失敗：\(error.localizedDescription)"
            showingSyncResult = true
            print("❌ 同步失敗: \(error)")
        }
    }

    // MARK: - 貸款同步功能
    private func syncToLoanMonthlyData(selectedStocks: [USStock], loan: Loan) {
        guard let client = client else {
            loanSyncMessage = "無法同步：沒有選中的客戶"
            showingLoanSyncResult = true
            return
        }

        // 計算選中股票的總市值和總成本(美金)
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
            let oldUsStock = Double(loanMonthlyData.usStock ?? "0") ?? 0
            let oldUsStockCost = Double(loanMonthlyData.usStockCost ?? "0") ?? 0

            // 更新美股市值和成本(美金)
            loanMonthlyData.usStock = String(format: "%.2f", totalMarketValue)
            loanMonthlyData.usStockCost = String(format: "%.2f", totalCost)

            // 獲取匯率(預設32)
            let exchangeRate = Double(loanMonthlyData.exchangeRate ?? "32") ?? 32

            // 計算美股加債券折合台幣 = (美股 + 債券) * 匯率
            let bonds = Double(loanMonthlyData.bonds ?? "0") ?? 0
            let usStockBondsInTwd = (totalMarketValue + bonds) * exchangeRate
            loanMonthlyData.usStockBondsInTwd = String(format: "%.2f", usStockBondsInTwd)

            // 計算投資總額(台幣) = 台股 + 美股加債券折合台幣
            let taiwanStock = Double(loanMonthlyData.taiwanStock ?? "0") ?? 0
            let totalInvestment = taiwanStock + usStockBondsInTwd
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
            美股市值：$\(String(format: "%.2f", oldUsStock)) → $\(String(format: "%.2f", totalMarketValue))
            美股成本：$\(String(format: "%.2f", oldUsStockCost)) → $\(String(format: "%.2f", totalCost))

            美股加債券折合台幣：NT$\(String(format: "%.2f", usStockBondsInTwd))
            投資總額(台幣)：NT$\(String(format: "%.2f", totalInvestment))
            """
            showingLoanSyncResult = true

            print("✅ 已同步美股數據到貸款月度數據")
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

    // MARK: - 更新即時快照的美股數字
    private func updateLiveSnapshotUSStock() {
        guard let client = client else { return }

        // 查找即時快照
        let fetchRequest: NSFetchRequest<MonthlyAsset> = MonthlyAsset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@ AND isLiveSnapshot == YES", client)
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)

            if let liveSnapshot = results.first {
                // 計算美股總市值
                let totalMarketValue = getTotalMarketValue()
                let totalCost = getTotalCost()

                // 更新即時快照的美股欄位
                liveSnapshot.usStock = String(format: "%.2f", totalMarketValue)
                liveSnapshot.usStockCost = String(format: "%.2f", totalCost)
                liveSnapshot.createdDate = Date()

                // 重新計算總資產
                let twd = Double(liveSnapshot.twdCash ?? "0") ?? 0
                let usd = Double(liveSnapshot.cash ?? "0") ?? 0
                let regularInvestment = Double(liveSnapshot.regularInvestment ?? "0") ?? 0
                let bonds = Double(liveSnapshot.bonds ?? "0") ?? 0
                let taiwanStockFolded = Double(liveSnapshot.taiwanStockFolded ?? "0") ?? 0
                let structured = Double(liveSnapshot.structured ?? "0") ?? 0
                let fund = Double(liveSnapshot.fund ?? "0") ?? 0
                let insurance = Double(liveSnapshot.insurance ?? "0") ?? 0

                let totalAssets = twd + usd + totalMarketValue + regularInvestment + bonds + taiwanStockFolded + structured + fund + insurance
                liveSnapshot.totalAssets = String(format: "%.2f", totalAssets)

                // 儲存
                try viewContext.save()
                PersistenceController.shared.save()

                print("✅ 已更新即時快照美股數字: $\(String(format: "%.2f", totalMarketValue))")
            }
        } catch {
            print("❌ 更新即時快照失敗: \(error)")
        }
    }
}

// MARK: - 持倉行組件
struct StockInventoryRow: View {
    @ObservedObject var stock: USStock
    let onUpdate: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // 基本信息行
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(stock.name?.isEmpty == false ? stock.name! : "未命名")
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

                            Text("成本: $\(formatNumber(stock.cost))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(formatNumber(stock.marketValue))")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)

                        if let returnRateStr = stock.returnRate {
                            let returnRate = getReturnRateValue(returnRateStr)
                            Text(returnRateStr)
                                .font(.caption)
                                .foregroundColor(returnRate >= 0 ? .green : .red)
                        }
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(PlainButtonStyle())

            // 展開的編輯區域
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()

                    // 編輯字段
                    VStack(spacing: 12) {
                        // 股票代碼
                        HStack {
                            Text("股票代碼")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("例如: AAPL", text: Binding(
                                get: { stock.name ?? "" },
                                set: {
                                    stock.name = $0
                                    onUpdate()
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 股數
                        HStack {
                            Text("股數")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: Binding(
                                get: { stock.shares ?? "0" },
                                set: {
                                    stock.shares = $0
                                    recalculateAndUpdate()
                                }
                            ))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 成本單價
                        HStack {
                            Text("成本單價")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: Binding(
                                get: { stock.costPerShare ?? "0" },
                                set: {
                                    stock.costPerShare = $0
                                    recalculateAndUpdate()
                                }
                            ))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 現價（唯讀，顯示灰色背景）
                        HStack {
                            Text("現價")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: Binding(
                                get: { stock.currentPrice ?? "0" },
                                set: { _ in }
                            ))
                            .disabled(true)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .background(Color(.tertiarySystemBackground))
                        }

                        // 幣別
                        HStack {
                            Text("幣別")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("USD", text: Binding(
                                get: { stock.currency ?? "USD" },
                                set: {
                                    stock.currency = $0
                                    onUpdate()
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 備註
                        HStack(alignment: .top) {
                            Text("備註")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                            TextEditor(text: Binding(
                                get: { stock.comment ?? "" },
                                set: {
                                    stock.comment = $0
                                    onUpdate()
                                }
                            ))
                            .frame(height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                        }
                    }
                    .padding(.horizontal)

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
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("確定要刪除 \(stock.name ?? "此持股") 嗎？此操作無法撤銷。")
        }
    }

    private func recalculateAndUpdate() {
        let shares = Double(stock.shares ?? "0") ?? 0
        let costPerShare = Double(stock.costPerShare ?? "0") ?? 0
        let currentPrice = Double(stock.currentPrice ?? "0") ?? 0

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

        onUpdate()
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

    private func getReturnRateValue(_ rateString: String) -> Double {
        let cleanValue = rateString.replacingOccurrences(of: "%", with: "")
        return Double(cleanValue) ?? 0
    }
}

#Preview {
    USStockInventoryView(client: nil)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
