import SwiftUI
import CoreData

// MARK: - 投資群組管理視圖
struct InvestmentGroupManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    let client: Client
    let groupType: GroupType // "usStock", "twStock", "bond", "structured"

    // FetchRequest 取得當前客戶的群組
    @FetchRequest private var groups: FetchedResults<InvestmentGroup>

    // 根據類型取得項目
    @FetchRequest private var usStocks: FetchedResults<USStock>
    @FetchRequest private var twStocks: FetchedResults<TWStock>
    @FetchRequest private var bonds: FetchedResults<CorporateBond>
    @FetchRequest private var structuredProducts: FetchedResults<StructuredProduct>

    @State private var showingAddGroup = false
    @State private var newGroupName = ""
    @State private var selectedGroup: InvestmentGroup?
    @State private var showingEditGroup = false

    enum GroupType: String {
        case usStock = "usStock"
        case twStock = "twStock"
        case bond = "bond"
        case structured = "structured"

        var displayName: String {
            switch self {
            case .usStock: return "美股"
            case .twStock: return "台股"
            case .bond: return "債券"
            case .structured: return "結構型"
            }
        }
    }

    init(client: Client, groupType: GroupType) {
        self.client = client
        self.groupType = groupType

        // 設定群組 FetchRequest
        _groups = FetchRequest<InvestmentGroup>(
            sortDescriptors: [NSSortDescriptor(keyPath: \InvestmentGroup.orderIndex, ascending: true)],
            predicate: NSPredicate(format: "client == %@ AND groupType == %@", client, groupType.rawValue),
            animation: .default
        )

        // 設定項目 FetchRequest（根據類型）
        switch groupType {
        case .usStock:
            _usStocks = FetchRequest<USStock>(
                sortDescriptors: [NSSortDescriptor(keyPath: \USStock.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client)
            )
            _twStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _bonds = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _structuredProducts = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
        case .twStock:
            _twStocks = FetchRequest<TWStock>(
                sortDescriptors: [NSSortDescriptor(keyPath: \TWStock.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client)
            )
            _usStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _bonds = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _structuredProducts = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
        case .bond:
            _bonds = FetchRequest<CorporateBond>(
                sortDescriptors: [NSSortDescriptor(keyPath: \CorporateBond.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client)
            )
            _usStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _twStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _structuredProducts = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
        case .structured:
            _structuredProducts = FetchRequest<StructuredProduct>(
                sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@ AND isExited == NO", client)
            )
            _usStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _twStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _bonds = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("群組列表")) {
                    ForEach(groups) { group in
                        GroupRowView(group: group, groupType: groupType)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedGroup = group
                                showingEditGroup = true
                            }
                    }
                    .onDelete(perform: deleteGroups)
                }
            }
            .navigationTitle("\(groupType.displayName)群組管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddGroup = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("新增群組", isPresented: $showingAddGroup) {
                TextField("群組名稱", text: $newGroupName)
                Button("取消", role: .cancel) {
                    newGroupName = ""
                }
                Button("新增") {
                    addGroup()
                }
            } message: {
                Text("請輸入群組名稱")
            }
            .sheet(item: $selectedGroup) { group in
                GroupEditView(group: group, groupType: groupType)
            }
        }
    }

    private func addGroup() {
        guard !newGroupName.isEmpty else { return }

        withAnimation {
            let newGroup = InvestmentGroup(context: viewContext)
            newGroup.id = UUID()
            newGroup.name = newGroupName
            newGroup.groupType = groupType.rawValue
            newGroup.client = client
            newGroup.createdDate = Date()
            newGroup.orderIndex = Int16(groups.count)

            do {
                try viewContext.save()
                print("✅ 已新增群組：\(newGroupName)")
                newGroupName = ""
            } catch {
                print("❌ 新增群組失敗：\(error)")
            }
        }
    }

    private func deleteGroups(offsets: IndexSet) {
        withAnimation {
            offsets.map { groups[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
                print("✅ 已刪除群組")
            } catch {
                print("❌ 刪除群組失敗：\(error)")
            }
        }
    }
}

// MARK: - 群組列表項
struct GroupRowView: View {
    @ObservedObject var group: InvestmentGroup
    let groupType: InvestmentGroupManagementView.GroupType

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name ?? "未命名群組")
                    .font(.system(size: 16, weight: .medium))

                Text("\(itemCount) 項目 • 總額 $\(formatCurrency(totalValue))")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(formatCurrency(totalValue))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }

    private var itemCount: Int {
        switch groupType {
        case .usStock:
            return (group.usStocks as? Set<USStock>)?.count ?? 0
        case .twStock:
            return (group.twStocks as? Set<TWStock>)?.count ?? 0
        case .bond:
            return (group.bonds as? Set<CorporateBond>)?.count ?? 0
        case .structured:
            return (group.structuredProducts as? Set<StructuredProduct>)?.count ?? 0
        }
    }

    private var totalValue: Double {
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
                let amount = Double(product.transactionAmount ?? "0") ?? 0
                return sum + amount
            })
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - 群組編輯視圖
struct GroupEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var group: InvestmentGroup
    let groupType: InvestmentGroupManagementView.GroupType

    @State private var groupName: String = ""
    @State private var selectedItems: Set<NSManagedObjectID> = []

    // 根據類型取得項目
    @FetchRequest private var usStocks: FetchedResults<USStock>
    @FetchRequest private var twStocks: FetchedResults<TWStock>
    @FetchRequest private var bonds: FetchedResults<CorporateBond>
    @FetchRequest private var structuredProducts: FetchedResults<StructuredProduct>

    init(group: InvestmentGroup, groupType: InvestmentGroupManagementView.GroupType) {
        self.group = group
        self.groupType = groupType

        guard let client = group.client else {
            // 如果沒有 client，創建空的 FetchRequest
            _usStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _twStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _bonds = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _structuredProducts = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            return
        }

        // 設定項目 FetchRequest
        switch groupType {
        case .usStock:
            _usStocks = FetchRequest<USStock>(
                sortDescriptors: [NSSortDescriptor(keyPath: \USStock.name, ascending: true)],
                predicate: NSPredicate(format: "client == %@", client)
            )
            _twStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _bonds = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _structuredProducts = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
        case .twStock:
            _twStocks = FetchRequest<TWStock>(
                sortDescriptors: [NSSortDescriptor(keyPath: \TWStock.name, ascending: true)],
                predicate: NSPredicate(format: "client == %@", client)
            )
            _usStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _bonds = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _structuredProducts = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
        case .bond:
            _bonds = FetchRequest<CorporateBond>(
                sortDescriptors: [NSSortDescriptor(keyPath: \CorporateBond.bondName, ascending: true)],
                predicate: NSPredicate(format: "client == %@", client)
            )
            _usStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _twStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _structuredProducts = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
        case .structured:
            _structuredProducts = FetchRequest<StructuredProduct>(
                sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.productCode, ascending: true)],
                predicate: NSPredicate(format: "client == %@ AND isExited == NO", client)
            )
            _usStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _twStocks = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _bonds = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("群組名稱")) {
                    TextField("群組名稱", text: $groupName)
                }

                Section(header: Text("選擇項目")) {
                    ForEach(allItems, id: \.objectID) { item in
                        ItemToggleRow(
                            item: item,
                            groupType: groupType,
                            isSelected: selectedItems.contains(item.objectID)
                        ) { isSelected in
                            if isSelected {
                                selectedItems.insert(item.objectID)
                            } else {
                                selectedItems.remove(item.objectID)
                            }
                        }
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
                        saveChanges()
                    }
                }
            }
            .onAppear {
                loadGroupData()
            }
        }
    }

    private var allItems: [NSManagedObject] {
        switch groupType {
        case .usStock:
            return Array(usStocks) as [NSManagedObject]
        case .twStock:
            return Array(twStocks) as [NSManagedObject]
        case .bond:
            return Array(bonds) as [NSManagedObject]
        case .structured:
            return Array(structuredProducts) as [NSManagedObject]
        }
    }

    private func loadGroupData() {
        groupName = group.name ?? ""

        // 載入已選擇的項目
        switch groupType {
        case .usStock:
            if let stocks = group.usStocks as? Set<USStock> {
                selectedItems = Set(stocks.map { $0.objectID })
            }
        case .twStock:
            if let stocks = group.twStocks as? Set<TWStock> {
                selectedItems = Set(stocks.map { $0.objectID })
            }
        case .bond:
            if let bonds = group.bonds as? Set<CorporateBond> {
                selectedItems = Set(bonds.map { $0.objectID })
            }
        case .structured:
            if let products = group.structuredProducts as? Set<StructuredProduct> {
                selectedItems = Set(products.map { $0.objectID })
            }
        }
    }

    private func saveChanges() {
        group.name = groupName

        // 更新群組成員
        switch groupType {
        case .usStock:
            let newStocks = usStocks.filter { selectedItems.contains($0.objectID) }
            group.usStocks = NSSet(array: newStocks)
        case .twStock:
            let newStocks = twStocks.filter { selectedItems.contains($0.objectID) }
            group.twStocks = NSSet(array: newStocks)
        case .bond:
            let newBonds = bonds.filter { selectedItems.contains($0.objectID) }
            group.bonds = NSSet(array: newBonds)
        case .structured:
            let newProducts = structuredProducts.filter { selectedItems.contains($0.objectID) }
            group.structuredProducts = NSSet(array: newProducts)
        }

        do {
            try viewContext.save()
            print("✅ 已儲存群組變更")
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("❌ 儲存失敗：\(error)")
        }
    }
}

// MARK: - 項目勾選列
struct ItemToggleRow: View {
    let item: NSManagedObject
    let groupType: InvestmentGroupManagementView.GroupType
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text(itemName)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)

                    Text(itemValue)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
    }

    private var itemName: String {
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

    private var itemValue: String {
        switch groupType {
        case .usStock:
            if let stock = item as? USStock {
                let price = Double(stock.currentPrice ?? "0") ?? 0
                let shares = Double(stock.shares ?? "0") ?? 0
                return "$\(formatNumber(price * shares))"
            }
        case .twStock:
            if let stock = item as? TWStock {
                let price = Double(stock.currentPrice ?? "0") ?? 0
                let shares = Double(stock.shares ?? "0") ?? 0
                return "$\(formatNumber(price * shares))"
            }
        case .bond:
            if let bond = item as? CorporateBond {
                let value = Double(bond.currentValue ?? "0") ?? 0
                return "$\(formatNumber(value))"
            }
        case .structured:
            if let product = item as? StructuredProduct {
                let amount = Double(product.transactionAmount ?? "0") ?? 0
                return "$\(formatNumber(amount))"
            }
        }
        return ""
    }

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
