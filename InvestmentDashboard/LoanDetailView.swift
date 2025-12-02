//
//  LoanDetailView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/11/10.
//

import SwiftUI
import CoreData

struct LoanDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var loan: Loan

    @State private var showingAddRateAdjustment = false
    @State private var selectedAdjustment: LoanRateAdjustment?
    @State private var showingDeleteAlert = false
    @State private var adjustmentToDelete: LoanRateAdjustment?

    // 獲取排序後的利率調整記錄
    private var sortedRateAdjustments: [LoanRateAdjustment] {
        guard let adjustments = loan.rateAdjustments as? Set<LoanRateAdjustment> else {
            return []
        }
        return adjustments.sorted { adj1, adj2 in
            // 優先使用 Date 排序
            if let date1 = adj1.adjustmentDateAsDate,
               let date2 = adj2.adjustmentDateAsDate {
                return date1 < date2
            }
            // 如果沒有 Date，則使用 String 排序
            return (adj1.adjustmentDate ?? "") < (adj2.adjustmentDate ?? "")
        }
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

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 貸款基本資訊卡片
                loanBasicInfoCard

                // 利率調整歷史區域
                rateAdjustmentSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(loan.loanName ?? "貸款詳情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddRateAdjustment) {
            // 傳入上一期的資訊作為預設值
            let lastAdjustment = sortedRateAdjustments.last
            let previousPayment = lastAdjustment?.newMonthlyPayment ?? (loan.gracePeriod > 0 ? loan.gracePeriodPayment : loan.normalPayment) ?? ""
            AddLoanRateAdjustmentView(
                loan: loan,
                previousEndDate: lastAdjustment?.adjustmentDate ?? loan.startDate ?? "",
                previousInterestRate: lastAdjustment?.newInterestRate ?? loan.interestRate ?? "",
                previousMonthlyPayment: previousPayment,
                previousRemainingBalance: lastAdjustment?.remainingBalance ?? loan.loanAmount ?? ""
            )
            .environment(\.managedObjectContext, viewContext)
        }
        .alert("刪除利率調整", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                if let adjustment = adjustmentToDelete {
                    deleteRateAdjustment(adjustment)
                }
            }
        } message: {
            Text("確定要刪除這個利率調整記錄嗎？")
        }
    }

    // MARK: - 貸款基本資訊卡片
    private var loanBasicInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                Text("貸款基本資訊")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                LoanInfoRow(title: "貸款類型", value: loan.loanType ?? "-")
                LoanInfoRow(title: "貸款名稱", value: loan.loanName ?? "-")
                LoanInfoRow(title: "貸款金額", value: "$\(formatNumber(loan.loanAmount ?? "0"))")
                LoanInfoRow(title: "已動用累積", value: "$\(formatNumber(loan.usedLoanAmount ?? "0"))", valueColor: .orange)
                LoanInfoRow(title: "初始利率", value: (loan.interestRate ?? "0") + "%")
                LoanInfoRow(title: "貸款期限", value: (loan.loanTerm ?? "0") + " 年")
                LoanInfoRow(title: "開始日期", value: loan.startDate ?? "-")
                LoanInfoRow(title: "結束日期", value: loan.endDate ?? "-")

                Divider()

                let initialPayment = loan.gracePeriod > 0 ? (loan.gracePeriodPayment ?? "0") : (loan.normalPayment ?? "0")
                LoanInfoRow(title: "初始月付金", value: "$\(formatNumber(initialPayment))", valueColor: .orange)
                LoanInfoRow(title: "已還款總額", value: "$\(formatNumber(loan.totalPaid ?? "0"))", valueColor: .green)
                LoanInfoRow(title: "剩餘本金", value: "$\(formatNumber(loan.remainingBalance ?? "0"))", valueColor: .red)

                if let notes = loan.notes, !notes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("備註")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }

    // MARK: - 利率調整歷史區域
    private var rateAdjustmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                Text("利率調整歷史")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(sortedRateAdjustments.count) 筆記錄")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                // 顯示初始記錄
                initialRateRow(loan: loan)

                // 顯示所有利率調整記錄
                ForEach(Array(sortedRateAdjustments.enumerated()), id: \.element) { index, adjustment in
                    rateAdjustmentRow(adjustment: adjustment, index: index)
                }

                // 新增利率調整按鈕
                Button(action: {
                    showingAddRateAdjustment = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("新增利率調整")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 12)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }

    // MARK: - 初始記錄行
    private func initialRateRow(loan: Loan) -> some View {
        let endDate = sortedRateAdjustments.first?.adjustmentDate ?? (loan.endDate ?? "-")

        return HStack(alignment: .top, spacing: 12) {
            // 左側時間軸圖示
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 12, height: 12)

                if !sortedRateAdjustments.isEmpty {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                }
            }
            .frame(width: 12)

            // 右側內容
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(loan.startDate ?? "-")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                // 利率標籤
                Text("利率 \(loan.interestRate ?? "0")")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // 日期範圍箭頭
                HStack(spacing: 8) {
                    Text(loan.startDate ?? "-")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(endDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 詳細資訊
                let initialMonthlyPayment = loan.gracePeriod > 0 ? (loan.gracePeriodPayment ?? "0") : (loan.normalPayment ?? "0")
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("月付金")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(formatNumber(initialMonthlyPayment))")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - 利率調整列表項目（時間軸樣式）
    private func rateAdjustmentRow(adjustment: LoanRateAdjustment, index: Int) -> some View {
        let startDate = index == 0 ? (loan.startDate ?? "-") : (sortedRateAdjustments[index - 1].adjustmentDate ?? "-")
        let endDate = index < sortedRateAdjustments.count - 1 ? (sortedRateAdjustments[index + 1].adjustmentDate ?? "-") : (loan.endDate ?? "-")

        return HStack(alignment: .top, spacing: 12) {
            // 左側時間軸圖示
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 12, height: 12)

                if index < sortedRateAdjustments.count - 1 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                }
            }
            .frame(width: 12)

            // 右側內容
            VStack(alignment: .leading, spacing: 8) {
                // 日期範圍和鈴鐺
                HStack(spacing: 8) {
                    // 調整日期
                    Text(adjustment.adjustmentDate ?? "-")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // 刪除按鈕
                    Button(action: {
                        adjustmentToDelete = adjustment
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // 利率標籤
                Text("利率 \(adjustment.newInterestRate ?? "0")")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // 日期範圍箭頭
                HStack(spacing: 8) {
                    Text(startDate)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(endDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 詳細資訊
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("新利率 \(adjustment.newInterestRate ?? "0")%")
                            .font(.caption)
                        Spacer()
                        Text("$\(formatNumber(adjustment.newMonthlyPayment ?? "0"))")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }

                if let notes = adjustment.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - 刪除利率調整
    private func deleteRateAdjustment(_ adjustment: LoanRateAdjustment) {
        withAnimation {
            viewContext.delete(adjustment)

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("利率調整記錄已成功刪除")
            } catch {
                print("Delete error: \(error)")
            }
        }
    }
}

// MARK: - 資訊行組件
struct LoanInfoRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}
