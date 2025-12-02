//
//
//  InsuranceOCREditView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/14.
//

import SwiftUI

struct InsuranceOCREditView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext

    let selectedImage: UIImage
    @State private var policyData: InsurancePolicyData
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var completeness: Double = 0.0
    @State private var missingFields: [String] = []

    let client: Client?
    let onSave: (InsurancePolicyData) -> Void

    init(image: UIImage, initialData: InsurancePolicyData, client: Client?, onSave: @escaping (InsurancePolicyData) -> Void) {
        self.selectedImage = image
        _policyData = State(initialValue: initialData)
        self.client = client
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 圖片預覽
                    imagePreviewSection

                    // 完整度指示器
                    completenessIndicator

                    // 表單編輯區域
                    formSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("確認保單資料")
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
                }
            }
            .alert("儲存結果", isPresented: $showAlert) {
                Button("確定", role: .cancel) {
                    if !alertMessage.contains("錯誤") && !alertMessage.contains("失敗") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                updateCompleteness()
                // 如果保單始期有值但繳費月份為空，自動提取
                if !policyData.startDate.isEmpty && policyData.paymentMonth.isEmpty {
                    extractPaymentMonth()
                }
            }
        }
    }

    // MARK: - 圖片預覽區域
    private var imagePreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("保單照片")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - 完整度指示器
    private var completenessIndicator: some View {
        VStack(spacing: 12) {
            HStack {
                Text("資料完整度")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("\(Int(completeness * 100))%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(completeness >= 0.7 ? .green : .orange)
            }

            // 進度條
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: completeness >= 0.7 ? [.green, .green.opacity(0.8)] : [.orange, .orange.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * completeness, height: 12)
                }
            }
            .frame(height: 12)

            if !missingFields.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("缺少：\(missingFields.joined(separator: "、"))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - 表單區域
    private var formSection: some View {
        VStack(spacing: 16) {
            FormField(
                label: "保險種類",
                icon: "list.bullet",
                text: $policyData.policyType,
                placeholder: "例：壽險、醫療險、意外險、投資型",
                isRequired: true
            )

            FormField(
                label: "保險公司",
                icon: "building.2",
                text: $policyData.insuranceCompany,
                placeholder: "例：國泰人壽",
                isRequired: true
            )

            FormField(
                label: "保單號碼",
                icon: "number",
                text: $policyData.policyNumber,
                placeholder: "例：ABC1234567",
                isRequired: true
            )

            FormField(
                label: "保險名稱",
                icon: "doc.text",
                text: $policyData.policyName,
                placeholder: "例：終身壽險",
                isRequired: true
            )

            FormField(
                label: "要保人",
                icon: "person.circle",
                text: $policyData.policyHolder,
                placeholder: "例：張三",
                isRequired: true
            )

            FormField(
                label: "被保險人",
                icon: "person",
                text: $policyData.insuredPerson,
                placeholder: "例：張三",
                isRequired: true
            )

            FormField(
                label: "保單始期",
                icon: "calendar",
                text: $policyData.startDate,
                placeholder: "例：2024/01/01",
                isRequired: true,
                onChange: {
                    // 自動從保單始期提取月份到繳費月份
                    extractPaymentMonth()
                }
            )

            FormField(
                label: "繳費月份",
                icon: "calendar.badge.clock",
                text: $policyData.paymentMonth,
                placeholder: "自動從保單始期帶入",
                isRequired: false
            )

            FormField(
                label: "保額",
                icon: "dollarsign.circle",
                text: $policyData.coverageAmount,
                placeholder: "例：1000000",
                keyboardType: .numberPad,
                isRequired: true
            )

            FormField(
                label: "年繳保費",
                icon: "creditcard",
                text: $policyData.annualPremium,
                placeholder: "例：50000",
                keyboardType: .numberPad,
                isRequired: true
            )

            FormField(
                label: "繳費年期",
                icon: "timer",
                text: $policyData.paymentPeriod,
                placeholder: "例：20",
                keyboardType: .numberPad,
                isRequired: false
            )
        }
        .onChange(of: policyData.policyType) { _ in updateCompleteness() }
        .onChange(of: policyData.insuranceCompany) { _ in updateCompleteness() }
        .onChange(of: policyData.policyNumber) { _ in updateCompleteness() }
        .onChange(of: policyData.policyName) { _ in updateCompleteness() }
        .onChange(of: policyData.insuredPerson) { _ in updateCompleteness() }
        .onChange(of: policyData.startDate) { _ in updateCompleteness() }
        .onChange(of: policyData.paymentMonth) { _ in updateCompleteness() }
        .onChange(of: policyData.coverageAmount) { _ in updateCompleteness() }
        .onChange(of: policyData.annualPremium) { _ in updateCompleteness() }
        .onChange(of: policyData.paymentPeriod) { _ in updateCompleteness() }
    }

    // MARK: - 儲存功能
    private func savePolicyData() {
        // 驗證必填欄位
        if policyData.policyType.isEmpty || policyData.insuranceCompany.isEmpty ||
           policyData.policyNumber.isEmpty || policyData.policyName.isEmpty {
            alertMessage = "請填寫必填欄位：保險種類、保險公司、保單號碼、保險名稱"
            showAlert = true
            return
        }

        // TODO: 儲存到 Core Data
        // 目前先回傳資料給父視圖
        onSave(policyData)

        print("✅ 保單資料準備儲存：")
        print("  - 保險種類：\(policyData.policyType)")
        print("  - 保險公司：\(policyData.insuranceCompany)")
        print("  - 保單號碼：\(policyData.policyNumber)")
        print("  - 保險名稱：\(policyData.policyName)")
        print("  - 要保人：\(policyData.policyHolder)")
        print("  - 被保險人：\(policyData.insuredPerson)")
        print("  - 保單始期：\(policyData.startDate)")
        print("  - 繳費月份：\(policyData.paymentMonth)")
        print("  - 保額：\(policyData.coverageAmount)")
        print("  - 年繳保費：\(policyData.annualPremium)")
        print("  - 繳費年期：\(policyData.paymentPeriod)")

        // 直接關閉視圖
        presentationMode.wrappedValue.dismiss()
    }

    // MARK: - 更新完整度
    private func updateCompleteness() {
        let ocrManager = InsuranceOCRManager()
        let validation = ocrManager.validateData(policyData)
        completeness = validation.completeness
        missingFields = validation.missingFields
    }

    // MARK: - 從保單始期提取月份
    private func extractPaymentMonth() {
        // 從保單始期提取月份
        let dateString = policyData.startDate

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
                    policyData.paymentMonth = month
                    print("✅ 自動提取繳費月份：\(month)")
                    return
                }
            }
        }

        print("⚠️ 無法從保單始期提取月份：\(dateString)")
    }
}

#Preview {
    InsuranceOCREditView(
        image: UIImage(systemName: "doc.text")!,
        initialData: InsurancePolicyData(),
        client: nil,
        onSave: { _ in }
    )
}
