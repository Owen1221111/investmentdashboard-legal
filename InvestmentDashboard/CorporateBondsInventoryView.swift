import SwiftUI
import CoreData

struct CorporateBondsInventoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client?

    // FetchRequest 取得當前客戶的公司債資料
    @FetchRequest private var corporateBonds: FetchedResults<CorporateBond>

    // FetchRequest 取得當前客戶的債券更新記錄（顯示最近 12 筆）
    @FetchRequest private var bondUpdateRecords: FetchedResults<BondUpdateRecord>

    @State private var showingSyncConfirmation = false
    @State private var showingSyncResult = false
    @State private var syncMessage = ""
    @State private var showingUpdateFromMonthlyAsset = false
    @State private var showingUpdateResult = false

    // 編輯記錄狀態
    @State private var editingRecord: BondUpdateRecord? = nil
    @State private var editRecordValue: String = ""
    @State private var editRecordInterest: String = ""
    @State private var updateMessage = ""
    @State private var showingAddBond = false
    @State private var showingSyncToBondDetail = false
    @State private var syncToBondDetailMessage = ""
    @State private var showingRecalculateConfirmation = false
    @State private var showingRecalculateResult = false
    @State private var recalculateMessage = ""

    // 可編輯的總值
    @State private var editableTotalCost = ""
    @State private var editableTotalCurrentValue = ""
    @State private var editableTotalReceivedInterest = ""
    @State private var isEditingValues = false

    // 債券編輯模式相關（⭐️ 使用 @AppStorage 實現跨視圖同步）
    // 使用動態生成的客戶專屬 key
    @State private var bondEditModeKey: String = ""
    @State private var bondEditModeRawValue: String = BondEditMode.individualUpdate.rawValue

    @State private var bondsTotalValue: String = ""
    @State private var bondsTotalInterest: String = ""

    // ⭐️ 多選刪除功能
    @State private var isEditingRecords = false // 是否進入編輯模式
    @State private var selectedRecords: Set<NSManagedObjectID> = [] // 選中的記錄

    // 匯率資料（全域共用，保持 @AppStorage）
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

    private var bondEditMode: BondEditMode {
        get { BondEditMode(rawValue: bondEditModeRawValue) ?? .batchUpdate }
        set { bondEditModeRawValue = newValue.rawValue }
    }

    private var bondEditModeBinding: Binding<BondEditMode> {
        Binding(
            get: { self.bondEditMode },
            set: { newValue in
                self.bondEditModeRawValue = newValue.rawValue
                // 同步到 UserDefaults
                UserDefaults.standard.set(newValue.rawValue, forKey: self.clientSpecificBondEditModeKey)
                // 發送通知，通知其他視圖模式已變更
                NotificationCenter.default.post(name: .init("BondEditModeDidChange"), object: nil)
                print("✅ 債券小卡：債券編輯模式已變更為：\(newValue.rawValue)")
            }
        )
    }

    // MARK: - 客戶特定的 UserDefaults Key
    private var clientSpecificBondEditModeKey: String {
        guard let clientID = client?.objectID.uriRepresentation().absoluteString else {
            return "bondEditMode_default"
        }
        return "bondEditMode_\(clientID)"
    }

    private var clientSpecificTotalValueKey: String {
        guard let clientID = client?.objectID.uriRepresentation().absoluteString else {
            return "bondsTotalValue_default"
        }
        return "bondsTotalValue_\(clientID)"
    }

    private var clientSpecificTotalInterestKey: String {
        guard let clientID = client?.objectID.uriRepresentation().absoluteString else {
            return "bondsTotalInterest_default"
        }
        return "bondsTotalInterest_\(clientID)"
    }

    // ⭐️ 從 CoreData 載入最新的債券更新記錄
    private func loadBatchData() {
        // 載入債券編輯模式
        bondEditModeRawValue = UserDefaults.standard.string(forKey: clientSpecificBondEditModeKey) ?? BondEditMode.individualUpdate.rawValue

        // ⭐️ 優先從 BondUpdateRecord 載入最新記錄（CoreData）
        if let latestRecord = bondUpdateRecords.first {
            bondsTotalValue = latestRecord.totalCurrentValue ?? ""
            bondsTotalInterest = latestRecord.totalInterest ?? ""
            print("✅ 載入批次數據（從 CoreData），客戶: \(client?.name ?? "Unknown"), 模式: \(bondEditModeRawValue), 總現值: \(bondsTotalValue), 總利息: \(bondsTotalInterest)")
        } else {
            // 沒有歷史記錄，清空輸入框
            bondsTotalValue = ""
            bondsTotalInterest = ""
            print("✅ 載入批次數據（無記錄），客戶: \(client?.name ?? "Unknown"), 模式: \(bondEditModeRawValue)")
        }

        // ⭐️ 載入後立即更新可編輯欄位的顯示
        updateEditableValues()
    }

    // 保存數據到 UserDefaults
    private func saveBatchData() {
        UserDefaults.standard.set(bondsTotalValue, forKey: clientSpecificTotalValueKey)
        UserDefaults.standard.set(bondsTotalInterest, forKey: clientSpecificTotalInterestKey)
        print("✅ 保存批次數據，客戶: \(client?.name ?? "Unknown"), Key: \(clientSpecificTotalValueKey), 總現值: \(bondsTotalValue), 總利息: \(bondsTotalInterest)")

        // 驗證儲存
        let savedValue = UserDefaults.standard.string(forKey: clientSpecificTotalValueKey)
        let savedInterest = UserDefaults.standard.string(forKey: clientSpecificTotalInterestKey)
        print("✅ 驗證儲存結果 - 總現值: \(savedValue ?? "nil"), 總利息: \(savedInterest ?? "nil")")
    }

    // MARK: - 保存債券更新記錄到 CoreData
    private func saveBondUpdateRecord() {
        guard let client = client else {
            print("❌ 無法保存：客戶資料不存在")
            return
        }

        // 創建新的 BondUpdateRecord
        let newRecord = BondUpdateRecord(context: viewContext)
        newRecord.recordDate = Date()
        newRecord.totalCurrentValue = editableTotalCurrentValue.replacingOccurrences(of: ",", with: "")
        newRecord.totalInterest = editableTotalReceivedInterest.replacingOccurrences(of: ",", with: "")
        newRecord.createdDate = Date()
        newRecord.client = client

        do {
            try viewContext.save()
            PersistenceController.shared.save()

            // 同步更新到 bondsTotalValue 和 bondsTotalInterest（用於顯示）
            bondsTotalValue = editableTotalCurrentValue
            bondsTotalInterest = editableTotalReceivedInterest

            print("✅ 債券更新記錄已保存，客戶: \(client.name ?? "Unknown"), 總現值: \(newRecord.totalCurrentValue ?? ""), 總利息: \(newRecord.totalInterest ?? "")")
        } catch {
            print("❌ 保存債券更新記錄失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - 新增空白記錄
    private func addNewRecord() {
        guard let client = client else {
            print("❌ 無法新增：客戶資料不存在")
            return
        }

        // 創建新的空白記錄
        let newRecord = BondUpdateRecord(context: viewContext)
        newRecord.recordDate = Date()
        newRecord.totalCurrentValue = "0"
        newRecord.totalInterest = "0"
        newRecord.createdDate = Date()
        newRecord.client = client

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 新增空白記錄成功")

            // 立即進入編輯模式
            startEditingRecord(newRecord)
        } catch {
            print("❌ 新增記錄失敗: \(error.localizedDescription)")
        }
    }

    init(client: Client?) {
        self.client = client

        // 設定 FetchRequest 以取得該客戶的公司債資料（排除橘色行記錄）
        if let client = client {
            _corporateBonds = FetchRequest<CorporateBond>(
                sortDescriptors: [NSSortDescriptor(keyPath: \CorporateBond.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@ AND bondName != %@", client, "__BATCH_UPDATE__"),
                animation: .default
            )

            // 設定 FetchRequest 以取得該客戶的債券更新記錄（最近 12 筆）
            _bondUpdateRecords = FetchRequest<BondUpdateRecord>(
                sortDescriptors: [NSSortDescriptor(keyPath: \BondUpdateRecord.recordDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client),
                animation: .default
            )
        } else {
            _corporateBonds = FetchRequest<CorporateBond>(
                sortDescriptors: [NSSortDescriptor(keyPath: \CorporateBond.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )

            _bondUpdateRecords = FetchRequest<BondUpdateRecord>(
                sortDescriptors: [NSSortDescriptor(keyPath: \BondUpdateRecord.recordDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 標題區域
                    headerView

                    Divider()

                    // 主要內容區域
                    mainContentView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // 功能選單（簡化版）
                        Menu {
                            // 同步到月度資產
                            Button(action: {
                                showingSyncConfirmation = true
                            }) {
                                Label("同步至月度資產", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .disabled(corporateBonds.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }

                        // 新增按鈕
                        Button(action: {
                            showingAddBond = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .confirmationDialog("確認更新", isPresented: $showingUpdateFromMonthlyAsset, titleVisibility: .visible) {
                Button("從月度資產更新") {
                    updateFromMonthlyAsset()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("將從最新的月度資產記錄中讀取債券現值，並更新所有公司債的現值數據，是否繼續？")
            }
            .confirmationDialog("確認同步", isPresented: $showingSyncConfirmation, titleVisibility: .visible) {
                Button("同步到月度資產") {
                    syncToMonthlyAsset()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("將當前公司債的總現值和總成本同步到最新的月度資產記錄，是否繼續？")
            }
            .alert("更新結果", isPresented: $showingUpdateResult) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(updateMessage)
            }
            .alert("同步結果", isPresented: $showingSyncResult) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(syncMessage)
            }
            .confirmationDialog("確認同步", isPresented: $showingSyncToBondDetail, titleVisibility: .visible) {
                Button("同步到公司債明細") {
                    syncToBondDetail()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("將保存當前所有公司債的編輯，並確保數據同步到公司債明細表格，是否繼續？")
            }
            .confirmationDialog("確認重新計算", isPresented: $showingRecalculateConfirmation, titleVisibility: .visible) {
                Button("重新計算報酬率") {
                    recalculateReturnRates()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("將根據各債券的現值、交易金額、已領利息重新計算報酬率，是否繼續？")
            }
            .alert("計算結果", isPresented: $showingRecalculateResult) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(recalculateMessage)
            }
            .sheet(isPresented: $showingAddBond) {
                if let client = client {
                    AddMonthlyDataView(onSave: { _, _ in
                        // 保存成功後關閉視圖
                    }, client: client)
                    .environment(\.managedObjectContext, viewContext)
                }
            }
            // ⭐️ 載入批次更新數據（從 UserDefaults）
            .onAppear {
                loadBatchData()
            }
            // ⭐️ 監聽模式變更通知（其他視圖可能改變模式）
            .onReceive(NotificationCenter.default.publisher(for: .init("BondEditModeDidChange"))) { _ in
                // 重新載入模式（不重新載入數值，避免覆蓋當前編輯）
                bondEditModeRawValue = UserDefaults.standard.string(forKey: clientSpecificBondEditModeKey) ?? BondEditMode.batchUpdate.rawValue
                print("✅ 債券小卡：收到模式變更通知，已同步為：\(bondEditModeRawValue)")
            }
            .sheet(item: $editingRecord) { record in
                editRecordSheet(record)
            }
        }
    }

    // MARK: - 主要內容區域
    @ViewBuilder
    private var mainContentView: some View {
        // 公司債列表（僅在逐一更新模式顯示）
        if bondEditMode == .individualUpdate {
            if corporateBonds.isEmpty {
                emptyStateView
            } else {
                bondListView
            }
        }

        // 歷史記錄表格（僅在批次更新模式顯示）
        if bondEditMode == .batchUpdate {
            bondUpdateRecordsTableView
        }
    }

    // MARK: - 標題區域
    private var headerView: some View {
        VStack(spacing: 12) {
            // 第一行：總成本、報酬率
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("總成本")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    TextField("", text: $editableTotalCost)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 30)

                VStack(spacing: 4) {
                    Text("報酬率")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(formatReturnRate(getTotalReturnRate()))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(getTotalReturnRate() >= 0 ? .green : .red)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }

            // 第二行：總現值、總已領利息
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("總現值")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    TextField("", text: $editableTotalCurrentValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .lineLimit(1)
                        .padding(8)
                        .background(bondEditMode == .batchUpdate ? Color.orange.opacity(0.12) : Color.clear)
                        .cornerRadius(6)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 30)

                VStack(spacing: 4) {
                    Text("總已領利息")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    TextField("", text: $editableTotalReceivedInterest)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .lineLimit(1)
                        .padding(8)
                        .background(bondEditMode == .batchUpdate ? Color.orange.opacity(0.12) : Color.clear)
                        .cornerRadius(6)
                }
                .frame(maxWidth: .infinity)
            }

            // 計算方式警語
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(bondEditMode == .batchUpdate ? .orange : .blue)
                Text(bondEditMode == .batchUpdate ? "目前使用「更新總額、總利息」模式計算" : "目前使用「逐一更新現值、已領息」模式計算")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(bondEditMode == .batchUpdate ? Color.orange.opacity(0.08) : Color.blue.opacity(0.08))
            .cornerRadius(8)
            .padding(.horizontal, 12)

            // 模式切換按鈕
            Picker("債券計算模式", selection: bondEditModeBinding) {
                ForEach(BondEditMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)

            // ⭐️ 儲存記錄按鈕（批次更新模式時顯示）
            if bondEditMode == .batchUpdate {
                Button(action: {
                    saveBondUpdateRecord()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("儲存記錄")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .onAppear {
            updateEditableValues()
        }
        .onChange(of: bondEditMode) { _ in
            updateEditableValues()
        }
        .onChange(of: bondsTotalValue) { _ in
            if bondEditMode == .batchUpdate {
                updateEditableValues()
            }
        }
        .onChange(of: bondsTotalInterest) { _ in
            if bondEditMode == .batchUpdate {
                updateEditableValues()
            }
        }
    }

    // MARK: - 空狀態視圖
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("尚無公司債資料")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)

            Text("點擊右上角 + 按鈕新增公司債")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 公司債列表
    private var bondListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(corporateBonds, id: \.self) { bond in
                BondInventoryRow(
                    bond: bond,
                    onUpdate: {
                        updateEditableValues()
                        do {
                            try viewContext.save()
                            PersistenceController.shared.save()
                        } catch {
                            print("保存失敗: \(error.localizedDescription)")
                        }
                    },
                    onDelete: {
                        deleteBond(bond)
                    }
                )
            }
        }
        .padding(16)
    }

    // MARK: - 債券更新歷史記錄表格
    private var bondUpdateRecordsTableView: some View {
        VStack(spacing: 0) {
            tableHeaderView
            Divider()
            tableContentView
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(16)
    }

    // 表格標題
    private var tableHeaderView: some View {
        HStack {
            Text("歷史記錄")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
            Text("最近 12 筆")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            // ⭐️ 編輯/刪除按鈕（進入多選模式）
            if !isEditingRecords {
                Button(action: {
                    withAnimation {
                        isEditingRecords = true
                        selectedRecords.removeAll()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
                .opacity(bondUpdateRecords.isEmpty ? 0.3 : 1.0)
                .disabled(bondUpdateRecords.isEmpty)
            } else {
                // 刪除選中的記錄
                Button(action: {
                    deleteSelectedRecords()
                }) {
                    Text("刪除 (\(selectedRecords.count))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .disabled(selectedRecords.isEmpty)
                .opacity(selectedRecords.isEmpty ? 0.5 : 1.0)

                // 取消按鈕
                Button(action: {
                    withAnimation {
                        isEditingRecords = false
                        selectedRecords.removeAll()
                    }
                }) {
                    Text("取消")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }

            // 新增記錄按鈕（只在非編輯模式顯示）
            if !isEditingRecords {
                Button(action: {
                    addNewRecord()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // 表格內容
    private var tableContentView: some View {
        Group {
            if bondUpdateRecords.isEmpty {
                emptyRecordsView
            } else {
                recordsListView
            }
        }
    }

    // 空狀態視圖
    private var emptyRecordsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("尚無歷史記錄")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            Text("點擊上方的保存按鈕來儲存記錄")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
    }

    // 記錄列表視圖
    private var recordsListView: some View {
        VStack(spacing: 0) {
            recordsTableHeader
            Divider()
            ForEach(Array(bondUpdateRecords.prefix(12)), id: \.self) { record in
                recordRow(record)
            }
        }
    }

    // 表格標頭
    private var recordsTableHeader: some View {
        HStack(spacing: 0) {
            Text("日期")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)

            Text("總現值")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 8)

            Text("總利息")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 10)
        .background(Color(white: 0.95))
    }

    // 單筆記錄行
    private func recordRow(_ record: BondUpdateRecord) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // ⭐️ 編輯模式：顯示勾選框
                if isEditingRecords {
                    Button(action: {
                        toggleRecordSelection(record)
                    }) {
                        Image(systemName: selectedRecords.contains(record.objectID) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(selectedRecords.contains(record.objectID) ? .blue : .gray)
                    }
                    .padding(.leading, 8)
                }

                Text(formatRecordDate(record.recordDate))
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)

                Text("$\(formatRecordValue(record.totalCurrentValue))")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 8)

                Text("$\(formatRecordValue(record.totalInterest))")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 8)
            }
            .padding(.vertical, 12)
            .background(selectedRecords.contains(record.objectID) ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                if isEditingRecords {
                    // 編輯模式：切換選中狀態
                    toggleRecordSelection(record)
                } else {
                    // 一般模式：點擊直接編輯
                    startEditingRecord(record)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                // 左滑刪除（只在非編輯模式顯示）
                if !isEditingRecords {
                    Button(role: .destructive) {
                        deleteRecord(record)
                    } label: {
                        Label("刪除", systemImage: "trash")
                    }

                    // 左滑編輯
                    Button {
                        startEditingRecord(record)
                    } label: {
                        Label("編輯", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }

            Divider()
        }
    }


    // MARK: - 幣別顏色
    private func getCurrencyColor(_ currency: String) -> Color {
        switch currency {
        case "USD": return Color.green
        case "TWD": return Color.blue
        case "EUR": return Color.purple
        case "JPY": return Color.orange
        case "GBP": return Color.pink
        case "CNY": return Color.red
        case "AUD": return Color.yellow
        case "CAD": return Color.mint
        case "CHF": return Color.indigo
        case "HKD": return Color.cyan
        case "SGD": return Color.teal
        default: return Color.gray
        }
    }

    // MARK: - 報酬率顏色
    private func getReturnRateColor(_ returnRate: String) -> Color {
        let value = Double(returnRate.replacingOccurrences(of: "%", with: "")) ?? 0
        return value >= 0 ? .green : .red
    }

    // MARK: - 計算總現值(折合美金)
    private func getTotalCurrentValue() -> Double {
        corporateBonds.reduce(0.0) { total, bond in
            let currency = bond.currency ?? "USD"
            let currentValue = Double(bond.currentValue?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0

            // USD 債券直接使用現值
            if currency == "USD" {
                return total + currentValue
            }

            // 非 USD 債券需要轉換
            guard let rateString = getExchangeRate(for: currency),
                  !rateString.isEmpty,
                  let rateValue = Double(rateString),
                  rateValue > 0 else {
                return total
            }

            // 計算折合美金 = 現值 ÷ 匯率
            let convertedUSD = currentValue / rateValue
            return total + convertedUSD
        }
    }

    // MARK: - 計算總成本（申購金額,折合美金）
    private func getTotalCost() -> Double {
        corporateBonds.reduce(0.0) { total, bond in
            let currency = bond.currency ?? "USD"
            let cost = Double(bond.transactionAmount?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0

            // USD 債券直接使用成本
            if currency == "USD" {
                return total + cost
            }

            // 非 USD 債券需要轉換
            guard let rateString = getExchangeRate(for: currency),
                  !rateString.isEmpty,
                  let rateValue = Double(rateString),
                  rateValue > 0 else {
                return total
            }

            // 計算折合美金 = 成本 ÷ 匯率
            let convertedUSD = cost / rateValue
            return total + convertedUSD
        }
    }

    // MARK: - 計算總已領利息(折合美金)
    private func getTotalReceivedInterest() -> Double {
        corporateBonds.reduce(0.0) { total, bond in
            let currency = bond.currency ?? "USD"
            let receivedInterest = Double(bond.receivedInterest?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0

            // USD 債券直接使用已領利息
            if currency == "USD" {
                return total + receivedInterest
            }

            // 非 USD 債券需要轉換
            guard let rateString = getExchangeRate(for: currency),
                  !rateString.isEmpty,
                  let rateValue = Double(rateString),
                  rateValue > 0 else {
                return total
            }

            // 計算折合美金 = 已領利息 ÷ 匯率
            let convertedUSD = receivedInterest / rateValue
            return total + convertedUSD
        }
    }

    // MARK: - 獲取匯率
    private func getExchangeRate(for currency: String) -> String? {
        switch currency {
        case "TWD": return exchangeRate
        case "EUR": return eurRate
        case "JPY": return jpyRate
        case "GBP": return gbpRate
        case "CNY": return cnyRate
        case "AUD": return audRate
        case "CAD": return cadRate
        case "CHF": return chfRate
        case "HKD": return hkdRate
        case "SGD": return sgdRate
        default: return nil
        }
    }

    // MARK: - 計算總報酬率
    private func getTotalReturnRate() -> Double {
        let totalCost = getTotalCost()
        guard totalCost > 0 else { return 0 }

        let totalCurrentValue: Double
        let totalReceivedInterest: Double

        // 根據債券編輯模式決定使用的數據源
        if bondEditMode == .batchUpdate {
            // 使用最新的歷史記錄（如果有的話）
            if let latestRecord = bondUpdateRecords.first {
                totalCurrentValue = Double(latestRecord.totalCurrentValue?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
                totalReceivedInterest = Double(latestRecord.totalInterest?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
            } else {
                // 如果沒有歷史記錄，使用當前輸入的值
                totalCurrentValue = Double(bondsTotalValue.replacingOccurrences(of: ",", with: "")) ?? 0
                totalReceivedInterest = Double(bondsTotalInterest.replacingOccurrences(of: ",", with: "")) ?? 0
            }
        } else {
            // 從債券資料計算(已折合美金)
            totalCurrentValue = getTotalCurrentValue()
            totalReceivedInterest = getTotalReceivedInterest()
        }

        return ((totalCurrentValue - totalCost + totalReceivedInterest) / totalCost) * 100
    }

    // MARK: - 從月度資產更新
    private func updateFromMonthlyAsset() {
        guard let client = client else {
            updateMessage = "無法找到客戶資料"
            showingUpdateResult = true
            return
        }

        // 獲取最新的月度資產記錄
        let fetchRequest: NSFetchRequest<MonthlyAsset> = MonthlyAsset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)

            guard let latestAsset = results.first else {
                updateMessage = "找不到月度資產記錄，請先新增月度資產"
                showingUpdateResult = true
                return
            }

            // 從月度資產讀取債券數據
            let bondsValue = Double(latestAsset.bonds ?? "0") ?? 0
            let confirmedInterest = Double(latestAsset.confirmedInterest ?? "0") ?? 0

            if corporateBonds.isEmpty {
                updateMessage = "沒有公司債記錄可以更新"
                showingUpdateResult = true
                return
            }

            // 計算當前總成本
            let totalCost = getTotalCost()

            // 按比例更新每個公司債的現值和已領利息
            if totalCost > 0 {
                for bond in corporateBonds {
                    let bondCost = Double(bond.transactionAmount ?? "0") ?? 0
                    let ratio = bondCost / totalCost

                    // 按比例分配現值
                    let newValue = bondsValue * ratio
                    bond.currentValue = String(format: "%.2f", newValue)

                    // 按比例分配已領利息
                    let newReceivedInterest = confirmedInterest * ratio
                    bond.receivedInterest = String(format: "%.2f", newReceivedInterest)

                    // 不要重新計算報酬率，保持原有數據
                }

                // 更新標題區域的總值顯示
                updateEditableValues()

                // 儲存
                try viewContext.save()
                PersistenceController.shared.save()

                updateMessage = "已成功從月度資產更新\n更新了 \(corporateBonds.count) 筆公司債\n總現值: $\(String(format: "%.2f", bondsValue))\n總已領利息: $\(String(format: "%.2f", confirmedInterest))"
                showingUpdateResult = true
            } else {
                updateMessage = "無法更新：公司債總成本為 0"
                showingUpdateResult = true
            }

        } catch {
            updateMessage = "更新失敗: \(error.localizedDescription)"
            showingUpdateResult = true
        }
    }

    // MARK: - 同步到月度資產
    private func syncToMonthlyAsset() {
        guard let client = client else {
            syncMessage = "無法找到客戶資料"
            showingSyncResult = true
            return
        }

        // 獲取最新的月度資產記錄
        let fetchRequest: NSFetchRequest<MonthlyAsset> = MonthlyAsset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MonthlyAsset.createdDate, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)

            guard let latestAsset = results.first else {
                syncMessage = "找不到月度資產記錄，請先新增月度資產"
                showingSyncResult = true
                return
            }

            // 計算總現值和總成本
            let totalValue = getTotalCurrentValue()
            let totalCost = getTotalCost()

            // 更新月度資產
            latestAsset.bonds = String(format: "%.2f", totalValue)
            latestAsset.bondsCost = String(format: "%.2f", totalCost)

            // 儲存
            try viewContext.save()
            PersistenceController.shared.save()

            syncMessage = "已成功同步至月度資產\n總現值: $\(String(format: "%.2f", totalValue))\n總成本: $\(String(format: "%.2f", totalCost))"
            showingSyncResult = true

        } catch {
            syncMessage = "同步失敗: \(error.localizedDescription)"
            showingSyncResult = true
        }
    }

    // MARK: - 格式化金額
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    // MARK: - 格式化報酬率
    private func formatReturnRate(_ rate: Double) -> String {
        return String(format: "%.2f%%", rate)
    }

    // MARK: - 更新可編輯值
    private func updateEditableValues() {
        editableTotalCost = formatWithCommas(getTotalCost())

        // 根據債券編輯模式決定顯示的值
        if bondEditMode == .batchUpdate {
            // 使用批次更新模式的數據
            editableTotalCurrentValue = bondsTotalValue
            editableTotalReceivedInterest = bondsTotalInterest
        } else {
            // 從債券資料計算
            editableTotalCurrentValue = formatWithCommas(getTotalCurrentValue())
            editableTotalReceivedInterest = formatWithCommas(getTotalReceivedInterest())
        }
    }

    // MARK: - 千分位格式化
    private func formatWithCommas(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    // MARK: - 重新計算報酬率
    private func recalculateReturnRates() {
        var updatedCount = 0

        for bond in corporateBonds {
            let currentVal = Double(bond.currentValue?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
            let receivedInt = Double(bond.receivedInterest?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
            let transactionAmount = Double(bond.transactionAmount?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0

            if transactionAmount > 0 {
                let returnRateValue = ((currentVal - transactionAmount + receivedInt) / transactionAmount) * 100
                bond.returnRate = String(format: "%.2f%%", returnRateValue)
                updatedCount += 1
            }
        }

        do {
            // 保存變更
            try viewContext.save()
            PersistenceController.shared.save()

            // 更新標題區域的總值
            updateEditableValues()

            // 計算總值
            let totalCurrentValue = getTotalCurrentValue()
            let totalCost = getTotalCost()
            let totalReceivedInterest = getTotalReceivedInterest()
            let totalReturnRate = getTotalReturnRate()

            recalculateMessage = """
            已成功重新計算 \(updatedCount) 筆公司債的報酬率

            總現值: $\(String(format: "%.2f", totalCurrentValue))
            總成本: $\(String(format: "%.2f", totalCost))
            總已領利息: $\(String(format: "%.2f", totalReceivedInterest))
            總報酬率: \(String(format: "%.2f%%", totalReturnRate))
            """
            showingRecalculateResult = true
        } catch {
            recalculateMessage = "計算失敗: \(error.localizedDescription)"
            showingRecalculateResult = true
        }
    }

    // MARK: - 同步到公司債明細
    private func syncToBondDetail() {
        do {
            // 保存所有變更
            try viewContext.save()
            PersistenceController.shared.save()

            // 更新標題區域
            updateEditableValues()

            syncMessage = "已成功同步到公司債明細\n共 \(corporateBonds.count) 筆公司債\n所有數據已保存"
            showingSyncResult = true
        } catch {
            syncMessage = "同步失敗: \(error.localizedDescription)"
            showingSyncResult = true
        }
    }

    // MARK: - 刪除公司債
    private func deleteBond(_ bond: CorporateBond) {
        withAnimation {
            viewContext.delete(bond)

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                updateEditableValues()
            } catch {
                print("刪除公司債失敗: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 刪除債券更新記錄
    private func deleteRecord(_ record: BondUpdateRecord) {
        withAnimation {
            viewContext.delete(record)

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("✅ 債券更新記錄已刪除")
            } catch {
                print("❌ 刪除債券更新記錄失敗: \(error.localizedDescription)")
            }
        }
    }

    // ⭐️ 切換記錄選中狀態
    private func toggleRecordSelection(_ record: BondUpdateRecord) {
        withAnimation {
            if selectedRecords.contains(record.objectID) {
                selectedRecords.remove(record.objectID)
            } else {
                selectedRecords.insert(record.objectID)
            }
        }
    }

    // ⭐️ 刪除選中的記錄
    private func deleteSelectedRecords() {
        guard !selectedRecords.isEmpty else { return }

        withAnimation {
            // 震動回饋
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)

            // 刪除選中的記錄
            for recordID in selectedRecords {
                if let record = try? viewContext.existingObject(with: recordID) as? BondUpdateRecord {
                    viewContext.delete(record)
                }
            }

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("✅ 批次刪除 \(selectedRecords.count) 筆債券更新記錄")

                // 清空選擇並退出編輯模式
                selectedRecords.removeAll()
                isEditingRecords = false
            } catch {
                print("❌ 批次刪除債券更新記錄失敗: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 格式化記錄日期
    private func formatRecordDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    // MARK: - 格式化記錄值
    private func formatRecordValue(_ value: String?) -> String {
        guard let value = value,
              let doubleValue = Double(value.replacingOccurrences(of: ",", with: "")) else {
            return "0.00"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: doubleValue)) ?? String(format: "%.2f", doubleValue)
    }

    // MARK: - 開始編輯記錄
    private func startEditingRecord(_ record: BondUpdateRecord) {
        editRecordValue = formatRecordValue(record.totalCurrentValue)
        editRecordInterest = formatRecordValue(record.totalInterest)
        editingRecord = record
    }

    // MARK: - 保存編輯的記錄
    private func saveEditedRecord() {
        guard let record = editingRecord else { return }

        record.totalCurrentValue = editRecordValue.replacingOccurrences(of: ",", with: "")
        record.totalInterest = editRecordInterest.replacingOccurrences(of: ",", with: "")

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 債券更新記錄已修改")
            editingRecord = nil
        } catch {
            print("❌ 修改債券更新記錄失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - 編輯記錄介面
    private func editRecordSheet(_ record: BondUpdateRecord) -> some View {
        NavigationView {
            Form {
                Section(header: Text("記錄日期")) {
                    Text(formatRecordDate(record.recordDate))
                        .foregroundColor(.secondary)
                }

                Section(header: Text("總現值")) {
                    TextField("總現值", text: $editRecordValue)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("總已領利息")) {
                    TextField("總已領利息", text: $editRecordInterest)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationBarTitle("編輯記錄", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    editingRecord = nil
                },
                trailing: Button("保存") {
                    saveEditedRecord()
                }
                .fontWeight(.semibold)
            )
        }
    }
}

// MARK: - 債券行組件
struct BondInventoryRow: View {
    @ObservedObject var bond: CorporateBond
    let onUpdate: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var showingDeleteConfirmation = false

    // 匯率資料（從 QuickUpdateView 同步）
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

    var body: some View {
        VStack(spacing: 0) {
            // 基本信息行
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(bond.bondName ?? "未命名債券")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)

                            // ⭐️ 只有非美金才顯示幣別標籤
                            if let currency = bond.currency, currency != "USD" {
                                Text(currency)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(getCurrencyColor(currency))
                                    .cornerRadius(4)

                                // 非美幣別顯示匯率
                                if let rate = getExchangeRate(for: currency) {
                                    Text("@ \(rate)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.8))
                                        .cornerRadius(4)
                                }
                            }
                        }

                        HStack(spacing: 8) {
                            Text("成本: \(formatNumber(bond.transactionAmount))")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("報酬率: \(bond.returnRate ?? "0%")")
                                .font(.caption)
                                .foregroundColor(getReturnRateColor(bond.returnRate ?? "0%"))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        // 主要顯示金額：非美金顯示折合美金，美金顯示原值
                        if let currency = bond.currency, currency != "USD", let convertedUSD = calculateConvertedToUSD(bond: bond) {
                            Text("$\(convertedUSD)")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)

                            // 顯示原幣別金額與匯率
                            if let rate = getExchangeRate(for: currency) {
                                Text("@ \(rate) = \(currency) \(formatNumber(bond.currentValue))")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .id("\(bond.currentValue ?? "")-\(currency)-\(rate)") // 強制刷新
                            }
                        } else {
                            // USD 債券直接顯示美金金額
                            Text("\(formatNumber(bond.currentValue))")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)
                        }

                        Text("已領: \(formatNumber(bond.receivedInterest))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(PlainButtonStyle())

            // 展開的編輯區域
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()

                    // 編輯字段
                    VStack(spacing: 12) {
                        // 債券名稱
                        HStack {
                            Text("債券名稱")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("例如: Apple 3.5%", text: Binding(
                                get: { bond.bondName ?? "" },
                                set: { newValue in
                                    bond.bondName = newValue
                                    onUpdate()
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 幣別
                        HStack {
                            Text("幣別")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("USD", text: Binding(
                                get: { bond.currency ?? "USD" },
                                set: { newValue in
                                    bond.currency = newValue
                                    onUpdate()
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 現值
                        HStack {
                            Text("現值")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: Binding(
                                get: { bond.currentValue ?? "0" },
                                set: { newValue in
                                    bond.currentValue = newValue
                                    recalculateAndUpdate()
                                }
                            ))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 已領利息
                        HStack {
                            Text("已領利息")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("0", text: Binding(
                                get: { bond.receivedInterest ?? "0" },
                                set: { newValue in
                                    bond.receivedInterest = newValue
                                    recalculateAndUpdate()
                                }
                            ))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 票面利率
                        HStack {
                            Text("票面利率")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("例如: 3.5%", text: Binding(
                                get: { bond.couponRate ?? "" },
                                set: { newValue in
                                    bond.couponRate = newValue
                                    onUpdate()
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // 殖利率
                        HStack {
                            Text("殖利率")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("例如: 3.8%", text: Binding(
                                get: { bond.yieldRate ?? "" },
                                set: { newValue in
                                    bond.yieldRate = newValue
                                    onUpdate()
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal)

                    // 刪除按鈕
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("刪除此債券")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
                    Button("取消", role: .cancel) {}
                    Button("刪除", role: .destructive) {
                        onDelete()
                    }
                } message: {
                    Text("確定要刪除此債券嗎？此操作無法復原。")
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func recalculateAndUpdate() {
        // 重新計算報酬率
        let currentVal = Double(bond.currentValue?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
        let receivedInt = Double(bond.receivedInterest?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
        let transactionAmount = Double(bond.transactionAmount?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0

        if transactionAmount > 0 {
            let returnRateValue = ((currentVal - transactionAmount + receivedInt) / transactionAmount) * 100
            bond.returnRate = String(format: "%.2f%%", returnRateValue)
        } else {
            bond.returnRate = "0%"
        }

        onUpdate()
    }

    private func formatNumber(_ value: String?) -> String {
        guard let value = value, let number = Double(value) else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? "$0.00"
    }

    private func getCurrencyColor(_ currency: String) -> Color {
        switch currency {
        case "USD": return Color.green
        case "TWD": return Color.blue
        case "EUR": return Color.purple
        case "JPY": return Color.orange
        case "GBP": return Color.pink
        case "CNY": return Color.red
        case "AUD": return Color.yellow
        case "CAD": return Color.mint
        case "CHF": return Color.indigo
        case "HKD": return Color.cyan
        case "SGD": return Color.teal
        default: return Color.gray
        }
    }

    private func getReturnRateColor(_ returnRate: String) -> Color {
        let value = Double(returnRate.replacingOccurrences(of: "%", with: "")) ?? 0
        return value >= 0 ? .green : .red
    }

    /// 根據幣別獲取對應的匯率
    private func getExchangeRate(for currency: String) -> String? {
        let rate: String
        switch currency {
        case "TWD":
            rate = exchangeRate
        case "EUR":
            rate = eurRate
        case "JPY":
            rate = jpyRate
        case "GBP":
            rate = gbpRate
        case "CNY":
            rate = cnyRate
        case "AUD":
            rate = audRate
        case "CAD":
            rate = cadRate
        case "CHF":
            rate = chfRate
        case "HKD":
            rate = hkdRate
        case "SGD":
            rate = sgdRate
        default:
            return nil
        }

        // 只有當匯率有效時才返回
        guard !rate.isEmpty, let rateValue = Double(rate), rateValue > 0 else {
            return nil
        }

        return String(format: "%.4f", rateValue)
    }

    /// 計算折合美金金額
    private func calculateConvertedToUSD(bond: CorporateBond) -> String? {
        let currency = bond.currency ?? "USD"

        // USD 不需要轉換
        if currency == "USD" {
            return nil
        }

        // 取得匯率
        guard let rateString = getExchangeRate(for: currency),
              let rate = Double(rateString) else {
            return nil
        }

        // 取得現值
        let currentValueString = (bond.currentValue ?? "").replacingOccurrences(of: ",", with: "")
        guard let currentValue = Double(currentValueString), currentValue > 0 else {
            return nil
        }

        // 計算折合美金 = 現值 ÷ 匯率
        let convertedUSD = currentValue / rate
        return formatNumber(String(format: "%.2f", convertedUSD))
    }
}

#Preview {
    CorporateBondsInventoryView(client: nil)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
