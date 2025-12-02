import Foundation

// MARK: - 結構型商品狀態
enum StructuredProductStatus: String, CaseIterable, Codable {
    case ongoing = "進行中"
    case exited = "已出場"
}

// MARK: - 結構型商品 Model
struct StructuredProduct: Identifiable, Codable {
    let id: UUID
    var clientID: UUID
    var tradeDate: Date          // 交易定價日
    var target: String           // 標的
    var executionDate: Date      // 發行日
    var latestEvaluationDate: Date // 最終評價日
    var periodPrice: Double      // 期間價格
    var executionPrice: Double   // 執行價格
    var knockOutBarrier: Double  // 敲出障礙
    var knockInBarrier: Double   // 敲入障礙
    var yield: Double           // 利率
    var monthlyYield: Double    // 月利率
    var tradeAmount: Double     // 交易金額
    var notes: String           // 備註
    var status: StructuredProductStatus // 狀態：進行中/已出場

    // 已出場專屬欄位
    var exitDate: Date?         // 出場日
    var holdingMonths: Int?     // 持有月
    var actualYield: Double?    // 實際收益
    var exitAmount: Double?     // 出場金額
    var actualReturn: Double?   // 實際收益

    // 計算屬性
    var pnl: Double {
        guard let exitAmount = exitAmount else { return 0 }
        return exitAmount - tradeAmount
    }

    var pnlPercentage: Double {
        guard let exitAmount = exitAmount, tradeAmount > 0 else { return 0 }
        return ((exitAmount - tradeAmount) / tradeAmount) * 100
    }

    init(
        id: UUID = UUID(),
        clientID: UUID,
        tradeDate: Date = Date(),
        target: String,
        executionDate: Date = Date(),
        latestEvaluationDate: Date = Date(),
        periodPrice: Double = 0,
        executionPrice: Double = 0,
        knockOutBarrier: Double = 0,
        knockInBarrier: Double = 0,
        yield: Double = 0,
        monthlyYield: Double = 0,
        tradeAmount: Double = 0,
        notes: String = "",
        status: StructuredProductStatus = .ongoing,
        exitDate: Date? = nil,
        holdingMonths: Int? = nil,
        actualYield: Double? = nil,
        exitAmount: Double? = nil,
        actualReturn: Double? = nil
    ) {
        self.id = id
        self.clientID = clientID
        self.tradeDate = tradeDate
        self.target = target
        self.executionDate = executionDate
        self.latestEvaluationDate = latestEvaluationDate
        self.periodPrice = periodPrice
        self.executionPrice = executionPrice
        self.knockOutBarrier = knockOutBarrier
        self.knockInBarrier = knockInBarrier
        self.yield = yield
        self.monthlyYield = monthlyYield
        self.tradeAmount = tradeAmount
        self.notes = notes
        self.status = status
        self.exitDate = exitDate
        self.holdingMonths = holdingMonths
        self.actualYield = actualYield
        self.exitAmount = exitAmount
        self.actualReturn = actualReturn
    }

    // 標記為已出場
    mutating func markAsExited(exitDate: Date, exitAmount: Double, actualYield: Double) {
        self.status = .exited
        self.exitDate = exitDate
        self.exitAmount = exitAmount
        self.actualYield = actualYield

        // 計算持有月份
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: executionDate, to: exitDate)
        self.holdingMonths = components.month ?? 0

        // 計算實際收益
        self.actualReturn = exitAmount - tradeAmount
    }
}

// MARK: - Extensions
extension StructuredProduct: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: StructuredProduct, rhs: StructuredProduct) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Data
extension StructuredProduct {
    static func sampleOngoingProducts(for clientID: UUID) -> [StructuredProduct] {
        [
            StructuredProduct(
                clientID: clientID,
                tradeDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
                target: "TSM NVDA",
                executionDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
                latestEvaluationDate: Calendar.current.date(byAdding: .month, value: 9, to: Date()) ?? Date(),
                periodPrice: 0.0,
                executionPrice: 0.0,
                knockOutBarrier: 0.0,
                knockInBarrier: 0.0,
                yield: 0.0,
                monthlyYield: 0.0,
                tradeAmount: 30000,
                notes: "接槓下一檔",
                status: .ongoing
            ),
            StructuredProduct(
                clientID: clientID,
                tradeDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
                target: "TSM TSLA NVDA",
                executionDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
                latestEvaluationDate: Calendar.current.date(byAdding: .month, value: 10, to: Date()) ?? Date(),
                periodPrice: 0.0,
                executionPrice: 0.0,
                knockOutBarrier: 0.0,
                knockInBarrier: 0.0,
                yield: 0.0,
                monthlyYield: 0.0,
                tradeAmount: 50000,
                notes: "",
                status: .ongoing
            )
        ]
    }

    static func sampleExitedProducts(for clientID: UUID) -> [StructuredProduct] {
        [
            StructuredProduct(
                clientID: clientID,
                tradeDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date(),
                target: "TSM NVDA",
                executionDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date(),
                latestEvaluationDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
                periodPrice: 20.00,
                executionPrice: 0.0,
                knockOutBarrier: 0.0,
                knockInBarrier: 0.0,
                yield: 1.67,
                monthlyYield: 0.0,
                tradeAmount: 30000,
                notes: "接槓下一檔",
                status: .exited,
                exitDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
                holdingMonths: 2,
                actualYield: 2.83,
                exitAmount: 30850,
                actualReturn: 850
            ),
            StructuredProduct(
                clientID: clientID,
                tradeDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
                target: "TSM TSLA NVDA",
                executionDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
                latestEvaluationDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
                periodPrice: 10.50,
                executionPrice: 0.0,
                knockOutBarrier: 0.0,
                knockInBarrier: 0.0,
                yield: 0.88,
                monthlyYield: 0.0,
                tradeAmount: 50000,
                notes: "",
                status: .exited,
                exitDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
                holdingMonths: 1,
                actualYield: 0.88,
                exitAmount: 50440,
                actualReturn: 440
            )
        ]
    }
}