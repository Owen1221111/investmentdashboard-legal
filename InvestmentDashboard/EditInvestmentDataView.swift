//
//  EditInvestmentDataView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/11/13.
//

import SwiftUI
import CoreData

struct EditInvestmentDataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client

    @State private var totalInvestment = ""
    @State private var taiwanStockCost = ""
    @State private var usStockCost = ""
    @State private var bondsCost = ""
    @State private var regularInvestmentCost = ""
    @State private var latestData: LoanMonthlyData?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 說明文字
                VStack(alignment: .leading, spacing: 8) {
                    Text("編輯投資數據")
                        .font(.headline)
                    Text("修改最新記錄的投資總額和各項成本")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGroupedBackground))

                ScrollView {
                    VStack(spacing: 16) {
                        // 投資總額
                        editField(
                            title: "投資總額",
                            value: $totalInvestment,
                            color: .green
                        )

                        Divider()
                            .padding(.horizontal)

                        // 成本明細標題
                        HStack {
                            Text("成本明細")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)

                        // 台股成本
                        editField(
                            title: "台股成本",
                            value: $taiwanStockCost,
                            color: .blue
                        )

                        // 美股成本
                        editField(
                            title: "美股成本",
                            value: $usStockCost,
                            color: .blue
                        )

                        // 債券成本
                        editField(
                            title: "債券成本",
                            value: $bondsCost,
                            color: .blue
                        )

                        // 定期定額成本
                        editField(
                            title: "定期定額成本",
                            value: $regularInvestmentCost,
                            color: .blue
                        )

                        // 總成本顯示
                        VStack(spacing: 12) {
                            Divider()

                            HStack {
                                Text("總成本")
                                    .font(.headline)
                                Spacer()
                                Text("$\(formatDouble(calculateTotalCost()))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // 報酬率預覽
                        VStack(spacing: 12) {
                            HStack {
                                Text("報酬率預覽")
                                    .font(.headline)
                                Spacer()
                                let returnRate = calculateReturnRate()
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.2f", returnRate))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(returnRate >= 0 ? .green : .red)
                                    Text("%")
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                        .foregroundColor(returnRate >= 0 ? .green : .red)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("編輯投資數據")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadLatestData()
            }
        }
    }

    // MARK: - 編輯欄位組件
    private func editField(title: String, value: Binding<String>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            HStack {
                Text("$")
                    .font(.title3)
                    .foregroundColor(.secondary)

                TextField("請輸入金額", text: Binding(
                    get: { value.wrappedValue },
                    set: { newValue in
                        value.wrappedValue = formatInput(newValue)
                    }
                ))
                .font(.title3)
                .keyboardType(.decimalPad)
                .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }

    // MARK: - 輔助函數

    private func loadLatestData() {
        let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)
            if let data = results.first {
                latestData = data
                totalInvestment = formatNumberForDisplay(data.totalInvestment ?? "0")
                taiwanStockCost = formatNumberForDisplay(data.taiwanStockCost ?? "0")
                usStockCost = formatNumberForDisplay(data.usStockCost ?? "0")
                bondsCost = formatNumberForDisplay(data.bondsCost ?? "0")
                regularInvestmentCost = formatNumberForDisplay(data.regularInvestmentCost ?? "0")
            }
        } catch {
            print("讀取數據錯誤: \(error)")
        }
    }

    private func formatNumberForDisplay(_ value: String) -> String {
        guard let number = Double(value.replacingOccurrences(of: ",", with: "")) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    private func formatInput(_ value: String) -> String {
        let cleaned = value.replacingOccurrences(of: ",", with: "")
        guard let number = Double(cleaned) else { return value }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    private func formatDouble(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func removeCommas(_ value: String) -> String {
        return value.replacingOccurrences(of: ",", with: "")
    }

    private func calculateTotalCost() -> Double {
        let cost1 = Double(removeCommas(taiwanStockCost)) ?? 0
        let cost2 = Double(removeCommas(usStockCost)) ?? 0
        let cost3 = Double(removeCommas(bondsCost)) ?? 0
        let cost4 = Double(removeCommas(regularInvestmentCost)) ?? 0
        return cost1 + cost2 + cost3 + cost4
    }

    private func calculateReturnRate() -> Double {
        let investment = Double(removeCommas(totalInvestment)) ?? 0
        let totalCost = calculateTotalCost()

        if totalCost > 0 {
            return ((investment - totalCost) / totalCost) * 100
        }
        return 0
    }

    // MARK: - 保存更改
    private func saveChanges() {
        guard let data = latestData else {
            dismiss()
            return
        }

        data.totalInvestment = removeCommas(totalInvestment)
        data.taiwanStockCost = removeCommas(taiwanStockCost)
        data.usStockCost = removeCommas(usStockCost)
        data.bondsCost = removeCommas(bondsCost)
        data.regularInvestmentCost = removeCommas(regularInvestmentCost)

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("投資數據已成功更新")
            dismiss()
        } catch {
            print("保存錯誤: \(error)")
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let client = Client(context: context)
    client.name = "測試客戶"

    return EditInvestmentDataView(client: client)
        .environment(\.managedObjectContext, context)
}
