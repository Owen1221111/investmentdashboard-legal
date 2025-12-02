import SwiftUI
import CoreData

struct StructuredProductsInventoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client?

    // FetchRequest 取得當前客戶的結構型商品資料
    @FetchRequest private var structuredProducts: FetchedResults<StructuredProduct>

    @State private var showingAddStructuredProduct = false
    @State private var showingSyncConfirmation = false
    @State private var showingSyncResult = false
    @State private var syncMessage = ""

    // 匯率資料（全域共用，保持 @AppStorage）
    @AppStorage("exchangeRate") private var exchangeRate: String = ""

    init(client: Client?) {
        self.client = client

        // 設定 FetchRequest 以取得該客戶的結構型商品資料（僅ongoing，未出場）
        if let client = client {
            _structuredProducts = FetchRequest<StructuredProduct>(
                sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@ AND isExited == NO", client),
                animation: .default
            )
        } else {
            _structuredProducts = FetchRequest<StructuredProduct>(
                sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 標題區域
                    headerView

                    Divider()

                    // 主要內容區域
                    mainContentView
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
                        // 功能選單（簡化版）
                        Menu {
                            // 同步到月度資產
                            Button(action: {
                                showingSyncConfirmation = true
                            }) {
                                Label("同步至月度資產", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .disabled(structuredProducts.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }

                        // 新增按鈕
                        Button(action: {
                            showingAddStructuredProduct = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .confirmationDialog("確認同步", isPresented: $showingSyncConfirmation, titleVisibility: .visible) {
                Button("同步到月度資產") {
                    syncToMonthlyAsset()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("將當前結構型商品的總現值同步到最新的月度資產記錄，是否繼續？")
            }
            .alert("同步結果", isPresented: $showingSyncResult) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(syncMessage)
            }
            .sheet(isPresented: $showingAddStructuredProduct) {
                if let client = client {
                    // TODO: 使用實際的新增結構型商品表單
                    // BatchAddStructuredProductView(preselectedClient: client)
                    Text("新增結構型商品表單")
                        .font(.title)
                }
            }
        }
    }

    // MARK: - 主要內容區域
    @ViewBuilder
    private var mainContentView: some View {
        if structuredProducts.isEmpty {
            emptyStateView
        } else {
            productListView
        }
    }

    // MARK: - 標題區域
    private var headerView: some View {
        VStack(spacing: 12) {
            // 第一行：總成本、報酬率
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("總成本")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Text(formatCurrency(getTotalCost()))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 30)

                VStack(spacing: 4) {
                    Text("年化利率")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(formatReturnRate(getAverageInterestRate()))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }

            // 第二行：總現值、商品數量
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("總現值")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Text(formatCurrency(getTotalCurrentValue()))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 30)

                VStack(spacing: 4) {
                    Text("商品數量")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Text("\(structuredProducts.count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }

    // MARK: - 空狀態視圖
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("尚無結構型商品資料")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)

            Text("點擊右上角 + 按鈕新增結構型商品")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 結構型商品列表
    private var productListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(structuredProducts, id: \.self) { product in
                StructuredProductInventoryRow(
                    product: product,
                    onUpdate: {
                        do {
                            try viewContext.save()
                            PersistenceController.shared.save()
                        } catch {
                            print("保存失敗: \(error.localizedDescription)")
                        }
                    },
                    onDelete: {
                        deleteProduct(product)
                    }
                )
            }
        }
        .padding(16)
    }

    // MARK: - 計算總現值（使用交易金額作為現值）
    private func getTotalCurrentValue() -> Double {
        structuredProducts.reduce(0.0) { total, product in
            let transactionAmount = Double(product.transactionAmount?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
            return total + transactionAmount
        }
    }

    // MARK: - 計算總成本
    private func getTotalCost() -> Double {
        structuredProducts.reduce(0.0) { total, product in
            let cost = Double(product.transactionAmount?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
            return total + cost
        }
    }

    // MARK: - 計算平均利率
    private func getAverageInterestRate() -> Double {
        guard !structuredProducts.isEmpty else { return 0 }

        let totalRate = structuredProducts.reduce(0.0) { total, product in
            let rate = Double(product.interestRate?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
            return total + rate
        }

        return totalRate / Double(structuredProducts.count)
    }

    // MARK: - 同步到月度資產
    private func syncToMonthlyAsset() {
        guard let client = client else {
            syncMessage = "無法找到客戶資料"
            showingSyncResult = true
            return
        }

        // 獲取最新的月度資產記錄
        let fetchRequest: NSFetchRequest<MonthlyAsset> = MonthlyAsset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)

            guard let latestAsset = results.first else {
                syncMessage = "找不到月度資產記錄，請先新增月度資產"
                showingSyncResult = true
                return
            }

            // 計算總現值
            let totalValue = getTotalCurrentValue()

            // 更新月度資產
            latestAsset.structured = String(format: "%.2f", totalValue)

            // 儲存
            try viewContext.save()
            PersistenceController.shared.save()

            syncMessage = "已成功同步至月度資產\n總現值: $\(String(format: "%.2f", totalValue))"
            showingSyncResult = true

        } catch {
            syncMessage = "同步失敗: \(error.localizedDescription)"
            showingSyncResult = true
        }
    }

    // MARK: - 格式化金額
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    // MARK: - 格式化報酬率
    private func formatReturnRate(_ rate: Double) -> String {
        return String(format: "%.2f%%", rate)
    }

    // MARK: - 刪除結構型商品
    private func deleteProduct(_ product: StructuredProduct) {
        withAnimation {
            viewContext.delete(product)

            do {
                try viewContext.save()
                PersistenceController.shared.save()
            } catch {
                print("刪除結構型商品失敗: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - 結構型商品行組件
struct StructuredProductInventoryRow: View {
    @ObservedObject var product: StructuredProduct
    let onUpdate: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var showingDeleteConfirmation = false

    // 匯率資料
    @AppStorage("exchangeRate") private var exchangeRate: String = ""

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
                            Text(product.productCode ?? "未命名商品")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        HStack(spacing: 8) {
                            // 顯示標的
                            let targets = getTargetsText()
                            if !targets.isEmpty {
                                Text("標的: \(targets)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            // 顯示利率
                            if let rate = product.interestRate, !rate.isEmpty {
                                Text("利率: \(rate)%")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatNumber(getTransactionAmount()))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)

                        // 顯示現價百分比
                        if let price1 = product.currentPrice1, !price1.isEmpty {
                            Text("\(price1)%")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                        // 商品代號
                        HStack {
                            Text("商品代號")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("例如: TSM", text: Binding(
                                get: { product.productCode ?? "" },
                                set: { newValue in
                                    product.productCode = newValue
                                    onUpdate()
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 標的1
                        HStack {
                            Text("標的1")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("例如: TSM", text: Binding(
                                get: { product.target1 ?? "" },
                                set: { newValue in
                                    product.target1 = newValue
                                    onUpdate()
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 標的2（如果有）
                        if (product.numberOfTargets > 1) {
                            HStack {
                                Text("標的2")
                                    .frame(width: 80, alignment: .leading)
                                    .foregroundColor(.secondary)
                                TextField("例如: SOXX", text: Binding(
                                    get: { product.target2 ?? "" },
                                    set: { newValue in
                                        product.target2 = newValue
                                        onUpdate()
                                    }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }

                        // 年化利率
                        HStack {
                            Text("年化利率 %")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: Binding(
                                get: { product.interestRate ?? "" },
                                set: { newValue in
                                    product.interestRate = newValue
                                    onUpdate()
                                }
                            ))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 現價比例1
                        HStack {
                            Text("現價1 %")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("100", text: Binding(
                                get: { product.currentPrice1 ?? "100" },
                                set: { newValue in
                                    product.currentPrice1 = newValue
                                    onUpdate()
                                }
                            ))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 交易金額
                        HStack {
                            Text("交易金額")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: Binding(
                                get: { product.transactionAmount ?? "0" },
                                set: { newValue in
                                    product.transactionAmount = newValue
                                    onUpdate()
                                }
                            ))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal)

                    // 刪除按鈕
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("刪除此商品")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
                    Button("取消", role: .cancel) {}
                    Button("刪除", role: .destructive) {
                        onDelete()
                    }
                } message: {
                    Text("確定要刪除此結構型商品嗎？此操作無法復原。")
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // 獲取標的文本
    private func getTargetsText() -> String {
        var targets: [String] = []
        if let t1 = product.target1, !t1.isEmpty { targets.append(t1) }
        if let t2 = product.target2, !t2.isEmpty { targets.append(t2) }
        if let t3 = product.target3, !t3.isEmpty { targets.append(t3) }
        if let t4 = product.target4, !t4.isEmpty { targets.append(t4) }
        return targets.joined(separator: ", ")
    }

    // 獲取交易金額
    private func getTransactionAmount() -> Double {
        return Double(product.transactionAmount?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
    }

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

#Preview {
    StructuredProductsInventoryView(client: nil)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
