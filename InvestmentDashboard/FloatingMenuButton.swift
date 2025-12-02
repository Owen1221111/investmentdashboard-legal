//
//  FloatingMenuButton.swift
//  InvestmentDashboard
//
//  浮動選單按鈕 - 跨客戶搜尋功能
//

import SwiftUI
import CoreData

/// 浮動選單按鈕
struct FloatingMenuButton: View {
    @Binding var isExpanded: Bool
    @State private var position: CGPoint = CGPoint(x: 0, y: 400)
    @State private var dragOffset: CGSize = .zero
    @GestureState private var isDragging = false
    @State private var selectedCategory: String? = nil // 選中的類別

    let onStructuredProductAdd: () -> Void
    let onStructuredProductInventory: () -> Void
    let onUSStockAdd: () -> Void
    let onUSStockInventory: () -> Void
    let onTWStockAdd: () -> Void
    let onTWStockInventory: () -> Void
    let onCorporateBondAdd: () -> Void
    let onCorporateBondInventory: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 展開的選單項目
                if isExpanded {
                    // 主選單或子選單
                    if let category = selectedCategory {
                        // 子選單（新增/出場/庫存）
                        VStack(spacing: 8) {
                            SubMenuButton(title: "新增", icon: "plus") {
                                switch category {
                                case "structured": onStructuredProductAdd()
                                case "us": onUSStockAdd()
                                case "tw": onTWStockAdd()
                                case "bond": onCorporateBondAdd()
                                default: break
                                }
                                closeMenu()
                            }

                            SubMenuButton(title: "出場", icon: "arrow.right.circle") {
                                switch category {
                                case "structured": onStructuredProductInventory()
                                case "us": onUSStockInventory()
                                case "tw": onTWStockInventory()
                                case "bond": onCorporateBondInventory()
                                default: break
                                }
                                closeMenu()
                            }

                            SubMenuButton(title: "庫存", icon: "list.bullet") {
                                switch category {
                                case "structured": onStructuredProductInventory()
                                case "us": onUSStockInventory()
                                case "tw": onTWStockInventory()
                                case "bond": onCorporateBondInventory()
                                default: break
                                }
                                closeMenu()
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.75))
                        )
                        .position(
                            x: calculateMenuPosition(geometry: geometry).x,
                            y: calculateMenuPosition(geometry: geometry).y
                        )
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // 主選單
                        VStack(spacing: 8) {
                            MainMenuButton(title: "結構型", icon: "chart.bar.doc.horizontal") {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedCategory = "structured"
                                }
                            }

                            MainMenuButton(title: "美股", icon: "dollarsign.circle") {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedCategory = "us"
                                }
                            }

                            MainMenuButton(title: "台股", icon: "yensign.circle") {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedCategory = "tw"
                                }
                            }

                            MainMenuButton(title: "債券", icon: "doc.text.fill") {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedCategory = "bond"
                                }
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.75))
                        )
                        .position(
                            x: calculateMenuPosition(geometry: geometry).x,
                            y: calculateMenuPosition(geometry: geometry).y
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                // 主按鈕（三個點點）
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if isExpanded {
                            closeMenu()
                        } else {
                            isExpanded = true
                        }
                    }
                }) {
                    VStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                }
                .position(
                    x: position.x == 0 ? 20 : position.x + dragOffset.width,
                    y: position.y + dragOffset.height
                )
                .gesture(
                    DragGesture()
                        .updating($isDragging) { _, state, _ in
                            state = true
                        }
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            var newX = (position.x == 0 ? 20 : position.x) + value.translation.width
                            var newY = position.y + value.translation.height

                            let padding: CGFloat = 20
                            newX = max(padding, min(geometry.size.width - padding, newX))
                            newY = max(padding + 100, min(geometry.size.height - padding - 100, newY))

                            // 吸附到左右邊緣
                            if newX < geometry.size.width / 2 {
                                newX = padding
                            } else {
                                newX = geometry.size.width - padding
                            }

                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                position = CGPoint(x: newX, y: newY)
                                dragOffset = .zero
                            }
                        }
                )
            }
        }
        .ignoresSafeArea()
    }

    private func closeMenu() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            isExpanded = false
            selectedCategory = nil
        }
    }

    private func calculateMenuPosition(geometry: GeometryProxy) -> CGPoint {
        let buttonX = position.x == 0 ? 20 : position.x + dragOffset.width
        let buttonY = position.y + dragOffset.height

        let menuHeight: CGFloat = 140
        var menuY = buttonY

        if buttonY < geometry.size.height / 2 {
            menuY = buttonY + menuHeight / 2 + 30
        } else {
            menuY = buttonY - menuHeight / 2 - 30
        }

        var menuX: CGFloat
        if buttonX < geometry.size.width / 2 {
            menuX = buttonX + 70
        } else {
            menuX = buttonX - 70
        }

        return CGPoint(x: menuX, y: menuY)
    }
}

/// 主選單按鈕
struct MainMenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: 90)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 子選單按鈕
struct SubMenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(width: 100)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 跨客戶搜尋視圖

/// 結構型商品跨客戶搜尋
struct CrossClientStructuredProductView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client?  // ⭐️ 可選的客戶參數，如果有則只顯示該客戶的商品

    @FetchRequest private var allProducts: FetchedResults<StructuredProduct>

    @State private var searchText = ""
    @State private var sortByClient = true  // ⭐️ 改為預設按客戶分組
    @State private var isUpdatingPrices = false
    @State private var showingPriceUpdateAlert = false
    @State private var priceUpdateMessage = ""
    @State private var editingProduct: StructuredProduct?  // ⭐️ 追蹤要編輯的商品

    // 出場相關狀態
    @State private var showingExitCategoryDialog = false  // 顯示分類選擇對話框
    @State private var showingExitDetailsSheet = false  // 顯示出場詳細資料表單
    @State private var showingNewExitCategoryDialog = false  // 顯示新增分類對話框
    @State private var exitingProductCode: String?  // 要出場的商品代碼
    @State private var exitingClientName: String?  // 要出場的客戶名稱（按客戶模式使用）
    @State private var selectedExitCategory = ""  // 選擇的出場分類
    @State private var newExitCategoryName = ""  // 新分類名稱
    @State private var exitDate = Date()  // 出場日期
    @State private var holdingMonths = ""  // 持有月數
    @State private var actualReturnPercentage = ""  // 實際收益%
    @AppStorage("structuredExitCategories") private var exitCategoriesData: Data = Data()  // 儲存自訂分類

    // ⭐️ 初始化，根據是否有 client 參數來設定 FetchRequest
    init(client: Client? = nil) {
        self.client = client

        if let client = client {
            // 如果有指定客戶，只顯示該客戶的商品
            _allProducts = FetchRequest<StructuredProduct>(
                sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
                predicate: NSPredicate(format: "isExited == NO AND client == %@", client),
                animation: .default
            )
        } else {
            // 如果沒有指定客戶，顯示所有商品
            _allProducts = FetchRequest<StructuredProduct>(
                sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
                predicate: NSPredicate(format: "isExited == NO"),
                animation: .default
            )
        }
    }

    var body: some View {
        NavigationView {
            List {
                if sortByClient {
                    // 按客戶名稱分組
                    ForEach(groupedByClient.keys.sorted(), id: \.self) { clientName in
                        Section(header: HStack {
                            Text(clientName).font(.headline)
                            Spacer()
                            HStack(spacing: 8) {
                                Text("\(groupedByClient[clientName]?.count ?? 0) 筆")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                // 出場按鈕
                                Button(action: {
                                    exitingClientName = clientName
                                    exitingProductCode = nil
                                    showingExitCategoryDialog = true
                                }) {
                                    Text("出場")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }) {
                            ForEach(groupedByClient[clientName] ?? [], id: \.self) { product in
                                productRow(product: product, showClient: false)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingProduct = product
                                    }
                            }
                        }
                    }
                } else {
                    // 按商品代號分組
                    ForEach(groupedByProductCode.keys.sorted(), id: \.self) { code in
                        Section(header: HStack {
                            Text(code).font(.headline)
                            Spacer()
                            HStack(spacing: 8) {
                                Text("\(groupedByProductCode[code]?.count ?? 0) 筆")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("$\(calculateTotalAmount(for: code))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                // 出場按鈕
                                Button(action: {
                                    exitingProductCode = code
                                    showingExitCategoryDialog = true
                                }) {
                                    Text("出場")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }) {
                            // 空白商品代號：個別顯示（因為標的可能不同）
                            if code == "空白" {
                                ForEach(groupedByProductCode[code] ?? [], id: \.self) { product in
                                    productRow(product: product, showClient: true)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            editingProduct = product
                                        }
                                }
                            } else {
                                // 有商品代號：共同資訊 + 客戶列表
                                if let firstProduct = groupedByProductCode[code]?.first {
                                    VStack(alignment: .leading, spacing: 6) {
                                        // 第一行：股票與距離出場%
                                        let targetInfos = getTargetInfos(for: firstProduct)
                                        if !targetInfos.isEmpty {
                                            HStack(spacing: 8) {
                                                ForEach(targetInfos.indices, id: \.self) { index in
                                                    let info = targetInfos[index]
                                                    // ⭐️ 改為上下排列（VStack）讓標的名稱和%分開顯示
                                                    VStack(spacing: 1) {
                                                        Text(info.target)
                                                            .font(.caption2)
                                                            .foregroundColor(.primary)
                                                        Text(info.distance)
                                                            .font(.caption2)
                                                            .foregroundColor(getDistanceColor(info.distance))
                                                    }
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 2)
                                                    .background(Color.gray.opacity(0.1))
                                                    .cornerRadius(3)
                                                }
                                                Spacer()
                                            }
                                        }

                                        // 第二行：利率、發行日、到期日
                                        HStack {
                                            if let rate = firstProduct.interestRate, !rate.isEmpty {
                                                let rateText = rate.contains("%") ? rate : "\(rate)%"
                                                Text("利率: \(rateText)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            if let issueDate = firstProduct.issueDate, !issueDate.isEmpty {
                                                Text("發行: \(issueDate)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }

                                            if let finalDate = firstProduct.finalValuationDate, !finalDate.isEmpty {
                                                Text("到期: \(finalDate)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        // 第三行：KO、PUT、KI
                                        HStack {
                                            if let ko = firstProduct.koPercentage, !ko.isEmpty {
                                                let koText = ko.contains("%") ? ko : "\(ko)%"
                                                Text("KO: \(koText)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }

                                            if let put = firstProduct.putPercentage, !put.isEmpty {
                                                let putText = put.contains("%") ? put : "\(put)%"
                                                Text("PUT: \(putText)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .padding(.leading, 8)
                                            }

                                            // ⭐️ KI 緊跟在 PUT 右邊
                                            if let ki = firstProduct.kiPercentage, !ki.isEmpty {
                                                let kiText = ki.contains("%") ? ki : "\(ki)%"
                                                Text("KI: \(kiText)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .padding(.leading, 8)
                                            }

                                            Spacer()
                                        }
                                    }
                                    .padding(.vertical, 4)

                                    // 客戶列表區塊（統一藍色背景）
                                    VStack(spacing: 0) {
                                        ForEach(groupedByProductCode[code] ?? [], id: \.self) { product in
                                            HStack {
                                                Text(product.client?.name ?? "未知客戶")
                                                    .font(.system(size: 14))

                                                Spacer()

                                                // 申購金額 + 鉛筆圖示
                                                if let amount = product.transactionAmount, !amount.isEmpty {
                                                    let formattedAmount = formatWithThousandSeparator(amount)
                                                    HStack(spacing: 4) {
                                                        Text("$\(formattedAmount)")
                                                            .font(.system(size: 14))
                                                            .foregroundColor(.secondary)

                                                        Image(systemName: "pencil")
                                                            .font(.system(size: 13))
                                                            .foregroundColor(.blue.opacity(0.7))
                                                    }
                                                }
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                editingProduct = product
                                            }

                                            // 分隔線（最後一個不顯示）
                                            if product != groupedByProductCode[code]?.last {
                                                Divider()
                                                    .padding(.leading, 12)
                                            }
                                        }
                                    }
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(8)
                                    .padding(.top, 6)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜尋標的代碼")
            .navigationTitle("結構型商品庫存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("排序", selection: $sortByClient) {
                        Text("按商品").tag(false)
                        Text("按客戶").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: updateAllPrices) {
                            if isUpdatingPrices {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(isUpdatingPrices)

                        Button("關閉") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("股價更新", isPresented: $showingPriceUpdateAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(priceUpdateMessage)
            }
            .sheet(item: $editingProduct) { product in
                BatchAddStructuredProductView(editingProduct: product)
                    .environment(\.managedObjectContext, viewContext)
            }
            .confirmationDialog("選擇出場分類", isPresented: $showingExitCategoryDialog, titleVisibility: .visible) {
                ForEach(categoriesWithClientInfo) { info in
                    Button(info.displayText) {
                        selectedExitCategory = info.category
                        showingExitDetailsSheet = true
                    }
                }

                Button("新增分類（自定義）") {
                    showingNewExitCategoryDialog = true
                }

                Button("取消", role: .cancel) { }
            } message: {
                if let code = exitingProductCode {
                    let count = groupedByProductCode[code]?.count ?? 0
                    Text("將 \(code) 商品代碼下的 \(count) 個客戶移至已出場\n\n如客戶沒有該分類會自動新建")
                } else if let clientName = exitingClientName {
                    let count = groupedByClient[clientName]?.count ?? 0
                    Text("將 \(clientName) 的 \(count) 個商品移至已出場\n\n如客戶沒有該分類會自動新建")
                }
            }
            .alert("新增出場分類", isPresented: $showingNewExitCategoryDialog) {
                TextField("自定義分類名稱", text: $newExitCategoryName)
                Button("取消", role: .cancel) {
                    newExitCategoryName = ""
                }
                Button("確定") {
                    if !newExitCategoryName.isEmpty {
                        addNewExitCategory(newExitCategoryName)
                        selectedExitCategory = newExitCategoryName
                        newExitCategoryName = ""
                        showingExitDetailsSheet = true
                    }
                }
            } message: {
                Text("請輸入自定義分類名稱")
            }
            .sheet(isPresented: $showingExitDetailsSheet) {
                exitDetailsSheet
            }
        }
    }

    // 出場詳細資料表單
    private var exitDetailsSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("出場資訊")) {
                    if let code = exitingProductCode {
                        HStack {
                            Text("商品代碼")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(code)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("客戶數量")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(groupedByProductCode[code]?.count ?? 0) 個客戶")
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("出場分類")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(selectedExitCategory)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    } else if let clientName = exitingClientName {
                        HStack {
                            Text("客戶名稱")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(clientName)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("商品數量")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(groupedByClient[clientName]?.count ?? 0) 筆")
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("出場分類")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(selectedExitCategory)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Section(header: Text("出場日期")) {
                    DatePicker("出場日", selection: $exitDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                Section(header: Text("持有月數"), footer: Text("⚠️ 請注意：這裡輸入的是月數，不是天數")) {
                    TextField("持有月數", text: $holdingMonths)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("實際收益%"), footer: suggestedReturnMessage) {
                    TextField("實際收益%", text: $actualReturnPercentage)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("實質收益預覽")) {
                    ForEach(calculateRealProfits(), id: \.clientName) { profitInfo in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profitInfo.clientName)
                                .font(.headline)
                            HStack {
                                Text("交易金額：")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("$\(profitInfo.transactionAmount)")
                            }
                            HStack {
                                Text("實質收益：")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("$\(profitInfo.realProfit)")
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("批量出場")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        resetExitForm()
                        showingExitDetailsSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("確認出場") {
                        confirmBatchMoveToExited()
                        showingExitDetailsSheet = false
                    }
                    .disabled(holdingMonths.isEmpty || actualReturnPercentage.isEmpty)
                }
            }
        }
    }

    // 建議收益訊息
    private var suggestedReturnMessage: Text {
        // 取得產品列表
        let products: [StructuredProduct]
        if let code = exitingProductCode {
            products = groupedByProductCode[code] ?? []
        } else if let clientName = exitingClientName {
            products = groupedByClient[clientName] ?? []
        } else {
            return Text("")
        }

        if let firstProduct = products.first,
           let monthlyRate = firstProduct.monthlyRate,
           !monthlyRate.isEmpty,
           let months = Double(holdingMonths.replacingOccurrences(of: ",", with: "")) {
            let cleanRate = monthlyRate.replacingOccurrences(of: "%", with: "")
            if let rate = Double(cleanRate) {
                let suggestedReturn = rate * months
                return Text("💡 建議收益：\(String(format: "%.2f", suggestedReturn))%（月利率 \(monthlyRate) × \(months) 個月）")
            }
        }
        return Text("")
    }

    // 計算實質收益
    private func calculateRealProfits() -> [(clientName: String, transactionAmount: String, realProfit: String)] {
        // 取得產品列表
        let products: [StructuredProduct]
        if let code = exitingProductCode {
            products = groupedByProductCode[code] ?? []
        } else if let clientName = exitingClientName {
            products = groupedByClient[clientName] ?? []
        } else {
            return []
        }

        guard let returnPercentage = Double(actualReturnPercentage.replacingOccurrences(of: ",", with: "")) else {
            return []
        }

        return products.map { product in
            let clientName = product.client?.name ?? "未知客戶"
            let amountStr = product.transactionAmount ?? "0"
            let cleanAmount = amountStr.replacingOccurrences(of: ",", with: "")
            let amount = Double(cleanAmount) ?? 0
            let realProfit = amount * returnPercentage / 100

            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2

            return (
                clientName: clientName,
                transactionAmount: formatter.string(from: NSNumber(value: amount)) ?? "0",
                realProfit: formatter.string(from: NSNumber(value: realProfit)) ?? "0"
            )
        }
    }

    // 重置出場表單
    private func resetExitForm() {
        exitDate = Date()
        holdingMonths = ""
        actualReturnPercentage = ""
        selectedExitCategory = ""
        exitingProductCode = nil
        exitingClientName = nil
    }

    // 商品行視圖
    @ViewBuilder
    private func productRow(product: StructuredProduct, showClient: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // 如果是按客戶排序，顯示客戶名
            if showClient {
                Text(product.client?.name ?? "未知客戶")
                    .font(.system(size: 15, weight: .semibold))
            }

            // 第一行：股票與距離出場%
            let targetInfos = getTargetInfos(for: product)
            if !targetInfos.isEmpty {
                HStack(spacing: 8) {
                    ForEach(targetInfos, id: \.target) { info in
                        // ⭐️ 改為上下排列（VStack）讓標的名稱和%分開顯示
                        VStack(spacing: 1) {
                            Text(info.target)
                                .font(.caption2)
                                .foregroundColor(.primary)
                            Text(info.distance)
                                .font(.caption2)
                                .foregroundColor(getDistanceColor(info.distance))
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(3)
                    }
                    Spacer()
                }
            }

            // 第二行：金額、利率
            HStack {
                if let amount = product.transactionAmount, !amount.isEmpty {
                    let formattedAmount = formatWithThousandSeparator(amount)
                    Text("金額: \(formattedAmount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let rate = product.interestRate, !rate.isEmpty {
                    let rateText = rate.contains("%") ? rate : "\(rate)%"
                    Text("利率: \(rateText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 第三行：發行日、月利率
            HStack {
                if let issueDate = product.issueDate, !issueDate.isEmpty {
                    Text("發行: \(issueDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let monthlyRate = product.monthlyRate, !monthlyRate.isEmpty {
                    let rateText = monthlyRate.contains("%") ? monthlyRate : "\(monthlyRate)%"
                    Text("月利率: \(rateText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 第四行：到期日、月領息
            HStack {
                if let finalDate = product.finalValuationDate, !finalDate.isEmpty {
                    Text("到期: \(finalDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 計算月領息：交易金額 × 月利率
                if let amount = product.transactionAmount, !amount.isEmpty,
                   let monthlyRate = product.monthlyRate, !monthlyRate.isEmpty {
                    let cleanedAmount = amount.replacingOccurrences(of: ",", with: "")
                    let cleanedRate = monthlyRate.replacingOccurrences(of: "%", with: "")
                    if let amountValue = Double(cleanedAmount),
                       let rateValue = Double(cleanedRate) {
                        let monthlyInterest = amountValue * rateValue / 100
                        let formattedInterest = formatWithThousandSeparator(String(format: "%.0f", monthlyInterest))
                        Text("月領息: $\(formattedInterest)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // 第五行：KO、PUT、KI（靠左）
            HStack {
                if let ko = product.koPercentage, !ko.isEmpty {
                    let koText = ko.contains("%") ? ko : "\(ko)%"
                    Text("KO: \(koText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let put = product.putPercentage, !put.isEmpty {
                    let putText = put.contains("%") ? put : "\(put)%"
                    Text("PUT: \(putText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }

                // ⭐️ KI 緊跟在 PUT 右邊
                if let ki = product.kiPercentage, !ki.isEmpty {
                    let kiText = ki.contains("%") ? ki : "\(ki)%"
                    Text("KI: \(kiText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    // 取得標的與距離出場%資訊
    private func getTargetInfos(for product: StructuredProduct) -> [(target: String, distance: String)] {
        var infos: [(String, String)] = []

        if let t1 = product.target1, !t1.isEmpty {
            let d1 = product.distanceToExit1 ?? ""
            infos.append((t1, d1.isEmpty ? "-" : d1))
        }
        if let t2 = product.target2, !t2.isEmpty {
            let d2 = product.distanceToExit2 ?? ""
            infos.append((t2, d2.isEmpty ? "-" : d2))
        }
        if let t3 = product.target3, !t3.isEmpty {
            let d3 = product.distanceToExit3 ?? ""
            infos.append((t3, d3.isEmpty ? "-" : d3))
        }
        if let t4 = product.target4, !t4.isEmpty {
            let d4 = product.distanceToExit4 ?? ""
            infos.append((t4, d4.isEmpty ? "-" : d4))
        }

        return infos
    }

    // 取得期初價格
    private func getInitialPrice(for product: StructuredProduct, index: Int) -> String {
        switch index {
        case 1: return product.initialPrice1 ?? "-"
        case 2: return product.initialPrice2 ?? "-"
        case 3: return product.initialPrice3 ?? "-"
        case 4: return product.initialPrice4 ?? "-"
        default: return "-"
        }
    }

    // 根據距離出場%設定顏色
    private func getDistanceColor(_ distance: String) -> Color {
        guard let value = Double(distance.replacingOccurrences(of: "%", with: "")) else {
            return .secondary
        }
        if value < 100 {
            return .red
        } else {
            return .secondary
        }
    }

    // 格式化數字加千分位
    private func formatWithThousandSeparator(_ value: String) -> String {
        let cleaned = value.replacingOccurrences(of: ",", with: "")
        guard let number = Double(cleaned) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    // 計算特定商品代號的交易金額總和
    private func calculateTotalAmount(for productCode: String) -> String {
        guard let products = groupedByProductCode[productCode] else { return "0" }

        var total: Double = 0
        for product in products {
            if let amountStr = product.transactionAmount,
               !amountStr.isEmpty {
                let cleaned = amountStr.replacingOccurrences(of: ",", with: "")
                if let amount = Double(cleaned) {
                    total += amount
                }
            }
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: total)) ?? "0"
    }

    // 更新所有股價
    private func updateAllPrices() {
        isUpdatingPrices = true

        // 收集所有標的代碼
        var allSymbols: Set<String> = []
        for product in allProducts {
            if let t1 = product.target1, !t1.isEmpty { allSymbols.insert(t1.uppercased()) }
            if let t2 = product.target2, !t2.isEmpty { allSymbols.insert(t2.uppercased()) }
            if let t3 = product.target3, !t3.isEmpty { allSymbols.insert(t3.uppercased()) }
            if let t4 = product.target4, !t4.isEmpty { allSymbols.insert(t4.uppercased()) }
        }

        if allSymbols.isEmpty {
            priceUpdateMessage = "沒有找到標的資料"
            showingPriceUpdateAlert = true
            isUpdatingPrices = false
            return
        }

        Task {
            let prices = await StockPriceService.shared.fetchMultipleStockPrices(symbols: Array(allSymbols))

            await MainActor.run {
                var successCount = 0
                var updatedSymbols: Set<String> = []

                // 更新每個商品的現價和距離出場%
                for product in allProducts {
                    // 更新現價
                    if let t1 = product.target1, !t1.isEmpty, let price = prices[t1.uppercased()] {
                        product.currentPrice1 = price
                        updateDistanceToExit(product: product, targetIndex: 1, currentPrice: price)
                        updatedSymbols.insert(t1.uppercased())
                    }
                    if let t2 = product.target2, !t2.isEmpty, let price = prices[t2.uppercased()] {
                        product.currentPrice2 = price
                        updateDistanceToExit(product: product, targetIndex: 2, currentPrice: price)
                        updatedSymbols.insert(t2.uppercased())
                    }
                    if let t3 = product.target3, !t3.isEmpty, let price = prices[t3.uppercased()] {
                        product.currentPrice3 = price
                        updateDistanceToExit(product: product, targetIndex: 3, currentPrice: price)
                        updatedSymbols.insert(t3.uppercased())
                    }
                    if let t4 = product.target4, !t4.isEmpty, let price = prices[t4.uppercased()] {
                        product.currentPrice4 = price
                        updateDistanceToExit(product: product, targetIndex: 4, currentPrice: price)
                        updatedSymbols.insert(t4.uppercased())
                    }
                }

                successCount = updatedSymbols.count

                // 儲存
                do {
                    try viewContext.save()
                    priceUpdateMessage = "成功更新 \(successCount) 檔股票"
                } catch {
                    priceUpdateMessage = "儲存失敗: \(error.localizedDescription)"
                }

                showingPriceUpdateAlert = true
                isUpdatingPrices = false
            }
        }
    }

    // 計算距離出場%
    private func updateDistanceToExit(product: StructuredProduct, targetIndex: Int, currentPrice: String) {
        guard let current = Double(currentPrice) else { return }

        let initialPrice: String?
        switch targetIndex {
        case 1: initialPrice = product.initialPrice1
        case 2: initialPrice = product.initialPrice2
        case 3: initialPrice = product.initialPrice3
        case 4: initialPrice = product.initialPrice4
        default: return
        }

        guard let initial = initialPrice, let initialValue = Double(initial), initialValue > 0 else { return }

        // 距離出場% = (現價 / 期初價) * 100
        let distance = (current / initialValue) * 100
        let distanceStr = String(format: "%.2f%%", distance)

        switch targetIndex {
        case 1: product.distanceToExit1 = distanceStr
        case 2: product.distanceToExit2 = distanceStr
        case 3: product.distanceToExit3 = distanceStr
        case 4: product.distanceToExit4 = distanceStr
        default: break
        }
    }

    // 按商品代號分組
    private var groupedByProductCode: [String: [StructuredProduct]] {
        let filtered = allProducts.filter { product in
            if searchText.isEmpty { return true }
            let searchContent = [product.productCode, product.target1, product.target2, product.target3, product.target4]
                .compactMap { $0 }
                .joined(separator: " ")
            return searchContent.localizedCaseInsensitiveContains(searchText)
        }

        var groups: [String: [StructuredProduct]] = [:]

        for product in filtered {
            // 只使用商品代號作為分組鍵，空白則顯示「空白」
            let key = product.productCode?.isEmpty == false ? product.productCode! : "空白"

            if groups[key] == nil {
                groups[key] = []
            }
            groups[key]?.append(product)
        }

        return groups
    }

    // 按客戶分組
    private var groupedByClient: [String: [StructuredProduct]] {
        let filtered = allProducts.filter { product in
            if searchText.isEmpty { return true }
            let targets = [product.target1, product.target2, product.target3, product.target4]
                .compactMap { $0 }
                .joined(separator: " ")
            return targets.localizedCaseInsensitiveContains(searchText)
        }

        var groups: [String: [StructuredProduct]] = [:]

        for product in filtered {
            let clientName = product.client?.name ?? "未知客戶"
            if groups[clientName] == nil {
                groups[clientName] = []
            }
            groups[clientName]?.append(product)
        }

        return groups
    }

    // 分類及客戶信息結構
    private struct CategoryInfo: Identifiable {
        let id = UUID()
        let category: String
        let clientsWithCategory: [String]  // 已有此分類的客戶名稱
        let clientsWithoutCategory: [String]  // 沒有此分類的客戶名稱

        var displayText: String {
            let hasCount = clientsWithCategory.count
            let newCount = clientsWithoutCategory.count
            if newCount == 0 {
                return "\(category) (全部客戶已有)"
            } else if hasCount == 0 {
                return "\(category) (全部客戶新增)"
            } else {
                return "\(category) (\(hasCount)客戶有, \(newCount)客戶新增)"
            }
        }
    }

    // 獲取所有可用的出場分類（舊版，保留給其他地方使用）
    private var availableExitCategories: [String] {
        // 從 UserDefaults 載入自訂分類
        if let decoded = try? JSONDecoder().decode([String].self, from: exitCategoriesData) {
            return decoded
        }
        return []
    }

    // 獲取分類及客戶狀態信息
    private var categoriesWithClientInfo: [CategoryInfo] {
        // 取得要出場的產品列表（可能是按商品代碼或按客戶名稱）
        let products: [StructuredProduct]
        if let productCode = exitingProductCode {
            // 按商品模式
            products = groupedByProductCode[productCode] ?? []
        } else if let clientName = exitingClientName {
            // 按客戶模式
            products = groupedByClient[clientName] ?? []
        } else {
            return []
        }

        // 生成年份分類選項
        var categoryInfos: [CategoryInfo] = []

        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())

        // 如果是 11-12 月，往後看 5 年；否則顯示上一年到後 3 年
        let years: [Int]
        if currentMonth >= 11 {
            // 11-12 月：顯示當前年到未來 4 年（共 5 年）
            years = Array(currentYear...(currentYear + 4))
        } else {
            // 1-10 月：顯示上一年到未來 3 年（共 5 年）
            years = Array((currentYear - 1)...(currentYear + 3))
        }

        for year in years {
            let category = String(year)
            var clientsWithCategory: [String] = []
            var clientsWithoutCategory: [String] = []

            for product in products {
                guard let client = product.client else { continue }
                let clientName = client.name ?? "未知客戶"

                // 檢查該客戶是否已有此分類
                let exitedProducts = client.structuredProducts?.filtered(using: NSPredicate(format: "isExited == true")) as? Set<StructuredProduct> ?? []
                let hasCategory = exitedProducts.contains { $0.exitCategory == category }

                if hasCategory {
                    clientsWithCategory.append(clientName)
                } else {
                    clientsWithoutCategory.append(clientName)
                }
            }

            categoryInfos.append(CategoryInfo(
                category: category,
                clientsWithCategory: clientsWithCategory,
                clientsWithoutCategory: clientsWithoutCategory
            ))
        }

        return categoryInfos
    }

    // 新增自訂分類
    private func addNewExitCategory(_ category: String) {
        var categories = availableExitCategories
        if !categories.contains(category) {
            categories.append(category)
            if let encoded = try? JSONEncoder().encode(categories) {
                exitCategoriesData = encoded
            }
        }
    }

    // 批量移至已出場
    private func confirmBatchMoveToExited() {
        // 取得要出場的產品列表
        let products: [StructuredProduct]
        let identifier: String
        if let productCode = exitingProductCode {
            products = groupedByProductCode[productCode] ?? []
            identifier = productCode
        } else if let clientName = exitingClientName {
            products = groupedByClient[clientName] ?? []
            identifier = clientName
        } else {
            return
        }

        guard let returnPercentage = Double(actualReturnPercentage.replacingOccurrences(of: ",", with: "")) else {
            return
        }

        // 格式化出場日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let exitDateStr = dateFormatter.string(from: exitDate)

        // 複製所有產品到已出場區域（不刪除進行中的商品）
        for product in products {
            // 建立一個新的已出場產品，複製原本的資料
            let exitedProduct = StructuredProduct(context: viewContext)
            exitedProduct.client = product.client
            exitedProduct.isExited = true
            exitedProduct.exitCategory = selectedExitCategory

            // 複製所有進行中的欄位資料
            exitedProduct.numberOfTargets = product.numberOfTargets
            exitedProduct.productCode = product.productCode
            exitedProduct.target1 = product.target1
            exitedProduct.target2 = product.target2
            exitedProduct.target3 = product.target3
            exitedProduct.target4 = product.target4
            exitedProduct.strikePrice1 = product.strikePrice1
            exitedProduct.strikePrice2 = product.strikePrice2
            exitedProduct.strikePrice3 = product.strikePrice3
            exitedProduct.strikePrice4 = product.strikePrice4
            exitedProduct.putPercentage = product.putPercentage
            exitedProduct.tradePricingDate = product.tradePricingDate
            exitedProduct.issueDate = product.issueDate
            exitedProduct.finalValuationDate = product.finalValuationDate
            exitedProduct.interestRate = product.interestRate
            exitedProduct.monthlyRate = product.monthlyRate
            exitedProduct.transactionAmount = product.transactionAmount
            exitedProduct.currency = product.currency
            exitedProduct.koPercentage = product.koPercentage
            exitedProduct.kiPercentage = product.kiPercentage

            // 填入用戶輸入的已出場資料
            exitedProduct.exitDate = exitDateStr
            exitedProduct.holdingMonths = holdingMonths
            exitedProduct.actualReturn = actualReturnPercentage

            // 計算實質收益：實際收益% × 交易金額
            let amountStr = product.transactionAmount ?? "0"
            let cleanAmount = amountStr.replacingOccurrences(of: ",", with: "")
            if let amount = Double(cleanAmount) {
                let realProfit = amount * returnPercentage / 100
                exitedProduct.realProfit = String(format: "%.2f", realProfit)
            } else {
                exitedProduct.realProfit = "0"
            }

            exitedProduct.notes = ""

            // ⭐️ 不刪除進行中的商品，只複製到已出場
            // viewContext.delete(product)  // 已移除
        }

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 成功將 \(products.count) 個 \(identifier) 商品複製至已出場（分類：\(selectedExitCategory)）")
        } catch {
            print("❌ 複製至已出場失敗: \(error)")
        }

        // 重置表單
        resetExitForm()
    }
}

/// 美股跨客戶搜尋
struct CrossClientUSStockView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \USStock.name, ascending: true)],
        animation: .default
    )
    private var allStocks: FetchedResults<USStock>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.sortOrder, ascending: true)]
    )
    private var allClients: FetchedResults<Client>

    @State private var searchText = ""
    @State private var isUpdatingPrices = false
    @State private var showingUpdateAlert = false
    @State private var showingPriceUpdateAlert = false
    @State private var priceUpdateMessage = ""

    var body: some View {
        NavigationView {
            List {
                // 按股票代碼分組
                ForEach(groupedStocks.keys.sorted(), id: \.self) { symbol in
                    Section(header: Text(symbol).font(.headline)) {
                        ForEach(groupedStocks[symbol] ?? [], id: \.self) { stock in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(stock.client?.name ?? "未知客戶")
                                        .font(.system(size: 15, weight: .semibold))

                                    Spacer()

                                    Text("\(stock.shares ?? "0") 股")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    // 成本（千分位）
                                    if let costStr = stock.cost, !costStr.isEmpty {
                                        let formattedCost = formatUSStockNumber(costStr)
                                        Text("成本: $\(formattedCost)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    // 現值（千分位）
                                    if let marketValue = stock.marketValue, !marketValue.isEmpty {
                                        let formattedValue = formatUSStockNumber(marketValue)
                                        Text("現值: $\(formattedValue)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    // 報酬率 = (現值 - 成本) / 成本 × 100
                                    if let marketValueStr = stock.marketValue,
                                       let costStr = stock.cost,
                                       let marketValue = Double(marketValueStr),
                                       let cost = Double(costStr),
                                       cost > 0 {
                                        let returnRate = (marketValue - cost) / cost * 100
                                        Text("\(returnRate >= 0 ? "+" : "")\(returnRate, specifier: "%.2f")%")
                                            .font(.caption)
                                            .foregroundColor(returnRate >= 0 ? .green : .red)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜尋股票代碼")
            .navigationTitle("美股庫存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: updateAllPrices) {
                            if isUpdatingPrices {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(isUpdatingPrices)

                        Button(action: { showingUpdateAlert = true }) {
                            Image(systemName: "square.and.arrow.down")
                        }

                        Button("關閉") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("更新月度資產", isPresented: $showingUpdateAlert) {
                Button("取消", role: .cancel) { }
                Button("確定") { updateToMonthlyAsset() }
            } message: {
                Text("將目前美股市值更新到所有客戶的月度資產明細？")
            }
            .alert("股價更新", isPresented: $showingPriceUpdateAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(priceUpdateMessage)
            }
        }
    }

    // 更新所有股價
    private func updateAllPrices() {
        isUpdatingPrices = true

        var allSymbols: Set<String> = []
        for stock in allStocks {
            if let name = stock.name, !name.isEmpty {
                allSymbols.insert(name.uppercased())
            }
        }

        if allSymbols.isEmpty {
            priceUpdateMessage = "沒有找到股票資料"
            showingPriceUpdateAlert = true
            isUpdatingPrices = false
            return
        }

        Task {
            let prices = await StockPriceService.shared.fetchMultipleStockPrices(symbols: Array(allSymbols))

            await MainActor.run {
                var successCount = 0
                for stock in allStocks {
                    if let name = stock.name, let price = prices[name.uppercased()] {
                        stock.currentPrice = price
                        successCount += 1

                        // 計算市值
                        if let sharesStr = stock.shares, let shares = Double(sharesStr), let priceVal = Double(price) {
                            stock.marketValue = String(format: "%.2f", shares * priceVal)
                        }

                        // 計算損益
                        if let costStr = stock.cost, let cost = Double(costStr), let priceVal = Double(price), let sharesStr = stock.shares, let shares = Double(sharesStr) {
                            let profitLoss = (priceVal * shares - cost)
                            stock.profitLoss = String(format: "%.2f", profitLoss)
                            if cost > 0 {
                                let returnRate = profitLoss / cost * 100
                                stock.returnRate = String(format: "%.2f", returnRate)
                            }
                        }
                    }
                }

                do {
                    try viewContext.save()
                    priceUpdateMessage = "成功更新 \(successCount) 檔股票"
                } catch {
                    priceUpdateMessage = "儲存失敗: \(error.localizedDescription)"
                }

                showingPriceUpdateAlert = true
                isUpdatingPrices = false
            }
        }
    }

    // 更新到月度資產明細
    private func updateToMonthlyAsset() {
        // 按客戶分組計算市值總和
        var clientUSStockValues: [Client: Double] = [:]

        for stock in allStocks {
            guard let client = stock.client else { continue }
            let marketValue = Double(stock.marketValue ?? "0") ?? 0
            clientUSStockValues[client, default: 0] += marketValue
        }

        // 更新每個客戶最近的月度資產
        for client in allClients {
            let totalValue = clientUSStockValues[client] ?? 0

            // 找到最近的月度資產記錄
            if let monthlyAssets = client.monthlyAssets as? Set<MonthlyAsset>,
               let latestAsset = monthlyAssets.sorted(by: { ($0.date ?? "") > ($1.date ?? "") }).first {
                latestAsset.usStock = String(format: "%.0f", totalValue)
            }
        }

        do {
            try viewContext.save()
        } catch {
            print("更新月度資產失敗: \(error)")
        }
    }

    // 格式化數字加千分位
    private func formatUSStockNumber(_ value: String) -> String {
        let cleaned = value.replacingOccurrences(of: ",", with: "")
        guard let number = Double(cleaned) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    // 按股票代碼分組
    private var groupedStocks: [String: [USStock]] {
        let filtered = allStocks.filter { stock in
            if searchText.isEmpty { return true }
            return stock.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }

        var groups: [String: [USStock]] = [:]

        for stock in filtered {
            let symbol = stock.name ?? "未知"
            if groups[symbol] == nil {
                groups[symbol] = []
            }
            groups[symbol]?.append(stock)
        }

        return groups
    }
}

/// 台股跨客戶搜尋
struct CrossClientTWStockView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TWStock.name, ascending: true)],
        animation: .default
    )
    private var allStocks: FetchedResults<TWStock>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.sortOrder, ascending: true)]
    )
    private var allClients: FetchedResults<Client>

    @State private var searchText = ""
    @State private var isUpdatingPrices = false
    @State private var showingUpdateAlert = false
    @State private var showingPriceUpdateAlert = false
    @State private var priceUpdateMessage = ""

    var body: some View {
        NavigationView {
            List {
                // 按股票代碼分組
                ForEach(groupedStocks.keys.sorted(), id: \.self) { symbol in
                    Section(header: Text(symbol).font(.headline)) {
                        ForEach(groupedStocks[symbol] ?? [], id: \.self) { stock in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(stock.client?.name ?? "未知客戶")
                                        .font(.system(size: 15, weight: .semibold))

                                    Spacer()

                                    Text("\(stock.shares ?? "0") 股")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    // 成本（千分位）
                                    if let costStr = stock.cost, !costStr.isEmpty {
                                        let formattedCost = formatTWStockNumber(costStr)
                                        Text("成本: $\(formattedCost)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    // 現值（千分位）
                                    if let marketValue = stock.marketValue, !marketValue.isEmpty {
                                        let formattedValue = formatTWStockNumber(marketValue)
                                        Text("現值: $\(formattedValue)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    // 報酬率 = (現值 - 成本) / 成本 × 100
                                    if let marketValueStr = stock.marketValue,
                                       let costStr = stock.cost,
                                       let marketValue = Double(marketValueStr),
                                       let cost = Double(costStr),
                                       cost > 0 {
                                        let returnRate = (marketValue - cost) / cost * 100
                                        Text("\(returnRate >= 0 ? "+" : "")\(returnRate, specifier: "%.2f")%")
                                            .font(.caption)
                                            .foregroundColor(returnRate >= 0 ? .green : .red)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜尋股票代碼")
            .navigationTitle("台股庫存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: updateAllPrices) {
                            if isUpdatingPrices {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(isUpdatingPrices)

                        Button(action: { showingUpdateAlert = true }) {
                            Image(systemName: "square.and.arrow.down")
                        }

                        Button("關閉") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("更新月度資產", isPresented: $showingUpdateAlert) {
                Button("取消", role: .cancel) { }
                Button("確定") { updateToMonthlyAsset() }
            } message: {
                Text("將目前台股市值更新到所有客戶的月度資產明細？")
            }
            .alert("股價更新", isPresented: $showingPriceUpdateAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(priceUpdateMessage)
            }
        }
    }

    // 更新所有股價（台股需要加 .TW 後綴）
    private func updateAllPrices() {
        isUpdatingPrices = true

        var allSymbols: Set<String> = []
        for stock in allStocks {
            if let name = stock.name, !name.isEmpty {
                // 台股需要加 .TW 後綴
                let symbol = name.hasSuffix(".TW") ? name : "\(name).TW"
                allSymbols.insert(symbol.uppercased())
            }
        }

        if allSymbols.isEmpty {
            priceUpdateMessage = "沒有找到股票資料"
            showingPriceUpdateAlert = true
            isUpdatingPrices = false
            return
        }

        Task {
            let prices = await StockPriceService.shared.fetchMultipleStockPrices(symbols: Array(allSymbols))

            await MainActor.run {
                var successCount = 0
                for stock in allStocks {
                    guard let name = stock.name else { continue }
                    let symbol = (name.hasSuffix(".TW") ? name : "\(name).TW").uppercased()

                    if let price = prices[symbol] {
                        stock.currentPrice = price
                        successCount += 1

                        // 計算市值
                        if let sharesStr = stock.shares, let shares = Double(sharesStr), let priceVal = Double(price) {
                            stock.marketValue = String(format: "%.0f", shares * priceVal)
                        }

                        // 計算損益
                        if let costStr = stock.cost, let cost = Double(costStr), let priceVal = Double(price), let sharesStr = stock.shares, let shares = Double(sharesStr) {
                            let profitLoss = (priceVal * shares - cost)
                            stock.profitLoss = String(format: "%.0f", profitLoss)
                            if cost > 0 {
                                let returnRate = profitLoss / cost * 100
                                stock.returnRate = String(format: "%.2f", returnRate)
                            }
                        }
                    }
                }

                do {
                    try viewContext.save()
                    priceUpdateMessage = "成功更新 \(successCount) 檔股票"
                } catch {
                    priceUpdateMessage = "儲存失敗: \(error.localizedDescription)"
                }

                showingPriceUpdateAlert = true
                isUpdatingPrices = false
            }
        }
    }

    // 格式化數字加千分位
    private func formatTWStockNumber(_ value: String) -> String {
        let cleaned = value.replacingOccurrences(of: ",", with: "")
        guard let number = Double(cleaned) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    // 更新到月度資產明細
    private func updateToMonthlyAsset() {
        // 按客戶分組計算市值總和
        var clientTWStockValues: [Client: Double] = [:]

        for stock in allStocks {
            guard let client = stock.client else { continue }
            let marketValue = Double(stock.marketValue ?? "0") ?? 0
            clientTWStockValues[client, default: 0] += marketValue
        }

        // 更新每個客戶最近的月度資產
        for client in allClients {
            let totalValue = clientTWStockValues[client] ?? 0

            // 找到最近的月度資產記錄
            if let monthlyAssets = client.monthlyAssets as? Set<MonthlyAsset>,
               let latestAsset = monthlyAssets.sorted(by: { ($0.date ?? "") > ($1.date ?? "") }).first {
                latestAsset.taiwanStock = String(format: "%.0f", totalValue)
            }
        }

        do {
            try viewContext.save()
        } catch {
            print("更新月度資產失敗: \(error)")
        }
    }

    // 按股票代碼分組
    private var groupedStocks: [String: [TWStock]] {
        let filtered = allStocks.filter { stock in
            if searchText.isEmpty { return true }
            return stock.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }

        var groups: [String: [TWStock]] = [:]

        for stock in filtered {
            let symbol = stock.name ?? "未知"
            if groups[symbol] == nil {
                groups[symbol] = []
            }
            groups[symbol]?.append(stock)
        }

        return groups
    }
}

// MARK: - 批次新增視圖

/// 批次新增股票資料（美股/台股用）
struct BatchAddStockView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default
    )
    private var allClients: FetchedResults<Client>

    let stockType: String // "us", "tw"

    // 步驟控制
    @State private var currentStep = 1 // 1: 選客戶, 2: 輸入股票資訊及各客戶股數

    // 步驟 1: 客戶選擇
    @State private var selectedClients: Set<NSManagedObjectID> = []

    // 步驟 2: 共同欄位及各客戶股數
    @State private var stockName: String = ""
    @State private var costPerShare: String = ""
    @State private var clientShares: [NSManagedObjectID: String] = [:]

    var body: some View {
        NavigationView {
            Group {
                if currentStep == 1 {
                    step1SelectClients
                } else {
                    step2StockInfoAndShares
                }
            }
        }
    }

    // MARK: - 步驟 1: 選擇客戶
    private var step1SelectClients: some View {
        List {
            Section(header: Text("選擇要新增的客戶")) {
                ForEach(allClients, id: \.objectID) { client in
                    HStack {
                        Text(client.name ?? "未知客戶")
                            .font(.system(size: 16))

                        Spacer()

                        if selectedClients.contains(client.objectID) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedClients.contains(client.objectID) {
                            selectedClients.remove(client.objectID)
                        } else {
                            selectedClients.insert(client.objectID)
                        }
                    }
                }
            }
        }
        .navigationTitle(stockTypeTitle + "新增 (1/2)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("下一步") {
                    currentStep = 2
                }
                .disabled(selectedClients.isEmpty)
            }
        }
    }

    // MARK: - 步驟 2: 輸入股票資訊及各客戶股數
    private var step2StockInfoAndShares: some View {
        List {
            // 股票共同資訊
            Section(header: Text("股票資訊（所有客戶共用）")) {
                HStack {
                    Text("股票代號")
                        .frame(width: 100, alignment: .leading)
                    TextField("例如: AAPL", text: $stockName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                }

                HStack {
                    Text("成本單價")
                        .frame(width: 100, alignment: .leading)
                    TextField("買入價格", text: $costPerShare)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }

            // 已選擇客戶 - 輸入股數及即時計算
            Section(header: Text("已選擇客戶"), footer: Text("輸入股數後將自動計算總成本\n\n⚠️ 最終成本不含手續費，請記得在明細頁面調整")) {
                ForEach(allClients.filter { selectedClients.contains($0.objectID) }, id: \.objectID) { client in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(client.name ?? "未知客戶")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(width: 100, alignment: .leading)

                            TextField("股數", text: Binding(
                                get: { clientShares[client.objectID] ?? "" },
                                set: { clientShares[client.objectID] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 即時計算預覽
                        if let sharesStr = clientShares[client.objectID],
                           !sharesStr.isEmpty,
                           let shares = Double(sharesStr),
                           let costPrice = Double(costPerShare) {

                            let cost = shares * costPrice
                            let currencySymbol = stockType == "us" ? "USD" : "TWD"

                            HStack {
                                Text("總成本:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.2f %@", cost, currencySymbol))
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(stockTypeTitle + "新增 (2/2)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") {
                    currentStep = 1
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    saveData()
                    dismiss()
                }
                .disabled(stockName.isEmpty || costPerShare.isEmpty || !allClientsHaveShares())
            }
        }
    }

    // MARK: - Helper Functions
    private var stockTypeTitle: String {
        switch stockType {
        case "us": return "美股"
        case "tw": return "台股"
        default: return ""
        }
    }

    private func allClientsHaveShares() -> Bool {
        for clientID in selectedClients {
            if let sharesStr = clientShares[clientID], !sharesStr.isEmpty {
                continue
            } else {
                return false
            }
        }
        return true
    }

    private func saveData() {
        guard let costPrice = Double(costPerShare) else {
            print("❌ 價格格式錯誤")
            return
        }

        // 設定幣別
        let currency = stockType == "us" ? "USD" : "TWD"

        for client in allClients {
            guard selectedClients.contains(client.objectID),
                  let sharesStr = clientShares[client.objectID],
                  !sharesStr.isEmpty,
                  let shares = Double(sharesStr) else { continue }

            // 計算欄位（初始時當前價格 = 成本單價，之後可透過刷新更新）
            let cost = shares * costPrice
            let marketValue = cost // 初始市值等於成本
            let profitLoss: Double = 0 // 初始損益為 0
            let returnRate: Double = 0 // 初始報酬率為 0

            switch stockType {
            case "us":
                let stock = USStock(context: viewContext)
                stock.client = client
                stock.name = stockName
                stock.shares = String(format: "%.0f", shares)
                stock.costPerShare = String(format: "%.2f", costPrice)
                stock.currentPrice = String(format: "%.2f", costPrice) // 初始設為成本價
                stock.cost = String(format: "%.2f", cost)
                stock.marketValue = String(format: "%.2f", marketValue)
                stock.profitLoss = String(format: "%.2f", profitLoss)
                stock.returnRate = String(format: "%.2f%%", returnRate)
                stock.currency = currency
                stock.createdDate = Date()

            case "tw":
                let stock = TWStock(context: viewContext)
                stock.client = client
                stock.name = stockName
                stock.shares = String(format: "%.0f", shares)
                stock.costPerShare = String(format: "%.2f", costPrice)
                stock.currentPrice = String(format: "%.2f", costPrice) // 初始設為成本價
                stock.cost = String(format: "%.2f", cost)
                stock.marketValue = String(format: "%.2f", marketValue)
                stock.profitLoss = String(format: "%.2f", profitLoss)
                stock.returnRate = String(format: "%.2f%%", returnRate)
                stock.currency = currency
                stock.createdDate = Date()

            default:
                break
            }
        }

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 成功新增 \(selectedClients.count) 筆\(stockTypeTitle)記錄")
        } catch {
            print("❌ 儲存失敗: \(error)")
        }
    }
}

// MARK: - 結構型商品批次新增

/// 結構型商品批次新增視圖
struct BatchAddStructuredProductView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default
    )
    private var allClients: FetchedResults<Client>

    // 預選客戶（可選）
    let preselectedClient: Client?

    // ⭐️ 編輯模式（可選）
    let editingProduct: StructuredProduct?

    // 步驟控制
    @State private var currentStep = 1 // 1: 選客戶, 2: 輸入金額, 3: 選標的數, 4: 輸入詳細資料

    // 客戶選擇
    @State private var selectedClients: Set<NSManagedObjectID> = []
    @State private var clientAmounts: [NSManagedObjectID: String] = [:]

    // 初始化
    init(preselectedClient: Client? = nil, editingProduct: StructuredProduct? = nil) {
        self.preselectedClient = preselectedClient
        self.editingProduct = editingProduct

        // ⭐️ 如果是編輯模式,直接跳到步驟 4 並預填所有資料
        if let product = editingProduct {
            _currentStep = State(initialValue: 4)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            // 基本資訊
            _numberOfTargets = State(initialValue: product.numberOfTargets)
            _productCode = State(initialValue: product.productCode ?? "")
            _currency = State(initialValue: product.currency ?? "USD")
            _interestRate = State(initialValue: product.interestRate ?? "")
            _monthlyRate = State(initialValue: product.monthlyRate ?? "")
            _koPercentage = State(initialValue: product.koPercentage ?? "")
            _putPercentage = State(initialValue: product.putPercentage ?? "")
            _kiPercentage = State(initialValue: product.kiPercentage ?? "")

            // 標的資訊
            _target1 = State(initialValue: product.target1 ?? "")
            _target2 = State(initialValue: product.target2 ?? "")
            _target3 = State(initialValue: product.target3 ?? "")
            _target4 = State(initialValue: product.target4 ?? "")

            // 初始價格
            _initialPrice1 = State(initialValue: product.initialPrice1 ?? "")
            _initialPrice2 = State(initialValue: product.initialPrice2 ?? "")
            _initialPrice3 = State(initialValue: product.initialPrice3 ?? "")
            _initialPrice4 = State(initialValue: product.initialPrice4 ?? "")

            // 履約價格
            _strikePrice1 = State(initialValue: product.strikePrice1 ?? "")
            _strikePrice2 = State(initialValue: product.strikePrice2 ?? "")
            _strikePrice3 = State(initialValue: product.strikePrice3 ?? "")
            _strikePrice4 = State(initialValue: product.strikePrice4 ?? "")

            // 保護價格
            _protectionPrice1 = State(initialValue: product.protectionPrice1 ?? "")
            _protectionPrice2 = State(initialValue: product.protectionPrice2 ?? "")
            _protectionPrice3 = State(initialValue: product.protectionPrice3 ?? "")
            _protectionPrice4 = State(initialValue: product.protectionPrice4 ?? "")

            // 日期 - 支援多種格式
            if let tradeDateStr = product.tradePricingDate,
               let tradeDate = Self.parseFlexibleDate(tradeDateStr) {
                _tradePricingDate = State(initialValue: tradeDate)
            }
            if let issueDateStr = product.issueDate,
               let issueD = Self.parseFlexibleDate(issueDateStr) {
                _issueDate = State(initialValue: issueD)
            }
            if let finalDateStr = product.finalValuationDate,
               let finalDate = Self.parseFlexibleDate(finalDateStr) {
                _finalValuationDate = State(initialValue: finalDate)
            }

            // 交易金額和選中的客戶
            if let client = product.client {
                _clientAmounts = State(initialValue: [client.objectID: product.transactionAmount ?? ""])
                _selectedClients = State(initialValue: [client.objectID])
            }
        }
    }

    // 在視圖出現時預選客戶
    private func preselectClientIfNeeded() {
        if let client = preselectedClient, selectedClients.isEmpty {
            selectedClients.insert(client.objectID)
        }
    }

    // 標的數量
    @State private var numberOfTargets: Int16 = 1

    // 結構型商品資料
    @State private var tradePricingDate = Date()
    @State private var target1 = ""
    @State private var target2 = ""
    @State private var target3 = ""
    @State private var issueDate = Date()
    @State private var finalValuationDate = Date()
    @State private var useClosingPrice = true  // true = 收盤價, false = 開盤價
    @State private var dayOffset = 0  // 0 = 前一天, 1 = 前兩天
    @State private var isFetchingPrices = false
    @State private var priceDate = ""  // 價格日期
    @State private var initialPrice1 = ""
    @State private var initialPrice2 = ""
    @State private var initialPrice3 = ""
    @State private var strikePrice1 = ""
    @State private var strikePrice2 = ""
    @State private var strikePrice3 = ""
    @State private var strikePrice4 = ""
    @State private var target4 = ""
    @State private var initialPrice4 = ""
    @State private var interestRate = ""
    @State private var monthlyRate = ""
    @State private var koPercentage = ""   // KO 百分比
    @State private var putPercentage = ""  // PUT 百分比
    @State private var kiPercentage = ""   // KI 百分比
    @State private var productCode = ""    // 商品代號
    @State private var currency = "USD"    // 幣別

    // 保護價格
    @State private var protectionPrice1 = ""
    @State private var protectionPrice2 = ""
    @State private var protectionPrice3 = ""
    @State private var protectionPrice4 = ""

    // 排序後的客戶列表：預選客戶在最上方
    private var sortedClients: [Client] {
        Array(allClients).sorted { client1, client2 in
            let isClient1Preselected = preselectedClient?.objectID == client1.objectID
            let isClient2Preselected = preselectedClient?.objectID == client2.objectID

            if isClient1Preselected && !isClient2Preselected {
                return true
            } else if !isClient1Preselected && isClient2Preselected {
                return false
            } else {
                return (client1.name ?? "") < (client2.name ?? "")
            }
        }
    }

    var body: some View {
        NavigationView {
            Group {
                switch currentStep {
                case 1:
                    clientSelectionView
                case 2:
                    amountInputView
                case 3:
                    targetCountSelectionView
                case 4:
                    detailInputView
                default:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - 步驟 1：選擇客戶
    private var clientSelectionView: some View {
        List {
            Section(header: Text("選擇要新增的客戶")) {
                ForEach(sortedClients, id: \.objectID) { client in
                    HStack {
                        Text(client.name ?? "未知客戶")
                            .font(.system(size: 16))

                        Spacer()

                        if selectedClients.contains(client.objectID) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        // 預選客戶使用淺藍色背景
                        preselectedClient?.objectID == client.objectID
                            ? Color.blue.opacity(0.15)
                            : Color.clear
                    )
                    .cornerRadius(8)
                    .onTapGesture {
                        if selectedClients.contains(client.objectID) {
                            selectedClients.remove(client.objectID)
                        } else {
                            selectedClients.insert(client.objectID)
                        }
                    }
                }
            }
        }
        .navigationTitle("結構型商品新增")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("下一步") { currentStep = 2 }
                    .disabled(selectedClients.isEmpty)
            }
        }
        .onAppear {
            preselectClientIfNeeded()
            // ⭐️ 編輯模式的資料已在 init 中預填
        }
    }

    // MARK: - 步驟 2：輸入金額
    private var amountInputView: some View {
        List {
            // 幣別選擇
            Section(header: Text("選擇幣別")) {
                Picker("幣別", selection: $currency) {
                    Text("USD").tag("USD")
                    Text("TWD").tag("TWD")
                    Text("EUR").tag("EUR")
                    Text("JPY").tag("JPY")
                    Text("GBP").tag("GBP")
                    Text("CNY").tag("CNY")
                    Text("AUD").tag("AUD")
                    Text("CAD").tag("CAD")
                    Text("CHF").tag("CHF")
                    Text("HKD").tag("HKD")
                    Text("SGD").tag("SGD")
                }
                .pickerStyle(MenuPickerStyle())
            }

            Section(header: Text("輸入各客戶交易金額")) {
                ForEach(allClients.filter { selectedClients.contains($0.objectID) }, id: \.objectID) { client in
                    HStack {
                        Text(client.name ?? "未知客戶")
                            .font(.system(size: 15))
                            .frame(width: 100, alignment: .leading)

                        TextField("金額", text: Binding(
                            get: { clientAmounts[client.objectID] ?? "" },
                            set: { clientAmounts[client.objectID] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
        }
        .navigationTitle("輸入金額")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") { currentStep = 1 }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("下一步") { currentStep = 3 }
            }
        }
    }

    // MARK: - 步驟 3：選擇標的數量
    private var targetCountSelectionView: some View {
        List {
            Section(header: Text("選擇標的數量")) {
                ForEach([1, 2, 3, 4], id: \.self) { count in
                    HStack {
                        Text("\(count) 個標的")
                            .font(.system(size: 16))

                        Spacer()

                        if numberOfTargets == Int16(count) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        numberOfTargets = Int16(count)
                    }
                }
            }
        }
        .navigationTitle("選擇標的數")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") { currentStep = 2 }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("下一步") { currentStep = 4 }
            }
        }
    }

    // MARK: - 步驟 4：輸入詳細資料
    private var detailInputView: some View {
        Form {
            // 1. 基本資料
            Section(header: Text("基本資料")) {
                HStack {
                    Text("商品代號")
                    Spacer()
                    TextField("輸入代號", text: $productCode)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 150)
                }
                DatePicker("交易定價日", selection: $tradePricingDate, displayedComponents: .date)
                DatePicker("發行日", selection: $issueDate, displayedComponents: .date)
                DatePicker("最終評價日", selection: $finalValuationDate, displayedComponents: .date)
            }

            // 2. 利率與價格參數
            Section(header: Text("利率與價格參數")) {
                HStack {
                    Text("年化利率 %")
                    Spacer()
                    TextField("", text: $interestRate)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: interestRate) { _ in
                            calculateMonthlyRate()
                        }
                }
                HStack {
                    Text("月配息率 %")
                    Spacer()
                    Text(monthlyRate.isEmpty ? "自動計算" : monthlyRate)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("KO %")
                    Spacer()
                    TextField("100", text: $koPercentage)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                HStack {
                    Text("PUT %")
                    Spacer()
                    TextField("85", text: $putPercentage)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: putPercentage) { _ in
                            calculatePrices()
                        }
                }
                HStack {
                    Text("KI %")
                    Spacer()
                    TextField("60", text: $kiPercentage)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: kiPercentage) { _ in
                            calculatePrices()
                        }
                }
            }

            // 3. 標的資訊（表格式）
            Section(header: VStack(alignment: .leading, spacing: 8) {
                Text("標的資訊")

                HStack {
                    Picker("", selection: $dayOffset) {
                        Text("前一天").tag(0)
                        Text("前兩天").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)

                    Picker("", selection: $useClosingPrice) {
                        Text("收盤").tag(true)
                        Text("開盤").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)

                    Button(action: {
                        fetchAllPrices()
                    }) {
                        HStack(spacing: 4) {
                            if isFetchingPrices {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("取得價格")
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .disabled(isFetchingPrices)

                    Spacer()
                }
            }) {
                // 價格日期提示
                if !priceDate.isEmpty {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("價格日期：\(priceDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // 表頭
                targetGridHeader

                // 代號行
                targetSymbolRow

                // 期初價行
                targetInitialPriceRow

                // 執行價行
                targetStrikePriceRow

                // 保護價行
                targetProtectionPriceRow
            }
        }
        .navigationTitle("輸入詳細資料")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") { currentStep = 3 }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("儲存") {
                    saveData()
                    dismiss()
                }
            }
        }
    }

    // 表格表頭
    private var targetGridHeader: some View {
        HStack(spacing: 4) {
            Text("")
                .frame(width: 50)
            ForEach(1...Int(numberOfTargets), id: \.self) { i in
                Text("標的\(i)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }

    // 代號行
    private var targetSymbolRow: some View {
        HStack(spacing: 4) {
            Text("代號")
                .font(.caption)
                .frame(width: 50, alignment: .leading)

            TextField("", text: $target1)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.caption)

            if numberOfTargets >= 2 {
                TextField("", text: $target2)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.caption)
            }
            if numberOfTargets >= 3 {
                TextField("", text: $target3)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.caption)
            }
            if numberOfTargets >= 4 {
                TextField("", text: $target4)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.caption)
            }
        }
    }

    // 期初價行
    private var targetInitialPriceRow: some View {
        HStack(spacing: 4) {
            Text("期初價")
                .font(.caption)
                .frame(width: 50, alignment: .leading)

            TextField("", text: $initialPrice1)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .font(.caption)
                .onChange(of: initialPrice1) { _ in calculatePrices() }

            if numberOfTargets >= 2 {
                TextField("", text: $initialPrice2)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .font(.caption)
                    .onChange(of: initialPrice2) { _ in calculatePrices() }
            }
            if numberOfTargets >= 3 {
                TextField("", text: $initialPrice3)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .font(.caption)
                    .onChange(of: initialPrice3) { _ in calculatePrices() }
            }
            if numberOfTargets >= 4 {
                TextField("", text: $initialPrice4)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .font(.caption)
                    .onChange(of: initialPrice4) { _ in calculatePrices() }
            }
        }
    }

    // 執行價行
    private var targetStrikePriceRow: some View {
        HStack(spacing: 4) {
            Text("執行價")
                .font(.caption)
                .frame(width: 50, alignment: .leading)
                .foregroundColor(.orange)

            Text(strikePrice1.isEmpty ? "-" : strikePrice1)
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(4)

            if numberOfTargets >= 2 {
                Text(strikePrice2.isEmpty ? "-" : strikePrice2)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(6)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(4)
            }
            if numberOfTargets >= 3 {
                Text(strikePrice3.isEmpty ? "-" : strikePrice3)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(6)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(4)
            }
            if numberOfTargets >= 4 {
                Text(strikePrice4.isEmpty ? "-" : strikePrice4)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(6)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(4)
            }
        }
    }

    // 保護價行
    private var targetProtectionPriceRow: some View {
        HStack(spacing: 4) {
            Text("保護價")
                .font(.caption)
                .frame(width: 50, alignment: .leading)
                .foregroundColor(.red)

            Text(protectionPrice1.isEmpty ? "-" : protectionPrice1)
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(Color.red.opacity(0.15))
                .cornerRadius(4)

            if numberOfTargets >= 2 {
                Text(protectionPrice2.isEmpty ? "-" : protectionPrice2)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(6)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(4)
            }
            if numberOfTargets >= 3 {
                Text(protectionPrice3.isEmpty ? "-" : protectionPrice3)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(6)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(4)
            }
            if numberOfTargets >= 4 {
                Text(protectionPrice4.isEmpty ? "-" : protectionPrice4)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(6)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(4)
            }
        }
    }

    // 計算月利率
    private func calculateMonthlyRate() {
        if let annual = Double(interestRate), annual > 0 {
            let monthly = annual / 12
            monthlyRate = String(format: "%.4f", monthly)
        } else {
            monthlyRate = ""
        }
    }

    // 取得所有標的價格
    private func fetchAllPrices() {
        // 收集所有輸入的股票代號
        var symbols: [String] = []
        if !target1.isEmpty { symbols.append(target1.uppercased()) }
        if !target2.isEmpty && numberOfTargets >= 2 { symbols.append(target2.uppercased()) }
        if !target3.isEmpty && numberOfTargets >= 3 { symbols.append(target3.uppercased()) }
        if !target4.isEmpty && numberOfTargets >= 4 { symbols.append(target4.uppercased()) }

        guard !symbols.isEmpty else { return }

        isFetchingPrices = true

        Task {
            do {
                let prices = await StockPriceService.shared.fetchMultipleStockPricesWithType(symbols: symbols, useClosingPrice: useClosingPrice, dayOffset: dayOffset)

                await MainActor.run {
                    // 更新價格
                    if let price = prices[target1.uppercased()] {
                        initialPrice1 = price
                    }
                    if numberOfTargets >= 2, let price = prices[target2.uppercased()] {
                        initialPrice2 = price
                    }
                    if numberOfTargets >= 3, let price = prices[target3.uppercased()] {
                        initialPrice3 = price
                    }
                    if numberOfTargets >= 4, let price = prices[target4.uppercased()] {
                        initialPrice4 = price
                    }

                    // 設定價格日期
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy/MM/dd"
                    let priceType = self.useClosingPrice ? "收盤價" : "開盤價"
                    let dayText = self.dayOffset == 0 ? "前一天" : "前兩天"

                    // 計算實際日期（大約）
                    let targetDate = Calendar.current.date(byAdding: .day, value: -(1 + self.dayOffset), to: Date()) ?? Date()
                    priceDate = "\(formatter.string(from: targetDate)) \(priceType) (\(dayText))"

                    // 重新計算執行價和保護價
                    calculatePrices()

                    isFetchingPrices = false
                }
            } catch {
                await MainActor.run {
                    isFetchingPrices = false
                    print("取得價格失敗: \(error)")
                }
            }
        }
    }

    // 計算執行價格和保護價格
    private func calculatePrices() {
        let put = Double(putPercentage) ?? 0
        let ki = Double(kiPercentage) ?? 0

        // 標的 1
        if let price1 = Double(initialPrice1), price1 > 0 {
            strikePrice1 = String(format: "%.2f", price1 * put / 100)
            protectionPrice1 = String(format: "%.2f", price1 * ki / 100)
        }

        // 標的 2
        if let price2 = Double(initialPrice2), price2 > 0 {
            strikePrice2 = String(format: "%.2f", price2 * put / 100)
            protectionPrice2 = String(format: "%.2f", price2 * ki / 100)
        }

        // 標的 3
        if let price3 = Double(initialPrice3), price3 > 0 {
            strikePrice3 = String(format: "%.2f", price3 * put / 100)
            protectionPrice3 = String(format: "%.2f", price3 * ki / 100)
        }

        // 標的 4
        if let price4 = Double(initialPrice4), price4 > 0 {
            strikePrice4 = String(format: "%.2f", price4 * put / 100)
            protectionPrice4 = String(format: "%.2f", price4 * ki / 100)
        }
    }

    // 日期格式化
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }

    // MARK: - 儲存資料
    private func saveData() {
        // ⭐️ 判斷是更新還是新增
        if let existingProduct = editingProduct {
            // 編輯模式：更新現有商品
            updateProduct(existingProduct)
            print("📝 編輯模式：更新商品")
        } else {
            // 新增模式：為每個選中的客戶創建商品
            for client in allClients {
                guard selectedClients.contains(client.objectID) else { continue }
                createProduct(for: client)
            }
            print("➕ 新增模式：創建商品")
        }

        do {
            try viewContext.save()
        } catch {
            print("儲存失敗: \(error)")
        }
    }

    // 創建新商品
    private func createProduct(for client: Client) {
        let product = StructuredProduct(context: viewContext)
        product.client = client
        product.createdDate = Date()
        product.isExited = false
        updateProductFields(product, clientID: client.objectID)
    }

    // 更新現有商品
    private func updateProduct(_ product: StructuredProduct) {
        updateProductFields(product, clientID: product.client?.objectID)
    }

    // 更新商品欄位
    private func updateProductFields(_ product: StructuredProduct, clientID: NSManagedObjectID?) {
        product.numberOfTargets = numberOfTargets
        product.tradePricingDate = dateFormatter.string(from: tradePricingDate)
        product.target1 = target1
        product.target2 = target2
        product.target3 = target3
        product.issueDate = dateFormatter.string(from: issueDate)
        product.finalValuationDate = dateFormatter.string(from: finalValuationDate)
        product.initialPrice1 = initialPrice1
        product.initialPrice2 = initialPrice2
        product.initialPrice3 = initialPrice3
        product.strikePrice1 = strikePrice1
        product.strikePrice2 = strikePrice2
        product.strikePrice3 = strikePrice3
        product.target4 = target4
        product.initialPrice4 = initialPrice4
        product.strikePrice4 = strikePrice4
        product.interestRate = interestRate
        product.monthlyRate = monthlyRate
        product.productCode = productCode
        product.currency = currency
        product.koPercentage = koPercentage
        product.putPercentage = putPercentage
        product.kiPercentage = kiPercentage
        product.protectionPrice1 = protectionPrice1
        product.protectionPrice2 = protectionPrice2
        product.protectionPrice3 = protectionPrice3
        product.protectionPrice4 = protectionPrice4

        // 交易金額（編輯模式和新增模式都使用 clientAmounts）
        if let clientID = clientID {
            product.transactionAmount = clientAmounts[clientID] ?? ""
        }

        // 編輯模式不更新這些欄位（保留原值）
        if editingProduct == nil {
            product.distanceToExit1 = ""
            product.distanceToExit2 = ""
            product.distanceToExit3 = ""
            product.distanceToExit4 = ""
            product.currentPrice1 = ""
            product.currentPrice2 = ""
            product.currentPrice3 = ""
            product.currentPrice4 = ""
        }
    }

    // ⭐️ 彈性日期解析函數 - 支援多種格式
    private static func parseFlexibleDate(_ dateString: String) -> Date? {
        let trimmed = dateString.trimmingCharacters(in: .whitespaces)

        // 格式1: yyyy-MM-dd (標準格式)
        let standardFormatter = DateFormatter()
        standardFormatter.dateFormat = "yyyy-MM-dd"
        if let date = standardFormatter.date(from: trimmed) {
            return date
        }

        // 格式2: M/d 或 MM/dd (沒有年份，補上當年)
        let shortFormatter = DateFormatter()
        shortFormatter.dateFormat = "M/d"
        if let date = shortFormatter.date(from: trimmed) {
            // 取得當前年份
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            var components = calendar.dateComponents([.month, .day], from: date)
            components.year = currentYear
            return calendar.date(from: components)
        }

        // 格式3: MM/dd (兩位數月份)
        shortFormatter.dateFormat = "MM/dd"
        if let date = shortFormatter.date(from: trimmed) {
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            var components = calendar.dateComponents([.month, .day], from: date)
            components.year = currentYear
            return calendar.date(from: components)
        }

        // 格式4: yyyy/MM/dd
        standardFormatter.dateFormat = "yyyy/MM/dd"
        if let date = standardFormatter.date(from: trimmed) {
            return date
        }

        // 格式5: M/d/yyyy
        standardFormatter.dateFormat = "M/d/yyyy"
        if let date = standardFormatter.date(from: trimmed) {
            return date
        }

        // 無法解析，返回 nil
        return nil
    }

    // ⭐️ 載入商品資料（編輯模式）
    private func loadProductData(_ product: StructuredProduct) {
        numberOfTargets = product.numberOfTargets
        productCode = product.productCode ?? ""
        currency = product.currency ?? "USD"
        interestRate = product.interestRate ?? ""
        monthlyRate = product.monthlyRate ?? ""
        koPercentage = product.koPercentage ?? ""
        putPercentage = product.putPercentage ?? ""
        kiPercentage = product.kiPercentage ?? ""

        // 標的資訊
        target1 = product.target1 ?? ""
        target2 = product.target2 ?? ""
        target3 = product.target3 ?? ""
        target4 = product.target4 ?? ""

        // 初始價格
        initialPrice1 = product.initialPrice1 ?? ""
        initialPrice2 = product.initialPrice2 ?? ""
        initialPrice3 = product.initialPrice3 ?? ""
        initialPrice4 = product.initialPrice4 ?? ""

        // 履約價格
        strikePrice1 = product.strikePrice1 ?? ""
        strikePrice2 = product.strikePrice2 ?? ""
        strikePrice3 = product.strikePrice3 ?? ""
        strikePrice4 = product.strikePrice4 ?? ""

        // 保護價格
        protectionPrice1 = product.protectionPrice1 ?? ""
        protectionPrice2 = product.protectionPrice2 ?? ""
        protectionPrice3 = product.protectionPrice3 ?? ""
        protectionPrice4 = product.protectionPrice4 ?? ""

        // ⭐️ 載入交易金額（編輯模式中需要顯示）
        if let client = product.client {
            clientAmounts[client.objectID] = product.transactionAmount ?? ""
            selectedClients.insert(client.objectID)
        }

        // 日期
        if let tradeDateStr = product.tradePricingDate,
           let tradeDate = dateFormatter.date(from: tradeDateStr) {
            tradePricingDate = tradeDate
        }
        if let issueDateStr = product.issueDate,
           let issueD = dateFormatter.date(from: issueDateStr) {
            issueDate = issueD
        }
        if let finalDateStr = product.finalValuationDate,
           let finalDate = dateFormatter.date(from: finalDateStr) {
            finalValuationDate = finalDate
        }
    }
}

// MARK: - 跨客戶債券庫存視圖
struct CrossClientCorporateBondView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \CorporateBond.bondName, ascending: true),
            NSSortDescriptor(keyPath: \CorporateBond.createdDate, ascending: false)
        ],
        predicate: NSPredicate(format: "bondName != %@", "__BATCH_UPDATE__"),
        animation: .default
    )
    private var allBonds: FetchedResults<CorporateBond>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.sortOrder, ascending: true)]
    )
    private var allClients: FetchedResults<Client>

    @State private var searchText = ""
    @State private var sortByClient = true  // ⭐️ 預設按客戶分組
    @State private var editingBond: CorporateBond?  // ⭐️ 追蹤要編輯的債券

    var body: some View {
        NavigationView {
            List {
                if sortByClient {
                    // 按客戶名稱分組
                    ForEach(groupedByClient.keys.sorted(), id: \.self) { clientName in
                        Section(header: Text(clientName).font(.headline)) {
                            ForEach(groupedByClient[clientName] ?? [], id: \.self) { bond in
                                bondRow(bond: bond, showClient: false)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingBond = bond
                                    }
                            }
                        }
                    }
                } else {
                    // 按債券名稱分組
                    ForEach(groupedBonds.keys.sorted(), id: \.self) { bondName in
                        Section(header: Text(bondName).font(.headline)) {
                            ForEach(groupedBonds[bondName] ?? [], id: \.self) { bond in
                                bondRow(bond: bond, showClient: true)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingBond = bond
                                    }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜尋債券名稱")
            .navigationTitle("債券庫存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("排序", selection: $sortByClient) {
                        Text("按商品").tag(false)
                        Text("按客戶").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $editingBond) { bond in
                AddMonthlyDataView(
                    onSave: { _, _ in },
                    client: bond.client,
                    initialTab: 1,  // ⭐️ 直接打開公司債頁面
                    hideTabSelector: true,  // ⭐️ 隱藏分頁選擇器
                    customTitle: "編輯公司債",  // ⭐️ 自訂標題
                    editingBond: bond  // ⭐️ 傳入正在編輯的債券
                )
                .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    // 債券列顯示組件
    @ViewBuilder
    private func bondRow(bond: CorporateBond, showClient: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if showClient {
                    Text(bond.client?.name ?? "未知客戶")
                        .font(.system(size: 15, weight: .semibold))
                } else {
                    Text(bond.bondName ?? "未命名債券")
                        .font(.system(size: 15, weight: .semibold))
                }

                Spacer()

                // 幣別標籤
                if let currency = bond.currency, currency != "USD" {
                    Text(currency)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }

            HStack {
                // 票面利率
                if let couponRate = bond.couponRate, !couponRate.isEmpty {
                    Text("票面: \(couponRate)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 現值
                if let currentValue = bond.currentValue, !currentValue.isEmpty {
                    let formattedValue = formatNumber(currentValue)
                    Text("現值: $\(formattedValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 報酬率
                if let returnRate = bond.returnRate, !returnRate.isEmpty {
                    if let rate = Double(returnRate) {
                        Text("\(rate >= 0 ? "+" : "")\(rate, specifier: "%.2f")%")
                            .font(.caption)
                            .foregroundColor(rate >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // 按客戶名稱分組
    private var groupedByClient: [String: [CorporateBond]] {
        let filtered = searchText.isEmpty ? Array(allBonds) : allBonds.filter {
            ($0.bondName ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.client?.name ?? "").localizedCaseInsensitiveContains(searchText)
        }

        return Dictionary(grouping: filtered) { bond in
            bond.client?.name ?? "未知客戶"
        }
    }

    // 按債券名稱分組
    private var groupedBonds: [String: [CorporateBond]] {
        let filtered = searchText.isEmpty ? Array(allBonds) : allBonds.filter {
            ($0.bondName ?? "").localizedCaseInsensitiveContains(searchText)
        }

        return Dictionary(grouping: filtered) { bond in
            bond.bondName ?? "未命名債券"
        }
    }

    // 格式化數字（千分位）
    private func formatNumber(_ value: String) -> String {
        guard let doubleValue = Double(value.replacingOccurrences(of: ",", with: "")) else {
            return value
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: doubleValue)) ?? value
    }
}

// MARK: - 債券批量新增

struct BatchAddCorporateBondView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default
    )
    private var allClients: FetchedResults<Client>

    // 步驟控制
    @State private var currentStep = 1 // 1: 選客戶, 2: 輸入金額, 3: 填寫債券詳細資訊

    // 步驟 1: 客戶選擇
    @State private var selectedClients: Set<NSManagedObjectID> = []

    // 步驟 2: 各客戶金額（可選）
    @State private var clientAmounts: [NSManagedObjectID: String] = [:]

    // 步驟 3: 債券詳細資訊
    @State private var bondName: String = ""
    @State private var currency: String = "USD"
    @State private var couponRate: String = ""
    @State private var yieldRate: String = ""
    @State private var subscriptionPrice: String = ""
    @State private var holdingFaceValue: String = ""
    @State private var previousHandInterest: String = ""
    @State private var currentValue: String = ""
    @State private var receivedInterest: String = ""
    @State private var dividendMonths: String = ""

    private let currencies = ["USD", "TWD", "EUR", "JPY", "GBP", "CNY", "AUD", "CAD", "CHF", "HKD", "SGD"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 進度指示器
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { step in
                        Circle()
                            .fill(currentStep >= step ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.vertical, 12)

                Divider()

                // 內容區域
                if currentStep == 1 {
                    step1SelectClients
                } else if currentStep == 2 {
                    step2EnterAmounts
                } else {
                    step3BondDetails
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep < 3 {
                        Button("下一步") {
                            nextStep()
                        }
                        .disabled(!canProceed)
                    } else {
                        Button("完成") {
                            saveBonds()
                        }
                        .disabled(!canSave)
                    }
                }
            }
        }
    }

    // MARK: - 步驟 1: 選擇客戶

    private var step1SelectClients: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("選擇要新增債券的客戶")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            List {
                ForEach(allClients) { client in
                    Button(action: {
                        toggleClientSelection(client)
                    }) {
                        HStack {
                            Image(systemName: selectedClients.contains(client.objectID) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedClients.contains(client.objectID) ? .blue : .gray)
                            Text(client.name ?? "未命名客戶")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }

    // MARK: - 步驟 2: 輸入金額

    private var step2EnterAmounts: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("為各客戶輸入金額（可選）")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            Text("若此步驟未輸入金額，可在步驟 3 統一輸入")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            List {
                ForEach(selectedClientsList, id: \.objectID) { client in
                    HStack {
                        Text(client.name ?? "未命名客戶")
                            .frame(width: 100, alignment: .leading)

                        TextField("金額", text: Binding(
                            get: { clientAmounts[client.objectID] ?? "" },
                            set: { clientAmounts[client.objectID] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }

    // MARK: - 步驟 3: 填寫債券詳細資訊

    private var step3BondDetails: some View {
        Form {
            Section(header: Text("基本資訊")) {
                FormField(label: "債券名稱", icon: "doc.text", text: $bondName, placeholder: "請輸入債券名稱")

                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(.blue)
                    Text("幣別")
                    Spacer()
                    Picker("幣別", selection: $currency) {
                        ForEach(currencies, id: \.self) { curr in
                            Text(curr).tag(curr)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }

            Section(header: Text("票面與殖利率")) {
                FormField(label: "票面利率(%)", icon: "percent", text: $couponRate, placeholder: "例: 5.5", keyboardType: .decimalPad)
                FormField(label: "殖利率(%)", icon: "chart.line.uptrend.xyaxis", text: $yieldRate, placeholder: "例: 6.2", keyboardType: .decimalPad)
            }

            Section(header: Text("持倉資訊")) {
                FormField(label: "認購價格", icon: "banknote", text: $subscriptionPrice, placeholder: "例: 98.5", keyboardType: .decimalPad)
                FormField(label: "持有面額", icon: "briefcase", text: $holdingFaceValue, placeholder: "例: 100000", keyboardType: .decimalPad)
                FormField(label: "前手利息", icon: "arrow.left.arrow.right", text: $previousHandInterest, placeholder: "例: 500", keyboardType: .decimalPad)
                FormField(label: "當前市值", icon: "chart.bar.fill", text: $currentValue, placeholder: "例: 105000", keyboardType: .decimalPad)
            }

            Section(header: Text("配息資訊")) {
                FormField(label: "已收利息", icon: "arrow.down.circle", text: $receivedInterest, placeholder: "例: 2500", keyboardType: .decimalPad)
                FormField(label: "配息月份", icon: "calendar", text: $dividendMonths, placeholder: "例: 3,6,9,12")
            }

            Section {
                Text("已選擇 \(selectedClients.count) 位客戶")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helper Properties

    private var navigationTitle: String {
        switch currentStep {
        case 1: return "選擇客戶 (1/3)"
        case 2: return "輸入金額 (2/3)"
        case 3: return "填寫債券資訊 (3/3)"
        default: return "批量新增債券"
        }
    }

    private var selectedClientsList: [Client] {
        allClients.filter { selectedClients.contains($0.objectID) }
    }

    private var canProceed: Bool {
        if currentStep == 1 {
            return !selectedClients.isEmpty
        }
        return true
    }

    private var canSave: Bool {
        !bondName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    private func toggleClientSelection(_ client: Client) {
        if selectedClients.contains(client.objectID) {
            selectedClients.remove(client.objectID)
            clientAmounts.removeValue(forKey: client.objectID)
        } else {
            selectedClients.insert(client.objectID)
        }
    }

    private func nextStep() {
        withAnimation {
            currentStep += 1
        }
    }

    private func saveBonds() {
        for clientID in selectedClients {
            guard let client = try? viewContext.existingObject(with: clientID) as? Client else {
                continue
            }

            let bond = CorporateBond(context: viewContext)
            bond.bondName = bondName
            bond.currency = currency
            bond.couponRate = couponRate.isEmpty ? nil : couponRate
            bond.yieldRate = yieldRate.isEmpty ? nil : yieldRate
            bond.subscriptionPrice = subscriptionPrice.isEmpty ? nil : subscriptionPrice
            bond.previousHandInterest = previousHandInterest.isEmpty ? nil : previousHandInterest
            bond.receivedInterest = receivedInterest.isEmpty ? nil : receivedInterest
            bond.dividendMonths = dividendMonths.isEmpty ? nil : dividendMonths
            bond.client = client

            // 處理持有面額：優先使用步驟2的客戶金額，否則使用步驟3的統一金額
            if let clientAmount = clientAmounts[clientID], !clientAmount.isEmpty {
                bond.holdingFaceValue = clientAmount
            } else if !holdingFaceValue.isEmpty {
                bond.holdingFaceValue = holdingFaceValue
            }

            // 處理當前市值：優先使用步驟2的客戶金額，否則使用步驟3的統一市值
            if let clientAmount = clientAmounts[clientID], !clientAmount.isEmpty {
                bond.currentValue = clientAmount
            } else if !currentValue.isEmpty {
                bond.currentValue = currentValue
            }

            // 計算報酬率
            calculateReturnRate(for: bond)
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("儲存債券失敗: \(error.localizedDescription)")
        }
    }

    private func calculateReturnRate(for bond: CorporateBond) {
        guard let currentVal = Double(bond.currentValue ?? "0"),
              let subPrice = Double(subscriptionPrice),
              let faceValue = Double(bond.holdingFaceValue ?? "0"),
              let prevInterest = Double(previousHandInterest) else {
            return
        }

        let cost = (subPrice / 100.0) * faceValue + prevInterest
        if cost > 0 {
            let returnRate = ((currentVal - cost) / cost) * 100
            bond.returnRate = String(format: "%.2f%%", returnRate)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        FloatingMenuButton(
            isExpanded: .constant(false),
            onStructuredProductAdd: { print("結構型新增") },
            onStructuredProductInventory: { print("結構型庫存") },
            onUSStockAdd: { print("美股新增") },
            onUSStockInventory: { print("美股庫存") },
            onTWStockAdd: { print("台股新增") },
            onTWStockInventory: { print("台股庫存") },
            onCorporateBondAdd: { print("債券新增") },
            onCorporateBondInventory: { print("債券庫存") }
        )
    }
}
