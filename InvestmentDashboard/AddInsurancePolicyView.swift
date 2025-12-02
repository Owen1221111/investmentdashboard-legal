//
//  AddInsurancePolicyView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/14.
//

import SwiftUI

struct AddInsurancePolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext

    let client: Client?
    let onSave: (InsurancePolicyData) -> Void

    @State private var policyType: String = ""
    @State private var insuranceCompany: String = ""
    @State private var policyNumber: String = ""
    @State private var policyName: String = ""
    @State private var policyHolder: String = ""
    @State private var insuredPerson: String = ""
    @State private var startDate: String = ""
    @State private var paymentMonth: String = ""
    @State private var coverageAmount: String = ""
    @State private var annualPremium: String = ""
    @State private var paymentPeriod: String = ""
    @State private var beneficiary: String = ""
    @State private var interestRate: String = ""
    @State private var currency: String = "TWD"
    @State private var exchangeRate: String = "32"
    @State private var twdAmount: String = ""

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showingPolicyTypePicker = false
    @State private var showingCompanyPicker = false
    @State private var showingCurrencyPicker = false

    // 保險種類選項
    private let policyTypes = ["儲蓄險", "保障型", "投資型", "醫療險", "意外險"]

    // 台灣主要保險公司
    private let insuranceCompanies = [
        "國泰人壽", "富邦人壽", "南山人壽", "新光人壽", "中國人壽",
        "台灣人壽", "全球人壽", "遠雄人壽", "三商美邦", "保誠人壽",
        "安聯人壽", "元大人壽", "宏泰人壽", "中華郵政", "第一金人壽"
    ]

    // 幣別選項
    private let currencies = ["TWD", "USD", "CNY", "HKD", "JPY", "EUR"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 客戶資訊卡片
                    if let client = client {
                        clientInfoCard(client: client)
                    }

                    // 表單區域
                    VStack(spacing: 16) {
                        // 保險種類（選擇器）
                        PickerField(
                            label: "保險種類",
                            icon: "list.bullet",
                            value: $policyType,
                            placeholder: "請選擇保險種類",
                            isRequired: true,
                            onTap: { showingPolicyTypePicker = true }
                        )

                        // 保險公司（改為文字輸入）
                        FormField(
                            label: "保險公司",
                            icon: "building.2",
                            text: $insuranceCompany,
                            placeholder: "例：國泰人壽",
                            isRequired: true
                        )

                        FormField(
                            label: "保單號碼",
                            icon: "number",
                            text: $policyNumber,
                            placeholder: "例：ABC1234567",
                            isRequired: true
                        )

                        FormField(
                            label: "保險名稱",
                            icon: "doc.text",
                            text: $policyName,
                            placeholder: "例：終身壽險",
                            isRequired: true
                        )

                        FormField(
                            label: "要保人",
                            icon: "person.circle",
                            text: $policyHolder,
                            placeholder: "例：張三",
                            isRequired: true
                        )

                        FormField(
                            label: "被保險人",
                            icon: "person",
                            text: $insuredPerson,
                            placeholder: "例：張三",
                            isRequired: true
                        )

                        FormField(
                            label: "保單始期",
                            icon: "calendar",
                            text: $startDate,
                            placeholder: "例：2024/01/01",
                            isRequired: true,
                            onChange: {
                                // 自動從保單始期提取月份
                                extractPaymentMonth()
                            }
                        )

                        FormField(
                            label: "繳費年期",
                            icon: "timer",
                            text: $paymentPeriod,
                            placeholder: "例：20",
                            keyboardType: .numberPad,
                            isRequired: false
                        )

                        FormField(
                            label: "繳費月份",
                            icon: "calendar.badge.clock",
                            text: $paymentMonth,
                            placeholder: "自動從保單始期帶入",
                            keyboardType: .numberPad,
                            isRequired: false
                        )

                        FormField(
                            label: "保額",
                            icon: "dollarsign.circle",
                            text: $coverageAmount,
                            placeholder: "例：1000000",
                            keyboardType: .numberPad,
                            isRequired: true
                        )

                        FormField(
                            label: "年繳保費",
                            icon: "creditcard",
                            text: $annualPremium,
                            placeholder: "例：50000",
                            keyboardType: .numberPad,
                            isRequired: true
                        )

                        FormField(
                            label: "受益人",
                            icon: "person.2",
                            text: $beneficiary,
                            placeholder: "例：配偶",
                            isRequired: false
                        )

                        FormField(
                            label: "利率 (%)",
                            icon: "percent",
                            text: $interestRate,
                            placeholder: "例：2.5",
                            keyboardType: .decimalPad,
                            isRequired: false
                        )

                        // 幣別（選擇器）
                        PickerField(
                            label: "幣別",
                            icon: "dollarsign.circle",
                            value: $currency,
                            placeholder: "請選擇幣別",
                            isRequired: false,
                            onTap: { showingCurrencyPicker = true }
                        )

                        FormField(
                            label: "匯率",
                            icon: "arrow.left.arrow.right",
                            text: $exchangeRate,
                            placeholder: "例：32",
                            keyboardType: .decimalPad,
                            isRequired: false
                        )
                        .onChange(of: exchangeRate) { _ in
                            calculateTwdAmount()
                        }
                        .onChange(of: annualPremium) { _ in
                            calculateTwdAmount()
                        }

                        FormField(
                            label: "折合台幣",
                            icon: "taiwandollar.circle",
                            text: $twdAmount,
                            placeholder: "自動計算或手動輸入",
                            keyboardType: .decimalPad,
                            isRequired: false
                        )
                    }

                    // 提示訊息
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("標示 * 為必填欄位")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("新增保單")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        savePolicyData()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
            .alert("儲存結果", isPresented: $showAlert) {
                Button("確定", role: .cancel) {
                    if !alertMessage.contains("錯誤") && !alertMessage.contains("請填寫") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
        .sheet(isPresented: $showingPolicyTypePicker) {
            PickerSheet(
                title: "選擇保險種類",
                options: policyTypes,
                selectedOption: $policyType
            )
        }
        .sheet(isPresented: $showingCompanyPicker) {
            PickerSheet(
                title: "選擇保險公司",
                options: insuranceCompanies,
                selectedOption: $insuranceCompany
            )
        }
        .sheet(isPresented: $showingCurrencyPicker) {
            PickerSheet(
                title: "選擇幣別",
                options: currencies,
                selectedOption: $currency
            )
        }
        .onAppear {
            // 預設要保人為客戶本人
            if let client = client, policyHolder.isEmpty {
                policyHolder = client.name ?? ""
            }
        }
    }

    // MARK: - 客戶資訊卡片
    private func clientInfoCard(client: Client) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("客戶")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text(client.name ?? "未知客戶")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - 表單驗證
    private var isFormValid: Bool {
        !policyType.isEmpty &&
        !insuranceCompany.isEmpty &&
        !policyNumber.isEmpty &&
        !policyName.isEmpty &&
        !policyHolder.isEmpty &&
        !insuredPerson.isEmpty &&
        !startDate.isEmpty &&
        !coverageAmount.isEmpty &&
        !annualPremium.isEmpty
    }

    // MARK: - 儲存功能
    private func savePolicyData() {
        // 驗證必填欄位
        guard isFormValid else {
            alertMessage = "請填寫所有必填欄位（標示 * 的欄位）"
            showAlert = true
            return
        }

        // 建立保單資料
        var policyData = InsurancePolicyData()
        policyData.policyType = policyType
        policyData.insuranceCompany = insuranceCompany
        policyData.policyNumber = policyNumber
        policyData.policyName = policyName
        policyData.policyHolder = policyHolder
        policyData.insuredPerson = insuredPerson
        policyData.startDate = startDate
        policyData.paymentMonth = paymentMonth
        policyData.coverageAmount = coverageAmount
        policyData.annualPremium = annualPremium
        policyData.paymentPeriod = paymentPeriod
        policyData.beneficiary = beneficiary
        policyData.interestRate = interestRate
        policyData.currency = currency
        policyData.exchangeRate = exchangeRate
        policyData.twdAmount = twdAmount

        // TODO: 儲存到 Core Data
        onSave(policyData)

        print("✅ 手動新增保單資料：")
        print("  - 保險種類：\(policyType)")
        print("  - 保險公司：\(insuranceCompany)")
        print("  - 保單號碼：\(policyNumber)")
        print("  - 保險名稱：\(policyName)")
        print("  - 要保人：\(policyHolder)")
        print("  - 被保險人：\(insuredPerson)")
        print("  - 保單始期：\(startDate)")
        print("  - 繳費月份：\(paymentMonth)")
        print("  - 保額：\(coverageAmount)")
        print("  - 年繳保費：\(annualPremium)")
        print("  - 繳費年期：\(paymentPeriod)")

        // 直接關閉視圖
        presentationMode.wrappedValue.dismiss()
    }

    // MARK: - 從保單始期提取月份
    private func extractPaymentMonth() {
        // 從保單始期提取月份
        let dateString = startDate

        // 支援多種日期格式：2024/01/01、2024-01-01、2024年1月1日
        let patterns = [
            "/([0-9]{1,2})/",      // 2024/01/01
            "-([0-9]{1,2})-",      // 2024-01-01
            "年([0-9]{1,2})月"      // 2024年1月1日
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: dateString, range: NSRange(dateString.startIndex..., in: dateString)) {
                if let range = Range(match.range(at: 1), in: dateString) {
                    let month = String(dateString[range])
                    paymentMonth = month
                    print("✅ 自動提取繳費月份：\(month)")
                    return
                }
            }
        }

        print("⚠️ 無法從保單始期提取月份：\(dateString)")
    }

    // MARK: - 計算折合台幣
    private func calculateTwdAmount() {
        // 如果年繳保費和匯率都有值，自動計算折合台幣
        guard !annualPremium.isEmpty, !exchangeRate.isEmpty else {
            return
        }

        if let premium = Double(annualPremium),
           let rate = Double(exchangeRate) {
            let calculated = premium * rate
            twdAmount = String(format: "%.0f", calculated)
            print("✅ 自動計算折合台幣：\(annualPremium) × \(exchangeRate) = \(twdAmount)")
        }
    }
}

#Preview {
    AddInsurancePolicyView(client: nil, onSave: { _ in })
}
