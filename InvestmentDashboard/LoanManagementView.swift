//
//  LoanManagementView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/11/07.
//

import SwiftUI
import CoreData

struct LoanManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    let client: Client?
    let onBack: () -> Void

    @State private var showingAddLoan = false
    @State private var selectedLoan: Loan?
    @State private var showingEditLoan = false
    @State private var showingLoanDetail = false
    @State private var loanForDetail: Loan?
    @State private var isLoanListExpanded: Bool = true
    @State private var showingUsedAmountInput = false
    @State private var loanForUsedAmount: Loan?
    @State private var usedAmountInput = ""
    @State private var showingEditLoanAmounts = false
    @State private var showingEditInvestmentData = false
    @State private var showingLoanDisplayModeOptions = false
    @State private var loanDisplayMode: LoanDisplayMode

    // 貸款顯示模式
    enum LoanDisplayMode: String, CaseIterable {
        case totalLoan = "貸款總額"
        case usedAccumulated = "已動用累積"
        case remainingLoan = "貸款餘額"

        var userDefaultsKey: String {
            return "LoanManagementView.loanDisplayMode"
        }
    }

    init(client: Client?, onBack: @escaping () -> Void) {
        self.client = client
        self.onBack = onBack

        // 從 UserDefaults 讀取保存的顯示模式
        let savedMode = UserDefaults.standard.string(forKey: LoanDisplayMode.totalLoan.userDefaultsKey) ?? LoanDisplayMode.totalLoan.rawValue
        _loanDisplayMode = State(initialValue: LoanDisplayMode(rawValue: savedMode) ?? .totalLoan)
    }

    // 計算貸款總額（原始貸款金額）
    private var totalLoanAmount: Double {
        guard let client = client,
              let loans = client.loans as? Set<Loan> else { return 0 }

        return loans.reduce(0.0) { total, loan in
            if let loanAmount = loan.loanAmount,
               let amount = Double(loanAmount) {
                return total + amount
            }
            return total
        }
    }

    // 計算每月還款總額
    private var totalMonthlyPayment: Double {
        guard let client = client,
              let loans = client.loans as? Set<Loan> else { return 0 }

        return loans.reduce(0.0) { total, loan in
            return total + getCurrentMonthlyPayment(loan: loan)
        }
    }

    // 計算已動用累積總額（從月度資料中取得最新的已動用累積）
    private var totalUsedAccumulated: Double {
        guard let client = client else { return 0 }

        let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)
            if let latestData = results.first,
               let usedAccumulated = latestData.usedLoanAccumulated,
               let value = Double(usedAccumulated) {
                return value
            }
        } catch {
            print("獲取已動用累積錯誤: \(error)")
        }

        return 0
    }

    // 計算貸款餘額（貸款總額 - 已動用累積）
    private var remainingLoanAmount: Double {
        return totalLoanAmount - totalUsedAccumulated
    }

    // 根據顯示模式取得對應的金額
    private var displayedLoanAmount: Double {
        switch loanDisplayMode {
        case .totalLoan:
            return totalLoanAmount
        case .usedAccumulated:
            return totalUsedAccumulated
        case .remainingLoan:
            return remainingLoanAmount
        }
    }

    // 獲取最新的投資總額
    private var latestInvestmentTotal: Double {
        guard let client = client else { return 0 }

        let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)
            if let latestData = results.first,
               let totalInvestment = latestData.totalInvestment,
               let value = Double(totalInvestment) {
                return value
            }
        } catch {
            print("獲取投資總額錯誤: \(error)")
        }

        return 0
    }

    // 計算投資報酬率
    private var investmentReturnRate: Double {
        guard let client = client else { return 0 }

        let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)
            if let latestData = results.first {
                // 計算投資成本總額 = 台股成本 + (美股成本 + 債券成本) × 匯率
                let taiwanStockCost = Double(latestData.taiwanStockCost ?? "0") ?? 0
                let usStockCost = Double(latestData.usStockCost ?? "0") ?? 0
                let bondsCost = Double(latestData.bondsCost ?? "0") ?? 0
                let exchangeRate = Double(latestData.exchangeRate ?? "32") ?? 32

                let totalCost = taiwanStockCost + (usStockCost + bondsCost) * exchangeRate

                // 計算投資總額
                let totalInvestment = Double(latestData.totalInvestment ?? "0") ?? 0

                // 計算報酬率 = (投資總額 - 投資成本) / 投資成本 × 100%
                if totalCost > 0 {
                    return ((totalInvestment - totalCost) / totalCost) * 100
                }
            }
        } catch {
            print("計算報酬率錯誤: \(error)")
        }

        return 0
    }

    // 格式化數字為千分位
    private func formatNumber(_ value: String) -> String {
        guard let number = Double(value) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    // 格式化 Double 為千分位
    private func formatDouble(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    // 判斷貸款是否在寬限期內
    private func isInGracePeriod(loan: Loan) -> Bool {
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
            return Date() < gracePeriodEndDate
        }

        return false
    }

    // 獲取貸款的當前月付金
    private func getCurrentMonthlyPayment(loan: Loan) -> Double {
        let inGracePeriod = isInGracePeriod(loan: loan)

        if inGracePeriod {
            // 在寬限期內，使用寬限還款金額
            if let payment = loan.gracePeriodPayment, let value = Double(payment) {
                return value
            }
        } else {
            // 不在寬限期內，使用非寬限還款金額
            if let payment = loan.normalPayment, let value = Double(payment) {
                return value
            }
        }

        return 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // 自定義頂部導航欄
            customNavigationBar

            // 主要內容
            if let client = client {
                ScrollView {
                    VStack(spacing: 16) {
                        // 貸款總覽卡片
                        loanSummaryCard

                        // 投資總覽卡片
                        investmentSummaryCard

                        // 貸款/投資總覽線圖
                        LoanInvestmentOverviewChart(client: client)
                            .environment(\.managedObjectContext, viewContext)

                        // 貸款列表
                        loanListSection

                        // 貸款/投資月度管理表格
                        LoanMonthlyDataTableView(client: client)
                            .environment(\.managedObjectContext, viewContext)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("請先選擇客戶")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
        .sheet(item: $loanForDetail) { loan in
            NavigationView {
                LoanDetailView(loan: loan)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .alert("輸入已動用金額", isPresented: $showingUsedAmountInput) {
            TextField("金額", text: $usedAmountInput)
                .keyboardType(.decimalPad)
            Button("取消", role: .cancel) {
                usedAmountInput = ""
            }
            Button("確認") {
                if let loan = loanForUsedAmount {
                    saveUsedAmount(for: loan)
                }
            }
        } message: {
            Text("請輸入本次已動用的貸款金額")
        }
        .sheet(isPresented: $showingEditLoanAmounts) {
            if let client = client {
                EditLoanAmountsView(client: client)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .sheet(isPresented: $showingEditInvestmentData) {
            if let client = client {
                EditInvestmentDataView(client: client)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .sheet(isPresented: $showingLoanDisplayModeOptions) {
            LoanDisplayModeSelectionView(
                selectedMode: $loanDisplayMode,
                onDismiss: {
                    showingLoanDisplayModeOptions = false
                    // 保存用戶選擇
                    UserDefaults.standard.set(loanDisplayMode.rawValue, forKey: LoanDisplayMode.totalLoan.userDefaultsKey)
                }
            )
        }
    }

    // MARK: - 自定義頂部導航欄
    private var customNavigationBar: some View {
        HStack {
            // 返回按鈕
            Button(action: {
                onBack()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 17, weight: .regular))
                }
                .foregroundColor(.blue)
            }
            .frame(width: 70, height: 44, alignment: .leading)

            Spacer()

            // 標題
            VStack(spacing: 2) {
                Text("貸款管理")
                    .font(.headline)
                    .fontWeight(.semibold)

                if let client = client {
                    Text(client.name ?? "未知客戶")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 佔位符以保持對稱
            Color.clear
                .frame(width: 70, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 貸款總覽卡片
    private var loanSummaryCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 表頭
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 14))
                    Text("貸款總覽")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                Spacer()

                // 顯示模式選擇按鈕
                Button(action: {
                    showingLoanDisplayModeOptions = true
                }) {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }

                // 編輯圖示
                Button(action: {
                    showingEditLoanAmounts = true
                }) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                VStack {
                    Spacer()
                    Divider()
                }
            )

            // 內容
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(loanDisplayMode.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(formatDouble(displayedLoanAmount))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("每月還款")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(formatDouble(totalMonthlyPayment))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.systemOrange))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }

    // MARK: - 投資總覽卡片
    private var investmentSummaryCard: some View {
        Button(action: {
            showingEditInvestmentData = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // 表頭
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 14))
                        Text("投資總覽")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                    Spacer()

                    // 編輯圖示
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    VStack {
                        Spacer()
                        Divider()
                    }
                )

                // 內容
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("投資總額")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(formatDouble(latestInvestmentTotal))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("報酬率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.2f", investmentReturnRate))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(investmentReturnRate >= 0 ? Color(.systemGreen) : Color(.systemRed))
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                            Text("%")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(investmentReturnRate >= 0 ? Color(.systemGreen) : Color(.systemRed))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 貸款列表區域
    private var loanListSection: some View {
        VStack(spacing: 0) {
            // 工具列（跟月度管理一樣的風格）
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14))
                    Text("貸款列表")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                Spacer()

                HStack(spacing: 8) {
                    // 收合/展開按鈕
                    Button(action: {
                        withAnimation {
                            isLoanListExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isLoanListExpanded ? "chevron.down" : "chevron.up")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }

                    // 新增貸款按鈕
                    Button(action: {
                        showingAddLoan = true
                    }) {
                        Text("新增貸款")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .sheet(isPresented: $showingAddLoan) {
                        if let client = client {
                            AddLoanView(client: client)
                                .environment(\.managedObjectContext, viewContext)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                VStack {
                    Spacer()
                    Divider()
                }
            )

            // 貸款列表內容（可收合）
            if isLoanListExpanded {
                if let client = client,
                   let loans = client.loans as? Set<Loan>,
                   !loans.isEmpty {
                    let sortedLoans = loans.sorted { ($0.createdDate ?? Date()) > ($1.createdDate ?? Date()) }

                    VStack(spacing: 12) {
                        ForEach(Array(sortedLoans.enumerated()), id: \.element) { index, loan in
                            loanRow(loan: loan, index: index)
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("尚無貸款記錄")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("點擊「新增貸款」按鈕來添加貸款記錄")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
        }
        .background(
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                    : UIColor.systemGroupedBackground
            })
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - 貸款列表項目
    private func loanRow(loan: Loan, index: Int) -> some View {
        Button(action: {
            loanForDetail = loan
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // 貸款類型標籤
                    Text(loan.loanType ?? "未分類")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(4)

                    Text(loan.loanName ?? "未命名貸款")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    // 利率調整記錄數量提示
                    if let adjustments = loan.rateAdjustments as? Set<LoanRateAdjustment>,
                       !adjustments.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 12))
                            Text("\(adjustments.count) 次調整")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    }

                    Menu {
                        Button(action: {
                            loanForUsedAmount = loan
                            usedAmountInput = ""
                            showingUsedAmountInput = true
                        }) {
                            Label("已動用", systemImage: "dollarsign.circle")
                        }

                        Button(action: {
                            selectedLoan = loan
                            showingEditLoan = true
                        }) {
                            Label("編輯", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: {
                            deleteLoan(loan: loan)
                        }) {
                            Label("刪除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }

                // 貸款詳細資訊（單行顯示）
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("貸款金額")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatNumber(loan.loanAmount ?? "0"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("已動用累積")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatNumber(loan.usedLoanAmount ?? "0"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("利率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text((loan.interestRate ?? "0") + "%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("貸款期限")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text((loan.loanTerm ?? "0") + "年")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }

                // 利率調整時間軸（永遠顯示，包含初始期數）
                Divider()

                let adjustments = loan.rateAdjustments as? Set<LoanRateAdjustment> ?? []
                let sortedAdjustments = adjustments.sorted { adj1, adj2 in
                    if let date1 = adj1.adjustmentDateAsDate,
                       let date2 = adj2.adjustmentDateAsDate {
                        return date1 < date2
                    }
                    return (adj1.adjustmentDate ?? "") < (adj2.adjustmentDate ?? "")
                }

                VStack(alignment: .leading, spacing: 8) {
                    // 顯示初始第 1 期
                    initialLoanPeriodRow(loan: loan, hasAdjustments: !sortedAdjustments.isEmpty)

                    // 顯示所有利率調整期數
                    ForEach(Array(sortedAdjustments.enumerated()), id: \.element) { index, adjustment in
                        loanRateAdjustmentTimelineRow(
                            adjustment: adjustment,
                            index: index + 1, // 從第 2 期開始
                            loan: loan,
                            sortedAdjustments: sortedAdjustments
                        )
                    }
                }

                // 點擊提示
                HStack {
                    Spacer()
                    Text("點擊查看詳情")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(item: $selectedLoan) { loan in
            AddLoanView(client: client!, loanToEdit: loan)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: - 初始貸款期數行
    private func initialLoanPeriodRow(loan: Loan, hasAdjustments: Bool) -> some View {
        let endDate = hasAdjustments ? (loan.rateAdjustments?.allObjects.first as? LoanRateAdjustment)?.adjustmentDate ?? (loan.endDate ?? "-") : (loan.endDate ?? "-")

        return HStack(alignment: .top, spacing: 8) {
            // 左側時間軸圖示
            VStack(spacing: 2) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 10, height: 10)

                if hasAdjustments {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
            }

            // 右側內容
            VStack(alignment: .leading, spacing: 4) {
                // 利率標籤
                Text("利率 \(loan.interestRate ?? "0")")
                    .font(.caption)
                    .fontWeight(.semibold)

                // 日期範圍箭頭
                HStack(spacing: 6) {
                    Text(loan.startDate ?? "-")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if hasAdjustments, let adjustments = loan.rateAdjustments as? Set<LoanRateAdjustment>, !adjustments.isEmpty {
                        let sorted = adjustments.sorted { adj1, adj2 in
                            if let date1 = adj1.adjustmentDateAsDate,
                               let date2 = adj2.adjustmentDateAsDate {
                                return date1 < date2
                            }
                            return (adj1.adjustmentDate ?? "") < (adj2.adjustmentDate ?? "")
                        }
                        Text(sorted.first?.adjustmentDate ?? "-")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(loan.endDate ?? "-")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // 月付金（初始期數：如果有寬限期則顯示寬限還款金額，否則顯示非寬限還款金額）
                    let initialPayment = loan.gracePeriod > 0 ? (loan.gracePeriodPayment ?? "0") : (loan.normalPayment ?? "0")
                    Text("$\(formatNumber(initialPayment))")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
        }
    }

    // MARK: - 利率調整時間軸行（列表中）
    private func loanRateAdjustmentTimelineRow(
        adjustment: LoanRateAdjustment,
        index: Int,
        loan: Loan,
        sortedAdjustments: [LoanRateAdjustment]
    ) -> some View {
        // index 從 1 開始（第 2 期），所以實際在 sortedAdjustments 中的索引是 index - 1
        let actualIndex = index - 1
        let startDate = adjustment.adjustmentDate ?? "-"
        let endDate = actualIndex < sortedAdjustments.count - 1 ? (sortedAdjustments[actualIndex + 1].adjustmentDate ?? "-") : (loan.endDate ?? "-")

        return HStack(alignment: .top, spacing: 8) {
            // 左側時間軸圖示
            VStack(spacing: 2) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 10, height: 10)

                if actualIndex < sortedAdjustments.count - 1 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
            }

            // 右側內容
            VStack(alignment: .leading, spacing: 4) {
                // 利率標籤
                Text("利率 \(adjustment.newInterestRate ?? "0")")
                    .font(.caption)
                    .fontWeight(.semibold)

                // 日期範圍箭頭
                HStack(spacing: 6) {
                    Text(startDate)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(endDate)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // 新月付金
                    Text("$\(formatNumber(adjustment.newMonthlyPayment ?? "0"))")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
        }
    }

    // MARK: - 刪除貸款
    private func deleteLoan(loan: Loan) {
        withAnimation {
            viewContext.delete(loan)

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("貸款已成功刪除")
            } catch {
                print("Delete error: \(error)")
            }
        }
    }

    // MARK: - 保存已動用金額
    private func saveUsedAmount(for loan: Loan) {
        guard !usedAmountInput.isEmpty,
              let inputAmount = Double(usedAmountInput.replacingOccurrences(of: ",", with: "")) else {
            return
        }

        withAnimation {
            // 1. 查詢該貸款最新一筆月度記錄的已動用累積
            var currentUsed: Double = 0
            let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "client == %@ AND loanType == %@",
                client!,
                loan.loanType ?? ""
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
            fetchRequest.fetchLimit = 1

            do {
                let results = try viewContext.fetch(fetchRequest)
                if let latestRecord = results.first {
                    currentUsed = Double(latestRecord.usedLoanAccumulated ?? "0") ?? 0
                }
            } catch {
                print("查詢最新記錄錯誤: \(error)")
            }

            // 2. 計算新的累積總額
            let newTotal = currentUsed + inputAmount

            // 3. 更新 Loan 的已動用累積
            loan.usedLoanAmount = String(format: "%.2f", newTotal)

            // 4. 在 LoanMonthlyData 中新增一筆記錄
            let monthlyData = LoanMonthlyData(context: viewContext)

            // 設定今天的日期
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            monthlyData.date = dateFormatter.string(from: Date())

            monthlyData.loanType = loan.loanType ?? ""
            monthlyData.loanAmount = loan.loanAmount ?? ""
            monthlyData.usedLoanAmount = String(format: "%.2f", inputAmount)
            monthlyData.usedLoanAccumulated = String(format: "%.2f", newTotal)
            monthlyData.taiwanStock = ""
            monthlyData.usStock = ""
            monthlyData.bonds = ""
            monthlyData.regularInvestment = ""
            monthlyData.taiwanStockCost = ""
            monthlyData.usStockCost = ""
            monthlyData.bondsCost = ""
            monthlyData.regularInvestmentCost = ""
            monthlyData.exchangeRate = "32"
            monthlyData.usStockBondsInTwd = ""
            monthlyData.totalInvestment = ""
            monthlyData.createdDate = Date()
            monthlyData.client = client

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("已動用金額已成功儲存")
                usedAmountInput = ""
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}

// MARK: - 貸款顯示模式選擇視圖
struct LoanDisplayModeSelectionView: View {
    @Binding var selectedMode: LoanManagementView.LoanDisplayMode
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(LoanManagementView.LoanDisplayMode.allCases, id: \.self) { mode in
                    Button(action: {
                        selectedMode = mode
                        onDismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.rawValue)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary)

                                Text(getModeDescription(for: mode))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("選擇顯示模式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onDismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(300)])
    }

    private func getModeDescription(for mode: LoanManagementView.LoanDisplayMode) -> String {
        switch mode {
        case .totalLoan:
            return "顯示所有貸款的原始金額總和"
        case .usedAccumulated:
            return "顯示已動用的貸款累積總額"
        case .remainingLoan:
            return "顯示貸款總額減去已動用累積"
        }
    }
}

#Preview {
    LoanManagementView(client: nil, onBack: {})
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(SubscriptionManager.shared)
}
