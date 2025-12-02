import SwiftUI
import CoreData

// MARK: - 群組編輯 Sheet 視圖
struct GroupEditSheetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var group: InvestmentGroup
    let groupType: InvestmentGroupRowView.GroupType

    @State private var groupName: String = ""
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationView {
            List {
                // 群組名稱編輯
                Section(header: Text("群組名稱")) {
                    TextField("群組名稱", text: $groupName)
                        .textFieldStyle(.roundedBorder)
                }

                // 群組內項目列表
                Section(header: Text("包含項目 (\(groupItems.count))")) {
                    if groupItems.isEmpty {
                        Text("此群組尚無項目")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    } else {
                        ForEach(groupItems, id: \.objectID) { item in
                            HStack {
                                Text(itemName(for: item))
                                    .font(.system(size: 15))

                                Spacer()

                                Text(formatCurrency(itemValue(for: item)))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)

                                Button(action: {
                                    removeItemFromGroup(item: item)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }

                // 刪除群組按鈕
                Section {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("刪除此群組")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("編輯群組")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveGroupName()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("確認刪除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("刪除", role: .destructive) {
                    deleteGroup()
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("確定要刪除「\(group.name ?? "")」群組嗎？群組內的投資項目不會被刪除。")
            }
        }
        .onAppear {
            groupName = group.name ?? ""
        }
    }

    // MARK: - 群組內項目
    private var groupItems: [NSManagedObject] {
        switch groupType {
        case .usStock:
            return Array(group.usStocks as? Set<USStock> ?? [])
        case .twStock:
            return Array(group.twStocks as? Set<TWStock> ?? [])
        case .bond:
            return Array(group.bonds as? Set<CorporateBond> ?? [])
        case .structured:
            return Array(group.structuredProducts as? Set<StructuredProduct> ?? [])
        }
    }

    // MARK: - 項目信息
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
                return Double(product.transactionAmount ?? "0") ?? 0
            }
        }
        return 0
    }

    // MARK: - 操作函數
    private func saveGroupName() {
        group.name = groupName
        try? viewContext.save()
    }

    private func removeItemFromGroup(item: NSManagedObject) {
        switch groupType {
        case .usStock:
            if let stock = item as? USStock {
                var groups = stock.groups as? Set<InvestmentGroup> ?? Set()
                groups.remove(group)
                stock.groups = groups as NSSet
            }
        case .twStock:
            if let stock = item as? TWStock {
                var groups = stock.groups as? Set<InvestmentGroup> ?? Set()
                groups.remove(group)
                stock.groups = groups as NSSet
            }
        case .bond:
            if let bond = item as? CorporateBond {
                var groups = bond.groups as? Set<InvestmentGroup> ?? Set()
                groups.remove(group)
                bond.groups = groups as NSSet
            }
        case .structured:
            if let product = item as? StructuredProduct {
                var groups = product.groups as? Set<InvestmentGroup> ?? Set()
                groups.remove(group)
                product.groups = groups as NSSet
            }
        }

        try? viewContext.save()
    }

    private func deleteGroup() {
        viewContext.delete(group)
        try? viewContext.save()
    }

    // MARK: - 格式化
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return "$\(formatter.string(from: NSNumber(value: value)) ?? "0")"
    }
}
