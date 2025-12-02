import Foundation
import CloudKit

// MARK: - Monthly Asset Record Model (月度資產明細 - CloudKit整合版本)
struct MonthlyAssetRecord: Identifiable, Codable {
    let id: UUID
    var clientID: UUID
    var date: Date
    
    // 資產項目 (16個欄位 - 根據文檔)
    var cash: Double                    // 現金
    var usStock: Double                 // 美股
    var regularInvestment: Double       // 定期定額
    var bonds: Double                   // 債券
    var structuredProducts: Double      // 結構型商品
    var twStock: Double                 // 台股
    var twStockConverted: Double        // 台股折合
    var confirmedInterest: Double       // 已確利息
    var deposit: Double                 // 匯入
    
    // 成本相關欄位
    var cashCost: Double               // 現金成本
    var stockCost: Double              // 股票成本
    var bondCost: Double               // 債券成本
    var otherCost: Double              // 其他成本
    
    // 備註
    var notes: String
    
    // 計算屬性
    var totalAssets: Double {
        cash + usStock + regularInvestment + bonds + structuredProducts + twStock + twStockConverted + confirmedInterest
    }
    
    var totalCost: Double {
        cashCost + stockCost + bondCost + otherCost
    }
    
    var totalPnL: Double {
        totalAssets - totalCost
    }
    
    var totalPnLPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (totalPnL / totalCost) * 100
    }
    
    init(
        id: UUID = UUID(),
        clientID: UUID,
        date: Date = Date(),
        cash: Double = 0,
        usStock: Double = 0,
        regularInvestment: Double = 0,
        bonds: Double = 0,
        structuredProducts: Double = 0,
        twStock: Double = 0,
        twStockConverted: Double = 0,
        confirmedInterest: Double = 0,
        deposit: Double = 0,
        cashCost: Double = 0,
        stockCost: Double = 0,
        bondCost: Double = 0,
        otherCost: Double = 0,
        notes: String = ""
    ) {
        self.id = id
        self.clientID = clientID
        self.date = date
        self.cash = cash
        self.usStock = usStock
        self.regularInvestment = regularInvestment
        self.bonds = bonds
        self.structuredProducts = structuredProducts
        self.twStock = twStock
        self.twStockConverted = twStockConverted
        self.confirmedInterest = confirmedInterest
        self.deposit = deposit
        self.cashCost = cashCost
        self.stockCost = stockCost
        self.bondCost = bondCost
        self.otherCost = otherCost
        self.notes = notes
    }

    // MARK: - CloudKit Support
    static let recordType = "MonthlyAssetRecord"

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString)
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: MonthlyAssetRecord.recordType, recordID: recordID)
        record["clientID"] = clientID.uuidString
        record["date"] = date
        record["cash"] = cash
        record["usStock"] = usStock
        record["regularInvestment"] = regularInvestment
        record["bonds"] = bonds
        record["structuredProducts"] = structuredProducts
        record["twStock"] = twStock
        record["twStockConverted"] = twStockConverted
        record["confirmedInterest"] = confirmedInterest
        record["deposit"] = deposit
        record["cashCost"] = cashCost
        record["stockCost"] = stockCost
        record["bondCost"] = bondCost
        record["otherCost"] = otherCost
        record["notes"] = notes
        return record
    }

    init?(from record: CKRecord) {
        guard
            let clientIDString = record["clientID"] as? String,
            let clientID = UUID(uuidString: clientIDString),
            let date = record["date"] as? Date,
            let cash = record["cash"] as? Double,
            let usStock = record["usStock"] as? Double,
            let regularInvestment = record["regularInvestment"] as? Double,
            let bonds = record["bonds"] as? Double,
            let structuredProducts = record["structuredProducts"] as? Double,
            let twStock = record["twStock"] as? Double,
            let twStockConverted = record["twStockConverted"] as? Double,
            let confirmedInterest = record["confirmedInterest"] as? Double,
            let deposit = record["deposit"] as? Double,
            let cashCost = record["cashCost"] as? Double,
            let stockCost = record["stockCost"] as? Double,
            let bondCost = record["bondCost"] as? Double,
            let otherCost = record["otherCost"] as? Double,
            let notes = record["notes"] as? String,
            let id = UUID(uuidString: record.recordID.recordName)
        else {
            return nil
        }

        self.id = id
        self.clientID = clientID
        self.date = date
        self.cash = cash
        self.usStock = usStock
        self.regularInvestment = regularInvestment
        self.bonds = bonds
        self.structuredProducts = structuredProducts
        self.twStock = twStock
        self.twStockConverted = twStockConverted
        self.confirmedInterest = confirmedInterest
        self.deposit = deposit
        self.cashCost = cashCost
        self.stockCost = stockCost
        self.bondCost = bondCost
        self.otherCost = otherCost
        self.notes = notes
    }

}

// MARK: - Extensions
extension MonthlyAssetRecord: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MonthlyAssetRecord, rhs: MonthlyAssetRecord) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Data
extension MonthlyAssetRecord {
    static func sampleRecord(for clientID: UUID) -> MonthlyAssetRecord {
        MonthlyAssetRecord(
            clientID: clientID,
            date: Date(),
            cash: 2000000,        // 200萬現金
            usStock: 4500000,     // 450萬美股
            regularInvestment: 500000,  // 50萬定期定額
            bonds: 2500000,       // 250萬債券
            structuredProducts: 200000, // 20萬結構型商品
            twStock: 800000,      // 80萬台股
            twStockConverted: 800000,   // 台股折合
            confirmedInterest: 125000,  // 12.5萬已確利息
            deposit: 0,
            cashCost: 1900000,    // 成本略低於資產
            stockCost: 4200000,
            bondCost: 2450000,
            otherCost: 950000,
            notes: "範例數據"
        )
    }
}