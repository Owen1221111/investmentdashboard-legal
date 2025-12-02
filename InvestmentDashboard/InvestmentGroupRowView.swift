import SwiftUI
import CoreData

// MARK: - 投資群組行視圖（內嵌在投資列表中）
struct InvestmentGroupRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var group: InvestmentGroup

    let groupType: GroupType
    var isParentExpanded: Bool = false  // 新增：父卡片是否展開
    let onEdit: () -> Void
    let onDropItem: (NSManagedObject) -> Void
    let onUpdate: () -> Void
    let onDeleteItem: (NSManagedObject) -> Void

    @State private var isExpanded = false
    @State private var isDropTarget = false

    // 匯率 AppStorage
    @AppStorage("exchangeRate") private var tempExchangeRate: String = "32"
    @AppStorage("eurRate") private var tempEURRate: String = ""
    @AppStorage("jpyRate") private var tempJPYRate: String = ""
    @AppStorage("gbpRate") private var tempGBPRate: String = ""
    @AppStorage("cnyRate") private var tempCNYRate: String = ""
    @AppStorage("audRate") private var tempAUDRate: String = ""
    @AppStorage("cadRate") private var tempCADRate: String = ""
    @AppStorage("chfRate") private var tempCHFRate: String = ""
    @AppStorage("hkdRate") private var tempHKDRate: String = ""
    @AppStorage("sgdRate") private var tempSGDRate: String = ""

    enum GroupType {
        case usStock, twStock, bond, structured
    }

    var body: some View {
        VStack(spacing: 0) {
            // 群組標題行
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // 左側：資料夾圖標 + 展開箭頭
                    HStack(spacing: 8) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)

                        Image(systemName: "folder.fill")
                            .font(.system(size: 20))
                            .foregroundColor(groupColor)

                        Text(group.name ?? "未命名群組")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    // 右側：總金額
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(calculateGroupTotal()))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(groupColor)

                        Text("\(itemCount) 項")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    // 編輯按鈕
                    Button(action: onEdit) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 8)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDropTarget ? groupColor.opacity(0.1) : Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isDropTarget ? groupColor : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onDrop(of: [.text], isTargeted: $isDropTarget) { providers in
                handleDrop(providers: providers)
            }

            // 展開的內容：群組內的項目
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(groupItems, id: \.objectID) { item in
                        if groupType == .usStock || groupType == .twStock {
                            // 使用可展開編輯的行視圖
                            ExpandableStockRow(
                                stock: item,
                                color: groupColor,
                                currencyPrefix: groupType == .usStock ? "USD " : "TWD ",
                                isUSStock: groupType == .usStock,
                                titleColor: isParentExpanded ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .primary,
                                onUpdate: {
                                    onUpdate()
                                },
                                onDelete: {
                                    onDeleteItem(item)
                                }
                            )
                            .padding(.leading, 20) // 縮排
                        } else {
                            // 債券和結構型商品保持原樣
                            groupItemRow(for: item)
                                .padding(.leading, 40)
                        }
                    }

                    // 拖曳提示文字（放在群組內最下方）
                    Text("⬇︎ 拖到下方區域移除群組")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                        .padding(.leading, 20)
                }
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - 計算群組總金額
    private func calculateGroupTotal() -> Double {
        switch groupType {
        case .usStock:
            let stocks = group.usStocks as? Set<USStock> ?? []
            return stocks.reduce(0.0) { sum, stock in
                let price = Double(stock.currentPrice ?? "0") ?? 0
                let shares = Double(stock.shares ?? "0") ?? 0
                return sum + (price * shares)
            }
        case .twStock:
            let stocks = group.twStocks as? Set<TWStock> ?? []
            return stocks.reduce(0.0) { sum, stock in
                let price = Double(stock.currentPrice ?? "0") ?? 0
                let shares = Double(stock.shares ?? "0") ?? 0
                return sum + (price * shares)
            }
        case .bond:
            let bonds = group.bonds as? Set<CorporateBond> ?? []
            return bonds.reduce(0.0) { sum, bond in
                let value = Double(bond.currentValue ?? "0") ?? 0
                return sum + value
            }
        case .structured:
            let products = group.structuredProducts as? Set<StructuredProduct> ?? []
            return products.reduce(0.0, { sum, product in
                return sum + calculateStructuredProductConvertedToUSD(product: product)
            })
        }
    }

    // MARK: - 群組內項目
    private var groupItems: [NSManagedObject] {
        switch groupType {
        case .usStock:
            let stocks = Array(group.usStocks as? Set<USStock> ?? [])
            return stocks.sorted { ($0.createdDate ?? Date()) < ($1.createdDate ?? Date()) }
        case .twStock:
            let stocks = Array(group.twStocks as? Set<TWStock> ?? [])
            return stocks.sorted { ($0.createdDate ?? Date()) < ($1.createdDate ?? Date()) }
        case .bond:
            let bonds = Array(group.bonds as? Set<CorporateBond> ?? [])
            return bonds.sorted { ($0.createdDate ?? Date()) < ($1.createdDate ?? Date()) }
        case .structured:
            let products = Array(group.structuredProducts as? Set<StructuredProduct> ?? [])
            return products.sorted { ($0.createdDate ?? Date()) < ($1.createdDate ?? Date()) }
        }
    }

    private var itemCount: Int {
        groupItems.count
    }

    // MARK: - 群組顏色
    private var groupColor: Color {
        switch groupType {
        case .usStock: return Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0))  // Green
        case .twStock: return Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0))  // Green
        case .bond: return Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0)  // #C44536 Tomato Jam
        case .structured: return Color(red: 0x19/255.0, green: 0x72/255.0, blue: 0x78/255.0)  // #197278 Stormy Teal
        }
    }

    // MARK: - 群組項目行視圖
    @ViewBuilder
    private func groupItemRow(for item: NSManagedObject) -> some View {
        HStack(spacing: 12) {
            // 項目圖標
            Circle()
                .fill(groupColor.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(itemIcon(for: item))
                        .font(.system(size: 14))
                )

            // 項目名稱和詳情
            VStack(alignment: .leading, spacing: 2) {
                Text(itemName(for: item))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Text(itemDetails(for: item))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 項目金額
            Text(formatCurrency(itemValue(for: item)))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(groupColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onDrag {
            // 震動回饋
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            return NSItemProvider(object: item.objectID.uriRepresentation().absoluteString as NSString)
        }
    }

    // MARK: - 項目信息提取
    private func itemIcon(for item: NSManagedObject) -> String {
        switch groupType {
        case .usStock: return "🇺🇸"
        case .twStock: return "🇹🇼"
        case .bond: return "📄"
        case .structured: return "📊"
        }
    }

    private func itemName(for item: NSManagedObject) -> String {
        switch groupType {
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

    private func itemDetails(for item: NSManagedObject) -> String {
        switch groupType {
        case .usStock:
            if let stock = item as? USStock {
                return "持有 \(stock.shares ?? "0"), $\(stock.currentPrice ?? "0")"
            }
        case .twStock:
            if let stock = item as? TWStock {
                return "持有 \(stock.shares ?? "0"), $\(stock.currentPrice ?? "0")"
            }
        case .bond:
            if let bond = item as? CorporateBond {
                return "面額 \(bond.holdingFaceValue ?? "0")"
            }
        case .structured:
            if let product = item as? StructuredProduct {
                return product.target1 ?? ""
            }
        }
        return ""
    }

    private func itemValue(for item: NSManagedObject) -> Double {
        switch groupType {
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
                return calculateStructuredProductConvertedToUSD(product: product)
            }
        }
        return 0
    }

    // MARK: - 處理拖放
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            guard let data = data as? Data,
                  let objectIDString = String(data: data, encoding: .utf8),
                  let url = URL(string: objectIDString),
                  let coordinator = viewContext.persistentStoreCoordinator else {
                return
            }

            if let objectID = coordinator.managedObjectID(forURIRepresentation: url),
               let object = try? viewContext.existingObject(with: objectID) as? NSManagedObject {
                DispatchQueue.main.async {
                    onDropItem(object)
                }
            }
        }

        return true
    }

    // MARK: - 計算結構型商品折合美金
    private func calculateStructuredProductConvertedToUSD(product: StructuredProduct) -> Double {
        let currency = product.currency ?? "USD"

        // USD 不需要轉換
        if currency == "USD" {
            let amount = Double(product.transactionAmount ?? "0") ?? 0
            return amount
        }

        // 取得匯率
        let rate: String
        switch currency {
        case "TWD": rate = tempExchangeRate
        case "EUR": rate = tempEURRate
        case "JPY": rate = tempJPYRate
        case "GBP": rate = tempGBPRate
        case "CNY": rate = tempCNYRate
        case "AUD": rate = tempAUDRate
        case "CAD": rate = tempCADRate
        case "CHF": rate = tempCHFRate
        case "HKD": rate = tempHKDRate
        case "SGD": rate = tempSGDRate
        default: return 0
        }

        guard !rate.isEmpty, let rateValue = Double(rate), rateValue > 0 else {
            return 0
        }

        // 取得交易金額
        let amountString = product.transactionAmount ?? "0"
        guard let amount = Double(amountString), amount > 0 else {
            return 0
        }

        // 計算折合美金 = 交易金額 ÷ 匯率
        let convertedUSD = amount / rateValue
        return convertedUSD
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
