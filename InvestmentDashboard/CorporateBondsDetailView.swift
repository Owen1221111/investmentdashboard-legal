import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct CorporateBondsDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var isExpanded = false
    @State private var showingColumnReorder = false
    @State private var columnOrder: [String] = []
    @State private var bondToDelete: CorporateBond? = nil
    @State private var showingDeleteConfirmation = false
    @State private var showingImportOptions = false
    @State private var showingFileImporter = false
    @State private var showingSubscription = false
    @State private var sortField: String? = nil
    @State private var sortAscending: Bool = true
    @State private var refreshTrigger = UUID() // 刷新觸發器
    let client: Client?

    // 匯率資料（使用 @AppStorage 與其他視圖同步）
    @AppStorage("exchangeRate") private var exchangeRate: String = ""
    @AppStorage("eurRate") private var eurRate: String = ""
    @AppStorage("jpyRate") private var jpyRate: String = ""
    @AppStorage("gbpRate") private var gbpRate: String = ""
    @AppStorage("cnyRate") private var cnyRate: String = ""
    @AppStorage("audRate") private var audRate: String = ""
    @AppStorage("cadRate") private var cadRate: String = ""
    @AppStorage("chfRate") private var chfRate: String = ""
    @AppStorage("hkdRate") private var hkdRate: String = ""
    @AppStorage("sgdRate") private var sgdRate: String = ""

    // 債券批次更新相關資料（⭐️ 改用 @State + UserDefaults，實現客戶專屬儲存）
    @State private var bondEditModeRawValue: String = "更新總額、總利息"
    @State private var bondsTotalValue: String = ""
    @State private var bondsTotalInterest: String = ""

    // FetchRequest 會自動監聽資料變化
    @FetchRequest private var corporateBonds: FetchedResults<CorporateBond>

    // MARK: - 客戶專屬儲存鍵值
    private var clientSpecificBondEditModeKey: String {
        guard let clientID = client?.objectID.uriRepresentation().absoluteString else {
            return "bondEditMode_default"
        }
        return "bondEditMode_\(clientID)"
    }

    private var clientSpecificBondsTotalValueKey: String {
        guard let clientID = client?.objectID.uriRepresentation().absoluteString else {
            return "bondsTotalValue_default"
        }
        return "bondsTotalValue_\(clientID)"
    }

    private var clientSpecificBondsTotalInterestKey: String {
        guard let clientID = client?.objectID.uriRepresentation().absoluteString else {
            return "bondsTotalInterest_default"
        }
        return "bondsTotalInterest_\(clientID)"
    }

    // MARK: - 客戶專屬資料載入與儲存
    private func loadClientSpecificBondData() {
        bondEditModeRawValue = UserDefaults.standard.string(forKey: clientSpecificBondEditModeKey) ?? "更新總額、總利息"
        bondsTotalValue = UserDefaults.standard.string(forKey: clientSpecificBondsTotalValueKey) ?? ""
        bondsTotalInterest = UserDefaults.standard.string(forKey: clientSpecificBondsTotalInterestKey) ?? ""
    }

    private func saveClientSpecificBondData() {
        UserDefaults.standard.set(bondEditModeRawValue, forKey: clientSpecificBondEditModeKey)
        UserDefaults.standard.set(bondsTotalValue, forKey: clientSpecificBondsTotalValueKey)
        UserDefaults.standard.set(bondsTotalInterest, forKey: clientSpecificBondsTotalInterestKey)
    }

    // MARK: - 批次更新資料（UserDefaults）⭐️ 新方案
    private func getBatchTotalValue() -> String {
        guard let client = client else { return "" }
        let clientID = client.objectID.uriRepresentation().absoluteString
        let key = "bondsTotalValue_\(clientID)"
        return UserDefaults.standard.string(forKey: key) ?? ""
    }

    private func getBatchTotalInterest() -> String {
        guard let client = client else { return "" }
        let clientID = client.objectID.uriRepresentation().absoluteString
        let key = "bondsTotalInterest_\(clientID)"
        return UserDefaults.standard.string(forKey: key) ?? ""
    }

    init(client: Client?) {
        self.client = client

        // 根據客戶 ID 建立 FetchRequest（按申購日降序排列，最新的在最上面，排除橘色行）
        if let client = client {
            let sortByDateDesc = NSSortDescriptor(keyPath: \CorporateBond.subscriptionDateAsDate, ascending: false)
            let sortByCreatedDesc = NSSortDescriptor(keyPath: \CorporateBond.createdDate, ascending: false)

            _corporateBonds = FetchRequest<CorporateBond>(
                sortDescriptors: [sortByDateDesc, sortByCreatedDesc],
                predicate: NSPredicate(format: "client == %@ AND bondName != %@", client, "__BATCH_UPDATE__"),
                animation: .default
            )
        } else {
            // 如果沒有客戶，返回空結果
            let sortByDateDesc = NSSortDescriptor(keyPath: \CorporateBond.subscriptionDateAsDate, ascending: false)
            let sortByCreatedDesc = NSSortDescriptor(keyPath: \CorporateBond.createdDate, ascending: false)

            _corporateBonds = FetchRequest<CorporateBond>(
                sortDescriptors: [sortByDateDesc, sortByCreatedDesc],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 標題區域（含縮放功能）
            tableHeader

            // 表格內容（可縮放）
            if isExpanded {
                corporateBondsTable
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
                headers: bondHeaders,
                initialOrder: columnOrder.isEmpty ? bondHeaders : columnOrder,
                onSave: { newOrder in
                    columnOrder = newOrder
                    // 儲存到 UserDefaults
                    UserDefaults.standard.set(newOrder, forKey: "CorporateBonds_ColumnOrder")
                }
            )
        }
        .onAppear {
            // ⭐️ 載入客戶專屬的債券資料
            loadClientSpecificBondData()

            // 從 UserDefaults 讀取欄位排序
            if let savedOrder = UserDefaults.standard.array(forKey: "CorporateBonds_ColumnOrder") as? [String], !savedOrder.isEmpty {
                // 檢查是否有新增的欄位需要加入
                var updatedOrder = savedOrder
                for (index, header) in bondHeaders.enumerated() {
                    if !updatedOrder.contains(header) {
                        // 新欄位插入到對應位置
                        let insertIndex = min(index, updatedOrder.count)
                        updatedOrder.insert(header, at: insertIndex)
                    }
                }
                // 移除已刪除的欄位
                updatedOrder = updatedOrder.filter { bondHeaders.contains($0) }
                columnOrder = updatedOrder

                // 如果有更新，儲存新的排序
                if updatedOrder != savedOrder {
                    UserDefaults.standard.set(updatedOrder, forKey: "CorporateBonds_ColumnOrder")
                }
            } else if columnOrder.isEmpty {
                columnOrder = bondHeaders
            }

            // ⭐️ 註冊通知觀察者，監聽債券數據更新
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("BondDataDidUpdate"),
                object: nil,
                queue: .main
            ) { notification in
                // 檢查是否是當前客戶的數據更新
                if let userInfo = notification.userInfo,
                   let notificationClientID = userInfo["clientID"] as? String,
                   let currentClientID = client?.objectID.uriRepresentation().absoluteString,
                   notificationClientID == currentClientID {
                    // 重新載入債券數據
                    loadClientSpecificBondData()
                }
            }
        }
        // ⭐️ 當債券資料改變時，儲存到客戶專屬的 UserDefaults
        .onChange(of: bondEditModeRawValue) { _ in
            saveClientSpecificBondData()
        }
        .onChange(of: bondsTotalValue) { _ in
            saveClientSpecificBondData()
        }
        .onChange(of: bondsTotalInterest) { _ in
            saveClientSpecificBondData()
        }
        .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) {
                bondToDelete = nil
            }
            Button("刪除", role: .destructive) {
                if let bond = bondToDelete {
                    deleteBond(bond)
                    bondToDelete = nil
                }
            }
        } message: {
            if let bond = bondToDelete {
                Text("確定要刪除「\(bond.bondName ?? "此債券")」嗎？此操作無法復原。")
            } else {
                Text("確定要刪除此債券嗎？此操作無法復原。")
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
                    Image(systemName: "banknote")
                        .font(.system(size: 14))
                    Text("公司債明細")
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

    // MARK: - 公司債明細表格
    private var corporateBondsTable: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0) {
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
                        if isSortableField(header) {
                            // 可排序欄位
                            Button(action: {
                                handleSort(for: header)
                            }) {
                                HStack(spacing: 4) {
                                    Text(header)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                                        .lineLimit(1)
                                        .truncationMode(.tail)

                                    if sortField == header {
                                        Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 14)
                                .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // 不可排序欄位
                            Text(header)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 14)
                                .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                        }
                    }
                }
                .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

                // 資料行（已排序）
                ForEach(Array(sortedBonds.enumerated()), id: \.offset) { index, bond in
                    let _ = refreshTrigger // 監聽刷新觸發器
                    HStack(spacing: 0) {
                        // 刪除按鈕（移到最左邊）
                        Button(action: {
                            bondToDelete = bond
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 8)
                        .frame(width: 40, alignment: .center)

                        ForEach(Array(currentColumnOrder.enumerated()), id: \.offset) { colIndex, header in
                            if header == "匯率" {
                                // 匯率欄位顯示當前幣別的匯率（唯讀）
                                let currency = bond.currency ?? "USD"
                                let rate = getExchangeRate(for: currency)
                                Text(rate)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                                    .background(Color.orange.opacity(0.05))
                                    .id("\(bond.currency ?? "")-\(rate)") // 強制刷新
                            } else if header == "折合美金" {
                                // 折合美金欄位顯示計算結果（唯讀）
                                let convertedUSD = calculateConvertedToUSD(bond: bond)
                                Text(formatNumberWithCommas(convertedUSD))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                                    .background(Color.green.opacity(0.05))
                                    .id("\(bond.currentValue ?? "")-\(bond.currency ?? "")-\(getExchangeRate(for: bond.currency ?? ""))") // 強制刷新
                            } else if header == "幣別" {
                                // 幣別使用選擇器
                                Menu {
                                    Button("USD") { setBondCurrency(bond, value: "USD") }
                                    Button("TWD") { setBondCurrency(bond, value: "TWD") }
                                    Button("EUR") { setBondCurrency(bond, value: "EUR") }
                                    Button("JPY") { setBondCurrency(bond, value: "JPY") }
                                    Button("GBP") { setBondCurrency(bond, value: "GBP") }
                                    Button("CNY") { setBondCurrency(bond, value: "CNY") }
                                    Button("AUD") { setBondCurrency(bond, value: "AUD") }
                                    Button("CAD") { setBondCurrency(bond, value: "CAD") }
                                    Button("CHF") { setBondCurrency(bond, value: "CHF") }
                                    Button("HKD") { setBondCurrency(bond, value: "HKD") }
                                    Button("SGD") { setBondCurrency(bond, value: "SGD") }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(bond.currency?.isEmpty == false ? bond.currency! : "USD")
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
                                    .frame(width: getBondColumnWidth(for: header), alignment: .leading)
                                    .background(Color(.systemGray6).opacity(0.3))
                                    .cornerRadius(4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else if header == "配息月份" {
                                // 配息月份使用選擇器，設計成類似文字欄位的樣式
                                Menu {
                                    // 半年配息
                                    Button("1月、7月") { setBondValue(bond, header: header, value: "1月、7月") }
                                    Button("2月、8月") { setBondValue(bond, header: header, value: "2月、8月") }
                                    Button("3月、9月") { setBondValue(bond, header: header, value: "3月、9月") }
                                    Button("4月、10月") { setBondValue(bond, header: header, value: "4月、10月") }
                                    Button("5月、11月") { setBondValue(bond, header: header, value: "5月、11月") }
                                    Button("6月、12月") { setBondValue(bond, header: header, value: "6月、12月") }
                                    // 季配息
                                    Button("1、4、7、10月") { setBondValue(bond, header: header, value: "1、4、7、10月") }
                                    Button("2、5、8、11月") { setBondValue(bond, header: header, value: "2、5、8、11月") }
                                    Button("3、6、9、12月") { setBondValue(bond, header: header, value: "3、6、9、12月") }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(bond.dividendMonths?.isEmpty == false ? bond.dividendMonths! : "選擇配息月份")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(bond.dividendMonths?.isEmpty == false ? .primary : .secondary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)

                                        Spacer()

                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                                    .background(Color(.systemGray6).opacity(0.3))
                                    .cornerRadius(4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else if isCalculatedField(header) {
                                // 自動計算欄位使用 Text（確保刷新）
                                let _ = refreshTrigger // 監聽刷新
                                Text(bindingForBond(bond, header: header).wrappedValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                                    .background(Color.blue.opacity(0.05))
                            } else {
                                // 其他欄位使用文字輸入
                                TextField("", text: bindingForBond(bond, header: header))
                                    .font(.system(size: 14, weight: .medium))
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                            }
                        }
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

                // 加總行
                summaryRow
            }
        }
        .frame(minHeight: 200)
    }

    // MARK: - 加總行
    private var summaryRow: some View {
        HStack(spacing: 0) {
            // 刪除按鈕欄位（空白）
            Text("")
                .frame(width: 40, alignment: .center)

            ForEach(Array(currentColumnOrder.enumerated()), id: \.offset) { colIndex, header in
                Group {
                    if header == "債券名稱" {
                        Text("合計")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                    } else if header == "申購金額" {
                        VStack(spacing: 0) {
                            Text(formatNumberWithCommas(String(getTotalSubscriptionAmount())))
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
                        .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
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
                        .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                    } else if header == "已領利息" {
                        VStack(spacing: 0) {
                            Text(formatNumberWithCommas(String(getTotalReceivedInterest())))
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
                        .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                    } else if header == "現值" {
                        VStack(spacing: 0) {
                            Text(formatNumberWithCommas(String(getTotalCurrentValue())))
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
                        .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                    } else if header == "報酬率" {
                        VStack(spacing: 0) {
                            Text(String(format: "%.2f%%", getTotalReturnRate()))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(getTotalReturnRate() >= 0 ? .green : .red)
                                .lineLimit(1)

                            Rectangle()
                                .fill(getTotalReturnRate() >= 0 ? Color.green : Color.red)
                                .frame(height: 2)
                                .padding(.top, 2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
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
                        .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                    } else {
                        // 其他欄位空白
                        Text("")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .frame(minWidth: getBondColumnWidth(for: header), maxWidth: getBondColumnWidth(for: header), alignment: .leading)
                    }
                }
            }
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

    // MARK: - 計算屬性
    private var currentColumnOrder: [String] {
        return columnOrder.isEmpty ? bondHeaders : columnOrder
    }

    // 排序後的債券列表
    private var sortedBonds: [CorporateBond] {
        guard let sortField = sortField else {
            return Array(corporateBonds)
        }

        return corporateBonds.sorted { bond1, bond2 in
            let value1 = getNumericValue(bond: bond1, header: sortField)
            let value2 = getNumericValue(bond: bond2, header: sortField)

            if sortAscending {
                return value1 < value2
            } else {
                return value1 > value2
            }
        }
    }

    // 判斷是否為可排序欄位
    private func isSortableField(_ header: String) -> Bool {
        return ["殖利率", "申購金額", "交易金額", "現值"].contains(header)
    }

    // 處理排序點擊
    private func handleSort(for header: String) {
        if sortField == header {
            // 同一個欄位，切換升降序
            sortAscending.toggle()
        } else {
            // 不同欄位，重設為升序
            sortField = header
            sortAscending = true
        }
    }

    // 獲取數字值（用於排序）
    private func getNumericValue(bond: CorporateBond, header: String) -> Double {
        let stringValue: String
        switch header {
        case "殖利率":
            stringValue = bond.yieldRate ?? ""
        case "申購金額":
            stringValue = bond.subscriptionAmount ?? ""
        case "交易金額":
            stringValue = bond.transactionAmount ?? ""
        case "現值":
            stringValue = bond.currentValue ?? ""
        default:
            return 0
        }

        // 移除 % 符號和逗號
        let cleanValue = removeCommas(stringValue)
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Double(cleanValue) ?? 0
    }

    // 計算申購金額總和
    private func getTotalSubscriptionAmount() -> Double {
        return corporateBonds.reduce(0.0) { sum, bond in
            let amount = Double(removeCommas(bond.subscriptionAmount ?? "")) ?? 0
            return sum + amount
        }
    }

    // 計算交易金額總和
    private func getTotalTransactionAmount() -> Double {
        return corporateBonds.reduce(0.0) { sum, bond in
            let amount = Double(removeCommas(bond.transactionAmount ?? "")) ?? 0
            return sum + amount
        }
    }

    // 計算已領利息總和
    private func getTotalReceivedInterest() -> Double {
        return corporateBonds.reduce(0.0) { sum, bond in
            let amount = Double(removeCommas(bond.receivedInterest ?? "")) ?? 0
            return sum + amount
        }
    }

    // 計算現值總和
    private func getTotalCurrentValue() -> Double {
        return corporateBonds.reduce(0.0) { sum, bond in
            let amount = Double(removeCommas(bond.currentValue ?? "")) ?? 0
            return sum + amount
        }
    }

    // 計算總報酬率
    private func getTotalReturnRate() -> Double {
        let totalCost = getTotalTransactionAmount()
        guard totalCost > 0 else { return 0 }

        let totalCurrentValue = getTotalCurrentValue()
        let totalReceivedInterest = getTotalReceivedInterest()

        return ((totalCurrentValue - totalCost + totalReceivedInterest) / totalCost) * 100
    }

    // 計算折合美金總和
    private func getTotalConvertedToUSD() -> Double {
        return corporateBonds.reduce(0.0) { sum, bond in
            let convertedString = calculateConvertedToUSD(bond: bond)
            let converted = Double(removeCommas(convertedString)) ?? 0
            return sum + converted
        }
    }

    // 設置債券欄位值（用於配息月份選擇器）
    private func setBondValue(_ bond: CorporateBond, header: String, value: String) {
        // 通知物件即將變更
        bond.objectWillChange.send()

        bond.dividendMonths = value

        // 重新計算單次配息 = 年度配息 ÷ 配息次數
        let currentAnnual = Double(removeCommas(bond.annualDividend ?? "")) ?? 0
        let paymentCount = countDividendPayments(value)

        if paymentCount > 0 && currentAnnual > 0 {
            let newSingle = currentAnnual / Double(paymentCount)
            bond.singleDividend = String(format: "%.2f", newSingle)
        }

        // 自動儲存變更
        do {
            try viewContext.save()
            PersistenceController.shared.save()

            // 刷新物件確保其他視圖更新
            viewContext.refresh(bond, mergeChanges: true)

            // 強制刷新視圖
            refreshTrigger = UUID()
        } catch {
            print("❌ 儲存失敗: \(error)")
        }
    }

    // 設置債券幣別（用於幣別選擇器）
    private func setBondCurrency(_ bond: CorporateBond, value: String) {
        bond.currency = value

        // 自動儲存變更
        do {
            try viewContext.save()
            PersistenceController.shared.save()
        } catch {
            print("❌ 儲存失敗: \(error)")
        }
    }

    // MARK: - 資料和輔助函數
    private let bondHeaders = [
        "申購日", "債券名稱", "到期日", "幣別", "匯率", "折合美金", "票面利率", "殖利率", "申購價", "申購金額",
        "持有面額", "前手息", "交易金額", "現值", "已領利息", "含息損益", "報酬率",
        "配息月份", "單次配息", "年度配息"
    ]

    private func getBondColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "申購日": return 110
        case "債券名稱": return 180
        case "到期日": return 110
        case "幣別": return 90
        case "匯率": return 90
        case "折合美金": return 110
        case "票面利率", "殖利率", "報酬率": return 90
        case "申購價": return 80
        case "持有面額": return 100
        case "申購金額", "前手息", "交易金額", "現值": return 110
        case "已領利息", "含息損益": return 100
        case "單次配息", "年度配息": return 90
        case "配息月份": return 140
        default: return 90
        }
    }

    // MARK: - 匯率和折合美金計算

    /// 根據幣別取得對應的匯率
    private func getExchangeRate(for currency: String) -> String {
        let rate: String
        switch currency {
        case "TWD": rate = exchangeRate
        case "EUR": rate = eurRate
        case "JPY": rate = jpyRate
        case "GBP": rate = gbpRate
        case "CNY": rate = cnyRate
        case "AUD": rate = audRate
        case "CAD": rate = cadRate
        case "CHF": rate = chfRate
        case "HKD": rate = hkdRate
        case "SGD": rate = sgdRate
        case "USD": return "1.0000"
        default: return ""
        }

        // 只有當匯率有效時才回傳
        guard !rate.isEmpty, let rateValue = Double(rate), rateValue > 0 else {
            return ""
        }

        return String(format: "%.4f", rateValue)
    }

    /// 計算債券折合美金金額
    private func calculateConvertedToUSD(bond: CorporateBond) -> String {
        let currency = bond.currency ?? "USD"

        // USD 不需要轉換
        if currency == "USD" {
            return bond.currentValue ?? ""
        }

        // 取得匯率
        let rateString = getExchangeRate(for: currency)
        guard !rateString.isEmpty, let rate = Double(rateString) else {
            return ""
        }

        // 取得現值
        let currentValueString = removeCommas(bond.currentValue ?? "")
        guard let currentValue = Double(currentValueString), currentValue > 0 else {
            return ""
        }

        // 計算折合美金 = 現值 ÷ 匯率
        let convertedUSD = currentValue / rate
        return String(format: "%.2f", convertedUSD)
    }

    // MARK: - 編輯和刪除功能
    private func deleteBond(_ bond: CorporateBond) {
        withAnimation {
            viewContext.delete(bond)
            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("✅ 公司債已刪除並同步到 iCloud")
            } catch {
                print("❌ 刪除失敗: \(error)")
            }
        }
    }

    private func addNewRow() {
        guard let client = client else {
            print("❌ 無法新增資料：沒有選中的客戶")
            return
        }

        withAnimation {
            let newBond = CorporateBond(context: viewContext)
            newBond.client = client
            newBond.subscriptionDate = ""
            newBond.subscriptionDateAsDate = nil  // 空白記錄，日期為 nil
            newBond.bondName = ""
            newBond.currency = "USD" // 預設美金
            newBond.couponRate = ""
            newBond.yieldRate = ""
            newBond.subscriptionPrice = ""
            newBond.subscriptionAmount = ""
            newBond.holdingFaceValue = ""
            newBond.previousHandInterest = ""
            newBond.transactionAmount = ""
            newBond.currentValue = ""
            newBond.receivedInterest = ""
            newBond.profitLossWithInterest = ""
            newBond.returnRate = ""
            newBond.dividendMonths = ""
            newBond.singleDividend = ""
            newBond.annualDividend = ""
            newBond.createdDate = Date()

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("✅ 新增空白公司債並同步到 iCloud")
            } catch {
                print("❌ 新增失敗: \(error)")
            }
        }
    }

    // MARK: - 格式化輔助函數
    private func formatNumberWithCommas(_ value: String?, forHeader header: String? = nil) -> String {
        guard let value = value, !value.isEmpty else { return "" }

        // 移除現有的逗號
        let cleanValue = value.replacingOccurrences(of: ",", with: "")

        // 如果可以轉換成數字，加上千分位
        if let number = Double(cleanValue) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal

            // 申購價固定顯示2位小數
            if header == "申購價" {
                formatter.minimumFractionDigits = 2
                formatter.maximumFractionDigits = 2
            } else {
                formatter.minimumFractionDigits = 0
                formatter.maximumFractionDigits = 2
            }

            return formatter.string(from: NSNumber(value: number)) ?? cleanValue
        }

        return cleanValue
    }

    private func removeCommas(_ value: String) -> String {
        return value.replacingOccurrences(of: ",", with: "")
    }

    // 判斷是否為數字欄位
    private func isNumberField(_ header: String) -> Bool {
        let textFields = ["申購日", "債券名稱", "到期日", "幣別", "配息月份"]
        return !textFields.contains(header)
    }

    // 判斷是否為自動計算欄位
    private func isCalculatedField(_ header: String) -> Bool {
        return header == "申購金額" || header == "交易金額" || header == "單次配息" || header == "年度配息" || header == "殖利率"
    }

    // 計算申購金額 = 申購價 × 持有面額 / 100
    private func calculateSubscriptionAmount(for bond: CorporateBond) -> String {
        let price = Double(removeCommas(bond.subscriptionPrice ?? "")) ?? 0
        let faceValue = Double(removeCommas(bond.holdingFaceValue ?? "")) ?? 0
        let result = price * faceValue / 100
        return String(format: "%.2f", result)
    }

    // 計算交易金額 = 申購金額 + 前手息
    private func calculateTransactionAmount(for bond: CorporateBond) -> String {
        let subscriptionAmount = Double(removeCommas(bond.subscriptionAmount ?? "")) ?? 0
        let previousInterest = Double(removeCommas(bond.previousHandInterest ?? "")) ?? 0
        let result = subscriptionAmount + previousInterest
        return String(format: "%.2f", result)
    }

    // 計算年度配息 = 持有面額 × 票面利率
    private func calculateAnnualDividend(for bond: CorporateBond) -> String {
        let couponRateStr = removeCommas(bond.couponRate ?? "").replacingOccurrences(of: "%", with: "")
        let couponRateValue = Double(couponRateStr) ?? 0
        let faceValue = Double(removeCommas(bond.holdingFaceValue ?? "")) ?? 0
        let result = (couponRateValue / 100) * faceValue
        return String(format: "%.2f", result)
    }

    // 計算單次配息 = 年度配息 ÷ 配息次數
    private func calculateSingleDividend(for bond: CorporateBond) -> String {
        let annualDividend = Double(removeCommas(bond.annualDividend ?? "")) ?? 0
        let dividendMonthsStr = bond.dividendMonths ?? ""

        // 計算配息次數
        let paymentCount = countDividendPayments(dividendMonthsStr)
        guard paymentCount > 0 else { return "0.00" }

        let result = annualDividend / Double(paymentCount)
        return String(format: "%.2f", result)
    }

    // 計算配息次數
    private func countDividendPayments(_ dividendMonthsStr: String) -> Int {
        guard !dividendMonthsStr.isEmpty else { return 2 } // 預設半年配

        var months: [Int] = []

        // 統一替換頓號為逗號
        let normalized = dividendMonthsStr.replacingOccurrences(of: "、", with: ",")

        // 先嘗試用逗號分隔
        if normalized.contains(",") {
            months = normalized.split(separator: ",")
                .compactMap { part -> Int? in
                    let cleaned = part.trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "月", with: "")
                    return Int(cleaned)
                }
                .filter { $0 >= 1 && $0 <= 12 }
        }
        // 嘗試用斜線分隔
        else if dividendMonthsStr.contains("/") {
            months = dividendMonthsStr.split(separator: "/")
                .compactMap { part -> Int? in
                    let cleaned = part.trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "月", with: "")
                    return Int(cleaned)
                }
                .filter { $0 >= 1 && $0 <= 12 }
        }
        // 單一數字
        else if let month = Int(dividendMonthsStr.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "月", with: "")) {
            if month >= 1 && month <= 12 {
                months = [month]
            }
        }

        return months.isEmpty ? 2 : months.count // 預設半年配
    }

    // 計算殖利率 = 年度配息 / 交易金額
    private func calculateYieldRate(for bond: CorporateBond) -> String {
        let annualDividend = Double(removeCommas(bond.annualDividend ?? "")) ?? 0
        let transactionAmount = Double(removeCommas(bond.transactionAmount ?? "")) ?? 0

        guard transactionAmount > 0 else { return "0.00%" }

        let result = (annualDividend / transactionAmount) * 100
        return String(format: "%.2f%%", result)
    }

    // 更新自動計算欄位
    private func updateCalculatedFields(for bond: CorporateBond) {
        // 計算申購金額
        bond.subscriptionAmount = calculateSubscriptionAmount(for: bond)
        // 計算交易金額
        bond.transactionAmount = calculateTransactionAmount(for: bond)
        // 計算年度配息（先算，因為單次配息依賴它）
        bond.annualDividend = calculateAnnualDividend(for: bond)
        // 計算單次配息
        bond.singleDividend = calculateSingleDividend(for: bond)
        // 計算殖利率
        bond.yieldRate = calculateYieldRate(for: bond)
    }

    // 解析日期字串為 Date（支援多種格式）
    private func parseSubscriptionDate(_ dateString: String) -> Date? {
        let trimmed = dateString.trimmingCharacters(in: .whitespaces)

        // 定義多種日期格式
        let dateFormatters: [DateFormatter] = {
            let formats = [
                "MMM d yyyy",     // Sep 8 2023
                "MMM dd yyyy",    // Sep 08 2023
                "yyyy-MM-dd",     // 2023-09-08
                "yyyy/MM/dd",     // 2023/09/08
                "dd/MM/yyyy",     // 08/09/2023
                "MM/dd/yyyy"      // 09/08/2023
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

        return nil
    }

    // MARK: - 綁定函數
    private func bindingForBond(_ bond: CorporateBond, header: String) -> Binding<String> {
        Binding<String>(
            get: {
                let rawValue: String
                switch header {
                case "申購日":
                    // 格式化日期為 yyyy/MM/dd 格式
                    if let dateStr = bond.subscriptionDate, !dateStr.isEmpty {
                        if let date = parseSubscriptionDate(dateStr) {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy/MM/dd"
                            rawValue = formatter.string(from: date)
                        } else {
                            rawValue = dateStr
                        }
                    } else {
                        rawValue = ""
                    }
                case "債券名稱": rawValue = bond.bondName ?? ""
                case "到期日": rawValue = bond.maturityDate ?? ""
                case "幣別": rawValue = bond.currency ?? "USD"
                case "票面利率": rawValue = bond.couponRate ?? ""
                case "殖利率": rawValue = bond.yieldRate ?? ""
                case "申購價": rawValue = bond.subscriptionPrice ?? ""
                case "申購金額": rawValue = bond.subscriptionAmount ?? ""
                case "持有面額": rawValue = bond.holdingFaceValue ?? ""
                case "前手息": rawValue = bond.previousHandInterest ?? ""
                case "交易金額": rawValue = bond.transactionAmount ?? ""
                case "現值": rawValue = bond.currentValue ?? ""
                case "已領利息": rawValue = bond.receivedInterest ?? ""
                case "含息損益": rawValue = bond.profitLossWithInterest ?? ""
                case "報酬率": rawValue = bond.returnRate ?? ""
                case "配息月份": rawValue = bond.dividendMonths ?? ""
                case "單次配息": rawValue = bond.singleDividend ?? ""
                case "年度配息": rawValue = bond.annualDividend ?? ""
                default: rawValue = ""
                }

                // 如果是數字欄位，加上千分位（傳遞 header 以便特殊格式化）
                return isNumberField(header) ? formatNumberWithCommas(rawValue, forHeader: header) : rawValue
            },
            set: { newValue in
                // 自動計算欄位為只讀，不允許編輯
                guard !isCalculatedField(header) else { return }

                // 移除千分位後儲存
                let cleanValue = isNumberField(header) ? removeCommas(newValue) : newValue

                switch header {
                case "申購日":
                    bond.subscriptionDate = cleanValue
                    // 自動解析日期並設定 subscriptionDateAsDate
                    bond.subscriptionDateAsDate = parseSubscriptionDate(cleanValue)
                case "債券名稱": bond.bondName = cleanValue
                case "到期日": bond.maturityDate = cleanValue
                case "幣別": bond.currency = cleanValue
                case "票面利率":
                    bond.couponRate = cleanValue
                    // 觸發自動計算（影響配息）
                    updateCalculatedFields(for: bond)
                case "殖利率": bond.yieldRate = cleanValue
                case "申購價":
                    bond.subscriptionPrice = cleanValue
                    // 觸發自動計算
                    updateCalculatedFields(for: bond)
                case "持有面額":
                    bond.holdingFaceValue = cleanValue
                    // 觸發自動計算（影響申購金額和配息）
                    updateCalculatedFields(for: bond)
                case "前手息":
                    bond.previousHandInterest = cleanValue
                    // 觸發自動計算
                    updateCalculatedFields(for: bond)
                case "現值": bond.currentValue = cleanValue
                case "已領利息": bond.receivedInterest = cleanValue
                case "含息損益": bond.profitLossWithInterest = cleanValue
                case "報酬率": bond.returnRate = cleanValue
                case "配息月份":
                    bond.dividendMonths = cleanValue
                    // 取得當前年度配息（不重新計算，保持原值）
                    let currentAnnual = Double(removeCommas(bond.annualDividend ?? "")) ?? 0
                    print("📊 配息月份變更: \(cleanValue)")
                    print("📊 當前年度配息: \(currentAnnual)")

                    // 計算配息次數
                    let paymentCount = countDividendPayments(cleanValue)
                    print("📊 配息次數: \(paymentCount)")

                    // 計算新的單次配息
                    let newSingle = currentAnnual / Double(paymentCount)
                    let newSingleStr = String(format: "%.2f", newSingle)
                    print("📊 新單次配息: \(newSingleStr)")

                    // 更新單次配息
                    bond.singleDividend = newSingleStr

                    // 立即儲存確保資料一致
                    try? viewContext.save()
                    print("📊 儲存完成，單次配息已更新為: \(bond.singleDividend ?? "")")

                    // 強制刷新視圖
                    refreshTrigger = UUID()
                case "單次配息": bond.singleDividend = cleanValue
                case "年度配息": bond.annualDividend = cleanValue
                default: break
                }

                // 自動儲存變更
                do {
                    try viewContext.save()
                    PersistenceController.shared.save()
                } catch {
                    print("❌ 儲存失敗: \(error)")
                }
            }
        )
    }

    // MARK: - 匯入功能處理
    private func handleManualDataEntry() {
        addNewRow()
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let firstURL = urls.first else { return }

            // 開始存取安全範圍的資源
            guard firstURL.startAccessingSecurityScopedResource() else {
                print("❌ 無法存取檔案")
                return
            }

            defer {
                firstURL.stopAccessingSecurityScopedResource()
            }

            do {
                let csvContent = try String(contentsOf: firstURL, encoding: .utf8)
                parseAndImportCSV(csvContent)
            } catch {
                print("❌ 讀取檔案失敗：\(error.localizedDescription)")
            }

        case .failure(let error):
            print("❌ 檔案選擇失敗：\(error.localizedDescription)")
        }
    }

    // MARK: - CSV 解析和匯入
    private func parseAndImportCSV(_ csvContent: String) {
        guard let client = client else {
            print("❌ 無法匯入資料：沒有選中的客戶")
            return
        }

        let lines = csvContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard lines.count >= 2 else {
            print("❌ CSV 檔案格式錯誤：資料不足")
            return
        }

        // 第一行是表頭
        let headers = parseCSVLine(lines[0])
        print("📋 CSV 表頭：\(headers)")

        // 建立表頭索引映射
        var headerIndexMap: [String: Int] = [:]
        for (index, header) in headers.enumerated() {
            let normalizedHeader = header.trimmingCharacters(in: .whitespaces)
            headerIndexMap[normalizedHeader] = index
        }

        // 驗證必要欄位是否存在（債券名稱 或 名稱）
        let hasRequiredField = headerIndexMap["債券名稱"] != nil ||
                              headerIndexMap["名稱"] != nil ||
                              headerIndexMap["Bond Name"] != nil

        if !hasRequiredField {
            print("❌ CSV 檔案缺少必要欄位：債券名稱（或名稱）")
            return
        }

        // 從第二行開始匯入資料
        var importCount = 0
        for i in 1..<lines.count {
            let values = parseCSVLine(lines[i])

            // 如果這行是空的，跳過
            if values.allSatisfy({ $0.isEmpty }) {
                continue
            }

            let newBond = CorporateBond(context: viewContext)
            newBond.client = client
            newBond.createdDate = Date()

            // 根據表頭映射來設定值
            let subscriptionDateString = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "申購日")
            newBond.subscriptionDate = subscriptionDateString
            newBond.subscriptionDateAsDate = parseSubscriptionDate(subscriptionDateString)
            newBond.bondName = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "債券名稱")
            newBond.maturityDate = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "到期日")
            let currencyValue = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "幣別")
            newBond.currency = currencyValue.isEmpty ? "USD" : currencyValue
            newBond.couponRate = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "票面利率")
            newBond.yieldRate = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "殖利率")
            newBond.subscriptionPrice = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "申購價")
            newBond.subscriptionAmount = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "申購金額")
            newBond.holdingFaceValue = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "持有面額")
            newBond.previousHandInterest = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "前手息")
            newBond.transactionAmount = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "交易金額")
            newBond.currentValue = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "現值")
            newBond.receivedInterest = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "已領利息")
            newBond.profitLossWithInterest = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "含息損益")
            newBond.returnRate = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "報酬率")
            newBond.dividendMonths = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "配息月份")
            newBond.singleDividend = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "單次配息")
            newBond.annualDividend = getValueFromCSV(values: values, headerMap: headerIndexMap, header: "年度配息")

            importCount += 1
        }

        // 儲存到 Core Data 和 iCloud
        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 成功匯入 \(importCount) 筆公司債資料並同步到 iCloud")
        } catch {
            print("❌ 儲存失敗：\(error.localizedDescription)")
        }
    }

    // 解析 CSV 行（處理引號包圍的值）
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }

        result.append(currentField.trimmingCharacters(in: .whitespaces))
        return result
    }

    // 從 CSV 值陣列中獲取指定表頭的值（支援多種可能的表頭名稱）
    private func getValueFromCSV(values: [String], headerMap: [String: Int], header: String) -> String {
        // 嘗試多種可能的表頭名稱
        let possibleHeaders = getPossibleHeaderNames(for: header)

        for possibleHeader in possibleHeaders {
            if let index = headerMap[possibleHeader], index < values.count {
                let value = values[index]
                // 移除數字中的逗號（如果有的話）
                return value.replacingOccurrences(of: ",", with: "")
            }
        }

        return ""
    }

    // 取得可能的表頭名稱（支援別名）
    private func getPossibleHeaderNames(for header: String) -> [String] {
        switch header {
        case "申購日": return ["申購日", "Subscription Date"]
        case "債券名稱": return ["債券名稱", "名稱", "Bond Name"]
        case "到期日": return ["到期日", "Maturity Date"]
        case "幣別": return ["幣別", "Currency"]
        case "票面利率": return ["票面利率", "Coupon Rate"]
        case "殖利率": return ["殖利率", "Yield Rate"]
        case "申購價": return ["申購價", "Subscription Price"]
        case "申購金額": return ["申購金額", "Subscription Amount"]
        case "持有面額": return ["持有面額", "Holding Face Value"]
        case "前手息": return ["前手息", "Previous Hand Interest"]
        case "交易金額": return ["交易金額", "Transaction Amount"]
        case "現值": return ["現值", "Current Value"]
        case "已領利息": return ["已領利息", "Received Interest"]
        case "含息損益": return ["含息損益", "Profit Loss With Interest"]
        case "報酬率": return ["報酬率", "Return Rate"]
        case "配息月份": return ["配息月份", "Dividend Months"]
        case "單次配息": return ["單次配息", "Single Dividend"]
        case "年度配息": return ["年度配息", "Annual Dividend"]
        default: return [header]
        }
    }
}

#Preview {
    CorporateBondsDetailView(client: nil)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .padding()
}