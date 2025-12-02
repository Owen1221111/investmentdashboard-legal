//
//  InsurancePolicyView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/13.
//

import SwiftUI
import CoreData

struct InsurancePolicyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var isExpanded = false  // 預設收合表格
    @State private var showingColumnReorder = false
    @State private var columnOrder: [String] = []
    @State private var showingImagePicker = false
    @State private var showingPhotoOptions = false
    @State private var showingAddPolicyAlert = false
    @State private var showingAddPolicyView = false
    @State private var selectedImage: UIImage?
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingOCREditView = false
    @State private var ocrPolicyData: InsurancePolicyData?
    @State private var isProcessingOCR = false
    @State private var policyToDelete: InsurancePolicy? = nil
    @State private var showingDeleteConfirmation = false
    @State private var showingSubscription = false

    // 排序相關
    @State private var sortByStartDateAscending: Bool = false  // true: 升序，false: 降序
    @State private var isEditingField: Bool = false  // 追蹤是否正在編輯欄位

    // 幣別切換
    @State private var selectedCurrency = "美金"  // 預設顯示美金

    // 走勢圖互動
    @State private var selectedAge: Int? = nil
    @State private var selectedDeathBenefit: Double? = nil
    @State private var ageDeathBenefitCache: [Int: Double] = [:]  // 快取年齡對應的保額
    @State private var hideDataPointWorkItem: DispatchWorkItem? = nil

    // 月度保費懸停互動
    @State private var hoveredPremiumMonth: Int? = nil

    // 表格辨識相關（一張照片多筆保單）
    @State private var multiplePoliciesData: [InsurancePolicyData] = []
    @State private var showingMultiplePoliciesView = false
    @State private var currentImageForBatch: UIImage?

    // 快速存放試算表相關（已改為直接存儲，不再需要文件選擇器）
    // @State private var showingQuickUploadFilePicker = false
    // @State private var selectedPolicyForQuickUpload: InsurancePolicy? = nil

    // 保險導覽系統
    @StateObject private var insuranceTutorialManager = InsuranceTutorialManager()
    @State private var showingInsuranceTutorial = false

    // 使用 Core Data FetchRequest 代替 savedPolicies
    @FetchRequest var insurancePolicies: FetchedResults<InsurancePolicy>

    let client: Client?
    let onBack: () -> Void

    init(client: Client?, onBack: @escaping () -> Void) {
        self.client = client
        self.onBack = onBack

        // 根據客戶篩選保單
        let predicate: NSPredicate
        if let client = client {
            predicate = NSPredicate(format: "client == %@", client)
        } else {
            predicate = NSPredicate(value: false) // 沒有客戶時不顯示任何資料
        }

        _insurancePolicies = FetchRequest<InsurancePolicy>(
            entity: InsurancePolicy.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \InsurancePolicy.createdDate, ascending: false)],
            predicate: predicate
        )
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 自定義頂部導航欄
                customNavigationBar

            // 主要內容
            if let client = client {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 20) {
                            // 上半部：保單總額大卡
                            insuranceSummaryCard

                            // 中間區域：圓餅圖 + 四張固定卡片
                            if geometry.size.width > 600 {
                                // iPad 佈局
                                HStack(alignment: .top, spacing: 16) {
                                    insurancePieChartCard
                                        .frame(maxWidth: 380, maxHeight: 585)

                                    VStack(spacing: 16) {
                                        // 固定四張卡片
                                        savingsInsuranceCard
                                        investmentInsuranceCard
                                        protectionInsuranceCard
                                        monthlyPremiumCard
                                    }
                                }
                            } else {
                                // iPhone 佈局
                                VStack(spacing: 16) {
                                    insurancePieChartCard
                                    // 固定四張卡片
                                    savingsInsuranceCard
                                    investmentInsuranceCard
                                    protectionInsuranceCard
                                    monthlyPremiumCard
                                }
                            }

                            // 下半部：保單列表管理
                            insurancePolicyList

                            // 保險試算表存放
                            InsuranceCalculatorView(client: client)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
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
        .confirmationDialog("選擇照片來源", isPresented: $showingPhotoOptions, titleVisibility: .visible) {
            Button("拍照") {
                imagePickerSourceType = .camera
                showingImagePicker = true
            }
            Button("從相簿選擇") {
                imagePickerSourceType = .photoLibrary
                showingImagePicker = true
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("請選擇要如何上傳保單照片\n（支援表格形式的多筆保單）")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: imagePickerSourceType)
        }
        .sheet(isPresented: $showingOCREditView) {
            if let image = selectedImage, let policyData = ocrPolicyData {
                InsuranceOCREditView(image: image, initialData: policyData, client: client) { savedData in
                    print("✅ 保單資料已確認：\(savedData.policyName)")
                    saveToCoreData(savedData)
                }
            }
        }
        .overlay {
            if isProcessingOCR {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("正在辨識保單內容...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        Text("（支援自動辨識表格中的多筆保單）")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.8))
                    )
                }
            }
        }
        .onChange(of: selectedImage) { image in
            guard let image = image else { return }
            processImageWithOCR(image)
        }
        .sheet(isPresented: $showingMultiplePoliciesView) {
            if !multiplePoliciesData.isEmpty, let image = currentImageForBatch {
                MultiplePoliciesReviewView(
                    image: image,
                    policiesData: $multiplePoliciesData,
                    client: client
                ) { confirmedPolicies in
                    // 批次儲存所有確認的保單
                    for policyData in confirmedPolicies {
                        saveToCoreData(policyData)
                    }
                    print("✅ 批次儲存完成：共 \(confirmedPolicies.count) 筆保單")
                }
            }
        }
        .sheet(isPresented: $showingColumnReorder) {
            ColumnReorderView(
                headers: insurancePolicyHeaders,
                initialOrder: columnOrder.isEmpty ? insurancePolicyHeaders : columnOrder,
                onSave: { newOrder in
                    columnOrder = newOrder
                    // 儲存到 UserDefaults
                    UserDefaults.standard.set(newOrder, forKey: "InsurancePolicy_ColumnOrder")
                }
            )
        }
        .onAppear {
            // 從 UserDefaults 讀取欄位排序
            if let savedOrder = UserDefaults.standard.array(forKey: "InsurancePolicy_ColumnOrder") as? [String], !savedOrder.isEmpty {
                // 檢查儲存的排序是否包含所有新欄位
                let savedSet = Set(savedOrder)
                let currentSet = Set(insurancePolicyHeaders)

                // 如果有新欄位未在舊排序中,重置為預設排序
                if currentSet.isSubset(of: savedSet) && savedSet.count == currentSet.count {
                    columnOrder = savedOrder
                } else {
                    // 有新欄位或欄位數量不符,使用預設排序並清除舊設定
                    columnOrder = insurancePolicyHeaders
                    UserDefaults.standard.removeObject(forKey: "InsurancePolicy_ColumnOrder")
                    print("🔄 偵測到新欄位,已重置欄位排序")
                }
            } else if columnOrder.isEmpty {
                columnOrder = insurancePolicyHeaders
            }

            // 檢查是否需要顯示保險導覽
            if insuranceTutorialManager.shouldShowTutorial() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingInsuranceTutorial = true
                }
            }
        }
        .sheet(isPresented: $showingAddPolicyView) {
            AddInsurancePolicyView(client: client) { savedData in
                print("✅ 手動新增的保單資料已確認：\(savedData.policyName)")
                saveToCoreData(savedData)
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) {
                policyToDelete = nil
            }
            Button("刪除", role: .destructive) {
                if let policy = policyToDelete {
                    deletePolicy(policy)
                    policyToDelete = nil
                }
            }
        } message: {
            if let policy = policyToDelete {
                Text("確定要刪除「\(policy.policyName ?? "此保單")」的資料嗎？此操作無法復原。")
            } else {
                Text("確定要刪除此保單資料嗎？此操作無法復原。")
            }
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
                .environmentObject(subscriptionManager)
        }

            // 保險功能導覽
            if showingInsuranceTutorial {
                InsuranceTutorialView(onComplete: {
                    showingInsuranceTutorial = false
                })
                .transition(.opacity)
            }
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
                Text("保單管理")
                    .font(.headline)
                    .fontWeight(.semibold)

                if let client = client {
                    Text(client.name ?? "未知客戶")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 說明按鈕
            Button(action: {
                showingInsuranceTutorial = true
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.blue)
            }
            .frame(width: 44, height: 44)

            // 右側：新增按鈕（手動新增保單，彈出表單）
            Button(action: {
                if !subscriptionManager.canAccessPremiumFeatures() {
                    showingSubscription = true
                } else {
                    showingAddPolicyView = true
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 保單總額大卡
    private var insuranceSummaryCard: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                if geometry.size.width > 600 {
                    // iPad 佈局：橫向排列
                    HStack(alignment: .top, spacing: 24) {
                        // 左側：保障額度區域
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 10) {
                                Text("保障額度")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.secondary)

                                // 幣別切換按鈕
                                HStack(spacing: 0) {
                                    Button("美金") {
                                        selectedCurrency = "美金"
                                        ageDeathBenefitCache.removeAll()  // 清空快取以重新計算
                                    }
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(selectedCurrency == "美金" ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.clear)
                                    .foregroundColor(selectedCurrency == "美金" ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))

                                    Button("台幣") {
                                        selectedCurrency = "台幣"
                                        ageDeathBenefitCache.removeAll()  // 清空快取以重新計算
                                    }
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(selectedCurrency == "台幣" ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.clear)
                                    .foregroundColor(selectedCurrency == "台幣" ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                                }
                                .background(Color(.init(red: 0.95, green: 0.95, blue: 0.96, alpha: 0.6)))
                                .clipShape(Capsule())

                                Spacer()
                            }
                            .padding(.bottom, 12)

                            Text(formatCurrency(getTotalCoverage()))
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)

                            Spacer()

                            // 時間按鈕（與右側卡片底部對齊）
                            HStack(spacing: 8) {
                                ForEach(["ALL", "7D", "1M", "3M", "1Y"], id: \.self) { period in
                                    Button(period) {
                                        // selectedPeriod = period
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(period == "ALL" ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.gray.opacity(0.2))
                                    .foregroundColor(period == "ALL" ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                                    .clipShape(Capsule())
                                }
                            }
                        }

                        // 右上角：統計小卡片群組
                        insuranceMiniStatsCardGroup
                            .frame(maxWidth: 392)
                    }
                } else {
                    // iPhone 佈局：垂直排列
                    VStack(alignment: .leading, spacing: 16) {
                        // 保障額度
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Text("保障額度")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)

                                // 幣別切換按鈕
                                HStack(spacing: 0) {
                                    Button("美金") {
                                        selectedCurrency = "美金"
                                        ageDeathBenefitCache.removeAll()  // 清空快取以重新計算
                                    }
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(selectedCurrency == "美金" ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.clear)
                                    .foregroundColor(selectedCurrency == "美金" ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))

                                    Button("台幣") {
                                        selectedCurrency = "台幣"
                                        ageDeathBenefitCache.removeAll()  // 清空快取以重新計算
                                    }
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(selectedCurrency == "台幣" ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.clear)
                                    .foregroundColor(selectedCurrency == "台幣" ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                                }
                                .background(Color(.init(red: 0.95, green: 0.95, blue: 0.96, alpha: 0.6)))
                                .clipShape(Capsule())

                                Spacer()
                            }

                            Text(formatCurrency(getTotalCoverage()))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // 時間按鈕
                        HStack(spacing: 6) {
                            ForEach(["ALL", "7D", "1M", "3M", "1Y"], id: \.self) { period in
                                Button(period) {
                                    // selectedPeriod = period
                                }
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(period == "ALL" ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.gray.opacity(0.2))
                                .foregroundColor(period == "ALL" ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                                .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // 統計卡片 - 使用 LazyVGrid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            statsCardSimple(title: "總繳保費", value: formatCurrencyWithoutSymbol(getTotalAccumulatedPremium()), isHighlight: false)
                            statsCardSimple(title: "年度保費", value: formatCurrencyWithoutSymbol(getTotalAnnualPremium()), isHighlight: false)
                        }

                        // 下次需繳保費
                        VStack(alignment: .leading, spacing: 6) {
                            Text("下次需繳保費")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)

                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(selectedCurrency == "美金" ? "USD" : "TWD")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))

                                Text(formatNextPremiumDue())
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)

                                Spacer()

                                Text(formatNextPremiumMonth())
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),
                                            Color(.init(red: 0.20, green: 0.40, blue: 0.30, alpha: 1.0))
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                }

                // 走勢圖
                insuranceTrendChart
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
        }
        .frame(minHeight: 630)
    }

    // MARK: - 統計小卡片群組
    private var insuranceMiniStatsCardGroup: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // 左側：總繳保費和年度保費垂直排列
            VStack(alignment: .leading, spacing: 12) {
                // 總繳保費 - 純文字顯示
                VStack(alignment: .leading, spacing: 8) {
                    Text("總繳保費")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))

                    Text(formatCurrencyWithoutSymbol(getTotalAccumulatedPremium()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.label))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)

                // 年度保費卡片 - 白色背景
                VStack(alignment: .leading, spacing: 8) {
                    Text("年度保費")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))

                    Text(formatCurrencyWithoutSymbol(getTotalAnnualPremium()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.label))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
            }
            .frame(width: 156)

            // 右側：下次需繳保費大卡片
            insuranceReturnRateCard
                .frame(width: 160)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - 下次需繳保費卡片
    private var insuranceReturnRateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("下次需繳保費")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Spacer()
            }

            // 顯示幣別
            HStack {
                Text(selectedCurrency == "美金" ? "USD" : "TWD")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(formatNextPremiumDue())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                HStack {
                    Text(formatNextPremiumMonth())
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    Spacer()
                }
            }
        }
        .frame(width: 140, height: 120)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)),
                            Color(.init(red: 0.20, green: 0.40, blue: 0.30, alpha: 1.0))
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }

    // 統計小卡片
    private func statsCard(title: String, value: String, isHighlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))

            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isHighlight ? Color.green : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    // 簡化版統計卡片（用於 iPhone 版的 LazyVGrid）
    private func statsCardSimple(title: String, value: String, isHighlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(.label))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    // 走勢圖
    private var insuranceTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("保障額度走勢")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                // 真實數據走勢線
                GeometryReader { geometry in
                    ZStack {
                        // 漸層填充區域（線條下方）
                        insuranceTrendFillArea(in: geometry.size)

                        // 趨勢線
                        insuranceTrendLine(in: geometry.size)

                        // 選中點的標記和數值
                        if let age = selectedAge, let benefit = selectedDeathBenefit {
                            selectedPointOverlay(age: age, benefit: benefit, in: geometry.size)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // 取消之前的隱藏任務
                                hideDataPointWorkItem?.cancel()
                                updateSelectedPoint(at: value.location, in: geometry.size)
                            }
                            .onEnded { _ in
                                // 5秒後自動隱藏數據點
                                let workItem = DispatchWorkItem {
                                    withAnimation {
                                        selectedAge = nil
                                        selectedDeathBenefit = nil
                                    }
                                }
                                hideDataPointWorkItem = workItem
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)
                            }
                    )
                }
                .frame(height: 203)

                // X 軸年齡標籤
                insuranceAgeLabels
            }
        }
        .padding(.top, 8)
    }

    // X 軸年齡標籤（顯示更多年齡刻度）
    private var insuranceAgeLabels: some View {
        GeometryReader { geometry in
            let ageRange = getInsuranceAgeRange()
            let minAge = ageRange.min
            let maxAge = ageRange.max
            let totalAges = maxAge - minAge + 1

            // 計算要顯示的年齡刻度（每5年顯示一次）
            let ageSteps = stride(from: minAge, through: maxAge, by: 5).map { $0 }

            ZStack(alignment: .leading) {
                // 繪製刻度線
                ForEach(ageSteps, id: \.self) { age in
                    let position = CGFloat(age - minAge) / CGFloat(totalAges - 1) * geometry.size.width

                    VStack(spacing: 2) {
                        // 刻度線
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 1, height: 4)

                        // 年齡標籤
                        Text("\(age)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .offset(x: position)
                }
            }
        }
        .frame(height: 20)
    }

    // 取得保險年齡範圍
    private func getInsuranceAgeRange() -> (min: Int, max: Int) {
        guard let client = client else { return (min: 0, max: 100) }

        // 取得所有保險試算表
        let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        var calculators: [InsuranceCalculator] = []
        do {
            calculators = try viewContext.fetch(fetchRequest)
        } catch {
            return (min: 0, max: 100)
        }

        guard !calculators.isEmpty else { return (min: 0, max: 100) }

        // 建立保險年齡對應的身故保險金資料
        var ageDeathBenefitMap: [Int: Double] = [:]

        for insuranceAge in 0...100 {
            var totalDeathBenefit: Double = 0.0

            for calculator in calculators {
                if let deathBenefit = getDeathBenefitForInsuranceAge(calculator: calculator, insuranceAge: insuranceAge) {
                    totalDeathBenefit += deathBenefit
                }
            }

            ageDeathBenefitMap[insuranceAge] = totalDeathBenefit
        }

        // 找出有數據的年齡範圍
        let agesWithData = ageDeathBenefitMap.filter { $0.value > 0 }.keys.sorted()
        guard !agesWithData.isEmpty else { return (min: 0, max: 100) }

        let minAge = agesWithData.min() ?? 0
        let maxAge = min(agesWithData.max() ?? 100, 100)

        return (min: minAge, max: maxAge)
    }

    // 保險走勢圖填充區域
    private func insuranceTrendFillArea(in size: CGSize) -> some View {
        let points = getInsuranceTrendDataPoints(in: size)
        let baseColor = Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0))

        var path = Path()
        if !points.isEmpty {
            path.move(to: CGPoint(x: points[0].x, y: size.height))
            path.addLine(to: points[0])

            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            path.addLine(to: CGPoint(x: points.last!.x, y: size.height))
            path.closeSubpath()
        }

        return path.fill(
            LinearGradient(
                gradient: Gradient(colors: [
                    baseColor.opacity(0.3),
                    baseColor.opacity(0.02)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // 保險走勢圖線條
    private func insuranceTrendLine(in size: CGSize) -> some View {
        let points = getInsuranceTrendDataPoints(in: size)
        let baseColor = Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0))

        var path = Path()
        if !points.isEmpty {
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }

        return path.stroke(
            LinearGradient(
                gradient: Gradient(colors: [
                    baseColor,
                    baseColor.opacity(0.7)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            lineWidth: 2.5
        )
    }

    // 計算保險走勢圖數據點（使用保險年齡）
    private func getInsuranceTrendDataPoints(in size: CGSize) -> [CGPoint] {
        guard let client = client else { return [] }

        // 取得所有保險試算表
        let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        var calculators: [InsuranceCalculator] = []
        do {
            calculators = try viewContext.fetch(fetchRequest)
        } catch {
            print("❌ 取得試算表失敗：\(error.localizedDescription)")
            return []
        }

        guard !calculators.isEmpty else { return [] }

        // 建立保險年齡對應的身故保險金資料（從0歲到100歲）
        var ageDeathBenefitMap: [Int: Double] = [:]

        for insuranceAge in 0...100 {
            var totalDeathBenefit: Double = 0.0

            for calculator in calculators {
                if let deathBenefit = getDeathBenefitForInsuranceAge(calculator: calculator, insuranceAge: insuranceAge) {
                    totalDeathBenefit += deathBenefit
                }
            }

            ageDeathBenefitMap[insuranceAge] = totalDeathBenefit
        }

        // 找出有數據的年齡範圍
        let agesWithData = ageDeathBenefitMap.filter { $0.value > 0 }.keys.sorted()
        guard !agesWithData.isEmpty else { return [] }

        let minAge = agesWithData.min() ?? 0
        let maxAge = min(agesWithData.max() ?? 100, 100)

        // 轉換為數值陣列
        let ages = Array(minAge...maxAge)
        let values = ages.map { ageDeathBenefitMap[$0] ?? 0.0 }

        guard !values.isEmpty else { return [] }

        // 調試輸出
        print("📊 保險走勢圖數據：")
        print("   年齡範圍：\(minAge)歲 - \(maxAge)歲")
        print("   數據點數量：\(values.count)")
        print("   前10個數據點：\(values.prefix(10).map { String(format: "%.0f", $0) })")
        print("   後10個數據點：\(values.suffix(10).map { String(format: "%.0f", $0) })")

        // 找出最大最小值用於歸一化
        // 使用 0 作為最小值，讓走勢圖從底部開始，更能呈現實際增長
        let minValue: Double = 0
        let maxValue = values.max() ?? 1
        let range = maxValue - minValue

        print("   最小值：\(String(format: "%.0f", minValue))")
        print("   最大值：\(String(format: "%.0f", maxValue))")
        print("   數據最小值：\(String(format: "%.0f", values.min() ?? 0))")

        // 計算座標點
        let stepX = size.width / CGFloat(values.count - 1)
        var points: [CGPoint] = []

        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * stepX
            let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
            let y = size.height - (CGFloat(normalizedValue) * size.height)
            points.append(CGPoint(x: x, y: y))
        }

        return points
    }

    // 根據保險年齡取得身故保險金
    private func getDeathBenefitForInsuranceAge(calculator: InsuranceCalculator, insuranceAge: Int) -> Double? {
        // 取得該試算表的所有資料行
        let fetchRequest: NSFetchRequest<InsuranceCalculatorRow> = InsuranceCalculatorRow.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "calculator == %@", calculator)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \InsuranceCalculatorRow.rowOrder, ascending: true)]

        do {
            let rows = try viewContext.fetch(fetchRequest)

            // 找出對應保險年齡的資料行
            for row in rows {
                // insuranceAge 是 String，需要轉換比較
                if let rowAgeString = row.insuranceAge,
                   let rowAge = Int(rowAgeString),
                   rowAge == insuranceAge {
                    // 取得身故保險金
                    if let deathBenefitString = row.deathBenefit, !deathBenefitString.isEmpty {
                        let cleanedString = deathBenefitString.replacingOccurrences(of: ",", with: "")
                        return Double(cleanedString)
                    }
                }
            }
        } catch {
            print("❌ 取得試算表資料失敗：\(error.localizedDescription)")
        }

        return nil
    }

    // MARK: - 走勢圖互動功能

    /// 更新選中的點位（根據觸摸位置）- 使用快取提升流暢度
    private func updateSelectedPoint(at location: CGPoint, in size: CGSize) {
        let ageRange = getInsuranceAgeRange()
        let minAge = ageRange.min
        let maxAge = ageRange.max
        let totalAges = maxAge - minAge + 1

        // 計算觸摸位置對應的年齡
        let ageRatio = location.x / size.width
        let selectedAgeFloat = CGFloat(minAge) + ageRatio * CGFloat(totalAges - 1)
        let age = Int(round(selectedAgeFloat))

        // 確保年齡在範圍內
        guard age >= minAge && age <= maxAge else { return }

        // 如果快取為空，建立快取
        if ageDeathBenefitCache.isEmpty {
            buildAgeDeathBenefitCache()
        }

        // 從快取中取得該年齡的保額
        if let benefit = ageDeathBenefitCache[age] {
            selectedAge = age
            selectedDeathBenefit = benefit
        }
    }

    /// 建立年齡-保額快取（預先計算所有年齡的保額）
    private func buildAgeDeathBenefitCache() {
        guard let client = client else { return }

        let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        do {
            let calculators = try viewContext.fetch(fetchRequest)
            let ageRange = getInsuranceAgeRange()

            // 為每個年齡計算總保額
            for age in ageRange.min...ageRange.max {
                var totalDeathBenefit: Double = 0.0

                for calculator in calculators {
                    if let benefit = getDeathBenefitForInsuranceAge(calculator: calculator, insuranceAge: age) {
                        // 根據幣別轉換
                        let currency = calculator.currency ?? "TWD"
                        let exchangeRate = Double(calculator.exchangeRate ?? "32") ?? 32
                        let convertedAmount = convertCurrency(
                            amount: benefit,
                            fromCurrency: currency,
                            toCurrency: selectedCurrency,
                            exchangeRate: exchangeRate
                        )
                        totalDeathBenefit += convertedAmount
                    }
                }

                ageDeathBenefitCache[age] = totalDeathBenefit
            }
        } catch {
            print("❌ 建立快取失敗：\(error.localizedDescription)")
        }
    }

    /// 顯示選中點的標記和數值
    private func selectedPointOverlay(age: Int, benefit: Double, in size: CGSize) -> some View {
        let ageRange = getInsuranceAgeRange()
        let minAge = ageRange.min
        let maxAge = ageRange.max
        let totalAges = maxAge - minAge + 1

        // 計算點的位置
        let xPosition = CGFloat(age - minAge) / CGFloat(totalAges - 1) * size.width

        // 計算 Y 位置（需要根據數據範圍）
        let points = getInsuranceTrendDataPoints(in: size)
        guard !points.isEmpty else { return AnyView(EmptyView()) }

        // 找到對應年齡的點
        let index = min(age - minAge, points.count - 1)
        let yPosition = index < points.count ? points[index].y : size.height / 2

        return AnyView(
            ZStack {
                // 垂直指示線
                Path { path in
                    path.move(to: CGPoint(x: xPosition, y: 0))
                    path.addLine(to: CGPoint(x: xPosition, y: size.height))
                }
                .stroke(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 0.5)), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

                // 選中點的圓圈
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)), lineWidth: 2)
                    )
                    .position(x: xPosition, y: yPosition)

                // 數值標籤（顯示在點的上方）
                VStack(spacing: 2) {
                    Text("年齡 \(age)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                    Text(formatCurrency(benefit))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 0.95)))
                )
                .position(x: xPosition, y: max(yPosition - 40, 20))
            }
        )
    }

    // MARK: - 保單類型圓餅圖卡片
    private var insurancePieChartCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text(selectedPieChartPage == 0 ? "保單類型分布" : "受益人分配")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<2, id: \.self) { i in
                        Circle()
                            .fill(i == selectedPieChartPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            // TabView 包裹兩頁內容
            TabView(selection: $selectedPieChartPage) {
                // 頁面0: 保單類型分布
                insuranceTypePieChart
                    .tag(0)

                // 頁面1: 受益人分配
                beneficiaryPieChart
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 455)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    Color(UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark
                            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                            : UIColor.white
                    })
                )
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }

    // 圖例項目
    private func legendItem(color: Color, title: String, percentage: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            Spacer()
            Text(percentage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
        }
    }

    // 頁面0: 保險類型分布圓餅圖
    private var insuranceTypePieChart: some View {
        VStack(spacing: 15) {
            // 圓餅圖
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 20)
                    .frame(width: 140, height: 140)

                // 動態繪製各保險類型的圓環
                ForEach(insuranceTypeSlices, id: \.type) { slice in
                    Circle()
                        .trim(from: slice.startAngle, to: slice.endAngle)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: slice.colors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                }

                // 中心文字 - 顯示最大類型
                VStack(spacing: 2) {
                    if let mainType = insuranceTypeStats.max(by: { $0.count < $1.count }) {
                        Text(mainType.percentage)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                        Text(mainType.type)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                    } else {
                        Text("0%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                        Text("無資料")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                    }
                }
            }

            // 圖例 - 顯示實際數據
            VStack(alignment: .leading, spacing: 8) {
                ForEach(insuranceTypeStats, id: \.type) { stat in
                    legendItem(color: stat.color, title: stat.type, percentage: stat.percentage)
                }
            }
        }
    }

    // 頁面1: 受益人分配圓餅圖
    private var beneficiaryPieChart: some View {
        let distribution = getAllBeneficiaryDistribution()

        return VStack(spacing: 15) {
            // 圓餅圖
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 20)
                    .frame(width: 140, height: 140)

                // 動態繪製各受益人的圓環
                ForEach(beneficiarySlices(from: distribution), id: \.name) { slice in
                    Circle()
                        .trim(from: slice.startAngle, to: slice.endAngle)
                        .stroke(
                            slice.color,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                }

                // 中心文字 - 顯示總身故保險金
                VStack(spacing: 2) {
                    if !distribution.isEmpty {
                        let totalAmount = distribution.reduce(0) { $0 + $1.totalAmount }
                        Text(formatCurrency(totalAmount))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        Text("總身故保險金")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                    } else {
                        Text("$0")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        Text("無資料")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                    }
                }
            }

            // 圖例 - 顯示受益人分配
            VStack(alignment: .leading, spacing: 8) {
                ForEach(distribution) { beneficiary in
                    let color = beneficiaryColor(for: beneficiary.name)
                    legendItem(
                        color: color,
                        title: beneficiary.name,
                        percentage: String(format: "%.1f%%", beneficiary.percentage)
                    )
                }
            }
        }
    }

    // MARK: - 保險類型卡片

    // 狀態變數：追蹤每個卡片的當前頁面
    @State private var selectedSavingsPage = 0
    @State private var selectedInvestmentPage = 0
    @State private var selectedProtectionPage = 0
    @State private var selectedPieChartPage = 0  // 保單類型分布頁面

    // 儲蓄險卡片（三頁：已累積保費 / 詳細資訊 / 受益人分配）
    private var savingsInsuranceCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text(selectedSavingsPage == 0 ? "儲蓄險" : selectedSavingsPage == 1 ? "儲蓄險詳情" : "受益人分配")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == selectedSavingsPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            TabView(selection: $selectedSavingsPage) {
                // 頁面0: 已累積保費
                insuranceTypePage0(type: "儲蓄險", icon: "banknote.fill", color: .blue).tag(0)
                // 頁面1: 詳細資訊
                insuranceTypePage1(type: "儲蓄險", color: .blue).tag(1)
                // 頁面2: 受益人分配
                beneficiaryDistributionPage(type: "儲蓄險", color: .blue).tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 70)
        }
        .padding(20)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    Color(UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark
                            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                            : UIColor.white
                    })
                )
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    // 投資型卡片（三頁：已累積保費 / 詳細資訊 / 受益人分配）
    private var investmentInsuranceCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text(selectedInvestmentPage == 0 ? "投資型" : selectedInvestmentPage == 1 ? "投資型詳情" : "受益人分配")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == selectedInvestmentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            TabView(selection: $selectedInvestmentPage) {
                // 頁面0: 已累積保費
                insuranceTypePage0(type: "投資型", icon: "chart.line.uptrend.xyaxis", color: .orange).tag(0)
                // 頁面1: 詳細資訊
                insuranceTypePage1(type: "投資型", color: .orange).tag(1)
                // 頁面2: 受益人分配
                beneficiaryDistributionPage(type: "投資型", color: .orange).tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 70)
        }
        .padding(20)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    Color(UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark
                            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                            : UIColor.white
                    })
                )
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    // 保障型卡片（兩頁：已累積保費 / 其他資訊）
    private var protectionInsuranceCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text(selectedProtectionPage == 0 ? "保障型" : "保障型詳情")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<2, id: \.self) { i in
                        Circle()
                            .fill(i == selectedProtectionPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            TabView(selection: $selectedProtectionPage) {
                // 頁面0: 已累積保費
                insuranceTypePage0(type: "保障型", icon: "shield.fill", color: .green).tag(0)
                // 頁面1: 詳細資訊
                insuranceTypePage1(type: "保障型", color: .green).tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 70)
        }
        .padding(20)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    Color(UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark
                            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                            : UIColor.white
                    })
                )
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    // 月度保費卡片（直方圖）
    private var monthlyPremiumCard: some View {
        monthlyPremiumChartCard
    }

    // 頁面0: 已累積保費顯示
    private func insuranceTypePage0(type: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("已累積保費")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                Text(formatCurrency(getInsuranceTypeAmount(type)))
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
    }

    // 頁面1: 詳細資訊顯示（待您決定要顯示什麼內容）
    private func insuranceTypePage1(type: String, color: Color) -> some View {
        HStack(spacing: 16) {
            // 左側：保單數量
            VStack(alignment: .leading, spacing: 6) {
                Text("保單數量")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                Text("\(getInsuranceTypeCount(type)) 筆")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 右側：平均年繳
            VStack(alignment: .leading, spacing: 6) {
                Text("平均年繳")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                Text(formatCurrency(getInsuranceTypeAverageAnnualPremium(type)))
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // 頁面2: 受益人身故保險金分配
    private func beneficiaryDistributionPage(type: String, color: Color) -> some View {
        let distribution = getBeneficiaryDistribution(for: type)

        return HStack(spacing: 12) {
            if distribution.isEmpty {
                Text("無受益人資料")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                // 顯示前兩位受益人的分配比例
                ForEach(Array(distribution.prefix(2)), id: \.name) { beneficiary in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(beneficiary.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                        Text("\(beneficiary.percentage, specifier: "%.1f")%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(color)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if distribution.count > 2 {
                    Text("+\(distribution.count - 2)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // 取得特定類型的保單數量
    private func getInsuranceTypeCount(_ type: String) -> Int {
        return insuranceTypeStats.first(where: { $0.type == type })?.count ?? 0
    }

    // 取得特定類型的平均年繳保費
    private func getInsuranceTypeAverageAnnualPremium(_ type: String) -> Double {
        let count = getInsuranceTypeCount(type)
        guard count > 0 else { return 0.0 }

        var totalAnnualPremium: Double = 0.0

        for policy in insurancePolicies where policy.policyType == type {
            guard let companyName = policy.insuranceCompany, !companyName.isEmpty,
                  let productName = policy.policyName, !productName.isEmpty,
                  let client = client else {
                continue
            }

            let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "client == %@ AND companyName == %@ AND productName == %@",
                client, companyName, productName
            )
            fetchRequest.fetchLimit = 1

            do {
                if let calculator = try viewContext.fetch(fetchRequest).first,
                   let annualPremiumString = calculator.annualPremium, !annualPremiumString.isEmpty,
                   let annualPremium = Double(annualPremiumString.replacingOccurrences(of: ",", with: "")) {
                    totalAnnualPremium += annualPremium
                }
            } catch {
                print("❌ 取得試算表失敗：\(error.localizedDescription)")
            }
        }

        return totalAnnualPremium / Double(count)
    }

    // 月度保費直方圖卡片（參考債券配息配色）
    private var monthlyPremiumChartCard: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
                    Text("月度保費")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(hoveredPremiumMonth == nil ? "年保費" : "\(hoveredPremiumMonth!)月保費")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                    Text(hoveredPremiumMonth == nil ? formatCurrency(getTotalAnnualPremium()) : formatCurrency(getMonthlyPremium(for: hoveredPremiumMonth!)))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                }
            }

            // 12個月直方圖（根據繳費月份和年繳保費計算）
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(1...12, id: \.self) { month in
                    let monthlyAmount = getMonthlyPremium(for: month)
                    let maxAmount = getMaxMonthlyPremium()
                    let barHeight = maxAmount > 0 ? (monthlyAmount / maxAmount) * 50 : 0

                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(hoveredPremiumMonth == month ? Color(.init(red: 0.35, green: 0.65, blue: 0.48, alpha: 1.0)) : Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
                            .frame(height: max(barHeight, monthlyAmount > 0 ? 10 : 0))
                            .frame(maxWidth: .infinity)

                        Text("\(month)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(hoveredPremiumMonth == month ? .primary : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if hoveredPremiumMonth == month {
                            hoveredPremiumMonth = nil
                        } else {
                            hoveredPremiumMonth = month
                        }
                    }
                }
            }
            .frame(height: 60)
        }
        .padding(20)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.clear)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    // 取得特定保險類型的已累積保費總額
    private func getInsuranceTypeAmount(_ type: String) -> Double {
        return insuranceTypeStats.first(where: { $0.type == type })?.amount ?? 0.0
    }

    // 受益人分配資料結構
    struct BeneficiaryDistribution: Identifiable {
        let id = UUID()
        let name: String
        let totalAmount: Double
        let percentage: Double
    }

    // 計算特定保險類型的受益人身故保險金分配
    private func getBeneficiaryDistribution(for type: String) -> [BeneficiaryDistribution] {
        // 確保 client 存在
        guard let client = client else {
            return []
        }

        // 字典用來累計每個受益人的身故保險金總額
        var beneficiaryTotals: [String: Double] = [:]

        // 從 Core Data 取得所有試算表
        let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        var calculators: [InsuranceCalculator] = []
        do {
            calculators = try viewContext.fetch(fetchRequest)
        } catch {
            print("❌ 取得試算表資料失敗：\(error.localizedDescription)")
            return []
        }

        // 遍歷所有保險試算表，篩選指定類型的保單
        for calculator in calculators {
            // 檢查是否為指定類型（從保險公司或商品名稱判斷）
            let companyName = calculator.companyName ?? ""
            let productName = calculator.productName ?? ""

            // 判斷是否為指定類型（這裡需要根據實際情況調整判斷邏輯）
            var isMatchingType = false
            if type == "儲蓄險" {
                // 儲蓄險的判斷邏輯（可根據公司名或產品名包含關鍵字）
                isMatchingType = companyName.contains("台新") || productName.contains("儲蓄")
            } else if type == "投資型" {
                // 投資型的判斷邏輯
                isMatchingType = companyName.contains("國泰") || productName.contains("投資") || productName.contains("123")
            }

            guard isMatchingType else { continue }

            // 取得身故保險金
            guard let deathBenefit = getCurrentDeathBenefitForCalculator(calculator: calculator, client: client), deathBenefit > 0 else {
                continue
            }

            // 解析受益人字串（格式：Owen50%，JACK50%）
            if let beneficiaryString = calculator.beneficiary, !beneficiaryString.isEmpty {
                let beneficiaries = beneficiaryString.components(separatedBy: CharacterSet(charactersIn: "，,"))

                for beneficiary in beneficiaries {
                    let trimmed = beneficiary.trimmingCharacters(in: .whitespaces)
                    // 提取受益人姓名和比例
                    if let percentIndex = trimmed.firstIndex(where: { $0.isNumber }) {
                        let name = String(trimmed[..<percentIndex])
                        let percentString = String(trimmed[percentIndex...]).replacingOccurrences(of: "%", with: "")

                        if let percent = Double(percentString), percent > 0 {
                            let beneficiaryAmount = deathBenefit * (percent / 100.0)
                            beneficiaryTotals[name, default: 0.0] += beneficiaryAmount
                        }
                    }
                }
            }
        }

        // 將字典轉換為陣列，並計算每個受益人的百分比
        var distributions: [BeneficiaryDistribution] = []
        let grandTotal = beneficiaryTotals.values.reduce(0, +)

        for (name, amount) in beneficiaryTotals {
            let percentage = grandTotal > 0 ? (amount / grandTotal) * 100.0 : 0.0
            distributions.append(BeneficiaryDistribution(
                name: name,
                totalAmount: amount,
                percentage: percentage
            ))
        }

        // 按金額從大到小排序
        return distributions.sorted { $0.totalAmount > $1.totalAmount }
    }

    // 計算所有保險類型的受益人身故保險金分配（不分類型）
    private func getAllBeneficiaryDistribution() -> [BeneficiaryDistribution] {
        // 確保 client 存在
        guard let client = client else {
            return []
        }

        // 字典用來累計每個受益人的身故保險金總額
        var beneficiaryTotals: [String: Double] = [:]

        // 從 Core Data 取得所有試算表
        let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        var calculators: [InsuranceCalculator] = []
        do {
            calculators = try viewContext.fetch(fetchRequest)
        } catch {
            print("❌ 取得試算表資料失敗：\(error.localizedDescription)")
            return []
        }

        // 遍歷所有保險試算表
        for calculator in calculators {
            // 取得身故保險金
            guard let deathBenefit = getCurrentDeathBenefitForCalculator(calculator: calculator, client: client), deathBenefit > 0 else {
                continue
            }

            // 解析受益人字串（格式：Owen50%，JACK50%）
            if let beneficiaryString = calculator.beneficiary, !beneficiaryString.isEmpty {
                let beneficiaries = beneficiaryString.components(separatedBy: CharacterSet(charactersIn: "，,"))

                for beneficiary in beneficiaries {
                    let trimmed = beneficiary.trimmingCharacters(in: .whitespaces)
                    // 提取受益人姓名和比例
                    if let percentIndex = trimmed.firstIndex(where: { $0.isNumber }) {
                        let name = String(trimmed[..<percentIndex])
                        let percentString = String(trimmed[percentIndex...]).replacingOccurrences(of: "%", with: "")

                        if let percent = Double(percentString), percent > 0 {
                            let beneficiaryAmount = deathBenefit * (percent / 100.0)
                            beneficiaryTotals[name, default: 0.0] += beneficiaryAmount
                        }
                    }
                }
            }
        }

        // 將字典轉換為陣列，並計算每個受益人的百分比
        var distributions: [BeneficiaryDistribution] = []
        let grandTotal = beneficiaryTotals.values.reduce(0, +)

        for (name, amount) in beneficiaryTotals {
            let percentage = grandTotal > 0 ? (amount / grandTotal) * 100.0 : 0.0
            distributions.append(BeneficiaryDistribution(
                name: name,
                totalAmount: amount,
                percentage: percentage
            ))
        }

        // 按金額從大到小排序
        return distributions.sorted { $0.totalAmount > $1.totalAmount }
    }

    // 受益人圓餅圖切片資料結構
    struct BeneficiarySlice: Identifiable {
        let id = UUID()
        let name: String
        let startAngle: CGFloat
        let endAngle: CGFloat
        let color: Color
    }

    // 將受益人分配轉換為圓餅圖切片
    private func beneficiarySlices(from distribution: [BeneficiaryDistribution]) -> [BeneficiarySlice] {
        var slices: [BeneficiarySlice] = []
        var currentAngle: CGFloat = 0.0

        for beneficiary in distribution {
            let angle = CGFloat(beneficiary.percentage / 100.0)
            let slice = BeneficiarySlice(
                name: beneficiary.name,
                startAngle: currentAngle,
                endAngle: currentAngle + angle,
                color: beneficiaryColor(for: beneficiary.name)
            )
            slices.append(slice)
            currentAngle += angle
        }

        return slices
    }

    // 根據受益人姓名返回顏色
    private func beneficiaryColor(for name: String) -> Color {
        // 使用姓名的 hash 值來生成一致的顏色
        let colors: [Color] = [
            Color(.init(red: 0.4, green: 0.6, blue: 0.95, alpha: 1.0)),  // 藍色
            Color(.init(red: 0.95, green: 0.6, blue: 0.4, alpha: 1.0)),  // 橘色
            Color(.init(red: 0.5, green: 0.8, blue: 0.5, alpha: 1.0)),   // 綠色
            Color(.init(red: 0.95, green: 0.7, blue: 0.4, alpha: 1.0)),  // 黃色
            Color(.init(red: 0.8, green: 0.5, blue: 0.8, alpha: 1.0)),   // 紫色
            Color(.init(red: 0.95, green: 0.5, blue: 0.6, alpha: 1.0)),  // 粉色
        ]

        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    // 原有的通用卡片函數（保留以備不時之需）
    private func insuranceTypeCard(title: String, amount: Double, icon: String) -> some View {
        HStack(spacing: 12) {
            // 圖標
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
            }

            // 資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                Text(formatCurrency(amount))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
            }

            Spacer()

            // 走勢圖佔位
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
                .frame(width: 80, height: 40)
                .overlay(
                    Text("走勢")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                )
        }
        .padding(20)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    Color(UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark
                            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                            : UIColor.white
                    })
                )
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - 保險明細表格
    private var insurancePolicyList: some View {
        VStack(spacing: 0) {
            // 標題區域（含縮放功能）
            insuranceTableHeader

            // 表格內容（可縮放）
            if isExpanded {
                insuranceTable
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // 標題區域（含縮放功能）
    private var insuranceTableHeader: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 14))
                    Text("保險明細")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                Spacer()

                HStack(spacing: 8) {
                    // 縮放按鈕
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        showingColumnReorder = true
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        if !subscriptionManager.canAccessPremiumFeatures() {
                            showingSubscription = true
                        } else {
                            showingPhotoOptions = true
                        }
                    }) {
                        Image(systemName: "camera")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        deleteLastPolicy()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }

                    // 綠色 + 按鈕：直接新增一行空白資料
                    Button(action: {
                        if !subscriptionManager.canAccessPremiumFeatures() {
                            showingSubscription = true
                        } else {
                            addNewPolicy()
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if isExpanded {
                Divider()
            }
        }
    }

    // 表格本體
    private var insuranceTable: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                // 表頭
                insuranceTableHeaderRow

                // 分隔線
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)

                // 資料行容器
                VStack(spacing: 0) {
                    if insurancePolicies.isEmpty {
                        // 空狀態提示
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("尚無保單資料")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            Text("點擊上方 📷 或 ➕ 按鈕新增保單")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                    } else {
                        // 使用排序後的保單列表
                        ForEach(Array(sortedPolicies.enumerated()), id: \.offset) { index, policy in
                            insuranceTableRow(policy: policy, index: index)
                        }
                    }
                }
            }
        }
    }

    // 表頭行
    private var insuranceTableHeaderRow: some View {
        HStack(spacing: 0) {
            // 刪除按鈕欄位表頭
            Text("")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                .frame(width: 40, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)

            ForEach(currentColumnOrder, id: \.self) { header in
                if header == "保單始期" {
                    // 保單始期欄位：可點擊排序
                    Button(action: {
                        toggleStartDateSort()
                    }) {
                        HStack(spacing: 4) {
                            Text(header)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                            Image(systemName: sortByStartDateAscending ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .frame(width: getColumnWidth(for: header), alignment: getColumnAlignment(for: header))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // 其他欄位：不可排序
                    Text(header)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                        .frame(width: getColumnWidth(for: header), alignment: getColumnAlignment(for: header))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
            }

            // 存放試算表按鈕欄位（固定在最右邊）
            Text("存放試算表")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                .frame(width: 110, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
        }
        .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))
    }

    // 表格行（支援直接編輯）
    private func insuranceTableRow(policy: InsurancePolicy, index: Int) -> some View {
        HStack(spacing: 0) {
            // 刪除按鈕（最左邊）
            Button(action: {
                policyToDelete = policy
                showingDeleteConfirmation = true
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            }
            .frame(width: 40, alignment: .center)
            .padding(.horizontal, 8)

            // 資料列（可直接編輯）
            ForEach(currentColumnOrder, id: \.self) { header in
                TextField("", text: bindingForPolicy(policy, header: header), onEditingChanged: { isEditing in
                    // 追蹤編輯狀態，避免排序時列表跳動
                    isEditingField = isEditing
                })
                    .font(.system(size: 14))
                    .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                    .textFieldStyle(PlainTextFieldStyle())
                    .multilineTextAlignment(getTextAlignment(for: header))
                    .frame(width: getColumnWidth(for: header), alignment: getColumnAlignment(for: header))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .background(Color.clear)
            }

            // 存放試算表按鈕（固定在最右邊）
            Button(action: {
                quickUploadCalculator(for: policy)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 12))
                    Text("存放")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green)
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 110, alignment: .center)
            .padding(.horizontal, 8)
        }
        .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.02))
        .overlay(
            VStack {
                Spacer()
                Divider()
                    .opacity(0.3)
            }
        )
    }

    // 取得儲存格數值
    private func getCellValue(for header: String, policy: InsurancePolicy) -> String {
        switch header {
        case "保險種類": return (policy.policyType ?? "").isEmpty ? "-" : (policy.policyType ?? "-")
        case "保險公司": return (policy.insuranceCompany ?? "").isEmpty ? "-" : (policy.insuranceCompany ?? "-")
        case "保單號碼": return (policy.policyNumber ?? "").isEmpty ? "-" : (policy.policyNumber ?? "-")
        case "保險名稱": return (policy.policyName ?? "").isEmpty ? "-" : (policy.policyName ?? "-")
        case "要保人": return (policy.policyHolder ?? "").isEmpty ? "-" : (policy.policyHolder ?? "-")
        case "被保險人": return (policy.insuredPerson ?? "").isEmpty ? "-" : (policy.insuredPerson ?? "-")
        case "保單始期": return (policy.startDate ?? "").isEmpty ? "-" : (policy.startDate ?? "-")
        case "繳費月份": return (policy.paymentMonth ?? "").isEmpty ? "-" : (policy.paymentMonth ?? "-")
        case "保額":
            if let amount = policy.coverageAmount, !amount.isEmpty {
                return "$" + formatNumber(amount)
            } else {
                return "$0"
            }
        case "年繳保費":
            if let premium = policy.annualPremium, !premium.isEmpty {
                return "$" + formatNumber(premium)
            } else {
                return "$0"
            }
        case "繳費年期": return (policy.paymentPeriod ?? "").isEmpty ? "-" : (policy.paymentPeriod ?? "-")
        case "利率": return (policy.interestRate ?? "").isEmpty ? "-" : (policy.interestRate ?? "-")
        case "受益人": return (policy.beneficiary ?? "").isEmpty ? "-" : (policy.beneficiary ?? "-")
        case "幣別": return (policy.currency ?? "").isEmpty ? "-" : (policy.currency ?? "-")
        case "匯率": return (policy.exchangeRate ?? "").isEmpty ? "-" : (policy.exchangeRate ?? "-")
        case "折合台幣":
            // 如果幣別是台幣，直接使用年繳保費
            let currency = (policy.currency ?? "").uppercased()
            if currency == "TWD" || currency == "台幣" || currency == "NT" || currency == "NTD" {
                if let premium = policy.annualPremium, !premium.isEmpty {
                    return "$" + formatNumber(premium)
                } else {
                    return "$0"
                }
            }
            // 其他幣別：計算折合台幣：年繳保費 × 匯率
            if let premium = policy.annualPremium, !premium.isEmpty,
               let rate = policy.exchangeRate, !rate.isEmpty,
               let premiumValue = Double(premium),
               let rateValue = Double(rate) {
                let twdAmount = premiumValue * rateValue
                return "$" + formatNumber(String(format: "%.0f", twdAmount))
            } else if let twdAmount = policy.twdAmount, !twdAmount.isEmpty {
                return "$" + formatNumber(twdAmount)
            } else {
                return "$0"
            }
        default: return ""
        }
    }

    // 格式化數字（加上千分位）
    private func formatNumber(_ value: String) -> String {
        guard let number = Double(value) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    // 取得欄位寬度
    private func getColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "保險種類": return 120
        case "保險公司": return 120
        case "保單號碼": return 150
        case "保險名稱": return 150
        case "要保人": return 120
        case "被保險人": return 120
        case "保單始期": return 120
        case "繳費月份": return 100
        case "保額": return 120
        case "年繳保費": return 120
        case "繳費年期": return 100
        case "利率": return 100
        case "受益人": return 200  // 增加寬度以顯示完整文字
        case "幣別": return 80
        case "匯率": return 80
        case "折合台幣": return 120
        default: return 120
        }
    }

    // 取得欄位對齊方式
    private func getColumnAlignment(for header: String) -> Alignment {
        // 全部靠左對齊（參考月度資料明細）
        return .leading
    }

    // 取得文字對齊方式（用於 TextField）
    private func getTextAlignment(for header: String) -> TextAlignment {
        // 全部靠左對齊（參考月度資料明細）
        return .leading
    }

    // MARK: - 雙向綁定函數

    /// 為保單欄位建立雙向綁定，支援自動儲存到 Core Data
    private func bindingForPolicy(_ policy: InsurancePolicy, header: String) -> Binding<String> {
        Binding<String>(
            get: {
                // 取得欄位值並格式化
                let rawValue: String
                switch header {
                case "保險種類":
                    rawValue = policy.policyType ?? ""
                case "保險公司":
                    rawValue = policy.insuranceCompany ?? ""
                case "保單號碼":
                    rawValue = policy.policyNumber ?? ""
                case "保險名稱":
                    rawValue = policy.policyName ?? ""
                case "要保人":
                    rawValue = policy.policyHolder ?? ""
                case "被保險人":
                    rawValue = policy.insuredPerson ?? ""
                case "保單始期":
                    rawValue = policy.startDate ?? ""
                case "繳費月份":
                    rawValue = policy.paymentMonth ?? ""
                case "保額":
                    rawValue = policy.coverageAmount ?? ""
                case "年繳保費":
                    rawValue = policy.annualPremium ?? ""
                case "繳費年期":
                    rawValue = policy.paymentPeriod ?? ""
                case "利率":
                    rawValue = policy.interestRate ?? ""
                case "受益人":
                    rawValue = policy.beneficiary ?? ""
                case "幣別":
                    rawValue = policy.currency ?? ""
                case "匯率":
                    rawValue = policy.exchangeRate ?? ""
                case "折合台幣":
                    // 如果幣別是台幣，直接使用年繳保費
                    let currency = (policy.currency ?? "").uppercased()
                    if currency == "TWD" || currency == "台幣" || currency == "NT" || currency == "NTD" {
                        rawValue = policy.annualPremium ?? ""
                    } else {
                        // 顯示計算後的折合台幣值（不可編輯）
                        if let premium = policy.annualPremium, !premium.isEmpty,
                           let rate = policy.exchangeRate, !rate.isEmpty,
                           let premiumValue = Double(premium),
                           let rateValue = Double(rate) {
                            let twdAmount = premiumValue * rateValue
                            rawValue = String(format: "%.0f", twdAmount)
                        } else {
                            rawValue = policy.twdAmount ?? ""
                        }
                    }
                default:
                    rawValue = ""
                }

                // 數字欄位加上千分位
                if isNumberField(header) && !rawValue.isEmpty {
                    return formatNumberWithCommas(rawValue)
                }
                return rawValue
            },
            set: { newValue in
                // 更新 Core Data 實體
                let cleanValue = isNumberField(header) ? removeCommas(newValue) : newValue

                switch header {
                case "保險種類":
                    policy.policyType = cleanValue
                case "保險公司":
                    policy.insuranceCompany = cleanValue
                case "保單號碼":
                    policy.policyNumber = cleanValue
                case "保險名稱":
                    policy.policyName = cleanValue
                case "要保人":
                    policy.policyHolder = cleanValue
                case "被保險人":
                    policy.insuredPerson = cleanValue
                case "保單始期":
                    policy.startDate = cleanValue
                    // 自動從保單始期提取月份到繳費月份
                    extractPaymentMonthFromDate(cleanValue, for: policy)
                case "繳費月份":
                    policy.paymentMonth = cleanValue
                case "保額":
                    policy.coverageAmount = cleanValue
                case "年繳保費":
                    policy.annualPremium = cleanValue
                case "繳費年期":
                    policy.paymentPeriod = cleanValue
                case "利率":
                    policy.interestRate = cleanValue
                case "受益人":
                    policy.beneficiary = cleanValue
                case "幣別":
                    policy.currency = cleanValue
                case "匯率":
                    policy.exchangeRate = cleanValue
                    // 當匯率更新時，重新計算折合台幣（但台幣不需要）
                    let currency = (policy.currency ?? "").uppercased()
                    if !(currency == "TWD" || currency == "台幣" || currency == "NT" || currency == "NTD") {
                        if let premium = policy.annualPremium, !premium.isEmpty,
                           let premiumValue = Double(premium),
                           let rateValue = Double(cleanValue) {
                            let twdAmount = premiumValue * rateValue
                            policy.twdAmount = String(format: "%.0f", twdAmount)
                        }
                    }
                case "折合台幣":
                    // 折合台幣欄位為計算欄位，但也允許手動編輯
                    policy.twdAmount = cleanValue
                default:
                    break
                }

                // 自動儲存變更到 Core Data
                do {
                    try viewContext.save()
                    PersistenceController.shared.save()
                    print("✅ 已自動儲存變更：\(header) = \(cleanValue)")

                    // 同步更新試算表資料（如果此保單已存放到試算表）
                    syncToCalculator(for: policy)
                } catch {
                    print("❌ 儲存失敗：\(error.localizedDescription)")
                }
            }
        )
    }

    // 判斷是否為數字欄位
    private func isNumberField(_ header: String) -> Bool {
        return header == "保額" || header == "年繳保費" || header == "匯率" || header == "折合台幣"
    }

    // 格式化數字（加上千分位）
    private func formatNumberWithCommas(_ value: String) -> String {
        // 移除現有的逗號
        let cleanValue = value.replacingOccurrences(of: ",", with: "")
        guard let number = Double(cleanValue) else { return value }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    // 移除千分位逗號
    private func removeCommas(_ value: String) -> String {
        return value.replacingOccurrences(of: ",", with: "")
    }

    // 從保單始期提取月份
    private func extractPaymentMonthFromDate(_ dateString: String, for policy: InsurancePolicy) {
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

                    // 儲存變更
                    do {
                        try viewContext.save()
                        PersistenceController.shared.save()
                    } catch {
                        print("❌ 儲存繳費月份失敗：\(error.localizedDescription)")
                    }
                    return
                }
            }
        }

        print("⚠️ 無法從保單始期提取月份：\(dateString)")
    }

    // MARK: - 欄位定義
    private let insurancePolicyHeaders = [
        "保險種類", "保險公司", "保單號碼", "保險名稱", "要保人", "被保險人",
        "保單始期", "繳費月份", "保額", "年繳保費", "繳費年期",
        "利率", "受益人", "幣別", "匯率", "折合台幣"
    ]

    // 當前欄位順序
    private var currentColumnOrder: [String] {
        return columnOrder.isEmpty ? insurancePolicyHeaders : columnOrder
    }

    // MARK: - 排序功能

    /// 切換保單始期的排序方向
    private func toggleStartDateSort() {
        withAnimation {
            sortByStartDateAscending.toggle()
        }
        print("📊 切換保單始期排序：\(sortByStartDateAscending ? "升序" : "降序")")
    }

    /// 取得排序後的保單列表
    private var sortedPolicies: [InsurancePolicy] {
        let policies = Array(insurancePolicies)

        // 如果正在編輯，則不進行排序，保持原始順序避免跳動
        if isEditingField {
            return policies
        }

        // 按照保單始期排序
        return policies.sorted { policy1, policy2 in
            let date1 = policy1.startDate ?? ""
            let date2 = policy2.startDate ?? ""

            // 空值處理：空值排在最後
            if date1.isEmpty && date2.isEmpty {
                return false
            } else if date1.isEmpty {
                return false  // 空值排在後面
            } else if date2.isEmpty {
                return true   // 非空值排在前面
            }

            // 比較日期字串（支援多種格式）
            if sortByStartDateAscending {
                return compareDateStrings(date1, date2) == .orderedAscending
            } else {
                return compareDateStrings(date1, date2) == .orderedDescending
            }
        }
    }

    /// 比較兩個日期字串（支援多種格式：2024/01/01、2024-01-01、2024年1月1日）
    private func compareDateStrings(_ date1: String, _ date2: String) -> ComparisonResult {
        let parsedDate1 = parseDate(date1)
        let parsedDate2 = parseDate(date2)

        if let d1 = parsedDate1, let d2 = parsedDate2 {
            return d1.compare(d2)
        } else if parsedDate1 != nil {
            return .orderedAscending  // 有效日期排在無效日期前
        } else if parsedDate2 != nil {
            return .orderedDescending // 無效日期排在有效日期後
        } else {
            return date1.compare(date2)  // 都無效時按字串比較
        }
    }

    /// 解析日期字串為 Date 物件
    private func parseDate(_ dateString: String) -> Date? {
        let dateFormatters: [DateFormatter] = {
            let formats = ["yyyy/MM/dd", "yyyy-MM-dd", "yyyy年M月d日", "yyyy/M/d", "yyyy-M-d"]
            return formats.map { format in
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "zh_TW")
                return formatter
            }
        }()

        for formatter in dateFormatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    // MARK: - 計算函數

    // 保險類型統計資料結構
    struct InsuranceTypeStat: Identifiable {
        let id = UUID()
        let type: String
        let count: Int
        let amount: Double  // 已累積保費金額
        let percentage: String
        let color: Color
    }

    // 派餅圖切片資料結構
    struct PieSlice: Identifiable {
        let id = UUID()
        let type: String
        let startAngle: Double
        let endAngle: Double
        let colors: [Color]
    }

    // 保險類型顏色映射
    private func colorForInsuranceType(_ type: String) -> Color {
        switch type {
        case "壽險":
            return Color(.init(red: 0.9, green: 0.25, blue: 0.25, alpha: 1.0))
        case "醫療險":
            return Color(.init(red: 0.25, green: 0.45, blue: 0.9, alpha: 1.0))
        case "意外險":
            return Color(.init(red: 0.25, green: 0.8, blue: 0.25, alpha: 1.0))
        case "投資型":
            return Color(.init(red: 1.0, green: 0.7, blue: 0.15, alpha: 1.0))
        default:
            return Color.gray
        }
    }

    // 保險類型圖標映射
    private func iconForInsuranceType(_ type: String) -> String {
        switch type {
        case "壽險":
            return "heart.fill"
        case "醫療險":
            return "cross.case.fill"
        case "意外險":
            return "exclamationmark.shield.fill"
        case "投資型":
            return "chart.line.uptrend.xyaxis"
        default:
            return "doc.fill"
        }
    }

    // 保險類型漸變色映射
    private func gradientColorsForInsuranceType(_ type: String) -> [Color] {
        switch type {
        case "壽險":
            return [
                Color(.init(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)),
                Color(.init(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0))
            ]
        case "醫療險":
            return [
                Color(.init(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)),
                Color(.init(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0))
            ]
        case "意外險":
            return [
                Color(.init(red: 0.25, green: 0.8, blue: 0.25, alpha: 1.0)),
                Color(.init(red: 0.3, green: 0.9, blue: 0.3, alpha: 1.0))
            ]
        case "投資型":
            return [
                Color(.init(red: 1.0, green: 0.65, blue: 0.1, alpha: 1.0)),
                Color(.init(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0))
            ]
        default:
            return [Color.gray, Color.gray.opacity(0.7)]
        }
    }

    // 計算保險類型統計（基於已累積保費）
    private var insuranceTypeStats: [InsuranceTypeStat] {
        // 統計各類型的保單數量和已累積保費
        var typeData: [String: (count: Int, amount: Double)] = [:]

        for policy in insurancePolicies {
            let type = policy.policyType ?? "其他"
            guard !type.isEmpty else { continue }

            // 取得該保單的已累積保費
            let accumulatedPremium = getAccumulatedPremiumForPolicy(policy)

            // 累加數量和金額
            let current = typeData[type, default: (count: 0, amount: 0.0)]
            typeData[type] = (count: current.count + 1, amount: current.amount + accumulatedPremium)
        }

        // 計算總金額
        let totalAmount = typeData.values.reduce(0.0) { $0 + $1.amount }

        // 如果沒有保單或總金額為0,返回空陣列
        guard totalAmount > 0 else {
            return []
        }

        // 轉換為統計資料結構並排序（按金額降序）
        return typeData.map { type, data in
            let percentage = (data.amount / totalAmount) * 100.0
            return InsuranceTypeStat(
                type: type,
                count: data.count,
                amount: data.amount,
                percentage: String(format: "%.0f%%", percentage),
                color: colorForInsuranceType(type)
            )
        }.sorted { $0.amount > $1.amount } // 按已累積保費金額降序排列
    }

    // 計算單一保單的已累積保費
    private func getAccumulatedPremiumForPolicy(_ policy: InsurancePolicy) -> Double {
        // 檢查保險公司和保險名稱是否存在
        guard let companyName = policy.insuranceCompany, !companyName.isEmpty,
              let productName = policy.policyName, !productName.isEmpty,
              let client = client else {
            return 0.0
        }

        // 查找對應的試算表記錄
        let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "client == %@ AND companyName == %@ AND productName == %@",
            client, companyName, productName
        )
        fetchRequest.fetchLimit = 1

        do {
            if let calculator = try viewContext.fetch(fetchRequest).first {
                // 計算已累積保費
                return calculateAccumulatedPremium(for: calculator)
            }
        } catch {
            print("❌ 取得試算表失敗：\(error.localizedDescription)")
        }

        return 0.0
    }

    // 計算已累積保費（與 InsuranceCalculatorView 中的邏輯相同）
    private func calculateAccumulatedPremium(for calculator: InsuranceCalculator) -> Double {
        // 1. 檢查保險始期和年繳保費是否存在
        guard let startDateString = calculator.startDate, !startDateString.isEmpty,
              let annualPremiumString = calculator.annualPremium, !annualPremiumString.isEmpty,
              let annualPremium = Double(annualPremiumString.replacingOccurrences(of: ",", with: "")) else {
            return 0.0
        }

        // 2. 解析保險始期日期
        guard let policyStartDate = parseDate(startDateString) else {
            return 0.0
        }

        // 3. 計算從保險始期到現在已經過了幾年
        let calendar = Calendar.current
        let now = Date()
        let yearComponents = calendar.dateComponents([.year], from: policyStartDate, to: now)
        guard let years = yearComponents.year else {
            return 0.0
        }

        // 4. 計算已繳年數
        let paidYears = max(0, years)

        // 5. 檢查是否超過繳費年期
        var finalPaidYears = paidYears
        if let paymentPeriodString = calculator.paymentPeriod, !paymentPeriodString.isEmpty {
            if let paymentPeriod = Int(paymentPeriodString.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) {
                finalPaidYears = min(paidYears, paymentPeriod)
            }
        }

        // 6. 計算累積保費
        return Double(finalPaidYears) * annualPremium
    }

    // 計算派餅圖切片（基於已累積保費金額）
    private var insuranceTypeSlices: [PieSlice] {
        let stats = insuranceTypeStats
        guard !stats.isEmpty else { return [] }

        // 使用已累積保費金額計算比例
        let totalAmount = stats.reduce(0.0) { $0 + $1.amount }
        var currentAngle: Double = 0.0

        return stats.map { stat in
            let proportion = stat.amount / totalAmount
            let startAngle = currentAngle
            let endAngle = currentAngle + proportion
            currentAngle = endAngle

            return PieSlice(
                type: stat.type,
                startAngle: startAngle,
                endAngle: endAngle,
                colors: gradientColorsForInsuranceType(stat.type)
            )
        }
    }

    private func getTotalInsuranceValue() -> Double {
        // 計算所有保單的保額總和
        return insurancePolicies.reduce(0.0) { total, policy in
            let amount = Double(policy.coverageAmount ?? "0") ?? 0.0
            return total + amount
        }
    }

    private func getPolicyCount() -> Int {
        return insurancePolicies.count
    }

    private func getMonthlyPremium() -> Double {
        // 計算月繳總額 (年繳 ÷ 12)
        let annualTotal = getAnnualPremium()
        return annualTotal / 12.0
    }

    private func getAnnualPremium() -> Double {
        // 計算所有保單的年繳保費總和
        return insurancePolicies.reduce(0.0) { total, policy in
            let premium = Double(policy.annualPremium ?? "0") ?? 0.0
            return total + premium
        }
    }

    private func getTotalCoverage() -> Double {
        // 計算所有已存放到試算表的保單的當前身故保險金總和
        guard let client = client else {
            return 0.0
        }

        // 取得客戶的所有試算表
        let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)

        do {
            let calculators = try viewContext.fetch(fetchRequest)
            var totalDeathBenefit = 0.0

            // 計算每個試算表的當前身故保險金
            for calculator in calculators {
                if let deathBenefit = getCurrentDeathBenefitForCalculator(calculator: calculator, client: client) {
                    // 根據選擇的幣別進行轉換
                    let convertedAmount = convertCurrency(
                        amount: deathBenefit,
                        fromCurrency: calculator.currency ?? "TWD",
                        toCurrency: selectedCurrency,
                        exchangeRate: Double(calculator.exchangeRate ?? "32") ?? 32
                    )

                    totalDeathBenefit += convertedAmount
                    print("📊 \(calculator.companyName ?? "") - \(calculator.productName ?? ""): \(calculator.currency ?? "TWD") $\(deathBenefit) -> \(selectedCurrency) $\(convertedAmount)")
                }
            }

            print("✅ 保障額度總和 (\(selectedCurrency))：$\(totalDeathBenefit)")
            return totalDeathBenefit
        } catch {
            print("❌ 計算保障額度失敗：\(error.localizedDescription)")
            return 0.0
        }
    }

    /// 取得指定試算表的當前身故保險金
    private func getCurrentDeathBenefitForCalculator(calculator: InsuranceCalculator, client: Client) -> Double? {
        // 1. 取得客戶當前年齡
        guard let birthDate = client.birthDate else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        guard let currentAge = ageComponents.year else {
            return nil
        }

        // 2. 計算保單第一年的保險年齡
        guard let startDate = calculator.startDate, !startDate.isEmpty else {
            return nil
        }

        guard let policyStartDate = parseDate(startDate) else {
            return nil
        }

        let policyStartAgeComponents = calendar.dateComponents([.year], from: birthDate, to: policyStartDate)
        guard let policyStartAge = policyStartAgeComponents.year else {
            return nil
        }

        // 3. 計算當前是保單第幾年
        let policyYear = currentAge - policyStartAge + 1

        // 4. 從試算表資料中找到對應保單年度的身故保險金
        let fetchRequest: NSFetchRequest<InsuranceCalculatorRow> = InsuranceCalculatorRow.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "calculator == %@ AND policyYear == %@", calculator, "\(policyYear)")
        fetchRequest.fetchLimit = 1

        do {
            if let row = try viewContext.fetch(fetchRequest).first,
               let deathBenefitString = row.deathBenefit,
               !deathBenefitString.isEmpty,
               let deathBenefit = Double(deathBenefitString.replacingOccurrences(of: ",", with: "")) {
                return deathBenefit
            }
        } catch {
            print("❌ 取得身故保險金失敗：\(error.localizedDescription)")
        }

        return nil
    }

    /// 幣別轉換函數
    private func convertCurrency(amount: Double, fromCurrency: String, toCurrency: String, exchangeRate: Double) -> Double {
        let fromCurrencyNormalized = fromCurrency.uppercased()
        let toCurrencyNormalized = toCurrency

        // 判斷來源幣別是否為台幣
        let isFromTWD = fromCurrencyNormalized == "TWD" || fromCurrencyNormalized == "台幣" || fromCurrencyNormalized == "NT" || fromCurrencyNormalized == "NTD"

        // 判斷目標幣別是否為台幣
        let isToTWD = toCurrencyNormalized == "台幣"

        if isFromTWD && isToTWD {
            // 台幣 -> 台幣：不轉換
            return amount
        } else if isFromTWD && toCurrencyNormalized == "美金" {
            // 台幣 -> 美金：除以匯率
            return amount / exchangeRate
        } else if !isFromTWD && toCurrencyNormalized == "台幣" {
            // 美金 -> 台幣：乘以匯率
            return amount * exchangeRate
        } else {
            // 美金 -> 美金：不轉換
            return amount
        }
    }

    // 計算年保費總額（支援幣別轉換）
    private func getTotalAnnualPremium() -> Double {
        var totalAnnualPremium: Double = 0.0

        // 遍歷所有保單,累加年繳保費
        for policy in insurancePolicies {
            // 查找對應的試算表記錄
            guard let companyName = policy.insuranceCompany, !companyName.isEmpty,
                  let productName = policy.policyName, !productName.isEmpty,
                  let client = client else {
                continue
            }

            let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "client == %@ AND companyName == %@ AND productName == %@",
                client, companyName, productName
            )
            fetchRequest.fetchLimit = 1

            do {
                if let calculator = try viewContext.fetch(fetchRequest).first,
                   let annualPremiumString = calculator.annualPremium, !annualPremiumString.isEmpty,
                   let annualPremium = Double(annualPremiumString.replacingOccurrences(of: ",", with: "")) {

                    // 根據試算表幣別和匯率進行轉換
                    let currency = calculator.currency ?? "TWD"
                    let exchangeRate = Double(calculator.exchangeRate ?? "32") ?? 32
                    let convertedAmount = convertCurrency(
                        amount: annualPremium,
                        fromCurrency: currency,
                        toCurrency: selectedCurrency,
                        exchangeRate: exchangeRate
                    )

                    totalAnnualPremium += convertedAmount
                }
            } catch {
                print("❌ 取得試算表失敗：\(error.localizedDescription)")
            }
        }

        return totalAnnualPremium
    }

    // 計算指定月份的保費總額（根據繳費月份和年繳保費）
    private func getMonthlyPremium(for month: Int) -> Double {
        var monthlyTotal: Double = 0.0

        for policy in insurancePolicies {
            // 取得保單的繳費月份
            guard let paymentMonthString = policy.paymentMonth, !paymentMonthString.isEmpty else {
                continue
            }

            // 解析繳費月份（可能是 "1", "01", "1月" 等格式）
            let cleanedMonth = paymentMonthString.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            guard let paymentMonth = Int(cleanedMonth), paymentMonth == month else {
                continue
            }

            // 查找對應的試算表記錄取得年繳保費
            guard let companyName = policy.insuranceCompany, !companyName.isEmpty,
                  let productName = policy.policyName, !productName.isEmpty,
                  let client = client else {
                continue
            }

            let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "client == %@ AND companyName == %@ AND productName == %@",
                client, companyName, productName
            )
            fetchRequest.fetchLimit = 1

            do {
                if let calculator = try viewContext.fetch(fetchRequest).first,
                   let annualPremiumString = calculator.annualPremium, !annualPremiumString.isEmpty,
                   let annualPremium = Double(annualPremiumString.replacingOccurrences(of: ",", with: "")) {
                    monthlyTotal += annualPremium
                }
            } catch {
                print("❌ 取得試算表失敗：\(error.localizedDescription)")
            }
        }

        return monthlyTotal
    }

    // 取得所有月份中的最大保費金額（用於計算直方圖高度比例）
    private func getMaxMonthlyPremium() -> Double {
        var maxAmount: Double = 0.0

        for month in 1...12 {
            let amount = getMonthlyPremium(for: month)
            if amount > maxAmount {
                maxAmount = amount
            }
        }

        return maxAmount
    }

    // 取得所有保單的已累積保費總和（支援幣別轉換）
    private func getTotalAccumulatedPremium() -> Double {
        var total: Double = 0.0

        for policy in insurancePolicies {
            let accumulatedPremium = getAccumulatedPremiumForPolicy(policy)

            // 根據保單幣別和匯率進行轉換
            let currency = policy.currency ?? "TWD"
            let exchangeRate = Double(policy.exchangeRate ?? "32") ?? 32
            let convertedAmount = convertCurrency(
                amount: accumulatedPremium,
                fromCurrency: currency,
                toCurrency: selectedCurrency,
                exchangeRate: exchangeRate
            )

            total += convertedAmount
        }

        return total
    }

    // 取得下次需繳保費資訊（金額、月份、保單名稱）
    private func getNextPremiumInfo() -> (amount: Double, month: Int, policyName: String) {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())

        // 找出當月或下個月的繳費
        for offset in 0...12 {
            let checkMonth = (currentMonth + offset - 1) % 12 + 1

            // 找出該月份的第一張保單
            for policy in insurancePolicies {
                guard let paymentMonthString = policy.paymentMonth, !paymentMonthString.isEmpty else {
                    continue
                }

                let cleanedMonth = paymentMonthString.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                guard let paymentMonth = Int(cleanedMonth), paymentMonth == checkMonth else {
                    continue
                }

                // 取得年繳保費
                guard let companyName = policy.insuranceCompany, !companyName.isEmpty,
                      let productName = policy.policyName, !productName.isEmpty,
                      let client = client else {
                    continue
                }

                let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
                fetchRequest.predicate = NSPredicate(
                    format: "client == %@ AND companyName == %@ AND productName == %@",
                    client, companyName, productName
                )
                fetchRequest.fetchLimit = 1

                do {
                    if let calculator = try viewContext.fetch(fetchRequest).first,
                       let annualPremiumString = calculator.annualPremium, !annualPremiumString.isEmpty,
                       let annualPremium = Double(annualPremiumString.replacingOccurrences(of: ",", with: "")) {

                        // 根據試算表幣別和匯率進行轉換
                        let currency = calculator.currency ?? "TWD"
                        let exchangeRate = Double(calculator.exchangeRate ?? "32") ?? 32
                        let convertedAmount = convertCurrency(
                            amount: annualPremium,
                            fromCurrency: currency,
                            toCurrency: selectedCurrency,
                            exchangeRate: exchangeRate
                        )

                        return (amount: convertedAmount, month: checkMonth, policyName: productName)
                    }
                } catch {
                    print("❌ 取得試算表失敗：\(error.localizedDescription)")
                }
            }
        }

        return (amount: 0.0, month: currentMonth, policyName: "")
    }

    // 格式化下次需繳保費金額
    private func formatNextPremiumDue() -> String {
        let info = getNextPremiumInfo()
        return formatCurrency(info.amount)
    }

    // 格式化下次繳費月份和保單名稱
    private func formatNextPremiumMonth() -> String {
        let info = getNextPremiumInfo()
        if info.policyName.isEmpty {
            return "\(info.month)月"
        }
        return "\(info.month)月 · \(info.policyName)"
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? "0")
    }

    private func formatCurrencyWithoutSymbol(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    // MARK: - 保單操作函數

    // 新增一行空白保單（直接在表格內編輯）
    private func addNewPolicy() {
        guard let client = client else {
            print("❌ 無法新增保單：沒有選中的客戶")
            return
        }

        // 建立空白保單實體
        let newPolicy = InsurancePolicy(context: viewContext)
        newPolicy.policyType = ""
        newPolicy.insuranceCompany = ""
        newPolicy.policyNumber = ""
        newPolicy.policyName = ""
        newPolicy.insuredPerson = ""
        newPolicy.startDate = ""
        newPolicy.paymentMonth = ""
        newPolicy.coverageAmount = ""
        newPolicy.annualPremium = ""
        newPolicy.paymentPeriod = ""
        newPolicy.beneficiary = ""
        newPolicy.interestRate = ""
        newPolicy.currency = "TWD"
        newPolicy.createdDate = Date()
        newPolicy.client = client

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 已新增一行空白保單，可直接在表格內編輯")
        } catch {
            print("❌ 新增空白保單失敗：\(error.localizedDescription)")
        }
    }

    // 刪除最後一筆保單
    private func deleteLastPolicy() {
        guard let lastPolicy = insurancePolicies.last else {
            print("⚠️  沒有保單可以刪除")
            return
        }
        deletePolicy(lastPolicy)
    }

    // MARK: - OCR 照片辨識處理
    private func processImageWithOCR(_ image: UIImage) {
        isProcessingOCR = true

        let ocrManager = InsuranceOCRManager()

        // 步驟 1: 提取文字
        ocrManager.extractText(from: image) { result in
            switch result {
            case .success(let text):
                print("✅ OCR 文字辨識成功")
                print("辨識文字：\n\(text)")

                // 步驟 2: 解析表格資料（支援一張照片多筆保單）
                let policiesData = ocrManager.parseTableData(from: text)
                print("📋 共辨識出 \(policiesData.count) 筆保單")

                // 步驟 3: 根據辨識結果數量決定顯示方式
                DispatchQueue.main.async {
                    self.isProcessingOCR = false

                    if policiesData.count == 1 {
                        // 單筆保單：顯示原有的編輯畫面
                        let parsedData = policiesData[0]
                        let validation = ocrManager.validateData(parsedData)
                        print("📊 資料完整度：\(Int(validation.completeness * 100))%")
                        if !validation.missingFields.isEmpty {
                            print("⚠️  缺少欄位：\(validation.missingFields.joined(separator: "、"))")
                        }

                        self.ocrPolicyData = parsedData
                        self.showingOCREditView = true
                    } else if policiesData.count > 1 {
                        // 多筆保單：顯示批次審閱畫面
                        print("📸 辨識到表格形式的多筆保單，進入批次審閱模式")
                        self.multiplePoliciesData = policiesData
                        self.currentImageForBatch = image
                        self.showingMultiplePoliciesView = true
                    } else {
                        // 辨識失敗
                        print("⚠️  無法從照片中辨識出保單資料")
                        // TODO: 顯示錯誤訊息給使用者
                    }
                }

            case .failure(let error):
                print("❌ OCR 辨識失敗：\(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isProcessingOCR = false
                    // TODO: 顯示錯誤訊息給使用者
                }
            }
        }
    }

    // MARK: - Core Data 資料持久化

    /// 儲存保單資料到 Core Data (會自動同步到 iCloud)
    private func saveToCoreData(_ policyData: InsurancePolicyData) {
        guard let client = client else {
            print("❌ 無法儲存：沒有選中的客戶")
            return
        }

        let newPolicy = InsurancePolicy(context: viewContext)
        newPolicy.policyType = policyData.policyType
        newPolicy.insuranceCompany = policyData.insuranceCompany
        newPolicy.policyNumber = policyData.policyNumber
        newPolicy.policyName = policyData.policyName
        newPolicy.policyHolder = policyData.policyHolder
        newPolicy.insuredPerson = policyData.insuredPerson
        newPolicy.startDate = policyData.startDate
        newPolicy.paymentMonth = policyData.paymentMonth
        newPolicy.coverageAmount = policyData.coverageAmount
        newPolicy.annualPremium = policyData.annualPremium
        newPolicy.paymentPeriod = policyData.paymentPeriod
        newPolicy.beneficiary = policyData.beneficiary
        newPolicy.interestRate = policyData.interestRate
        newPolicy.currency = policyData.currency
        newPolicy.createdDate = Date()
        newPolicy.client = client

        do {
            try viewContext.save()
            print("✅ 保單已儲存到 Core Data 並自動同步到 iCloud")
            print("📋 目前共有 \(insurancePolicies.count) 筆保單")
        } catch {
            print("❌ 儲存保單失敗：\(error.localizedDescription)")
        }
    }

    /// 刪除保單
    private func deletePolicy(_ policy: InsurancePolicy) {
        viewContext.delete(policy)

        do {
            try viewContext.save()
            print("✅ 保單已刪除")
        } catch {
            print("❌ 刪除保單失敗：\(error.localizedDescription)")
        }
    }

    // MARK: - 快速上傳試算表功能

    /// 快速上傳試算表（自動帶入保險公司和保險名稱作為分類）
    private func quickUploadCalculator(for policy: InsurancePolicy) {
        // 檢查保險公司和保險名稱是否已填寫
        guard let companyName = policy.insuranceCompany, !companyName.isEmpty else {
            print("⚠️ 請先填寫保險公司名稱")
            // TODO: 顯示提示訊息給使用者
            return
        }

        guard let productName = policy.policyName, !productName.isEmpty else {
            print("⚠️ 請先填寫保險名稱")
            // TODO: 顯示提示訊息給使用者
            return
        }

        print("📤 存放試算表到分類")
        print("   保險公司：\(companyName)")
        print("   保險名稱：\(productName)")

        // 步驟 1：檢查保險試算表中是否已有這家保險公司
        let existingCompanies = fetchExistingCompanies()
        let companyExists = existingCompanies.contains(companyName)

        if !companyExists {
            print("   ➕ 保險公司不存在，將自動新增：\(companyName)")
        } else {
            print("   ✓ 保險公司已存在：\(companyName)")
        }

        // 步驟 2：檢查該公司下是否有相同的保險名稱
        let existingProducts = fetchExistingProducts(for: companyName)
        let productExists = existingProducts.contains(productName)

        if !productExists {
            print("   ➕ 保險商品不存在，將自動新增：\(productName)")
        } else {
            print("   ✓ 保險商品已存在：\(productName)")
        }

        // 步驟 3：移轉保單欄位資料到試算表
        // 這裡類似結構型明細的「出場」功能，自動建立一個試算表記錄
        createCalculatorFromPolicy(policy, companyName: companyName, productName: productName)

        // 步驟 4：通知 InsuranceCalculatorView 自動選擇對應的公司和商品
        NotificationCenter.default.post(
            name: NSNotification.Name("QuickUploadCalculator"),
            object: nil,
            userInfo: [
                "companyName": companyName,
                "productName": productName
            ]
        )

        print("✅ 存放完成")
    }

    /// 取得所有已存在的保險公司
    private func fetchExistingCompanies() -> Set<String> {
        let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client!)

        do {
            let results = try viewContext.fetch(fetchRequest)
            return Set(results.compactMap { $0.companyName }.filter { !$0.isEmpty })
        } catch {
            print("❌ 無法取得保險公司列表：\(error.localizedDescription)")
            return []
        }
    }

    /// 取得指定公司下的所有商品名稱
    private func fetchExistingProducts(for companyName: String) -> Set<String> {
        let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@ AND companyName == %@", client!, companyName)

        do {
            let results = try viewContext.fetch(fetchRequest)
            return Set(results.compactMap { $0.productName }.filter { !$0.isEmpty })
        } catch {
            print("❌ 無法取得商品列表：\(error.localizedDescription)")
            return []
        }
    }

    /// 從保單建立試算表記錄（不包含表格資料，等待用戶匯入CSV或照片）
    private func createCalculatorFromPolicy(_ policy: InsurancePolicy, companyName: String, productName: String) {
        guard let client = client else {
            print("❌ 無法建立試算表記錄：沒有選中的客戶")
            return
        }

        // 檢查是否已經存在相同的試算表
        let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "client == %@ AND companyName == %@ AND productName == %@",
            client, companyName, productName
        )

        do {
            let existingCalculators = try viewContext.fetch(fetchRequest)

            // 如果已存在，直接展開該試算表視圖
            if !existingCalculators.isEmpty {
                print("   ✓ 試算表已存在，直接開啟")

                // 通知展開視圖
                NotificationCenter.default.post(
                    name: NSNotification.Name("QuickUploadCalculator"),
                    object: nil,
                    userInfo: [
                        "companyName": companyName,
                        "productName": productName
                    ]
                )
                return
            }

            // 建立新的試算表記錄
            let newCalculator = InsuranceCalculator(context: viewContext)
            newCalculator.client = client
            newCalculator.companyName = companyName
            newCalculator.productName = productName
            newCalculator.createdDate = Date()
            newCalculator.sortOrder = 0
            // 從保單轉移所有相關欄位
            newCalculator.startDate = policy.startDate ?? ""
            newCalculator.paymentPeriod = policy.paymentPeriod ?? ""
            newCalculator.insuredPerson = policy.insuredPerson ?? ""
            newCalculator.beneficiary = policy.beneficiary ?? ""
            newCalculator.annualPremium = policy.annualPremium ?? ""
            newCalculator.paymentMonth = policy.paymentMonth ?? ""
            newCalculator.interestRate = policy.interestRate ?? ""
            newCalculator.currency = policy.currency ?? "TWD"
            newCalculator.exchangeRate = policy.exchangeRate ?? "32"
            // 不設定 fileName 和 fileData，因為這是一個空的試算表

            // 自動生成100行試算表資料（包含保險年齡推算）
            generateCalculatorRows(for: newCalculator, client: client, startDate: policy.startDate)

            // 儲存到 Core Data
            try viewContext.save()
            PersistenceController.shared.save()

            print("✅ 已建立試算表記錄")
            print("   公司：\(companyName)")
            print("   商品：\(productName)")
            print("   保險始期：\(policy.startDate ?? "未設定")")
            print("   繳費年期：\(policy.paymentPeriod ?? "未設定")")
            print("   已自動生成100年試算表資料（含保險年齡推算）")

            // 通知 InsuranceCalculatorView 刷新並選擇對應的分類
            NotificationCenter.default.post(
                name: NSNotification.Name("QuickUploadCalculator"),
                object: nil,
                userInfo: [
                    "companyName": companyName,
                    "productName": productName
                ]
            )

        } catch {
            print("❌ 儲存試算表記錄失敗：\(error.localizedDescription)")
        }
    }

    // MARK: - 保險年齡推算功能

    /// 生成100行試算表資料（包含保險年齡推算）
    private func generateCalculatorRows(for calculator: InsuranceCalculator, client: Client, startDate: String?) {
        // 計算第一年的保險年齡
        let firstYearAge = calculateFirstYearInsuranceAge(client: client, startDate: startDate)

        print("📊 開始生成試算表資料：")
        print("   客戶出生日期：\(client.birthDate != nil ? formatDateForDisplay(client.birthDate!) : "未設定")")
        print("   保險始期：\(startDate ?? "未設定")")
        print("   第一年保險年齡：\(firstYearAge != nil ? "\(firstYearAge!)" : "無法計算（缺少出生日期或保險始期）")")

        // 生成100行資料
        for year in 1...100 {
            let row = InsuranceCalculatorRow(context: viewContext)
            row.calculator = calculator
            row.policyYear = "\(year)"
            row.rowOrder = Int16(year - 1)
            row.createdDate = Date()

            // 計算保險年齡（如果第一年年齡有效，則遞增）
            if let baseAge = firstYearAge {
                let currentAge = baseAge + (year - 1)
                row.insuranceAge = "\(currentAge)"
            } else {
                row.insuranceAge = ""  // 無法計算時留空
            }

            // 其他欄位初始化為空
            row.cashValue = ""
            row.deathBenefit = ""
        }

        print("✅ 已生成100行試算表資料")
    }

    /// 計算第一年的保險年齡
    /// - Parameters:
    ///   - client: 客戶實體（包含出生日期）
    ///   - startDate: 保險始期（字串格式）
    /// - Returns: 第一年的保險年齡，如果無法計算則返回 nil
    private func calculateFirstYearInsuranceAge(client: Client, startDate: String?) -> Int? {
        // 檢查是否有客戶出生日期
        guard let birthDate = client.birthDate else {
            print("⚠️ 客戶未設定出生日期，無法計算保險年齡")
            return nil
        }

        // 檢查是否有保險始期
        guard let startDateString = startDate, !startDateString.isEmpty else {
            print("⚠️ 保險始期未設定，無法計算保險年齡")
            return nil
        }

        // 解析保險始期字串為 Date 物件
        guard let policyStartDate = parseDate(startDateString) else {
            print("⚠️ 無法解析保險始期：\(startDateString)")
            return nil
        }

        // 計算年齡差距
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: policyStartDate)

        guard let age = ageComponents.year else {
            print("⚠️ 計算年齡失敗")
            return nil
        }

        print("✅ 計算出保險年齡：\(age) 歲")
        print("   出生日期：\(formatDateForDisplay(birthDate))")
        print("   保險始期：\(formatDateForDisplay(policyStartDate))")

        return age
    }

    /// 格式化日期為顯示用字串
    private func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }

    // MARK: - 雙向同步功能

    /// 重新計算試算表的保險年齡（當保險始期變更時）
    private func recalculateInsuranceAges(for calculator: InsuranceCalculator, client: Client, newStartDate: String?) {
        // 計算第一年的保險年齡
        let firstYearAge = calculateFirstYearInsuranceAge(client: client, startDate: newStartDate)

        guard let baseAge = firstYearAge else {
            print("⚠️ 無法計算保險年齡：缺少出生日期或保險始期")
            return
        }

        // 取得所有試算表行
        let fetchRequest: NSFetchRequest<InsuranceCalculatorRow> = InsuranceCalculatorRow.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "calculator == %@", calculator)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \InsuranceCalculatorRow.rowOrder, ascending: true)]

        do {
            let rows = try viewContext.fetch(fetchRequest)

            // 更新每一行的保險年齡
            for row in rows {
                if let policyYearString = row.policyYear, let policyYear = Int(policyYearString) {
                    let currentAge = baseAge + (policyYear - 1)
                    row.insuranceAge = "\(currentAge)"
                }
            }

            print("✅ 已重新計算 \(rows.count) 行的保險年齡（起始年齡：\(baseAge)）")
        } catch {
            print("❌ 重新計算保險年齡失敗：\(error.localizedDescription)")
        }
    }

    /// 同步保單資料到試算表（當保單資料更新時）
    private func syncToCalculator(for policy: InsurancePolicy) {
        // 檢查是否有保險公司和保險名稱
        guard let companyName = policy.insuranceCompany, !companyName.isEmpty,
              let productName = policy.policyName, !productName.isEmpty,
              let client = client else {
            return
        }

        // 查找對應的試算表記錄
        let fetchRequest: NSFetchRequest<InsuranceCalculator> = InsuranceCalculator.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "client == %@ AND companyName == %@ AND productName == %@",
            client, companyName, productName
        )

        do {
            let calculators = try viewContext.fetch(fetchRequest)

            // 如果找到對應的試算表，更新資料
            if let calculator = calculators.first {
                var hasChanges = false

                // 同步所有相關欄位
                let startDateChanged = calculator.startDate != policy.startDate
                if startDateChanged {
                    calculator.startDate = policy.startDate ?? ""
                    hasChanges = true
                }
                if calculator.paymentPeriod != policy.paymentPeriod {
                    calculator.paymentPeriod = policy.paymentPeriod ?? ""
                    hasChanges = true
                }
                if calculator.insuredPerson != policy.insuredPerson {
                    calculator.insuredPerson = policy.insuredPerson ?? ""
                    hasChanges = true
                }
                if calculator.beneficiary != policy.beneficiary {
                    calculator.beneficiary = policy.beneficiary ?? ""
                    hasChanges = true
                }
                if calculator.annualPremium != policy.annualPremium {
                    calculator.annualPremium = policy.annualPremium ?? ""
                    hasChanges = true
                }
                if calculator.paymentMonth != policy.paymentMonth {
                    calculator.paymentMonth = policy.paymentMonth ?? ""
                    hasChanges = true
                }
                if calculator.interestRate != policy.interestRate {
                    calculator.interestRate = policy.interestRate ?? ""
                    hasChanges = true
                }
                if calculator.currency != policy.currency {
                    calculator.currency = policy.currency ?? "TWD"
                    hasChanges = true
                }
                if calculator.exchangeRate != policy.exchangeRate {
                    calculator.exchangeRate = policy.exchangeRate ?? "32"
                    hasChanges = true
                }

                // 如果有變更，儲存
                if hasChanges {
                    // 如果保險始期有變更，需要重新計算所有行的保險年齡
                    if startDateChanged {
                        recalculateInsuranceAges(for: calculator, client: client, newStartDate: policy.startDate)
                    }

                    try viewContext.save()
                    PersistenceController.shared.save()
                    print("🔄 已同步更新試算表資料：\(companyName) - \(productName)")

                    if startDateChanged {
                        print("📊 已重新計算保險年齡")
                    }
                }
            }
        } catch {
            print("❌ 同步試算表資料失敗：\(error.localizedDescription)")
        }
    }

}

#Preview {
    InsurancePolicyView(client: nil, onBack: {})
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
