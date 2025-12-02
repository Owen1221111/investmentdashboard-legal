import SwiftUI
import CoreData
import UniformTypeIdentifiers

// MARK: - 可拖曳的投資項目行視圖
struct DraggableInvestmentItemRow: View {
    let item: NSManagedObject
    let itemType: ItemType
    let onTap: () -> Void

    @State private var isDragging = false

    enum ItemType {
        case usStock, twStock, bond, structured

        var color: Color {
            switch self {
            case .usStock: return .blue
            case .twStock: return .orange
            case .bond: return .purple
            case .structured: return .pink
            }
        }

        var icon: String {
            switch self {
            case .usStock: return "🇺🇸"
            case .twStock: return "🇹🇼"
            case .bond: return "📄"
            case .structured: return "📊"
            }
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 左側：圖標
                Circle()
                    .fill(itemType.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(itemType.icon)
                            .font(.system(size: 18))
                    )

                // 中間：項目信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(itemName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)

                    Text(itemDetails)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    // 顯示所屬群組標籤（如果有）
                    if !belongingGroups.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(belongingGroups, id: \.self) { groupName in
                                    Text(groupName)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(itemType.color)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(itemType.color.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }

                Spacer()

                // 右側：金額
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(itemValue))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    if let profitLoss = itemProfitLoss {
                        Text(profitLoss >= 0 ? "+\(formatCurrency(profitLoss))" : formatCurrency(profitLoss))
                            .font(.system(size: 12))
                            .foregroundColor(profitLoss >= 0 ? .green : .red)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .opacity(isDragging ? 0.5 : 1.0)
            .scaleEffect(isDragging ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onDrag {
            isDragging = true
            // 震動回饋
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            return NSItemProvider(object: itemDragData as NSString)
        }
        .onChange(of: isDragging) { newValue in
            if !newValue {
                // 拖曳結束後延遲恢復狀態
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isDragging = false
                }
            }
        }
    }

    // MARK: - 項目信息提取
    private var itemName: String {
        switch itemType {
        case .usStock:
            return (item as? USStock)?.name ?? ""
        case .twStock:
            return (item as? TWStock)?.name ?? ""
        case .bond:
            return (item as? CorporateBond)?.bondName ?? ""
        case .structured:
            return (item as? StructuredProduct)?.productCode ?? ""
        }
    }

    private var itemDetails: String {
        switch itemType {
        case .usStock:
            if let stock = item as? USStock {
                return "持有 \(stock.shares ?? "0") 股, $\(stock.currentPrice ?? "0")"
            }
        case .twStock:
            if let stock = item as? TWStock {
                return "持有 \(stock.shares ?? "0") 股, $\(stock.currentPrice ?? "0")"
            }
        case .bond:
            if let bond = item as? CorporateBond {
                return "面額 \(bond.holdingFaceValue ?? "0"), 利率 \(bond.couponRate ?? "0")%"
            }
        case .structured:
            if let product = item as? StructuredProduct {
                return product.target1 ?? ""
            }
        }
        return ""
    }

    private var itemValue: Double {
        switch itemType {
        case .usStock:
            if let stock = item as? USStock {
                let price = Double(stock.currentPrice ?? "0") ?? 0
                let shares = Double(stock.shares ?? "0") ?? 0
                return price * shares
            }
        case .twStock:
            if let stock = item as? TWStock {
                let price = Double(stock.currentPrice ?? "0") ?? 0
                let shares = Double(stock.shares ?? "0") ?? 0
                return price * shares
            }
        case .bond:
            if let bond = item as? CorporateBond {
                return Double(bond.currentValue ?? "0") ?? 0
            }
        case .structured:
            if let product = item as? StructuredProduct {
                return Double(product.transactionAmount ?? "0") ?? 0
            }
        }
        return 0
    }

    private var itemProfitLoss: Double? {
        switch itemType {
        case .usStock:
            if let stock = item as? USStock {
                return Double(stock.profitLoss ?? "") ?? nil
            }
        case .twStock:
            if let stock = item as? TWStock {
                return Double(stock.profitLoss ?? "") ?? nil
            }
        case .bond:
            if let bond = item as? CorporateBond {
                return Double(bond.profitLossWithInterest ?? "") ?? nil
            }
        case .structured:
            return nil
        }
        return nil
    }

    // MARK: - 所屬群組
    private var belongingGroups: [String] {
        var groupNames: [String] = []

        switch itemType {
        case .usStock:
            if let stock = item as? USStock,
               let groups = stock.groups as? Set<InvestmentGroup> {
                groupNames = groups.compactMap { $0.name }
            }
        case .twStock:
            if let stock = item as? TWStock,
               let groups = stock.groups as? Set<InvestmentGroup> {
                groupNames = groups.compactMap { $0.name }
            }
        case .bond:
            if let bond = item as? CorporateBond,
               let groups = bond.groups as? Set<InvestmentGroup> {
                groupNames = groups.compactMap { $0.name }
            }
        case .structured:
            if let product = item as? StructuredProduct,
               let groups = product.groups as? Set<InvestmentGroup> {
                groupNames = groups.compactMap { $0.name }
            }
        }

        return groupNames
    }

    // MARK: - 拖曳數據
    private var itemDragData: String {
        return item.objectID.uriRepresentation().absoluteString
    }

    // MARK: - 格式化金額
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return "$\(formatter.string(from: NSNumber(value: value)) ?? "0")"
    }
}
