//
//  TWStockLoanSyncSelectionView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/11/17.
//

import SwiftUI
import CoreData

struct TWStockLoanSyncSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client
    let stocks: [TWStock]
    let onSync: ([TWStock], Loan) -> Void

    @State private var selectedStocks: Set<TWStock> = []
    @State private var selectedLoan: Loan?
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // 獲取客戶的貸款列表
    private var loans: [Loan] {
        guard let loansSet = client.loans as? Set<Loan> else { return [] }
        return loansSet.sorted { ($0.createdDate ?? Date()) > ($1.createdDate ?? Date()) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 說明文字
                VStack(alignment: .leading, spacing: 8) {
                    Text("選擇要同步的台股標的")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("選擇與貸款相關的台股標的,將同步到「貸款/投資月度管理」")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGroupedBackground))

                Divider()

                // 標的列表
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(stocks, id: \.self) { stock in
                            stockSelectionRow(stock: stock)

                            if stock != stocks.last {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Divider()

                // 貸款選擇和確認按鈕
                VStack(spacing: 16) {
                    // 貸款選擇
                    VStack(alignment: .leading, spacing: 8) {
                        Text("選擇貸款")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        if loans.isEmpty {
                            Text("尚無貸款記錄,請先新增貸款")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else {
                            Picker("貸款", selection: $selectedLoan) {
                                Text("請選擇貸款").tag(nil as Loan?)
                                ForEach(loans, id: \.self) { loan in
                                    Text(loan.loanName ?? "未命名貸款")
                                        .tag(loan as Loan?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }

                    // 統計資訊
                    if !selectedStocks.isEmpty {
                        VStack(spacing: 8) {
                            HStack {
                                Text("已選擇標的")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(selectedStocks.count) 個")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }

                            HStack {
                                Text("總市值")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatCurrency(getTotalMarketValue()))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }

                            HStack {
                                Text("總成本")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatCurrency(getTotalCost()))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                    }

                    // 確認按鈕
                    Button(action: {
                        handleSync()
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .medium))
                            Text("確認同步")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            selectedStocks.isEmpty || selectedLoan == nil
                                ? Color.gray
                                : Color.orange
                        )
                        .cornerRadius(12)
                    }
                    .disabled(selectedStocks.isEmpty || selectedLoan == nil)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("貸款同步")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(selectedStocks.count == stocks.count ? "全不選" : "全選") {
                        if selectedStocks.count == stocks.count {
                            selectedStocks.removeAll()
                        } else {
                            selectedStocks = Set(stocks)
                        }
                    }
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - 標的選擇行
    private func stockSelectionRow(stock: TWStock) -> some View {
        Button(action: {
            if selectedStocks.contains(stock) {
                selectedStocks.remove(stock)
            } else {
                selectedStocks.insert(stock)
            }
        }) {
            HStack(spacing: 12) {
                // 選擇框
                Image(systemName: selectedStocks.contains(stock) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(selectedStocks.contains(stock) ? .orange : .gray)
                    .frame(width: 30)

                // 股票資訊
                VStack(alignment: .leading, spacing: 4) {
                    // 股票名稱和代號
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            // 股票名稱（上方）
                            Text(stock.stockName?.isEmpty == false ? stock.stockName! : (stock.name ?? "未命名"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("TWD")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }

                        // 股票代號（下方）
                        if let code = stock.name, !code.isEmpty {
                            Text(code)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(spacing: 12) {
                        Text("市值: NT$\(formatNumber(stock.marketValue))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("成本: NT$\(formatNumber(stock.cost))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 報酬率
                if let returnRateStr = stock.returnRate {
                    let returnRate = getReturnRateValue(returnRateStr)
                    Text(String(format: "%.2f%%", returnRate))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(returnRate >= 0 ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((returnRate >= 0 ? Color.green : Color.red).opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(selectedStocks.contains(stock) ? Color.orange.opacity(0.05) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 處理同步
    private func handleSync() {
        guard !selectedStocks.isEmpty else {
            alertMessage = "請至少選擇一個標的"
            showingAlert = true
            return
        }

        guard let loan = selectedLoan else {
            alertMessage = "請選擇要同步的貸款"
            showingAlert = true
            return
        }

        // 調用回調函數執行同步
        onSync(Array(selectedStocks), loan)

        // 關閉視圖
        dismiss()
    }

    // MARK: - 計算函數
    private func getTotalMarketValue() -> Double {
        return selectedStocks.reduce(0.0) { total, stock in
            total + (Double(stock.marketValue ?? "0") ?? 0)
        }
    }

    private func getTotalCost() -> Double {
        return selectedStocks.reduce(0.0) { total, stock in
            total + (Double(stock.cost ?? "0") ?? 0)
        }
    }

    // MARK: - 格式化函數
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return "NT$\(formatter.string(from: NSNumber(value: value)) ?? "0.00")"
    }

    private func formatNumber(_ value: String?) -> String {
        guard let value = value, !value.isEmpty else { return "0" }
        if let number = Double(value) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: number)) ?? value
        }
        return value
    }

    private func getReturnRateValue(_ rateString: String) -> Double {
        let cleanValue = rateString.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
        return Double(cleanValue) ?? 0
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let client = Client(context: context)
    client.name = "測試客戶"

    return TWStockLoanSyncSelectionView(
        client: client,
        stocks: [],
        onSync: { _, _ in }
    )
    .environment(\.managedObjectContext, context)
}
