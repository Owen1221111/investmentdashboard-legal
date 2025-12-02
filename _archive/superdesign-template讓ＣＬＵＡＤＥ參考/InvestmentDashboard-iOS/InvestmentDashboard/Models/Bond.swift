import Foundation
import CloudKit

// MARK: - Bond Model (公司債明細)
struct Bond: Identifiable, Codable {
    let id: UUID
    var clientID: UUID
    var purchaseDate: Date          // 申購日
    var bondName: String           // 債券名稱
    var couponRate: Double         // 票面利率 (%)
    var yieldRate: Double          // 殖利率 (%)
    var purchasePrice: Double      // 申購價
    var purchaseAmount: Double     // 申購金額
    var holdingFaceValue: Double   // 持有面額
    var tradeAmount: Double        // 交易金額
    var currentValue: Double       // 現值
    var receivedInterest: Double   // 已領利息
    var dividendMonths: String     // 配息月份
    var singleDividend: Double     // 單次配息
    var annualDividend: Double     // 年度配息

    // 計算屬性
    var totalPnLWithInterest: Double {
        return currentValue + receivedInterest - purchaseAmount
    }

    var returnRate: Double {
        guard purchaseAmount > 0 else { return 0 }
        return (totalPnLWithInterest / purchaseAmount) * 100
    }

    var formattedPnL: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let sign = totalPnLWithInterest >= 0 ? "+" : ""
        return "\(sign)\(formatter.string(from: NSNumber(value: totalPnLWithInterest)) ?? "0")"
    }

    var formattedReturnRate: String {
        let sign = returnRate >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, returnRate)
    }

    init(
        id: UUID = UUID(),
        clientID: UUID,
        purchaseDate: Date = Date(),
        bondName: String = "",
        couponRate: Double = 0,
        yieldRate: Double = 0,
        purchasePrice: Double = 0,
        purchaseAmount: Double = 0,
        holdingFaceValue: Double = 0,
        tradeAmount: Double = 0,
        currentValue: Double = 0,
        receivedInterest: Double = 0,
        dividendMonths: String = "",
        singleDividend: Double = 0,
        annualDividend: Double = 0
    ) {
        self.id = id
        self.clientID = clientID
        self.purchaseDate = purchaseDate
        self.bondName = bondName
        self.couponRate = couponRate
        self.yieldRate = yieldRate
        self.purchasePrice = purchasePrice
        self.purchaseAmount = purchaseAmount
        self.holdingFaceValue = holdingFaceValue
        self.tradeAmount = tradeAmount
        self.currentValue = currentValue
        self.receivedInterest = receivedInterest
        self.dividendMonths = dividendMonths
        self.singleDividend = singleDividend
        self.annualDividend = annualDividend
    }
}

// MARK: - Extensions
extension Bond: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Bond, rhs: Bond) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Data
extension Bond {
    static func sampleBonds(for clientID: UUID) -> [Bond] {
        [
            Bond(
                clientID: clientID,
                purchaseDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
                bondName: "中華電信2028",
                couponRate: 2.5,
                yieldRate: 2.8,
                purchasePrice: 98.5,
                purchaseAmount: 985000,
                holdingFaceValue: 1000000,
                tradeAmount: 985000,
                currentValue: 1020000,
                receivedInterest: 25000,
                dividendMonths: "6,12",
                singleDividend: 12500,
                annualDividend: 25000
            ),
            Bond(
                clientID: clientID,
                purchaseDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
                bondName: "台積電2027",
                couponRate: 1.8,
                yieldRate: 2.1,
                purchasePrice: 96.2,
                purchaseAmount: 481000,
                holdingFaceValue: 500000,
                tradeAmount: 481000,
                currentValue: 505000,
                receivedInterest: 9000,
                dividendMonths: "3,9",
                singleDividend: 4500,
                annualDividend: 9000
            )
        ]
    }
}

// MARK: - Conversion Helper
extension Bond {
    /// 從字串陣列轉換為 Bond 物件 (用於現有資料移轉)
    static func fromStringArray(_ data: [String], clientID: UUID) -> Bond? {
        guard data.count >= 15 else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM-dd"

        let purchaseDate = dateFormatter.date(from: data[0]) ?? Date()
        let bondName = data[1]
        let couponRate = Double(data[2].replacingOccurrences(of: "%", with: "")) ?? 0
        let yieldRate = Double(data[3].replacingOccurrences(of: "%", with: "")) ?? 0
        let purchasePrice = Double(data[4]) ?? 0
        let purchaseAmount = Double(data[5].replacingOccurrences(of: ",", with: "")) ?? 0
        let holdingFaceValue = Double(data[6].replacingOccurrences(of: ",", with: "")) ?? 0
        let tradeAmount = Double(data[7].replacingOccurrences(of: ",", with: "")) ?? 0
        let currentValue = Double(data[8].replacingOccurrences(of: ",", with: "")) ?? 0
        let receivedInterest = Double(data[9].replacingOccurrences(of: ",", with: "")) ?? 0
        let dividendMonths = data[12]
        let singleDividend = Double(data[13].replacingOccurrences(of: ",", with: "")) ?? 0
        let annualDividend = Double(data[14].replacingOccurrences(of: ",", with: "")) ?? 0

        return Bond(
            clientID: clientID,
            purchaseDate: purchaseDate,
            bondName: bondName,
            couponRate: couponRate,
            yieldRate: yieldRate,
            purchasePrice: purchasePrice,
            purchaseAmount: purchaseAmount,
            holdingFaceValue: holdingFaceValue,
            tradeAmount: tradeAmount,
            currentValue: currentValue,
            receivedInterest: receivedInterest,
            dividendMonths: dividendMonths,
            singleDividend: singleDividend,
            annualDividend: annualDividend
        )
    }

    /// 轉換為字串陣列 (用於相容現有界面)
    func toStringArray() -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM-dd"

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        return [
            dateFormatter.string(from: purchaseDate),                                    // 申購日
            bondName,                                                                   // 債券名稱
            String(format: "%.1f%%", couponRate),                                       // 票面利率
            String(format: "%.1f%%", yieldRate),                                        // 殖利率
            String(format: "%.1f", purchasePrice),                                      // 申購價
            formatter.string(from: NSNumber(value: purchaseAmount)) ?? "0",             // 申購金額
            formatter.string(from: NSNumber(value: holdingFaceValue)) ?? "0",           // 持有面額
            formatter.string(from: NSNumber(value: tradeAmount)) ?? "0",                // 交易金額
            formatter.string(from: NSNumber(value: currentValue)) ?? "0",               // 現值
            formatter.string(from: NSNumber(value: receivedInterest)) ?? "0",           // 已領利息
            formattedPnL,                                                               // 含息損益
            formattedReturnRate,                                                        // 報酬率
            dividendMonths,                                                             // 配息月份
            formatter.string(from: NSNumber(value: singleDividend)) ?? "0",             // 單次配息
            formatter.string(from: NSNumber(value: annualDividend)) ?? "0"              // 年度配息
        ]
    }
}