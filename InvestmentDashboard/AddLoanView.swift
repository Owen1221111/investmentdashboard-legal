//
//  AddLoanView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/11/10.
//

import SwiftUI
import CoreData

struct AddLoanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client
    let loanToEdit: Loan?

    @State private var loanType = "房貸"
    @State private var loanName = ""
    @State private var loanAmount = ""
    @State private var usedLoanAmount = ""
    @State private var interestRate = ""
    @State private var loanTerm = ""
    @State private var startDate = ""
    @State private var endDate = ""
    @State private var gracePeriodPayment = "" // 寬限還款金額
    @State private var normalPayment = "" // 非寬限還款金額
    @State private var totalPaid = ""
    @State private var remainingBalance = ""
    @State private var notes = ""
    @State private var gracePeriod = 0 // 寬限期 (年)

    @State private var showingDatePicker = false
    @State private var isUpdatingFromDate = false // 防止循環更新

    let loanTypes = ["房貸", "理財型房貸", "車貸", "信用貸款", "學生貸款", "其他"]

    init(client: Client, loanToEdit: Loan? = nil) {
        self.client = client
        self.loanToEdit = loanToEdit

        if let loan = loanToEdit {
            _loanType = State(initialValue: loan.loanType ?? "房貸")
            _loanName = State(initialValue: loan.loanName ?? "")
            _loanAmount = State(initialValue: Self.formatNumberForDisplay(loan.loanAmount ?? ""))
            _usedLoanAmount = State(initialValue: Self.formatNumberForDisplay(loan.usedLoanAmount ?? ""))
            _interestRate = State(initialValue: loan.interestRate ?? "")
            _loanTerm = State(initialValue: loan.loanTerm ?? "")
            _startDate = State(initialValue: loan.startDate ?? "")
            _endDate = State(initialValue: loan.endDate ?? "")
            _gracePeriodPayment = State(initialValue: Self.formatNumberForDisplay(loan.gracePeriodPayment ?? ""))
            _normalPayment = State(initialValue: Self.formatNumberForDisplay(loan.normalPayment ?? ""))
            _totalPaid = State(initialValue: Self.formatNumberForDisplay(loan.totalPaid ?? ""))
            _remainingBalance = State(initialValue: Self.formatNumberForDisplay(loan.remainingBalance ?? ""))
            _notes = State(initialValue: loan.notes ?? "")
            _gracePeriod = State(initialValue: Int(loan.gracePeriod))
        }
    }

    // 計算兩個日期之間的年份差
    private func calculateYearsBetweenDates(start: String, end: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let startDate = dateFormatter.date(from: start),
              let endDate = dateFormatter.date(from: end) else {
            return ""
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: startDate, to: endDate)

        if let years = components.year, let months = components.month {
            if months >= 6 {
                return "\(years + 1)"
            } else {
                return "\(years)"
            }
        }

        return ""
    }

    // 根據開始日期和貸款年限計算結束日期
    private func calculateEndDate(start: String, years: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let startDate = dateFormatter.date(from: start),
              let yearsInt = Int(years) else {
            return ""
        }

        let calendar = Calendar.current
        if let endDate = calendar.date(byAdding: .year, value: yearsInt, to: startDate) {
            return dateFormatter.string(from: endDate)
        }

        return ""
    }

    // 格式化數字為千分位
    private static func formatNumberForDisplay(_ value: String) -> String {
        let cleanValue = value.replacingOccurrences(of: ",", with: "")
        guard let number = Double(cleanValue) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    // 移除千分位符號，只保留數字
    private func removeFormatting(_ value: String) -> String {
        return value.replacingOccurrences(of: ",", with: "")
    }

    // 格式化輸入的數字
    private func formatInput(_ value: String) -> String {
        let cleanValue = removeFormatting(value)
        guard let number = Double(cleanValue) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    var body: some View {
        NavigationView {
            Form {
                Section("貸款基本資訊") {
                    Picker("貸款類型", selection: $loanType) {
                        ForEach(loanTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }

                    HStack {
                        Text("貸款名稱")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $loanName)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("貸款金額")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $loanAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: loanAmount) { oldValue, newValue in
                                let cleaned = removeFormatting(newValue)
                                // 只在輸入的是有效數字時才格式化
                                if !cleaned.isEmpty, Double(cleaned) != nil {
                                    let formatted = formatInput(cleaned)
                                    if formatted != newValue {
                                        loanAmount = formatted
                                    }
                                }
                            }
                    }

                    HStack {
                        Text("已動用累積")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $usedLoanAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: usedLoanAmount) { oldValue, newValue in
                                let cleaned = removeFormatting(newValue)
                                // 只在輸入的是有效數字時才格式化
                                if !cleaned.isEmpty, Double(cleaned) != nil {
                                    let formatted = formatInput(cleaned)
                                    if formatted != newValue {
                                        usedLoanAmount = formatted
                                    }
                                }
                            }
                    }

                    HStack {
                        Text("利率 (%)")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $interestRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("開始日期")
                            .frame(width: 100, alignment: .leading)
                        TextField("YYYY-MM-DD", text: $startDate)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: startDate) { oldValue, newValue in
                                // 當開始日期改變時，如果有結束日期，自動計算貸款年限
                                if !isUpdatingFromDate && !endDate.isEmpty && !newValue.isEmpty {
                                    isUpdatingFromDate = true
                                    let years = calculateYearsBetweenDates(start: newValue, end: endDate)
                                    if !years.isEmpty {
                                        loanTerm = years
                                    }
                                    isUpdatingFromDate = false
                                }
                                // 如果有貸款年限，自動計算結束日期
                                else if !isUpdatingFromDate && !loanTerm.isEmpty && !newValue.isEmpty {
                                    isUpdatingFromDate = true
                                    let calculatedEndDate = calculateEndDate(start: newValue, years: loanTerm)
                                    if !calculatedEndDate.isEmpty {
                                        endDate = calculatedEndDate
                                    }
                                    isUpdatingFromDate = false
                                }
                            }
                    }

                    HStack {
                        Text("貸款期限 (年)")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $loanTerm)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: loanTerm) { oldValue, newValue in
                                // 當貸款年限改變時，如果有開始日期，自動計算結束日期
                                if !isUpdatingFromDate && !startDate.isEmpty && !newValue.isEmpty {
                                    isUpdatingFromDate = true
                                    let calculatedEndDate = calculateEndDate(start: startDate, years: newValue)
                                    if !calculatedEndDate.isEmpty {
                                        endDate = calculatedEndDate
                                    }
                                    isUpdatingFromDate = false
                                }
                            }
                    }

                    HStack {
                        Text("結束日期")
                            .frame(width: 100, alignment: .leading)
                        TextField("YYYY-MM-DD", text: $endDate)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: endDate) { oldValue, newValue in
                                // 當結束日期改變時，如果有開始日期，自動計算貸款年限
                                if !isUpdatingFromDate && !startDate.isEmpty && !newValue.isEmpty {
                                    isUpdatingFromDate = true
                                    let years = calculateYearsBetweenDates(start: startDate, end: newValue)
                                    if !years.isEmpty {
                                        loanTerm = years
                                    }
                                    isUpdatingFromDate = false
                                }
                            }
                    }

                    Picker("寬限期 (年)", selection: $gracePeriod) {
                        ForEach(0...20, id: \.self) { years in
                            Text("\(years)").tag(years)
                        }
                    }
                }

                Section("還款資訊") {
                    HStack {
                        Text("寬限還款金額")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $gracePeriodPayment)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: gracePeriodPayment) { oldValue, newValue in
                                let cleaned = removeFormatting(newValue)
                                if !cleaned.isEmpty, Double(cleaned) != nil {
                                    let formatted = formatInput(cleaned)
                                    if formatted != newValue {
                                        gracePeriodPayment = formatted
                                    }
                                }
                            }
                    }

                    HStack {
                        Text("非寬限還款金額")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $normalPayment)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: normalPayment) { oldValue, newValue in
                                let cleaned = removeFormatting(newValue)
                                if !cleaned.isEmpty, Double(cleaned) != nil {
                                    let formatted = formatInput(cleaned)
                                    if formatted != newValue {
                                        normalPayment = formatted
                                    }
                                }
                            }
                    }

                    HStack {
                        Text("已還款總額")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $totalPaid)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: totalPaid) { oldValue, newValue in
                                let cleaned = removeFormatting(newValue)
                                if !cleaned.isEmpty, Double(cleaned) != nil {
                                    let formatted = formatInput(cleaned)
                                    if formatted != newValue {
                                        totalPaid = formatted
                                    }
                                }
                            }
                    }

                    HStack {
                        Text("剩餘本金")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $remainingBalance)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
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
                }

                Section("備註") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(loanToEdit == nil ? "新增貸款" : "編輯貸款")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveLoan()
                    }
                    .disabled(loanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveLoan() {
        withAnimation {
            let loan = loanToEdit ?? Loan(context: viewContext)

            loan.loanType = loanType
            loan.loanName = loanName.trimmingCharacters(in: .whitespacesAndNewlines)
            // 儲存時移除千分位符號
            loan.loanAmount = removeFormatting(loanAmount).trimmingCharacters(in: .whitespacesAndNewlines)
            loan.usedLoanAmount = removeFormatting(usedLoanAmount).trimmingCharacters(in: .whitespacesAndNewlines)
            loan.interestRate = interestRate.trimmingCharacters(in: .whitespacesAndNewlines)
            loan.loanTerm = loanTerm.trimmingCharacters(in: .whitespacesAndNewlines)
            loan.startDate = startDate.trimmingCharacters(in: .whitespacesAndNewlines)
            loan.endDate = endDate.trimmingCharacters(in: .whitespacesAndNewlines)
            loan.gracePeriodPayment = removeFormatting(gracePeriodPayment).trimmingCharacters(in: .whitespacesAndNewlines)
            loan.normalPayment = removeFormatting(normalPayment).trimmingCharacters(in: .whitespacesAndNewlines)
            loan.totalPaid = removeFormatting(totalPaid).trimmingCharacters(in: .whitespacesAndNewlines)
            loan.remainingBalance = removeFormatting(remainingBalance).trimmingCharacters(in: .whitespacesAndNewlines)
            loan.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            loan.gracePeriod = Int16(gracePeriod)

            if loanToEdit == nil {
                loan.createdDate = Date()
                loan.client = client
            }

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("貸款已成功儲存")
                dismiss()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let client = Client(context: context)
    client.name = "測試客戶"

    return AddLoanView(client: client)
        .environment(\.managedObjectContext, context)
}
