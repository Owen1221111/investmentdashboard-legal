//
//  ContentView.swift
//  InvestmentDashboard
//
//  Created by CheHung Liu on 2025/9/25.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Client.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Client.createdDate, ascending: true)
        ],
        animation: .default)
    private var clients: FetchedResults<Client>

    @State private var selectedClient: Client?
    @State private var showingAddCustomer = false
    @State private var showingSidebar = false
    @State private var showingClientPanel = false // 控制客戶面板顯示
    @State private var showingAddMonthlyData = false // 控制月度資料新增面板
    @State private var showingInsurancePolicy = false // 控制保單管理頁面（主畫面切換）
    @State private var showingLoanManagement = false // 控制貸款管理頁面（主畫面切換）
    @State private var showingReminder = false // 控制提醒視窗顯示
    @State private var showingSubscription = false // 控制訂閱視窗顯示
    @State private var editingClient: Client? // 正在編輯的客戶
    @State private var isDragModeEnabled = false // 拖拽模式開關

    // 客戶列表（用於拖拽排序）
    @State private var clientsArray: [Client] = []

    // 導覽系統
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var showingOnboarding = false
    @StateObject private var dashboardTutorialManager = DashboardTutorialManager()
    @State private var showingDashboardTutorial = false
    @State private var showingStructuredProductTutorial = false // 結構型商品教學
    @State private var showingHelpMenu = false // 控制幫助選單顯示

    // 浮動選單
    @State private var isFloatingMenuExpanded = false
    @State private var showingCrossClientStructured = false
    @State private var showingCrossClientUSStock = false
    @State private var showingCrossClientTWStock = false
    @State private var showingCrossClientCorporateBond = false
    @State private var showingBatchAddStructured = false
    @State private var showingBatchAddUSStock = false
    @State private var showingBatchAddTWStock = false
    @State private var showingBatchAddCorporateBond = false

    // 備份系統
    @StateObject private var backupManager = BackupManager.shared
    @State private var showingBackupAlert = false
    @State private var showingRestoreAlert = false
    @State private var showingRestoreConfirm = false
    @State private var backupAlertMessage = ""

    // 更新客戶數組
    private func updateClientsArray() {
        clientsArray = Array(clients)
    }

    // 判斷是否應顯示浮動選單
    private var shouldShowFloatingMenu: Bool {
        let notShowingPages = !showingInsurancePolicy && !showingLoanManagement
        let notShowingTutorials = !showingOnboarding && !showingDashboardTutorial && !showingStructuredProductTutorial
        return notShowingPages && notShowingTutorials
    }

    var body: some View {
        finalView
    }

    @ViewBuilder
    private var contentWithCommonSheets: some View {
        baseContent
            .modifier(CommonSheetsModifier(
                showingAddMonthlyData: $showingAddMonthlyData,
                editingClient: $editingClient,
                showingReminder: $showingReminder,
                showingSubscription: $showingSubscription,
                selectedClient: selectedClient,
                addMonthlyData: addMonthlyData,
                subscriptionManager: subscriptionManager,
                viewContext: viewContext
            ))
    }

    @ViewBuilder
    private var contentWithFloatingMenuSheets: some View {
        contentWithCommonSheets
            .modifier(FloatingMenuSheetsModifier(
                showingCrossClientStructured: $showingCrossClientStructured,
                showingCrossClientUSStock: $showingCrossClientUSStock,
                showingCrossClientTWStock: $showingCrossClientTWStock,
                showingCrossClientCorporateBond: $showingCrossClientCorporateBond,
                showingBatchAddStructured: $showingBatchAddStructured,
                showingBatchAddUSStock: $showingBatchAddUSStock,
                showingBatchAddTWStock: $showingBatchAddTWStock,
                showingBatchAddCorporateBond: $showingBatchAddCorporateBond,
                selectedClient: selectedClient,
                addMonthlyData: addMonthlyData,
                viewContext: viewContext
            ))
    }

    @ViewBuilder
    private var finalView: some View {
        contentWithFloatingMenuSheets
            .modifier(BackupSheetsModifier(
                showingBackupAlert: $showingBackupAlert,
                showingRestoreAlert: $showingRestoreAlert,
                showingRestoreConfirm: $showingRestoreConfirm,
                backupAlertMessage: $backupAlertMessage,
                backupManager: backupManager,
                performRestore: performRestore
            ))
            .modifier(LifecycleModifier(
                clients: clients,
                selectedClient: selectedClient,
                showingClientPanel: showingClientPanel,
                showingOnboarding: $showingOnboarding,
                showingSubscription: $showingSubscription,
                showingDashboardTutorial: $showingDashboardTutorial,
                onboardingManager: onboardingManager,
                subscriptionManager: subscriptionManager,
                dashboardTutorialManager: dashboardTutorialManager,
                updateClientsArray: updateClientsArray
            ))
    }

    @ViewBuilder
    private var baseContent: some View {
        ZStack {
            // 主要 NavigationSplitView 內容
            VStack(spacing: 0) {
                // 自定義頂部導航欄 - 只在主畫面顯示
                if !showingInsurancePolicy && !showingLoanManagement {
                    customNavigationBar
                }

                // 主要內容區域 - 根據狀態顯示不同頁面
                if showingInsurancePolicy {
                    InsurancePolicyView(
                        client: selectedClient,
                        onBack: {
                            withAnimation {
                                showingInsurancePolicy = false
                            }
                        }
                    )
                    .environment(\.managedObjectContext, viewContext)
                } else if showingLoanManagement {
                    LoanManagementView(
                        client: selectedClient,
                        onBack: {
                            withAnimation {
                                showingLoanManagement = false
                            }
                        }
                    )
                    .environment(\.managedObjectContext, viewContext)
                } else {
                    ClientDetailView(client: selectedClient)
                        .sheet(isPresented: $showingAddCustomer) {
                            AddClientView()
                        }
                }
            }

            // 客戶選擇面板覆蓋層
            if showingClientPanel {
                clientSelectionPanel
            }

            // 導覽頁面
            if showingOnboarding {
                OnboardingView(onComplete: {
                    showingOnboarding = false
                })
                .transition(.opacity)
            }

            // 儀表板功能導覽
            if showingDashboardTutorial {
                DashboardTutorialView(onComplete: {
                    showingDashboardTutorial = false
                })
                .transition(.opacity)
            }

            // 結構型商品教學
            if showingStructuredProductTutorial {
                StructuredProductTutorialView(onComplete: {
                    showingStructuredProductTutorial = false
                })
                .transition(.opacity)
            }

            // 浮動搜尋按鈕
            if shouldShowFloatingMenu {
                FloatingMenuButton(
                    isExpanded: $isFloatingMenuExpanded,
                    onStructuredProductAdd: {
                        showingBatchAddStructured = true
                    },
                    onStructuredProductInventory: {
                        showingCrossClientStructured = true
                    },
                    onUSStockAdd: {
                        showingBatchAddUSStock = true
                    },
                    onUSStockInventory: {
                        showingCrossClientUSStock = true
                    },
                    onTWStockAdd: {
                        showingBatchAddTWStock = true
                    },
                    onTWStockInventory: {
                        showingCrossClientTWStock = true
                    },
                    onCorporateBondAdd: {
                        showingBatchAddCorporateBond = true
                    },
                    onCorporateBondInventory: {
                        showingCrossClientCorporateBond = true
                    }
                )
            }
        }
    }

    // MARK: - 自定義頂部導航欄
    private var customNavigationBar: some View {
        HStack {
            // 漢堡按鈕
            Button("☰") {
                print("🔍 漢堡按鈕被點擊 - 顯示客戶管理面板")
                // 檢查 iCloud 狀態
                PersistenceController.shared.checkCloudKitStatus()
                // 初始化客戶數組
                updateClientsArray()
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingClientPanel = true
                }
            }
            .font(.system(size: 28, weight: .medium))
            .frame(width: 44, height: 44)

            // 說明按鈕
            Button(action: {
                showingHelpMenu = true
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.blue)
            }
            .frame(width: 44, height: 44)
            .confirmationDialog("選擇功能", isPresented: $showingHelpMenu, titleVisibility: .visible) {
                Button("基本使用教學") {
                    showingOnboarding = true
                }
                Button("儀表板功能教學") {
                    showingDashboardTutorial = true
                }
                Button("結構型商品教學") {
                    showingStructuredProductTutorial = true
                }
                Button(backupManager.isBackingUp ? "備份中..." : "備份到 iCloud") {
                    performBackup()
                }
                .disabled(backupManager.isBackingUp)
                Button("從 iCloud 還原") {
                    showingRestoreConfirm = true
                }
                .disabled(backupManager.isRestoring)
                Button("取消", role: .cancel) {}
            }

            // 訂閱按鈕
            Button(action: {
                showingSubscription = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: subscriptionManager.isSubscriptionActive ? "crown.fill" : "crown")
                        .font(.system(size: 16, weight: .medium))

                    if subscriptionManager.subscriptionStatus == .inTrialPeriod,
                       let days = subscriptionManager.remainingTrialDays() {
                        Text("\(days)天")
                            .font(.system(size: 10, weight: .bold))
                    }
                }
                .foregroundStyle(
                    subscriptionManager.isSubscriptionActive
                        ? LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.gray], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
            .frame(width: 44, height: 44)

            Spacer()

            // 標題
            VStack(spacing: 2) {
                Text("儀表板")
                    .font(.headline)
                    .fontWeight(.semibold)

                if let client = selectedClient {
                    Text(client.name ?? "未知客戶")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 右側按鈕組
            HStack(spacing: 6) {
                // 保險按鈕
                Button(action: {
                    showingInsurancePolicy = true
                }) {
                    Text("保險")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        .fixedSize()
                }

                // 提醒按鈕
                Button(action: {
                    showingReminder = true
                }) {
                    Text("提醒")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        .fixedSize()
                }

                // 貸款按鈕
                Button(action: {
                    showingLoanManagement = true
                }) {
                    Text("貸款")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        .fixedSize()
                }

                // 新增資料按鈕
                Button(action: {
                    // 檢查訂閱狀態
                    if !subscriptionManager.canAccessPremiumFeatures() {
                        showingSubscription = true
                    } else {
                        showingAddMonthlyData = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                }
                .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 0)
        .frame(height: 52)
        .background(Color(.systemBackground))
    }

    // MARK: - 客戶選擇面板
    private var clientSelectionPanel: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingClientPanel = false
                    }
                }

            // 側邊欄內容
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    // 標題區域
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("客戶管理")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(isDragModeEnabled ? "拖動以重新排序" : "選擇或管理客戶")
                                .font(.caption)
                                .foregroundColor(isDragModeEnabled ? .orange : .secondary)
                        }

                        Spacer()

                        // 新增客戶按鈕
                        Button(action: {
                            // 檢查訂閱狀態
                            if !subscriptionManager.canAccessPremiumFeatures() {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingClientPanel = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    showingSubscription = true
                                }
                            } else {
                                showingAddCustomer = true
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.green)
                        }
                        .frame(width: 44, height: 44)

                        // 拖拽模式切換按鈕
                        Button(action: {
                            isDragModeEnabled.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isDragModeEnabled ? "checkmark" : "arrow.up.arrow.down")
                                Text(isDragModeEnabled ? "完成" : "排序")
                            }
                            .font(.caption)
                            .foregroundColor(isDragModeEnabled ? .green : .blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((isDragModeEnabled ? Color.green : Color.blue).opacity(0.1))
                            .cornerRadius(6)
                        }

                        // 關閉按鈕
                        Button("✕") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingClientPanel = false
                            }
                        }
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                        )
                    }
                    .padding()

                    Divider()

                    // 客戶列表區域
                    VStack(spacing: 0) {
                        // 客戶列表
                        if isDragModeEnabled {
                            // 拖拽模式 - 使用 List
                            List {
                                ForEach(clientsArray, id: \.self) { client in
                                    DragClientRow(
                                        client: client,
                                        selectedClient: $selectedClient
                                    )
                                }
                                .onMove(perform: moveClients)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .listStyle(PlainListStyle())
                            .background(Color(.systemBackground))
                        } else {
                            // 正常模式 - 使用 ScrollView
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(clientsArray, id: \.self) { client in
                                        ClientRowButton(
                                            client: client,
                                            selectedClient: $selectedClient,
                                            editingClient: $editingClient,
                                            resetTrigger: false,
                                            onClientSelected: {
                                                // 選擇客戶後關閉面板
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    showingClientPanel = false
                                                }
                                            },
                                            onClientDelete: { clientToDelete in
                                                deleteClient(clientToDelete)
                                            },
                                            onClientEdit: { clientToEdit in
                                                editingClient = clientToEdit
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                                .background(Color(.systemBackground))
                            }
                            .background(Color(.systemBackground))
                        }
                    }
                    .background(Color(.systemBackground))

                    Spacer()
                }
                .frame(width: min(UIScreen.main.bounds.width * 0.75, 320))
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 2, y: 0)

                Spacer()
            }
            .transition(.move(edge: .leading))
        }
        .zIndex(1000)
    }

    // MARK: - 刪除客戶功能
    private func deleteClients(offsets: IndexSet) {
        withAnimation {
            offsets.map { clients[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("客戶已從 iCloud 刪除")
            } catch {
                print("Delete error: \(error)")
            }
        }
    }

    private func deleteClient(_ client: Client) {
        withAnimation {
            // 如果刪除的是當前選中的客戶，清除選擇
            if selectedClient == client {
                selectedClient = nil
            }

            viewContext.delete(client)
            // 同時從本地數組中移除
            clientsArray.removeAll { $0 == client }

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("客戶 '\(client.name ?? "未知")' 已從 iCloud 刪除")
            } catch {
                print("Delete error: \(error)")
            }
        }
    }

    // 拖拽移動客戶
    private func moveClients(from source: IndexSet, to destination: Int) {
        withAnimation {
            clientsArray.move(fromOffsets: source, toOffset: destination)
            print("🔄 客戶順序已更新")

            // 持久化順序：更新所有客戶的 sortOrder
            for (index, client) in clientsArray.enumerated() {
                client.sortOrder = Int16(index)
            }

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("✅ 客戶排序已保存到 iCloud")
            } catch {
                print("❌ 保存排序失敗: \(error)")
            }
        }
    }

    // MARK: - 備份功能
    private func performBackup() {
        backupManager.backup(context: viewContext) { success, error in
            if !success {
                backupAlertMessage = "備份失敗：\(error ?? "未知錯誤")"
                showingBackupAlert = true
            }
            // 成功時會自動顯示分享表單
        }
    }

    private func performRestore() {
        backupManager.restore(context: viewContext) { success, error in
            if success {
                backupAlertMessage = "還原成功！請重新選擇客戶查看資料"
            } else {
                backupAlertMessage = "還原失敗：\(error ?? "未知錯誤")"
            }
            showingRestoreAlert = true
        }
    }

    // MARK: - 新增月度資料功能
    private func addMonthlyData(_ newData: [String], _ selectedDate: Date) {
        print("📊 新增月度資料：\(newData)")

        // 確保有選中的客戶
        guard let currentClient = selectedClient else {
            print("❌ 沒有選中客戶，無法儲存資料")
            return
        }

        print("💾 為客戶 \(currentClient.name ?? "Unknown") 儲存月度資料到 Core Data")

        // 直接儲存到 Core Data
        withAnimation {
            let newAsset = MonthlyAsset(context: viewContext)
            newAsset.client = currentClient
            newAsset.date = newData[safe: 0] ?? ""
            newAsset.twdCash = newData[safe: 1] ?? ""
            newAsset.cash = newData[safe: 2] ?? ""
            newAsset.usStock = newData[safe: 3] ?? ""
            newAsset.regularInvestment = newData[safe: 4] ?? ""
            newAsset.bonds = newData[safe: 5] ?? ""
            newAsset.confirmedInterest = newData[safe: 6] ?? ""
            newAsset.structured = newData[safe: 7] ?? ""
            newAsset.taiwanStock = newData[safe: 8] ?? ""
            newAsset.taiwanStockFolded = newData[safe: 9] ?? ""
            newAsset.twdToUsd = newData[safe: 10] ?? ""
            newAsset.totalAssets = newData[safe: 11] ?? ""
            newAsset.exchangeRate = newData[safe: 12] ?? "32"
            newAsset.deposit = newData[safe: 13] ?? ""
            newAsset.depositAccumulated = newData[safe: 14] ?? ""
            newAsset.usStockCost = newData[safe: 15] ?? ""
            newAsset.regularInvestmentCost = newData[safe: 16] ?? ""
            newAsset.bondsCost = newData[safe: 17] ?? ""
            newAsset.taiwanStockCost = newData[safe: 18] ?? ""
            newAsset.notes = newData[safe: 19] ?? ""
            newAsset.fund = newData[safe: 20] ?? ""
            newAsset.fundCost = newData[safe: 21] ?? ""
            newAsset.insurance = newData[safe: 22] ?? ""
            // 其他貨幣現金
            newAsset.eurCash = newData[safe: 23] ?? ""
            newAsset.jpyCash = newData[safe: 24] ?? ""
            newAsset.gbpCash = newData[safe: 25] ?? ""
            newAsset.cnyCash = newData[safe: 26] ?? ""
            newAsset.audCash = newData[safe: 27] ?? ""
            newAsset.cadCash = newData[safe: 28] ?? ""
            newAsset.chfCash = newData[safe: 29] ?? ""
            newAsset.hkdCash = newData[safe: 30] ?? ""
            newAsset.sgdCash = newData[safe: 31] ?? ""
            // 貨幣折合美金
            newAsset.eurToUsd = newData[safe: 32] ?? ""
            newAsset.jpyToUsd = newData[safe: 33] ?? ""
            newAsset.gbpToUsd = newData[safe: 34] ?? ""
            newAsset.cnyToUsd = newData[safe: 35] ?? ""
            newAsset.audToUsd = newData[safe: 36] ?? ""
            newAsset.cadToUsd = newData[safe: 37] ?? ""
            newAsset.chfToUsd = newData[safe: 38] ?? ""
            newAsset.hkdToUsd = newData[safe: 39] ?? ""
            newAsset.sgdToUsd = newData[safe: 40] ?? ""
            // 匯率
            newAsset.eurRate = newData[safe: 41] ?? ""
            newAsset.jpyRate = newData[safe: 42] ?? ""
            newAsset.gbpRate = newData[safe: 43] ?? ""
            newAsset.cnyRate = newData[safe: 44] ?? ""
            newAsset.audRate = newData[safe: 45] ?? ""
            newAsset.cadRate = newData[safe: 46] ?? ""
            newAsset.chfRate = newData[safe: 47] ?? ""
            newAsset.hkdRate = newData[safe: 48] ?? ""
            newAsset.sgdRate = newData[safe: 49] ?? ""
            newAsset.createdDate = selectedDate // 修改：使用使用者選擇的日期

            do {
                try viewContext.save()

                // ⭐️ 刷新物件快取
                viewContext.refreshAllObjects()

                PersistenceController.shared.save()
                print("✅ 月度資產已儲存並同步到 iCloud")

                // ⭐️ 發送通知讓儀表板刷新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let clientKey = currentClient.objectID.uriRepresentation().absoluteString
                    NotificationCenter.default.post(
                        name: NSNotification.Name("MonthlyAssetUpdated"),
                        object: nil,
                        userInfo: ["clientID": clientKey]
                    )
                    print("✅ 已發送月度資產更新通知")
                }
            } catch {
                print("❌ 儲存失敗: \(error)")
            }
        }
    }

}

// MARK: - View Modifiers for Breaking Up Compiler Complexity

struct CommonSheetsModifier: ViewModifier {
    @Binding var showingAddMonthlyData: Bool
    @Binding var editingClient: Client?
    @Binding var showingReminder: Bool
    @Binding var showingSubscription: Bool
    let selectedClient: Client?
    let addMonthlyData: ([String], Date) -> Void
    let subscriptionManager: SubscriptionManager
    let viewContext: NSManagedObjectContext

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingAddMonthlyData) {
                AddMonthlyDataView(onSave: { newData, selectedDate in
                    addMonthlyData(newData, selectedDate)
                }, client: selectedClient)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $editingClient) { client in
                EditClientView(client: client)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingReminder) {
                ReminderDashboardView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
                    .environmentObject(subscriptionManager)
            }
    }
}

struct FloatingMenuSheetsModifier: ViewModifier {
    @Binding var showingCrossClientStructured: Bool
    @Binding var showingCrossClientUSStock: Bool
    @Binding var showingCrossClientTWStock: Bool
    @Binding var showingCrossClientCorporateBond: Bool
    @Binding var showingBatchAddStructured: Bool
    @Binding var showingBatchAddUSStock: Bool
    @Binding var showingBatchAddTWStock: Bool
    @Binding var showingBatchAddCorporateBond: Bool
    let selectedClient: Client?
    let addMonthlyData: ([String], Date) -> Void
    let viewContext: NSManagedObjectContext

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingCrossClientStructured) {
                CrossClientStructuredProductView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingCrossClientUSStock) {
                CrossClientUSStockView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingCrossClientTWStock) {
                CrossClientTWStockView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingCrossClientCorporateBond) {
                CrossClientCorporateBondView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingBatchAddStructured) {
                BatchAddStructuredProductView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingBatchAddUSStock) {
                BatchAddStockView(stockType: "us")
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingBatchAddTWStock) {
                BatchAddStockView(stockType: "tw")
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingBatchAddCorporateBond) {
                BatchAddCorporateBondView()
                    .environment(\.managedObjectContext, viewContext)
            }
    }
}

struct BackupSheetsModifier: ViewModifier {
    @Binding var showingBackupAlert: Bool
    @Binding var showingRestoreAlert: Bool
    @Binding var showingRestoreConfirm: Bool
    @Binding var backupAlertMessage: String
    @ObservedObject var backupManager: BackupManager
    let performRestore: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("備份結果", isPresented: $showingBackupAlert) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(backupAlertMessage)
            }
            .alert("還原結果", isPresented: $showingRestoreAlert) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(backupAlertMessage)
            }
            .confirmationDialog("確認還原", isPresented: $showingRestoreConfirm, titleVisibility: .visible) {
                Button("還原資料", role: .destructive) {
                    performRestore()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("還原將會新增備份中的資料，建議先確認現有資料已備份。確定要繼續嗎？")
            }
            .sheet(isPresented: $backupManager.showShareSheet) {
                if let url = backupManager.backupFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $backupManager.showDocumentPicker) {
                DocumentPicker { url in
                    if let context = backupManager.pendingRestoreContext,
                       let completion = backupManager.restoreCompletion {
                        backupManager.restoreFromURL(url, context: context) { success, error in
                            if success {
                                backupAlertMessage = "還原成功！請重新選擇客戶查看資料"
                            } else {
                                backupAlertMessage = "還原失敗：\(error ?? "未知錯誤")"
                            }
                            showingRestoreAlert = true
                        }
                    }
                }
            }
    }
}

struct LifecycleModifier: ViewModifier {
    let clients: FetchedResults<Client>
    let selectedClient: Client?
    let showingClientPanel: Bool
    @Binding var showingOnboarding: Bool
    @Binding var showingSubscription: Bool
    @Binding var showingDashboardTutorial: Bool
    let onboardingManager: OnboardingManager
    let subscriptionManager: SubscriptionManager
    let dashboardTutorialManager: DashboardTutorialManager
    let updateClientsArray: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: clients.count) { _ in
                // 當客戶數量變化時更新數組
                if showingClientPanel {
                    updateClientsArray()
                }
            }
            .onChange(of: selectedClient) { newClient in
                // 當首次選擇客戶時，顯示儀表板功能導覽
                if newClient != nil && dashboardTutorialManager.shouldShowTutorial() {
                    // 延遲顯示，避免與其他動畫衝突
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingDashboardTutorial = true
                    }
                }
            }
            .onAppear {
                updateClientsArray()

                // 檢查是否需要顯示首次引導
                if onboardingManager.shouldShowOnboarding() {
                    showingOnboarding = true
                }

                // 檢查是否需要顯示訂閱提示（首次打開 App）
                // 延遲顯示，避免與 onboarding 衝突
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if subscriptionManager.shouldShowSubscriptionPrompt() {
                        showingSubscription = true
                    }
                }
            }
    }
}

// MARK: - Array Safe Subscript Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 客戶行按鈕組件
struct ClientRowButton: View {
    let client: Client
    @Binding var selectedClient: Client?
    @Binding var editingClient: Client?
    let resetTrigger: Bool
    let onClientSelected: () -> Void
    let onClientDelete: (Client) -> Void
    let onClientEdit: (Client) -> Void

    @State private var showingDeleteAlert = false
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        // 正常顯示模式 - 使用長按選單
        Button(action: {
                // 點擊選擇客戶
                selectedClient = client
                onClientSelected()
            }) {
                HStack(spacing: 12) {
                    // 客戶資訊
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(client.name ?? "未知客戶")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedClient == client {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                            }
                        }

                        if let email = client.email, !email.isEmpty {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let createdDate = client.createdDate {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(dateFormatter.string(from: createdDate))
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            selectedClient == client
                            ? Color.blue.opacity(0.08)
                            : Color(.systemGray6).opacity(0.5)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            selectedClient == client
                            ? Color.blue.opacity(0.3)
                            : Color.clear,
                            lineWidth: 1.5
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                // 編輯按鈕
                Button(action: {
                    onClientEdit(client)
                }) {
                    Label("編輯客戶", systemImage: "pencil")
                }

                // 刪除按鈕
                Button(role: .destructive, action: {
                    showingDeleteAlert = true
                }) {
                    Label("刪除客戶", systemImage: "trash")
                }
            }
            .alert("刪除客戶", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("刪除", role: .destructive) {
                    onClientDelete(client)
                }
            } message: {
                Text("確定要刪除客戶 '\(client.name ?? "未知客戶")' 嗎？這個操作無法撤銷。")
            }
    }

    private func updateClientName(_ newName: String) {
        withAnimation {
            client.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("客戶名稱已更新為: \(newName)")
            } catch {
                print("Update error: \(error)")
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - 編輯客戶行組件
struct EditingClientRow: View {
    let client: Client
    @Binding var editingClient: Client?
    let onSave: (String) -> Void

    @State private var editingName: String
    @FocusState private var isTextFieldFocused: Bool

    init(client: Client, editingClient: Binding<Client?>, onSave: @escaping (String) -> Void) {
        self.client = client
        self._editingClient = editingClient
        self.onSave = onSave
        self._editingName = State(initialValue: client.name ?? "")
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                TextField("客戶名稱", text: $editingName)
                    .font(.headline)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)

                if let email = client.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let createdDate = client.createdDate {
                    Text("創建於 \(createdDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 8) {
                // 保存按鈕
                Button(action: {
                    onSave(editingName)
                    editingClient = nil
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())

                // 取消按鈕
                Button(action: {
                    editingClient = nil
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange, lineWidth: 2)
        )
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - 拖拽客戶行組件
struct DragClientRow: View {
    let client: Client
    @Binding var selectedClient: Client?

    var body: some View {
        HStack {
            // 拖拽指示器
            VStack(spacing: 2) {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.orange)
                    .font(.system(size: 16, weight: .medium))
                Text("拖動")
                    .font(.system(size: 8))
                    .foregroundColor(.orange)
            }
            .padding(.trailing, 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(client.name ?? "未知客戶")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    if selectedClient == client {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }

                if let email = client.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let createdDate = client.createdDate {
                    Text("創建於 \(createdDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedClient == client ? Color.blue.opacity(0.1) : Color.orange.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selectedClient == client ? Color.blue : Color.orange.opacity(0.5), lineWidth: selectedClient == client ? 2 : 1)
        )
        .onTapGesture {
            selectedClient = client
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - 分享表單
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 文件選擇器
struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                onPick(url)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(SubscriptionManager.shared)
}
