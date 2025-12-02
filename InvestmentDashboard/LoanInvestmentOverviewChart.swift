//
//  LoanInvestmentOverviewChart.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/11/13.
//

import SwiftUI
import CoreData

struct LoanInvestmentOverviewChart: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var monthlyDataList: FetchedResults<LoanMonthlyData>

    let client: Client
    @State private var chartType: ChartType = .usedLoanVsInvestment
    @State private var isExpanded: Bool = true

    enum ChartType: String, CaseIterable {
        case usedLoanVsInvestment = "已動用累積/投資總額"
        case totalLoanVsInvestment = "貸款總額/投資總額"
    }

    init(client: Client) {
        self.client = client
        _monthlyDataList = FetchRequest<LoanMonthlyData>(
            sortDescriptors: [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: true)],
            predicate: NSPredicate(format: "client == %@", client),
            animation: .default
        )
    }

    // 計算貸款總額
    private var totalLoanAmount: Double {
        guard let loans = client.loans as? Set<Loan> else { return 0 }

        return loans.reduce(0.0) { total, loan in
            if let loanAmount = loan.loanAmount,
               let amount = Double(loanAmount) {
                return total + amount
            }
            return total
        }
    }

    // 準備圖表數據
    private var chartData: [(date: String, value1: Double, value2: Double)] {
        let sortedData = monthlyDataList.sorted { ($0.date ?? "") < ($1.date ?? "") }

        return sortedData.map { data in
            let value1: Double
            if chartType == .usedLoanVsInvestment {
                value1 = Double(data.usedLoanAccumulated ?? "0") ?? 0
            } else {
                value1 = totalLoanAmount
            }
            let value2 = Double(data.totalInvestment ?? "0") ?? 0

            return (date: formatDate(data.date ?? ""), value1: value1, value2: value2)
        }
    }

    // 格式化日期顯示
    private func formatDate(_ dateString: String) -> String {
        let components = dateString.split(separator: "-")
        if components.count >= 2 {
            return "\(components[0])/\(components[1])"
        }
        return dateString
    }

    var body: some View {
        VStack(spacing: 0) {
            // 工具列
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 14))
                    Text("貸款/投資總覽")
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

                    // 圖表類型選擇下拉選單
                    Menu {
                        ForEach(ChartType.allCases, id: \.self) { type in
                            Button(action: {
                                withAnimation {
                                    chartType = type
                                }
                            }) {
                                HStack {
                                    Text(type.rawValue)
                                    if chartType == type {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(chartType.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                        }
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

            // 圖表內容
            if isExpanded {
                VStack(spacing: 16) {
                    if chartData.isEmpty {
                        // 空狀態
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("尚無數據")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("請先在月度管理中新增數據")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                    } else {
                        // 圖例
                        HStack(spacing: 20) {
                            // 第一條線圖例
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(chartType == .usedLoanVsInvestment ? Color.orange : Color.blue)
                                    .frame(width: 10, height: 10)
                                Text(chartType == .usedLoanVsInvestment ? "已動用累積" : "貸款總額")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // 第二條線圖例
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                Text("投資總額")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // 漸層風格線圖
                        GradientLineChartView(
                            data: chartData,
                            color1: chartType == .usedLoanVsInvestment ? .orange : .blue,
                            color2: .green
                        )
                        .frame(height: 200)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - 漸層風格線圖視圖
struct GradientLineChartView: View {
    let data: [(date: String, value1: Double, value2: Double)]
    let color1: Color
    let color2: Color

    private var maxValue: Double {
        let allValues = data.flatMap { [$0.value1, $0.value2] }
        return allValues.max() ?? 1
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let points1 = generatePoints(values: data.map { $0.value1 }, width: width, height: height)
            let points2 = generatePoints(values: data.map { $0.value2 }, width: width, height: height)

            ZStack {
                // 第一條線的漸層填充區域
                fillArea(points: points1, height: height, color: color1)

                // 第二條線的漸層填充區域
                fillArea(points: points2, height: height, color: color2)

                // 第一條漸層線條
                gradientLine(points: points1, color: color1)

                // 第二條漸層線條
                gradientLine(points: points2, color: color2)

                // X 軸標籤
                HStack(spacing: 0) {
                    ForEach(0..<min(data.count, 5), id: \.self) { index in
                        let step = max(data.count / 5, 1)
                        let dataIndex = index * step
                        if dataIndex < data.count {
                            Text(data[dataIndex].date)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .offset(y: height - 10)
            }
        }
    }

    // 填充區域
    private func fillArea(points: [CGPoint], height: CGFloat, color: Color) -> some View {
        var path = Path()
        if !points.isEmpty {
            path.move(to: CGPoint(x: points[0].x, y: height))
            path.addLine(to: points[0])

            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            path.addLine(to: CGPoint(x: points.last!.x, y: height))
            path.closeSubpath()
        }

        return path.fill(
            LinearGradient(
                gradient: Gradient(colors: [
                    color.opacity(0.3),
                    color.opacity(0.02)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // 漸層線條
    private func gradientLine(points: [CGPoint], color: Color) -> some View {
        var path = Path()
        if !points.isEmpty {
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }

        return path.stroke(
            LinearGradient(
                gradient: Gradient(colors: [
                    color,
                    color.opacity(0.7)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            lineWidth: 2.5
        )
    }

    private func generatePoints(values: [Double], width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard !values.isEmpty else { return [] }

        // 歸一化數據到 0-1 範圍
        let minVal = min(values.min() ?? 0, 0)  // 確保最小值至少為 0
        let maxVal = maxValue
        let range = maxVal - minVal

        let normalizedValues = values.map { value -> CGFloat in
            if range > 0 {
                return CGFloat((value - minVal) / range)
            } else {
                return 0.5
            }
        }

        let stepX = width / CGFloat(max(values.count - 1, 1))

        return normalizedValues.enumerated().map { index, value in
            CGPoint(
                x: CGFloat(index) * stepX,
                y: height - (value * height * 0.85) - (height * 0.1)  // 留出上下邊距
            )
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let client = Client(context: context)
    client.name = "測試客戶"

    return LoanInvestmentOverviewChart(client: client)
        .environment(\.managedObjectContext, context)
        .padding()
        .background(Color(.systemGroupedBackground))
}
