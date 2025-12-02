//
//  InsuranceCalculatorView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/16.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

/// 保險試算表管理視圖
/// 採用兩層頁籤結構：
/// - 第一層：保險公司分類（例如：國泰人壽、富邦人壽等）
/// - 第二層：商品分類（例如：終身壽險、投資型保單等）
struct InsuranceCalculatorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isExpanded = false
    @State private var selectedCompany = "全部"  // 第一層：選擇的保險公司
    @State private var selectedProduct = "全部"  // 第二層：選擇的商品
    @State private var showingFilePicker = false
    @State private var showingCompanyDialog = false
    @State private var showingProductDialog = false
    @State private var newCompanyName = ""
    @State private var newProductName = ""
    @State private var calculatorToDelete: InsuranceCalculator? = nil
    @State private var showingDeleteConfirmation = false

    // 拖曳排序相關
    @State private var draggingCompany: String? = nil
    @State private var draggingProduct: String? = nil
    @State private var companyOrder: [String] = []
    @State private var productOrder: [String: [String]] = [:]  // 每個公司的商品排序

    // 自定義分類列表（儲存在 UserDefaults）
    @State private var customCompanies: [String] = []
    @State private var customProducts: [String: [String]] = [:]  // 每個公司的商品列表

    let client: Client?

    // FetchRequest 取得試算表資料
    @FetchRequest private var calculators: FetchedResults<InsuranceCalculator>

    init(client: Client?) {
        self.client = client

        // 設定 FetchRequest
        if let client = client {
            _calculators = FetchRequest<InsuranceCalculator>(
                sortDescriptors: [
                    NSSortDescriptor(keyPath: \InsuranceCalculator.companyName, ascending: true),
                    NSSortDescriptor(keyPath: \InsuranceCalculator.productName, ascending: true),
                    NSSortDescriptor(keyPath: \InsuranceCalculator.sortOrder, ascending: true)
                ],
                predicate: NSPredicate(format: "client == %@", client),
                animation: .default
            )
        } else {
            _calculators = FetchRequest<InsuranceCalculator>(
                sortDescriptors: [NSSortDescriptor(keyPath: \InsuranceCalculator.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 標題區域
            calculatorTableHeader

            // 表格內容（可縮放）
            if isExpanded {
                VStack(spacing: 0) {
                    // 第一層頁籤：保險公司
                    companyTabsView

                    // 第二層頁籤：商品分類（只在非「全部」時顯示）
                    if selectedCompany != "全部" {
                        Divider()
                        productTabsView
                    }

                    Divider()

                    // 試算表列表
                    calculatorListView
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .spreadsheet, .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .alert("新增保險公司", isPresented: $showingCompanyDialog) {
            TextField("保險公司名稱（例如：國泰人壽）", text: $newCompanyName)
            Button("取消", role: .cancel) {
                newCompanyName = ""
            }
            Button("確定") {
                if !newCompanyName.isEmpty {
                    // 新增公司到自定義列表
                    addCustomCompany(newCompanyName)
                    // 新增公司後自動選擇
                    selectedCompany = newCompanyName
                    selectedProduct = "全部"
                    newCompanyName = ""
                }
            }
        } message: {
            Text("請輸入新的保險公司名稱")
        }
        .alert("新增商品分類", isPresented: $showingProductDialog) {
            TextField("商品名稱（例如：終身壽險）", text: $newProductName)
            Button("取消", role: .cancel) {
                newProductName = ""
            }
            Button("確定") {
                if !newProductName.isEmpty && selectedCompany != "全部" {
                    // 新增商品到自定義列表
                    addCustomProduct(newProductName, to: selectedCompany)
                    // 新增商品後自動選擇
                    selectedProduct = newProductName
                    newProductName = ""
                }
            }
        } message: {
            Text("請輸入新的商品分類名稱")
        }
        .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) {
                calculatorToDelete = nil
            }
            Button("刪除", role: .destructive) {
                if let calculator = calculatorToDelete {
                    deleteCalculator(calculator)
                    calculatorToDelete = nil
                }
            }
        } message: {
            if let calculator = calculatorToDelete {
                Text("確定要刪除「\(calculator.calculatorName ?? "此試算表")」嗎？此操作無法復原。")
            } else {
                Text("確定要刪除此試算表嗎？此操作無法復原。")
            }
        }
        .onAppear {
            loadCompanyOrder()
            loadProductOrders()
            loadCustomCompanies()
            loadCustomProducts()

            // 監聽快速上傳試算表的通知
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("QuickUploadCalculator"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let companyName = userInfo["companyName"] as? String,
                   let productName = userInfo["productName"] as? String {
                    handleQuickUpload(companyName: companyName, productName: productName)
                }
            }

            // 監聽刷新視圖的通知
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("RefreshCalculatorView"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let companyName = userInfo["companyName"] as? String,
                   let productName = userInfo["productName"] as? String {
                    // 刷新視圖並選擇對應的分類
                    selectedCompany = companyName
                    selectedProduct = productName
                    // 展開視圖
                    isExpanded = true
                }
            }
        }
        .onDisappear {
            // 移除通知監聽
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("QuickUploadCalculator"), object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("RefreshCalculatorView"), object: nil)
        }
    }

    // MARK: - 標題區域
    private var calculatorTableHeader: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                    Text("保險試算表存放")
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

                    // 上傳檔案按鈕
                    Button(action: {
                        if selectedCompany == "全部" {
                            // 提示需要先選擇公司
                            showingCompanyDialog = true
                        } else if selectedProduct == "全部" {
                            // 提示需要先選擇商品
                            showingProductDialog = true
                        } else {
                            showingFilePicker = true
                        }
                    }) {
                        Image(systemName: "arrow.up.doc")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }

                    // 刪除最後一筆
                    Button(action: {
                        deleteLastCalculator()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
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

    // MARK: - 第一層頁籤：保險公司
    private var companyTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableCompanies, id: \.self) { company in
                    Button(action: {
                        selectedCompany = company
                        selectedProduct = "全部"  // 切換公司時重置商品選擇
                    }) {
                        Text(company)
                            .font(.system(size: 14, weight: selectedCompany == company ? .semibold : .regular))
                            .foregroundColor(selectedCompany == company ? .white : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCompany == company ? Color.blue : Color.blue.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        if company != "全部" {
                            Button(role: .destructive) {
                                // TODO: 實現刪除公司分類（需檢查是否有試算表）
                            } label: {
                                Label("刪除公司", systemImage: "trash")
                            }
                        }
                    }
                }

                // 新增公司按鈕
                Button(action: {
                    showingCompanyDialog = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                        Text("新增公司")
                            .font(.system(size: 14, weight: .regular))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - 第二層頁籤：商品分類
    private var productTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableProducts, id: \.self) { product in
                    Button(action: {
                        selectedProduct = product
                    }) {
                        Text(product)
                            .font(.system(size: 13, weight: selectedProduct == product ? .semibold : .regular))
                            .foregroundColor(selectedProduct == product ? .white : .orange)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(selectedProduct == product ? Color.orange : Color.orange.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        if product != "全部" {
                            Button(role: .destructive) {
                                // TODO: 實現刪除商品分類（需檢查是否有試算表）
                            } label: {
                                Label("刪除商品", systemImage: "trash")
                            }
                        }
                    }
                }

                // 新增商品按鈕
                if selectedCompany != "全部" {
                    Button(action: {
                        showingProductDialog = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 13))
                            Text("新增商品")
                                .font(.system(size: 13, weight: .regular))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - 試算表列表
    private var calculatorListView: some View {
        VStack(spacing: 12) {
            if filteredCalculators.isEmpty {
                // 空狀態
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("尚無試算表")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    Text("點擊上方「上傳」按鈕新增試算表")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                ForEach(filteredCalculators) { calculator in
                    CalculatorCardView(
                        calculator: calculator,
                        client: client,
                        onDelete: {
                            calculatorToDelete = calculator
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
        }
        .padding()
    }

    // MARK: - 計算屬性

    /// 取得所有保險公司列表（包含資料庫中的和自定義的）
    private var availableCompanies: [String] {
        // 從資料庫取得的公司
        let dbCompanies = Set(calculators.compactMap { $0.companyName }.filter { !$0.isEmpty })

        // 合併自定義公司列表
        let allCompanies = dbCompanies.union(Set(customCompanies))

        if !companyOrder.isEmpty {
            let orderedCompanies = companyOrder.filter { allCompanies.contains($0) }
            let newCompanies = allCompanies.filter { !companyOrder.contains($0) }.sorted()
            return ["全部"] + orderedCompanies + newCompanies
        } else {
            return ["全部"] + allCompanies.sorted()
        }
    }

    /// 取得當前公司的所有商品列表（包含資料庫中的和自定義的）
    private var availableProducts: [String] {
        guard selectedCompany != "全部" else { return ["全部"] }

        // 從資料庫取得的商品
        let dbProducts = Set(calculators
            .filter { $0.companyName == selectedCompany }
            .compactMap { $0.productName }
            .filter { !$0.isEmpty })

        // 合併自定義商品列表
        let customProductsList = customProducts[selectedCompany] ?? []
        let allProducts = dbProducts.union(Set(customProductsList))

        if let order = productOrder[selectedCompany], !order.isEmpty {
            let orderedProducts = order.filter { allProducts.contains($0) }
            let newProducts = allProducts.filter { !order.contains($0) }.sorted()
            return ["全部"] + orderedProducts + newProducts
        } else {
            return ["全部"] + allProducts.sorted()
        }
    }

    /// 篩選後的試算表列表
    private var filteredCalculators: [InsuranceCalculator] {
        var filtered = Array(calculators)

        // 按公司篩選
        if selectedCompany != "全部" {
            filtered = filtered.filter { $0.companyName == selectedCompany }
        }

        // 按商品篩選
        if selectedProduct != "全部" {
            filtered = filtered.filter { $0.productName == selectedProduct }
        }

        return filtered
    }

    // MARK: - 檔案處理

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // 確保可以訪問檔案
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ 無法訪問檔案：\(url)")
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            do {
                // 讀取檔案資料
                let fileData = try Data(contentsOf: url)
                let fileName = url.lastPathComponent
                let fileExtension = url.pathExtension

                // 建立試算表實體
                guard let client = client else {
                    print("❌ 無法新增試算表：沒有選中的客戶")
                    return
                }

                let newCalculator = InsuranceCalculator(context: viewContext)
                newCalculator.client = client
                newCalculator.companyName = selectedCompany
                newCalculator.productName = selectedProduct
                newCalculator.fileName = fileName
                newCalculator.fileData = fileData
                newCalculator.fileExtension = fileExtension
                newCalculator.calculatorName = fileName
                newCalculator.createdDate = Date()
                newCalculator.sortOrder = Int16(filteredCalculators.count)

                // 儲存到 Core Data
                try viewContext.save()
                PersistenceController.shared.save()

                print("✅ 試算表已上傳：\(fileName)")
                print("   公司：\(selectedCompany)")
                print("   商品：\(selectedProduct)")
                print("   檔案大小：\(fileData.count / 1024)KB")

            } catch {
                print("❌ 檔案上傳失敗：\(error.localizedDescription)")
            }

        case .failure(let error):
            print("❌ 檔案選擇失敗：\(error.localizedDescription)")
        }
    }

    // MARK: - 刪除功能

    private func deleteCalculator(_ calculator: InsuranceCalculator) {
        viewContext.delete(calculator)

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 試算表已刪除")
        } catch {
            print("❌ 刪除試算表失敗：\(error.localizedDescription)")
        }
    }

    private func deleteLastCalculator() {
        guard let lastCalculator = filteredCalculators.last else {
            print("⚠️ 沒有試算表可以刪除")
            return
        }
        deleteCalculator(lastCalculator)
    }

    // MARK: - 排序管理

    private func saveCompanyOrder() {
        let key = companyOrderKey()
        UserDefaults.standard.set(companyOrder, forKey: key)
        print("💾 Saved company order: \(companyOrder)")
    }

    private func loadCompanyOrder() {
        let key = companyOrderKey()
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            companyOrder = saved
            print("📂 Loaded company order: \(companyOrder)")
        }
    }

    private func saveProductOrder(for company: String) {
        let key = productOrderKey(for: company)
        if let order = productOrder[company] {
            UserDefaults.standard.set(order, forKey: key)
            print("💾 Saved product order for \(company): \(order)")
        }
    }

    private func loadProductOrders() {
        for company in availableCompanies where company != "全部" {
            let key = productOrderKey(for: company)
            if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
                productOrder[company] = saved
                print("📂 Loaded product order for \(company): \(saved)")
            }
        }
    }

    private func companyOrderKey() -> String {
        if let client = client {
            return "InsuranceCalculator_CompanyOrder_\(client.objectID.uriRepresentation().absoluteString)"
        } else {
            return "InsuranceCalculator_CompanyOrder_AllClients"
        }
    }

    private func productOrderKey(for company: String) -> String {
        if let client = client {
            return "InsuranceCalculator_ProductOrder_\(company)_\(client.objectID.uriRepresentation().absoluteString)"
        } else {
            return "InsuranceCalculator_ProductOrder_\(company)_AllClients"
        }
    }

    // MARK: - 自定義分類管理

    /// 新增自定義公司
    private func addCustomCompany(_ companyName: String) {
        guard !companyName.isEmpty else { return }

        // 避免重複
        if !customCompanies.contains(companyName) {
            customCompanies.append(companyName)
            saveCustomCompanies()
            print("✅ 新增自定義公司：\(companyName)")
        }
    }

    /// 新增自定義商品
    private func addCustomProduct(_ productName: String, to companyName: String) {
        guard !productName.isEmpty, !companyName.isEmpty else { return }

        // 初始化公司的商品列表（如果不存在）
        if customProducts[companyName] == nil {
            customProducts[companyName] = []
        }

        // 避免重複
        if !customProducts[companyName]!.contains(productName) {
            customProducts[companyName]!.append(productName)
            saveCustomProducts()
            print("✅ 新增自定義商品：\(companyName) - \(productName)")
        }
    }

    /// 儲存自定義公司列表
    private func saveCustomCompanies() {
        let key = customCompaniesKey()
        UserDefaults.standard.set(customCompanies, forKey: key)
    }

    /// 載入自定義公司列表
    private func loadCustomCompanies() {
        let key = customCompaniesKey()
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            customCompanies = saved
            print("📂 載入自定義公司列表：\(saved)")
        }
    }

    /// 儲存自定義商品列表
    private func saveCustomProducts() {
        let key = customProductsKey()
        // 將字典轉換為 JSON 儲存
        if let jsonData = try? JSONEncoder().encode(customProducts) {
            UserDefaults.standard.set(jsonData, forKey: key)
        }
    }

    /// 載入自定義商品列表
    private func loadCustomProducts() {
        let key = customProductsKey()
        if let jsonData = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: jsonData) {
            customProducts = decoded
            print("📂 載入自定義商品列表：\(decoded)")
        }
    }

    private func customCompaniesKey() -> String {
        if let client = client {
            return "InsuranceCalculator_CustomCompanies_\(client.objectID.uriRepresentation().absoluteString)"
        } else {
            return "InsuranceCalculator_CustomCompanies_AllClients"
        }
    }

    private func customProductsKey() -> String {
        if let client = client {
            return "InsuranceCalculator_CustomProducts_\(client.objectID.uriRepresentation().absoluteString)"
        } else {
            return "InsuranceCalculator_CustomProducts_AllClients"
        }
    }

    // MARK: - 快速上傳處理

    /// 處理快速上傳試算表（從保單頁面觸發）
    private func handleQuickUpload(companyName: String, productName: String) {
        print("📥 接收快速上傳請求")
        print("   公司：\(companyName)")
        print("   商品：\(productName)")

        // 自動添加公司和商品到自定義列表（如果不存在）
        addCustomCompany(companyName)
        addCustomProduct(productName, to: companyName)

        // 自動選擇對應的公司和商品
        selectedCompany = companyName
        selectedProduct = productName

        // 展開視圖
        isExpanded = true

        print("✅ 已自動選擇：\(companyName) - \(productName)")
    }
}

// MARK: - 試算表卡片視圖
struct CalculatorCardView: View {
    let calculator: InsuranceCalculator
    let client: Client?
    let onDelete: () -> Void

    @State private var showingDetailView = false
    @Environment(\.managedObjectContext) private var viewContext

    // 資料行數量
    @FetchRequest private var calculatorRows: FetchedResults<InsuranceCalculatorRow>

    init(calculator: InsuranceCalculator, client: Client?, onDelete: @escaping () -> Void) {
        self.calculator = calculator
        self.client = client
        self.onDelete = onDelete

        // 設定 FetchRequest，計算此試算表的資料行數
        _calculatorRows = FetchRequest<InsuranceCalculatorRow>(
            sortDescriptors: [NSSortDescriptor(keyPath: \InsuranceCalculatorRow.rowOrder, ascending: true)],
            predicate: NSPredicate(format: "calculator == %@", calculator),
            animation: .default
        )
    }

    var body: some View {
        Button(action: {
            showingDetailView = true
        }) {
            HStack(spacing: 12) {
                // 圖示（只在 iPad 顯示）
                if UIDevice.current.userInterfaceIdiom == .pad {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 50, height: 50)
                        Image(systemName: "tablecells.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }

                // 資訊
                VStack(alignment: .leading, spacing: 8) {
                    // 標題：商品名稱 + 利率 + 公司
                    HStack(spacing: 6) {
                        Text(calculator.productName ?? "未命名")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                            .lineLimit(1)

                        if let interestRate = calculator.interestRate, !interestRate.isEmpty {
                            Text("(\(interestRate))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.orange)
                        }

                        Text("-")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Text(calculator.companyName ?? "")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // 使用 GeometryReader 來偵測寬度並選擇佈局
                    GeometryReader { geometry in
                        if geometry.size.width > 450 {
                            // iPad 佈局：橫向排列
                            ipadsLayoutContent
                        } else {
                            // iPhone 佈局：垂直排列
                            iphoneLayoutContent
                        }
                    }
                    .frame(height: cardContentHeight)
                }

                Spacer()

                // 操作按鈕
                VStack(spacing: 8) {
                    // 查看按鈕
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(8)

                    // 刪除按鈕
                    Button(action: {
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetailView) {
            CalculatorTableDetailView(calculator: calculator, client: client)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // 計算卡片內容高度
    private var cardContentHeight: CGFloat {
        // 根據有多少資訊決定高度
        var height: CGFloat = 0

        // 第一列：要保人、被保人
        height += 24

        // 第二列：始期和繳費
        height += 20

        // 第三列：年繳和已累積
        height += 20

        // 第四列：身故保險金
        if getCurrentDeathBenefit(for: calculator) != nil {
            height += 20
        }

        // 第五列：受益人（可能換行，需要更多空間）
        if let beneficiary = calculator.beneficiary, !beneficiary.isEmpty {
            // 根據受益人文字長度決定高度
            let beneficiaryLength = beneficiary.count
            if beneficiaryLength > 20 {
                height += 40 // 長文字需要更多空間
            } else {
                height += 24
            }
        }

        return max(height, 120) // 最小高度 120
    }

    // MARK: - iPad 佈局（橫向排列）
    private var ipadsLayoutContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 第一列：要保人、被保險人
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 12))
                        .frame(width: 14)
                    Text("要保人：\(calculator.policyHolder ?? "-")")
                        .font(.system(size: 13))
                }
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)

                HStack(spacing: 4) {
                    Image(systemName: "person")
                        .font(.system(size: 12))
                        .frame(width: 14)
                    Text("被保人：\(calculator.insuredPerson ?? "-")")
                        .font(.system(size: 13))
                }
                .foregroundColor(.secondary)
            }

            // 第二列：保險始期、繳費年期
            HStack(spacing: 12) {
                if let startDate = calculator.startDate, !startDate.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .frame(width: 14)
                        Text("始期：\(startDate)")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.secondary)
                    .frame(width: 150, alignment: .leading)
                }

                if let paymentPeriod = calculator.paymentPeriod, !paymentPeriod.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 12))
                            .frame(width: 14)
                        Text("繳費：\(paymentPeriod)年")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.secondary)
                }
            }

            // 第三列：年繳保費、已累積保費
            HStack(spacing: 12) {
                if let annualPremium = calculator.annualPremium, !annualPremium.isEmpty, let amount = Double(annualPremium) {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 12))
                            .frame(width: 14)
                        Text("年繳：\(formatCurrency(amount))")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.secondary)
                    .frame(width: 150, alignment: .leading)
                }

                // 已累積保費
                if let accumulatedPremium = getAccumulatedPremium(for: calculator) {
                    HStack(spacing: 4) {
                        Image(systemName: "banknote")
                            .font(.system(size: 12))
                            .frame(width: 14)
                        Text("已累積：\(formatCurrency(accumulatedPremium))")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.secondary)
                }
            }

            // 第四列：身故保險金（粗體）
            if let deathBenefit = getCurrentDeathBenefit(for: calculator) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.circle")
                        .font(.system(size: 12))
                        .frame(width: 14)
                    Text("身故保險金：\(formatCurrency(deathBenefit))")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.secondary)
            }

            // 第五列：受益人（粗體）
            if let beneficiary = calculator.beneficiary, !beneficiary.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.system(size: 12))
                        .frame(width: 14)
                    Text("受益人：\(beneficiary)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - iPhone 佈局（垂直排列）
    private var iphoneLayoutContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 第一列：要保人、被保人
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 11))
                        .frame(width: 12)
                    Text("要保人：\(calculator.policyHolder ?? "-")")
                        .font(.system(size: 12))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 4) {
                    Image(systemName: "person")
                        .font(.system(size: 11))
                        .frame(width: 12)
                    Text("被保人：\(calculator.insuredPerson ?? "-")")
                        .font(.system(size: 12))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 第二列：始期和繳費年期
            HStack(spacing: 8) {
                if let startDate = calculator.startDate, !startDate.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .frame(width: 12)
                        Text("始期：\(startDate)")
                            .font(.system(size: 11))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let paymentPeriod = calculator.paymentPeriod, !paymentPeriod.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 11))
                            .frame(width: 12)
                        Text("繳費：\(paymentPeriod)年")
                            .font(.system(size: 11))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // 第三列：年繳和已累積
            HStack(spacing: 8) {
                if let annualPremium = calculator.annualPremium, !annualPremium.isEmpty, let amount = Double(annualPremium) {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 11))
                            .frame(width: 12)
                        Text("年繳：\(formatCurrency(amount))")
                            .font(.system(size: 11))
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let accumulatedPremium = getAccumulatedPremium(for: calculator) {
                    HStack(spacing: 4) {
                        Image(systemName: "banknote")
                            .font(.system(size: 11))
                            .frame(width: 12)
                        Text("已累積：\(formatCurrency(accumulatedPremium))")
                            .font(.system(size: 11))
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // 第四列：身故保險金（粗體）
            if let deathBenefit = getCurrentDeathBenefit(for: calculator) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.circle")
                        .font(.system(size: 11))
                        .frame(width: 12)
                    Text("身故保險金：")
                        .font(.system(size: 11))
                    + Text("\(formatCurrency(deathBenefit))")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            // 第五列：受益人（粗體）
            if let beneficiary = calculator.beneficiary, !beneficiary.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.system(size: 11))
                        .frame(width: 12)
                    Text("受益人：\(beneficiary)")
                        .font(.system(size: 12, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(.secondary)
            }
        }
    }

    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    // 格式化貨幣
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? "0")
    }

    // 取得當前年紀對應的身故保險金
    private func getCurrentDeathBenefit(for calculator: InsuranceCalculator) -> Double? {
        // 1. 取得客戶當前年齡
        guard let client = client, let birthDate = client.birthDate else {
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

        guard let policyStartDate = parseStartDate(startDate) else {
            return nil
        }

        let policyStartAgeComponents = calendar.dateComponents([.year], from: birthDate, to: policyStartDate)
        guard let policyStartAge = policyStartAgeComponents.year else {
            return nil
        }

        // 3. 計算當前是保單第幾年（保單年度 = 當前年齡 - 保單起始年齡 + 1）
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

    // 計算已累積保費
    private func getAccumulatedPremium(for calculator: InsuranceCalculator) -> Double? {
        // 1. 檢查保險始期和年繳保費是否存在
        guard let startDateString = calculator.startDate, !startDateString.isEmpty,
              let annualPremiumString = calculator.annualPremium, !annualPremiumString.isEmpty,
              let annualPremium = Double(annualPremiumString.replacingOccurrences(of: ",", with: "")) else {
            return nil
        }

        // 2. 解析保險始期日期
        guard let policyStartDate = parseStartDate(startDateString) else {
            return nil
        }

        // 3. 計算從保險始期到現在已經過了幾年
        let calendar = Calendar.current
        let now = Date()

        // 計算完整年份（從保險始期到今天）
        let yearComponents = calendar.dateComponents([.year, .month], from: policyStartDate, to: now)
        guard let years = yearComponents.year else {
            return nil
        }

        // 4. 計算已繳年數
        // 如果已經過了一個完整年度，則算一年；未滿一年則算0年
        let paidYears = max(0, years)

        // 5. 檢查是否超過繳費年期
        var finalPaidYears = paidYears
        if let paymentPeriodString = calculator.paymentPeriod, !paymentPeriodString.isEmpty {
            if let paymentPeriod = Int(paymentPeriodString.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) {
                // 如果已繳年數超過繳費年期，則以繳費年期為準
                finalPaidYears = min(paidYears, paymentPeriod)
            }
        }

        // 6. 計算累積保費
        let accumulatedPremium = Double(finalPaidYears) * annualPremium

        return accumulatedPremium
    }

    // 解析保險始期字串為 Date
    private func parseStartDate(_ dateString: String) -> Date? {
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
}

#Preview {
    InsuranceCalculatorView(client: nil)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .padding()
}
