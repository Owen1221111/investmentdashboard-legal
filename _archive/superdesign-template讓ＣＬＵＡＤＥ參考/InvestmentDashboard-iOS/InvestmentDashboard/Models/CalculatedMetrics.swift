import Foundation

// MARK: - Calculated Metrics (從月度資產明細計算出的指標)
struct CalculatedMetrics: Codable {
    let clientID: UUID
    let lastUpdated: Date
    
    // 總資產統計
    let totalAssets: Double
    let totalPnL: Double
    let totalPnLPercentage: Double
    
    // 資產配置百分比 (根據文檔的5大類)
    let allocationPercentages: AssetAllocation
    
    // 圖表數據
    let chartData: [ChartDataPoint]
    let monthlyTrend: [MonthlyTrendPoint]
    
    init(from records: [MonthlyAssetRecord]) {
        guard let latestRecord = records.sorted(by: { $0.date > $1.date }).first else {
            self.clientID = UUID()
            self.lastUpdated = Date()
            self.totalAssets = 0
            self.totalPnL = 0
            self.totalPnLPercentage = 0
            self.allocationPercentages = AssetAllocation()
            self.chartData = []
            self.monthlyTrend = []
            return
        }
        
        self.clientID = latestRecord.clientID
        self.lastUpdated = Date()
        self.totalAssets = latestRecord.totalAssets
        self.totalPnL = latestRecord.totalPnL
        self.totalPnLPercentage = latestRecord.totalPnLPercentage
        
        // 計算資產配置
        self.allocationPercentages = AssetAllocation(from: latestRecord)
        
        // 生成圖表數據
        self.chartData = CalculatedMetrics.generateChartData(from: latestRecord)
        
        // 生成月度趨勢
        self.monthlyTrend = CalculatedMetrics.generateMonthlyTrend(from: records)
    }
    
    // 生成資產配置圖表數據
    private static func generateChartData(from record: MonthlyAssetRecord) -> [ChartDataPoint] {
        let allocation = AssetAllocation(from: record)
        
        return [
            ChartDataPoint(name: "美股", value: allocation.usStockPercentage, color: "#1f77b4"),
            ChartDataPoint(name: "債券", value: allocation.bondsPercentage, color: "#ff7f0e"),
            ChartDataPoint(name: "現金", value: allocation.cashPercentage, color: "#2ca02c"),
            ChartDataPoint(name: "台股", value: allocation.twStockPercentage, color: "#d62728"),
            ChartDataPoint(name: "結構型", value: allocation.structuredPercentage, color: "#9467bd")
        ].filter { $0.value > 0 }
    }
    
    // 生成月度趨勢數據
    private static func generateMonthlyTrend(from records: [MonthlyAssetRecord]) -> [MonthlyTrendPoint] {
        let sortedRecords = records.sorted(by: { $0.date < $1.date })
        
        return sortedRecords.map { record in
            MonthlyTrendPoint(
                date: record.date,
                totalAssets: record.totalAssets,
                totalPnL: record.totalPnL
            )
        }
    }
}

// MARK: - Asset Allocation (資產配置)
struct AssetAllocation: Codable {
    let usStockPercentage: Double      // 美股百分比
    let bondsPercentage: Double        // 債券百分比
    let cashPercentage: Double         // 現金百分比
    let twStockPercentage: Double      // 台股百分比
    let structuredPercentage: Double   // 結構型商品百分比
    
    init() {
        self.usStockPercentage = 0
        self.bondsPercentage = 0
        self.cashPercentage = 0
        self.twStockPercentage = 0
        self.structuredPercentage = 0
    }
    
    init(from record: MonthlyAssetRecord) {
        let total = record.totalAssets
        
        guard total > 0 else {
            self.usStockPercentage = 0
            self.bondsPercentage = 0
            self.cashPercentage = 0
            self.twStockPercentage = 0
            self.structuredPercentage = 0
            return
        }
        
        // 計算各類資產百分比
        self.usStockPercentage = ((record.usStock + record.regularInvestment) / total) * 100
        self.bondsPercentage = (record.bonds / total) * 100
        self.cashPercentage = (record.cash / total) * 100
        self.twStockPercentage = ((record.twStock + record.twStockConverted) / total) * 100
        self.structuredPercentage = (record.structuredProducts / total) * 100
    }
}

// MARK: - Chart Data Point (圖表數據點)
struct ChartDataPoint: Codable, Identifiable {
    let id: UUID
    let name: String
    let value: Double
    let color: String
    
    init(name: String, value: Double, color: String) {
        self.id = UUID()
        self.name = name
        self.value = value
        self.color = color
    }
}

// MARK: - Monthly Trend Point (月度趨勢點)
struct MonthlyTrendPoint: Codable, Identifiable {
    let id: UUID
    let date: Date
    let totalAssets: Double
    let totalPnL: Double
    
    init(date: Date, totalAssets: Double, totalPnL: Double) {
        self.id = UUID()
        self.date = date
        self.totalAssets = totalAssets
        self.totalPnL = totalPnL
    }
}

// MARK: - Extensions
extension AssetAllocation {
    // 取得最大配置項目 (用於圓餅圖中心顯示)
    var majorAllocation: (name: String, percentage: Double) {
        let allocations = [
            ("美股", usStockPercentage),
            ("債券", bondsPercentage),
            ("現金", cashPercentage),
            ("台股", twStockPercentage),
            ("結構型", structuredPercentage)
        ]
        
        return allocations.max(by: { $0.1 < $1.1 }) ?? ("", 0)
    }
}