//
//  InsuranceCalculatorRow.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/16.
//  保險試算表資料行 Entity
//

import Foundation
import CoreData

// MARK: - Core Data Entity: InsuranceCalculatorRow
//
// 請在 Xcode 的 DataModel.xcdatamodeld 中手動建立此 Entity，包含以下屬性：
//
// Entity Name: InsuranceCalculatorRow
//
// Attributes:
// - policyYear: String (保單年度)
// - insuranceAge: String (保險年齡)
// - cashValue: String (保單現金價值/解約金)
// - deathBenefit: String (身故保險金)
// - rowOrder: Int16 (排序順序)
// - createdDate: Date (建立日期)
//
// Relationships:
// - calculator: InsuranceCalculator (對應的試算表，inverse: rows)
//
// ⚠️ 重要：此檔案僅作為參考文件，實際的 Entity 需要在 Xcode 中手動建立

// ⚠️ 此 extension 需要在 Core Data 中建立 InsuranceCalculatorRow Entity 後才能使用
// 暫時註解，待 Entity 建立後再取消註解

/*
extension InsuranceCalculatorRow {

    /// 建立新的試算表資料行
    static func create(
        in context: NSManagedObjectContext,
        calculator: InsuranceCalculator,
        policyYear: String,
        insuranceAge: String,
        cashValue: String,
        deathBenefit: String,
        rowOrder: Int16
    ) -> InsuranceCalculatorRow {
        let row = InsuranceCalculatorRow(context: context)
        row.calculator = calculator
        row.policyYear = policyYear
        row.insuranceAge = insuranceAge
        row.cashValue = cashValue
        row.deathBenefit = deathBenefit
        row.rowOrder = rowOrder
        row.createdDate = Date()
        return row
    }
}
*/

// MARK: - 試算表資料結構（用於CSV和OCR）

/// 試算表單行資料（解析用）
struct CalculatorRowData {
    var policyYear: String      // 保單年度
    var insuranceAge: String    // 保險年齡
    var cashValue: String       // 保單現金價值（解約金）
    var deathBenefit: String    // 身故保險金

    /// 初始化（所有欄位都是空字串）
    init() {
        self.policyYear = ""
        self.insuranceAge = ""
        self.cashValue = ""
        self.deathBenefit = ""
    }

    /// 初始化（指定欄位）
    init(policyYear: String, insuranceAge: String, cashValue: String, deathBenefit: String) {
        self.policyYear = policyYear
        self.insuranceAge = insuranceAge
        self.cashValue = cashValue
        self.deathBenefit = deathBenefit
    }

    /// 檢查是否為空行
    var isEmpty: Bool {
        return policyYear.isEmpty && insuranceAge.isEmpty && cashValue.isEmpty && deathBenefit.isEmpty
    }

    /// 檢查是否為有效行（至少有一個欄位有值）
    var isValid: Bool {
        return !isEmpty
    }
}
