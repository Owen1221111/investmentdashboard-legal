import Foundation
import SwiftUI

// MARK: - 欄位類型定義
enum AssetFieldType: String, Codable, CaseIterable, Identifiable {
    case twdCash = "台幣"
    case cash = "美金"
    case usStock = "美股"
    case regularInvestment = "定期定額"
    case bonds = "債券"
    case taiwanStock = "台股"
    case taiwanStockFolded = "台股折合美金"
    case twdToUsd = "台幣折合美金"
    case structured = "結構型商品"
    case confirmedInterest = "債券已領利息"
    case totalAssets = "總資產"
    case fund = "基金"
    case insurance = "保險"
    case exchangeRate = "匯率"
    case fundCost = "基金成本"
    case usStockCost = "美股成本"
    case regularInvestmentCost = "定期定額成本"
    case bondsCost = "債券成本"
    case taiwanStockCost = "台股成本"

    // 其他貨幣（順序：現金 -> 匯率 -> 折合美金）
    case eurCash = "歐元"
    case eurRate = "歐元兌美金匯率"
    case eurToUsd = "歐元折合美金"

    case jpyCash = "日圓"
    case jpyRate = "日圓兌美金匯率"
    case jpyToUsd = "日圓折合美金"

    case gbpCash = "英鎊"
    case gbpRate = "英鎊兌美金匯率"
    case gbpToUsd = "英鎊折合美金"

    case cnyCash = "人民幣"
    case cnyRate = "人民幣兌美金匯率"
    case cnyToUsd = "人民幣折合美金"

    case audCash = "澳幣"
    case audRate = "澳幣兌美金匯率"
    case audToUsd = "澳幣折合美金"

    case cadCash = "加幣"
    case cadRate = "加幣兌美金匯率"
    case cadToUsd = "加幣折合美金"

    case chfCash = "瑞士法郎"
    case chfRate = "瑞士法郎兌美金匯率"
    case chfToUsd = "瑞士法郎折合美金"

    case hkdCash = "港幣"
    case hkdRate = "港幣兌美金匯率"
    case hkdToUsd = "港幣折合美金"

    case sgdCash = "新加坡幣"
    case sgdRate = "新加坡幣兌美金匯率"
    case sgdToUsd = "新加坡幣折合美金"

    // 月度資產明細特有欄位
    case date = "日期"
    case deposit = "匯入"
    case depositAccumulated = "匯入累積"
    case notes = "備註"

    var id: String { self.rawValue }

    var displayName: String { self.rawValue }

    // 是否為唯讀欄位
    var isReadOnly: Bool {
        switch self {
        case .taiwanStockFolded, .twdToUsd, .totalAssets,
             .eurToUsd, .jpyToUsd, .gbpToUsd, .cnyToUsd, .audToUsd,
             .cadToUsd, .chfToUsd, .hkdToUsd, .sgdToUsd,
             .depositAccumulated:  // 匯入累積為自動計算
            return true
        default:
            return false
        }
    }

    // 是否為預設顯示欄位
    var isDefaultVisible: Bool {
        switch self {
        case .eurCash, .jpyCash, .gbpCash, .cnyCash, .audCash,
             .cadCash, .chfCash, .hkdCash, .sgdCash,
             .eurToUsd, .jpyToUsd, .gbpToUsd, .cnyToUsd, .audToUsd,
             .cadToUsd, .chfToUsd, .hkdToUsd, .sgdToUsd,
             .eurRate, .jpyRate, .gbpRate, .cnyRate, .audRate,
             .cadRate, .chfRate, .hkdRate, .sgdRate:
            return false // 預設隱藏
        default:
            return true
        }
    }
}

// MARK: - 欄位配置
struct FieldConfiguration: Codable, Identifiable {
    let id: String
    let type: AssetFieldType
    var isVisible: Bool
    var order: Int

    init(type: AssetFieldType, isVisible: Bool = true, order: Int = 0) {
        self.id = type.rawValue
        self.type = type
        self.isVisible = isVisible
        self.order = order
    }
}

// MARK: - 欄位配置管理器
class FieldConfigurationManager: ObservableObject {
    static let shared = FieldConfigurationManager()

    @Published var fieldConfigurations: [FieldConfiguration] = []

    private let userDefaultsKey = "AssetFieldConfigurations"

    private init() {
        loadConfigurations()
    }

    // 載入配置
    private func loadConfigurations() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([FieldConfiguration].self, from: data) {
            fieldConfigurations = decoded.sorted(by: { $0.order < $1.order })
            print("✅ 已載入自定義欄位配置，共 \(fieldConfigurations.count) 個欄位")

            // 遷移邏輯：檢查是否有新增的欄位類型
            let existingTypes = Set(fieldConfigurations.map { $0.type })
            let allTypes = Set(AssetFieldType.allCases)
            let missingTypes = allTypes.subtracting(existingTypes)

            if !missingTypes.isEmpty {
                print("🔄 發現 \(missingTypes.count) 個新增欄位，正在遷移...")

                // 計算新欄位的起始順序（接在現有欄位之後）
                let maxOrder = fieldConfigurations.map { $0.order }.max() ?? 0

                // 為新欄位創建配置
                let newConfigs = missingTypes.enumerated().map { index, type in
                    FieldConfiguration(
                        type: type,
                        isVisible: type.isDefaultVisible,
                        order: maxOrder + index + 1
                    )
                }

                // 加入新欄位
                fieldConfigurations.append(contentsOf: newConfigs)
                fieldConfigurations.sort { $0.order < $1.order }

                // 儲存更新後的配置
                saveConfigurations()
                print("✅ 已自動加入 \(missingTypes.count) 個新欄位")
                print("   新增欄位: \(missingTypes.map { $0.displayName }.joined(separator: ", "))")
            }
        } else {
            // 使用預設配置
            resetToDefault()
        }
    }

    // 儲存配置
    func saveConfigurations() {
        if let encoded = try? JSONEncoder().encode(fieldConfigurations) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("💾 已儲存欄位配置")
        }
    }

    // 重設為預設配置
    func resetToDefault() {
        fieldConfigurations = AssetFieldType.allCases.enumerated().map { index, type in
            FieldConfiguration(type: type, isVisible: type.isDefaultVisible, order: index)
        }
        saveConfigurations()
        print("🔄 已重設為預設欄位配置")
    }

    // 更新欄位順序
    func updateOrder(from source: IndexSet, to destination: Int) {
        fieldConfigurations.move(fromOffsets: source, toOffset: destination)

        // 更新所有欄位的 order
        for (index, _) in fieldConfigurations.enumerated() {
            fieldConfigurations[index].order = index
        }

        saveConfigurations()
    }

    // 切換欄位可見性
    func toggleVisibility(for fieldId: String) {
        if let index = fieldConfigurations.firstIndex(where: { $0.id == fieldId }) {
            fieldConfigurations[index].isVisible.toggle()
            saveConfigurations()
        }
    }

    // 取得可見欄位
    var visibleFields: [FieldConfiguration] {
        return fieldConfigurations.filter { $0.isVisible }.sorted(by: { $0.order < $1.order })
    }
}
