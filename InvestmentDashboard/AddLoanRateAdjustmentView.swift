//
//  AddLoanRateAdjustmentView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/11/10.
//

import SwiftUI
import CoreData

struct AddLoanRateAdjustmentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let loan: Loan
    let previousEndDate: String
    let previousInterestRate: String
    let previousMonthlyPayment: String
    let previousRemainingBalance: String

    @State private var startDate = ""
    @State private var endDate = ""
    @State private var newInterestRate = ""
    @State private var newMonthlyPayment = ""
    @State private var remainingBalance = ""
    @State private var notes = ""

    init(loan: Loan, previousEndDate: String = "", previousInterestRate: String = "", previousMonthlyPayment: String = "", previousRemainingBalance: String = "") {
        self.loan = loan
        self.previousEndDate = previousEndDate
        self.previousInterestRate = previousInterestRate
        self.previousMonthlyPayment = previousMonthlyPayment
        self.previousRemainingBalance = previousRemainingBalance

        // 格式化金額為千分位
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        let formattedPayment: String
        if let num = Double(previousMonthlyPayment.replacingOccurrences(of: ",", with: "")) {
            formattedPayment = formatter.string(from: NSNumber(value: num)) ?? previousMonthlyPayment
        } else {
            formattedPayment = previousMonthlyPayment
        }

        let formattedBalance: String
        if let num = Double(previousRemainingBalance.replacingOccurrences(of: ",", with: "")) {
            formattedBalance = formatter.string(from: NSNumber(value: num)) ?? previousRemainingBalance
        } else {
            formattedBalance = previousRemainingBalance
        }

        // 預設填入上一期的資訊
        _startDate = State(initialValue: previousEndDate)
        _endDate = State(initialValue: loan.endDate ?? "")
        _newInterestRate = State(initialValue: previousInterestRate)
        _newMonthlyPayment = State(initialValue: formattedPayment)
        _remainingBalance = State(initialValue: formattedBalance)
    }

    // 格式化數字為千分位
    private func formatInput(_ value: String) -> String {
        let cleanValue = value.replacingOccurrences(of: ",", with: "")
        guard let number = Double(cleanValue) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    // 移除千分位符號
    private func removeFormatting(_ value: String) -> String {
        return value.replacingOccurrences(of: ",", with: "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("期間日期")) {
                    TextField("開始日期 (YYYY-MM-DD)", text: $startDate)
                        .keyboardType(.numbersAndPunctuation)

                    TextField("結束日期 (YYYY-MM-DD)", text: $endDate)
                        .keyboardType(.numbersAndPunctuation)
                }

                Section(header: Text("新利率與月付金")) {
                    HStack {
                        TextField("新利率", text: $newInterestRate)
                            .keyboardType(.decimalPad)
                        Text("%")
                            .foregroundColor(.secondary)
                    }

                    TextField("新月付金", text: $newMonthlyPayment)
                        .keyboardType(.decimalPad)
                        .onChange(of: newMonthlyPayment) { oldValue, newValue in
                            let cleaned = removeFormatting(newValue)
                            if !cleaned.isEmpty, Double(cleaned) != nil {
                                let formatted = formatInput(cleaned)
                                if formatted != newValue {
                                    newMonthlyPayment = formatted
                                }
                            }
                        }
                }

                Section(header: Text("當時剩餘本金")) {
                    TextField("剩餘本金", text: $remainingBalance)
                        .keyboardType(.decimalPad)
                        .onChange(of: remainingBalance) { oldValue, newValue in
                            let cleaned = removeFormatting(newValue)
                            if !cleaned.isEmpty, Double(cleaned) != nil {
                                let formatted = formatInput(cleaned)
                                if formatted != newValue {
                                    remainingBalance = formatted
                                }
                            }
                        }
                }

                Section(header: Text("備註 (選填)")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("說明")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("• 開始日期：這個利率期間的開始日期")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 結束日期：這個利率期間的結束日期")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 新利率：這個期間使用的年利率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 新月付金：這個期間每月需要繳納的金額")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 剩餘本金：期間開始時的剩餘貸款本金")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("新增利率調整")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveRateAdjustment()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    // 檢查表單是否有效
    private var isFormValid: Bool {
        return !startDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !endDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !newInterestRate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !newMonthlyPayment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !remainingBalance.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // 保存利率調整記錄
    private func saveRateAdjustment() {
        withAnimation {
            let adjustment = LoanRateAdjustment(context: viewContext)

            // 使用開始日期作為 adjustmentDate（保持與現有結構兼容）
            adjustment.adjustmentDate = startDate.trimmingCharacters(in: .whitespacesAndNewlines)
            adjustment.newInterestRate = newInterestRate.trimmingCharacters(in: .whitespacesAndNewlines)
            adjustment.newMonthlyPayment = removeFormatting(newMonthlyPayment).trimmingCharacters(in: .whitespacesAndNewlines)
            adjustment.remainingBalance = removeFormatting(remainingBalance).trimmingCharacters(in: .whitespacesAndNewlines)

            // 將結束日期儲存在備註中（暫時方案）
            var notesText = "結束日期: \(endDate.trimmingCharacters(in: .whitespacesAndNewlines))"
            if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                notesText += "\n\n" + notes.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            adjustment.notes = notesText

            adjustment.createdDate = Date()
            adjustment.loan = loan

            // 將字串日期轉換為 Date 對象以便排序
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: startDate) {
                adjustment.adjustmentDateAsDate = date
            }

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("利率調整記錄已成功儲存")
                dismiss()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let loan = Loan(context: context)
    loan.loanName = "測試貸款"
    loan.loanAmount = "5000000"
    loan.interestRate = "2.0"

    return AddLoanRateAdjustmentView(
        loan: loan,
        previousEndDate: "2025-01-01",
        previousInterestRate: "2.0",
        previousMonthlyPayment: "30000",
        previousRemainingBalance: "4800000"
    )
    .environment(\.managedObjectContext, context)
}
