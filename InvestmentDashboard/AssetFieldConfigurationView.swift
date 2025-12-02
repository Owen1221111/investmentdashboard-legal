import SwiftUI

struct AssetFieldConfigurationView: View {
    @ObservedObject var configManager = FieldConfigurationManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showingResetAlert = false

    init() {
        // 設定導航欄外觀，確保背景色統一
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.3)

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 說明文字
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                    Text("拖動欄位以調整順序，點擊眼睛圖示以顯示/隱藏")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))

                // 欄位列表（按分組顯示）
                List {
                    // 資產資訊分組
                    Section(header: Text("資產資訊")) {
                        ForEach(generalFieldConfigs) { config in
                            FieldConfigRow(config: config)
                        }
                        .onMove { source, destination in
                            moveFieldsInSection(section: .general, from: source, to: destination)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    // 投資成本分組
                    Section(header: Text("投資成本")) {
                        ForEach(costFieldConfigs) { config in
                            FieldConfigRow(config: config)
                        }
                        .onMove { source, destination in
                            moveFieldsInSection(section: .cost, from: source, to: destination)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    // 美金匯率換算分組
                    Section(header: Text("美金匯率換算")) {
                        ForEach(exchangeFieldConfigs) { config in
                            FieldConfigRow(config: config)
                        }
                        .onMove { source, destination in
                            moveFieldsInSection(section: .exchange, from: source, to: destination)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .environment(\.editMode, .constant(.active))
                .contentMargins(.top, 0, for: .scrollContent)
            }
            .navigationTitle("欄位設定")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .medium))
                            Text("重設")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.orange)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("完成")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }
            .alert("重設欄位配置", isPresented: $showingResetAlert) {
                Button("取消", role: .cancel) { }
                Button("重設", role: .destructive) {
                    configManager.resetToDefault()
                }
            } message: {
                Text("確定要將欄位順序和顯示設定重設為預設值嗎？")
            }
        }
    }

    // 定義分組類型
    enum FieldSection {
        case general, cost, exchange
    }

    // 資產資訊分組的欄位
    private var generalFieldConfigs: [FieldConfiguration] {
        configManager.fieldConfigurations.filter { config in
            ![.fundCost, .usStockCost, .regularInvestmentCost, .bondsCost, .taiwanStockCost,
              .exchangeRate, .taiwanStockFolded, .twdToUsd,
              .eurRate, .eurToUsd, .jpyRate, .jpyToUsd, .gbpRate, .gbpToUsd,
              .cnyRate, .cnyToUsd, .audRate, .audToUsd, .cadRate, .cadToUsd,
              .chfRate, .chfToUsd, .hkdRate, .hkdToUsd, .sgdRate, .sgdToUsd].contains(config.type)
        }
    }

    // 投資成本分組的欄位
    private var costFieldConfigs: [FieldConfiguration] {
        configManager.fieldConfigurations.filter { config in
            [.fundCost, .usStockCost, .regularInvestmentCost, .bondsCost, .taiwanStockCost].contains(config.type)
        }
    }

    // 美金匯率換算分組的欄位
    private var exchangeFieldConfigs: [FieldConfiguration] {
        configManager.fieldConfigurations.filter { config in
            [.exchangeRate, .taiwanStockFolded, .twdToUsd,
             .eurRate, .eurToUsd, .jpyRate, .jpyToUsd, .gbpRate, .gbpToUsd,
             .cnyRate, .cnyToUsd, .audRate, .audToUsd, .cadRate, .cadToUsd,
             .chfRate, .chfToUsd, .hkdRate, .hkdToUsd, .sgdRate, .sgdToUsd].contains(config.type)
        }
    }

    // 在分組內移動欄位
    private func moveFieldsInSection(section: FieldSection, from source: IndexSet, to destination: Int) {
        let sectionConfigs: [FieldConfiguration]
        switch section {
        case .general:
            sectionConfigs = generalFieldConfigs
        case .cost:
            sectionConfigs = costFieldConfigs
        case .exchange:
            sectionConfigs = exchangeFieldConfigs
        }

        // 獲取移動的欄位
        guard let sourceIndex = source.first,
              sourceIndex < sectionConfigs.count,
              destination <= sectionConfigs.count else { return }

        let movingConfig = sectionConfigs[sourceIndex]

        // 在全局配置中找到這些欄位的索引
        guard let globalSourceIndex = configManager.fieldConfigurations.firstIndex(where: { $0.id == movingConfig.id }) else { return }

        // 計算目標位置在全局配置中的索引
        var globalDestination: Int
        if destination < sectionConfigs.count {
            let targetConfig = sectionConfigs[destination]
            globalDestination = configManager.fieldConfigurations.firstIndex(where: { $0.id == targetConfig.id }) ?? globalSourceIndex
        } else {
            // 移到分組末尾
            if let lastConfig = sectionConfigs.last,
               let lastIndex = configManager.fieldConfigurations.firstIndex(where: { $0.id == lastConfig.id }) {
                globalDestination = lastIndex + 1
            } else {
                globalDestination = globalSourceIndex
            }
        }

        // 調整目標索引（如果源在目標前面，目標索引需要-1）
        if globalSourceIndex < globalDestination {
            globalDestination -= 1
        }

        // 執行移動
        configManager.fieldConfigurations.move(fromOffsets: IndexSet(integer: globalSourceIndex), toOffset: globalDestination)

        // 更新所有欄位的 order
        for (index, _) in configManager.fieldConfigurations.enumerated() {
            configManager.fieldConfigurations[index].order = index
        }

        configManager.saveConfigurations()
    }

    private func moveFields(from source: IndexSet, to destination: Int) {
        configManager.updateOrder(from: source, to: destination)
    }
}

// MARK: - 欄位配置行組件
struct FieldConfigRow: View {
    let config: FieldConfiguration
    @ObservedObject var configManager = FieldConfigurationManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // 拖動指示器（系統自動提供）
            // 不需要手動添加，List 的 onMove 會自動顯示

            // 欄位名稱
            Text(config.type.displayName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(config.isVisible ? .primary : .secondary)

            Spacer()

            // 唯讀標籤
            if config.type.isReadOnly {
                Text("自動")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }

            // 可見性切換按鈕
            Button(action: {
                configManager.toggleVisibility(for: config.id)
            }) {
                Image(systemName: config.isVisible ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 18))
                    .foregroundColor(config.isVisible ? .blue : .gray)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AssetFieldConfigurationView()
}
