import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct MonthlyAssetDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var fieldConfigManager = FieldConfigurationManager.shared  // 使用 FieldConfigurationManager
    @State private var showingImportOptions = false
    @State private var showingFileImporter = false
    @State private var isExpanded = false
    @State private var showingFieldConfig = false  // 欄位配置（排序 + 顯示/隱藏）
    @State private var assetToDelete: MonthlyAsset? = nil
    @State private var showingDeleteConfirmation = false
    @Binding var monthlyData: [[String]]
    let client: Client?

    // FetchRequest 會自動監聽資料變化
    @FetchRequest private var monthlyAssets: FetchedResults<MonthlyAsset>

    init(monthlyData: Binding<[[String]]>, client: Client?) {
        self._monthlyData = monthlyData
        self.client = client

        // 根據客戶 ID 建立 FetchRequest
        // 排序：按 createdDate 降序（新到舊），過濾掉即時快照
        if let client = client {
            _monthlyAssets = FetchRequest<MonthlyAsset>(
                sortDescriptors: [
                    NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)
                ],
                predicate: NSPredicate(format: "client == %@ AND isLiveSnapshot == NO", client),
                animation: .default
            )
        } else {
            // 如果沒有客戶，返回空結果
            _monthlyAssets = FetchRequest<MonthlyAsset>(
                sortDescriptors: [
                    NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)
                ],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }


    var body: some View {
        VStack(spacing: 0) {
            // 標題區域（含縮放功能）
            tableHeader

            // 表格內容（可縮放）
            if isExpanded {
                monthlyAssetTable
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
        .sheet(isPresented: $showingFieldConfig) {
            AssetFieldConfigurationView()
        }
        .onAppear {
            // 修復所有沒有總資產的記錄
            fixMissingTotalAssets()
            // 重新計算所有匯入累積
            recalculateAllDepositAccumulated()
            // 儲存修復結果
            do {
                try viewContext.save()
                PersistenceController.shared.save()
            } catch {
                print("❌ 儲存修復結果失敗: \(error)")
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) {
                assetToDelete = nil
            }
            Button("刪除", role: .destructive) {
                if let asset = assetToDelete {
                    deleteAsset(asset)
                    assetToDelete = nil
                }
            }
        } message: {
            if let asset = assetToDelete {
                Text("確定要刪除「\(asset.date ?? "此記錄")」的月度資產資料嗎？此操作無法復原。")
            } else {
                Text("確定要刪除此月度資產資料嗎？此操作無法復原。")
            }
        }
    }

    // MARK: - 標題區域（含縮放功能）
    private var tableHeader: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                    Text("月度資產明細")
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
                        showingFieldConfig = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
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


    // MARK: - 月度資產明細表格
    private var monthlyAssetTable: some View {
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
                            .frame(minWidth: getColumnWidth(for: header), alignment: .leading)
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
                        ForEach(Array(monthlyAssets.enumerated()), id: \.offset) { index, asset in
                            HStack(spacing: 0) {
                                // 刪除按鈕
                                Button(action: {
                                    assetToDelete = asset
                                    showingDeleteConfirmation = true
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 8)
                                .frame(width: 40, alignment: .center)

                                ForEach(Array(currentColumnOrder.enumerated()), id: \.offset) { colIndex, header in
                                    if header == "總資產" || header == "匯入累積" || header == "台股折合" || header == "台幣折合美金" ||
                                       header == "歐元折合美金" || header == "日圓折合美金" || header == "英鎊折合美金" ||
                                       header == "人民幣折合美金" || header == "澳幣折合美金" || header == "加幣折合美金" ||
                                       header == "瑞士法郎折合美金" || header == "港幣折合美金" || header == "新加坡幣折合美金" {
                                        // 總資產、匯入累積、所有折合美金欄位顯示為唯讀（灰色背景）
                                        Text(bindingForAsset(asset, header: header).wrappedValue)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(.secondaryLabel))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                            .frame(width: getColumnWidth(for: header), alignment: .leading)
                                            .background(Color(.tertiarySystemBackground))
                                    } else {
                                        TextField("", text: bindingForAsset(asset, header: header))
                                            .font(.system(size: 15, weight: .medium))
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                            .frame(width: getColumnWidth(for: header), alignment: .leading)
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
                    }
                }
                .frame(maxHeight: 400)
            }
        }
    }

    // MARK: - 計算屬性
    private var currentColumnOrder: [String] {
        // 從 FieldConfigurationManager 獲取可見的資產欄位並轉換為欄位名稱
        return fieldConfigManager.visibleFields.compactMap { fieldTypeToHeaderName($0.type) }
    }

    // 將 AssetFieldType 轉換為月度資產明細的欄位名稱
    private func fieldTypeToHeaderName(_ type: AssetFieldType) -> String? {
        switch type {
        case .twdCash: return "台幣"
        case .cash: return "美金"
        case .usStock: return "美股"
        case .regularInvestment: return "定期定額"
        case .bonds: return "債券"
        case .taiwanStock: return "台股"
        case .taiwanStockFolded: return "台股折合"
        case .twdToUsd: return "台幣折合美金"
        case .structured: return "結構型"
        case .confirmedInterest: return "已領利息"
        case .totalAssets: return "總資產"
        case .fund: return "基金"
        case .insurance: return "保險"
        case .exchangeRate: return "匯率"
        case .fundCost: return "基金成本"
        case .usStockCost: return "美股成本"
        case .regularInvestmentCost: return "定期定額成本"
        case .bondsCost: return "債券成本"
        case .taiwanStockCost: return "台股成本"
        // 多幣別
        case .eurCash: return "歐元"
        case .eurRate: return "歐元兌美金匯率"
        case .eurToUsd: return "歐元折合美金"
        case .jpyCash: return "日圓"
        case .jpyRate: return "日圓兌美金匯率"
        case .jpyToUsd: return "日圓折合美金"
        case .gbpCash: return "英鎊"
        case .gbpRate: return "英鎊兌美金匯率"
        case .gbpToUsd: return "英鎊折合美金"
        case .cnyCash: return "人民幣"
        case .cnyRate: return "人民幣兌美金匯率"
        case .cnyToUsd: return "人民幣折合美金"
        case .audCash: return "澳幣"
        case .audRate: return "澳幣兌美金匯率"
        case .audToUsd: return "澳幣折合美金"
        case .cadCash: return "加幣"
        case .cadRate: return "加幣兌美金匯率"
        case .cadToUsd: return "加幣折合美金"
        case .chfCash: return "瑞士法郎"
        case .chfRate: return "瑞士法郎兌美金匯率"
        case .chfToUsd: return "瑞士法郎折合美金"
        case .hkdCash: return "港幣"
        case .hkdRate: return "港幣兌美金匯率"
        case .hkdToUsd: return "港幣折合美金"
        case .sgdCash: return "新加坡幣"
        case .sgdRate: return "新加坡幣兌美金匯率"
        case .sgdToUsd: return "新加坡幣折合美金"
        // 月度資產明細特有欄位
        case .date: return "日期"
        case .deposit: return "匯入"
        case .depositAccumulated: return "匯入累積"
        case .notes: return "備註"
        }
    }

    // MARK: - 資料和輔助函數
    private let monthlyAssetHeaders = [
        "日期", "台幣", "美金", "美股", "定期定額", "債券", "已領利息",
        "結構型", "台股", "台股折合", "台幣折合美金", "基金", "保險", "總資產", "匯率", "匯入", "匯入累積", "基金成本", "美股成本",
        "定期定額成本", "債券成本", "台股成本", "備註",
        // 多幣別欄位（預設隱藏）
        "歐元", "歐元兌美金匯率", "歐元折合美金",
        "日圓", "日圓兌美金匯率", "日圓折合美金",
        "英鎊", "英鎊兌美金匯率", "英鎊折合美金",
        "人民幣", "人民幣兌美金匯率", "人民幣折合美金",
        "澳幣", "澳幣兌美金匯率", "澳幣折合美金",
        "加幣", "加幣兌美金匯率", "加幣折合美金",
        "瑞士法郎", "瑞士法郎兌美金匯率", "瑞士法郎折合美金",
        "港幣", "港幣兌美金匯率", "港幣折合美金",
        "新加坡幣", "新加坡幣兌美金匯率", "新加坡幣折合美金"
    ]


    private func getColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "日期": return 120
        case "基金": return 110
        case "保險": return 110
        case "台幣": return 110
        case "美金": return 110
        case "美股": return 110
        case "定期定額": return 110
        case "債券": return 110
        case "已領利息": return 110
        case "結構型": return 110
        case "台股": return 110
        case "台股折合": return 110
        case "台幣折合美金": return 120
        case "總資產": return 120
        case "匯率": return 110
        case "匯入": return 110
        case "匯入累積": return 120
        case "基金成本": return 120
        case "美股成本": return 120
        case "定期定額成本": return 130
        case "債券成本": return 120
        case "台股成本": return 120
        case "備註": return 200
        // 多幣別欄位寬度
        case "歐元", "日圓", "英鎊", "人民幣", "澳幣", "加幣", "瑞士法郎", "港幣", "新加坡幣": return 110
        case "歐元兌美金匯率", "日圓兌美金匯率", "英鎊兌美金匯率", "人民幣兌美金匯率",
             "澳幣兌美金匯率", "加幣兌美金匯率", "瑞士法郎兌美金匯率", "港幣兌美金匯率", "新加坡幣兌美金匯率": return 130
        case "歐元折合美金", "日圓折合美金", "英鎊折合美金", "人民幣折合美金",
             "澳幣折合美金", "加幣折合美金", "瑞士法郎折合美金", "港幣折合美金", "新加坡幣折合美金": return 120
        default: return 110
        }
    }

    private func formatNumberString(_ value: String) -> String {
        guard let doubleValue = Double(value),
              !value.contains("-") || value.hasPrefix("-"),
              !value.contains("%"),
              !value.isEmpty else {
            return value
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: doubleValue)) ?? value
    }

    // MARK: - 編輯和刪除功能
    private func deleteAsset(_ asset: MonthlyAsset) {
        withAnimation {
            viewContext.delete(asset)
            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("✅ 月度資產已刪除並同步到 iCloud")
            } catch {
                print("❌ 刪除失敗: \(error)")
            }
        }
    }

    private func deleteLastRow() {
        if let lastAsset = monthlyAssets.last {
            deleteAsset(lastAsset)
        }
    }

    private func addNewRow() {
        guard let client = client else {
            print("❌ 無法新增資料：沒有選中的客戶")
            return
        }

        withAnimation {
            let newAsset = MonthlyAsset(context: viewContext)
            newAsset.client = client

            // 使用當前日期作為預設值
            let now = Date()
            newAsset.createdDate = now

            // 格式化為顯示用的日期字串
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            dateFormatter.locale = Locale(identifier: "en_US")
            newAsset.date = dateFormatter.string(from: now)

            // 取得前一筆記錄的資料作為預設值
            if let previousAsset = monthlyAssets.first {
                // 複製前一筆的資產數據
                newAsset.twdCash = previousAsset.twdCash
                newAsset.cash = previousAsset.cash
                newAsset.usStock = previousAsset.usStock
                newAsset.regularInvestment = previousAsset.regularInvestment
                newAsset.bonds = previousAsset.bonds
                newAsset.confirmedInterest = previousAsset.confirmedInterest
                newAsset.structured = previousAsset.structured
                newAsset.taiwanStock = previousAsset.taiwanStock
                newAsset.taiwanStockFolded = previousAsset.taiwanStockFolded
                newAsset.twdToUsd = previousAsset.twdToUsd
                newAsset.exchangeRate = previousAsset.exchangeRate

                // 複製成本數據
                newAsset.usStockCost = previousAsset.usStockCost
                newAsset.regularInvestmentCost = previousAsset.regularInvestmentCost
                newAsset.bondsCost = previousAsset.bondsCost
                newAsset.taiwanStockCost = previousAsset.taiwanStockCost

                // 備註設為空（不複製）
                newAsset.notes = ""

                // 匯入設為0（不複製前一筆的匯入）
                newAsset.deposit = "0"

                print("📋 複製前一筆資料：日期=\(previousAsset.date ?? "")")
            } else {
                // 如果沒有前一筆記錄，使用空值
                newAsset.twdCash = ""
                newAsset.cash = ""
                newAsset.usStock = ""
                newAsset.regularInvestment = ""
                newAsset.bonds = ""
                newAsset.confirmedInterest = ""
                newAsset.structured = ""
                newAsset.taiwanStock = ""
                newAsset.taiwanStockFolded = ""
                newAsset.twdToUsd = ""
                newAsset.exchangeRate = "32"
                newAsset.usStockCost = ""
                newAsset.regularInvestmentCost = ""
                newAsset.bondsCost = ""
                newAsset.taiwanStockCost = ""
                newAsset.notes = ""
                newAsset.deposit = "0"

                print("📋 新增第一筆資料（無前一筆可複製）")
            }

            // 自動計算總資產
            recalculateTotalAssets(for: newAsset)

            // 自動計算匯入累積
            recalculateDepositAccumulated(for: newAsset)

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("✅ 新增月度資產並同步到 iCloud")
            } catch {
                print("❌ 新增失敗: \(error)")
            }
        }
    }

    // MARK: - 格式化輔助函數
    private func formatNumberWithCommas(_ value: String?) -> String {
        guard let value = value, !value.isEmpty else { return "" }

        // 如果是「日期」或「備註」欄位，直接返回
        if !value.contains(where: { $0.isNumber }) {
            return value
        }

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
        return header != "日期" && header != "備註"
    }

    // MARK: - 綁定函數
    private func bindingForAsset(_ asset: MonthlyAsset, header: String) -> Binding<String> {
        Binding<String>(
            get: {
                let rawValue: String
                switch header {
                case "日期":
                    // 格式化日期為 yyyy/MM/dd 格式
                    if let dateStr = asset.date, !dateStr.isEmpty {
                        // 嘗試解析日期
                        if let date = parseDateString(dateStr) {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy/MM/dd"
                            rawValue = formatter.string(from: date)
                        } else {
                            rawValue = dateStr
                        }
                    } else {
                        rawValue = ""
                    }
                case "基金": rawValue = asset.fund ?? ""
                case "保險": rawValue = asset.insurance ?? ""
                case "台幣": rawValue = asset.twdCash ?? ""
                case "美金": rawValue = asset.cash ?? ""
                case "美股": rawValue = asset.usStock ?? ""
                case "定期定額": rawValue = asset.regularInvestment ?? ""
                case "債券": rawValue = asset.bonds ?? ""
                case "已領利息": rawValue = asset.confirmedInterest ?? ""
                case "結構型": rawValue = asset.structured ?? ""
                case "台股": rawValue = asset.taiwanStock ?? ""
                case "台股折合": rawValue = asset.taiwanStockFolded ?? ""
                case "台幣折合美金": rawValue = asset.twdToUsd ?? ""
                case "總資產": rawValue = asset.totalAssets ?? ""
                case "匯率": rawValue = asset.exchangeRate ?? ""
                case "匯入": rawValue = asset.deposit ?? ""
                case "匯入累積": rawValue = asset.depositAccumulated ?? ""
                case "基金成本": rawValue = asset.fundCost ?? ""
                case "美股成本": rawValue = asset.usStockCost ?? ""
                case "定期定額成本": rawValue = asset.regularInvestmentCost ?? ""
                case "債券成本": rawValue = asset.bondsCost ?? ""
                case "台股成本": rawValue = asset.taiwanStockCost ?? ""
                case "備註": rawValue = asset.notes ?? ""
                // 多幣別欄位
                case "歐元": rawValue = asset.eurCash ?? ""
                case "歐元兌美金匯率": rawValue = asset.eurRate ?? ""
                case "歐元折合美金": rawValue = asset.eurToUsd ?? ""
                case "日圓": rawValue = asset.jpyCash ?? ""
                case "日圓兌美金匯率": rawValue = asset.jpyRate ?? ""
                case "日圓折合美金": rawValue = asset.jpyToUsd ?? ""
                case "英鎊": rawValue = asset.gbpCash ?? ""
                case "英鎊兌美金匯率": rawValue = asset.gbpRate ?? ""
                case "英鎊折合美金": rawValue = asset.gbpToUsd ?? ""
                case "人民幣": rawValue = asset.cnyCash ?? ""
                case "人民幣兌美金匯率": rawValue = asset.cnyRate ?? ""
                case "人民幣折合美金": rawValue = asset.cnyToUsd ?? ""
                case "澳幣": rawValue = asset.audCash ?? ""
                case "澳幣兌美金匯率": rawValue = asset.audRate ?? ""
                case "澳幣折合美金": rawValue = asset.audToUsd ?? ""
                case "加幣": rawValue = asset.cadCash ?? ""
                case "加幣兌美金匯率": rawValue = asset.cadRate ?? ""
                case "加幣折合美金": rawValue = asset.cadToUsd ?? ""
                case "瑞士法郎": rawValue = asset.chfCash ?? ""
                case "瑞士法郎兌美金匯率": rawValue = asset.chfRate ?? ""
                case "瑞士法郎折合美金": rawValue = asset.chfToUsd ?? ""
                case "港幣": rawValue = asset.hkdCash ?? ""
                case "港幣兌美金匯率": rawValue = asset.hkdRate ?? ""
                case "港幣折合美金": rawValue = asset.hkdToUsd ?? ""
                case "新加坡幣": rawValue = asset.sgdCash ?? ""
                case "新加坡幣兌美金匯率": rawValue = asset.sgdRate ?? ""
                case "新加坡幣折合美金": rawValue = asset.sgdToUsd ?? ""
                default: rawValue = ""
                }

                // 如果是數字欄位，加上千分位
                return isNumberField(header) ? formatNumberWithCommas(rawValue) : rawValue
            },
            set: { newValue in
                // 移除千分位後儲存
                let cleanValue = isNumberField(header) ? removeCommas(newValue) : newValue

                switch header {
                case "日期":
                    asset.date = cleanValue
                    // 當日期被修改時，也要更新 createdDate 用於排序
                    if let parsedDate = parseDateString(cleanValue) {
                        asset.createdDate = parsedDate
                    }
                case "基金":
                    asset.fund = cleanValue
                    recalculateTotalAssets(for: asset)
                case "保險":
                    asset.insurance = cleanValue
                    recalculateTotalAssets(for: asset)
                case "台幣":
                    asset.twdCash = cleanValue
                    // 台幣變更時，自動計算台幣折合美金
                    calculateTwdToUsd(for: asset)
                case "美金":
                    asset.cash = cleanValue
                    recalculateTotalAssets(for: asset)
                case "美股":
                    asset.usStock = cleanValue
                    recalculateTotalAssets(for: asset)
                case "定期定額":
                    asset.regularInvestment = cleanValue
                    recalculateTotalAssets(for: asset)
                case "債券":
                    asset.bonds = cleanValue
                    recalculateTotalAssets(for: asset)
                case "已領利息":
                    asset.confirmedInterest = cleanValue
                    // 已領利息不影響總資產，不需要重新計算
                case "結構型":
                    asset.structured = cleanValue
                    recalculateTotalAssets(for: asset)
                case "台股":
                    asset.taiwanStock = cleanValue
                    // 台股變更時，自動計算台股折合
                    calculateTaiwanStockFolded(for: asset)
                case "台股折合":
                    asset.taiwanStockFolded = cleanValue
                    recalculateTotalAssets(for: asset)
                case "台幣折合美金":
                    asset.twdToUsd = cleanValue
                    recalculateTotalAssets(for: asset)
                case "總資產":
                    // 總資產為自動計算，不允許手動修改
                    break
                case "匯率":
                    asset.exchangeRate = cleanValue
                    // 匯率變更時，自動重新計算台股折合和台幣折合美金
                    calculateTaiwanStockFolded(for: asset)
                    calculateTwdToUsd(for: asset)
                case "匯入":
                    asset.deposit = cleanValue
                    recalculateAllDepositAccumulated()
                case "匯入累積":
                    // 匯入累積為自動計算，不允許手動修改
                    break
                case "基金成本": asset.fundCost = cleanValue
                case "美股成本": asset.usStockCost = cleanValue
                case "定期定額成本": asset.regularInvestmentCost = cleanValue
                case "債券成本": asset.bondsCost = cleanValue
                case "台股成本": asset.taiwanStockCost = cleanValue
                case "備註": asset.notes = cleanValue
                // 多幣別欄位（現金金額變更時自動計算折合美金）
                case "歐元":
                    asset.eurCash = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "EUR")
                case "歐元兌美金匯率":
                    asset.eurRate = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "EUR")
                case "歐元折合美金":
                    asset.eurToUsd = cleanValue
                    recalculateTotalAssets(for: asset)
                case "日圓":
                    asset.jpyCash = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "JPY")
                case "日圓兌美金匯率":
                    asset.jpyRate = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "JPY")
                case "日圓折合美金":
                    asset.jpyToUsd = cleanValue
                    recalculateTotalAssets(for: asset)
                case "英鎊":
                    asset.gbpCash = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "GBP")
                case "英鎊兌美金匯率":
                    asset.gbpRate = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "GBP")
                case "英鎊折合美金":
                    asset.gbpToUsd = cleanValue
                    recalculateTotalAssets(for: asset)
                case "人民幣":
                    asset.cnyCash = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "CNY")
                case "人民幣兌美金匯率":
                    asset.cnyRate = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "CNY")
                case "人民幣折合美金":
                    asset.cnyToUsd = cleanValue
                    recalculateTotalAssets(for: asset)
                case "澳幣":
                    asset.audCash = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "AUD")
                case "澳幣兌美金匯率":
                    asset.audRate = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "AUD")
                case "澳幣折合美金":
                    asset.audToUsd = cleanValue
                    recalculateTotalAssets(for: asset)
                case "加幣":
                    asset.cadCash = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "CAD")
                case "加幣兌美金匯率":
                    asset.cadRate = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "CAD")
                case "加幣折合美金":
                    asset.cadToUsd = cleanValue
                    recalculateTotalAssets(for: asset)
                case "瑞士法郎":
                    asset.chfCash = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "CHF")
                case "瑞士法郎兌美金匯率":
                    asset.chfRate = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "CHF")
                case "瑞士法郎折合美金":
                    asset.chfToUsd = cleanValue
                    recalculateTotalAssets(for: asset)
                case "港幣":
                    asset.hkdCash = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "HKD")
                case "港幣兌美金匯率":
                    asset.hkdRate = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "HKD")
                case "港幣折合美金":
                    asset.hkdToUsd = cleanValue
                    recalculateTotalAssets(for: asset)
                case "新加坡幣":
                    asset.sgdCash = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "SGD")
                case "新加坡幣兌美金匯率":
                    asset.sgdRate = cleanValue
                    calculateCurrencyToUsd(for: asset, currency: "SGD")
                case "新加坡幣折合美金":
                    asset.sgdToUsd = cleanValue
                    recalculateTotalAssets(for: asset)
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

    // MARK: - 台股折合自動計算（台股 ÷ 匯率）
    private func calculateTaiwanStockFolded(for asset: MonthlyAsset) {
        let taiwanStockValue = Double(asset.taiwanStock ?? "0") ?? 0
        let exchangeRateValue = Double(asset.exchangeRate ?? "32") ?? 32

        guard exchangeRateValue != 0 else {
            asset.taiwanStockFolded = "0"
            recalculateTotalAssets(for: asset)
            return
        }

        let taiwanStockFolded = taiwanStockValue / exchangeRateValue
        asset.taiwanStockFolded = String(format: "%.2f", taiwanStockFolded)

        // 台股折合變更後，重新計算總資產
        recalculateTotalAssets(for: asset)
    }

    // MARK: - 台幣折合美金自動計算（台幣 ÷ 匯率）
    private func calculateTwdToUsd(for asset: MonthlyAsset) {
        let twdCashValue = Double(asset.twdCash ?? "0") ?? 0
        let exchangeRateValue = Double(asset.exchangeRate ?? "32") ?? 32

        guard exchangeRateValue != 0 else {
            asset.twdToUsd = "0"
            recalculateTotalAssets(for: asset)
            return
        }

        let twdToUsd = twdCashValue / exchangeRateValue
        asset.twdToUsd = String(format: "%.2f", twdToUsd)

        // 台幣折合美金變更後，重新計算總資產
        recalculateTotalAssets(for: asset)
    }

    // MARK: - 多幣別折合美金自動計算（金額 ÷ 匯率）
    private func calculateCurrencyToUsd(for asset: MonthlyAsset, currency: String) {
        let cashValue: Double
        let rateValue: Double

        switch currency {
        case "EUR":
            cashValue = Double(asset.eurCash ?? "0") ?? 0
            rateValue = Double(asset.eurRate ?? "1") ?? 1
        case "JPY":
            cashValue = Double(asset.jpyCash ?? "0") ?? 0
            rateValue = Double(asset.jpyRate ?? "1") ?? 1
        case "GBP":
            cashValue = Double(asset.gbpCash ?? "0") ?? 0
            rateValue = Double(asset.gbpRate ?? "1") ?? 1
        case "CNY":
            cashValue = Double(asset.cnyCash ?? "0") ?? 0
            rateValue = Double(asset.cnyRate ?? "1") ?? 1
        case "AUD":
            cashValue = Double(asset.audCash ?? "0") ?? 0
            rateValue = Double(asset.audRate ?? "1") ?? 1
        case "CAD":
            cashValue = Double(asset.cadCash ?? "0") ?? 0
            rateValue = Double(asset.cadRate ?? "1") ?? 1
        case "CHF":
            cashValue = Double(asset.chfCash ?? "0") ?? 0
            rateValue = Double(asset.chfRate ?? "1") ?? 1
        case "HKD":
            cashValue = Double(asset.hkdCash ?? "0") ?? 0
            rateValue = Double(asset.hkdRate ?? "1") ?? 1
        case "SGD":
            cashValue = Double(asset.sgdCash ?? "0") ?? 0
            rateValue = Double(asset.sgdRate ?? "1") ?? 1
        default:
            return
        }

        guard rateValue != 0 else {
            setCurrencyToUsd(for: asset, currency: currency, value: "0")
            recalculateTotalAssets(for: asset)
            return
        }

        let toUsd = cashValue / rateValue
        let formattedValue = String(format: "%.2f", toUsd)
        setCurrencyToUsd(for: asset, currency: currency, value: formattedValue)

        // 折合美金變更後，重新計算總資產
        recalculateTotalAssets(for: asset)
    }

    // 設置多幣別折合美金值
    private func setCurrencyToUsd(for asset: MonthlyAsset, currency: String, value: String) {
        switch currency {
        case "EUR": asset.eurToUsd = value
        case "JPY": asset.jpyToUsd = value
        case "GBP": asset.gbpToUsd = value
        case "CNY": asset.cnyToUsd = value
        case "AUD": asset.audToUsd = value
        case "CAD": asset.cadToUsd = value
        case "CHF": asset.chfToUsd = value
        case "HKD": asset.hkdToUsd = value
        case "SGD": asset.sgdToUsd = value
        default: break
        }
    }

    // MARK: - 總資產自動計算
    private func recalculateTotalAssets(for asset: MonthlyAsset) {
        let fundValue = Double(asset.fund ?? "0") ?? 0
        let insuranceValue = Double(asset.insurance ?? "0") ?? 0
        let cashValue = Double(asset.cash ?? "0") ?? 0
        let usStockValue = Double(asset.usStock ?? "0") ?? 0
        let regularInvestmentValue = Double(asset.regularInvestment ?? "0") ?? 0
        let bondsValue = Double(asset.bonds ?? "0") ?? 0
        let structuredValue = Double(asset.structured ?? "0") ?? 0
        let taiwanStockFoldedValue = Double(asset.taiwanStockFolded ?? "0") ?? 0
        let twdToUsdValue = Double(asset.twdToUsd ?? "0") ?? 0

        // 多幣別折合美金
        let eurToUsdValue = Double(asset.eurToUsd ?? "0") ?? 0
        let jpyToUsdValue = Double(asset.jpyToUsd ?? "0") ?? 0
        let gbpToUsdValue = Double(asset.gbpToUsd ?? "0") ?? 0
        let cnyToUsdValue = Double(asset.cnyToUsd ?? "0") ?? 0
        let audToUsdValue = Double(asset.audToUsd ?? "0") ?? 0
        let cadToUsdValue = Double(asset.cadToUsd ?? "0") ?? 0
        let chfToUsdValue = Double(asset.chfToUsd ?? "0") ?? 0
        let hkdToUsdValue = Double(asset.hkdToUsd ?? "0") ?? 0
        let sgdToUsdValue = Double(asset.sgdToUsd ?? "0") ?? 0

        let totalAssets = fundValue + insuranceValue + cashValue + usStockValue + regularInvestmentValue +
                        bondsValue + structuredValue + taiwanStockFoldedValue + twdToUsdValue +
                        eurToUsdValue + jpyToUsdValue + gbpToUsdValue + cnyToUsdValue + audToUsdValue +
                        cadToUsdValue + chfToUsdValue + hkdToUsdValue + sgdToUsdValue

        asset.totalAssets = String(format: "%.2f", totalAssets)
    }

    // MARK: - 匯入累積自動計算
    // 重新計算所有記錄的匯入累積（用於手動編輯時）
    private func recalculateAllDepositAccumulated() {
        // 按日期升序排列所有記錄
        let sortedAssets = monthlyAssets
            .filter { $0.createdDate != nil }
            .sorted { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }

        var cumulativeDeposit: Double = 0

        for asset in sortedAssets {
            let currentDeposit = Double(asset.deposit ?? "0") ?? 0
            cumulativeDeposit += currentDeposit
            asset.depositAccumulated = String(format: "%.2f", cumulativeDeposit)

            print("📊 重算匯入累積：日期=\(asset.date ?? ""), 本次匯入=\(currentDeposit), 累積總額=\(cumulativeDeposit)")
        }
    }

    // 計算單筆記錄的匯入累積（用於新增資料時）
    private func recalculateDepositAccumulated(for asset: MonthlyAsset) {
        // 本次匯入金額
        let currentDeposit = Double(asset.deposit ?? "0") ?? 0

        // 找出上一筆記錄（按日期排序）
        guard let currentDate = asset.createdDate else {
            // 如果沒有日期，只設定本次匯入
            asset.depositAccumulated = String(format: "%.2f", currentDeposit)
            return
        }

        // 找出同一客戶的所有記錄，按日期升序排列
        let sortedAssets = monthlyAssets
            .filter { $0.createdDate != nil && $0 != asset }
            .sorted { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }

        // 找出上一筆記錄（日期小於當前記錄的最後一筆）
        let previousAsset = sortedAssets.last { ($0.createdDate ?? Date.distantPast) < currentDate }

        // 上一筆的匯入累積
        let previousDepositAccumulated = Double(previousAsset?.depositAccumulated ?? "0") ?? 0

        // 本次匯入累積 = 本次匯入 + 上一筆匯入累積
        let newDepositAccumulated = currentDeposit + previousDepositAccumulated

        asset.depositAccumulated = String(format: "%.2f", newDepositAccumulated)

        print("📊 計算匯入累積：日期=\(asset.date ?? ""), 本次匯入=\(currentDeposit), 上一筆累積=\(previousDepositAccumulated), 新累積=\(newDepositAccumulated)")
    }

    // 修復所有總資產（重新計算，確保不包含已領利息和台幣）
    private func fixMissingTotalAssets() {
        var needsSave = false

        for asset in monthlyAssets {
            let fundValue = Double(asset.fund ?? "0") ?? 0
            let insuranceValue = Double(asset.insurance ?? "0") ?? 0
            let cashValue = Double(asset.cash ?? "0") ?? 0
            let usStockValue = Double(asset.usStock ?? "0") ?? 0
            let regularInvestmentValue = Double(asset.regularInvestment ?? "0") ?? 0
            let bondsValue = Double(asset.bonds ?? "0") ?? 0
            let structuredValue = Double(asset.structured ?? "0") ?? 0
            let taiwanStockFoldedValue = Double(asset.taiwanStockFolded ?? "0") ?? 0
            let twdToUsdValue = Double(asset.twdToUsd ?? "0") ?? 0

            // 多幣別折合美金
            let eurToUsdValue = Double(asset.eurToUsd ?? "0") ?? 0
            let jpyToUsdValue = Double(asset.jpyToUsd ?? "0") ?? 0
            let gbpToUsdValue = Double(asset.gbpToUsd ?? "0") ?? 0
            let cnyToUsdValue = Double(asset.cnyToUsd ?? "0") ?? 0
            let audToUsdValue = Double(asset.audToUsd ?? "0") ?? 0
            let cadToUsdValue = Double(asset.cadToUsd ?? "0") ?? 0
            let chfToUsdValue = Double(asset.chfToUsd ?? "0") ?? 0
            let hkdToUsdValue = Double(asset.hkdToUsd ?? "0") ?? 0
            let sgdToUsdValue = Double(asset.sgdToUsd ?? "0") ?? 0

            let newTotalAssets = fundValue + insuranceValue + cashValue + usStockValue + regularInvestmentValue +
                            bondsValue + structuredValue + taiwanStockFoldedValue + twdToUsdValue +
                            eurToUsdValue + jpyToUsdValue + gbpToUsdValue + cnyToUsdValue + audToUsdValue +
                            cadToUsdValue + chfToUsdValue + hkdToUsdValue + sgdToUsdValue

            // 重新計算所有記錄的總資產（確保不包含已領利息）
            let oldTotalAssets = Double(asset.totalAssets ?? "0") ?? 0
            if abs(newTotalAssets - oldTotalAssets) > 0.01 {
                asset.totalAssets = String(format: "%.2f", newTotalAssets)
                needsSave = true
                print("🔧 更新總資產：日期=\(asset.date ?? ""), 舊值=\(oldTotalAssets), 新值=\(newTotalAssets)")
            }
        }

        if needsSave {
            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("✅ 已更新所有總資產（已移除已領利息）")
            } catch {
                print("❌ 更新總資產失敗: \(error)")
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
            guard let firstURL = urls.first else { return }

            // 開始存取安全範圍的資源
            guard firstURL.startAccessingSecurityScopedResource() else {
                print("❌ 無法存取檔案")
                return
            }

            defer {
                firstURL.stopAccessingSecurityScopedResource()
            }

            do {
                let csvContent = try String(contentsOf: firstURL, encoding: .utf8)
                parseAndImportCSV(csvContent)
            } catch {
                print("❌ 讀取檔案失敗：\(error.localizedDescription)")
            }

        case .failure(let error):
            print("❌ 檔案選擇失敗：\(error.localizedDescription)")
        }
    }

    // MARK: - CSV 解析和匯入
    private func parseAndImportCSV(_ csvContent: String) {
        guard let client = client else {
            print("❌ 無法匯入資料：沒有選中的客戶")
            return
        }

        let lines = csvContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard lines.count >= 2 else {
            print("❌ CSV 檔案格式錯誤：資料不足")
            return
        }

        // 第一行是表頭
        let headers = parseCSVLine(lines[0])
        print("📋 CSV 表頭：\(headers)")

        // 建立表頭索引映射
        var headerIndexMap: [String: Int] = [:]
        for (index, header) in headers.enumerated() {
            let normalizedHeader = header.trimmingCharacters(in: .whitespaces)
            headerIndexMap[normalizedHeader] = index
        }

        // 驗證必要欄位是否存在
        let requiredHeaders = ["日期"]
        for required in requiredHeaders {
            if headerIndexMap[required] == nil {
                print("❌ CSV 檔案缺少必要欄位：\(required)")
                return
            }
        }

        // 從第二行開始匯入資料
        var importCount = 0
        var newAssets: [MonthlyAsset] = []

        for i in 1..<lines.count {
            let values = parseCSVLine(lines[i])

            // 如果這行是空的，跳過
            if values.allSatisfy({ $0.isEmpty }) {
                continue
            }

            let newAsset = MonthlyAsset(context: viewContext)
            newAsset.client = client

            // 根據表頭映射來設定值
            let dateString = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "日期")
            newAsset.date = dateString

            // 解析日期字串並設定 createdDate，用於排序
            newAsset.createdDate = parseDateString(dateString) ?? Date()

            // 設定各項資產欄位
            let twdCashStr = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "台幣")
            let cashStr = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "美金")
            let usStockStr = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "美股")
            let regularInvestmentStr = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "定期定額")
            let bondsStr = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "債券")
            let confirmedInterestStr = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "已領利息")
            let structuredStr = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "結構型")
            let taiwanStockStr = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "台股")
            let taiwanStockFoldedStr = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "台股折合")
            let twdToUsdStr = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "台幣折合美金")
            let exchangeRateStr = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "匯率")

            newAsset.twdCash = twdCashStr
            newAsset.cash = cashStr
            newAsset.usStock = usStockStr
            newAsset.regularInvestment = regularInvestmentStr
            newAsset.bonds = bondsStr
            newAsset.confirmedInterest = confirmedInterestStr
            newAsset.structured = structuredStr
            newAsset.taiwanStock = taiwanStockStr
            newAsset.taiwanStockFolded = taiwanStockFoldedStr
            newAsset.twdToUsd = twdToUsdStr
            newAsset.exchangeRate = exchangeRateStr

            // 自動計算總資產（不從 CSV 讀取，已領利息和台幣不計入總資產）
            let cashValue = Double(cashStr) ?? 0
            let usStockValue = Double(usStockStr) ?? 0
            let regularInvestmentValue = Double(regularInvestmentStr) ?? 0
            let bondsValue = Double(bondsStr) ?? 0
            let structuredValue = Double(structuredStr) ?? 0
            let taiwanStockFoldedValue = Double(taiwanStockFoldedStr) ?? 0
            let twdToUsdValue = Double(twdToUsdStr) ?? 0

            let totalAssets = cashValue + usStockValue + regularInvestmentValue +
                            bondsValue + structuredValue + taiwanStockFoldedValue + twdToUsdValue

            print("📊 計算總資產: 美金=\(cashValue), 美股=\(usStockValue), 定期定額=\(regularInvestmentValue), 債券=\(bondsValue), 結構型=\(structuredValue), 台股折合=\(taiwanStockFoldedValue), 台幣折合美金=\(twdToUsdValue), 總資產=\(totalAssets)")

            newAsset.totalAssets = String(format: "%.2f", totalAssets)

            // 設定其他欄位
            newAsset.deposit = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "匯入")

            // 先不計算匯入累積，等全部資料都建立後再一起計算
            newAsset.depositAccumulated = "0"

            newAsset.usStockCost = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "美股成本")
            newAsset.regularInvestmentCost = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "定期定額成本")
            newAsset.bondsCost = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "債券成本")
            newAsset.taiwanStockCost = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "台股成本")
            newAsset.notes = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "備註")

            newAssets.append(newAsset)
            importCount += 1
        }

        // 先儲存到 Core Data
        do {
            try viewContext.save()
            print("✅ 已建立 \(importCount) 筆月度資產資料")
        } catch {
            print("❌ 儲存失敗：\(error.localizedDescription)")
            return
        }

        // 按日期排序後重新計算所有匯入累積
        let sortedNewAssets = newAssets.sorted {
            ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast)
        }

        // 結合舊資料和新資料一起計算
        let existingAssets = Array(monthlyAssets)
        print("🔍 現有資料筆數: \(existingAssets.count)")
        print("🔍 新匯入資料筆數: \(sortedNewAssets.count)")

        let allAssets = (existingAssets + sortedNewAssets).sorted {
            ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast)
        }

        print("🔍 合併後總筆數: \(allAssets.count)")

        // 依序計算每一筆的匯入累積
        var cumulativeDeposit: Double = 0
        for (index, asset) in allAssets.enumerated() {
            let currentDeposit = Double(asset.deposit ?? "0") ?? 0
            cumulativeDeposit += currentDeposit

            asset.depositAccumulated = String(format: "%.2f", cumulativeDeposit)

            print("📊 [第\(index+1)筆] 日期=\(asset.date ?? ""), 本次匯入=\(currentDeposit), 累積總額=\(cumulativeDeposit)")
        }

        // 最後再儲存一次，同步到 iCloud
        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 成功匯入 \(importCount) 筆月度資產資料並同步到 iCloud")
        } catch {
            print("❌ 儲存失敗：\(error.localizedDescription)")
        }
    }

    // 解析 CSV 行（處理引號包圍的值）
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }

        result.append(currentField.trimmingCharacters(in: .whitespaces))
        return result
    }

    // 從 CSV 值陣列中獲取指定表頭的值（支援多種可能的表頭名稱）
    private func getValueFromCSV(values: [String], headerMap: [String: Int], header: String) -> String {
        // 嘗試多種可能的表頭名稱
        let possibleHeaders = getPossibleHeaderNames(for: header)

        for possibleHeader in possibleHeaders {
            if let index = headerMap[possibleHeader], index < values.count {
                let value = values[index]
                // 移除數字中的逗號（如果有的話）
                return value.replacingOccurrences(of: ",", with: "")
            }
        }

        return ""
    }

    // 解析日期字串（支援多種格式）
    private func parseDateString(_ dateString: String) -> Date? {
        let trimmed = dateString.trimmingCharacters(in: .whitespaces)

        // 支援的日期格式
        let formatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, yyyy"  // Sep 30, 2025
                formatter.locale = Locale(identifier: "en_US")
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM dd, yyyy"  // Sep 30, 2025
                formatter.locale = Locale(identifier: "en_US")
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"  // 2025-09-30
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy/MM/dd"  // 2025/09/30
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d/yyyy"  // 9/30/2025
                return formatter
            }()
        ]

        // 嘗試每種格式
        for formatter in formatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        return nil
    }

    // 取得可能的表頭名稱（支援別名）
    private func getPossibleHeaderNames(for header: String) -> [String] {
        switch header {
        case "日期": return ["日期", "Date"]
        case "台幣": return ["台幣", "TWD Cash", "TWD"]
        case "美金": return ["美金", "現金", "Cash"]
        case "美股": return ["美股", "US Stock"]
        case "定期定額": return ["定期定額", "Regular Investment"]
        case "債券": return ["債券", "Bonds"]
        case "已領利息": return ["已領利息", "已確利息", "Confirmed Interest"]
        case "結構型": return ["結構型", "Structured", "結構型商品"]
        case "台股": return ["台股", "Taiwan Stock"]
        case "台股折合": return ["台股折合", "Taiwan Stock Folded"]
        case "台幣折合美金": return ["台幣折合美金", "TWD to USD"]
        case "總資產": return ["總資產", "總額", "Total Assets"]
        case "匯率": return ["匯率", "Exchange Rate"]
        case "匯入": return ["匯入", "Deposit"]
        case "匯入累積": return ["匯入累積", "Deposit Accumulated"]
        case "美股成本": return ["美股成本", "US Stock Cost"]
        case "定期定額成本": return ["定期定額成本", "Regular Investment Cost"]
        case "債券成本": return ["債券成本", "Bonds Cost"]
        case "台股成本": return ["台股成本", "Taiwan Stock Cost"]
        case "備註": return ["備註", "Notes"]
        default: return [header]
        }
    }
}

#Preview {
    MonthlyAssetDetailView(monthlyData: .constant([]), client: nil)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .padding()
}