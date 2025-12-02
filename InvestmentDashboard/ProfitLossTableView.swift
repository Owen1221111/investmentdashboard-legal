import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct ProfitLossTableView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingImportOptions = false
    @State private var showingFileImporter = false
    @State private var isExpanded = false
    @State private var showingColumnReorder = false
    @State private var columnOrder: [String] = []
    @State private var pnlToDelete: ProfitLoss? = nil
    @State private var showingDeleteConfirmation = false

    let client: Client?

    // FetchRequest 取得當前客戶的損益資料
    @FetchRequest private var profitLosses: FetchedResults<ProfitLoss>

    init(client: Client?) {
        self.client = client

        // 設定 FetchRequest 以取得該客戶的損益資料
        if let client = client {
            _profitLosses = FetchRequest<ProfitLoss>(
                sortDescriptors: [NSSortDescriptor(keyPath: \ProfitLoss.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client),
                animation: .default
            )
        } else {
            _profitLosses = FetchRequest<ProfitLoss>(
                sortDescriptors: [NSSortDescriptor(keyPath: \ProfitLoss.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }

    private let headers = ["交易編碼", "交易類別", "交易日/配息入帳日", "交割幣別", "成交股數", "成交價格", "交易金額", "投入成本", "損益", "報酬率"]

    var body: some View {
        VStack(spacing: 0) {
            // 標題區域（含縮放功能）
            tableHeader

            // 表格內容（可縮放）
            if isExpanded {
                pnlTable
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
        .confirmationDialog("匯入資料", isPresented: $showingImportOptions, titleVisibility: .visible) {
            Button("從 CSV 檔案匯入") {
                showingFileImporter = true
            }
            Button("手動新增資料") {
                handleManualDataEntry()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("選擇匯入方式")
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.commaSeparatedText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .sheet(isPresented: $showingColumnReorder) {
            ColumnReorderView(
                headers: headers,
                initialOrder: columnOrder.isEmpty ? headers : columnOrder,
                onSave: { newOrder in
                    columnOrder = newOrder
                    // 儲存到 UserDefaults
                    UserDefaults.standard.set(newOrder, forKey: "ProfitLoss_ColumnOrder")
                }
            )
        }
        .onAppear {
            // 從 UserDefaults 讀取欄位排序
            if let savedOrder = UserDefaults.standard.array(forKey: "ProfitLoss_ColumnOrder") as? [String], !savedOrder.isEmpty {
                columnOrder = savedOrder
            } else if columnOrder.isEmpty {
                columnOrder = headers
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) {
                pnlToDelete = nil
            }
            Button("刪除", role: .destructive) {
                if let pnl = pnlToDelete {
                    deleteProfitLoss(pnl)
                    pnlToDelete = nil
                }
            }
        } message: {
            if let pnl = pnlToDelete {
                Text("確定要刪除「\(pnl.transactionCode ?? "此記錄")」嗎？此操作無法復原。")
            } else {
                Text("確定要刪除此記錄嗎？此操作無法復原。")
            }
        }
    }

    // MARK: - 標題區域（含縮放功能）
    private var tableHeader: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14))
                    Text("損益表")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

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
                        showingImportOptions = true
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

    // MARK: - 損益表
    private var pnlTable: some View {
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
                        Text(header)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 14)
                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                    }
                }
                .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

                // 分隔線
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)

                // 資料行容器
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(profitLosses, id: \.objectID) { pnl in
                            let index = profitLosses.firstIndex(of: pnl) ?? 0
                            HStack(spacing: 0) {
                                // 刪除按鈕（移到最左邊）
                                Button(action: {
                                    pnlToDelete = pnl
                                    showingDeleteConfirmation = true
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 8)
                                .frame(width: 40, alignment: .center)

                                ForEach(currentColumnOrder, id: \.self) { header in
                                    if isAutoCalculatedField(header) {
                                        // 自動計算欄位顯示為唯讀（灰色背景）
                                        Text(bindingForProfitLoss(pnl, header: header).wrappedValue)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(.secondaryLabel))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                            .background(Color(.tertiarySystemBackground))
                                    } else {
                                        TextField("", text: bindingForProfitLoss(pnl, header: header))
                                            .font(.system(size: 15, weight: .medium))
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                            .background(Color.clear)
                                    }
                                }
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

                        // ⭐️ 合計行
                        if !profitLosses.isEmpty {
                            // 分隔線（加粗橘色）
                            Rectangle()
                                .fill(Color.orange.opacity(0.6))
                                .frame(height: 2)

                            HStack(spacing: 0) {
                                Text("")
                                    .frame(width: 40, alignment: .center)

                                ForEach(currentColumnOrder, id: \.self) { header in
                                    if header == "交易金額" {
                                        Text(formatNumberWithCommas(String(format: "%.2f", calculateTotalTransactionAmount())))
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                            .background(Color.yellow.opacity(0.15))
                                    } else if header == "投入成本" {
                                        Text(formatNumberWithCommas(String(format: "%.2f", calculateTotalInvestedCost())))
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                            .background(Color.yellow.opacity(0.15))
                                    } else if header == "損益" {
                                        Text(formatNumberWithCommas(String(format: "%.2f", calculateTotalProfitLoss())))
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(calculateTotalProfitLoss() >= 0 ? .green : .red)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                            .background(Color.yellow.opacity(0.15))
                                    } else if header == "報酬率" {
                                        let totalCost = calculateTotalInvestedCost()
                                        let returnRate = totalCost > 0 ? (calculateTotalProfitLoss() / totalCost) * 100 : 0
                                        Text(String(format: "%.2f%%", returnRate))
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(returnRate >= 0 ? .green : .red)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                            .background(Color.yellow.opacity(0.15))
                                    } else if header == "交易編碼" {
                                        Text("合計")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                            .background(Color.yellow.opacity(0.15))
                                    } else {
                                        Text("")
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                            .background(Color.yellow.opacity(0.15))
                                    }
                                }
                            }

                            // 底部橘色分隔線
                            Rectangle()
                                .fill(Color.orange.opacity(0.6))
                                .frame(height: 2)
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
    }

    // MARK: - 計算屬性
    private var currentColumnOrder: [String] {
        return columnOrder.isEmpty ? headers : columnOrder
    }

    // MARK: - 欄位寬度
    private func getColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "交易編碼": return 100
        case "交易類別": return 100
        case "交易日/配息入帳日": return 150
        case "交割幣別": return 80
        case "成交股數": return 100
        case "成交價格": return 100
        case "交易金額": return 120
        case "投入成本": return 120
        case "損益": return 100
        case "報酬率": return 100
        default: return 100
        }
    }

    // MARK: - 資料綁定
    private func bindingForProfitLoss(_ pnl: ProfitLoss, header: String) -> Binding<String> {
        Binding<String>(
            get: {
                let rawValue: String
                switch header {
                case "交易編碼": rawValue = pnl.transactionCode ?? ""
                case "交易類別": rawValue = pnl.transactionType ?? ""
                case "交易日/配息入帳日": rawValue = pnl.transactionDate ?? ""
                case "交割幣別": rawValue = pnl.settlementCurrency ?? ""
                case "成交股數": rawValue = pnl.shares ?? ""
                case "成交價格": rawValue = pnl.transactionPrice ?? ""
                case "交易金額": rawValue = pnl.transactionAmount ?? ""
                case "投入成本": rawValue = pnl.investedCost ?? ""
                case "損益": rawValue = pnl.profitLoss ?? ""
                case "報酬率": rawValue = pnl.returnRate ?? ""
                default: rawValue = ""
                }

                // 如果是數字欄位，加上千分位
                return isNumberField(header) ? formatNumberWithCommas(rawValue) : rawValue
            },
            set: { newValue in
                // 移除千分位後儲存
                let cleanValue = isNumberField(header) ? removeCommas(newValue) : newValue

                switch header {
                case "交易編碼": pnl.transactionCode = cleanValue
                case "交易類別": pnl.transactionType = cleanValue
                case "交易日/配息入帳日": pnl.transactionDate = cleanValue
                case "交割幣別": pnl.settlementCurrency = cleanValue
                case "成交股數":
                    pnl.shares = cleanValue
                    recalculateProfitLoss(pnl: pnl)
                case "成交價格":
                    pnl.transactionPrice = cleanValue
                    recalculateProfitLoss(pnl: pnl)
                case "交易金額":
                    // 交易金額為自動計算，不允許手動修改
                    break
                case "投入成本":
                    pnl.investedCost = cleanValue
                    recalculateProfitLoss(pnl: pnl)
                case "損益":
                    // 損益為自動計算，不允許手動修改
                    break
                case "報酬率":
                    // 報酬率為自動計算，不允許手動修改
                    break
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

    // 判斷是否為數字欄位
    private func isNumberField(_ header: String) -> Bool {
        let textFields = ["交易編碼", "交易類別", "交易日/配息入帳日", "交割幣別"]
        return !textFields.contains(header)
    }

    // 判斷是否為自動計算欄位
    private func isAutoCalculatedField(_ header: String) -> Bool {
        let autoFields = ["交易金額", "損益", "報酬率"]
        return autoFields.contains(header)
    }

    // MARK: - 自動計算
    private func recalculateProfitLoss(pnl: ProfitLoss) {
        // 移除千分位並轉換為數字
        let shares = Double(removeCommas(pnl.shares ?? "")) ?? 0
        let transactionPrice = Double(removeCommas(pnl.transactionPrice ?? "")) ?? 0
        let investedCost = Double(removeCommas(pnl.investedCost ?? "")) ?? 0

        // 計算交易金額 = 成交股數 × 成交價格
        let transactionAmount = shares * transactionPrice
        pnl.transactionAmount = String(format: "%.2f", transactionAmount)

        // 計算損益 = 交易金額 - 投入成本
        let profitLoss = transactionAmount - investedCost
        pnl.profitLoss = String(format: "%.2f", profitLoss)

        // 計算報酬率 = 損益 / 投入成本 × 100
        if investedCost > 0 {
            let returnRate = (profitLoss / investedCost) * 100
            pnl.returnRate = String(format: "%.2f%%", returnRate)
        } else {
            pnl.returnRate = "0.00%"
        }
    }

    // MARK: - ⭐️ 計算損益表合計
    private func calculateTotalTransactionAmount() -> Double {
        return profitLosses.reduce(0.0) { total, pnl in
            let amountStr = removeCommas(pnl.transactionAmount ?? "")
            return total + (Double(amountStr) ?? 0)
        }
    }

    private func calculateTotalInvestedCost() -> Double {
        return profitLosses.reduce(0.0) { total, pnl in
            let costStr = removeCommas(pnl.investedCost ?? "")
            return total + (Double(costStr) ?? 0)
        }
    }

    private func calculateTotalProfitLoss() -> Double {
        return profitLosses.reduce(0.0) { total, pnl in
            let plStr = removeCommas(pnl.profitLoss ?? "")
            return total + (Double(plStr) ?? 0)
        }
    }

    // MARK: - 編輯和刪除功能
    private func deleteProfitLoss(_ pnl: ProfitLoss) {
        withAnimation {
            viewContext.delete(pnl)
            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("✅ 損益記錄已刪除並同步到 iCloud")
            } catch {
                print("❌ 刪除失敗: \(error)")
            }
        }
    }

    private func deleteLastRow() {
        if let lastPnl = profitLosses.last {
            deleteProfitLoss(lastPnl)
        }
    }

    private func addNewRow() {
        guard let client = client else {
            print("❌ 無法新增資料：沒有選中的客戶")
            return
        }

        withAnimation {
            let newPnl = ProfitLoss(context: viewContext)
            newPnl.client = client
            newPnl.transactionCode = ""
            newPnl.transactionType = ""
            newPnl.transactionDate = ""
            newPnl.settlementCurrency = ""
            newPnl.shares = ""
            newPnl.transactionPrice = ""
            newPnl.transactionAmount = ""
            newPnl.investedCost = ""
            newPnl.profitLoss = ""
            newPnl.returnRate = ""
            newPnl.createdDate = Date()

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("✅ 新增空白損益記錄並同步到 iCloud")
            } catch {
                print("❌ 新增失敗: \(error)")
            }
        }
    }

    // MARK: - 匯入功能處理
    private func handleManualDataEntry() {
        addNewRow()
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let firstURL = urls.first {
                print("成功選擇檔案：\(firstURL)")
            }
        case .failure(let error):
            print("檔案選擇失敗：\(error.localizedDescription)")
        }
    }
}

#Preview {
    ProfitLossTableView(client: nil)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .padding()
}
