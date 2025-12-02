//
//  MultiplePoliciesReviewView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/14.
//

import SwiftUI

/// 多筆保單審閱編輯畫面
/// 用於從一張表格照片中辨識出多筆保單後，進行批次審閱和編輯
struct MultiplePoliciesReviewView: View {
    @Environment(\.presentationMode) var presentationMode

    let image: UIImage
    @Binding var policiesData: [InsurancePolicyData]
    let client: Client?
    let onConfirm: ([InsurancePolicyData]) -> Void

    @State private var selectedPolicyIndex: Int? = nil
    @State private var showingImagePreview = false
    @State private var editingPolicies: [InsurancePolicyData] = []

    init(image: UIImage, policiesData: Binding<[InsurancePolicyData]>, client: Client?, onConfirm: @escaping ([InsurancePolicyData]) -> Void) {
        self.image = image
        self._policiesData = policiesData
        self.client = client
        self.onConfirm = onConfirm
        self._editingPolicies = State(initialValue: policiesData.wrappedValue)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 頂部照片預覽區
                imagePreviewSection

                // 分隔線
                Divider()

                // 保單列表
                if editingPolicies.isEmpty {
                    emptyStateView
                } else {
                    policiesListView
                }
            }
            .navigationTitle("辨識結果審閱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("確認全部") {
                        confirmAllPolicies()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(editingPolicies.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingImagePreview) {
            ImagePreviewView(image: image)
        }
    }

    // MARK: - 照片預覽區
    private var imagePreviewSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("辨識來源照片")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    showingImagePreview = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                        Text("查看大圖")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // 照片縮圖
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 空狀態
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("沒有辨識到保單資料")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("請嘗試重新拍攝照片，確保表格內容清晰可見")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 保單列表
    private var policiesListView: some View {
        VStack(spacing: 0) {
            // 統計資訊
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("共辨識到 \(editingPolicies.count) 筆保單")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text("點擊可編輯")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGroupedBackground))

            // 保單卡片列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(editingPolicies.enumerated()), id: \.offset) { index, policy in
                        PolicyCardView(
                            policy: policy,
                            index: index,
                            onEdit: {
                                selectedPolicyIndex = index
                            },
                            onDelete: {
                                deletePolicy(at: index)
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .sheet(item: Binding(
            get: { selectedPolicyIndex.map { IndexWrapper(index: $0) } },
            set: { selectedPolicyIndex = $0?.index }
        )) { wrapper in
            PolicyEditSheet(
                policy: $editingPolicies[wrapper.index],
                client: client,
                onSave: {
                    selectedPolicyIndex = nil
                }
            )
        }
    }

    // MARK: - 操作函數

    private func deletePolicy(at index: Int) {
        withAnimation {
            editingPolicies.remove(at: index)
        }
    }

    private func confirmAllPolicies() {
        onConfirm(editingPolicies)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 保單卡片
struct PolicyCardView: View {
    let policy: InsurancePolicyData
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題列
            HStack {
                Text("保單 #\(index + 1)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                // 完整度指示器
                completenessIndicator

                // 編輯按鈕
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("編輯")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }

                // 刪除按鈕
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            // 保單資訊
            VStack(spacing: 8) {
                if !policy.insuranceCompany.isEmpty {
                    InfoRow(label: "保險公司", value: policy.insuranceCompany)
                }
                if !policy.policyName.isEmpty {
                    InfoRow(label: "保險名稱", value: policy.policyName)
                }
                if !policy.policyNumber.isEmpty {
                    InfoRow(label: "保單號碼", value: policy.policyNumber)
                }
                if !policy.policyHolder.isEmpty {
                    InfoRow(label: "要保人", value: policy.policyHolder)
                }
                if !policy.insuredPerson.isEmpty {
                    InfoRow(label: "被保險人", value: policy.insuredPerson)
                }
                if !policy.coverageAmount.isEmpty {
                    InfoRow(label: "保額", value: "$\(formatNumber(policy.coverageAmount))")
                }
                if !policy.annualPremium.isEmpty {
                    InfoRow(label: "年繳保費", value: "$\(formatNumber(policy.annualPremium))")
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // 完整度指示器
    private var completenessIndicator: some View {
        let completeness = calculateCompleteness()
        let color: Color = completeness > 0.7 ? .green : completeness > 0.4 ? .orange : .red

        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(Int(completeness * 100))%")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
        }
    }

    private func calculateCompleteness() -> Double {
        let fields = [
            policy.insuranceCompany,
            policy.policyName,
            policy.policyNumber,
            policy.insuredPerson,
            policy.coverageAmount,
            policy.annualPremium
        ]
        let filledCount = fields.filter { !$0.isEmpty }.count
        return Double(filledCount) / Double(fields.count)
    }

    private func formatNumber(_ value: String) -> String {
        guard let number = Double(value) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? value
    }
}

// MARK: - 資訊行
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - 保單編輯 Sheet
struct PolicyEditSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var policy: InsurancePolicyData
    let client: Client?
    let onSave: () -> Void

    // MARK: - 從保單始期提取月份
    private func extractPaymentMonth() {
        let dateString = policy.startDate

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
                    policy.paymentMonth = month
                    print("✅ 自動提取繳費月份：\(month)")
                    return
                }
            }
        }

        print("⚠️ 無法從保單始期提取月份：\(dateString)")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本資訊")) {
                    TextField("保險公司", text: $policy.insuranceCompany)
                    TextField("保險名稱", text: $policy.policyName)
                    TextField("保單號碼", text: $policy.policyNumber)
                    TextField("保險種類", text: $policy.policyType)
                }

                Section(header: Text("保險人資訊")) {
                    TextField("要保人", text: $policy.policyHolder)
                    TextField("被保險人", text: $policy.insuredPerson)
                }

                Section(header: Text("金額資訊")) {
                    TextField("保額", text: $policy.coverageAmount)
                        .keyboardType(.decimalPad)
                    TextField("年繳保費", text: $policy.annualPremium)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("日期資訊")) {
                    TextField("保單始期", text: $policy.startDate)
                        .onChange(of: policy.startDate) { _ in
                            extractPaymentMonth()
                        }
                    TextField("繳費月份（自動帶入）", text: $policy.paymentMonth)
                    TextField("繳費年期", text: $policy.paymentPeriod)
                }
            }
            .navigationTitle("編輯保單")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 如果保單始期有值但繳費月份為空，自動提取
                if !policy.startDate.isEmpty && policy.paymentMonth.isEmpty {
                    extractPaymentMonth()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        onSave()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - 照片預覽
struct ImagePreviewView: View {
    @Environment(\.presentationMode) var presentationMode
    let image: UIImage

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - 輔助結構
struct IndexWrapper: Identifiable {
    let id = UUID()
    let index: Int
}

#Preview {
    let sampleData = [
        InsurancePolicyData(
            policyType: "壽險",
            insuranceCompany: "國泰人壽",
            policyNumber: "P123456789",
            policyName: "終身壽險",
            insuredPerson: "王小明",
            startDate: "2024/01/01",
            paymentMonth: "1",
            coverageAmount: "1000000",
            annualPremium: "50000",
            paymentPeriod: "20年"
        ),
        InsurancePolicyData(
            policyType: "醫療險",
            insuranceCompany: "富邦人壽",
            policyNumber: "P987654321",
            policyName: "醫療保險",
            insuredPerson: "王小明",
            startDate: "2024/02/01",
            paymentMonth: "2",
            coverageAmount: "500000",
            annualPremium: "30000",
            paymentPeriod: "終身"
        )
    ]

    return MultiplePoliciesReviewView(
        image: UIImage(systemName: "doc.text")!,
        policiesData: .constant(sampleData),
        client: nil,
        onConfirm: { _ in }
    )
}
