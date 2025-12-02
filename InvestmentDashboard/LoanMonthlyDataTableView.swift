//
//  LoanMonthlyDataTableView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/11/11.
//

import SwiftUI
import CoreData

struct LoanMonthlyDataTableView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var monthlyDataList: FetchedResults<LoanMonthlyData>

    let client: Client
    @State private var showingAddData = false
    @State private var editingData: LoanMonthlyData?
    @State private var isExpanded: Bool = true
    @State private var sortColumn: String = "日期"
    @State private var sortAscending: Bool = false
    @State private var showingColumnReorder = false
    @State private var columnOrder: [String] = []

    init(client: Client) {
        self.client = client
        _monthlyDataList = FetchRequest<LoanMonthlyData>(
            sortDescriptors: [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)],
            predicate: NSPredicate(format: "client == %@", client),
            animation: .default
        )
    }

    private let defaultHeaders = [
        "日期", "貸款類型", "貸款金額", "已動用貸款", "已動用累積",
        "台股", "美股", "債券", "定期定額",
        "台股成本", "美股成本", "債券成本", "定期定額成本",
        "匯率", "美股加債券折合台幣", "投資總額"
    ]

    private var currentColumnOrder: [String] {
        if columnOrder.isEmpty {
            return defaultHeaders
        }
        return columnOrder
    }

    var body: some View {
        VStack(spacing: 0) {
            // 工具列
            toolBar

            // 表格內容（始終顯示表頭）
            tableView
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
        .sheet(isPresented: $showingAddData) {
            AddLoanMonthlyDataView(client: client, dataToEdit: editingData)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingColumnReorder) {
            ColumnReorderView(
                headers: defaultHeaders,
                initialOrder: columnOrder.isEmpty ? defaultHeaders : columnOrder,
                onSave: { newOrder in
                    columnOrder = newOrder
                    UserDefaults.standard.set(newOrder, forKey: "LoanMonthlyData_ColumnOrder")
                }
            )
        }
        .onChange(of: showingAddData) { oldValue, newValue in
            if !newValue {
                editingData = nil
            }
        }
        .onAppear {
            if let savedOrder = UserDefaults.standard.array(forKey: "LoanMonthlyData_ColumnOrder") as? [String], !savedOrder.isEmpty {
                columnOrder = savedOrder
            }
        }
    }

    // MARK: - 工具列
    private var toolBar: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                Text("貸款/投資月度管理")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

            Spacer()

            HStack(spacing: 8) {
                // 收合/展開按鈕
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }

                // 排序按鈕（開啟欄位排序）
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

                // 分享按鈕
                Button(action: {
                    // 分享功能（待實作）
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }

                // 綠色 + 按鈕（新增空白行）
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

                // 新增按鈕（藍色，開啟表單）
                Button(action: {
                    editingData = nil
                    showingAddData = true
                }) {
                    Text("新增")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            VStack {
                Spacer()
                Divider()
            }
        )
    }

    // MARK: - 表格視圖
    private var tableView: some View {
        Group {
            if isExpanded {
                // 橫向滾動包裹整個表格（表頭和資料連動）
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(spacing: 0) {
                        // 固定表頭
                        HStack(spacing: 0) {
                            // 刪除欄位（空白）
                            Text("")
                                .frame(width: 40, height: 44)

                            ForEach(currentColumnOrder, id: \.self) { header in
                                Button(action: {
                                    toggleSort(for: header)
                                }) {
                                    HStack(spacing: 4) {
                                        Text(header)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                                        if sortColumn == header {
                                            Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 10))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .frame(minWidth: getColumnWidth(for: header), alignment: .leading)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

                        // 資料區域
                        if monthlyDataList.isEmpty {
                            // 空狀態提示
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))

                                Text("尚無月度數據")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                        } else {
                            // 資料行（僅垂直滾動）
                            ScrollView(.vertical, showsIndicators: true) {
                                LazyVStack(spacing: 0) {
                                    ForEach(Array(sortedData().enumerated()), id: \.element.objectID) { index, data in
                                        dataRow(data: data, index: index)
                                            .onTapGesture {
                                                editingData = data
                                                showingAddData = true
                                            }
                                            .contextMenu {
                                                Button(action: {
                                                    editingData = data
                                                    showingAddData = true
                                                }) {
                                                    Label("編輯", systemImage: "pencil")
                                                }

                                                Button(role: .destructive, action: {
                                                    deleteData(data)
                                                }) {
                                                    Label("刪除", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                            .frame(maxHeight: 350)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 數據行
    private func dataRow(data: LoanMonthlyData, index: Int) -> some View {
        HStack(spacing: 0) {
            // 刪除按鈕
            Button(action: {
                deleteData(data)
            }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(PlainButtonStyle())

            // 根據 currentColumnOrder 動態渲染欄位
            ForEach(currentColumnOrder, id: \.self) { header in
                cellView(for: header, data: data)
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

    // MARK: - 欄位視圖
    @ViewBuilder
    private func cellView(for header: String, data: LoanMonthlyData) -> some View {
        let defaultColor = Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0))
        let greenColor = Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0))

        switch header {
        case "日期":
            Text(data.date ?? "")
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "貸款類型":
            Text(data.loanType ?? "")
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "貸款金額":
            Text(formatNumber(data.loanAmount ?? ""))
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "已動用貸款":
            Text(formatNumber(data.usedLoanAmount ?? ""))
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "已動用累積":
            Text(formatNumber(data.usedLoanAccumulated ?? ""))
                .font(.system(size: 12))
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "台股":
            Text(formatNumber(data.taiwanStock ?? ""))
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "美股":
            Text(formatNumber(data.usStock ?? ""))
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "債券":
            Text(formatNumber(data.bonds ?? ""))
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "定期定額":
            Text(formatNumber(data.regularInvestment ?? ""))
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "台股成本":
            Text(formatNumber(data.taiwanStockCost ?? ""))
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "美股成本":
            Text(formatNumber(data.usStockCost ?? ""))
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "債券成本":
            Text(formatNumber(data.bondsCost ?? ""))
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "定期定額成本":
            Text(formatNumber(data.regularInvestmentCost ?? ""))
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "匯率":
            Text(data.exchangeRate ?? "32")
                .font(.system(size: 12))
                .foregroundColor(defaultColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "美股加債券折合台幣":
            Text(formatNumber(data.usStockBondsInTwd ?? ""))
                .font(.system(size: 12))
                .foregroundColor(greenColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        case "投資總額":
            Text(formatNumber(data.totalInvestment ?? ""))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(greenColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

        default:
            Text("")
                .frame(minWidth: getColumnWidth(for: header), alignment: .leading)
        }
    }

    // MARK: - 輔助函數
    private func getColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "日期": return 90
        case "貸款類型": return 100
        case "貸款金額", "已動用貸款", "已動用累積": return 110
        case "台股", "美股", "債券", "定期定額": return 90
        case "台股成本", "美股成本", "債券成本", "定期定額成本": return 100
        case "匯率": return 60
        case "美股加債券折合台幣": return 140
        case "投資總額": return 110
        default: return 100
        }
    }

    private func formatNumber(_ value: String) -> String {
        guard let doubleValue = Double(value),
              !value.isEmpty else {
            return value
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: doubleValue)) ?? value
    }

    private func deleteData(_ data: LoanMonthlyData) {
        withAnimation {
            viewContext.delete(data)
            do {
                try viewContext.save()
                PersistenceController.shared.save()
            } catch {
                print("Delete error: \(error)")
            }
        }
    }

    // MARK: - 新增空白行（預填前一筆資料）
    private func addNewRow() {
        withAnimation {
            let newData = LoanMonthlyData(context: viewContext)

            // 設定今天的日期
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            newData.date = dateFormatter.string(from: Date())

            // 查詢最新一筆資料並預填
            let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "client == %@", client)
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
            fetchRequest.fetchLimit = 1

            if let latestData = try? viewContext.fetch(fetchRequest).first {
                // 預填投資資產數據（不包含貸款資訊）
                newData.taiwanStock = latestData.taiwanStock ?? ""
                newData.usStock = latestData.usStock ?? ""
                newData.bonds = latestData.bonds ?? ""
                newData.regularInvestment = latestData.regularInvestment ?? ""
                newData.taiwanStockCost = latestData.taiwanStockCost ?? ""
                newData.usStockCost = latestData.usStockCost ?? ""
                newData.bondsCost = latestData.bondsCost ?? ""
                newData.regularInvestmentCost = latestData.regularInvestmentCost ?? ""
                newData.exchangeRate = latestData.exchangeRate ?? "32"
            } else {
                // 沒有前一筆資料，設定預設值
                newData.taiwanStock = ""
                newData.usStock = ""
                newData.bonds = ""
                newData.regularInvestment = ""
                newData.taiwanStockCost = ""
                newData.usStockCost = ""
                newData.bondsCost = ""
                newData.regularInvestmentCost = ""
                newData.exchangeRate = "32"
            }

            // 貸款相關欄位設為空（需要用戶選擇貸款）
            newData.loanType = ""
            newData.loanAmount = ""
            newData.usedLoanAmount = ""
            newData.usedLoanAccumulated = ""

            // 計算結果欄位設為空
            newData.usStockBondsInTwd = ""
            newData.totalInvestment = ""

            newData.createdDate = Date()
            newData.client = client

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("已成功新增行並預填前一筆資料")
            } catch {
                print("Add row error: \(error)")
            }
        }
    }

    // MARK: - 排序功能
    private func toggleSort(for column: String) {
        if sortColumn == column {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = true
        }
    }

    private func sortedData() -> [LoanMonthlyData] {
        let data = Array(monthlyDataList)

        return data.sorted { data1, data2 in
            let result: Bool
            switch sortColumn {
            case "日期":
                result = (data1.date ?? "") < (data2.date ?? "")
            case "貸款類型":
                result = (data1.loanType ?? "") < (data2.loanType ?? "")
            case "貸款金額":
                result = (Double(data1.loanAmount ?? "0") ?? 0) < (Double(data2.loanAmount ?? "0") ?? 0)
            case "已動用貸款":
                result = (Double(data1.usedLoanAmount ?? "0") ?? 0) < (Double(data2.usedLoanAmount ?? "0") ?? 0)
            case "已動用累積":
                result = (Double(data1.usedLoanAccumulated ?? "0") ?? 0) < (Double(data2.usedLoanAccumulated ?? "0") ?? 0)
            case "台股":
                result = (Double(data1.taiwanStock ?? "0") ?? 0) < (Double(data2.taiwanStock ?? "0") ?? 0)
            case "美股":
                result = (Double(data1.usStock ?? "0") ?? 0) < (Double(data2.usStock ?? "0") ?? 0)
            case "債券":
                result = (Double(data1.bonds ?? "0") ?? 0) < (Double(data2.bonds ?? "0") ?? 0)
            case "定期定額":
                result = (Double(data1.regularInvestment ?? "0") ?? 0) < (Double(data2.regularInvestment ?? "0") ?? 0)
            case "台股成本":
                result = (Double(data1.taiwanStockCost ?? "0") ?? 0) < (Double(data2.taiwanStockCost ?? "0") ?? 0)
            case "美股成本":
                result = (Double(data1.usStockCost ?? "0") ?? 0) < (Double(data2.usStockCost ?? "0") ?? 0)
            case "債券成本":
                result = (Double(data1.bondsCost ?? "0") ?? 0) < (Double(data2.bondsCost ?? "0") ?? 0)
            case "定期定額成本":
                result = (Double(data1.regularInvestmentCost ?? "0") ?? 0) < (Double(data2.regularInvestmentCost ?? "0") ?? 0)
            case "匯率":
                result = (Double(data1.exchangeRate ?? "32") ?? 32) < (Double(data2.exchangeRate ?? "32") ?? 32)
            case "美股加債券折合台幣":
                result = (Double(data1.usStockBondsInTwd ?? "0") ?? 0) < (Double(data2.usStockBondsInTwd ?? "0") ?? 0)
            case "投資總額":
                result = (Double(data1.totalInvestment ?? "0") ?? 0) < (Double(data2.totalInvestment ?? "0") ?? 0)
            default:
                result = (data1.date ?? "") < (data2.date ?? "")
            }

            return sortAscending ? result : !result
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let client = Client(context: context)
    client.name = "測試客戶"

    return LoanMonthlyDataTableView(client: client)
        .environment(\.managedObjectContext, context)
}
