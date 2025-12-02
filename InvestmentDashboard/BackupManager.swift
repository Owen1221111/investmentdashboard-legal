//
//  BackupManager.swift
//  InvestmentDashboard
//
//  iCloud Documents 備份管理器
//

import Foundation
import CoreData
import CloudKit
import SwiftUI

class BackupManager: ObservableObject {
    static let shared = BackupManager()

    @Published var lastBackupDate: Date?
    @Published var isBackingUp = false
    @Published var isRestoring = false
    @Published var backupError: String?
    @Published var backupFileURL: URL?
    @Published var showShareSheet = false
    @Published var showDocumentPicker = false
    @Published var pendingRestoreContext: NSManagedObjectContext?
    @Published var restoreCompletion: ((Bool, String?) -> Void)?

    private let lastBackupKey = "lastBackupDate"
    private let backupFolderName = "Backup"

    init() {
        loadLastBackupDate()
    }

    // MARK: - 備份時間管理

    private func loadLastBackupDate() {
        if let date = UserDefaults.standard.object(forKey: lastBackupKey) as? Date {
            lastBackupDate = date
        }
    }

    private func saveLastBackupDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastBackupKey)
        DispatchQueue.main.async {
            self.lastBackupDate = date
        }
    }

    // MARK: - iCloud Documents 路徑

    private func getBackupURL() -> URL? {
        // 明確指定容器識別碼
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.com.owen.InvestmentDashboard") else {
            print("無法取得 iCloud 容器，請確認 iCloud 已登入且已啟用 iCloud 雲碟")
            return nil
        }

        let backupURL = containerURL
            .appendingPathComponent("Documents")
            .appendingPathComponent(backupFolderName)

        // 建立資料夾
        do {
            try FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true)
        } catch {
            print("建立備份資料夾失敗: \(error)")
            return nil
        }

        return backupURL
    }

    // MARK: - 備份功能（產生檔案供分享）

    func backup(context: NSManagedObjectContext, completion: @escaping (Bool, String?) -> Void) {
        guard !isBackingUp else {
            completion(false, "備份進行中")
            return
        }

        DispatchQueue.main.async {
            self.isBackingUp = true
            self.backupError = nil
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 匯出所有資料
                let backupData = try self.exportAllData(context: context)

                // 產生檔案名稱
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                let fileName = "InvestmentDashboard_backup_\(formatter.string(from: Date())).json"

                // 儲存到暫存目錄
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

                // 寫入檔案
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let jsonData = try encoder.encode(backupData)
                try jsonData.write(to: tempURL)

                // 更新備份時間
                let now = Date()
                self.saveLastBackupDate(now)

                DispatchQueue.main.async {
                    self.isBackingUp = false
                    self.backupFileURL = tempURL
                    self.showShareSheet = true
                    completion(true, nil)
                }

                print("備份檔案已建立: \(tempURL)")

            } catch {
                DispatchQueue.main.async {
                    self.isBackingUp = false
                    self.backupError = error.localizedDescription
                    completion(false, error.localizedDescription)
                }
                print("備份失敗: \(error)")
            }
        }
    }

    // MARK: - 還原功能（顯示文件選擇器）

    func restore(context: NSManagedObjectContext, completion: @escaping (Bool, String?) -> Void) {
        guard !isRestoring else {
            completion(false, "還原進行中")
            return
        }

        DispatchQueue.main.async {
            self.pendingRestoreContext = context
            self.restoreCompletion = completion
            self.showDocumentPicker = true
        }
    }

    // 從選擇的檔案還原
    func restoreFromURL(_ url: URL, context: NSManagedObjectContext, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.async {
            self.isRestoring = true
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 開始存取安全範圍的 URL
                guard url.startAccessingSecurityScopedResource() else {
                    throw BackupError.importFailed
                }
                defer { url.stopAccessingSecurityScopedResource() }

                // 讀取備份檔案
                let jsonData = try Data(contentsOf: url)
                let backupData = try JSONDecoder().decode(BackupData.self, from: jsonData)

                // 還原資料
                try self.importAllData(backupData, context: context)

                DispatchQueue.main.async {
                    self.isRestoring = false
                    completion(true, nil)
                }

                print("還原成功")

            } catch {
                DispatchQueue.main.async {
                    self.isRestoring = false
                    completion(false, error.localizedDescription)
                }
                print("還原失敗: \(error)")
            }
        }
    }

    // MARK: - 清理舊備份

    private func cleanOldBackups(in folderURL: URL) {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.creationDateKey])
                .filter { $0.pathExtension == "json" }
                .sorted { (url1, url2) -> Bool in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }

            // 保留最近 5 個備份
            if files.count > 5 {
                for file in files.suffix(from: 5) {
                    try FileManager.default.removeItem(at: file)
                    print("已刪除舊備份: \(file.lastPathComponent)")
                }
            }
        } catch {
            print("清理舊備份失敗: \(error)")
        }
    }

    // MARK: - 資料匯出

    private func exportAllData(context: NSManagedObjectContext) throws -> BackupData {
        var backupData = BackupData()

        // 在主執行緒執行 Core Data 操作
        try context.performAndWait {
            // 匯出客戶
            let clientRequest: NSFetchRequest<Client> = Client.fetchRequest()
            let clients = try context.fetch(clientRequest)

            for client in clients {
                var clientBackup = ClientBackup(
                    id: client.objectID.uriRepresentation().absoluteString,
                    name: client.name ?? "",
                    email: client.email,
                    birthday: client.birthDate,
                    createdDate: client.createdDate
                )

                // 匯出月度資產
                if let monthlyAssets = client.monthlyAssets as? Set<MonthlyAsset> {
                    clientBackup.monthlyAssets = monthlyAssets.map { asset in
                        MonthlyAssetBackup(
                            date: asset.date,
                            createdDate: asset.createdDate,
                            twdCash: asset.twdCash,
                            cash: asset.cash,
                            usStock: asset.usStock,
                            usStockCost: asset.usStockCost,
                            regularInvestment: asset.regularInvestment,
                            regularInvestmentCost: asset.regularInvestmentCost,
                            bonds: asset.bonds,
                            bondsCost: asset.bondsCost,
                            confirmedInterest: asset.confirmedInterest,
                            structured: asset.structured,
                            taiwanStock: asset.taiwanStock,
                            taiwanStockCost: asset.taiwanStockCost,
                            taiwanStockFolded: asset.taiwanStockFolded,
                            twdToUsd: asset.twdToUsd,
                            totalAssets: asset.totalAssets,
                            exchangeRate: asset.exchangeRate,
                            deposit: asset.deposit,
                            depositAccumulated: asset.depositAccumulated,
                            notes: asset.notes,
                            fund: asset.fund,
                            fundCost: asset.fundCost,
                            insurance: asset.insurance
                        )
                    }
                }

                // 匯出公司債
                if let bonds = client.corporateBonds as? Set<CorporateBond> {
                    clientBackup.corporateBonds = bonds.map { bond in
                        CorporateBondBackup(
                            subscriptionDate: bond.subscriptionDate,
                            subscriptionDateAsDate: bond.subscriptionDateAsDate,
                            bondName: bond.bondName,
                            currency: bond.currency,
                            couponRate: bond.couponRate,
                            yieldRate: bond.yieldRate,
                            subscriptionPrice: bond.subscriptionPrice,
                            subscriptionAmount: bond.subscriptionAmount,
                            holdingFaceValue: bond.holdingFaceValue,
                            previousHandInterest: bond.previousHandInterest,
                            transactionAmount: bond.transactionAmount,
                            currentValue: bond.currentValue,
                            receivedInterest: bond.receivedInterest,
                            profitLossWithInterest: bond.profitLossWithInterest,
                            returnRate: bond.returnRate,
                            dividendMonths: bond.dividendMonths,
                            singleDividend: bond.singleDividend,
                            annualDividend: bond.annualDividend,
                            createdDate: bond.createdDate
                        )
                    }
                }

                // 匯出結構型商品
                if let products = client.structuredProducts as? Set<StructuredProduct> {
                    clientBackup.structuredProducts = products.map { product in
                        StructuredProductBackup(
                            numberOfTargets: product.numberOfTargets,
                            tradePricingDate: product.tradePricingDate,
                            target1: product.target1,
                            target2: product.target2,
                            target3: product.target3,
                            issueDate: product.issueDate,
                            finalValuationDate: product.finalValuationDate,
                            initialPrice1: product.initialPrice1,
                            initialPrice2: product.initialPrice2,
                            initialPrice3: product.initialPrice3,
                            strikePrice1: product.strikePrice1,
                            strikePrice2: product.strikePrice2,
                            strikePrice3: product.strikePrice3,
                            distanceToExit1: product.distanceToExit1,
                            distanceToExit2: product.distanceToExit2,
                            distanceToExit3: product.distanceToExit3,
                            currentPrice1: product.currentPrice1,
                            currentPrice2: product.currentPrice2,
                            currentPrice3: product.currentPrice3,
                            interestRate: product.interestRate,
                            monthlyRate: product.monthlyRate,
                            transactionAmount: product.transactionAmount,
                            exitDate: product.exitDate,
                            holdingMonths: product.holdingMonths,
                            actualReturn: product.actualReturn,
                            realProfit: product.realProfit,
                            notes: product.notes,
                            createdDate: product.createdDate,
                            isExited: product.isExited,
                            exitCategory: product.exitCategory
                        )
                    }
                }

                // 匯出美股
                if let usStocks = client.usStocks as? Set<USStock> {
                    clientBackup.usStocks = usStocks.map { stock in
                        USStockBackup(
                            market: stock.market,
                            name: stock.name,
                            shares: stock.shares,
                            cost: stock.cost,
                            costPerShare: stock.costPerShare,
                            currentPrice: stock.currentPrice,
                            marketValue: stock.marketValue,
                            profitLoss: stock.profitLoss,
                            returnRate: stock.returnRate,
                            currency: stock.currency,
                            comment: stock.comment,
                            createdDate: stock.createdDate
                        )
                    }
                }

                // 匯出台股
                if let twStocks = client.twStocks as? Set<TWStock> {
                    clientBackup.taiwanStocks = twStocks.map { stock in
                        TWStockBackup(
                            name: stock.name,
                            shares: stock.shares,
                            cost: stock.cost,
                            costPerShare: stock.costPerShare,
                            currentPrice: stock.currentPrice,
                            marketValue: stock.marketValue,
                            profitLoss: stock.profitLoss,
                            returnRate: stock.returnRate,
                            currency: stock.currency,
                            comment: stock.comment,
                            createdDate: stock.createdDate
                        )
                    }
                }

                // 匯出保單
                if let policies = client.insurancePolicies as? Set<InsurancePolicy> {
                    clientBackup.insurancePolicies = policies.map { policy in
                        InsurancePolicyBackup(
                            policyType: policy.policyType,
                            insuranceCompany: policy.insuranceCompany,
                            policyNumber: policy.policyNumber,
                            policyName: policy.policyName,
                            policyHolder: policy.policyHolder,
                            insuredPerson: policy.insuredPerson,
                            startDate: policy.startDate,
                            paymentMonth: policy.paymentMonth,
                            coverageAmount: policy.coverageAmount,
                            annualPremium: policy.annualPremium,
                            paymentPeriod: policy.paymentPeriod,
                            beneficiary: policy.beneficiary,
                            interestRate: policy.interestRate,
                            currency: policy.currency,
                            createdDate: policy.createdDate
                        )
                    }
                }

                // 匯出貸款
                if let loans = client.loans as? Set<Loan> {
                    clientBackup.loans = loans.map { loan in
                        LoanBackup(
                            loanType: loan.loanType,
                            loanName: loan.loanName,
                            loanAmount: loan.loanAmount,
                            usedLoanAmount: loan.usedLoanAmount,
                            interestRate: loan.interestRate,
                            loanTerm: loan.loanTerm,
                            startDate: loan.startDate,
                            endDate: loan.endDate,
                            gracePeriodPayment: loan.gracePeriodPayment,
                            normalPayment: loan.normalPayment,
                            totalPaid: loan.totalPaid,
                            remainingBalance: loan.remainingBalance,
                            notes: loan.notes,
                            gracePeriod: loan.gracePeriod,
                            createdDate: loan.createdDate
                        )
                    }
                }

                backupData.clients.append(clientBackup)
            }
        }

        backupData.backupDate = Date()
        backupData.version = "1.0"

        return backupData
    }

    // MARK: - 資料匯入

    private func importAllData(_ data: BackupData, context: NSManagedObjectContext) throws {
        try context.performAndWait {
            for clientBackup in data.clients {
                let client = Client(context: context)
                client.name = clientBackup.name
                client.email = clientBackup.email
                client.birthDate = clientBackup.birthday
                client.createdDate = clientBackup.createdDate ?? Date()

                // 匯入月度資產
                for assetBackup in clientBackup.monthlyAssets {
                    let asset = MonthlyAsset(context: context)
                    asset.date = assetBackup.date
                    asset.createdDate = assetBackup.createdDate
                    asset.twdCash = assetBackup.twdCash
                    asset.cash = assetBackup.cash
                    asset.usStock = assetBackup.usStock
                    asset.usStockCost = assetBackup.usStockCost
                    asset.regularInvestment = assetBackup.regularInvestment
                    asset.regularInvestmentCost = assetBackup.regularInvestmentCost
                    asset.bonds = assetBackup.bonds
                    asset.bondsCost = assetBackup.bondsCost
                    asset.confirmedInterest = assetBackup.confirmedInterest
                    asset.structured = assetBackup.structured
                    asset.taiwanStock = assetBackup.taiwanStock
                    asset.taiwanStockCost = assetBackup.taiwanStockCost
                    asset.taiwanStockFolded = assetBackup.taiwanStockFolded
                    asset.twdToUsd = assetBackup.twdToUsd
                    asset.totalAssets = assetBackup.totalAssets
                    asset.exchangeRate = assetBackup.exchangeRate
                    asset.deposit = assetBackup.deposit
                    asset.depositAccumulated = assetBackup.depositAccumulated
                    asset.notes = assetBackup.notes
                    asset.fund = assetBackup.fund
                    asset.fundCost = assetBackup.fundCost
                    asset.insurance = assetBackup.insurance
                    asset.client = client
                }

                // 匯入公司債
                for bondBackup in clientBackup.corporateBonds {
                    let bond = CorporateBond(context: context)
                    bond.subscriptionDate = bondBackup.subscriptionDate
                    bond.subscriptionDateAsDate = bondBackup.subscriptionDateAsDate
                    bond.bondName = bondBackup.bondName
                    bond.currency = bondBackup.currency
                    bond.couponRate = bondBackup.couponRate
                    bond.yieldRate = bondBackup.yieldRate
                    bond.subscriptionPrice = bondBackup.subscriptionPrice
                    bond.subscriptionAmount = bondBackup.subscriptionAmount
                    bond.holdingFaceValue = bondBackup.holdingFaceValue
                    bond.previousHandInterest = bondBackup.previousHandInterest
                    bond.transactionAmount = bondBackup.transactionAmount
                    bond.currentValue = bondBackup.currentValue
                    bond.receivedInterest = bondBackup.receivedInterest
                    bond.profitLossWithInterest = bondBackup.profitLossWithInterest
                    bond.returnRate = bondBackup.returnRate
                    bond.dividendMonths = bondBackup.dividendMonths
                    bond.singleDividend = bondBackup.singleDividend
                    bond.annualDividend = bondBackup.annualDividend
                    bond.createdDate = bondBackup.createdDate
                    bond.client = client
                }

                // 匯入結構型商品
                for productBackup in clientBackup.structuredProducts {
                    let product = StructuredProduct(context: context)
                    product.numberOfTargets = productBackup.numberOfTargets
                    product.tradePricingDate = productBackup.tradePricingDate
                    product.target1 = productBackup.target1
                    product.target2 = productBackup.target2
                    product.target3 = productBackup.target3
                    product.issueDate = productBackup.issueDate
                    product.finalValuationDate = productBackup.finalValuationDate
                    product.initialPrice1 = productBackup.initialPrice1
                    product.initialPrice2 = productBackup.initialPrice2
                    product.initialPrice3 = productBackup.initialPrice3
                    product.strikePrice1 = productBackup.strikePrice1
                    product.strikePrice2 = productBackup.strikePrice2
                    product.strikePrice3 = productBackup.strikePrice3
                    product.distanceToExit1 = productBackup.distanceToExit1
                    product.distanceToExit2 = productBackup.distanceToExit2
                    product.distanceToExit3 = productBackup.distanceToExit3
                    product.currentPrice1 = productBackup.currentPrice1
                    product.currentPrice2 = productBackup.currentPrice2
                    product.currentPrice3 = productBackup.currentPrice3
                    product.interestRate = productBackup.interestRate
                    product.monthlyRate = productBackup.monthlyRate
                    product.transactionAmount = productBackup.transactionAmount
                    product.exitDate = productBackup.exitDate
                    product.holdingMonths = productBackup.holdingMonths
                    product.actualReturn = productBackup.actualReturn
                    product.realProfit = productBackup.realProfit
                    product.notes = productBackup.notes
                    product.createdDate = productBackup.createdDate
                    product.isExited = productBackup.isExited
                    product.exitCategory = productBackup.exitCategory
                    product.client = client
                }

                // 匯入美股
                for stockBackup in clientBackup.usStocks {
                    let stock = USStock(context: context)
                    stock.market = stockBackup.market
                    stock.name = stockBackup.name
                    stock.shares = stockBackup.shares
                    stock.cost = stockBackup.cost
                    stock.costPerShare = stockBackup.costPerShare
                    stock.currentPrice = stockBackup.currentPrice
                    stock.marketValue = stockBackup.marketValue
                    stock.profitLoss = stockBackup.profitLoss
                    stock.returnRate = stockBackup.returnRate
                    stock.currency = stockBackup.currency
                    stock.comment = stockBackup.comment
                    stock.createdDate = stockBackup.createdDate
                    stock.client = client
                }

                // 匯入台股
                for stockBackup in clientBackup.taiwanStocks {
                    let stock = TWStock(context: context)
                    stock.name = stockBackup.name
                    stock.shares = stockBackup.shares
                    stock.cost = stockBackup.cost
                    stock.costPerShare = stockBackup.costPerShare
                    stock.currentPrice = stockBackup.currentPrice
                    stock.marketValue = stockBackup.marketValue
                    stock.profitLoss = stockBackup.profitLoss
                    stock.returnRate = stockBackup.returnRate
                    stock.currency = stockBackup.currency
                    stock.comment = stockBackup.comment
                    stock.createdDate = stockBackup.createdDate
                    stock.client = client
                }

                // 匯入保單
                for policyBackup in clientBackup.insurancePolicies {
                    let policy = InsurancePolicy(context: context)
                    policy.policyType = policyBackup.policyType
                    policy.insuranceCompany = policyBackup.insuranceCompany
                    policy.policyNumber = policyBackup.policyNumber
                    policy.policyName = policyBackup.policyName
                    policy.policyHolder = policyBackup.policyHolder
                    policy.insuredPerson = policyBackup.insuredPerson
                    policy.startDate = policyBackup.startDate
                    policy.paymentMonth = policyBackup.paymentMonth
                    policy.coverageAmount = policyBackup.coverageAmount
                    policy.annualPremium = policyBackup.annualPremium
                    policy.paymentPeriod = policyBackup.paymentPeriod
                    policy.beneficiary = policyBackup.beneficiary
                    policy.interestRate = policyBackup.interestRate
                    policy.currency = policyBackup.currency
                    policy.createdDate = policyBackup.createdDate
                    policy.client = client
                }

                // 匯入貸款
                for loanBackup in clientBackup.loans {
                    let loan = Loan(context: context)
                    loan.loanType = loanBackup.loanType
                    loan.loanName = loanBackup.loanName
                    loan.loanAmount = loanBackup.loanAmount
                    loan.usedLoanAmount = loanBackup.usedLoanAmount
                    loan.interestRate = loanBackup.interestRate
                    loan.loanTerm = loanBackup.loanTerm
                    loan.startDate = loanBackup.startDate
                    loan.endDate = loanBackup.endDate
                    loan.gracePeriodPayment = loanBackup.gracePeriodPayment
                    loan.normalPayment = loanBackup.normalPayment
                    loan.totalPaid = loanBackup.totalPaid
                    loan.remainingBalance = loanBackup.remainingBalance
                    loan.notes = loanBackup.notes
                    loan.gracePeriod = loanBackup.gracePeriod
                    loan.createdDate = loanBackup.createdDate
                    loan.client = client
                }
            }

            try context.save()
        }
    }
}

// MARK: - 錯誤類型

enum BackupError: LocalizedError {
    case iCloudNotAvailable
    case noBackupFound
    case exportFailed
    case importFailed

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud 不可用，請確認已登入 iCloud"
        case .noBackupFound:
            return "找不到備份檔案"
        case .exportFailed:
            return "匯出資料失敗"
        case .importFailed:
            return "匯入資料失敗"
        }
    }
}

// MARK: - 備份資料結構

struct BackupData: Codable {
    var version: String = "1.0"
    var backupDate: Date?
    var clients: [ClientBackup] = []
}

struct ClientBackup: Codable {
    var id: String
    var name: String
    var email: String?
    var birthday: Date?
    var createdDate: Date?
    var monthlyAssets: [MonthlyAssetBackup] = []
    var corporateBonds: [CorporateBondBackup] = []
    var structuredProducts: [StructuredProductBackup] = []
    var usStocks: [USStockBackup] = []
    var taiwanStocks: [TWStockBackup] = []
    var insurancePolicies: [InsurancePolicyBackup] = []
    var loans: [LoanBackup] = []
}

struct MonthlyAssetBackup: Codable {
    var date: String?
    var createdDate: Date?
    var twdCash: String?
    var cash: String?
    var usStock: String?
    var usStockCost: String?
    var regularInvestment: String?
    var regularInvestmentCost: String?
    var bonds: String?
    var bondsCost: String?
    var confirmedInterest: String?
    var structured: String?
    var taiwanStock: String?
    var taiwanStockCost: String?
    var taiwanStockFolded: String?
    var twdToUsd: String?
    var totalAssets: String?
    var exchangeRate: String?
    var deposit: String?
    var depositAccumulated: String?
    var notes: String?
    var fund: String?
    var fundCost: String?
    var insurance: String?
}

struct CorporateBondBackup: Codable {
    var subscriptionDate: String?
    var subscriptionDateAsDate: Date?
    var bondName: String?
    var currency: String?
    var couponRate: String?
    var yieldRate: String?
    var subscriptionPrice: String?
    var subscriptionAmount: String?
    var holdingFaceValue: String?
    var previousHandInterest: String?
    var transactionAmount: String?
    var currentValue: String?
    var receivedInterest: String?
    var profitLossWithInterest: String?
    var returnRate: String?
    var dividendMonths: String?
    var singleDividend: String?
    var annualDividend: String?
    var createdDate: Date?
}

struct StructuredProductBackup: Codable {
    var numberOfTargets: Int16
    var tradePricingDate: String?
    var target1: String?
    var target2: String?
    var target3: String?
    var issueDate: String?
    var finalValuationDate: String?
    var initialPrice1: String?
    var initialPrice2: String?
    var initialPrice3: String?
    var strikePrice1: String?
    var strikePrice2: String?
    var strikePrice3: String?
    var distanceToExit1: String?
    var distanceToExit2: String?
    var distanceToExit3: String?
    var currentPrice1: String?
    var currentPrice2: String?
    var currentPrice3: String?
    var interestRate: String?
    var monthlyRate: String?
    var transactionAmount: String?
    var exitDate: String?
    var holdingMonths: String?
    var actualReturn: String?
    var realProfit: String?
    var notes: String?
    var createdDate: Date?
    var isExited: Bool
    var exitCategory: String?
}

struct USStockBackup: Codable {
    var market: String?
    var name: String?
    var shares: String?
    var cost: String?
    var costPerShare: String?
    var currentPrice: String?
    var marketValue: String?
    var profitLoss: String?
    var returnRate: String?
    var currency: String?
    var comment: String?
    var createdDate: Date?
}

struct TWStockBackup: Codable {
    var name: String?
    var shares: String?
    var cost: String?
    var costPerShare: String?
    var currentPrice: String?
    var marketValue: String?
    var profitLoss: String?
    var returnRate: String?
    var currency: String?
    var comment: String?
    var createdDate: Date?
}

struct InsurancePolicyBackup: Codable {
    var policyType: String?
    var insuranceCompany: String?
    var policyNumber: String?
    var policyName: String?
    var policyHolder: String?
    var insuredPerson: String?
    var startDate: String?
    var paymentMonth: String?
    var coverageAmount: String?
    var annualPremium: String?
    var paymentPeriod: String?
    var beneficiary: String?
    var interestRate: String?
    var currency: String?
    var createdDate: Date?
}

struct LoanBackup: Codable {
    var loanType: String?
    var loanName: String?
    var loanAmount: String?
    var usedLoanAmount: String?
    var interestRate: String?
    var loanTerm: String?
    var startDate: String?
    var endDate: String?
    var gracePeriodPayment: String?
    var normalPayment: String?
    var totalPaid: String?
    var remainingBalance: String?
    var notes: String?
    var gracePeriod: Int16
    var createdDate: Date?
}
