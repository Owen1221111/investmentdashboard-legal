import SwiftUI
import UniformTypeIdentifiers

struct MonthlyAssetTableView: View {
    @State private var selectedTab = 0
    // 移除了 structuredProducts，現在使用 StructuredProductsDetailView
    // 移除了結構型商品相關的狀態變數

    private let tabs = ["月度資產", "公司債", "損益表"]
    let monthlyData: [[String]]
    let bondData: [[String]]

    init(monthlyData: [[String]] = [], bondData: [[String]] = []) {
        self.monthlyData = monthlyData.isEmpty ? defaultMonthlyAssetData : monthlyData
        self.bondData = bondData.isEmpty ? defaultBondData : bondData
    }

    var body: some View {
        VStack(spacing: 16) {
            // 主要表格容器
            VStack(spacing: 0) {
                // 標籤切換
                tabHeader

                // 工具列
                toolBar

                // 表格內容
                TabView(selection: $selectedTab) {
                    // 月度資產明細
                    monthlyAssetTable
                        .tag(0)

                    // 公司債明細
                    corporateBondsTable
                        .tag(1)

                    // 損益表
                    pnlTable
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: calculateTableHeight())
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

            // 結構型明細已移除，現在使用 StructuredProductsDetailView
        }
    }

    // MARK: - 標籤切換
    private var tabHeader: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 0) {
                        Text(tabs[index])
                            .font(.system(size: 14, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundColor(selectedTab == index ? Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)) : Color.gray)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)

                        Rectangle()
                            .fill(selectedTab == index ? Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)) : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            Spacer()
        }
        .background(
            VStack {
                Spacer()
                Divider()
            }
        )
    }

    // MARK: - 工具列
    private var toolBar: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                Text(getTableTitle())
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

            Spacer()

            HStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }

                Button(action: {}) {
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
        .background(
            VStack {
                Spacer()
                Divider()
            }
        )
    }

    private func getTableTitle() -> String {
        switch selectedTab {
        case 0: return "月度資產明細"
        case 1: return "公司債明細"
        case 2: return "損益表"
        default: return "月度資產明細"
        }
    }

    // MARK: - 月度資產明細表格
    private var monthlyAssetTable: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                // 表頭
                HStack(spacing: 0) {
                    ForEach(monthlyAssetHeaders, id: \.self) { header in
                        Text(header)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .frame(minWidth: getColumnWidth(for: header), alignment: .leading)
                    }
                }
                .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

                // 分隔線
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)

                // 資料行容器
                VStack(spacing: 0) {
                    ForEach(monthlyData.indices, id: \.self) { index in
                        HStack(spacing: 0) {
                            ForEach(Array(monthlyData[index].enumerated()), id: \.offset) { colIndex, value in
                                Text(formatNumberString(value))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 10)
                                    .frame(minWidth: getColumnWidth(for: monthlyAssetHeaders[colIndex]), alignment: .leading)
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
        }
    }

    // MARK: - 公司債明細表格
    private var corporateBondsTable: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0) {
                // 表頭
                HStack(spacing: 0) {
                    ForEach(bondHeaders, id: \.self) { header in
                        Text(header)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .frame(minWidth: getBondColumnWidth(for: header), alignment: .leading)
                    }
                }
                .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

                // 資料行
                ForEach(bondData.indices, id: \.self) { index in
                    HStack(spacing: 0) {
                        ForEach(Array(bondData[index].enumerated()), id: \.offset) { colIndex, value in
                            Text(value)
                                .font(.system(size: 12))
                                .foregroundColor(
                                    value.contains("+") ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) :
                                    value.contains("-") ? Color(.init(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)) :
                                    Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0))
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 10)
                                .frame(minWidth: getBondColumnWidth(for: bondHeaders[colIndex]), alignment: .leading)
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
    }

    // MARK: - 損益表
    private var pnlTable: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0) {
                // 表頭
                HStack(spacing: 0) {
                    ForEach(pnlHeaders, id: \.self) { header in
                        Text(header)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .frame(minWidth: 100, alignment: .leading)
                    }
                }
                .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

                // 資料行
                ForEach(pnlData.indices, id: \.self) { index in
                    HStack(spacing: 0) {
                        ForEach(Array(pnlData[index].enumerated()), id: \.offset) { colIndex, value in
                            Text(value)
                                .font(.system(size: 13))
                                .foregroundColor(
                                    value.contains("+") ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) :
                                    Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0))
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .frame(minWidth: 100, alignment: .leading)
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
    }

    // MARK: - 資料和輔助函數
    private let monthlyAssetHeaders = [
        "日期", "基金", "保險", "美金", "美股", "定期定額", "債券", "結構型商品",
        "台股", "台股折合", "已確利息", "匯入", "基金成本", "美股成本", "定期定額成本",
        "債券成本", "台股成本", "備註", "總資產"
    ]

    private let defaultMonthlyAssetData = [
        ["Sep-10", "2005", "6317.80", "10115.02", "15400.67", "215408.5", "0.0", "186501.0", "5703.15695", "13952.5", "6000.00", "9800.00", "15000.00", "0.0", "最新記錄", "260945.97"],
        ["Aug-08", "2105", "6420.15", "10205.30", "15500.20", "218500.0", "0.0", "187200.0", "5750.25", "14000.0", "6100.00", "9900.00", "15100.00", "0.0", "八月記錄", "264661.40"],
        ["Aug-09", "2200", "6525.30", "10295.75", "15600.85", "220000.0", "0.0", "188000.0", "5800.50", "14150.0", "6200.00", "10000.00", "15200.00", "0.0", "備註", "268372.70"]
    ]

    private let bondHeaders = [
        "申購日", "債券名稱", "票面利率", "殖利率", "申購價", "持有面額",
        "前手息", "申購金額", "交易金額", "現值", "已領利息", "報酬率",
        "配息月份", "單次配息", "年度配息"
    ]

    private let defaultBondData = [
        ["Mar-6", "2030債券", "5.2%", "2.34%", "100.00", "200,000", "1,500", "200,000", "201,500", "200,000.00", "3,104.0", "+7.84%", "3月/9月", "5,200", "10,400"],
        ["Apr-15", "2028債券", "4.8%", "3.1%", "102.50", "150,000", "800", "153,750", "154,550", "151,200.00", "2,400.0", "-0.1%", "4月/10月", "3,600", "7,200"],
        ["Jun-20", "2032債券", "6.0%", "2.8%", "98.75", "300,000", "2,200", "296,250", "298,450", "305,400.00", "4,500.0", "+4.61%", "6月/12月", "9,000", "18,000"]
    ]

    private let pnlHeaders = ["交易日期", "資產", "買入價格", "賣出價格", "損益", "手續費"]

    private let pnlData = [
        ["2024/12/01", "AAPL", "150.00", "165.50", "+15.50", "2.50"],
        ["2024/11/28", "MSFT", "280.00", "275.20", "-4.80", "2.50"],
        ["2024/11/25", "GOOGL", "132.50", "138.75", "+6.25", "2.50"]
    ]

    private func getColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "日期": return 70
        case "基金", "保險": return 80
        case "美金", "美股", "債券": return 80
        case "結構型商品": return 100
        case "台股折合", "已確利息": return 90
        case "基金成本", "美股成本", "定期定額成本", "債券成本", "台股成本": return 85
        case "備註": return 120
        case "總資產": return 100
        default: return 80
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

    private func getBondColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "申購日": return 70
        case "債券名稱": return 100
        case "票面利率", "殖利率", "報酬率": return 70
        case "申購價": return 70
        case "持有面額", "申購金額", "交易金額", "現值": return 90
        case "前手息", "已領利息", "單次配息", "年度配息": return 80
        case "配息月份": return 90
        default: return 80
        }
    }

    private func calculateTableHeight() -> CGFloat {
        let headerHeight: CGFloat = 45  // 表頭高度
        let rowHeight: CGFloat = 35     // 每行高度
        let emptyStateHeight: CGFloat = 200  // 空狀態高度

        switch selectedTab {
        case 0:  // 月度資產明細
            if monthlyData.isEmpty {
                return emptyStateHeight
            }
            return headerHeight + CGFloat(monthlyData.count) * rowHeight + 2  // +2 for divider
        case 1:  // 公司債明細
            if bondData.isEmpty {
                return emptyStateHeight
            }
            return headerHeight + CGFloat(bondData.count) * rowHeight + 2
        case 2:  // 損益表
            if pnlData.isEmpty {
                return emptyStateHeight
            }
            return headerHeight + CGFloat(pnlData.count) * rowHeight + 2
        default:
            return 300
        }
    }
}
