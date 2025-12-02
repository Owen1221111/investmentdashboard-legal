import Foundation

// MARK: - Calculation Service
class CalculationService {
    
    // MARK: - Singleton
    static let shared = CalculationService()
    private init() {}
    
    // MARK: - Main Calculation Methods
    
    /// 從月度記錄計算完整指標
    func calculateMetrics(from records: [MonthlyAssetRecord]) -> CalculatedMetrics {
        return CalculatedMetrics(from: records)
    }
    
    /// 計算總資產 (從記錄陣列)
    func calculateTotalAssets(from records: [MonthlyAssetRecord]) -> Double {
        guard let latestRecord = records.sorted(by: { $0.date > $1.date }).first else {
            return 0
        }
        return latestRecord.totalAssets
    }
    
    /// 計算總損益
    func calculateTotalPnL(from records: [MonthlyAssetRecord]) -> (amount: Double, percentage: Double) {
        guard let latestRecord = records.sorted(by: { $0.date > $1.date }).first else {
            return (0, 0)
        }
        return (latestRecord.totalPnL, latestRecord.totalPnLPercentage)
    }
    
    /// 計算資產配置百分比
    func calculateAssetAllocation(from record: MonthlyAssetRecord) -> AssetAllocation {
        return AssetAllocation(from: record)
    }
    
    // MARK: - Chart Data Generation
    
    /// 生成圓餅圖數據 (資產配置)
    func generatePieChartData(from record: MonthlyAssetRecord) -> [ChartDataPoint] {
        let allocation = AssetAllocation(from: record)
        
        let chartData = [
            ChartDataPoint(name: "美股", value: allocation.usStockPercentage, color: "#1f77b4"),
            ChartDataPoint(name: "債券", value: allocation.bondsPercentage, color: "#ff7f0e"),
            ChartDataPoint(name: "現金", value: allocation.cashPercentage, color: "#2ca02c"),
            ChartDataPoint(name: "台股", value: allocation.twStockPercentage, color: "#d62728"),
            ChartDataPoint(name: "結構型", value: allocation.structuredPercentage, color: "#9467bd")
        ]
        
        // 只回傳有值的項目，並按百分比排序
        return chartData.filter { $0.value > 0.1 }.sorted { $0.value > $1.value }
    }
    
    /// 生成線圖數據 (總資產趨勢)
    func generateLineChartData(from records: [MonthlyAssetRecord]) -> [MonthlyTrendPoint] {
        let sortedRecords = records.sorted { $0.date < $1.date }
        
        return sortedRecords.map { record in
            MonthlyTrendPoint(
                date: record.date,
                totalAssets: record.totalAssets,
                totalPnL: record.totalPnL
            )
        }
    }
    
    /// 生成柱狀圖數據 (月度配息) - 根據文檔需求
    func generateDividendChartData(from records: [MonthlyAssetRecord]) -> [DividendDataPoint] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        // 建立12個月的配息數據
        var monthlyDividends: [DividendDataPoint] = []
        
        for month in 1...12 {
            let dividendAmount = calculateMonthlyDividend(
                for: month,
                year: currentYear,
                from: records
            )
            
            let monthName = DateFormatter().shortMonthSymbols[month - 1]
            monthlyDividends.append(
                DividendDataPoint(
                    month: monthName,
                    amount: dividendAmount,
                    year: currentYear
                )
            )
        }
        
        return monthlyDividends
    }
    
    // MARK: - Advanced Calculations
    
    /// 計算月度配息 (預估)
    private func calculateMonthlyDividend(for month: Int, year: Int, from records: [MonthlyAssetRecord]) -> Double {
        guard let latestRecord = records.sorted(by: { $0.date > $1.date }).first else {
            return 0
        }
        
        // 簡化計算：債券年配息率 3-5%，按月分配
        let bondsDividendRate = 0.04 // 4% 年配息率
        let monthlyBondsDividend = (latestRecord.bonds * bondsDividendRate) / 12
        
        // 美股配息 (部分股票有配息)
        let stockDividendRate = 0.02 // 2% 年配息率
        let monthlyStockDividend = (latestRecord.usStock * stockDividendRate) / 12
        
        return monthlyBondsDividend + monthlyStockDividend
    }
    
    /// 計算年度總配息
    func calculateAnnualDividend(from records: [MonthlyAssetRecord]) -> Double {
        let monthlyDividends = generateDividendChartData(from: records)
        return monthlyDividends.reduce(0) { $0 + $1.amount }
    }
    
    /// 計算投資報酬率 (時間範圍)
    func calculateReturnRate(
        from records: [MonthlyAssetRecord],
        period: TimePeriod
    ) -> Double {
        let sortedRecords = records.sorted { $0.date < $1.date }
        guard sortedRecords.count >= 2 else { return 0 }
        
        let endDate = Date()
        let startDate = period.startDate(from: endDate)
        
        // 找到期間內的記錄
        let periodRecords = sortedRecords.filter { record in
            record.date >= startDate && record.date <= endDate
        }
        
        guard let firstRecord = periodRecords.first,
              let lastRecord = periodRecords.last,
              firstRecord.totalCost > 0 else {
            return 0
        }
        
        let totalReturn = lastRecord.totalAssets - firstRecord.totalCost
        return (totalReturn / firstRecord.totalCost) * 100
    }
    
    /// 計算風險指標 (變異數)
    func calculateVolatility(from records: [MonthlyAssetRecord]) -> Double {
        let returns = calculateMonthlyReturns(from: records)
        guard returns.count > 1 else { return 0 }
        
        let meanReturn = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - meanReturn, 2) }.reduce(0, +) / Double(returns.count)
        
        return sqrt(variance) * 100 // 轉為百分比
    }
    
    /// 計算月度報酬率陣列
    private func calculateMonthlyReturns(from records: [MonthlyAssetRecord]) -> [Double] {
        let sortedRecords = records.sorted { $0.date < $1.date }
        guard sortedRecords.count >= 2 else { return [] }
        
        var returns: [Double] = []
        
        for i in 1..<sortedRecords.count {
            let previousValue = sortedRecords[i-1].totalAssets
            let currentValue = sortedRecords[i].totalAssets
            
            if previousValue > 0 {
                let returnRate = ((currentValue - previousValue) / previousValue) * 100
                returns.append(returnRate)
            }
        }
        
        return returns
    }
    
    // MARK: - Utility Methods
    
    /// 格式化金額 (台幣)
    func formatCurrency(_ amount: Double, locale: Locale = Locale(identifier: "zh_TW")) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: amount)) ?? "NT$0"
    }
    
    /// 格式化百分比
    func formatPercentage(_ value: Double, decimalPlaces: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = decimalPlaces
        formatter.minimumFractionDigits = decimalPlaces
        
        return formatter.string(from: NSNumber(value: value / 100)) ?? "0%"
    }
}

// MARK: - Supporting Data Structures

/// 配息數據點
struct DividendDataPoint: Identifiable, Codable {
    let id: UUID
    let month: String
    let amount: Double
    let year: Int
    
    init(month: String, amount: Double, year: Int) {
        self.id = UUID()
        self.month = month
        self.amount = amount
        self.year = year
    }
}

/// 時間週期枚舉
enum TimePeriod: String, CaseIterable {
    case oneDay = "1D"
    case sevenDays = "7D"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case oneYear = "1Y"
    
    func startDate(from endDate: Date) -> Date {
        let calendar = Calendar.current
        
        switch self {
        case .oneDay:
            return calendar.date(byAdding: .day, value: -1, to: endDate) ?? endDate
        case .sevenDays:
            return calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        }
    }
}

// MARK: - Extensions
extension CalculationService {
    
    /// 判斷損益是否為正
    func isProfitable(_ amount: Double) -> Bool {
        return amount > 0
    }
    
    /// 取得損益顏色 (用於UI)
    func getPnLColor(_ amount: Double) -> String {
        return isProfitable(amount) ? "#34C759" : "#FF3B30"
    }
    
    /// 取得損益符號
    func getPnLSymbol(_ amount: Double) -> String {
        return isProfitable(amount) ? "+" : ""
    }
}
