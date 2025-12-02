import Foundation
import CloudKit

// MARK: - CloudKit Protocol
protocol CloudKitConvertible {
    static var recordType: String { get }
    var recordID: CKRecord.ID { get }
    init?(from record: CKRecord)
    func toCKRecord() -> CKRecord
}

// MARK: - Client + CloudKit
extension Client: CloudKitConvertible {
    static var recordType: String { "Client" }

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString)
    }

    init?(from record: CKRecord) {
        guard let name = record["name"] as? String,
              let email = record["email"] as? String,
              let createdDate = record["createdDate"] as? Date,
              let idString = record.recordID.recordName,
              let id = UUID(uuidString: idString) else {
            return nil
        }

        self.init(id: id, name: name, email: email, createdDate: createdDate)
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Client.recordType, recordID: recordID)
        record["name"] = name
        record["email"] = email
        record["createdDate"] = createdDate
        return record
    }
}

// MARK: - MonthlyAssetRecord + CloudKit
extension MonthlyAssetRecord: CloudKitConvertible {
    static var recordType: String { "MonthlyAssetRecord" }

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString)
    }

    init?(from record: CKRecord) {
        guard let clientIDString = record["clientID"] as? String,
              let clientID = UUID(uuidString: clientIDString),
              let date = record["date"] as? Date,
              let idString = record.recordID.recordName,
              let id = UUID(uuidString: idString) else {
            return nil
        }

        self.init(
            id: id,
            clientID: clientID,
            date: date,
            cash: record["cash"] as? Double ?? 0,
            usStock: record["usStock"] as? Double ?? 0,
            regularInvestment: record["regularInvestment"] as? Double ?? 0,
            bonds: record["bonds"] as? Double ?? 0,
            structuredProducts: record["structuredProducts"] as? Double ?? 0,
            twStock: record["twStock"] as? Double ?? 0,
            twStockConverted: record["twStockConverted"] as? Double ?? 0,
            confirmedInterest: record["confirmedInterest"] as? Double ?? 0,
            deposit: record["deposit"] as? Double ?? 0,
            cashCost: record["cashCost"] as? Double ?? 0,
            stockCost: record["stockCost"] as? Double ?? 0,
            bondCost: record["bondCost"] as? Double ?? 0,
            otherCost: record["otherCost"] as? Double ?? 0,
            notes: record["notes"] as? String ?? ""
        )
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
}

// MARK: - Bond + CloudKit
extension Bond: CloudKitConvertible {
    static var recordType: String { "Bond" }

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString)
    }

    init?(from record: CKRecord) {
        guard let clientIDString = record["clientID"] as? String,
              let clientID = UUID(uuidString: clientIDString),
              let purchaseDate = record["purchaseDate"] as? Date,
              let bondName = record["bondName"] as? String,
              let idString = record.recordID.recordName,
              let id = UUID(uuidString: idString) else {
            return nil
        }

        self.init(
            id: id,
            clientID: clientID,
            purchaseDate: purchaseDate,
            bondName: bondName,
            couponRate: record["couponRate"] as? Double ?? 0,
            yieldRate: record["yieldRate"] as? Double ?? 0,
            purchasePrice: record["purchasePrice"] as? Double ?? 0,
            purchaseAmount: record["purchaseAmount"] as? Double ?? 0,
            holdingFaceValue: record["holdingFaceValue"] as? Double ?? 0,
            tradeAmount: record["tradeAmount"] as? Double ?? 0,
            currentValue: record["currentValue"] as? Double ?? 0,
            receivedInterest: record["receivedInterest"] as? Double ?? 0,
            dividendMonths: record["dividendMonths"] as? String ?? "",
            singleDividend: record["singleDividend"] as? Double ?? 0,
            annualDividend: record["annualDividend"] as? Double ?? 0
        )
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Bond.recordType, recordID: recordID)
        record["clientID"] = clientID.uuidString
        record["purchaseDate"] = purchaseDate
        record["bondName"] = bondName
        record["couponRate"] = couponRate
        record["yieldRate"] = yieldRate
        record["purchasePrice"] = purchasePrice
        record["purchaseAmount"] = purchaseAmount
        record["holdingFaceValue"] = holdingFaceValue
        record["tradeAmount"] = tradeAmount
        record["currentValue"] = currentValue
        record["receivedInterest"] = receivedInterest
        record["dividendMonths"] = dividendMonths
        record["singleDividend"] = singleDividend
        record["annualDividend"] = annualDividend
        return record
    }
}

// MARK: - StructuredProduct + CloudKit
extension StructuredProduct: CloudKitConvertible {
    static var recordType: String { "StructuredProduct" }

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString)
    }

    init?(from record: CKRecord) {
        guard let clientIDString = record["clientID"] as? String,
              let clientID = UUID(uuidString: clientIDString),
              let tradeDate = record["tradeDate"] as? Date,
              let target = record["target"] as? String,
              let executionDate = record["executionDate"] as? Date,
              let latestEvaluationDate = record["latestEvaluationDate"] as? Date,
              let statusString = record["status"] as? String,
              let status = StructuredProductStatus(rawValue: statusString),
              let idString = record.recordID.recordName,
              let id = UUID(uuidString: idString) else {
            return nil
        }

        self.init(
            id: id,
            clientID: clientID,
            tradeDate: tradeDate,
            target: target,
            executionDate: executionDate,
            latestEvaluationDate: latestEvaluationDate,
            periodPrice: record["periodPrice"] as? Double ?? 0,
            executionPrice: record["executionPrice"] as? Double ?? 0,
            knockOutBarrier: record["knockOutBarrier"] as? Double ?? 0,
            knockInBarrier: record["knockInBarrier"] as? Double ?? 0,
            yield: record["yield"] as? Double ?? 0,
            monthlyYield: record["monthlyYield"] as? Double ?? 0,
            tradeAmount: record["tradeAmount"] as? Double ?? 0,
            notes: record["notes"] as? String ?? "",
            status: status,
            exitDate: record["exitDate"] as? Date,
            holdingMonths: record["holdingMonths"] as? Int,
            actualYield: record["actualYield"] as? Double,
            exitAmount: record["exitAmount"] as? Double,
            actualReturn: record["actualReturn"] as? Double
        )
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: StructuredProduct.recordType, recordID: recordID)
        record["clientID"] = clientID.uuidString
        record["tradeDate"] = tradeDate
        record["target"] = target
        record["executionDate"] = executionDate
        record["latestEvaluationDate"] = latestEvaluationDate
        record["periodPrice"] = periodPrice
        record["executionPrice"] = executionPrice
        record["knockOutBarrier"] = knockOutBarrier
        record["knockInBarrier"] = knockInBarrier
        record["yield"] = yield
        record["monthlyYield"] = monthlyYield
        record["tradeAmount"] = tradeAmount
        record["notes"] = notes
        record["status"] = status.rawValue
        record["exitDate"] = exitDate
        record["holdingMonths"] = holdingMonths
        record["actualYield"] = actualYield
        record["exitAmount"] = exitAmount
        record["actualReturn"] = actualReturn
        return record
    }
}

// MARK: - CloudKit Error Handling
enum CloudKitError: Error, LocalizedError {
    case networkUnavailable
    case accountNotFound
    case quotaExceeded
    case recordNotFound
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "網路連線不可用"
        case .accountNotFound:
            return "找不到 iCloud 帳號"
        case .quotaExceeded:
            return "iCloud 儲存空間不足"
        case .recordNotFound:
            return "找不到記錄"
        case .unknown(let error):
            return "未知錯誤: \(error.localizedDescription)"
        }
    }
}