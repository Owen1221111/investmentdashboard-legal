//
//  AddLoanMonthlyDataView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/11/11.
//

import SwiftUI
import CoreData

struct AddLoanMonthlyDataView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext

    let client: Client
    let dataToEdit: LoanMonthlyData?

    @State private var selectedDate = Date()
    @State private var selectedLoan: Loan? = nil
    @State private var loanType = ""
    @State private var loanAmount = ""
    @State private var monthlyPayment = "" // 月付金
    @State private var usedLoanAmount = ""
    @State private var usedLoanAccumulated = ""
    @State private var baseAccumulated: Double = 0  // 基礎已動用累積（選擇貸款時的值）
    @State private var taiwanStock = ""
    @State private var usStock = ""
    @State private var bonds = ""
    @State private var regularInvestment = ""
    @State private var taiwanStockCost = ""
    @State private var usStockCost = ""
    @State private var bondsCost = ""
    @State private var regularInvestmentCost = ""
    @State private var exchangeRate = "32"

    // 獲取客戶的貸款列表
    private var loans: [Loan] {
        guard let loansSet = client.loans as? Set<Loan> else { return [] }
        return loansSet.sorted { ($0.createdDate ?? Date()) > ($1.createdDate ?? Date()) }
    }

    // 計算屬性：美股加債券折合台幣 = (美股 + 債券) * 匯率
    private var calculatedUsStockBondsInTwd: String {
        let usStockValue = Double(removeCommas(usStock)) ?? 0
        let bondsValue = Double(removeCommas(bonds)) ?? 0
        let exchangeRateValue = Double(removeCommas(exchangeRate)) ?? 32

        let result = (usStockValue + bondsValue) * exchangeRateValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    // 計算屬性：投資總額 = 台股 + 美股加債券折合台幣
    private var calculatedTotalInvestment: String {
        let taiwanStockValue = Double(removeCommas(taiwanStock)) ?? 0
        let usStockBondsInTwdValue = Double(removeCommas(calculatedUsStockBondsInTwd)) ?? 0

        let result = taiwanStockValue + usStockBondsInTwdValue
        return formatWithCommas(String(format: "%.2f", result))
    }

    init(client: Client, dataToEdit: LoanMonthlyData? = nil) {
        self.client = client
        self.dataToEdit = dataToEdit

        if let data = dataToEdit {
            // 編輯模式：載入要編輯的資料
            _loanType = State(initialValue: data.loanType ?? "")
            _loanAmount = State(initialValue: Self.formatNumberForDisplay(data.loanAmount ?? ""))
            _monthlyPayment = State(initialValue: Self.formatNumberForDisplay(data.monthlyPayment ?? ""))
            _usedLoanAmount = State(initialValue: Self.formatNumberForDisplay(data.usedLoanAmount ?? ""))
            _usedLoanAccumulated = State(initialValue: Self.formatNumberForDisplay(data.usedLoanAccumulated ?? ""))
            _taiwanStock = State(initialValue: Self.formatNumberForDisplay(data.taiwanStock ?? ""))
            _usStock = State(initialValue: Self.formatNumberForDisplay(data.usStock ?? ""))
            _bonds = State(initialValue: Self.formatNumberForDisplay(data.bonds ?? ""))
            _regularInvestment = State(initialValue: Self.formatNumberForDisplay(data.regularInvestment ?? ""))
            _taiwanStockCost = State(initialValue: Self.formatNumberForDisplay(data.taiwanStockCost ?? ""))
            _usStockCost = State(initialValue: Self.formatNumberForDisplay(data.usStockCost ?? ""))
            _bondsCost = State(initialValue: Self.formatNumberForDisplay(data.bondsCost ?? ""))
            _regularInvestmentCost = State(initialValue: Self.formatNumberForDisplay(data.regularInvestmentCost ?? ""))
            _exchangeRate = State(initialValue: data.exchangeRate ?? "32")

            // 解析日期
            if let dateStr = data.date, !dateStr.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateStr) {
                    _selectedDate = State(initialValue: date)
                }
            }

            // 根據 loanType 找到對應的 Loan（編輯模式）
            if let loansSet = client.loans as? Set<Loan> {
                let foundLoan = loansSet.first { $0.loanType == data.loanType }
                _selectedLoan = State(initialValue: foundLoan)

                // 設置基礎累積（編輯模式下，基礎累積應該是當前累積 - 本次已動用）
                if let accumulated = Double(data.usedLoanAccumulated ?? "0"),
                   let used = Double(data.usedLoanAmount ?? "0") {
                    _baseAccumulated = State(initialValue: accumulated - used)
                }
            }
        } else {
            // 新增模式：查詢最新一筆資料並預填
            let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "client == %@", client)
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
            fetchRequest.fetchLimit = 1

            let context = PersistenceController.shared.container.viewContext
            if let latestData = try? context.fetch(fetchRequest).first {
                // 預填投資資產數據（不包含貸款資訊）
                _taiwanStock = State(initialValue: Self.formatNumberForDisplay(latestData.taiwanStock ?? ""))
                _usStock = State(initialValue: Self.formatNumberForDisplay(latestData.usStock ?? ""))
                _bonds = State(initialValue: Self.formatNumberForDisplay(latestData.bonds ?? ""))
                _regularInvestment = State(initialValue: Self.formatNumberForDisplay(latestData.regularInvestment ?? ""))
                _taiwanStockCost = State(initialValue: Self.formatNumberForDisplay(latestData.taiwanStockCost ?? ""))
                _usStockCost = State(initialValue: Self.formatNumberForDisplay(latestData.usStockCost ?? ""))
                _bondsCost = State(initialValue: Self.formatNumberForDisplay(latestData.bondsCost ?? ""))
                _regularInvestmentCost = State(initialValue: Self.formatNumberForDisplay(latestData.regularInvestmentCost ?? ""))
                _exchangeRate = State(initialValue: latestData.exchangeRate ?? "32")
            }
        }
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

    // 移除千分位符號
    private func removeCommas(_ value: String) -> String {
        return value.replacingOccurrences(of: ",", with: "")
    }

    // 格式化輸入的數字
    private func formatInput(_ value: String) -> String {
        let cleanValue = removeCommas(value)
        guard let number = Double(cleanValue) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    // 格式化數字並加千分位
    private func formatWithCommas(_ value: String) -> String {
        let cleanValue = value.replacingOccurrences(of: ",", with: "")
        guard let number = Double(cleanValue) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    // 判斷是否在寬限期內
    private func isInGracePeriod(loan: Loan, currentDate: Date) -> Bool {
        guard let startDateStr = loan.startDate, !startDateStr.isEmpty else {
            return false
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let startDate = dateFormatter.date(from: startDateStr) else {
            return false
        }

        let gracePeriodYears = Int(loan.gracePeriod)
        guard gracePeriodYears > 0 else {
            return false
        }

        let calendar = Calendar.current
        if let gracePeriodEndDate = calendar.date(byAdding: .year, value: gracePeriodYears, to: startDate) {
            return currentDate < gracePeriodEndDate
        }

        return false
    }

    // 自動計算月付金
    private func calculateMonthlyPayment(loan: Loan) -> String {
        let inGracePeriod = isInGracePeriod(loan: loan, currentDate: selectedDate)

        if inGracePeriod {
            // 在寬限期內，使用寬限還款金額
            return Self.formatNumberForDisplay(loan.gracePeriodPayment ?? "0")
        } else {
            // 不在寬限期內，使用非寬限還款金額
            return Self.formatNumberForDisplay(loan.normalPayment ?? "0")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("基本資訊") {
                    DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) { oldValue, newValue in
                            // 當日期改變時，重新計算月付金（判斷是否進入或離開寬限期）
                            if let loan = selectedLoan {
                                monthlyPayment = calculateMonthlyPayment(loan: loan)
                            }
                        }

                    // 貸款選擇器
                    if loans.isEmpty {
                        Text("尚無貸款記錄")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("貸款", selection: $selectedLoan) {
                            Text("請選擇貸款").tag(nil as Loan?)
                            ForEach(loans, id: \.self) { loan in
                                Text(loan.loanName ?? "未命名貸款")
                                    .tag(loan as Loan?)
                            }
                        }
                        .onChange(of: selectedLoan) { oldValue, newValue in
                            if let loan = newValue {
                                loanType = loan.loanType ?? ""
                                loanAmount = Self.formatNumberForDisplay(loan.loanAmount ?? "0")

                                // 自動計算月付金（根據是否在寬限期內）
                                monthlyPayment = calculateMonthlyPayment(loan: loan)

                                // 查詢該貸款最新一筆月度記錄的已動用累積
                                let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
                                fetchRequest.predicate = NSPredicate(
                                    format: "client == %@ AND loanType == %@",
                                    client,
                                    loan.loanType ?? ""
                                )
                                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
                                fetchRequest.fetchLimit = 1

                                do {
                                    let results = try viewContext.fetch(fetchRequest)
                                    if let latestRecord = results.first {
                                        // 使用最新記錄的累積值作為基礎
                                        baseAccumulated = Double(latestRecord.usedLoanAccumulated ?? "0") ?? 0
                                        usedLoanAccumulated = Self.formatNumberForDisplay(latestRecord.usedLoanAccumulated ?? "0")
                                    } else {
                                        // 沒有歷史記錄，從 0 開始
                                        baseAccumulated = 0
                                        usedLoanAccumulated = "0"
                                    }
                                } catch {
                                    print("查詢最新記錄錯誤: \(error)")
                                    baseAccumulated = 0
                                    usedLoanAccumulated = "0"
                                }

                                // 清空已動用貸款欄位
                                usedLoanAmount = ""
                            }
                        }
                    }

                    HStack {
                        Text("貸款金額")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $loanAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: loanAmount) { oldValue, newValue in
                                formatNumberField(&loanAmount, newValue)
                            }
                    }

                    HStack {
                        Text("月付金")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $monthlyPayment)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: monthlyPayment) { oldValue, newValue in
                                formatNumberField(&monthlyPayment, newValue)
                            }
                    }

                    HStack {
                        Text("已動用貸款")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $usedLoanAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: usedLoanAmount) { oldValue, newValue in
                                formatNumberField(&usedLoanAmount, newValue)

                                // 自動計算累積：基礎累積 + 本次已動用
                                let currentUsed = Double(removeCommas(usedLoanAmount)) ?? 0
                                let newAccumulated = baseAccumulated + currentUsed
                                usedLoanAccumulated = Self.formatNumberForDisplay(String(format: "%.2f", newAccumulated))
                            }
                    }

                    HStack {
                        Text("已動用累積")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $usedLoanAccumulated)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: usedLoanAccumulated) { oldValue, newValue in
                                formatNumberField(&usedLoanAccumulated, newValue)
                            }
                    }
                }

                Section("投資資產") {
                    HStack {
                        Text("台股")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $taiwanStock)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: taiwanStock) { oldValue, newValue in
                                formatNumberField(&taiwanStock, newValue)
                            }
                    }

                    HStack {
                        Text("美股")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $usStock)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: usStock) { oldValue, newValue in
                                formatNumberField(&usStock, newValue)
                            }
                    }

                    HStack {
                        Text("債券")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $bonds)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: bonds) { oldValue, newValue in
                                formatNumberField(&bonds, newValue)
                            }
                    }

                    HStack {
                        Text("定期定額")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $regularInvestment)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: regularInvestment) { oldValue, newValue in
                                formatNumberField(&regularInvestment, newValue)
                            }
                    }
                }

                Section("成本資訊") {
                    HStack {
                        Text("台股成本")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $taiwanStockCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: taiwanStockCost) { oldValue, newValue in
                                formatNumberField(&taiwanStockCost, newValue)
                            }
                    }

                    HStack {
                        Text("美股成本")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $usStockCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: usStockCost) { oldValue, newValue in
                                formatNumberField(&usStockCost, newValue)
                            }
                    }

                    HStack {
                        Text("債券成本")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $bondsCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: bondsCost) { oldValue, newValue in
                                formatNumberField(&bondsCost, newValue)
                            }
                    }

                    HStack {
                        Text("定期定額成本")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $regularInvestmentCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: regularInvestmentCost) { oldValue, newValue in
                                formatNumberField(&regularInvestmentCost, newValue)
                            }
                    }
                }

                Section("匯率與計算") {
                    HStack {
                        Text("匯率")
                            .frame(width: 100, alignment: .leading)
                        TextField("", text: $exchangeRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("美股加債券折合台幣")
                        Spacer()
                        Text(calculatedUsStockBondsInTwd)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("投資總額")
                        Spacer()
                        Text(calculatedTotalInvestment)
                            .foregroundColor(.secondary)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .navigationTitle(dataToEdit == nil ? "新增月度數據" : "編輯月度數據")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveData()
                    }
                }
            }
        }
    }

    private func formatNumberField(_ field: inout String, _ newValue: String) {
        let cleaned = removeCommas(newValue)
        if !cleaned.isEmpty, Double(cleaned) != nil {
            let formatted = formatInput(cleaned)
            if formatted != newValue {
                field = formatted
            }
        }
    }

    private func saveData() {
        withAnimation {
            let data = dataToEdit ?? LoanMonthlyData(context: viewContext)

            // 格式化日期
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            data.date = dateFormatter.string(from: selectedDate)

            data.loanType = loanType.trimmingCharacters(in: .whitespacesAndNewlines)
            data.loanAmount = removeCommas(loanAmount).trimmingCharacters(in: .whitespacesAndNewlines)
            data.monthlyPayment = removeCommas(monthlyPayment).trimmingCharacters(in: .whitespacesAndNewlines)
            data.usedLoanAmount = removeCommas(usedLoanAmount).trimmingCharacters(in: .whitespacesAndNewlines)
            data.usedLoanAccumulated = removeCommas(usedLoanAccumulated).trimmingCharacters(in: .whitespacesAndNewlines)
            data.taiwanStock = removeCommas(taiwanStock).trimmingCharacters(in: .whitespacesAndNewlines)
            data.usStock = removeCommas(usStock).trimmingCharacters(in: .whitespacesAndNewlines)
            data.bonds = removeCommas(bonds).trimmingCharacters(in: .whitespacesAndNewlines)
            data.regularInvestment = removeCommas(regularInvestment).trimmingCharacters(in: .whitespacesAndNewlines)
            data.taiwanStockCost = removeCommas(taiwanStockCost).trimmingCharacters(in: .whitespacesAndNewlines)
            data.usStockCost = removeCommas(usStockCost).trimmingCharacters(in: .whitespacesAndNewlines)
            data.bondsCost = removeCommas(bondsCost).trimmingCharacters(in: .whitespacesAndNewlines)
            data.regularInvestmentCost = removeCommas(regularInvestmentCost).trimmingCharacters(in: .whitespacesAndNewlines)
            data.exchangeRate = exchangeRate.trimmingCharacters(in: .whitespacesAndNewlines)

            // 保存計算結果
            data.usStockBondsInTwd = removeCommas(calculatedUsStockBondsInTwd)
            data.totalInvestment = removeCommas(calculatedTotalInvestment)

            if dataToEdit == nil {
                data.createdDate = Date()
                data.client = client
            }

            do {
                try viewContext.save()

                // 保存後，重新計算該貸款類型所有資料的累積值
                if let loan = selectedLoan {
                    recalculateAccumulatedAmounts(for: loan.loanType ?? "")

                    // 更新 Loan 的累積值為最新記錄
                    let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
                    fetchRequest.predicate = NSPredicate(
                        format: "client == %@ AND loanType == %@",
                        client,
                        loan.loanType ?? ""
                    )
                    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
                    fetchRequest.fetchLimit = 1

                    if let latestRecord = try? viewContext.fetch(fetchRequest).first {
                        loan.usedLoanAmount = latestRecord.usedLoanAccumulated ?? "0"
                    }

                    try viewContext.save()
                }

                PersistenceController.shared.save()
                print("貸款月度數據已成功儲存，並重新計算累積值")
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Save error: \(error)")
            }
        }
    }

    /// 重新計算該貸款類型所有月度資料的已動用累積
    private func recalculateAccumulatedAmounts(for loanType: String) {
        let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "client == %@ AND loanType == %@",
            client,
            loanType
        )
        // 按日期升序排列（從舊到新）
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: true)]

        do {
            let allRecords = try viewContext.fetch(fetchRequest)
            var accumulated: Double = 0

            // 依序重新計算每筆資料的累積值
            for record in allRecords {
                let usedAmount = Double(record.usedLoanAmount ?? "0") ?? 0
                accumulated += usedAmount
                record.usedLoanAccumulated = String(format: "%.2f", accumulated)
            }

            try viewContext.save()
            print("已重新計算 \(loanType) 的累積值，共 \(allRecords.count) 筆資料")
        } catch {
            print("重新計算累積值時發生錯誤: \(error)")
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let client = Client(context: context)
    client.name = "測試客戶"

    return AddLoanMonthlyDataView(client: client)
        .environment(\.managedObjectContext, context)
}
