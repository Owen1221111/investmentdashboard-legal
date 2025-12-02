import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct StructuredProductsDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingImportOptions = false
    @State private var showingFileImporter = false
    @State private var isExpanded = false
    @State private var showingColumnReorder = false
    @State private var showingExitedColumnReorder = false
    @State private var columnOrder: [String] = []
    @State private var productToDelete: StructuredProduct? = nil
    @State private var showingDeleteConfirmation = false
    @State private var showingTargetSelection = false
    @State private var isAddingToExited = false
    @State private var sortAscending = false  // 交易定價日排序方向（false=降序/新到舊，true=升序/舊到新）
    @State private var exitedSortAscending = false  // 已出場的排序方向
    @State private var isEditingOngoingField = false  // 追蹤是否正在編輯進行中的欄位
    @State private var isEditingExitedField = false  // 追蹤是否正在編輯已出場的欄位

    // 股價刷新管理（僅進行中）
    @State private var isRefreshingOngoing = false  // 進行中商品刷新狀態
    @State private var showingRefreshAlert = false  // 刷新結果提示
    @State private var refreshMessage = ""  // 刷新結果消息

    // 頁籤管理
    @State private var selectedCategory = "全部"  // 當前選擇的頁籤
    @State private var showingCategorySelector = false  // 顯示頁籤選擇對話框
    @State private var showingNewCategoryDialog = false  // 顯示新增頁籤對話框
    @State private var newCategoryName = ""  // 新頁籤名稱
    @State private var productToMove: StructuredProduct? = nil  // 待移動的商品
    @State private var customCategories: [String] = []  // 自訂分類列表
    @State private var categoryOrder: [String] = []  // 頁籤排序
    @State private var draggingCategory: String? = nil  // 正在拖曳的頁籤
    @State private var showingDeleteCategoryConfirmation = false  // 顯示刪除分類確認對話框
    @State private var categoryToDelete: String? = nil  // 待刪除的分類
    @State private var showingSubscription = false

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

    let client: Client?

    // FetchRequest 取得進行中的結構型商品資料
    @FetchRequest private var ongoingProducts: FetchedResults<StructuredProduct>

    // FetchRequest 取得已出場的結構型商品資料
    @FetchRequest private var exitedProducts: FetchedResults<StructuredProduct>

    init(client: Client?) {
        self.client = client

        // 設定 FetchRequest 以取得進行中的結構型商品資料
        if let client = client {
            _ongoingProducts = FetchRequest<StructuredProduct>(
                sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@ AND isExited == NO", client),
                animation: .default
            )
            _exitedProducts = FetchRequest<StructuredProduct>(
                sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@ AND isExited == YES", client),
                animation: .default
            )
        } else {
            _ongoingProducts = FetchRequest<StructuredProduct>(
                sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
            _exitedProducts = FetchRequest<StructuredProduct>(
                sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }

    private let headers = ["交易定價日", "商品代號", "標的", "發行日", "最終評價日", "期初價格", "執行價格", "保護價", "距離出場%", "現價", "利率", "月利率", "月領息", "KO%", "PUT%", "KI%", "幣別", "折合美金", "交易金額"]
    // 商品代號已在交易定價日右邊
    private let exitedHeaders = ["交易定價日", "標的", "發行日", "最終評價日", "利率", "月利率", "出場日", "持有月數", "實際收益", "交易金額", "實質收益", "備註"]

    @State private var isExitedExpanded = false
    @State private var exitedColumnOrder: [String] = []

    var body: some View {
        VStack(spacing: 16) {
            // 進行中的結構型商品
            VStack(spacing: 0) {
                tableHeader

                if isExpanded {
                    productsTable
                }
            }
            .background(
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                        : UIColor.white
                })
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)

            // 已出場的結構型商品
            VStack(spacing: 0) {
                exitedTableHeader

                if isExitedExpanded {
                    exitedProductsTable
                }
            }
            .background(
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                        : UIColor.white
                })
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        }
        .confirmationDialog("匯入資料", isPresented: $showingImportOptions, titleVisibility: .visible) {
            Button("從 CSV 檔案匯入") {
                showingFileImporter = true
            }
            Button("手動新增資料") {
                handleManualDataEntry()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("選擇匯入方式")
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.commaSeparatedText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .sheet(isPresented: $showingColumnReorder) {
            ColumnReorderView(
                headers: headers,
                initialOrder: columnOrder.isEmpty ? headers : columnOrder,
                onSave: { newOrder in
                    columnOrder = newOrder
                    // 儲存到 UserDefaults
                    UserDefaults.standard.set(newOrder, forKey: "StructuredProducts_ColumnOrder")
                }
            )
        }
        .sheet(isPresented: $showingExitedColumnReorder) {
            ColumnReorderView(
                headers: exitedHeaders,
                initialOrder: exitedColumnOrder.isEmpty ? exitedHeaders : exitedColumnOrder,
                onSave: { newOrder in
                    exitedColumnOrder = newOrder
                    // 儲存到 UserDefaults
                    UserDefaults.standard.set(newOrder, forKey: "StructuredProductsExited_ColumnOrder")
                }
            )
        }
        .onAppear {
            // 從 UserDefaults 讀取欄位排序，並加入新欄位
            if let savedOrder = UserDefaults.standard.array(forKey: "StructuredProducts_ColumnOrder") as? [String], !savedOrder.isEmpty {
                // 找出新增的欄位（在 headers 中但不在 savedOrder 中）
                let newColumns = headers.filter { !savedOrder.contains($0) }
                // 將新欄位加到最後
                columnOrder = savedOrder + newColumns
                // 移除已刪除的欄位
                columnOrder = columnOrder.filter { headers.contains($0) }
            } else if columnOrder.isEmpty {
                columnOrder = headers
            }

            if let savedExitedOrder = UserDefaults.standard.array(forKey: "StructuredProductsExited_ColumnOrder") as? [String], !savedExitedOrder.isEmpty {
                let newExitedColumns = exitedHeaders.filter { !savedExitedOrder.contains($0) }
                exitedColumnOrder = savedExitedOrder + newExitedColumns
                exitedColumnOrder = exitedColumnOrder.filter { exitedHeaders.contains($0) }
            } else if exitedColumnOrder.isEmpty {
                exitedColumnOrder = exitedHeaders
            }

            // 從 UserDefaults 讀取自訂分類
            loadCustomCategories()

            // 從 UserDefaults 讀取頁籤排序
            loadCategoryOrder()
        }
        .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) {
                productToDelete = nil
            }
            Button("刪除", role: .destructive) {
                if let product = productToDelete {
                    deleteProduct(product)
                    productToDelete = nil
                }
            }
        } message: {
            Text("確定要刪除此記錄嗎？此操作無法復原。")
        }
        .confirmationDialog("選擇標的數量", isPresented: $showingTargetSelection, titleVisibility: .visible) {
            Button("1 個標的") {
                createNewProduct(numberOfTargets: 1, isExited: isAddingToExited)
            }
            Button("2 個標的") {
                createNewProduct(numberOfTargets: 2, isExited: isAddingToExited)
            }
            Button("3 個標的") {
                createNewProduct(numberOfTargets: 3, isExited: isAddingToExited)
            }
            Button("4 個標的") {
                createNewProduct(numberOfTargets: 4, isExited: isAddingToExited)
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("請選擇此結構型商品的標的數量")
        }
        .confirmationDialog("選擇分類", isPresented: $showingCategorySelector, titleVisibility: .visible) {
            ForEach(availableCategories.filter { $0 != "全部" }, id: \.self) { category in
                Button(category) {
                    if productToMove != nil {
                        // 移至已出場
                        confirmMoveToExited(category: category)
                    } else if isAddingToExited {
                        // 新增已出場資料
                        selectedCategory = category
                        showingTargetSelection = true
                    }
                }
            }
            Button("新增分類...") {
                showingNewCategoryDialog = true
            }
            Button("取消", role: .cancel) {
                productToMove = nil
                if isAddingToExited {
                    isAddingToExited = false
                }
            }
        } message: {
            Text(productToMove != nil ? "請選擇要將此商品歸檔到哪個分類" : "請選擇新資料的分類")
        }
        .alert("新增分類", isPresented: $showingNewCategoryDialog) {
            TextField("分類名稱（例如：2024）", text: $newCategoryName)
            Button("取消", role: .cancel) {
                newCategoryName = ""
                if isAddingToExited && productToMove == nil {
                    isAddingToExited = false
                }
            }
            Button("確定") {
                if !newCategoryName.isEmpty {
                    if productToMove != nil {
                        // 移至已出場
                        confirmMoveToExited(category: newCategoryName)
                    } else if isAddingToExited {
                        // 新增已出場資料
                        selectedCategory = newCategoryName
                        showingTargetSelection = true
                    } else {
                        // 單純新增分類頁籤（加入自訂分類列表）
                        if !customCategories.contains(newCategoryName) {
                            customCategories.append(newCategoryName)
                            saveCustomCategories()
                        }
                        selectedCategory = newCategoryName
                    }
                    newCategoryName = ""
                }
            }
        } message: {
            Text("請輸入新的分類名稱")
        }
        .alert("股價更新", isPresented: $showingRefreshAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(refreshMessage)
        }
        .alert("確認刪除分類", isPresented: $showingDeleteCategoryConfirmation) {
            if let category = categoryToDelete {
                let productsInCategory = exitedProducts.filter { $0.exitCategory == category }.count
                if productsInCategory > 0 {
                    Button("確定") {
                        categoryToDelete = nil
                    }
                } else {
                    Button("取消", role: .cancel) {
                        categoryToDelete = nil
                    }
                    Button("刪除", role: .destructive) {
                        deleteCategory(category)
                        categoryToDelete = nil
                    }
                }
            } else {
                Button("取消", role: .cancel) {
                    categoryToDelete = nil
                }
            }
        } message: {
            if let category = categoryToDelete {
                let productsInCategory = exitedProducts.filter { $0.exitCategory == category }.count
                if productsInCategory > 0 {
                    Text("此分類中還有 \(productsInCategory) 個商品，無法刪除。請先將商品移至其他分類或刪除商品。")
                } else {
                    Text("確定要刪除「\(category)」分類嗎？")
                }
            } else {
                Text("確定要刪除此分類嗎？")
            }
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
                .environmentObject(subscriptionManager)
        }
    }

    // MARK: - 標題區域（含縮放功能）
    private var tableHeader: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 14))
                    Text("結構型明細")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                Spacer()

                HStack(spacing: 8) {
                    // 縮放按鈕
                    Button(action: {
                        // ⭐️ 移除動畫，避免複雜表格導致 UI 凍結
                        isExpanded.toggle()
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 刷新股價按鈕（排序按鈕左邊）
                    Button(action: {
                        refreshOngoingPrices()
                    }) {
                        if isRefreshingOngoing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                                .frame(width: 30, height: 30)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                                .padding(8)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .disabled(isRefreshingOngoing)

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
                        showingImportOptions = true
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        if !subscriptionManager.canAccessPremiumFeatures() {
                            showingSubscription = true
                        } else {
                            addNewRow()
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

    // MARK: - 結構型商品表格
    private var productsTable: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                // 表頭
                HStack(spacing: 0) {
                    // 刪除按鈕欄位
                    Text("")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(width: 40, alignment: .center)

                    ForEach(currentColumnOrder, id: \.self) { header in
                        if header == "交易定價日" {
                            // 交易定價日欄位加上排序按鈕
                            Button(action: {
                                sortAscending.toggle()
                            }) {
                                HStack(spacing: 4) {
                                    Text(header)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                                    Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 14)
                                .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Text(header)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 14)
                                .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                        }
                    }

                    // 移至已出場按鈕欄位
                    Text("出場")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(width: 50, alignment: .center)
                }
                .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

                // 分隔線
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)

                // 資料行容器
                LazyVStack(spacing: 0) {
                    ForEach(Array(sortedOngoingProducts.enumerated()), id: \.offset) { index, product in
                        HStack(spacing: 0) {
                            // 刪除按鈕（移到最左邊）
                            Button(action: {
                                productToDelete = product
                                showingDeleteConfirmation = true
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 8)
                            .frame(width: 40, alignment: .center)

                            ForEach(Array(currentColumnOrder.enumerated()), id: \.offset) { colIndex, header in
                                if header == "標的" {
                                    // 標的欄位特殊處理（支援多個標的）
                                    targetsCell(for: product)
                                        .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                } else if header == "期初價格" {
                                    // 期初價格欄位特殊處理（支援多個期初價格）
                                    initialPricesCell(for: product)
                                        .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                } else if header == "執行價格" {
                                    // 執行價格欄位特殊處理（支援多個執行價格）
                                    strikePricesCell(for: product)
                                        .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                } else if header == "保護價" {
                                    // 保護價欄位特殊處理（支援多個保護價）
                                    protectionPricesCell(for: product)
                                        .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                } else if header == "距離出場%" {
                                    // 距離出場%欄位特殊處理（支援多個距離出場%）
                                    distanceToExitCell(for: product)
                                        .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                } else if header == "現價" {
                                    // 現價欄位特殊處理（支援多個現價）
                                    currentPricesCell(for: product)
                                        .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                } else if header == "幣別" {
                                    // 幣別使用下拉選單
                                    Menu {
                                        Button("USD") { setProductCurrency(product, value: "USD") }
                                        Button("TWD") { setProductCurrency(product, value: "TWD") }
                                        Button("EUR") { setProductCurrency(product, value: "EUR") }
                                        Button("JPY") { setProductCurrency(product, value: "JPY") }
                                        Button("GBP") { setProductCurrency(product, value: "GBP") }
                                        Button("CNY") { setProductCurrency(product, value: "CNY") }
                                        Button("AUD") { setProductCurrency(product, value: "AUD") }
                                        Button("CAD") { setProductCurrency(product, value: "CAD") }
                                        Button("CHF") { setProductCurrency(product, value: "CHF") }
                                        Button("HKD") { setProductCurrency(product, value: "HKD") }
                                        Button("SGD") { setProductCurrency(product, value: "SGD") }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(product.currency?.isEmpty == false ? product.currency! : "USD")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                                .fixedSize(horizontal: true, vertical: false)

                                            Spacer(minLength: 0)

                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 9))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 12)
                                        .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                        .background(Color(.systemGray6).opacity(0.3))
                                        .cornerRadius(4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    TextField("", text: bindingForProduct(product, header: header), onEditingChanged: { isEditing in
                                        // 追蹤編輯狀態，避免排序時列表跳動
                                        isEditingOngoingField = isEditing
                                    })
                                        .font(.system(size: 15, weight: .medium))
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 12)
                                        .frame(minWidth: getColumnWidth(for: header), alignment: .center)
                                        .background(Color.clear)
                                }
                            }

                            // 移至已出場按鈕
                            Button(action: {
                                moveToExited(product)
                            }) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 8)
                            .frame(width: 50, alignment: .center)
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

                    // 合計行
                    summaryRow
                }
            }
        }
    }

    // MARK: - 合計行
    private var summaryRow: some View {
        HStack(spacing: 0) {
            // 刪除按鈕欄位（空白）
            Text("")
                .frame(width: 40, alignment: .center)

            ForEach(Array(currentColumnOrder.enumerated()), id: \.offset) { colIndex, header in
                Group {
                    if header == "標的" {
                        Text("合計")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .frame(minWidth: getColumnWidth(for: header), maxWidth: getColumnWidth(for: header), alignment: .center)
                    } else if header == "折合美金" {
                        VStack(spacing: 0) {
                            Text(formatNumberWithCommas(String(getTotalConvertedToUSD())))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                                .lineLimit(1)

                            Rectangle()
                                .fill(Color.green)
                                .frame(height: 2)
                                .padding(.top, 2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(minWidth: getColumnWidth(for: header), maxWidth: getColumnWidth(for: header), alignment: .center)
                    } else if header == "交易金額" {
                        VStack(spacing: 0) {
                            Text(formatNumberWithCommas(String(getTotalTransactionAmount())))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                                .lineLimit(1)

                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 2)
                                .padding(.top, 2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(minWidth: getColumnWidth(for: header), maxWidth: getColumnWidth(for: header), alignment: .center)
                    } else {
                        // 其他欄位空白
                        Text("")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .frame(minWidth: getColumnWidth(for: header), maxWidth: getColumnWidth(for: header), alignment: .center)
                    }
                }
            }

            // 移至已出場按鈕欄位（空白）
            Text("")
                .frame(width: 50, alignment: .center)
        }
        .background(Color.blue.opacity(0.08))
        .overlay(
            VStack {
                Divider()
                    .background(Color.blue.opacity(0.3))
                Spacer()
            }
        )
    }

    // MARK: - 已出場表格標題區域
    private var exitedTableHeader: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("結構型已出場")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                Spacer()

                HStack(spacing: 8) {
                    // 縮放按鈕
                    Button(action: {
                        // ⭐️ 移除動畫，避免複雜表格導致 UI 凍結
                        isExitedExpanded.toggle()
                    }) {
                        Image(systemName: isExitedExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        showingExitedColumnReorder = true
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
                            addExitedRow()
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

            // 頁籤選擇器
            if isExitedExpanded {
                Divider()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableCategories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                                    .font(.system(size: 14, weight: selectedCategory == category ? .semibold : .regular))
                                    .foregroundColor(selectedCategory == category ? .white : .blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.blue : Color.blue.opacity(0.1))
                                    .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                // 只有非「全部」的頁籤才能刪除
                                if category != "全部" {
                                    Button(role: .destructive) {
                                        categoryToDelete = category
                                        showingDeleteCategoryConfirmation = true
                                    } label: {
                                        Label("刪除分類", systemImage: "trash")
                                    }
                                }
                            }
                            .onDrag {
                                // 只有非「全部」的頁籤才能拖拽
                                if category != "全部" {
                                    print("🔵 開始拖曳: \(category)")
                                    draggingCategory = category
                                    return NSItemProvider(object: category as NSString)
                                }
                                return NSItemProvider()
                            }
                            .onDrop(of: [.plainText], delegate: CategoryDropDelegate(
                                category: category,
                                categories: $categoryOrder,
                                availableCategories: availableCategories,
                                draggingCategory: $draggingCategory,
                                onReorder: saveCategoryOrder
                            ))
                        }

                        // 新增分類按鈕
                        Button(action: {
                            showingNewCategoryDialog = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 14))
                                Text("新增分類")
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

                Divider()
            }
        }
    }

    // MARK: - 已出場結構型商品表格
    private var exitedProductsTable: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                // 表頭
                HStack(spacing: 0) {
                    // 刪除按鈕欄位
                    Text("")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(width: 40, alignment: .center)

                    ForEach(currentExitedColumnOrder, id: \.self) { header in
                        if header == "交易定價日" {
                            // 交易定價日欄位加上排序按鈕
                            Button(action: {
                                exitedSortAscending.toggle()
                            }) {
                                HStack(spacing: 4) {
                                    Text(header)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                                    Image(systemName: exitedSortAscending ? "arrow.up" : "arrow.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 14)
                                .frame(minWidth: getExitedColumnWidth(for: header), alignment: .center)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Text(header)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 14)
                                .frame(minWidth: getExitedColumnWidth(for: header), alignment: .center)
                        }
                    }

                    // 更改分類按鈕欄位
                    Text("分類")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 14)
                        .frame(width: 70, alignment: .center)
                }
                .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

                // 分隔線
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)

                // 資料行容器
                LazyVStack(spacing: 0) {
                    ForEach(Array(sortedExitedProducts.enumerated()), id: \.offset) { index, product in
                        HStack(spacing: 0) {
                            // 刪除按鈕
                            Button(action: {
                                productToDelete = product
                                showingDeleteConfirmation = true
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 8)
                            .frame(width: 40, alignment: .center)

                            ForEach(Array(currentExitedColumnOrder.enumerated()), id: \.offset) { colIndex, header in
                                if header == "標的" {
                                    targetsCell(for: product)
                                        .frame(minWidth: getExitedColumnWidth(for: header), alignment: .center)
                                } else if header == "實質收益" {
                                    // 實質收益為自動計算欄位（唯讀，灰色背景）
                                    Text(bindingForExitedProduct(product, header: header).wrappedValue)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(.secondaryLabel))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 12)
                                        .frame(minWidth: getExitedColumnWidth(for: header), alignment: .center)
                                        .background(Color(.tertiarySystemBackground))
                                } else {
                                    TextField("", text: bindingForExitedProduct(product, header: header), onEditingChanged: { isEditing in
                                        // 追蹤編輯狀態，避免排序時列表跳動
                                        isEditingExitedField = isEditing
                                    })
                                        .font(.system(size: 15, weight: .medium))
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 12)
                                        .frame(minWidth: getExitedColumnWidth(for: header), alignment: .center)
                                        .background(Color.clear)
                                }
                            }

                            // 更改分類按鈕
                            Button(action: {
                                productToMove = product
                                isAddingToExited = false  // 確保不是新增模式
                                showingCategorySelector = true
                            }) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 8)
                            .frame(width: 70, alignment: .center)
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
                }

                // ⭐️ 合計行
                HStack(spacing: 0) {
                    // 空白欄（刪除按鈕欄位）
                    Text("")
                        .frame(width: 40, alignment: .center)

                    ForEach(currentExitedColumnOrder, id: \.self) { header in
                        if header == "實質收益" {
                            // 實質收益合計
                            Text(formatNumberWithCommas(String(format: "%.2f", calculateExitedTotalRealProfit())))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                                .frame(minWidth: getExitedColumnWidth(for: header), alignment: .center)
                                .background(Color.yellow.opacity(0.15))
                        } else if header == "交易定價日" {
                            // 第一欄顯示「合計」文字
                            Text("合計")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                                .frame(minWidth: getExitedColumnWidth(for: header), alignment: .center)
                                .background(Color.yellow.opacity(0.15))
                        } else {
                            // 其他欄位空白
                            Text("")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                                .frame(minWidth: getExitedColumnWidth(for: header), alignment: .center)
                                .background(Color.yellow.opacity(0.15))
                        }
                    }

                    // 出場按鈕欄位（空白）
                    Text("")
                        .frame(width: 70, alignment: .center)
                        .background(Color.yellow.opacity(0.15))
                }
                .overlay(
                    VStack {
                        Divider()
                            .background(Color.orange)
                        Spacer()
                        Divider()
                            .background(Color.orange)
                    }
                )
            }
        }
    }

    // ⭐️ 計算已出場商品的實質收益合計
    private func calculateExitedTotalRealProfit() -> Double {
        return exitedProducts.reduce(0.0) { total, product in
            let actualReturnStr = removeCommas(product.actualReturn ?? "")
                .replacingOccurrences(of: "%", with: "")
                .trimmingCharacters(in: .whitespaces)
            let transactionAmountStr = removeCommas(product.transactionAmount ?? "")

            if let actualReturn = Double(actualReturnStr),
               let transactionAmount = Double(transactionAmountStr),
               !actualReturnStr.isEmpty && !transactionAmountStr.isEmpty {
                let realProfit = actualReturn * transactionAmount
                return total + realProfit
            }
            return total
        }
    }

    // MARK: - 標的欄位（支援4個標的）
    private func targetsCell(for product: StructuredProduct) -> some View {
        let effectiveTargetCount = getEffectiveTargetCount(for: product)

        return VStack(alignment: .leading, spacing: 2) {
            if effectiveTargetCount >= 1 {
                TextField("標的1", text: Binding(
                    get: { product.target1 ?? "" },
                    set: { product.target1 = $0; saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 2 {
                TextField("標的2", text: Binding(
                    get: { product.target2 ?? "" },
                    set: { product.target2 = $0; saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 3 {
                TextField("標的3", text: Binding(
                    get: { product.target3 ?? "" },
                    set: { product.target3 = $0; saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 4 {
                TextField("標的4", text: Binding(
                    get: { product.target4 ?? "" },
                    set: { product.target4 = $0; saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    // 取得有效的標的數量（兼容舊資料）
    private func getEffectiveTargetCount(for product: StructuredProduct) -> Int {
        // 如果 numberOfTargets 有設定且不為 0，就使用它
        if product.numberOfTargets > 0 {
            return Int(product.numberOfTargets)
        }

        // 否則根據實際有填寫的標的來判斷（兼容舊資料）
        var count = 0
        if !(product.target1 ?? "").isEmpty { count = 1 }
        if !(product.target2 ?? "").isEmpty { count = 2 }
        if !(product.target3 ?? "").isEmpty { count = 3 }
        if !(product.target4 ?? "").isEmpty { count = 4 }

        // 如果都沒有資料，預設至少顯示 1 個欄位
        return max(count, 1)
    }

    // MARK: - 期初價格欄位（支援4個價格）
    private func initialPricesCell(for product: StructuredProduct) -> some View {
        let effectiveTargetCount = getEffectiveTargetCount(for: product)

        return VStack(alignment: .leading, spacing: 2) {
            if effectiveTargetCount >= 1 {
                TextField("價格1", text: Binding(
                    get: { formatNumberWithCommas(product.initialPrice1) },
                    set: {
                        product.initialPrice1 = removeCommas($0)
                        calculateDistanceToExit(for: product)
                        calculateStrikeAndProtectionPrices(for: product)
                        saveContext()
                    }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 2 {
                TextField("價格2", text: Binding(
                    get: { formatNumberWithCommas(product.initialPrice2) },
                    set: {
                        product.initialPrice2 = removeCommas($0)
                        calculateDistanceToExit(for: product)
                        calculateStrikeAndProtectionPrices(for: product)
                        saveContext()
                    }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 3 {
                TextField("價格3", text: Binding(
                    get: { formatNumberWithCommas(product.initialPrice3) },
                    set: {
                        product.initialPrice3 = removeCommas($0)
                        calculateDistanceToExit(for: product)
                        calculateStrikeAndProtectionPrices(for: product)
                        saveContext()
                    }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 4 {
                TextField("價格4", text: Binding(
                    get: { formatNumberWithCommas(product.initialPrice4) },
                    set: {
                        product.initialPrice4 = removeCommas($0)
                        calculateDistanceToExit(for: product)
                        calculateStrikeAndProtectionPrices(for: product)
                        saveContext()
                    }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    // MARK: - 執行價格欄位（支援4個價格）
    private func strikePricesCell(for product: StructuredProduct) -> some View {
        let effectiveTargetCount = getEffectiveTargetCount(for: product)

        return VStack(alignment: .leading, spacing: 2) {
            if effectiveTargetCount >= 1 {
                TextField("執行價1", text: Binding(
                    get: { formatNumberWithCommas(product.strikePrice1) },
                    set: { product.strikePrice1 = removeCommas($0); saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 2 {
                TextField("執行價2", text: Binding(
                    get: { formatNumberWithCommas(product.strikePrice2) },
                    set: { product.strikePrice2 = removeCommas($0); saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 3 {
                TextField("執行價3", text: Binding(
                    get: { formatNumberWithCommas(product.strikePrice3) },
                    set: { product.strikePrice3 = removeCommas($0); saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 4 {
                TextField("執行價4", text: Binding(
                    get: { formatNumberWithCommas(product.strikePrice4) },
                    set: { product.strikePrice4 = removeCommas($0); saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    // MARK: - 保護價欄位（支援4個價格）
    private func protectionPricesCell(for product: StructuredProduct) -> some View {
        let effectiveTargetCount = getEffectiveTargetCount(for: product)

        return VStack(alignment: .leading, spacing: 2) {
            if effectiveTargetCount >= 1 {
                TextField("保護價1", text: Binding(
                    get: { formatNumberWithCommas(product.protectionPrice1) },
                    set: { product.protectionPrice1 = removeCommas($0); saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 2 {
                TextField("保護價2", text: Binding(
                    get: { formatNumberWithCommas(product.protectionPrice2) },
                    set: { product.protectionPrice2 = removeCommas($0); saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 3 {
                TextField("保護價3", text: Binding(
                    get: { formatNumberWithCommas(product.protectionPrice3) },
                    set: { product.protectionPrice3 = removeCommas($0); saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 4 {
                TextField("保護價4", text: Binding(
                    get: { formatNumberWithCommas(product.protectionPrice4) },
                    set: { product.protectionPrice4 = removeCommas($0); saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    // MARK: - 距離出場%欄位（支援4個百分比）
    private func distanceToExitCell(for product: StructuredProduct) -> some View {
        let effectiveTargetCount = getEffectiveTargetCount(for: product)

        return VStack(alignment: .leading, spacing: 2) {
            if effectiveTargetCount >= 1 {
                TextField("距離1", text: Binding(
                    get: { product.distanceToExit1 ?? "" },
                    set: { product.distanceToExit1 = $0; saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 2 {
                TextField("距離2", text: Binding(
                    get: { product.distanceToExit2 ?? "" },
                    set: { product.distanceToExit2 = $0; saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 3 {
                TextField("距離3", text: Binding(
                    get: { product.distanceToExit3 ?? "" },
                    set: { product.distanceToExit3 = $0; saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 4 {
                TextField("距離4", text: Binding(
                    get: { product.distanceToExit4 ?? "" },
                    set: { product.distanceToExit4 = $0; saveContext() }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    // MARK: - 現價欄位（支援4個現價）
    private func currentPricesCell(for product: StructuredProduct) -> some View {
        let effectiveTargetCount = getEffectiveTargetCount(for: product)

        return VStack(alignment: .leading, spacing: 2) {
            if effectiveTargetCount >= 1 {
                TextField("現價1", text: Binding(
                    get: { formatNumberWithCommas(product.currentPrice1) },
                    set: {
                        product.currentPrice1 = removeCommas($0)
                        calculateDistanceToExit(for: product)
                        saveContext()
                    }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.cyan.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 2 {
                TextField("現價2", text: Binding(
                    get: { formatNumberWithCommas(product.currentPrice2) },
                    set: {
                        product.currentPrice2 = removeCommas($0)
                        calculateDistanceToExit(for: product)
                        saveContext()
                    }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.cyan.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 3 {
                TextField("現價3", text: Binding(
                    get: { formatNumberWithCommas(product.currentPrice3) },
                    set: {
                        product.currentPrice3 = removeCommas($0)
                        calculateDistanceToExit(for: product)
                        saveContext()
                    }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.cyan.opacity(0.1))
                .cornerRadius(4)
            }

            if effectiveTargetCount >= 4 {
                TextField("現價4", text: Binding(
                    get: { formatNumberWithCommas(product.currentPrice4) },
                    set: {
                        product.currentPrice4 = removeCommas($0)
                        calculateDistanceToExit(for: product)
                        saveContext()
                    }
                ))
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.cyan.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    // MARK: - 計算屬性
    private var currentColumnOrder: [String] {
        return columnOrder.isEmpty ? headers : columnOrder
    }

    private var currentExitedColumnOrder: [String] {
        return exitedColumnOrder.isEmpty ? exitedHeaders : exitedColumnOrder
    }

    // 獲取所有已存在的分類（頁籤）
    private var availableCategories: [String] {
        let categoriesFromProducts = Set(exitedProducts.compactMap { $0.exitCategory }.filter { !$0.isEmpty })
        let allCategories = categoriesFromProducts.union(customCategories)

        // 如果有自訂排序，使用自訂排序
        if !categoryOrder.isEmpty {
            // 先取得已排序的分類
            let orderedCategories = categoryOrder.filter { allCategories.contains($0) }
            // 再加上不在排序中的新分類（按字母排序）
            let newCategories = allCategories.filter { !categoryOrder.contains($0) }.sorted()
            return ["全部"] + orderedCategories + newCategories
        } else {
            // 沒有自訂排序時，使用字母排序
            return ["全部"] + allCategories.sorted()
        }
    }

    // 根據選擇的分類篩選已出場商品
    private var filteredExitedProducts: [StructuredProduct] {
        if selectedCategory == "全部" {
            return Array(exitedProducts)
        } else {
            return exitedProducts.filter { $0.exitCategory == selectedCategory }
        }
    }

    // 排序後的進行中商品
    private var sortedOngoingProducts: [StructuredProduct] {
        let products = Array(ongoingProducts)

        // 如果正在編輯，則不進行排序，保持原始順序避免跳動
        if isEditingOngoingField {
            return products
        }

        return products.sorted { product1, product2 in
            let date1 = parseTradePricingDate(product1.tradePricingDate ?? "")
            let date2 = parseTradePricingDate(product2.tradePricingDate ?? "")

            if sortAscending {
                return date1 < date2  // 升序（舊到新）
            } else {
                return date1 > date2  // 降序（新到舊）
            }
        }
    }

    // 排序後的已出場商品（先篩選分類，再排序）
    private var sortedExitedProducts: [StructuredProduct] {
        // 如果正在編輯，則不進行排序，保持原始順序避免跳動
        if isEditingExitedField {
            return filteredExitedProducts
        }

        return filteredExitedProducts.sorted { product1, product2 in
            let date1 = parseTradePricingDate(product1.tradePricingDate ?? "")
            let date2 = parseTradePricingDate(product2.tradePricingDate ?? "")

            if exitedSortAscending {
                return date1 < date2  // 升序（舊到新）
            } else {
                return date1 > date2  // 降序（新到舊）
            }
        }
    }

    // 計算交易金額總和（進行中商品）
    private func getTotalTransactionAmount() -> Double {
        return ongoingProducts.reduce(0.0) { sum, product in
            let amount = Double(removeCommas(product.transactionAmount ?? "")) ?? 0
            return sum + amount
        }
    }

    // 計算折合美金總和（進行中商品）
    private func getTotalConvertedToUSD() -> Double {
        return ongoingProducts.reduce(0.0) { sum, product in
            let currency = product.currency ?? "USD"

            // USD 直接加交易金額
            if currency == "USD" {
                let amount = Double(removeCommas(product.transactionAmount ?? "")) ?? 0
                return sum + amount
            }

            // 非 USD 使用折合美金
            let convertedUSDStr = calculateConvertedToUSD(product: product)
            if !convertedUSDStr.isEmpty, let convertedUSD = Double(convertedUSDStr) {
                return sum + convertedUSD
            }

            return sum
        }
    }

    // 解析交易定價日字串為 Date（支援多種格式）
    private func parseTradePricingDate(_ dateString: String) -> Date {
        let trimmed = dateString.trimmingCharacters(in: .whitespaces)

        // 如果是空字串，返回一個很舊的日期（讓空白資料排在最後）
        if trimmed.isEmpty {
            return Date(timeIntervalSince1970: 0)
        }

        // 定義多種日期格式
        let dateFormatters: [DateFormatter] = {
            let formats = [
                "MMM d yyyy",     // Sep 8 2023
                "MMM dd yyyy",    // Sep 08 2023
                "yyyy-MM-dd",     // 2023-09-08
                "yyyy/MM/dd",     // 2023/09/08
                "yyyy/M/d",       // 2025/3/4
                "yyyy-M-d",       // 2025-3-4
                "dd/MM/yyyy",     // 08/09/2023
                "MM/dd/yyyy",     // 09/08/2023
                "M/d/yyyy"        // 3/4/2025
            ]

            return formats.map { format in
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }
        }()

        // 嘗試各種格式
        for formatter in dateFormatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        // 如果無法解析，返回一個很舊的日期
        return Date(timeIntervalSince1970: 0)
    }

    // MARK: - 欄位寬度
    private func getColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "交易定價日": return 120
        case "商品代號": return 100
        case "標的": return 150
        case "發行日": return 100
        case "最終評價日": return 120
        case "期初價格": return 150
        case "執行價格": return 120
        case "保護價": return 120
        case "距離出場%": return 100
        case "現價": return 150
        case "利率": return 80
        case "月利率": return 80
        case "月領息": return 100
        case "KO%": return 80
        case "PUT%": return 80
        case "KI%": return 80
        case "幣別": return 90
        case "折合美金": return 120
        case "交易金額": return 120
        default: return 100
        }
    }

    private func getExitedColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "交易定價日": return 120
        case "標的": return 150
        case "發行日": return 100
        case "最終評價日": return 120
        case "利率": return 80
        case "月利率": return 80
        case "出場日": return 100
        case "持有月數": return 100
        case "實際收益": return 120
        case "交易金額": return 120
        case "實質收益": return 120
        case "備註": return 150
        default: return 100
        }
    }

    // MARK: - 資料綁定
    private func bindingForProduct(_ product: StructuredProduct, header: String) -> Binding<String> {
        Binding<String>(
            get: {
                let rawValue: String
                switch header {
                case "交易定價日": rawValue = product.tradePricingDate ?? ""
                case "商品代號": rawValue = product.productCode ?? ""
                case "發行日": rawValue = product.issueDate ?? ""
                case "最終評價日": rawValue = product.finalValuationDate ?? ""
                case "利率": rawValue = product.interestRate ?? ""
                case "月利率":
                    // 自動計算：利率 ÷ 12
                    if let interestRateStr = product.interestRate,
                       !interestRateStr.isEmpty {
                        // 移除逗號和百分比符號
                        let cleanStr = interestRateStr
                            .replacingOccurrences(of: ",", with: "")
                            .replacingOccurrences(of: "%", with: "")
                            .trimmingCharacters(in: .whitespaces)

                        if let interestRate = Double(cleanStr), interestRate > 0 {
                            let monthlyRate = interestRate / 12.0
                            rawValue = String(format: "%.2f%%", monthlyRate)
                        } else {
                            rawValue = ""
                        }
                    } else {
                        rawValue = ""
                    }
                case "月領息":
                    // ⭐️ 自動計算：交易金額 × 月利率
                    if let transactionAmountStr = product.transactionAmount,
                       !transactionAmountStr.isEmpty,
                       let interestRateStr = product.interestRate,
                       !interestRateStr.isEmpty {
                        // 移除逗號
                        let cleanAmount = transactionAmountStr.replacingOccurrences(of: ",", with: "")
                        let cleanRate = interestRateStr
                            .replacingOccurrences(of: ",", with: "")
                            .replacingOccurrences(of: "%", with: "")
                            .trimmingCharacters(in: .whitespaces)

                        if let amount = Double(cleanAmount),
                           let rate = Double(cleanRate),
                           amount > 0, rate > 0 {
                            let monthlyRate = rate / 12.0
                            let monthlyInterest = amount * (monthlyRate / 100.0)
                            rawValue = String(format: "%.2f", monthlyInterest)
                        } else {
                            rawValue = ""
                        }
                    } else {
                        rawValue = ""
                    }
                case "KO%": rawValue = product.koPercentage ?? ""
                case "PUT%": rawValue = product.putPercentage ?? ""
                case "KI%": rawValue = product.kiPercentage ?? ""
                case "幣別": rawValue = product.currency ?? "USD"
                case "折合美金": rawValue = calculateConvertedToUSD(product: product)
                case "交易金額": rawValue = product.transactionAmount ?? ""
                default: rawValue = ""
                }

                // 如果是數字欄位，加上千分位（月利率和月領息除外，因為已經格式化）
                if header == "月利率" || header == "月領息" {
                    return rawValue
                }
                return isNumberField(header) ? formatNumberWithCommas(rawValue) : rawValue
            },
            set: { newValue in
                // 月利率、月領息和折合美金是唯讀欄位，不儲存
                if header == "月利率" || header == "月領息" || header == "折合美金" {
                    return
                }

                // 移除千分位後儲存
                let cleanValue = isNumberField(header) ? removeCommas(newValue) : newValue

                switch header {
                case "交易定價日": product.tradePricingDate = cleanValue
                case "商品代號": product.productCode = cleanValue
                case "發行日": product.issueDate = cleanValue
                case "最終評價日": product.finalValuationDate = cleanValue
                case "利率":
                    product.interestRate = cleanValue
                    // 當利率更新時，自動更新月利率（儲存時也帶%符號）
                    let rateStr = cleanValue
                        .replacingOccurrences(of: ",", with: "")
                        .replacingOccurrences(of: "%", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    if let rate = Double(rateStr), rate > 0 {
                        product.monthlyRate = String(format: "%.2f%%", rate / 12.0)
                    } else {
                        product.monthlyRate = ""
                    }
                case "KO%":
                    product.koPercentage = cleanValue
                case "PUT%":
                    product.putPercentage = cleanValue
                    calculateStrikeAndProtectionPrices(for: product)
                case "KI%":
                    product.kiPercentage = cleanValue
                    calculateStrikeAndProtectionPrices(for: product)
                case "幣別": product.currency = cleanValue
                case "交易金額": product.transactionAmount = cleanValue
                default: break
                }

                saveContext()
            }
        )
    }

    private func bindingForExitedProduct(_ product: StructuredProduct, header: String) -> Binding<String> {
        Binding<String>(
            get: {
                let rawValue: String
                switch header {
                case "交易定價日": rawValue = product.tradePricingDate ?? ""
                case "發行日": rawValue = product.issueDate ?? ""
                case "最終評價日": rawValue = product.finalValuationDate ?? ""
                case "利率": rawValue = product.interestRate ?? ""
                case "月利率": rawValue = product.monthlyRate ?? ""
                case "出場日": rawValue = product.exitDate ?? ""
                case "持有月數": rawValue = product.holdingMonths ?? ""
                case "實際收益": rawValue = product.actualReturn ?? ""
                case "交易金額": rawValue = product.transactionAmount ?? ""
                case "實質收益":
                    // 自動計算：實際收益 × 交易金額
                    let actualReturnStr = removeCommas(product.actualReturn ?? "")
                    let transactionAmountStr = removeCommas(product.transactionAmount ?? "")

                    // 移除百分比符號（如果有）
                    let cleanActualReturn = actualReturnStr
                        .replacingOccurrences(of: "%", with: "")
                        .trimmingCharacters(in: .whitespaces)

                    if let actualReturn = Double(cleanActualReturn),
                       let transactionAmount = Double(transactionAmountStr),
                       !cleanActualReturn.isEmpty && !transactionAmountStr.isEmpty {
                        // 如果實際收益是百分比形式，需要除以 100
                        let returnRate = actualReturnStr.contains("%") ? actualReturn / 100 : actualReturn
                        let realProfit = returnRate * transactionAmount
                        rawValue = String(format: "%.2f", realProfit)
                    } else {
                        rawValue = product.realProfit ?? ""
                    }
                case "備註": rawValue = product.notes ?? ""
                default: rawValue = ""
                }

                // 如果是數字欄位，加上千分位
                return isExitedNumberField(header) ? formatNumberWithCommas(rawValue) : rawValue
            },
            set: { newValue in
                // 實質收益為唯讀欄位，不允許手動修改
                if header == "實質收益" {
                    return
                }

                // 移除千分位後儲存
                let cleanValue = isExitedNumberField(header) ? removeCommas(newValue) : newValue

                switch header {
                case "交易定價日": product.tradePricingDate = cleanValue
                case "發行日": product.issueDate = cleanValue
                case "最終評價日": product.finalValuationDate = cleanValue
                case "利率": product.interestRate = cleanValue
                case "月利率": product.monthlyRate = cleanValue
                case "出場日": product.exitDate = cleanValue
                case "持有月數": product.holdingMonths = cleanValue
                case "實際收益":
                    product.actualReturn = cleanValue
                    // 當實際收益更新時，自動重新計算實質收益
                    recalculateRealProfit(product: product)
                case "交易金額":
                    product.transactionAmount = cleanValue
                    // 當交易金額更新時，自動重新計算實質收益
                    recalculateRealProfit(product: product)
                case "備註": product.notes = cleanValue
                default: break
                }

                saveContext()
            }
        )
    }

    // MARK: - 格式化輔助函數
    private func formatNumberWithCommas(_ value: String?) -> String {
        guard let value = value, !value.isEmpty else { return "" }

        // 移除現有的逗號
        let cleanValue = value.replacingOccurrences(of: ",", with: "")

        // 如果可以轉換成數字，加上千分位
        if let number = Double(cleanValue) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: number)) ?? cleanValue
        }

        return cleanValue
    }

    private func removeCommas(_ value: String) -> String {
        return value.replacingOccurrences(of: ",", with: "")
    }

    // MARK: - 計算折合美金
    private func calculateConvertedToUSD(product: StructuredProduct) -> String {
        let currency = product.currency ?? "USD"

        // USD 不需要轉換
        if currency == "USD" {
            return ""
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
        default: return ""
        }

        guard !rate.isEmpty, let rateValue = Double(rate), rateValue > 0 else {
            return ""
        }

        // 取得交易金額
        let amountString = removeCommas(product.transactionAmount ?? "")
        guard let amount = Double(amountString), amount > 0 else {
            return ""
        }

        // 計算折合美金 = 交易金額 ÷ 匯率
        let convertedUSD = amount / rateValue
        return String(format: "%.2f", convertedUSD)
    }

    // 判斷是否為數字欄位
    private func isNumberField(_ header: String) -> Bool {
        let textFields = ["交易定價日", "商品代號", "發行日", "最終評價日"]
        return !textFields.contains(header)
    }

    private func isExitedNumberField(_ header: String) -> Bool {
        let textFields = ["交易定價日", "發行日", "最終評價日", "出場日", "備註"]
        return !textFields.contains(header)
    }

    private func saveContext() {
        do {
            try viewContext.save()
            // 使用 DispatchQueue 延遲同步，避免短時間內多次保存
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                PersistenceController.shared.save()
            }
        } catch {
            print("❌ 儲存失敗: \(error)")
        }
    }

    // 設定結構型商品幣別
    private func setProductCurrency(_ product: StructuredProduct, value: String) {
        product.currency = value
        saveContext()
    }

    // MARK: - 自動計算功能
    private func recalculateRealProfit(product: StructuredProduct) {
        // 移除千分位和百分比符號
        let actualReturnStr = removeCommas(product.actualReturn ?? "")
        let transactionAmountStr = removeCommas(product.transactionAmount ?? "")

        let cleanActualReturn = actualReturnStr
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespaces)

        // 計算實質收益 = 實際收益 × 交易金額
        if let actualReturn = Double(cleanActualReturn),
           let transactionAmount = Double(transactionAmountStr),
           !cleanActualReturn.isEmpty && !transactionAmountStr.isEmpty {
            // 如果實際收益是百分比形式，需要除以 100
            let returnRate = actualReturnStr.contains("%") ? actualReturn / 100 : actualReturn
            let realProfit = returnRate * transactionAmount
            product.realProfit = String(format: "%.2f", realProfit)
        } else {
            product.realProfit = ""
        }
    }

    // MARK: - 編輯和刪除功能
    private func deleteProduct(_ product: StructuredProduct) {
        withAnimation {
            viewContext.delete(product)
            do {
                try viewContext.save()
                DispatchQueue.main.async {
                    PersistenceController.shared.save()
                    print("✅ 結構型商品已刪除並同步到 iCloud")
                }
            } catch {
                print("❌ 刪除失敗: \(error)")
            }
        }
    }

    private func deleteLastRow() {
        if let lastProduct = ongoingProducts.last {
            deleteProduct(lastProduct)
        }
    }

    private func moveToExited(_ product: StructuredProduct) {
        // 先儲存商品，然後顯示分類選擇對話框
        productToMove = product
        isAddingToExited = false  // 確保不是新增模式
        showingCategorySelector = true
    }

    private func confirmMoveToExited(category: String) {
        guard let product = productToMove, let client = product.client else {
            print("❌ 無法處理資料：沒有關聯的客戶")
            return
        }

        // 如果商品已經是已出場狀態，只更改分類
        if product.isExited {
            product.exitCategory = category
            do {
                try viewContext.save()
                DispatchQueue.main.async {
                    PersistenceController.shared.save()
                    print("✅ 已更改分類為：\(category)")
                }
                productToMove = nil
                selectedCategory = category
            } catch {
                print("❌ 更改分類失敗: \(error)")
            }
            return
        }

        // 如果是進行中商品，建立一個新的已出場產品，複製原本的資料
        let exitedProduct = StructuredProduct(context: viewContext)
        exitedProduct.client = client
        exitedProduct.isExited = true
        exitedProduct.exitCategory = category  // 設定分類

        // 複製所有進行中的欄位資料
            exitedProduct.numberOfTargets = product.numberOfTargets
            exitedProduct.tradePricingDate = product.tradePricingDate
            exitedProduct.target1 = product.target1
            exitedProduct.target2 = product.target2
            exitedProduct.target3 = product.target3
            exitedProduct.issueDate = product.issueDate
            exitedProduct.finalValuationDate = product.finalValuationDate
            exitedProduct.initialPrice1 = product.initialPrice1
            exitedProduct.initialPrice2 = product.initialPrice2
            exitedProduct.initialPrice3 = product.initialPrice3
            exitedProduct.strikePrice1 = product.strikePrice1
            exitedProduct.strikePrice2 = product.strikePrice2
            exitedProduct.strikePrice3 = product.strikePrice3
            exitedProduct.distanceToExit1 = product.distanceToExit1
            exitedProduct.distanceToExit2 = product.distanceToExit2
            exitedProduct.distanceToExit3 = product.distanceToExit3
            exitedProduct.currentPrice1 = product.currentPrice1
            exitedProduct.currentPrice2 = product.currentPrice2
            exitedProduct.currentPrice3 = product.currentPrice3
            exitedProduct.interestRate = product.interestRate
            exitedProduct.monthlyRate = product.monthlyRate
            exitedProduct.transactionAmount = product.transactionAmount

            // 初始化已出場相關欄位為空字串（讓使用者自行填寫）
        exitedProduct.exitDate = ""
        exitedProduct.holdingMonths = ""
        exitedProduct.actualReturn = ""
        exitedProduct.realProfit = ""
        exitedProduct.notes = ""
        exitedProduct.createdDate = Date()

        do {
            try viewContext.save()
            DispatchQueue.main.async {
                PersistenceController.shared.save()
                print("✅ 已複製結構型商品至已出場區域（分類：\(category)）並同步到 iCloud")
            }
            productToMove = nil
            // 切換到新的分類頁籤
            selectedCategory = category
        } catch {
            print("❌ 複製失敗: \(error)")
        }
    }

    private func addNewRow() {
        isAddingToExited = false
        showingTargetSelection = true
    }

    private func addExitedRow() {
        productToMove = nil  // 確保不是更改分類模式
        isAddingToExited = true
        // 先選擇標的數量
        showingTargetSelection = true
    }

    private func createNewProduct(numberOfTargets: Int16, isExited: Bool = false) {
        guard let client = client else {
            print("❌ 無法新增資料：沒有選中的客戶")
            return
        }

        let newProduct = StructuredProduct(context: viewContext)
        newProduct.client = client
        newProduct.numberOfTargets = numberOfTargets
        newProduct.tradePricingDate = ""
        newProduct.target1 = ""
        newProduct.target2 = ""
        newProduct.target3 = ""
        newProduct.issueDate = ""
        newProduct.finalValuationDate = ""
        newProduct.initialPrice1 = ""
        newProduct.initialPrice2 = ""
        newProduct.initialPrice3 = ""
        newProduct.strikePrice1 = ""
        newProduct.strikePrice2 = ""
        newProduct.strikePrice3 = ""
        newProduct.distanceToExit1 = ""
        newProduct.distanceToExit2 = ""
        newProduct.distanceToExit3 = ""
        newProduct.currentPrice1 = ""
        newProduct.currentPrice2 = ""
        newProduct.currentPrice3 = ""
        newProduct.interestRate = ""
        newProduct.monthlyRate = ""
        newProduct.transactionAmount = ""
        newProduct.currency = "USD"  // 預設美金
        newProduct.putPercentage = ""
        newProduct.koPercentage = ""  // KO 敲出
        newProduct.kiPercentage = ""  // KI 敲入
        newProduct.createdDate = Date()
        newProduct.isExited = isExited

        // 如果是已出場，初始化已出場欄位並設定分類
        if isExited {
            newProduct.exitDate = ""
            newProduct.holdingMonths = ""
            newProduct.actualReturn = ""
            newProduct.realProfit = ""
            newProduct.notes = ""
            // 設定分類（如果當前不是"全部"，使用當前分類）
            newProduct.exitCategory = selectedCategory != "全部" ? selectedCategory : ""
        }

        do {
            try viewContext.save()

            // 根據是否為已出場和標的數量，調整延遲時間
            let delay: Double = {
                if isExited && numberOfTargets >= 2 {
                    return 0.3  // 已出場且2-3個標的，延遲更久
                } else if numberOfTargets >= 2 {
                    return 0.2  // 進行中且2-3個標的
                } else {
                    return 0.1  // 1個標的
                }
            }()

            // 延遲同步到 iCloud，讓 UI 先穩定
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                PersistenceController.shared.save()
                let typeText = isExited ? "已出場" : "進行中"
                let categoryInfo = isExited && !(newProduct.exitCategory ?? "").isEmpty ? "，分類：\(newProduct.exitCategory ?? "")" : ""
                print("✅ 新增空白結構型商品（\(numberOfTargets)個標的，\(typeText)\(categoryInfo)）並同步到 iCloud")
            }
        } catch {
            print("❌ 新增失敗: \(error)")
        }
    }

    // MARK: - 匯入功能處理
    private func handleManualDataEntry() {
        addNewRow()
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let firstURL = urls.first {
                print("成功選擇檔案：\(firstURL)")
            }
        case .failure(let error):
            print("檔案選擇失敗：\(error.localizedDescription)")
        }
    }

    // MARK: - 自訂分類管理
    private func saveCustomCategories() {
        UserDefaults.standard.set(customCategories, forKey: "StructuredProducts_CustomCategories")
    }

    private func loadCustomCategories() {
        if let saved = UserDefaults.standard.array(forKey: "StructuredProducts_CustomCategories") as? [String] {
            customCategories = saved
        }
    }

    private func deleteCategory(_ category: String) {
        // 檢查是否有商品在此分類中
        let productsInCategory = exitedProducts.filter { $0.exitCategory == category }

        if !productsInCategory.isEmpty {
            print("⚠️ 無法刪除分類「\(category)」，因為還有 \(productsInCategory.count) 個商品在此分類中")
            return
        }

        // 從自訂分類列表中移除
        if let index = customCategories.firstIndex(of: category) {
            customCategories.remove(at: index)
            saveCustomCategories()
            print("✅ 已從自訂分類列表移除：\(category)")
        }

        // 從排序列表中移除
        if let index = categoryOrder.firstIndex(of: category) {
            categoryOrder.remove(at: index)
            saveCategoryOrder()
            print("✅ 已從排序列表移除：\(category)")
        }

        // 如果當前選擇的是被刪除的分類，切換到「全部」
        if selectedCategory == category {
            selectedCategory = "全部"
        }

        print("✅ 成功刪除分類：\(category)")
    }

    // MARK: - 頁籤排序管理
    private func saveCategoryOrder() {
        print("💾 Saving category order: \(categoryOrder)")
        let key = categoryOrderKey()
        UserDefaults.standard.set(categoryOrder, forKey: key)
    }

    private func loadCategoryOrder() {
        let key = categoryOrderKey()
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            categoryOrder = saved
            print("📂 Loaded category order: \(categoryOrder)")
        } else {
            print("📂 No saved category order found")
        }
    }

    private func categoryOrderKey() -> String {
        if let client = client {
            return "StructuredProducts_CategoryOrder_\(client.objectID.uriRepresentation().absoluteString)"
        } else {
            return "StructuredProducts_CategoryOrder_AllClients"
        }
    }

    // MARK: - 刷新股價功能
    private func refreshOngoingPrices() {
        // 如果沒有商品，提示用戶
        guard !ongoingProducts.isEmpty else {
            refreshMessage = "目前沒有進行中的結構型商品"
            showingRefreshAlert = true
            return
        }

        // 設置刷新狀態
        isRefreshingOngoing = true

        // 使用異步任務獲取股價
        Task {
            // 收集所有標的代碼
            var symbolMap: [String: [(product: StructuredProduct, index: Int)]] = [:]

            for product in ongoingProducts {
                let targetCount = getEffectiveTargetCount(for: product)

                // 收集所有標的
                if targetCount >= 1, let target1 = product.target1, !target1.isEmpty {
                    let symbol = target1.trimmingCharacters(in: .whitespaces).uppercased()
                    symbolMap[symbol, default: []].append((product, 1))
                }
                if targetCount >= 2, let target2 = product.target2, !target2.isEmpty {
                    let symbol = target2.trimmingCharacters(in: .whitespaces).uppercased()
                    symbolMap[symbol, default: []].append((product, 2))
                }
                if targetCount >= 3, let target3 = product.target3, !target3.isEmpty {
                    let symbol = target3.trimmingCharacters(in: .whitespaces).uppercased()
                    symbolMap[symbol, default: []].append((product, 3))
                }
                if targetCount >= 4, let target4 = product.target4, !target4.isEmpty {
                    let symbol = target4.trimmingCharacters(in: .whitespaces).uppercased()
                    symbolMap[symbol, default: []].append((product, 4))
                }
            }

            guard !symbolMap.isEmpty else {
                await MainActor.run {
                    isRefreshingOngoing = false
                    refreshMessage = "沒有有效的標的代碼"
                    showingRefreshAlert = true
                }
                return
            }

            // 批量獲取股價
            let symbols = Array(symbolMap.keys)
            let prices = await StockPriceService.shared.fetchMultipleStockPrices(symbols: symbols)

            // 在主線程更新 UI
            await MainActor.run {
                var successCount = 0
                var failCount = 0

                // 更新每個標的的現價
                var updatedProducts = Set<StructuredProduct>()
                for (symbol, mappings) in symbolMap {
                    if let newPrice = prices[symbol] {
                        for mapping in mappings {
                            switch mapping.index {
                            case 1:
                                mapping.product.currentPrice1 = newPrice
                            case 2:
                                mapping.product.currentPrice2 = newPrice
                            case 3:
                                mapping.product.currentPrice3 = newPrice
                            case 4:
                                mapping.product.currentPrice4 = newPrice
                            default:
                                break
                            }
                            updatedProducts.insert(mapping.product)
                        }
                        successCount += mappings.count
                    } else {
                        failCount += mappings.count
                    }
                }

                // 自動重新計算距離出場%
                for product in updatedProducts {
                    calculateDistanceToExit(for: product)
                }

                // 保存到 Core Data
                if successCount > 0 {
                    do {
                        try viewContext.save()
                        PersistenceController.shared.save()
                        print("✅ 成功更新 \(successCount) 個標的的價格")
                    } catch {
                        print("❌ 保存失敗: \(error)")
                    }
                }

                // 顯示結果
                isRefreshingOngoing = false
                if successCount > 0 {
                    refreshMessage = "成功更新 \(successCount) 個標的\(failCount > 0 ? "，\(failCount) 個失敗" : "")"
                } else {
                    refreshMessage = "更新失敗，請檢查標的代碼是否正確"
                }
                showingRefreshAlert = true
            }
        }
    }

    // MARK: - 自動計算距離出場%
    private func calculateDistanceToExit(for product: StructuredProduct) {
        let targetCount = getEffectiveTargetCount(for: product)

        // 計算標的1的距離出場%
        if targetCount >= 1 {
            if let currentPrice1 = product.currentPrice1,
               let initialPrice1 = product.initialPrice1,
               !currentPrice1.isEmpty,
               !initialPrice1.isEmpty,
               let current = Double(removeCommas(currentPrice1)),
               let initial = Double(removeCommas(initialPrice1)),
               initial > 0 {
                let percentage = (current / initial) * 100
                product.distanceToExit1 = String(format: "%.2f%%", percentage)
            }
        }

        // 計算標的2的距離出場%
        if targetCount >= 2 {
            if let currentPrice2 = product.currentPrice2,
               let initialPrice2 = product.initialPrice2,
               !currentPrice2.isEmpty,
               !initialPrice2.isEmpty,
               let current = Double(removeCommas(currentPrice2)),
               let initial = Double(removeCommas(initialPrice2)),
               initial > 0 {
                let percentage = (current / initial) * 100
                product.distanceToExit2 = String(format: "%.2f%%", percentage)
            }
        }

        // 計算標的3的距離出場%
        if targetCount >= 3 {
            if let currentPrice3 = product.currentPrice3,
               let initialPrice3 = product.initialPrice3,
               !currentPrice3.isEmpty,
               !initialPrice3.isEmpty,
               let current = Double(removeCommas(currentPrice3)),
               let initial = Double(removeCommas(initialPrice3)),
               initial > 0 {
                let percentage = (current / initial) * 100
                product.distanceToExit3 = String(format: "%.2f%%", percentage)
            }
        }

        // 計算標的4的距離出場%
        if targetCount >= 4 {
            if let currentPrice4 = product.currentPrice4,
               let initialPrice4 = product.initialPrice4,
               !currentPrice4.isEmpty,
               !initialPrice4.isEmpty,
               let current = Double(removeCommas(currentPrice4)),
               let initial = Double(removeCommas(initialPrice4)),
               initial > 0 {
                let percentage = (current / initial) * 100
                product.distanceToExit4 = String(format: "%.2f%%", percentage)
            }
        }
    }

    // MARK: - 自動計算執行價和保護價
    private func calculateStrikeAndProtectionPrices(for product: StructuredProduct) {
        let targetCount = getEffectiveTargetCount(for: product)

        // 取得 PUT% 和 KI%
        let putPercent = Double(product.putPercentage ?? "") ?? 0
        let kiPercent = Double(product.kiPercentage ?? "") ?? 0

        // 計算標的1
        if targetCount >= 1 {
            if let initialPrice1 = product.initialPrice1,
               !initialPrice1.isEmpty,
               let initial = Double(removeCommas(initialPrice1)),
               initial > 0 {
                if putPercent > 0 {
                    let strike = initial * (putPercent / 100)
                    product.strikePrice1 = String(format: "%.2f", strike)
                }
                if kiPercent > 0 {
                    let protection = initial * (kiPercent / 100)
                    product.protectionPrice1 = String(format: "%.2f", protection)
                }
            }
        }

        // 計算標的2
        if targetCount >= 2 {
            if let initialPrice2 = product.initialPrice2,
               !initialPrice2.isEmpty,
               let initial = Double(removeCommas(initialPrice2)),
               initial > 0 {
                if putPercent > 0 {
                    let strike = initial * (putPercent / 100)
                    product.strikePrice2 = String(format: "%.2f", strike)
                }
                if kiPercent > 0 {
                    let protection = initial * (kiPercent / 100)
                    product.protectionPrice2 = String(format: "%.2f", protection)
                }
            }
        }

        // 計算標的3
        if targetCount >= 3 {
            if let initialPrice3 = product.initialPrice3,
               !initialPrice3.isEmpty,
               let initial = Double(removeCommas(initialPrice3)),
               initial > 0 {
                if putPercent > 0 {
                    let strike = initial * (putPercent / 100)
                    product.strikePrice3 = String(format: "%.2f", strike)
                }
                if kiPercent > 0 {
                    let protection = initial * (kiPercent / 100)
                    product.protectionPrice3 = String(format: "%.2f", protection)
                }
            }
        }

        // 計算標的4
        if targetCount >= 4 {
            if let initialPrice4 = product.initialPrice4,
               !initialPrice4.isEmpty,
               let initial = Double(removeCommas(initialPrice4)),
               initial > 0 {
                if putPercent > 0 {
                    let strike = initial * (putPercent / 100)
                    product.strikePrice4 = String(format: "%.2f", strike)
                }
                if kiPercent > 0 {
                    let protection = initial * (kiPercent / 100)
                    product.protectionPrice4 = String(format: "%.2f", protection)
                }
            }
        }
    }

}

// MARK: - CategoryDropDelegate
struct CategoryDropDelegate: DropDelegate {
    let category: String
    @Binding var categories: [String]
    let availableCategories: [String]
    @Binding var draggingCategory: String?
    let onReorder: () -> Void

    func dropEntered(info: DropInfo) {
        print("🔍 Drop entered: \(category)")

        guard let fromCategoryName = draggingCategory else {
            print("🔍 Drop: No dragging category")
            return
        }

        print("🔍 Drop: From '\(fromCategoryName)' to '\(category)'")

        guard fromCategoryName != category else {
            print("🔍 Drop: Same category, skipping")
            return
        }

        guard fromCategoryName != "全部", category != "全部" else {
            print("🔍 Drop: '全部' cannot be moved")
            return
        }

        print("🔍 Drop: Current categories: \(categories)")

        // 如果 categories 是空的，從 availableCategories 初始化（排除「全部」）
        if categories.isEmpty {
            categories = availableCategories.filter { $0 != "全部" }
            print("🔍 Drop: Initialized categories: \(categories)")
        }

        // 確保 fromCategory 和 toCategory 都在 categories 中（可能是新加入的分類）
        if !categories.contains(fromCategoryName) {
            categories.append(fromCategoryName)
            print("🔍 Drop: Added missing fromCategory '\(fromCategoryName)' to categories")
        }

        if !categories.contains(category) {
            categories.append(category)
            print("🔍 Drop: Added missing toCategory '\(category)' to categories")
        }

        guard let fromIndex = categories.firstIndex(of: fromCategoryName) else {
            print("🔍 Drop: Cannot find fromIndex for '\(fromCategoryName)'")
            return
        }

        guard let toIndex = categories.firstIndex(of: category) else {
            print("🔍 Drop: Cannot find toIndex for '\(category)'")
            return
        }

        print("🔍 Drop: Moving from index \(fromIndex) to \(toIndex)")

        if fromIndex != toIndex {
            categories.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            print("🔍 Drop: New order: \(categories)")
            onReorder()
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        print("🔍 performDrop called for: \(category)")
        draggingCategory = nil
        return true
    }
}

#Preview {
    StructuredProductsDetailView(client: nil)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .padding()
}
