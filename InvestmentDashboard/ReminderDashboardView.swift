import SwiftUI
import CoreData
import Charts

struct ReminderDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default)
    private var customers: FetchedResults<Client>

    @State private var upcomingDividends: [DividendReminder] = []
    @State private var upcomingInsurancePayments: [InsuranceReminder] = []
    @State private var selectedMonthIndex: Int = 0
    @State private var selectedCurrencyIndex: Int = 0 // 選中的幣別索引

    // 取得所有可用的月份
    private var availableMonths: [(monthKey: String, year: Int, month: Int)] {
        let calendar = Calendar.current
        let today = Date()

        var months: [(monthKey: String, year: Int, month: Int)] = []
        for i in 0...2 {
            if let date = calendar.date(byAdding: .month, value: i, to: today) {
                let year = calendar.component(.year, from: date)
                let month = calendar.component(.month, from: date)
                months.append((monthKey: "\(year)年\(month)月", year: year, month: month))
            }
        }
        return months
    }

    // 當前選中月份的所有配息
    private var currentMonthAllDividends: [DividendReminder] {
        guard selectedMonthIndex < availableMonths.count else { return [] }
        let selectedMonth = availableMonths[selectedMonthIndex]
        return upcomingDividends
            .filter { $0.year == selectedMonth.year && $0.month == selectedMonth.month }
            .sorted { $0.customerName < $1.customerName }
    }

    // 當前月份可用的幣別（USD 優先）
    private var availableCurrencies: [String] {
        let currencies = Array(Set(currentMonthAllDividends.map { $0.currency }))
        // USD 排第一，其他按字母排序
        let sorted = currencies.sorted { c1, c2 in
            if c1 == "USD" { return true }
            if c2 == "USD" { return false }
            return c1 < c2
        }
        print("🔍 可用幣別: \(sorted), 數量: \(sorted.count)")
        return sorted
    }

    // 當前選中幣別
    private var selectedCurrency: String {
        guard selectedCurrencyIndex < availableCurrencies.count else {
            return availableCurrencies.first ?? "USD"
        }
        return availableCurrencies[selectedCurrencyIndex]
    }

    // 當前選中月份和幣別的配息
    private var currentMonthDividends: [DividendReminder] {
        return currentMonthAllDividends.filter { $0.currency == selectedCurrency }
    }

    // 幣別顏色對應
    private func currencyColor(for currency: String) -> Color {
        switch currency {
        case "USD": return .green
        case "TWD": return .blue
        case "EUR": return .purple
        case "JPY": return .orange
        case "GBP": return .pink
        case "CNY": return .red
        case "AUD": return .yellow
        case "CAD": return .mint
        case "CHF": return .indigo
        case "HKD": return .cyan
        case "SGD": return .teal
        default: return .green
        }
    }

    // 當前選中月份的保費
    private var currentMonthInsurance: [InsuranceReminder] {
        guard selectedMonthIndex < availableMonths.count else { return [] }
        let selectedMonth = availableMonths[selectedMonthIndex]
        let calendar = Calendar.current

        return upcomingInsurancePayments.filter { payment in
            let year = calendar.component(.year, from: payment.paymentDate)
            let month = calendar.component(.month, from: payment.paymentDate)
            return year == selectedMonth.year && month == selectedMonth.month
        }.sorted { $0.paymentDate < $1.paymentDate }
    }

    // 按月份分組的配息提醒
    private var groupedDividends: [(month: String, dividends: [DividendReminder])] {
        let grouped = Dictionary(grouping: upcomingDividends) { dividend in
            "\(dividend.year)年\(dividend.month)月"
        }
        return grouped.sorted { (group1, group2) in
            let d1 = group1.value.first
            let d2 = group2.value.first
            if let d1 = d1, let d2 = d2 {
                if d1.year != d2.year {
                    return d1.year < d2.year
                }
                return d1.month < d2.month
            }
            return false
        }.map { ($0.key, $0.value.sorted { $0.customerName < $1.customerName }) }
    }

    // 按月份分組的保費提醒
    private var groupedInsurance: [(month: String, payments: [InsuranceReminder])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: upcomingInsurancePayments) { payment in
            let year = calendar.component(.year, from: payment.paymentDate)
            let month = calendar.component(.month, from: payment.paymentDate)
            return "\(year)年\(month)月"
        }
        return grouped.sorted { (group1, group2) in
            let p1 = group1.value.first
            let p2 = group2.value.first
            if let p1 = p1, let p2 = p2 {
                return p1.paymentDate < p2.paymentDate
            }
            return false
        }.map { ($0.key, $0.value.sorted { $0.paymentDate < $1.paymentDate }) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header section
                VStack(alignment: .leading, spacing: 16) {
                    Text("投資提醒")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)

                    // Month tabs - Segmented style
                    HStack(spacing: 0) {
                        ForEach(0..<availableMonths.count, id: \.self) { index in
                            MonthTab(
                                title: availableMonths[index].monthKey,
                                isSelected: selectedMonthIndex == index
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedMonthIndex = index
                                    selectedCurrencyIndex = 0 // 重置幣別為預設（USD）
                                }
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .background(Color(.systemGroupedBackground))

                // Content area - Connected page style
                ScrollView {
                    VStack(spacing: 20) {
                        // Dividend reminders for current month
                        if !currentMonthAllDividends.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // Dividend header tag
                                HStack {
                                    CompactSummaryTag(
                                        title: "公司債配息",
                                        count: currentMonthDividends.count,
                                        icon: "dollarsign.circle.fill",
                                        color: currencyColor(for: selectedCurrency)
                                    )

                                    Spacer()

                                    // 幣別指示器（多幣別時顯示）
                                    if availableCurrencies.count > 1 {
                                        HStack(spacing: 4) {
                                            ForEach(Array(availableCurrencies.enumerated()), id: \.offset) { index, currency in
                                                Button {
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        selectedCurrencyIndex = index
                                                    }
                                                } label: {
                                                    Text(currency)
                                                        .font(.system(size: 12, weight: selectedCurrencyIndex == index ? .semibold : .regular))
                                                        .foregroundColor(selectedCurrencyIndex == index ? .white : .secondary)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(
                                                            selectedCurrencyIndex == index
                                                                ? currencyColor(for: currency)
                                                                : Color(.systemGray5)
                                                        )
                                                        .cornerRadius(6)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)

                                // 配息卡片區域（支援左右滑動切換幣別）
                                if availableCurrencies.count > 1 {
                                    TabView(selection: $selectedCurrencyIndex) {
                                        ForEach(0..<availableCurrencies.count, id: \.self) { index in
                                            let currency = availableCurrencies[index]
                                            let filteredDividends = currentMonthAllDividends.filter { $0.currency == currency }

                                            ScrollView {
                                                VStack(spacing: 8) {
                                                    ForEach(filteredDividends) { dividend in
                                                        DividendReminderCard(reminder: dividend)
                                                    }
                                                }
                                                .padding(.horizontal)
                                            }
                                            .tag(index)
                                        }
                                    }
                                    .tabViewStyle(.page(indexDisplayMode: .never))
                                    .frame(height: CGFloat(min(currentMonthDividends.count, 5) * 85 + 20))

                                    // 滑動提示
                                    HStack {
                                        Spacer()
                                        Text("← 左右滑動切換幣別 →")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.top, 4)
                                } else {
                                    ForEach(currentMonthDividends) { dividend in
                                        DividendReminderCard(reminder: dividend)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.top, 20)
                        }

                        // Insurance payment reminders for current month
                        if !currentMonthInsurance.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // Insurance header tag
                                CompactSummaryTag(
                                    title: "保費",
                                    count: currentMonthInsurance.count,
                                    icon: "shield.fill",
                                    color: .blue
                                )
                                .padding(.horizontal)

                                ForEach(currentMonthInsurance) { payment in
                                    InsuranceReminderCard(reminder: payment)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        // Empty state for current month
                        if currentMonthDividends.isEmpty && currentMonthInsurance.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)

                                Text("本月沒有即將到來的事項")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                Text("這個月沒有配息或保費提醒")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                            .padding(.bottom)
                        }
                    }
                    .padding(.bottom)
                }
                .background(Color(.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                calculateUpcomingReminders()
            }
        }
    }

    private func calculateUpcomingReminders() {
        let calendar = Calendar.current
        let today = Date()

        let currentMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: today)

        // 計算目標月份：當月 + 未來兩個月（總共3個月）
        // 例如：10/29 → 10月、11月、12月
        var targetMonths: [(month: Int, year: Int)] = []
        for i in 0...2 {
            if let date = calendar.date(byAdding: .month, value: i, to: today) {
                let month = calendar.component(.month, from: date)
                let year = calendar.component(.year, from: date)
                targetMonths.append((month: month, year: year))
            }
        }

        var dividends: [DividendReminder] = []
        var insurancePayments: [InsuranceReminder] = []

        // Process each customer
        for customer in customers {
            // Check corporate bonds for dividends
            if let bonds = customer.corporateBonds?.allObjects as? [CorporateBond] {
                for bond in bonds {
                    if let dividendMonthsStr = bond.dividendMonths, !dividendMonthsStr.isEmpty {
                        let months = parseDividendMonths(dividendMonthsStr)

                        for (month, year) in targetMonths {
                            if months.contains(month) {
                                let amount = Double(removeCommas(bond.singleDividend ?? "")) ?? 0
                                let currency = bond.currency ?? "USD"

                                print("📊 配息提醒: \(bond.bondName ?? ""), 幣別: \(currency), 金額: \(amount)")

                                dividends.append(DividendReminder(
                                    id: UUID(),
                                    customerName: customer.name ?? "未知客戶",
                                    bondName: bond.bondName ?? "未知債券",
                                    month: month,
                                    year: year,
                                    amount: amount,
                                    currency: currency
                                ))
                            }
                        }
                    }
                }
            }

            // Check insurance policies for payment dates
            if let policies = customer.insurancePolicies?.allObjects as? [InsurancePolicy] {
                for policy in policies {
                    if let paymentMonthStr = policy.paymentMonth, !paymentMonthStr.isEmpty {
                        // Parse payment months (e.g., "1月、7月" or "01")
                        let months = parsePaymentMonths(paymentMonthStr)

                        for (month, year) in targetMonths {
                            if months.contains(month) {
                                // Create a date for this payment month
                                var components = DateComponents()
                                components.year = year
                                components.month = month
                                components.day = 1

                                if let paymentDate = calendar.date(from: components) {
                                    let amount = Double(removeCommas(policy.annualPremium ?? "")) ?? 0
                                    let currency = policy.currency ?? "TWD"

                                    insurancePayments.append(InsuranceReminder(
                                        id: UUID(),
                                        customerName: customer.name ?? "未知客戶",
                                        policyName: policy.policyName ?? policy.insuranceCompany ?? "未知保單",
                                        paymentDate: paymentDate,
                                        amount: amount,
                                        currency: currency
                                    ))
                                }
                            }
                        }
                    }
                }
            }
        }

        // Sort dividends by month
        dividends.sort { (d1, d2) -> Bool in
            if d1.year != d2.year {
                return d1.year < d2.year
            }
            return d1.month < d2.month
        }

        // Sort insurance payments by date
        insurancePayments.sort { $0.paymentDate < $1.paymentDate }

        self.upcomingDividends = dividends
        self.upcomingInsurancePayments = insurancePayments
    }

    private func parseDividendMonths(_ monthsStr: String) -> [Int] {
        var months: [Int] = []

        // Try splitting by comma, 頓號, or slash
        if monthsStr.contains(",") || monthsStr.contains("、") || monthsStr.contains("/") {
            // Normalize all separators to comma
            let normalized = monthsStr
                .replacingOccurrences(of: "、", with: ",")
                .replacingOccurrences(of: "/", with: ",")

            months = normalized.split(separator: ",")
                .compactMap { part -> Int? in
                    let cleaned = part.trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "月", with: "")
                    return Int(cleaned)
                }
                .filter { $0 >= 1 && $0 <= 12 }
        } else {
            // Try parsing as single month number (e.g., "01" or "1")
            let cleaned = monthsStr.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "月", with: "")
            if let month = Int(cleaned), month >= 1 && month <= 12 {
                months = [month]
            }
        }

        return months
    }

    private func parsePaymentMonths(_ monthsStr: String) -> [Int] {
        // Reuse the same logic as dividend months parsing
        return parseDividendMonths(monthsStr)
    }

    private func parsePaymentDate(_ dateStr: String, currentYear: Int) -> Date? {
        let calendar = Calendar.current

        // Try format: "MM/DD" or "M/D"
        if dateStr.contains("/") {
            let parts = dateStr.split(separator: "/")
            if parts.count == 2,
               let month = Int(parts[0]),
               let day = Int(parts[1]) {
                var components = DateComponents()
                components.year = currentYear
                components.month = month
                components.day = day
                return calendar.date(from: components)
            }
        }

        // Try format: "YYYY-MM-DD"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateStr) {
            return date
        }

        return nil
    }

    private func removeCommas(_ string: String) -> String {
        return string.replacingOccurrences(of: ",", with: "")
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        if let formatted = formatter.string(from: NSNumber(value: amount)) {
            return "$\(formatted)"
        }
        return "$\(Int(amount))"
    }
}

// MARK: - Supporting Views

struct MonthTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : Color(.systemGray2))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 10,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 10
                        )
                        .fill(isSelected ? Color(.systemBackground) : Color(.systemGray5))
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 10,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 10
                        )
                        .stroke(
                            isSelected ? Color.clear : Color(.systemGray4).opacity(0.5),
                            lineWidth: 1
                        )
                    )

                // Extension to connect with content below
                if isSelected {
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .frame(height: 8)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SummaryCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 24))
                Spacer()
            }

            Text("\(count)")
                .font(.system(size: 32, weight: .bold))

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CompactSummaryTag: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))

            Text("\(count)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DividendReminderCard: View {
    let reminder: DividendReminder

    // 根據幣別返回對應顏色
    private var currencyColor: Color {
        switch reminder.currency {
        case "USD": return .green
        case "TWD": return .blue
        case "EUR": return .purple
        case "JPY": return .orange
        case "GBP": return .pink
        case "CNY": return .red
        case "AUD": return .yellow
        case "CAD": return .mint
        case "CHF": return .indigo
        case "HKD": return .cyan
        case "SGD": return .teal
        default: return .green
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar - 根據幣別顯示不同顏色
            Rectangle()
                .fill(currencyColor)
                .frame(width: 4)

            HStack(spacing: 12) {
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.customerName)
                        .font(.system(size: 16, weight: .semibold))

                    HStack(spacing: 4) {
                        Text(reminder.bondName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Amount with currency
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(reminder.amount))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(currencyColor)

                    Text(reminder.currency)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
        )
    }

    private func formatDate(year: Int, month: Int) -> String {
        return "\(year)年 \(month)月"
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        if let formatted = formatter.string(from: NSNumber(value: amount)) {
            return "$\(formatted)"
        }
        return "$\(amount)"
    }
}

struct InsuranceReminderCard: View {
    let reminder: InsuranceReminder

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            Rectangle()
                .fill(Color.blue)
                .frame(width: 4)

            HStack(spacing: 12) {
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.customerName)
                        .font(.system(size: 16, weight: .semibold))

                    HStack(spacing: 6) {
                        Text(reminder.policyName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Text("•")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Text(formatDate(reminder.paymentDate))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Amount
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(reminder.amount))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)

                    Text(reminder.currency)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d日"
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        if let formatted = formatter.string(from: NSNumber(value: amount)) {
            return "$\(formatted)"
        }
        return "$\(amount)"
    }
}

// MARK: - Data Models

struct DividendReminder: Identifiable {
    let id: UUID
    let customerName: String
    let bondName: String
    let month: Int
    let year: Int
    let amount: Double
    let currency: String // 幣別
}

// 幣別配息匯總（用於圖表）
struct CurrencyDividendSummary: Identifiable {
    let id = UUID()
    let currency: String
    let amount: Double
    let color: Color
}

struct InsuranceReminder: Identifiable {
    let id: UUID
    let customerName: String
    let policyName: String
    let paymentDate: Date
    let amount: Double
    let currency: String
}

struct ReminderDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderDashboardView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
