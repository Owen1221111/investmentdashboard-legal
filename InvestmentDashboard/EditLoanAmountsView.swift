//
//  EditLoanAmountsView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/11/13.
//

import SwiftUI
import CoreData

struct EditLoanAmountsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client

    @State private var editableLoans: [EditableLoan] = []

    struct EditableLoan: Identifiable {
        let id = UUID()
        let loan: Loan
        var amount: String
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 說明文字
                VStack(alignment: .leading, spacing: 8) {
                    Text("編輯貸款金額")
                        .font(.headline)
                    Text("修改各項貸款的原始貸款金額")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGroupedBackground))

                // 貸款列表
                if !editableLoans.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach($editableLoans) { $editableLoan in
                                loanEditRow(editableLoan: $editableLoan)
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("尚無貸款記錄")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("編輯貸款金額")
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
                loadLoans()
            }
        }
    }

    // MARK: - 貸款編輯行
    private func loanEditRow(editableLoan: Binding<EditableLoan>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 貸款信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(editableLoan.wrappedValue.loan.loanName ?? "未命名貸款")
                        .font(.headline)
                    Text(editableLoan.wrappedValue.loan.loanType ?? "未分類")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // 金額輸入
            VStack(alignment: .leading, spacing: 8) {
                Text("貸款金額")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("$")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    TextField("請輸入金額", text: Binding(
                        get: { editableLoan.wrappedValue.amount },
                        set: { newValue in
                            editableLoan.wrappedValue.amount = formatInput(newValue)
                        }
                    ))
                    .font(.title2)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - 輔助函數

    private func loadLoans() {
        guard let loans = client.loans as? Set<Loan> else { return }

        editableLoans = loans.sorted { ($0.createdDate ?? Date()) > ($1.createdDate ?? Date()) }
            .map { loan in
                EditableLoan(
                    loan: loan,
                    amount: formatNumberForDisplay(loan.loanAmount ?? "0")
                )
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
        // 移除所有非數字和小數點的字符
        let cleaned = value.replacingOccurrences(of: ",", with: "")
        guard let number = Double(cleaned) else { return value }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    private func removeCommas(_ value: String) -> String {
        return value.replacingOccurrences(of: ",", with: "")
    }

    // MARK: - 保存更改
    private func saveChanges() {
        for editableLoan in editableLoans {
            let cleanedAmount = removeCommas(editableLoan.amount)
            if !cleanedAmount.isEmpty {
                editableLoan.loan.loanAmount = cleanedAmount
            }
        }

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("貸款金額已成功更新")
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

    return EditLoanAmountsView(client: client)
        .environment(\.managedObjectContext, context)
}
