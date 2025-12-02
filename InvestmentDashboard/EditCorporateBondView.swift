//
//  EditCorporateBondView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/11/25.
//

import SwiftUI
import CoreData

struct EditCorporateBondView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var bond: CorporateBond
    let client: Client?

    @State private var bondName: String = ""
    @State private var currency: String = "USD"
    @State private var couponRate: String = ""
    @State private var yieldRate: String = ""
    @State private var subscriptionPrice: String = ""
    @State private var holdingFaceValue: String = ""
    @State private var previousHandInterest: String = ""
    @State private var currentValue: String = ""
    @State private var receivedInterest: String = ""
    @State private var dividendMonths: String = ""
    @State private var returnRate: String = ""

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showingCurrencyPicker = false

    // 幣別選項
    private let currencies = ["USD", "TWD", "EUR", "JPY", "GBP", "CNY", "AUD", "CAD", "CHF", "HKD", "SGD"]

    init(bond: CorporateBond, client: Client?) {
        self.bond = bond
        self.client = client

        // 初始化狀態變數
        _bondName = State(initialValue: bond.bondName ?? "")
        _currency = State(initialValue: bond.currency ?? "USD")
        _couponRate = State(initialValue: bond.couponRate ?? "")
        _yieldRate = State(initialValue: bond.yieldRate ?? "")
        _subscriptionPrice = State(initialValue: bond.subscriptionPrice ?? "")
        _holdingFaceValue = State(initialValue: bond.holdingFaceValue ?? "")
        _previousHandInterest = State(initialValue: bond.previousHandInterest ?? "")
        _currentValue = State(initialValue: bond.currentValue ?? "")
        _receivedInterest = State(initialValue: bond.receivedInterest ?? "")
        _dividendMonths = State(initialValue: bond.dividendMonths ?? "")
        _returnRate = State(initialValue: bond.returnRate ?? "")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 表單區域
                    VStack(spacing: 16) {
                        // 債券名稱
                        FormField(
                            label: "債券名稱",
                            icon: "doc.text",
                            text: $bondName,
                            placeholder: "請輸入債券名稱",
                            isRequired: true
                        )

                        // 幣別
                        PickerField(
                            label: "幣別",
                            icon: "dollarsign.circle",
                            value: $currency,
                            placeholder: "請選擇幣別",
                            isRequired: true,
                            onTap: { showingCurrencyPicker = true }
                        )

                        // 票面利率
                        FormField(
                            label: "票面利率",
                            icon: "percent",
                            text: $couponRate,
                            placeholder: "例如: 3.5%",
                            isRequired: false
                        )

                        // 殖利率
                        FormField(
                            label: "殖利率",
                            icon: "chart.line.uptrend.xyaxis",
                            text: $yieldRate,
                            placeholder: "例如: 3.8%",
                            isRequired: false
                        )

                        // 申購價格
                        FormField(
                            label: "申購價格",
                            icon: "dollarsign.square",
                            text: $subscriptionPrice,
                            placeholder: "例如: 98.5",
                            keyboardType: .decimalPad,
                            isRequired: false
                        )

                        // 持有面額
                        FormField(
                            label: "持有面額",
                            icon: "banknote",
                            text: $holdingFaceValue,
                            placeholder: "例如: 100000",
                            keyboardType: .decimalPad,
                            isRequired: false
                        )

                        // 前手息
                        FormField(
                            label: "前手息",
                            icon: "dollarsign.circle",
                            text: $previousHandInterest,
                            placeholder: "例如: 500",
                            keyboardType: .decimalPad,
                            isRequired: false
                        )

                        // 配息月份
                        FormField(
                            label: "配息月份",
                            icon: "calendar",
                            text: $dividendMonths,
                            placeholder: "例如: 1月、7月",
                            isRequired: false
                        )

                        // ⭐️ 分隔線：當前狀態
                        VStack(spacing: 8) {
                            Divider()
                                .padding(.vertical, 8)

                            HStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0))
                                Text("當前狀態")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("選填")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }

                            Text("新增舊有債券時可直接填寫當前現值和已領利息，若不填寫現值則預設等於申購金額")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 8)

                        // 現值
                        FormField(
                            label: "現值",
                            icon: "dollarsign.circle.fill",
                            text: $currentValue,
                            placeholder: "未填寫則使用申購金額",
                            keyboardType: .decimalPad,
                            isRequired: false
                        )

                        // 已領利息
                        FormField(
                            label: "已領利息",
                            icon: "arrow.down.circle",
                            text: $receivedInterest,
                            placeholder: "例如: 1500",
                            keyboardType: .decimalPad,
                            isRequired: false
                        )
                    }
                    .padding(.top)
                }
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("編輯公司債")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveBond()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCurrencyPicker) {
                PickerSheet(
                    title: "選擇幣別",
                    options: currencies,
                    selectedOption: $currency
                )
            }
            .alert("提示", isPresented: $showAlert) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func saveBond() {
        // 驗證必填欄位
        guard !bondName.isEmpty else {
            alertMessage = "請填寫債券名稱"
            showAlert = true
            return
        }

        // 更新債券資料
        bond.bondName = bondName
        bond.currency = currency
        bond.couponRate = couponRate
        bond.yieldRate = yieldRate
        bond.subscriptionPrice = subscriptionPrice
        bond.holdingFaceValue = holdingFaceValue
        bond.previousHandInterest = previousHandInterest
        bond.currentValue = currentValue
        bond.receivedInterest = receivedInterest
        bond.dividendMonths = dividendMonths

        // 計算申購金額
        let price = Double(subscriptionPrice.replacingOccurrences(of: ",", with: "")) ?? 0
        let faceValue = Double(holdingFaceValue.replacingOccurrences(of: ",", with: "")) ?? 0
        let subscriptionAmount = price * faceValue / 100
        bond.subscriptionAmount = String(format: "%.2f", subscriptionAmount)

        // 計算交易金額 = 申購金額 + 前手息
        let previousInterest = Double(previousHandInterest.replacingOccurrences(of: ",", with: "")) ?? 0
        let transactionAmount = subscriptionAmount + previousInterest
        bond.transactionAmount = String(format: "%.2f", transactionAmount)

        // ⭐️ 如果現值為空或為 0，自動使用申購金額作為初始現值
        var currentVal = Double(currentValue.replacingOccurrences(of: ",", with: "")) ?? 0
        if currentVal == 0 && transactionAmount > 0 {
            currentVal = transactionAmount
            bond.currentValue = String(format: "%.2f", currentVal)
            print("✅ 現值為空，自動使用申購金額：\(currentVal)")
        }

        // 計算報酬率
        let receivedInt = Double(receivedInterest.replacingOccurrences(of: ",", with: "")) ?? 0

        if transactionAmount > 0 {
            let returnRateValue = ((currentVal - transactionAmount + receivedInt) / transactionAmount) * 100
            bond.returnRate = String(format: "%.2f%%", returnRateValue)
        } else {
            bond.returnRate = "0%"
        }

        // 儲存
        do {
            try viewContext.save()
            PersistenceController.shared.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "保存失敗: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
