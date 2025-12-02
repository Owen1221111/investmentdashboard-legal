# InvestmentDashboard - iCloud 客戶管理系統

## 專案概述

這是一個具有 iCloud 同步功能的 iOS 客戶管理系統，支援跨設備資料同步，使用 SwiftUI + Core Data + CloudKit 實作。

## 功能特色

- 📱 **跨平台支援**：iPhone 和 iPad 響應式設計
- ☁️ **iCloud 同步**：客戶資料自動在不同設備間同步
- 🔄 **即時更新**：新增、編輯、刪除操作立即推送到雲端
- 📋 **側邊欄設計**：iPad 使用分割視圖，iPhone 使用導航推送

## 技術架構

### 核心技術棧
- **SwiftUI**：使用者介面框架
- **Core Data**：本地資料持久化
- **CloudKit**：雲端資料同步
- **NSPersistentCloudKitContainer**：Core Data 與 CloudKit 整合

### 專案結構

```
InvestmentDashboard/
├── InvestmentDashboardApp.swift    # App 主入口，設定 Core Data 環境
├── ContentView.swift               # 主視圖，使用 NavigationSplitView
├── PersistenceController.swift     # Core Data + CloudKit 控制器
├── SidebarView.swift              # 客戶列表側邊欄
├── ClientDetailView.swift         # 客戶詳情顯示頁面
├── AddClientView.swift            # 新增客戶表單
├── EditClientView.swift           # 編輯客戶表單
├── DataModel.xcdatamodeld/        # Core Data 資料模型
└── Assets.xcassets/               # 應用程式資源
```

## Core Data 資料模型

### Client 實體

```xml
<entity name="Client" representedClassName="Client" syncable="YES" codeGenerationType="class">
    <attribute name="name" attributeType="String" defaultValueString=""/>
    <attribute name="email" optional="YES" attributeType="String"/>
    <attribute name="birthDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    <attribute name="createdDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    <attribute name="recordName" optional="YES" attributeType="String"/>
    <relationship name="monthlyAssets" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="MonthlyAsset" inverseName="client" inverseEntity="MonthlyAsset"/>
    <relationship name="corporateBonds" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="CorporateBond" inverseName="client" inverseEntity="CorporateBond"/>
</entity>
```

**欄位說明：**
- `name`: 客戶姓名（必填）
- `email`: 電子郵件（選填）
- `birthDate`: 出生年月日（選填，用於計算保險年齡）
- `createdDate`: 建立日期（自動生成）
- `recordName`: CloudKit 記錄名稱（自動生成 UUID）
- `monthlyAssets`: 與 MonthlyAsset 的一對多關聯（級聯刪除）
- `corporateBonds`: 與 CorporateBond 的一對多關聯（級聯刪除）

### MonthlyAsset 實體（月度資產明細）

```xml
<entity name="MonthlyAsset" representedClassName="MonthlyAsset" syncable="YES" codeGenerationType="class">
    <attribute name="date" attributeType="String" defaultValueString=""/>
    <attribute name="cash" attributeType="String" defaultValueString=""/>
    <attribute name="usStock" attributeType="String" defaultValueString=""/>
    <attribute name="regularInvestment" attributeType="String" defaultValueString=""/>
    <attribute name="bonds" attributeType="String" defaultValueString=""/>
    <attribute name="confirmedInterest" attributeType="String" defaultValueString=""/>
    <attribute name="structured" attributeType="String" defaultValueString=""/>
    <attribute name="taiwanStockFolded" attributeType="String" defaultValueString=""/>
    <attribute name="totalAssets" attributeType="String" defaultValueString=""/>
    <attribute name="deposit" attributeType="String" defaultValueString=""/>
    <attribute name="depositAccumulated" attributeType="String" defaultValueString=""/>
    <attribute name="usStockCost" attributeType="String" defaultValueString=""/>
    <attribute name="regularInvestmentCost" attributeType="String" defaultValueString=""/>
    <attribute name="bondsCost" attributeType="String" defaultValueString=""/>
    <attribute name="taiwanStockCost" attributeType="String" defaultValueString=""/>
    <attribute name="notes" attributeType="String" defaultValueString=""/>
    <attribute name="createdDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    <relationship name="client" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Client" inverseName="monthlyAssets" inverseEntity="Client"/>
</entity>
```

**欄位說明：**
- `date`: 記錄日期
- `cash`: 現金金額
- `usStock`: 美股金額
- `regularInvestment`: 定期定額
- `bonds`: 債券金額
- `confirmedInterest`: 已確認利息
- `structured`: 結構型商品
- `taiwanStockFolded`: 台股折合美金
- `totalAssets`: 總資產
- `deposit`: 匯入金額
- `depositAccumulated`: 匯入累積
- `usStockCost`: 美股成本
- `regularInvestmentCost`: 定期定額成本
- `bondsCost`: 債券成本
- `taiwanStockCost`: 台股成本
- `notes`: 備註
- `createdDate`: 建立日期
- `client`: 關聯的客戶

### CorporateBond 實體（公司債）

```xml
<entity name="CorporateBond" representedClassName="CorporateBond" syncable="YES" codeGenerationType="class">
    <attribute name="subscriptionDate" attributeType="String" defaultValueString=""/>
    <attribute name="bondName" attributeType="String" defaultValueString=""/>
    <attribute name="couponRate" attributeType="String" defaultValueString=""/>
    <attribute name="yieldRate" attributeType="String" defaultValueString=""/>
    <attribute name="subscriptionPrice" attributeType="String" defaultValueString=""/>
    <attribute name="subscriptionAmount" attributeType="String" defaultValueString=""/>
    <attribute name="holdingFaceValue" attributeType="String" defaultValueString=""/>
    <attribute name="transactionAmount" attributeType="String" defaultValueString=""/>
    <attribute name="currentValue" attributeType="String" defaultValueString=""/>
    <attribute name="receivedInterest" attributeType="String" defaultValueString=""/>
    <attribute name="profitLossWithInterest" attributeType="String" defaultValueString=""/>
    <attribute name="returnRate" attributeType="String" defaultValueString=""/>
    <attribute name="dividendMonths" attributeType="String" defaultValueString=""/>
    <attribute name="singleDividend" attributeType="String" defaultValueString=""/>
    <attribute name="annualDividend" attributeType="String" defaultValueString=""/>
    <attribute name="createdDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    <relationship name="client" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Client" inverseName="corporateBonds" inverseEntity="Client"/>
</entity>
```

**欄位說明：**
- `subscriptionDate`: 申購日期
- `bondName`: 債券名稱
- `couponRate`: 票面利率
- `yieldRate`: 殖利率
- `subscriptionPrice`: 申購價格
- `subscriptionAmount`: 申購金額
- `holdingFaceValue`: 持有面額
- `transactionAmount`: 交易金額
- `currentValue`: 現值
- `receivedInterest`: 已領利息
- `profitLossWithInterest`: 含息損益
- `returnRate`: 報酬率
- `dividendMonths`: 配息月份
- `singleDividend`: 單次配息
- `annualDividend`: 年度配息
- `createdDate`: 建立日期
- `client`: 關聯的客戶

## CloudKit Database Schema

### Record Types 命名規則

Core Data 與 CloudKit 整合時，CloudKit 會自動為每個 Entity 建立對應的 Record Type，並加上 `CD_` 前綴：

| Core Data Entity | CloudKit Record Type |
|-----------------|---------------------|
| `Client` | `CD_Client` |
| `MonthlyAsset` | `CD_MonthlyAsset` |
| `CorporateBond` | `CD_CorporateBond` |
| `USStock` | `CD_USStock` |

### CloudKit 索引設定

須在 [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard) 中為以下 Record Types 設定索引：

#### CD_Client 索引
```
索引 1:
- Field: createdDate
- Type: SORTABLE
- Order: DESCENDING

索引 2:
- Field: name
- Type: QUERYABLE
```

#### CD_MonthlyAsset 索引
```
索引 1:
- Field: createdDate
- Type: SORTABLE
- Order: DESCENDING

索引 2:
- Field: CD_client
- Type: QUERYABLE
```

#### CD_CorporateBond 索引
```
索引 1:
- Field: createdDate
- Type: SORTABLE
- Order: DESCENDING

索引 2:
- Field: CD_client
- Type: QUERYABLE
```

#### CD_USStock 索引
```
索引 1:
- Field: createdDate
- Type: SORTABLE
- Order: DESCENDING

索引 2:
- Field: CD_client
- Type: QUERYABLE
```

### 索引類型說明

| 索引類型 | 用途 | 對應程式碼 |
|---------|------|-----------|
| **QUERYABLE** | 需要查詢或篩選的欄位 | `NSPredicate(format: "client == %@", client)` |
| **SORTABLE** | 需要排序的欄位 | `NSSortDescriptor(keyPath: \Entity.createdDate, ascending: false)` |

### 設定步驟

1. **前往 CloudKit Dashboard**
   - 網址：https://icloud.developer.apple.com/dashboard
   - 使用 Apple Developer 帳號登入
   - 選擇你的 App

2. **選擇環境**
   - 開始時選擇 **Development** 環境進行測試
   - 測試完成後部署到 **Production** 環境

3. **設定索引**
   - 點擊左側選單的 **"Indexes"**
   - 選擇要設定的 Record Type
   - 點擊 **"Add Index"** 新增索引
   - 設定欄位名稱、索引類型、排序方式
   - 點擊 **"Save Changes"** 儲存

4. **等待索引生效**
   - CloudKit 需要 5-10 分鐘更新索引
   - 可在 **"Data"** 標籤測試查詢功能

### 注意事項

⚠️ **索引是必須的** - 沒有索引，查詢和排序功能將無法正常運作
⚠️ **Development vs Production** - 兩個環境的索引設定是獨立的，需要分別設定
⚠️ **部署後無法撤銷** - 部署到 Production 後無法撤銷，請謹慎操作

詳細設定指南請參考：`CloudKit_Index_Setup_Guide.md`

## 實作步驟指南

### 1. 專案設定

#### 建立新專案
```bash
# 在 Xcode 中建立新的 iOS App 專案
# 選擇 SwiftUI 和 Core Data
```

#### 設定 Bundle ID
```
com.yourcompany.YourAppName
```

### 2. 添加 iCloud Capability

1. 選擇專案 → Target → **Signing & Capabilities**
2. 點擊 **"+ Capability"**
3. 搜索並添加 **"iCloud"**
4. 勾選 **"CloudKit"**
5. 系統會自動建立 CloudKit Container

### 3. Core Data 模型設定

建立 `DataModel.xcdatamodeld` 檔案，內容如上述 XML 結構。

重要設定：
- `usedWithCloudKit="YES"`
- Entity 名稱必須與 CloudKit 記錄類型一致
- 適當的屬性設定（必填/選填）

### 4. PersistenceController 實作

```swift
import CoreData
import CloudKit

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    lazy var container: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "DataModel")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        // 基本的 CloudKit 設定
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \\(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }()

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
                print("資料已儲存到 iCloud")
            } catch {
                print("Save error: \\(error)")
            }
        }
    }

    func checkCloudKitStatus() {
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    print("iCloud 可用")
                case .noAccount:
                    print("未登錄 iCloud")
                case .restricted:
                    print("iCloud 受限")
                case .couldNotDetermine:
                    print("無法確定 iCloud 狀態")
                @unknown default:
                    print("未知的 iCloud 狀態")
                }
            }
        }
    }
}
```

### 5. App 主入口設定

```swift
import SwiftUI

@main
struct YourApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
```

### 6. 主要 UI 組件

#### NavigationSplitView 結構

```swift
struct ContentView: View {
    @State private var selectedClient: Client?
    @State private var showingAddClient = false

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedClient: $selectedClient,
                showingAddClient: $showingAddClient
            )
        } detail: {
            ClientDetailView(client: selectedClient)
        }
        .sheet(isPresented: $showingAddClient) {
            AddClientView()
        }
    }
}
```

#### FetchRequest 使用

```swift
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \\Client.name, ascending: true)],
    animation: .default)
private var clients: FetchedResults<Client>
```

### 7. CRUD 操作實作

#### 新增客戶

```swift
private func saveClient() {
    withAnimation {
        let newClient = Client(context: viewContext)
        newClient.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        newClient.email = email.isEmpty ? nil : email
        newClient.createdDate = Date()
        newClient.recordName = UUID().uuidString

        do {
            try viewContext.save()
            PersistenceController.shared.save()
        } catch {
            print("Save error: \\(error)")
        }
    }
}
```

#### 新增月度資產

```swift
private func addMonthlyData(_ newData: [String]) {
    guard let currentClient = selectedClient else {
        print("❌ 沒有選中客戶，無法儲存資料")
        return
    }

    withAnimation {
        let newAsset = MonthlyAsset(context: viewContext)
        newAsset.client = currentClient
        newAsset.date = newData[safe: 0] ?? ""
        newAsset.cash = newData[safe: 1] ?? ""
        newAsset.usStock = newData[safe: 2] ?? ""
        newAsset.regularInvestment = newData[safe: 3] ?? ""
        newAsset.bonds = newData[safe: 4] ?? ""
        newAsset.confirmedInterest = newData[safe: 5] ?? ""
        newAsset.structured = newData[safe: 6] ?? ""
        newAsset.taiwanStockFolded = newData[safe: 7] ?? ""
        newAsset.totalAssets = newData[safe: 8] ?? ""
        newAsset.deposit = newData[safe: 9] ?? ""
        newAsset.depositAccumulated = newData[safe: 10] ?? ""
        newAsset.usStockCost = newData[safe: 11] ?? ""
        newAsset.regularInvestmentCost = newData[safe: 12] ?? ""
        newAsset.bondsCost = newData[safe: 13] ?? ""
        newAsset.taiwanStockCost = newData[safe: 14] ?? ""
        newAsset.notes = newData[safe: 15] ?? ""
        newAsset.createdDate = Date()

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 月度資產已儲存並同步到 iCloud")
        } catch {
            print("❌ 儲存失敗: \\(error)")
        }
    }
}
```

#### 新增公司債

```swift
private func addCorporateBond() {
    guard let client = client else {
        print("❌ 無法新增資料：沒有選中的客戶")
        return
    }

    withAnimation {
        let newBond = CorporateBond(context: viewContext)
        newBond.client = client
        newBond.subscriptionDate = ""
        newBond.bondName = ""
        newBond.couponRate = ""
        newBond.yieldRate = ""
        newBond.subscriptionPrice = ""
        newBond.subscriptionAmount = ""
        newBond.holdingFaceValue = ""
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
            print("✅ 新增公司債並同步到 iCloud")
        } catch {
            print("❌ 新增失敗: \\(error)")
        }
    }
}
```

#### 編輯客戶

**EditClientView** 提供完整的客戶資料編輯功能，包括基本資訊和出生年月日設定。

**主要功能：**
- 編輯客戶姓名（必填）
- 編輯電子郵件（選填）
- 設定出生年月日（選填，用於計算保險年齡）

**UI 設計：**
- 使用 `Form` + `NavigationView` 標準表單設計
- 分為兩個 Section：
  1. 「基本信息」：姓名、電子郵件
  2. 「出生年月日」：Toggle 開關 + 圖形化日曆選擇器
- DatePicker 使用 `.graphical` 樣式，提供月曆視圖
- 支援繁體中文介面（`zh_TW`）

**實作程式碼：**

```swift
struct EditClientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client

    @State private var name: String
    @State private var email: String
    @State private var birthDate: Date
    @State private var hasBirthDate: Bool

    init(client: Client) {
        self.client = client
        self._name = State(initialValue: client.name ?? "")
        self._email = State(initialValue: client.email ?? "")
        self._birthDate = State(initialValue: client.birthDate ?? Date())
        self._hasBirthDate = State(initialValue: client.birthDate != nil)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("客戶姓名", text: $name)
                    TextField("電子郵件", text: $email)
                        .keyboardType(.emailAddress)
                }

                Section("出生年月日") {
                    Toggle("已設定出生年月日", isOn: $hasBirthDate)

                    if hasBirthDate {
                        DatePicker(
                            "出生日期",
                            selection: $birthDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale(identifier: "zh_TW"))
                    }
                }
            }
            .navigationTitle("編輯客戶")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        updateClient()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func updateClient() {
        withAnimation {
            client.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            client.email = email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
            client.birthDate = hasBirthDate ? birthDate : nil

            do {
                try viewContext.save()
                PersistenceController.shared.save()
                print("客戶資料已更新到 iCloud")
                dismiss()
            } catch {
                print("Update error: \(error)")
            }
        }
    }
}
```

**使用方式：**
1. 在客戶列表長按客戶名字
2. 選擇「編輯客戶」
3. 修改姓名或電子郵件
4. 開啟「已設定出生年月日」Toggle
5. 使用圖形化日曆選擇出生日期
6. 點選「保存」儲存變更並同步到 iCloud

**資料驗證：**
- 客戶姓名不可為空（保存按鈕會被禁用）
- 電子郵件為選填，空白時儲存為 `nil`
- 出生日期為選填，Toggle 關閉時儲存為 `nil`

#### 刪除客戶（級聯刪除關聯資料）

```swift
private func deleteClients(offsets: IndexSet) {
    withAnimation {
        offsets.map { clients[$0] }.forEach(viewContext.delete)

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("客戶及其所有月度資產、公司債已從 iCloud 刪除")
        } catch {
            print("Delete error: \\(error)")
        }
    }
}
```

### 8. 使用 FetchRequest 載入關聯資料

#### 載入特定客戶的月度資產

```swift
struct MonthlyAssetDetailView: View {
    @Environment(\\.managedObjectContext) private var viewContext
    let client: Client?

    @FetchRequest private var monthlyAssets: FetchedResults<MonthlyAsset>

    init(client: Client?) {
        self.client = client

        if let client = client {
            _monthlyAssets = FetchRequest<MonthlyAsset>(
                sortDescriptors: [NSSortDescriptor(keyPath: \\MonthlyAsset.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client),
                animation: .default
            )
        } else {
            _monthlyAssets = FetchRequest<MonthlyAsset>(
                sortDescriptors: [NSSortDescriptor(keyPath: \\MonthlyAsset.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }

    var body: some View {
        List {
            ForEach(monthlyAssets) { asset in
                Text("\\(asset.date ?? "") - \\(asset.totalAssets ?? "")")
            }
        }
    }
}
```

#### 載入特定客戶的公司債

```swift
struct CorporateBondsDetailView: View {
    @Environment(\\.managedObjectContext) private var viewContext
    let client: Client?

    @FetchRequest private var corporateBonds: FetchedResults<CorporateBond>

    init(client: Client?) {
        self.client = client

        if let client = client {
            _corporateBonds = FetchRequest<CorporateBond>(
                sortDescriptors: [NSSortDescriptor(keyPath: \\CorporateBond.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client),
                animation: .default
            )
        } else {
            _corporateBonds = FetchRequest<CorporateBond>(
                sortDescriptors: [NSSortDescriptor(keyPath: \\CorporateBond.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }

    var body: some View {
        List {
            ForEach(corporateBonds) { bond in
                Text("\\(bond.bondName ?? "") - \\(bond.returnRate ?? "")")
            }
        }
    }
}
```

### 9. 數據連動與即時計算

#### 卡片資料自動連動到月度資產明細

所有統計卡片的數字都會自動從 Core Data 的 MonthlyAsset 最新一筆資料讀取：

```swift
struct ClientDetailView: View {
    @Environment(\\.managedObjectContext) private var viewContext
    let client: Client?

    // FetchRequest 取得當前客戶的月度資產（按日期降序）
    @FetchRequest private var monthlyAssets: FetchedResults<MonthlyAsset>

    init(client: Client?) {
        self.client = client

        if let client = client {
            _monthlyAssets = FetchRequest<MonthlyAsset>(
                sortDescriptors: [NSSortDescriptor(keyPath: \\MonthlyAsset.createdDate, ascending: false)],
                predicate: NSPredicate(format: "client == %@", client),
                animation: .default
            )
        } else {
            _monthlyAssets = FetchRequest<MonthlyAsset>(
                sortDescriptors: [NSSortDescriptor(keyPath: \\MonthlyAsset.createdDate, ascending: false)],
                predicate: NSPredicate(value: false),
                animation: .default
            )
        }
    }
}
```

#### 總資產讀取

```swift
private func getTotalAssets() -> Double {
    // 從最新一筆月度資產讀取總資產
    guard let latestAsset = monthlyAssets.first,
          let totalAssetsStr = latestAsset.totalAssets,
          let totalAssets = Double(totalAssetsStr) else {
        return 0.0
    }
    return totalAssets
}
```

#### 總損益自動計算

```swift
private func getTotalPnL() -> Double {
    // 總損益 = 總資產 - 匯入累積
    guard let latestAsset = monthlyAssets.first,
          let totalAssetsStr = latestAsset.totalAssets,
          let depositAccStr = latestAsset.depositAccumulated,
          let totalAssets = Double(totalAssetsStr),
          let depositAcc = Double(depositAccStr) else {
        return 0.0
    }
    return totalAssets - depositAcc
}
```

#### 總額報酬率自動計算

```swift
private func getTotalReturnRate() -> Double {
    // 總額報酬率 = (總資產 - 匯入累積) / 匯入累積 * 100
    guard let latestAsset = monthlyAssets.first,
          let totalAssetsStr = latestAsset.totalAssets,
          let depositAccStr latestAsset.depositAccumulated,
          let totalAssets = Double(totalAssetsStr),
          let depositAcc = Double(depositAccStr),
          depositAcc > 0 else {
        return 0.0
    }
    return ((totalAssets - depositAcc) / depositAcc) * 100
}
```

#### 現金讀取

```swift
private func getCash() -> Double {
    // 從最新一筆月度資產讀取現金
    guard let latestAsset = monthlyAssets.first,
          let cashStr = latestAsset.cash,
          let cash = Double(cashStr) else {
        return 0.0
    }
    return cash
}
```

#### 匯入累積讀取

```swift
private func getTotalDeposit() -> Double {
    // 從最新一筆月度資產讀取匯入累積
    guard let latestAsset = monthlyAssets.first,
          let depositAccStr = latestAsset.depositAccumulated,
          let depositAcc = Double(depositAccStr) else {
        return 0.0
    }
    return depositAcc
}
```

#### 資料流程圖

```
用戶操作: 按下「+」新增月度資料
    ↓
儲存到 Core Data MonthlyAsset 實體
    ↓
自動同步到 iCloud（透過 NSPersistentCloudKitContainer）
    ↓
@FetchRequest 自動偵測變化並載入最新資料
    ↓
卡片數字即時更新（透過 SwiftUI 響應式機制）
```

#### 連動的卡片與欄位對應

| 卡片/欄位 | 資料來源 | 計算方式 |
|---------|---------|---------|
| 總資產 | `MonthlyAsset.totalAssets` | 直接讀取 |
| 總損益金額 | `MonthlyAsset.totalAssets` - `MonthlyAsset.depositAccumulated` | 自動計算 |
| 總損益率 | `(總資產 - 匯入累積) / 匯入累積 × 100%` | 自動計算 |
| 總匯入 | `MonthlyAsset.depositAccumulated` | 直接讀取 |
| 現金 | `MonthlyAsset.cash` | 直接讀取 |
| 總額報酬率 | `(總資產 - 匯入累積) / 匯入累積 × 100%` | 自動計算 |
| 本月收益 | `MonthlyAsset.confirmedInterest` | 直接讀取 |

#### 使用範例

在 UI 中使用這些函數：

```swift
// 總資產大卡片
Text(formatCurrency(getTotalAssets()))
    .font(.system(size: 44, weight: .bold))

// 總損益顯示
Text("總損益: \\(formatPnL(getTotalPnL()))")
    .foregroundColor(getTotalPnL() >= 0 ? .green : .red)

// 統計小卡片
statsCard(title: "總匯入", value: formatCurrency(getTotalDeposit()))
statsCard(title: "總額報酬率", value: formatReturnRate(getTotalReturnRate()))
statsCard(title: "現金", value: formatCurrency(getCash()))
statsCard(title: "本月收益", value: formatCurrency(getMonthlyIncome()))
```

**防止數字換行的實作**：

所有顯示金額的卡片都添加了自動縮放功能，避免百萬級數字換行：

**1. statsCard 函數**（2x2 統計小卡片）：
```swift
private func statsCard(title: String, value: String, isHighlight: Bool) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isHighlight ? .white : Color(.secondaryLabel))

        Text(value)
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(isHighlight ? .white : Color(.label))
            .minimumScaleFactor(0.4)  // 允許縮小到40%
            .lineLimit(1)              // 限制單行顯示
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(...)
}
```

**2. totalDepositMiniCard**（總匯入小卡片）：
```swift
private var totalDepositMiniCard: some View {
    VStack(alignment: .leading, spacing: 4) {
        Text("總匯入")
            .font(.system(size: 15, weight: .medium))

        Text(formatCurrency(getTotalDeposit()))
            .font(.system(size: 16, weight: .bold))
            .minimumScaleFactor(0.3)  // 億級數字用
            .lineLimit(1)
    }
}
```

**3. 總匯入**（iPad 版 miniStatsCardGroup）：
```swift
Text(formatCurrency(getTotalDeposit()))
    .font(.system(size: 24, weight: .bold))
    .minimumScaleFactor(0.3)  // 億級數字用
    .lineLimit(1)
```

**4. 現金卡片**（整合卡片中）：
```swift
Text(formatCurrency(getCash()))
    .font(.system(size: 18, weight: .bold))
    .minimumScaleFactor(0.4)  // 百萬級數字用
    .lineLimit(1)
```

**5. 現金卡片**（iPad 版 miniStatsCardGroup）：
```swift
Text(formatCurrency(getCash()))
    .font(.system(size: 24, weight: .bold))
    .minimumScaleFactor(0.4)  // 百萬級數字用
    .lineLimit(1)
```

**6. 總資產大數字**（iPhone）：
```swift
Text(formatCurrency(getTotalAssets()))
    .font(.system(size: 36, weight: .bold))
    .minimumScaleFactor(0.3)  // 億級數字用
    .lineLimit(1)
```

**7. 總資產大數字**（iPad）：
```swift
Text(formatCurrency(getTotalAssets()))
    .font(.system(size: 44, weight: .bold))
    .minimumScaleFactor(0.3)  // 億級數字用
    .lineLimit(1)
```

**自動縮放參數說明**：
- `.minimumScaleFactor(0.3)`：允許文字縮小至原尺寸的 30%（用於億級數字：總資產、總匯入）
- `.minimumScaleFactor(0.4)`：允許文字縮小至原尺寸的 40%（用於百萬級數字：現金、統計小卡片）
- `.lineLimit(1)`：強制限制為單行顯示
- 當數字超過可用寬度時，SwiftUI 會自動縮小字體而不換行

#### 特點與優勢

- ✅ **即時更新**：新增或編輯月度資產後，所有卡片數字立即更新
- ✅ **自動計算**：總損益和報酬率自動計算，無需手動維護
- ✅ **客戶隔離**：每個客戶只顯示自己的資料，透過 NSPredicate 篩選
- ✅ **雲端同步**：所有數據透過 iCloud 自動同步到所有設備
- ✅ **資料一致性**：所有顯示的數字都來自同一資料來源，確保一致性
- ✅ **無需刷新**：SwiftUI 的 @FetchRequest 自動監聽資料變化
- ✅ **自動縮放**：數字過長時自動縮小字體，避免換行保持美觀

### 10. 資產配置與投資卡片數據連動

#### 資產配置圓餅圖數據計算

所有資產配置比例都從月度資產明細最新一筆資料自動計算：

```swift
// 現金比例
private func getCashPercentage() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let cashStr = latestAsset.cash,
          let totalStr = latestAsset.totalAssets,
          let cash = Double(cashStr),
          let total = Double(totalStr),
          total > 0 else {
        return 0.0
    }
    return (cash / total) * 100
}

// 債券比例
private func getBondsPercentage() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let bondsStr = latestAsset.bonds,
          let totalStr = latestAsset.totalAssets,
          let bonds = Double(bondsStr),
          let total = Double(totalStr),
          total > 0 else {
        return 0.0
    }
    return (bonds / total) * 100
}

// 美股比例
private func getUSStockPercentage() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let usStockStr = latestAsset.usStock,
          let totalStr = latestAsset.totalAssets,
          let usStock = Double(usStockStr),
          let total = Double(totalStr),
          total > 0 else {
        return 0.0
    }
    return (usStock / total) * 100
}

// 台幣比例（新增）
private func getTWDPercentage() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let twdToUsdStr = latestAsset.twdToUsd,
          let totalStr = latestAsset.totalAssets,
          let twdToUsd = Double(twdToUsdStr),
          let total = Double(totalStr),
          total > 0 else {
        return 0.0
    }
    return (twdToUsd / total) * 100
}

// 台股比例
private func getTWStockPercentage() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let twStockStr = latestAsset.taiwanStockFolded,
          let totalStr = latestAsset.totalAssets,
          let twStock = Double(twStockStr),
          let total = Double(totalStr),
          total > 0 else {
        return 0.0
    }
    return (twStock / total) * 100
}

// 結構型商品比例
private func getStructuredPercentage() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let structuredStr = latestAsset.structured,
          let totalStr = latestAsset.totalAssets,
          let structured = Double(structuredStr),
          let total = Double(totalStr),
          total > 0 else {
        return 0.0
    }
    return (structured / total) * 100
}
```

#### 投資卡片金額與報酬率計算

**美股卡片**：

```swift
// 美股金額（純美股，不包含定期定額）
private func getUSStockValue() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let usStockStr = latestAsset.usStock,
          let usStock = Double(usStockStr) else {
        return 0.0
    }
    return usStock
}

// 美股報酬率 = (美股 - 美股成本) / 美股成本 * 100
private func getUSStockReturnRate() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let usStockStr = latestAsset.usStock,
          let usStockCostStr = latestAsset.usStockCost,
          let usStock = Double(usStockStr),
          let usStockCost = Double(usStockCostStr),
          usStockCost > 0 else {
        return 0.0
    }
    return ((usStock - usStockCost) / usStockCost) * 100
}
```

**台股卡片**：

```swift
// 台股金額（使用台股原始數值，非台股折合）
private func getTWStockValue() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let twStockStr = latestAsset.taiwanStock,
          let twStock = Double(twStockStr) else {
        return 0.0
    }
    return twStock
}

// 台股報酬率 = (台股 - 台股成本) / 台股成本 * 100
private func getTWStockReturnRate() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let twStockStr = latestAsset.taiwanStock,
          let twStockCostStr = latestAsset.taiwanStockCost,
          let twStock = Double(twStockStr),
          let twStockCost = Double(twStockCostStr),
          twStockCost > 0 else {
        return 0.0
    }
    return ((twStock - twStockCost) / twStockCost) * 100
}
```

**定期定額卡片**：

```swift
// 定期定額金額
private func getRegularInvestmentValue() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let regularStr = latestAsset.regularInvestment,
          let regular = Double(regularStr) else {
        return 0.0
    }
    return regular
}

// 定期定額報酬率 = (定期定額 - 定期定額成本) / 定期定額成本 * 100
private func getRegularInvestmentReturnRate() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let regularStr = latestAsset.regularInvestment,
          let regularCostStr = latestAsset.regularInvestmentCost,
          let regular = Double(regularStr),
          let regularCost = Double(regularCostStr),
          regularCost > 0 else {
        return 0.0
    }
    return ((regular - regularCost) / regularCost) * 100
}
```

**債券卡片**：

```swift
// 債券金額
private func getBondsValue() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let bondsStr = latestAsset.bonds,
          let bonds = Double(bondsStr) else {
        return 0.0
    }
    return bonds
}

// 債券報酬率 = (債券 + 已領利息 - 債券成本) / 債券成本 * 100
private func getBondsReturnRate() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let bondsStr = latestAsset.bonds,
          let bondsCostStr = latestAsset.bondsCost,
          let confirmedInterestStr = latestAsset.confirmedInterest,
          let bonds = Double(bondsStr),
          let bondsCost = Double(bondsCostStr),
          let confirmedInterest = Double(confirmedInterestStr),
          bondsCost > 0 else {
        return 0.0
    }
    return ((bonds + confirmedInterest - bondsCost) / bondsCost) * 100
}
```

#### 欄位對應關係表

| 卡片/圖表 | 資料來源 | 計算方式 |
|---------|---------|---------|
| **資產配置圓餅圖** | | |
| 現金比例 | `MonthlyAsset.cash / totalAssets * 100` | 自動計算 |
| 債券比例 | `MonthlyAsset.bonds / totalAssets * 100` | 自動計算 |
| 美股比例 | `MonthlyAsset.usStock / totalAssets * 100` | 自動計算 |
| 台幣比例 | `MonthlyAsset.twdToUsd / totalAssets * 100` | 自動計算（新增）|
| 台股比例 | `MonthlyAsset.taiwanStockFolded / totalAssets * 100` | 自動計算 |
| 結構型比例 | `MonthlyAsset.structured / totalAssets * 100` | 自動計算 |
| **美股卡片** | | |
| 美股金額 | `MonthlyAsset.usStock` | 直接讀取 |
| 美股報酬率 | `(usStock - usStockCost) / usStockCost * 100` | 自動計算 |
| **台股卡片** | | |
| 台股金額 | `MonthlyAsset.taiwanStock` | 直接讀取（已修正）|
| 台股報酬率 | `(taiwanStock - taiwanStockCost) / taiwanStockCost * 100` | 自動計算 |
| **定期定額卡片** | | |
| 定期定額金額 | `MonthlyAsset.regularInvestment` | 直接讀取 |
| 定期定額報酬率 | `(regular - regularCost) / regularCost * 100` | 自動計算 |
| **債券卡片** | | |
| 債券金額 | `MonthlyAsset.bonds` | 直接讀取 |
| 債券報酬率 | `(bonds + confirmedInterest - bondsCost) / bondsCost * 100` | 自動計算（已修正）|

#### 投資走勢圖數據函數

所有投資卡片的走勢圖都使用 `createdDate` 作為排序依據，確保數據按照實際創建時間順序顯示：

```swift
// 美股走勢數據
private func getUSStockTrendData() -> [Double] {
    return monthlyAssets
        .sorted { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }
        .compactMap { asset -> Double? in
            guard let valueStr = asset.usStock else { return nil }
            return Double(valueStr)
        }
}

// 台股走勢數據
private func getTWStockTrendData() -> [Double] {
    return monthlyAssets
        .sorted { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }
        .compactMap { asset -> Double? in
            guard let valueStr = asset.taiwanStockFolded else { return nil }
            return Double(valueStr)
        }
}

// 定期定額走勢數據
private func getRegularInvestmentTrendData() -> [Double] {
    return monthlyAssets
        .sorted { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }
        .compactMap { asset -> Double? in
            guard let valueStr = asset.regularInvestment else { return nil }
            return Double(valueStr)
        }
}

// 債券走勢數據
private func getBondsTrendData() -> [Double] {
    return monthlyAssets
        .sorted { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }
        .compactMap { asset -> Double? in
            guard let valueStr = asset.bonds else { return nil }
            return Double(valueStr)
        }
}
```

**重要說明**：
- ✅ 使用 `createdDate` 排序而非 `date` 字串，確保時間順序正確
- ✅ 走勢圖數據與月度資產明細的實際順序一致
- ✅ 避免因字串排序導致的時間順序錯誤

#### 投資卡片佈局設計

所有投資卡片（美股、台股、定期定額、債券）採用一致的 50/50 佈局：

```swift
// 美股卡片範例
HStack(spacing: 16) {
    // 左側：金額和報酬率（佔50%）
    VStack(alignment: .leading, spacing: 6) {
        Text(formatCurrency(getUSStockValue()))
            .font(.system(size: 21, weight: .bold))

        Text("報酬率: \(formatReturnRate(getUSStockReturnRate()))")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(getUSStockReturnRate() >= 0 ? Color.green : .red)
    }
    .frame(maxWidth: .infinity, alignment: .leading)

    // 右側：折線圖（佔50%）
    LineChartView(
        color: getUSStockReturnRate() >= 0 ? Color.green : .red,
        dataPoints: getUSStockTrendData()
    )
    .frame(maxWidth: .infinity)
}
```

**佈局特點**：
- ✅ 左側50%顯示金額和報酬率
- ✅ 右側50%顯示走勢圖
- ✅ 走勢圖不設固定尺寸，自動填滿可用空間
- ✅ 所有卡片統一佈局風格

#### 美股持倉明細功能

美股卡片支援點擊打開持倉明細視圖（`USStockInventoryView.swift`），提供完整的持倉管理功能。

**功能特點**：

1. **持倉列表顯示**
   - 顯示所有美股持倉（從 `USStock` 實體讀取）
   - 每個持倉顯示：股票代碼、股數、成本、市值、報酬率
   - 支援展開/收起查看詳細信息

2. **統計摘要**（頂部顯示）
   ```swift
   - 總市值：所有持股的市值總和
   - 總成本：所有持股的成本總和
   - 總損益：總市值 - 總成本
   - 總報酬率：(總損益 / 總成本) × 100
   ```

3. **持倉編輯**
   - 股票代碼：可編輯
   - 股數：可編輯，修改後自動重新計算
   - 成本單價：可編輯，修改後自動重新計算
   - 現價：唯讀（灰色背景），只能通過更新股價按鈕更新
   - 幣別：可編輯（預設 USD）
   - 備註：可編輯

4. **自動計算**
   ```swift
   市值 = 現價 × 股數
   成本 = 成本單價 × 股數
   損益 = 市值 - 成本
   報酬率 = (損益 / 成本) × 100
   ```

5. **功能按鈕**（右上角）
   - **月度**（藍色）：同步到月度資產
   - **股價**（綠色）：更新所有持股的股價
   - **⊕**：新增持股

**數據流向與同步機制**：

美股相關數據有兩個獨立的資料庫：

| 資料庫 | 用途 | 更新方式 |
|-------|------|---------|
| `USStock` 實體 | 持倉明細（實時數據） | 在持倉明細視圖中隨時編輯 |
| `MonthlyAsset.usStock` | 月度資產快照 | 通過「月度」按鈕同步 |

**同步到月度資產功能**：

點擊「月度」按鈕會執行以下操作：

1. 計算所有 `USStock` 的總市值和總成本
2. 找到最新的 `MonthlyAsset` 記錄（按 `createdDate` 降序）
3. 更新以下字段：
   - `usStock`：美股市值
   - `usStockCost`：美股成本
   - `totalAssets`：重新計算總資產

4. 總資產計算公式（**美金計價**）：
   ```swift
   總資產(USD) = 美金 + 美股 + 定期定額 + 債券 + 台股折合 + 台幣折合美金 + 結構型 + 基金 + 保險

   其中：
   - 台股折合(USD) = 台股(TWD) / 匯率
   - 台幣折合美金 = 台幣現金(TWD) / 匯率
   ```

**重要說明**：

- ⚠️ `totalAssets` 儲存的是**美金計價**的值，不是台幣
- ⚠️ `totalAssets` 是存儲字段（非計算屬性），用於保留歷史快照
- ⚠️ 同步時必須手動重新計算 `totalAssets`，否則總資產不會更新
- ℹ️ 在顯示時，如果選擇台幣，會將美金值乘以匯率轉換顯示（參考 `CustomerDetailView.swift:1746-1771`）
- ✅ 持倉明細的修改是實時的，月度資產的同步是手動觸發的
- ✅ 這種設計允許隨時更新持倉，但保留每月的資產快照

**更新股價功能**：

點擊「股價」按鈕會：
1. 顯示確認對話框：「將從網路獲取最新股價並更新持倉數據，是否繼續？」
2. 批量獲取所有股票的最新價格（使用 `StockPriceService`）
3. 更新每個持股的 `currentPrice` 字段
4. 自動重新計算市值、損益、報酬率
5. 顯示更新結果（成功/失敗的股票數量）

**UI 設計要點**：

```swift
// 統計數字佈局（防止 iPhone 換行）
HStack(spacing: 4) {
    VStack(alignment: .center, spacing: 4) {
        Text("總市值")
            .font(.caption2)
        Text(formatCurrency(getTotalMarketValue()))
            .font(.system(size: 16, weight: .bold))
            .minimumScaleFactor(0.7)  // 允許縮小到 70%
            .lineLimit(1)              // 強制單行
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 4)

    // 其他三個統計項目...
}
```

**按鈕設計**：

```swift
// 月度同步按鈕
Button(action: { showingSyncConfirmation = true }) {
    HStack(spacing: 4) {
        Image(systemName: "arrow.triangle.2.circlepath")
        Text("月度")
    }
    .foregroundColor(.blue)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Color.blue.opacity(0.1))
    .cornerRadius(8)
}

// 更新股價按鈕
Button(action: { showingRefreshConfirmation = true }) {
    HStack(spacing: 4) {
        Image(systemName: "arrow.clockwise")
        Text("股價")
    }
    .foregroundColor(.green)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Color.green.opacity(0.1))
    .cornerRadius(8)
}
```

#### 台股持倉明細功能

台股卡片支援點擊打開持倉明細視圖（`TWStockInventoryView.swift`），提供完整的持倉管理功能，與美股功能類似。

**功能特點**：

1. **持倉列表顯示**
   - 顯示所有台股持倉（從 `TWStock` 實體讀取）
   - 每個持倉顯示：股票代碼、股數、成本、市值、報酬率
   - 支援展開/收起查看詳細信息

2. **統計摘要**（頂部顯示）
   ```swift
   - 總市值：所有持股的市值總和（NT$）
   - 總成本：所有持股的成本總和（NT$）
   - 總損益：總市值 - 總成本
   - 總報酬率：(總損益 / 總成本) × 100
   ```

3. **持倉編輯**
   - 股票代碼：可編輯（例如：2330）
   - 股數：可編輯，修改後自動重新計算
   - 成本單價：可編輯，修改後自動重新計算
   - 現價：唯讀（灰色背景），只能通過更新股價按鈕更新
   - 幣別：預設 TWD
   - 備註：可編輯

4. **自動計算**
   ```swift
   市值 = 現價 × 股數
   成本 = 成本單價 × 股數
   損益 = 市值 - 成本
   報酬率 = (損益 / 成本) × 100
   ```

5. **功能按鈕**（右上角）
   - **月度**（藍色）：同步到月度資產
   - **股價**（綠色）：更新所有持股的股價（開發中）
   - **⊕**：新增持股

**數據流向與同步機制**：

台股相關數據有兩個獨立的資料庫：

| 資料庫 | 用途 | 更新方式 |
|-------|------|---------|
| `TWStock` 實體 | 持倉明細（實時數據） | 在持倉明細視圖中隨時編輯 |
| `MonthlyAsset.taiwanStock` | 月度資產快照 | 通過「月度」按鈕同步 |

**同步到月度資產功能**：

點擊「月度」按鈕會執行以下操作：

1. 計算所有 `TWStock` 的總市值和總成本
2. 找到最新的 `MonthlyAsset` 記錄（按 `createdDate` 降序）
3. 更新以下字段：
   - `taiwanStock`：台股市值（TWD）
   - `taiwanStockCost`：台股成本（TWD）
   - `taiwanStockFolded`：台股折合美金（市值 ÷ 匯率）
   - `totalAssets`：重新計算總資產

4. 總資產計算公式（**美金計價**）：
   ```swift
   總資產(USD) = 美金 + 美股 + 定期定額 + 債券 + 台股折合 + 台幣折合美金 + 結構型 + 基金 + 保險

   其中：
   - 台股折合(USD) = 台股(TWD) / 匯率
   - 台幣折合美金 = 台幣現金(TWD) / 匯率
   ```

**重要說明**：

- ⚠️ `totalAssets` 儲存的是**美金計價**的值，不是台幣
- ⚠️ `totalAssets` 是存儲字段（非計算屬性），用於保留歷史快照
- ⚠️ 同步時必須手動重新計算 `totalAssets`、`taiwanStockFolded`，否則總資產不會更新
- ⚠️ 台股更新股價功能目前開發中，暫時需要手動更新
- ✅ 持倉明細的修改是實時的，月度資產的同步是手動觸發的
- ✅ 這種設計允許隨時更新持倉，但保留每月的資產快照

**Core Data 結構**：

```swift
entity TWStock {
    comment: String          // 備註
    cost: String            // 總成本
    costPerShare: String    // 成本單價
    createdDate: Date       // 創建日期
    currency: String        // 幣別（預設 TWD）
    currentPrice: String    // 現價
    marketValue: String     // 市值
    name: String            // 股票代碼
    profitLoss: String      // 損益
    returnRate: String      // 報酬率
    shares: String          // 股數
    client: Client          // 所屬客戶
}
```

**與美股持倉的差異**：

| 特性 | 美股 (USStock) | 台股 (TWStock) |
|-----|---------------|---------------|
| 幣別 | USD | TWD |
| 市場欄位 | 有 (market) | 無 |
| 股價 API | 已實作 | 開發中 |
| 同步公式 | 直接加總 | 需除以匯率轉換為美金 |

#### 台股明細表格

主畫面中的台股明細表格（`TWStockDetailView.swift`）提供完整的台股資料管理功能，位於美股明細表格下方、損益表格上方。

**功能特點**：

1. **表格顯示**
   - 可展開/收起的表格視圖
   - 顯示所有台股記錄的詳細資訊
   - 欄位包括：日期、股票名稱、股數、成本、成本單價、現價、市值、損益、報酬率、幣別、評論

2. **表格功能**
   - **展開/收起**：點擊向下/向上箭頭圖示
   - **更新股價**：批量獲取所有台股的最新價格（開發中）
   - **欄位排序**：可自訂欄位顯示順序
   - **新增記錄**：點擊「+」按鈕新增台股記錄
   - **編輯**：直接在表格中編輯各欄位
   - **刪除**：左滑刪除記錄

3. **自動計算**
   - 編輯股數或成本單價時，自動重新計算：
     - 成本 = 成本單價 × 股數
     - 市值 = 現價 × 股數
     - 損益 = 市值 - 成本
     - 報酬率 = (損益 / 成本) × 100

4. **數據持久化**
   - 所有修改自動保存到 `TWStock` 實體
   - 支援 iCloud 同步

**欄位說明**：

| 欄位 | 說明 | 可編輯 |
|-----|------|-------|
| 日期 | 創建日期（格式：yyyy/MM/dd） | ❌ 唯讀 |
| 股票名稱 | 股票代碼（例如：2330） | ✅ |
| 股數 | 持有股數 | ✅ |
| 成本 | 總成本（自動計算） | ✅ |
| 成本單價 | 每股成本 | ✅ |
| 現價 | 當前價格 | ✅ |
| 市值 | 總市值（自動計算） | ❌ 唯讀 |
| 損益 | 未實現損益（自動計算） | ❌ 唯讀 |
| 報酬率 | 報酬率百分比（自動計算） | ❌ 唯讀 |
| 幣別 | 貨幣單位（預設 TWD） | ✅ |
| 評論 | 備註說明 | ✅ |

**與台股持倉明細視圖的差異**：

| 特性 | 台股明細表格 | 台股持倉明細視圖 |
|-----|------------|-----------------|
| 位置 | 主畫面（美股明細下方） | 從台股卡片點擊彈出 |
| 顯示方式 | 表格形式，可排序 | 卡片列表形式 |
| 新增功能 | 直接在表格中新增行 | 彈出表單新增 |
| 統計摘要 | 無 | 有（總市值、總成本等） |
| 同步功能 | 無 | 有（同步到月度資產） |
| 使用場景 | 查看和編輯所有台股記錄 | 快速管理持倉並同步 |

**程式碼位置**：

```swift
// CustomerDetailView.swift 中的表格順序
VStack(spacing: 16) {
    // 1. 月度資產明細
    MonthlyAssetDetailView(monthlyData: $monthlyAssetData, client: client)

    // 2. 公司債明細
    CorporateBondsDetailView(client: client)

    // 3. 結構型明細
    StructuredProductsDetailView(client: client)

    // 4. 美股明細
    USStockDetailView(client: client)

    // 5. 台股明細 ← 新增位置
    TWStockDetailView(client: client)

    // 6. 損益表
    ProfitLossTableView(client: client)
}
```

#### 使用範例

在資產配置圓餅圖中使用：

```swift
// 資產配置圓餅圖顯示
Circle()
    .trim(from: 0, to: getCashPercentage() / 100)
    .stroke(Color.orange, lineWidth: 24)

Text("\\(String(format: "%.1f", getCashPercentage()))%")
    .foregroundColor(.orange)
```

在投資卡片中使用：

```swift
// 美股卡片
VStack(alignment: .leading) {
    Text("美股")
    Text(formatCurrency(getUSStockValue()))
    Text("報酬率：\\(formatReturnRate(getUSStockReturnRate()))")
}

// 台股卡片
VStack(alignment: .leading) {
    Text("台股")
    Text(formatCurrency(getTWStockValue()))
    Text("報酬率：\\(formatReturnRate(getTWStockReturnRate()))")
}
```

#### 時間範圍篩選功能

總額大卡和所有投資卡片的走勢圖都支援時間範圍篩選：

```swift
@State private var selectedPeriod = "ALL" // 預設顯示全部資料

// 時間按鈕選項：ALL, 7D, 1M, 3M, 1Y
ForEach(["ALL", "7D", "1M", "3M", "1Y"], id: \.self) { period in
    Button(period) {
        selectedPeriod = period
    }
}

// 根據時間範圍篩選資料的共用函數
private func filterAssetsByPeriod(_ assets: [MonthlyAsset]) -> [MonthlyAsset] {
    switch selectedPeriod {
    case "ALL":
        return assets
    case "7D":
        return Array(assets.suffix(7))   // 最近7筆
    case "1M":
        return Array(assets.suffix(1))   // 最近1筆
    case "3M":
        return Array(assets.suffix(3))   // 最近3筆
    case "1Y":
        return Array(assets.suffix(12))  // 最近12筆
    default:
        return assets
    }
}
```

**時間範圍說明**：
- **ALL**：顯示所有月度資料（預設）
- **7D**：顯示最近7筆資料（過去七次記錄）
- **1M**：顯示最近1筆資料（過去一個月）
- **3M**：顯示最近3筆資料（過去三個月）
- **1Y**：顯示最近12筆資料（過去一年）

**連動範圍**：
- ✅ 總額大卡走勢圖
- ✅ 美股卡片走勢圖
- ✅ 台股卡片走勢圖
- ✅ 債券卡片走勢圖
- ✅ 定期定額卡片走勢圖

#### 幣別切換功能

總資產卡片支援美金/台幣切換按鈕：

```swift
@State private var selectedCurrency = "美金" // 預設顯示美金

// 幣別切換按鈕（位於「總資產」文字右側）
HStack(spacing: 0) {
    Button("美金") {
        selectedCurrency = "美金"
    }
    .font(.system(size: 11, weight: .medium))
    .padding(.horizontal, 10)
    .padding(.vertical, 4)
    .background(selectedCurrency == "美金" ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.clear)
    .foregroundColor(selectedCurrency == "美金" ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))

    Button("台幣") {
        selectedCurrency = "台幣"
    }
    .font(.system(size: 11, weight: .medium))
    .padding(.horizontal, 10)
    .padding(.vertical, 4)
    .background(selectedCurrency == "台幣" ? Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.8)) : Color.clear)
    .foregroundColor(selectedCurrency == "台幣" ? .white : Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
}
.background(Color(.init(red: 0.95, green: 0.95, blue: 0.96, alpha: 0.6)))
.clipShape(Capsule())
```

**設計特點**：
- ✅ 位置：緊鄰「總資產」文字右側
- ✅ 透明感：選中背景80%透明度，外框60%透明度
- ✅ 配色：深色背景+白色文字（選中）、灰色文字（未選中）
- ✅ 預設選中「美金」
- ✅ iPhone 和 iPad 版本統一風格

**幣別轉換邏輯**：

**美金模式**（預設）：
```swift
private func getTotalAssets() -> Double {
    // 直接讀取月度資產明細的 totalAssets 欄位
    guard let latestAsset = monthlyAssets.first,
          let totalAssetsStr = latestAsset.totalAssets,
          let totalAssets = Double(totalAssetsStr) else {
        return 0.0
    }
    return totalAssets
}
```

**台幣模式**：
```swift
private func getTotalAssets() -> Double {
    // 重新計算總資產（台幣）
    // 總資產 = ((美金資產 - 台股折合 - 台幣折合美金) × 匯率) + 台幣 + 台股

    let cash = Double(latestAsset.cash ?? "0") ?? 0
    let usStock = Double(latestAsset.usStock ?? "0") ?? 0
    let regularInvestment = Double(latestAsset.regularInvestment ?? "0") ?? 0
    let bonds = Double(latestAsset.bonds ?? "0") ?? 0
    let structured = Double(latestAsset.structured ?? "0") ?? 0
    let taiwanStockFolded = Double(latestAsset.taiwanStockFolded ?? "0") ?? 0
    let twdToUsd = Double(latestAsset.twdToUsd ?? "0") ?? 0
    let twdCash = Double(latestAsset.twdCash ?? "0") ?? 0
    let taiwanStock = Double(latestAsset.taiwanStock ?? "0") ?? 0
    let exchangeRate = getLatestExchangeRate()

    // 美金部分資產（扣除已經包含的台股折合和台幣折合美金）
    let usdAssets = cash + usStock + regularInvestment + bonds + structured - taiwanStockFolded - twdToUsd

    // 轉換為台幣並加上原本的台幣資產
    return (usdAssets * exchangeRate) + twdCash + taiwanStock
}
```

**匯率取得函數**：
```swift
private func getLatestExchangeRate() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let exchangeRateStr = latestAsset.exchangeRate,
          let exchangeRate = Double(exchangeRateStr) else {
        return 32.0 // 預設匯率
    }
    return exchangeRate
}
```

**幣別符號顯示**：
```swift
private func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? "0"

    // 無論美金或台幣都使用 $ 符號
    return "$\(formattedNumber)"
}
```

**影響範圍**：
- ✅ 總資產：根據幣別重新計算或直接讀取
- ✅ 總損益：`總資產 - 總匯入`（兩者使用相同幣別）
- ✅ 總匯入：台幣模式時乘以匯率
- ✅ 幣別符號：美金和台幣都顯示 `$`（不使用 NT 前綴）

**台幣計算優勢**：
- ✅ 台幣和台股直接以台幣顯示，不需要先換算成美金再換回台幣
- ✅ 避免雙重換算的誤差
- ✅ 更符合實際情況（台幣資產本來就是台幣計價）
- ✅ 扣除了「台股折合」和「台幣折合美金」，避免重複計算

#### 總資產走勢圖互動功能

總額大卡的走勢圖支援點擊/拖動互動，讓用戶可以即時查看特定時間點的總資產金額。

**主要功能**：
- ✅ **點擊互動**：在走勢圖上任意位置點擊，顯示該資料點的詳細資訊
- ✅ **拖動互動**：支援手指拖動瀏覽整條走勢線的所有資料點
- ✅ **視覺回饋**：
  - 垂直虛線指示器（虛線樣式：5pt 線段，5pt 間距）
  - 資料點圓形標記（白色填充，外框顏色隨損益變化）
  - 浮動標籤顯示日期和金額
- ✅ **幣別同步**：自動根據選擇的幣別（美金/台幣）顯示對應金額
- ✅ **時間範圍同步**：配合時間篩選功能（ALL/7D/1M/3M/1Y）

**狀態變數**（CustomerDetailView.swift: 14-17）：
```swift
// 走勢圖互動
@State private var selectedDataPointIndex: Int? = nil
@State private var selectedDataPointValue: Double? = nil
@State private var selectedDataPointDate: String? = nil
```

**使用方式**：
1. 在總額大卡的走勢圖上任意點擊或拖動
2. 系統自動計算最接近的資料點
3. 顯示垂直指示線標記該位置
4. 在資料點上方顯示浮動標籤，包含：
   - 日期（格式：M/d，例如 1/15）
   - 總資產金額（根據選擇的幣別自動轉換）

**技術特點**：

**1. 手勢處理**（CustomerDetailView.swift: 657-726）：
```swift
.gesture(
    DragGesture(minimumDistance: 0)
        .onChanged { gestureValue in
            let location = gestureValue.location

            // 根據選擇的時間範圍篩選資料
            let filteredAssets: [MonthlyAsset]
            switch selectedPeriod {
            case "ALL":
                filteredAssets = sortedAssets
            case "7D":
                filteredAssets = Array(sortedAssets.suffix(7))
            case "1M":
                filteredAssets = Array(sortedAssets.suffix(1))
            case "3M":
                filteredAssets = Array(sortedAssets.suffix(3))
            case "1Y":
                filteredAssets = Array(sortedAssets.suffix(12))
            default:
                filteredAssets = sortedAssets
            }

            // 計算觸摸位置對應的資料點索引
            let count = filteredAssets.count
            let stepX = geometry.size.width / CGFloat(max(count - 1, 1))
            let index = Int(round(location.x / stepX))

            // 根據幣別計算總資產
            if index >= 0 && index < filteredAssets.count {
                let asset = filteredAssets[index]
                let totalAssets: Double

                if selectedCurrency == "台幣" {
                    // 台幣模式：重新計算
                    let exchangeRate = Double(asset.exchangeRate ?? "32") ?? 32
                    // ... 計算邏輯
                } else {
                    // 美金模式：直接讀取
                    totalAssets = Double(asset.totalAssets ?? "0") ?? 0
                }

                selectedDataPointIndex = index
                selectedDataPointValue = totalAssets
                selectedDataPointDate = dateString
            }
        }
)
```

**2. 視覺覆蓋層**（CustomerDetailView.swift: 647-694）：
```swift
// 選中點的標記和數值
if let index = selectedDataPointIndex,
   let value = selectedDataPointValue,
   let date = selectedDataPointDate {
    let points = getTrendDataPoints(in: geometry.size)

    if index < points.count {
        let point = points[index]
        let changeValue = getTrendChangeValue()
        let baseColor = changeValue >= 0 ?
            Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) :
            Color.red

        ZStack {
            // 垂直指示線
            Path { path in
                path.move(to: CGPoint(x: point.x, y: 0))
                path.addLine(to: CGPoint(x: point.x, y: geometry.size.height))
            }
            .stroke(baseColor.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

            // 選中點的圓圈
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(baseColor, lineWidth: 2)
                )
                .position(x: point.x, y: point.y)

            // 數值標籤
            VStack(spacing: 2) {
                Text(date)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                Text(formatCurrency(value))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(baseColor.opacity(0.95))
            )
            .position(x: point.x, y: max(point.y - 40, 20))
        }
    }
}
```

**3. 幣別自動轉換**：
- **美金模式**：直接讀取 `MonthlyAsset.totalAssets`
- **台幣模式**：重新計算總資產
  - 美金資產部分：`(現金 + 美股 + 定期定額 + 債券 + 結構型 - 台股折合 - 台幣折合美金) × 匯率`
  - 台幣資產部分：`台幣現金 + 台股`
  - 總計：美金部分 + 台幣部分

**4. 顏色主題**：
- **正報酬**（綠色）：`Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0))`
- **負報酬**（紅色）：`Color.red`
- 指示線和標籤背景自動根據總損益值切換顏色

**5. 標籤位置自適應**：
```swift
.position(x: point.x, y: max(point.y - 40, 20))
```
- 標籤預設顯示在資料點上方 40pt
- 當資料點接近圖表頂部時，標籤自動下移至至少距離頂部 20pt，避免被截斷

**優勢與最佳實踐**：
- ✅ **即時響應**：使用 `DragGesture(minimumDistance: 0)` 實現點擊和拖動雙重支援
- ✅ **邏輯內聯**：所有計算邏輯直接在 View 內部實作，確保可存取 `@State` 變數
- ✅ **數據一致性**：幣別轉換邏輯與大卡主數字完全一致
- ✅ **效能考量**：由於月度資產資料點較少（通常 < 50 筆），無需快取機制
- ✅ **視覺清晰**：虛線指示器、圓形標記、浮動標籤三重視覺提示

**程式碼位置**：
- 主要實作：`CustomerDetailView.swift`
- 狀態變數：第 14-17 行
- 手勢處理：第 657-726 行
- 視覺覆蓋層：第 647-694 行

#### 走勢圖數據點自動隱藏功能

為了提升使用者體驗，走勢圖支援數據點自動隱藏功能，避免資訊持續顯示影響視覺。

**功能說明**：
- ✅ **手指滑動時**：即時顯示對應數據點的詳細資訊
- ✅ **手指放開後**：資訊繼續顯示 5 秒
- ✅ **自動隱藏**：5 秒後自動隱藏數據點，帶平滑動畫效果
- ✅ **計時器重置**：如果在 5 秒內再次滑動，計時器會重新開始計算

**狀態變數**（CustomerDetailView.swift: 18）：
```swift
@State private var hideDataPointWorkItem: DispatchWorkItem? = nil
```

**實作邏輯**：

**1. 投資儀表板**（CustomerDetailView.swift: 702-787）：
```swift
.gesture(
    DragGesture(minimumDistance: 0)
        .onChanged { gestureValue in
            // 取消之前的隱藏任務
            hideDataPointWorkItem?.cancel()

            // ... 處理觸摸事件，更新選中的數據點
        }
        .onEnded { _ in
            // 5秒後自動隱藏數據點
            let workItem = DispatchWorkItem {
                withAnimation {
                    selectedDataPointIndex = nil
                    selectedDataPointValue = nil
                    selectedDataPointDate = nil
                }
            }
            hideDataPointWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)
        }
)
```

**2. 保險管理**（InsurancePolicyView.swift: 636-654）：
```swift
.gesture(
    DragGesture(minimumDistance: 0)
        .onChanged { value in
            // 取消之前的隱藏任務
            hideDataPointWorkItem?.cancel()
            updateSelectedPoint(at: value.location, in: geometry.size)
        }
        .onEnded { _ in
            // 5秒後自動隱藏數據點
            let workItem = DispatchWorkItem {
                withAnimation {
                    selectedAge = nil
                    selectedDeathBenefit = nil
                }
            }
            hideDataPointWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)
        }
)
```

**技術特點**：
- ✅ **DispatchWorkItem**：使用可取消的任務，避免重複執行
- ✅ **動畫過渡**：使用 `withAnimation` 提供平滑的淡出效果
- ✅ **即時取消**：每次新的滑動都會取消之前的隱藏任務
- ✅ **統一體驗**：投資儀表板和保險管理頁面保持一致的行為

#### 小卡片群組配色方案

總資產大卡和保險額度大卡右上角的小卡片群組採用統一的配色方案，提升視覺層次和可讀性。

**投資儀表板配色**（CustomerDetailView.swift: 494-554）：

**1. 外層大卡片**：
```swift
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemGray6))  // 灰色背景
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
)
```

**2. 總匯入**（純文字顯示，無卡片背景）：
```swift
VStack(alignment: .leading, spacing: 8) {
    Text("總匯入")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(.secondaryLabel))

    Text(formatCurrencyWithoutSymbol(getTotalDeposit()))
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(Color(.label))
        .minimumScaleFactor(0.6)
        .lineLimit(1)
}
.frame(maxWidth: .infinity, alignment: .leading)
```

**3. 現金卡片**（白色背景）：
```swift
VStack(alignment: .leading, spacing: 8) {
    Text("現金")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(.secondaryLabel))

    Text(formatCurrencyWithoutSymbol(getCash()))
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(Color(.label))
        .minimumScaleFactor(0.6)
        .lineLimit(1)
}
.padding(16)
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(Color.white)  // 白色背景
)
```

**4. 總額報酬率卡片**（綠色漸層背景，保持原有設計）：
- 保持綠色漸層背景
- 顯示報酬率百分比
- 顯示較上次變化

**保險管理配色**（InsurancePolicyView.swift: 469-519）：

採用與投資儀表板完全一致的配色方案：

**1. 外層大卡片**：灰色背景（`Color(.systemGray6)`）
**2. 總繳保費**：純文字顯示（無卡片背景）
**3. 年度保費**：白色卡片（`Color.white`）
**4. 下次需繳保費**：綠色漸層卡片（保持原有設計）

**配色規則總結**：
- ✅ **外層大卡片**：淺灰色（`systemGray6`），提供整體視覺基礎
- ✅ **第一項數據**（總匯入/總繳保費）：純文字顯示，直接顯示在灰色背景上
- ✅ **第二項數據**（現金/年度保費）：白色卡片，提供對比和層次
- ✅ **重點數據**（報酬率/下次需繳）：綠色漸層卡片，突出重要資訊
- ✅ **統一設計**：兩個頁面保持完全一致的視覺語言

**視覺優勢**：
- ✅ **層次分明**：三種不同的視覺處理方式（純文字、白色卡片、綠色卡片）清晰區分不同重要程度的資訊
- ✅ **對比適中**：灰色背景搭配白色卡片，提供柔和的視覺對比
- ✅ **重點突出**：綠色卡片立即吸引視線，強調最重要的指標
- ✅ **深色模式友好**：使用系統顏色（`systemGray6`），自動適配深色模式

#### 數據連動特點

- ✅ **純淨計算**：每個資產類別獨立計算，避免重複統計（美股不包含定期定額，台股不包含台股折合）
- ✅ **比例自動調整**：資產配置圓餅圖比例根據實際資產金額自動計算
- ✅ **報酬率即時更新**：所有投資卡片的報酬率基於最新成本和現值自動計算
- ✅ **零手動維護**：新增月度資料後，所有圖表和卡片自動更新
- ✅ **客戶隔離**：每個客戶的資產配置和投資數據完全獨立
- ✅ **時間範圍連動**：所有走勢圖同步響應時間範圍切換
- ✅ **走勢圖漸層**：所有走勢圖統一使用漸層填充和漸層線條

## 移植到其他 App 的步驟

### 1. 複製核心檔案

必要檔案：
- `PersistenceController.swift`
- `DataModel.xcdatamodeld/`（需要根據需求修改實體）

### 2. 修改資料模型

根據新 App 的需求修改 Core Data 模型：
- 更改實體名稱
- 調整屬性
- 設定關聯性（如果需要）

### 3. 設定 CloudKit

1. 在新專案中添加 iCloud Capability
2. 在 CloudKit Dashboard 中建立對應的記錄類型
3. 確保欄位名稱和類型一致

### 4. 調整 UI 組件

根據新 App 的設計需求調整：
- 修改表單欄位
- 更改顯示樣式
- 調整導航結構

### 5. 測試同步功能

1. 在不同設備上登錄相同的 iCloud 帳號
2. 測試資料的新增、修改、刪除
3. 驗證跨設備同步是否正常

## 常見問題與解決方案

### 1. Core Data 載入失敗

**錯誤**：Thread 1: Fatal error: Core Data failed to load
**解決**：檢查 NSPersistentCloudKitContainer 初始化參數，確保資料模型名稱正確

### 2. CloudKit 同步失敗

**錯誤**：iCloud 狀態顯示不可用
**解決**：
- 確保設備已登錄 iCloud
- 檢查 iCloud Capability 是否正確設定
- 驗證 CloudKit Dashboard 中的記錄類型

### 3. 編譯錯誤

**錯誤**：Cannot find type 'Client' in scope
**解決**：
- 確保 Core Data 模型中的實體名稱正確
- 檢查 codeGenerationType="class" 設定
- Clean Build Folder (⌘+Shift+K)

## 開發工具要求

- **Xcode 15.0+**
- **iOS 16.0+** (支援 NavigationSplitView)
- **Apple Developer Account** (CloudKit 功能需要付費帳號)
- **macOS 13.0+**

## 部署注意事項

1. **Bundle ID 註冊**：確保在 Apple Developer Portal 中註冊 Bundle ID
2. **Provisioning Profile**：使用包含 iCloud 功能的 Provisioning Profile
3. **CloudKit Console**：確保 Production 環境中有正確的記錄類型
4. **測試**：在 TestFlight 或正式環境中測試 iCloud 同步功能

## 版本歷史

### v1.2.0 (2025-11-11)
**貸款管理功能重大更新**

#### 貸款/投資月度管理系統
- **新增完整的月度數據追蹤功能**
  - 創建 `LoanMonthlyDataTableView.swift`：專業的表格視圖組件
  - 創建 `AddLoanMonthlyDataView.swift`：月度數據輸入表單
  - 支援 15 個數據欄位追蹤：
    - 基本資訊：日期、貸款類型、貸款金額、已動用貸款
    - 投資資產：台股、美股、債券、定期定額
    - 成本資訊：台股成本、美股成本、債券成本、定期定額成本
    - 計算欄位：匯率、美股加債券折合台幣、投資總額

- **表格功能特色**
  - ✅ 固定表頭設計：橫向滾動時表頭和資料連動，垂直滾動時表頭保持固定
  - ✅ 可收合/展開功能：點擊向下箭頭可收合表格，節省空間
  - ✅ 欄位排序功能：點擊任意表頭可對該欄位進行升序/降序排序
  - ✅ 快速新增空白行：綠色 + 按鈕可直接新增空白行，點擊編輯
  - ✅ 表單新增：藍色「新增」按鈕開啟完整表單
  - ✅ 刪除按鈕：每行最左側有紅色垃圾桶按鈕可快速刪除
  - ✅ 自動計算：
    - 美股加債券折合台幣 = (美股 + 債券) × 匯率
    - 投資總額 = 台股 + 美股 + 債券 + 定期定額
  - ✅ 千分位格式化：所有數字欄位自動顯示千分位符號
  - ✅ 點擊編輯：點擊任意資料行可編輯
  - ✅ 長按選單：支援編輯和刪除操作

- **Core Data 更新**
  - 新增 `LoanMonthlyData` 實體，包含 16 個屬性
  - 建立 Client → LoanMonthlyData 一對多關聯
  - 支援級聯刪除（刪除客戶時自動刪除相關月度數據）

#### 貸款基本功能增強
- **已動用累積功能**
  - 在 Loan 實體新增 `usedLoanAmount` 欄位
  - 貸款列表卡片顯示「已動用累積」（橙色標示）
  - 貸款詳情頁顯示已動用累積資訊
  - AddLoanView 新增已動用累積輸入欄位，支援千分位格式化

- **快速已動用輸入**
  - 貸款卡片右上角三個點選單新增「已動用」選項
  - 點擊後彈出輸入框，輸入本次已動用金額
  - 自動執行兩項操作：
    1. 累加到貸款的「已動用累積」欄位
    2. 在「貸款/投資月度管理」表格新增一筆記錄
  - 實現了快速記錄與詳細追蹤的完美結合

- **貸款類型擴充**
  - 新增「理財型房貸」選項
  - 貸款類型清單：房貸、理財型房貸、車貸、信用貸款、學生貸款、其他

#### 貸款列表 UI/UX 改進
- **統一設計風格**
  - 貸款列表標題與「貸款/投資月度管理」使用相同風格
  - 圖示大小 14pt，字體 16pt semibold，統一灰色 (0.25, 0.25, 0.28)
  - 工具列結構一致：標題 + Spacer + 按鈕組

- **收合/展開功能**
  - 新增向下箭頭按鈕可收合/展開貸款列表
  - 使用動畫效果讓過渡更流暢
  - 節省螢幕空間，提升使用體驗

- **視覺優化**
  - 貸款列表區域底色：灰色 (systemGroupedBackground)
  - 貸款卡片背景：白色 (systemBackground)
  - 白色卡片在灰色背景上更突出，視覺層次清晰
  - 移除卡片間分隔線，改用間距區隔
  - 卡片間距：12pt

- **按鈕優化**
  - 「新增貸款」按鈕改為藍色長方形風格，與其他區域一致
  - 移除圖示，只保留「新增貸款」文字
  - 統一圓形按鈕樣式（收合按鈕等）

#### 技術改進
- **表格滾動優化**
  - 外層橫向 ScrollView 包裹表頭和資料，實現連動滾動
  - 內層垂直 ScrollView 只負責資料上下滾動
  - 表頭永遠可見，不會被滾動遮蓋
  - 最大高度 350pt，超過可滾動查看

- **排序功能實作**
  - 所有 15 個欄位都支援排序
  - 數字欄位按數值大小排序
  - 文字欄位按字母順序排序
  - 當前排序欄位顯示藍色箭頭指示器（↑/↓）

- **Core Data 關聯管理**
  - Client → LoanMonthlyData (一對多，Cascade 刪除)
  - Loan → 新增 usedLoanAmount 欄位
  - 確保資料一致性和完整性

#### 檔案結構更新
```
新增檔案：
├── LoanMonthlyDataTableView.swift      # 月度數據表格視圖
├── AddLoanMonthlyDataView.swift        # 月度數據輸入表單

修改檔案：
├── LoanManagementView.swift            # 貸款管理主視圖
├── AddLoanView.swift                   # 新增/編輯貸款表單
├── LoanDetailView.swift                # 貸款詳情頁
├── DataModel.xcdatamodeld/             # Core Data 模型更新
```

#### 使用者工作流程
1. **查看貸款列表**
   - 白色卡片顯示貸款基本資訊（貸款金額、已動用累積、利率、期限）
   - 橙色標示已動用累積金額，一目了然

2. **快速記錄已動用**
   - 點擊貸款卡片右上角三個點 → 已動用
   - 輸入金額 → 確認
   - 系統自動更新累積金額並新增月度記錄

3. **詳細管理月度數據**
   - 查看「貸款/投資月度管理」表格
   - 使用綠色 + 快速新增空白行
   - 或使用藍色「新增」開啟完整表單
   - 點擊表頭排序，輕鬆找到特定記錄
   - 點擊資料行編輯，或用垃圾桶刪除

4. **追蹤投資與貸款關係**
   - 每筆月度記錄包含完整的投資資產和成本資訊
   - 自動計算美股債券折合台幣和投資總額
   - 清楚掌握貸款動用與投資配置的關係

### v1.1.1 (2025-11-05)
**隱私政策網站部署完成**

#### GitHub Pages 部署
- **GitHub Repository**: https://github.com/Owen1221111/investmentdashboard-legal
- **部署狀態**: ✅ 已上線
- **部署日期**: 2025-11-05

#### 網站網址
- **首頁**: https://owen1221111.github.io/investmentdashboard-legal/
- **隱私權政策（中文）**: https://owen1221111.github.io/investmentdashboard-legal/privacy-zh.html
- **隱私權政策（英文）**: https://owen1221111.github.io/investmentdashboard-legal/privacy-en.html
- **使用條款（中文）**: https://owen1221111.github.io/investmentdashboard-legal/terms-zh.html
- **使用條款（英文）**: https://owen1221111.github.io/investmentdashboard-legal/terms-en.html

#### 本地文件位置
- **網頁文件目錄**: `/Users/chehungliu/Desktop/superdesign-template拷貝/InvestmentDashboard/網頁檔案/`
- **文件清單**:
  - `index.html` - 首頁（導航頁面）
  - `privacy-zh.html` - 隱私權政策（繁體中文）
  - `privacy-en.html` - Privacy Policy（English）
  - `terms-zh.html` - 使用條款（繁體中文）
  - `terms-en.html` - Terms of Service（English）

#### Markdown 原始文件
- `隱私權政策.md` - 隱私政策中文版原始檔
- `Privacy_Policy.md` - 隱私政策英文版原始檔
- `使用條款.md` - 使用條款中文版原始檔
- `Terms_of_Service.md` - 使用條款英文版原始檔

#### 如何更新內容
1. **修改本地 Markdown 文件**（如 `隱私權政策.md`）
2. **重新生成 HTML 文件**（使用相同的轉換工具）
3. **上傳到 GitHub**:
   - 方法 1（網頁）: GitHub repository → Upload files → 上傳更新的 HTML
   - 方法 2（命令列）:
     ```bash
     cd /path/to/local/repo
     git add .
     git commit -m "Update privacy policy"
     git push
     ```
4. **等待 1-2 分鐘**: GitHub Pages 會自動重新部署

#### App Store Connect 使用
- **Privacy Policy URL**: `https://owen1221111.github.io/investmentdashboard-legal/privacy-zh.html`
- **Support URL**: `https://owen1221111.github.io/investmentdashboard-legal/`

#### 聯絡資訊
- **開發者**: Owen Liu
- **Email**: stockbankapp@gmail.com
- **GitHub 用戶名**: Owen1221111

#### 網站特色
- ✅ 完全免費（GitHub Pages 免費託管）
- ✅ HTTPS 加密（Apple 要求）
- ✅ 響應式設計（手機/電腦適配）
- ✅ 專業的紫色漸層設計
- ✅ 中英文雙語支援
- ✅ 清晰的內容結構和導航

### v1.1.0 (2025-11-04/11-05)
**訂閱功能完整實作與測試**

#### 核心訂閱系統
- **實作 StoreKit 2 訂閱管理系統**
  - 新增 `SubscriptionManager.swift`：完整的訂閱生命週期管理
    - 訂閱狀態枚舉：notSubscribed, inTrialPeriod, subscribed, expired
    - 自動續訂訂閱支援：1個月免費試用 + NT$100/月
    - 訂閱狀態即時檢查和更新（Transaction.currentEntitlements）
    - 購買流程：`purchase()` 方法處理完整交易流程
    - 恢復購買：`restorePurchases()` 同步 App Store 狀態
    - 交易驗證：使用 `VerificationResult` 確保安全性
    - 交易監聽：`listenForTransactions()` 實時更新訂閱狀態
  - 產品 ID：`com.owenliu.investmentdashboard.monthly`
  - 訂閱群組：InvestmentDashboard Premium
  - Swift Concurrency 處理：
    - `@MainActor` 確保 UI 更新在主線程
    - `nonisolated` 關鍵字用於純函數驗證
    - Task.detached 用於後台交易監聽

#### 訂閱策略實作（選項 1：首次打開要求試用）
- **首次啟動體驗**
  - 首次打開 App 自動顯示訂閱頁面（延遲 1.5 秒避免與 onboarding 衝突）
  - UserDefaults 追蹤：`hasSeenSubscriptionPrompt` 鍵值
  - `shouldShowSubscriptionPrompt()` 方法判斷是否顯示提示
  - `markSubscriptionPromptAsSeen()` 標記用戶已看過
  - 用戶可選擇「關閉」，之後不再自動彈出

- **試用期機制**
  - 30 天免費試用期
  - 試用期間享有完整功能
  - 導航欄顯示皇冠圖標 + 剩餘天數（如：👑 29天）
  - `remainingTrialDays()` 計算剩餘天數
  - 試用期結束前 24 小時自動續訂（Apple 標準機制）

- **功能限制規則**
  - 試用期 / 已訂閱：所有功能完全可用
  - 試用期結束 / 未訂閱：
    - ❌ 新增客戶（需要訂閱）
    - ❌ 新增月度資料（需要訂閱）
    - ❌ 新增公司債資料（需要訂閱）
    - ❌ 新增結構型商品（進行中/已出場，需要訂閱）
    - ❌ 新增保險保單（需要訂閱）
    - ❌ OCR 辨識保單（需要訂閱）
    - ✅ 編輯現有資料（完全免費）
    - ✅ 刪除現有資料（完全免費）
    - ✅ 查看所有資料（完全免費）
    - ✅ iCloud 同步持續運作
    - ✅ 圖表分析完全可用

- **功能鎖定實作位置**（共 8 個新增入口）
  1. `ContentView.swift` (第 93 行)：新增客戶按鈕
  2. `ContentView.swift` (第 115 行)：新增月度資料按鈕
  3. `CorporateBondsDetailView.swift` (第 174 行)：公司債明細表格綠色 + 按鈕
  4. `StructuredProductsDetailView.swift` (第 377 行)：結構型商品（進行中）綠色 + 按鈕
  5. `StructuredProductsDetailView.swift` (第 577 行)：結構型商品（已出場）綠色 + 按鈕
  6. `InsurancePolicyView.swift` (第 338 行)：保險管理頁頂部 + 按鈕（手動新增表單）
  7. `InsurancePolicyView.swift` (第 1916 行)：保險明細表格相機按鈕（OCR 辨識）
  8. `InsurancePolicyView.swift` (第 1939 行)：保險明細表格綠色 + 按鈕（直接新增空白行）

- **資料安全保證**
  - 所有資料儲存在用戶自己的 iCloud 帳號
  - 訂閱狀態和資料儲存完全獨立
  - 試用期結束或取消訂閱後，資料永遠保留
  - 重新訂閱後立即恢復所有功能和資料
  - 訂閱只控制「新增資料」功能，不影響資料存取

#### 訂閱界面設計
- **訂閱頁面 (`SubscriptionView.swift`)**
  - 簡潔的訂閱方案展示（移除冗長的功能列表）
  - 訂閱方案卡片內容：
    - 標題：月費方案
    - 價格：NT$ 100 / 月（大字體顯示）
    - 試用期說明：
      - "試用 30 天後才開始收費"
      - "試用期間隨時可在設定中取消"
      - "取消後仍可使用至試用期結束"
    - 開發者說明（放在試用期說明下方）：
      - "此 App 是個人研發製作"
      - "因本身是金融從業人員，為了自己記錄方便開發此 App"
      - "如有操作上需要優化請 Email：stockbankapp@gmail.com"（可點擊）
  - 訂閱狀態卡片（已訂閱時顯示）：
    - 綠色背景，顯示 ✓ 圖標
    - "試用期中" 或 "已訂閱"
    - 剩餘天數提示
  - 行動按鈕：
    - "開始免費試用"（藍紫漸層按鈕）
    - "恢復購買"（文字按鈕）
  - 法律條款連結（底部）：
    - 隱私權政策
    - 使用條款
    - "付款將從您的 Apple ID 帳戶收取"

- **導航欄整合 (`ContentView.swift`)**
  - 訂閱入口：皇冠圖標按鈕
  - 訂閱狀態視覺化：
    - 金色皇冠（crown.fill）：已訂閱
    - 灰色皇冠（crown）：未訂閱
  - 試用期倒數：顯示剩餘天數（如：👑 29天）
  - 點擊皇冠圖標可隨時打開訂閱頁面

#### StoreKit Configuration 設定
- **本地測試配置 (`Configuration.storekit`)**
  - 創建位置：InvestmentDashboard 資料夾內
  - 訂閱群組：InvestmentDashboard Premium
  - 訂閱產品設定：
    - Reference Name: Monthly Subscription
    - Product ID: `com.owenliu.investmentdashboard.monthly`
    - Price: 100（測試用，實際價格在 App Store Connect 設定）
    - Subscription Duration: 1 Month
    - Introductory Offer Type: Free
    - Introductory Offer Duration: 1 Month
    - Family Sharing: Off
  - Xcode Scheme 配置：
    - Product → Scheme → Edit Scheme...
    - Run → Options → StoreKit Configuration
    - 選擇 "Configuration"

- **Xcode 專案配置**
  - Signing & Capabilities：
    - 添加 "In-App Purchase" Capability
  - 測試流程：
    1. 清除構建（⌘ + Shift + K）
    2. 重新運行（⌘ + R）
    3. 測試訂閱購買流程
    4. 驗證功能鎖定是否正常運作

#### 文檔更新
- **訂閱策略文檔 (`訂閱策略說明.md`)**
  - 用戶體驗流程詳細說明
  - 資料安全保證承諾
  - 功能限制規則表格
  - 用戶場景範例（積極用戶、猶豫用戶、取消後重訂等）
  - 技術實作細節
  - SubscriptionManager 核心方法說明
  - 已實作的功能鎖定位置清單
  - App Store 描述建議
  - 常見問題 FAQ

- **法律文件更新**
  - 更新 `Privacy_Policy.md` 和 `隱私權政策.md`
    - 開發者：Owen Liu
    - Email：stockbankapp@gmail.com
    - 移除地址欄位
  - 更新 `Terms_of_Service.md` 和 `使用條款.md`
    - 聯絡方式：stockbankapp@gmail.com
    - 訂閱條款說明

#### 技術架構與最佳實踐
- **Swift Concurrency**
  - `@MainActor` 用於 UI 更新
  - `async/await` 處理非同步操作
  - `Task.detached` 用於後台監聽
  - `nonisolated` 用於純函數驗證

- **StoreKit 2 API**
  - `Product.products(for:)` 載入產品
  - `product.purchase()` 發起購買
  - `AppStore.sync()` 同步交易
  - `Transaction.currentEntitlements` 檢查訂閱
  - `Transaction.updates` 監聽更新
  - `VerificationResult` 驗證交易安全性

- **狀態管理**
  - `@Published` property 自動通知 UI 更新
  - `ObservableObject` 符合 SwiftUI 響應式設計
  - `@EnvironmentObject` 全局共享訂閱狀態
  - UserDefaults 持久化簡單狀態

- **錯誤處理**
  - 自定義 `SubscriptionError` 枚舉
  - 完整的錯誤訊息本地化
  - UI 友善的錯誤提示

#### 測試驗證
- ✅ 訂閱購買流程正常運作
- ✅ 免費試用期正確啟動（30天）
- ✅ 試用期倒數顯示準確（29、28...天）
- ✅ 皇冠圖標狀態切換正常
- ✅ 所有 8 個新增按鈕功能鎖定生效
- ✅ 未訂閱用戶點擊新增按鈕會彈出訂閱頁面
- ✅ 已訂閱用戶可正常使用所有功能
- ✅ 開發者說明文字正確顯示
- ✅ Email 連結可點擊
- ✅ StoreKit 測試模式正常運作

### v1.0.2 (2025-11-04)
**導航欄優化更新**
- 優化 iPhone 導航欄佈局，解決按鈕擠壓問題
  - 標題文字從「投資儀表板」簡化為「儀表板」（ContentView.swift:174）
  - 減少右側按鈕組間距：HStack spacing 從 8 改為 4（ContentView.swift:188）
  - 縮小按鈕字體大小：從 14 改為 13（ContentView.swift:194, 207）
  - 減少按鈕水平內邊距：horizontal padding 從 12 改為 8（ContentView.swift:196, 209）
  - 調整按鈕圓角：從 8 改為 6，使按鈕更緊湊（ContentView.swift:199, 212）
- 提升「提醒」和「保單」按鈕在小螢幕設備上的可用性和視覺體驗

### v1.0.1 (2025-10-07)
**UI 優化更新**
- 統一小群組卡片內總匯入和現金的字體大小 (font-size: 24, minimumScaleFactor: 0.6)
- 移除小群組卡片內總匯入和現金的 $ 貨幣符號，改用純數字顯示
- 修正總額報酬率負數顯示問題（移除重複的 + 符號）
  - 新增 `formatReturnRate` 邏輯：正數顯示 "+X.X%"，負數顯示 "-X.X%"
- 統一時間軸按鈕（ALL/7D/1M/3M/1Y）配色，與美金/台幣按鈕一致
  - 選中狀態：深灰色背景 (rgb: 0.12, 0.12, 0.15, alpha: 0.8)，白色文字
  - 未選中狀態：淺灰色背景，灰色文字 (rgb: 0.5, 0.5, 0.55)
  - 保持原有按鈕間距和膠囊形狀
- 調整小群組卡片內總匯入的左對齊（padding-leading: 16），使「總」字與「現」字左對齊

**結構型商品功能優化**
- 實現月利率自動計算功能（進行中表格）
  - 月利率 = 利率 ÷ 12，自動計算並顯示
  - 支援利率欄位輸入格式：純數字、帶 % 符號、帶逗號
  - 月利率顯示格式：帶 % 符號（如 "1.00%"）
  - 月利率欄位為唯讀，不可手動編輯
- 已出場表格的月利率保持可編輯
  - 從進行中移至已出場時，自動帶入計算好的月利率值
  - 用戶可手動修改已出場的月利率

**客戶管理功能優化**
- 實現客戶排序持久化功能
  - 在 Client 實體新增 `sortOrder` 屬性（Integer 16，預設值：0）
  - 修改 FetchRequest 以 sortOrder 為主要排序依據
  - 拖拽排序後自動保存順序到 Core Data 和 iCloud
  - 新增客戶時自動設定 sortOrder，排在列表最後
  - 關閉 APP 後重新打開，客戶順序保持不變

### v1.0.0
**基本功能**
- 基本客戶管理功能，支援 iCloud 同步
- 支援 iPhone 和 iPad
- 基本的 CRUD 操作
- CloudKit 跨設備同步

## 深色模式支援

### 待辦事項

#### 已完成
- ✅ 主統計卡片支援深色模式
- ✅ 小群組卡片支援深色模式
- ✅ 統計小卡片支援深色模式

#### 待修改組件

**資產配置卡片 (Asset Allocation Card)**
- [ ] 背景色改為 `Color(.systemBackground)`
- [ ] 標題文字改為 `Color(.label)`
- [ ] 副標題文字改為 `Color(.secondaryLabel)`
- [ ] 圓餅圖背景改為 `Color(.tertiarySystemBackground)`

**投資卡片 (Investment Cards)**
- [ ] 美股卡片背景改為 `Color(.tertiarySystemBackground)`
- [ ] 台股卡片背景改為 `Color(.tertiarySystemBackground)`
- [ ] 債券卡片背景改為 `Color(.tertiarySystemBackground)`
- [ ] 債券配息卡片背景改為 `Color(.tertiarySystemBackground)`
- [ ] 所有卡片標題改為 `Color(.secondaryLabel)`
- [ ] 所有卡片內容改為 `Color(.label)`

**表格視圖 (Table Views)**
- [ ] 月度資產明細表格背景改為 `Color(.systemBackground)`
- [ ] 公司債明細表格背景改為 `Color(.systemBackground)`
- [ ] 結構型明細表格背景改為 `Color(.systemBackground)`
- [ ] 損益表背景改為 `Color(.systemBackground)`
- [ ] 表格標題文字改為 `Color(.label)`
- [ ] 表格內容文字改為 `Color(.secondaryLabel)`
- [ ] 表格分隔線改為 `Color(.separator)`

**側邊欄 (Sidebar)**
- [ ] 側邊欄背景改為 `Color(.systemBackground)`
- [ ] 客戶列表項目背景改為 `Color(.secondarySystemBackground)`
- [ ] 選中狀態背景改為 `Color(.tertiarySystemBackground)`
- [ ] 客戶名稱文字改為 `Color(.label)`

**表單視圖 (Forms)**
- [ ] 新增客戶表單背景改為 `Color(.systemBackground)`
- [ ] 編輯客戶表單背景改為 `Color(.systemBackground)`
- [ ] 新增月度資料表單背景改為 `Color(.systemBackground)`
- [ ] 輸入框背景改為 `Color(.tertiarySystemBackground)`
- [ ] 標籤文字改為 `Color(.label)`
- [ ] 佔位符文字改為 `Color(.placeholderText)`

**走勢圖 (Trend Chart)**
- [ ] 走勢圖背景改為透明或 `Color(.clear)`
- [ ] 走勢線顏色保持不變（粉紅色）
- [ ] 填充區域漸層調整為深色模式友好顏色
- [ ] 數值標籤改為 `Color(.label)`

### 系統顏色對照表

| 用途 | 淺色模式 | 深色模式 | 對應的 UIColor |
|------|---------|---------|---------------|
| 主要背景 | 白色 | 深灰/黑色 | `systemBackground` |
| 次要背景 | 淺灰 | 次深灰 | `secondarySystemBackground` |
| 第三層背景 | 更淺灰 | 次次深灰 | `tertiarySystemBackground` |
| 主要文字 | 黑色 | 白色 | `label` |
| 次要文字 | 深灰 | 淺灰 | `secondaryLabel` |
| 第三層文字 | 更深灰 | 更淺灰 | `tertiaryLabel` |
| 佔位符文字 | 淺灰 | 深灰 | `placeholderText` |
| 分隔線 | 淺灰 | 深灰 | `separator` |

### 修改原則

1. **背景顏色**：將所有固定的 `Color.white` 改為 `Color(.systemBackground)` 或其他系統背景色
2. **文字顏色**：將固定顏色改為 `Color(.label)`、`Color(.secondaryLabel)` 等系統文字顏色
3. **高亮顏色**：綠色報酬率等保持不變，因為它們本身就是語意顏色
4. **漸層背景**：需要在深色模式下調整漸層顏色，或改用系統顏色

### 實作範例

**修改前**：
```swift
.background(Color.white)
Text("標題").foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
```

**修改後**：
```swift
.background(Color(.systemBackground))
Text("標題").foregroundColor(Color(.label))
```

## CSV 匯入功能

### 功能概述

系統支援從 CSV 檔案批量匯入資料，並自動根據第一行表頭識別欄位對應關係。

### 支援的表格

1. **月度資產明細** (MonthlyAssetDetailView)
2. **公司債明細** (CorporateBondsDetailView)

### 匯入流程

1. 點擊表格右上角的藍色「匯入」按鈕（下載圖示）
2. 選擇「從 CSV 檔案匯入」
3. 選擇要匯入的 CSV 檔案
4. 系統自動解析並匯入資料
5. 資料自動儲存到 Core Data 並同步到 iCloud

### CSV 檔案格式要求

#### 月度資產明細 CSV 格式

**第一行必須包含表頭**，支援以下欄位名稱（順序可以任意）：

| 欄位名稱 | 別名 | 說明 | 是否必填 |
|---------|------|------|---------|
| 日期 | Date | 記錄日期 | ✅ 必填 |
| 現金 | Cash | 現金金額 | - |
| 美股 | US Stock | 美股金額 | - |
| 定期定額 | Regular Investment | 定期定額金額 | - |
| 債券 | Bonds | 債券金額 | - |
| 已確利息 | Confirmed Interest | 已確認利息 | - |
| 結構型 | Structured, 結構型商品 | 結構型商品金額 | - |
| 台股折合 | Taiwan Stock Folded | 台股折合美金 | - |
| 總資產 | 總額, Total Assets | 總資產金額 | - |
| 匯入 | Deposit | 匯入金額 | - |
| 匯入累積 | Deposit Accumulated | 匯入累積金額 | - |
| 美股成本 | US Stock Cost | 美股成本 | - |
| 定期定額成本 | Regular Investment Cost | 定期定額成本 | - |
| 債券成本 | Bonds Cost | 債券成本 | - |
| 台股成本 | Taiwan Stock Cost | 台股成本 | - |
| 備註 | Notes | 備註說明 | - |

**範例 CSV：**

```csv
日期,現金,美股,定期定額,債券,已確利息,結構型,台股折合,總額,匯入,匯入累積,美股成本,定期定額成本,債券成本,台股成本,備註
Sep 30, 2025,2222833,3752446,0,3765244,164048,400000,0,10140523,0,9370803,3178648,0,3912356,0,
Aug 28, 2025,3264395,3596018,0,2739362,164048,400000,0,9999775,0,9370803,3056265,0,2906035,0,
```

#### 公司債明細 CSV 格式

**第一行必須包含表頭**，支援以下欄位名稱（順序可以任意）：

| 欄位名稱 | 別名 | 說明 | 是否必填 |
|---------|------|------|---------|
| 申購日 | Subscription Date | 申購日期 | - |
| 債券名稱 | Bond Name | 債券名稱 | ✅ 必填 |
| 票面利率 | Coupon Rate | 票面利率 | - |
| 殖利率 | Yield Rate | 殖利率 | - |
| 申購價 | Subscription Price | 申購價格 | - |
| 申購金額 | Subscription Amount | 申購金額 | - |
| 持有面額 | Holding Face Value | 持有面額 | - |
| 交易金額 | Transaction Amount | 交易金額 | - |
| 現值 | Current Value | 現值 | - |
| 已領利息 | Received Interest | 已領利息 | - |
| 含息損益 | Profit Loss With Interest | 含息損益 | - |
| 報酬率 | Return Rate | 報酬率 | - |
| 配息月份 | Dividend Months | 配息月份 | - |
| 單次配息 | Single Dividend | 單次配息 | - |
| 年度配息 | Annual Dividend | 年度配息 | - |

**範例 CSV：**

```csv
申購日,債券名稱,票面利率,殖利率,申購價,申購金額,持有面額,交易金額,現值,已領利息,含息損益,報酬率,配息月份,單次配息,年度配息
Mar-6,2030債券,5.2%,2.34%,100.00,200000,200000,201500,200000.00,3104.0,+7.84%,3月/9月,5200,10400
```

### 日期格式支援

系統支援以下日期格式（月度資產明細）：

- `MMM d, yyyy` (例如：Sep 30, 2025)
- `MMM dd, yyyy` (例如：Sep 30, 2025)
- `yyyy-MM-dd` (例如：2025-09-30)
- `yyyy/MM/dd` (例如：2025/09/30)
- `M/d/yyyy` (例如：9/30/2025)

**重要**：日期欄位會自動解析並設定 `createdDate` 用於排序，確保資料按照實際日期降序排列。

### CSV 解析特點

1. **自動欄位識別**
   - 讀取第一行表頭
   - 支援中英文欄位名稱
   - 支援多種別名（例如：總資產 = 總額）
   - 欄位順序可以任意

2. **資料清理**
   - 自動移除數字中的千分位逗號（1,000,000 → 1000000）
   - 自動去除前後空白
   - 空白欄位自動填入空字串

3. **錯誤處理**
   - 驗證必填欄位是否存在
   - 跳過空白行
   - 處理引號包圍的欄位值（支援 CSV 標準格式）

4. **自動同步**
   - 匯入完成後自動儲存到 Core Data
   - 自動同步到 iCloud
   - 顯示匯入筆數

### 實作細節

#### MonthlyAssetDetailView.swift

**CSV 匯入函數**：

```swift
private func handleFileImport(result: Result<[URL], Error>) {
    // 處理檔案選擇結果
    // 讀取 CSV 內容
    // 呼叫 parseAndImportCSV() 解析並匯入
}

private func parseAndImportCSV(_ csvContent: String) {
    // 解析 CSV 行
    // 建立表頭索引映射
    // 驗證必填欄位
    // 逐行匯入資料
    // 儲存到 Core Data 和 iCloud
}

private func parseCSVLine(_ line: String) -> [String] {
    // 處理引號包圍的值
    // 處理逗號分隔
}

private func parseDateString(_ dateString: String) -> Date? {
    // 支援多種日期格式
    // 返回 Date 物件用於排序
}

private func getPossibleHeaderNames(for header: String) -> [String] {
    // 返回欄位的所有可能別名
}
```

#### CorporateBondsDetailView.swift

實作方式與 MonthlyAssetDetailView 類似，但針對公司債欄位進行調整。

### 使用範例

#### 步驟 1：準備 CSV 檔案

使用 Excel、Numbers 或文字編輯器建立 CSV 檔案：

```csv
日期,現金,美股,債券,總額
Sep 30, 2025,310000,0,0,310000
Nov 30, 2023,800,0,303646,310000
```

#### 步驟 2：匯入資料

1. 開啟 App
2. 選擇客戶
3. 點擊「月度資產明細」表格的匯入按鈕
4. 選擇「從 CSV 檔案匯入」
5. 選擇準備好的 CSV 檔案

#### 步驟 3：驗證結果

- 檢查資料是否正確匯入
- 確認日期排序是否正確（最新日期在最上方）
- 檢查數字格式是否正確顯示千分位

### 注意事項

1. **表頭名稱**
   - 第一行必須是表頭
   - 表頭名稱必須完全匹配（大小寫敏感）
   - 可以使用中文或英文別名

2. **資料格式**
   - 數字可以包含千分位逗號，系統會自動移除
   - 日期必須使用支援的格式之一
   - 空白欄位會被儲存為空字串

3. **檔案編碼**
   - 建議使用 UTF-8 編碼
   - 避免使用特殊字元

4. **重複資料**
   - 系統不會自動去重
   - 每次匯入都會新增資料
   - 如需清除舊資料，請先手動刪除

5. **資料驗證**
   - 匯入後請檢查資料是否正確
   - 特別注意日期和數字格式
   - 如有錯誤，請刪除後重新匯入

### 疑難排解

**問題：匯入後資料顯示為空**
- 檢查 CSV 表頭名稱是否正確
- 確認必填欄位是否存在
- 查看控制台錯誤訊息

**問題：日期排序不正確**
- 確認日期格式符合支援的格式
- 刪除舊資料後重新匯入
- 檢查 `createdDate` 是否正確設定

**問題：數字格式顯示不正確**
- 確認數字欄位不包含非數字字元（除了逗號和小數點）
- 檢查千分位格式是否正確

**問題：匯入失敗**
- 確認檔案格式為 CSV
- 檢查檔案編碼是否為 UTF-8
- 確認檔案至少有兩行（表頭 + 資料）

## 債券每月配息卡片連動功能

### 功能概述

債券每月配息卡片會自動從公司債明細表格讀取資料，計算並顯示每個月的債券配息金額，以12個月長條圖的形式呈現。

### 多幣別滑動切換功能

當客戶擁有不同幣別的債券時，卡片支援左右滑動切換幣別顯示：

#### 功能特點
- **左右滑動**：在配息小卡上滑動切換不同幣別
- **幣別標籤**：年配息金額左邊顯示當前幣別標籤（如 `USD`、`TWD`）
- **顏色區分**：不同幣別顯示不同顏色的長條圖
- **圓點指示器**：底部顯示幣別頁數指示點
- **獨立計算**：每個幣別的年配息和月配息獨立計算
- **預設 USD**：美金優先顯示

#### 幣別顏色對應
| 幣別 | 顏色 |
|------|------|
| USD | 綠色（預設） |
| TWD | 藍色 |
| EUR | 紫色 |
| JPY | 橘色 |
| GBP | 粉紅色 |
| CNY | 紅色 |
| AUD | 黃色 |
| CAD | 薄荷色 |
| CHF | 靛藍色 |
| HKD | 青色 |
| SGD | 藍綠色 |

#### 技術實現
```swift
// CustomerDetailView.swift

// 狀態變數
@State private var selectedBondCurrencyIndex: Int = 0

// 可用幣別（USD 優先）
private var availableBondCurrencies: [String] {
    let currencies = Array(Set(corporateBonds.compactMap { $0.currency ?? "USD" }))
    return currencies.sorted { c1, c2 in
        if c1 == "USD" { return true }
        if c2 == "USD" { return false }
        return c1 < c2
    }
}

// 配息計算支援幣別篩選
private func getMonthlyDividends(for currency: String? = nil) -> [Double]
private func getTotalAnnualDividend(for currency: String? = nil) -> Double
private func getMonthHeight(_ month: Int, for currency: String? = nil) -> CGFloat
```

**實作位置：** CustomerDetailView.swift:1767-1855

### 資料來源

卡片資料完全來自 **公司債明細表格** 的以下欄位：
- `配息月份`（dividendMonths）
- `單次配息`（singleDividend）
- `債券名稱`（bondName）

### 自動計算邏輯

#### 計算流程

```swift
private func getMonthlyDividends() -> [Double] {
    // 1. 初始化 12 個月的配息陣列（全部為 0）
    var monthlyDividends: [Double] = Array(repeating: 0.0, count: 12)

    // 2. 遍歷所有公司債
    for bond in corporateBonds {
        // 3. 讀取配息月份和單次配息金額
        // 4. 解析配息月份（支援多種格式）
        // 5. 將配息累加到對應月份
    }

    return monthlyDividends
}
```

**實作位置：** CustomerDetailView.swift:1546-1606

#### 支援的配息月份格式

系統支援以下三種配息月份格式，會自動識別並解析：

| 格式類型 | 範例 | 說明 |
|---------|------|------|
| 逗號分隔 | `1,3,6,9` 或 `1, 3, 6, 9` | 標準數字格式，用逗號分隔 |
| 斜線分隔（中文） | `1月/7月`、`3月/9月`、`5月/11月` | 中文月份格式，用斜線分隔 |
| 單一月份 | `6` 或 `12` | 只在單一月份配息 |

**解析邏輯：** CustomerDetailView.swift:1563-1591

```swift
// 先嘗試用逗號分隔
if dividendMonthsStr.contains(",") {
    months = dividendMonthsStr.split(separator: ",")
        .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
}
// 嘗試用斜線分隔（例如："1月/7月"）
else if dividendMonthsStr.contains("/") {
    months = dividendMonthsStr.split(separator: "/")
        .compactMap { part -> Int? in
            let cleaned = part.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "月", with: "")
            return Int(cleaned)
        }
}
// 單一數字
else if let month = Int(dividendMonthsStr.trimmingCharacters(in: .whitespaces)) {
    months = [month]
}
```

### 配息自動計算公式

公司債的年度配息和單次配息會自動計算，不允許用戶手動輸入。

#### 計算公式

| 欄位 | 計算公式 | 說明 |
|------|----------|------|
| 年度配息 | `票面利率 × 持有面額` | 固定值，不隨配息月份變化 |
| 單次配息 | `年度配息 ÷ 配息次數` | 依據配息月份數量動態計算 |

#### 配息次數判定

系統會自動從配息月份字串解析配息次數：

| 配息月份 | 配息次數 | 單次配息計算 |
|----------|----------|--------------|
| `1月、7月` | 2 | 年度配息 ÷ 2 |
| `1月、4月、7月、10月` | 4 | 年度配息 ÷ 4 |
| `3、6、9、12月` | 4 | 年度配息 ÷ 4 |
| `6月` | 1 | 年度配息 ÷ 1 |

#### 自動重新計算

當用戶在公司債明細表格中**更改配息月份**時，系統會自動：
1. 保持年度配息不變
2. 重新計算配息次數
3. 更新單次配息 = 年度配息 ÷ 新配息次數
4. 債券每月配息小卡同步更新

#### 範例計算

**情境**：持有面額 100,000，票面利率 10%

1. **年度配息** = 10% × 100,000 = **10,000**
2. 選擇「1月、7月」（2 次）→ **單次配息 = 5,000**
3. 改選「3、6、9、12月」（4 次）→ **單次配息 = 2,500**

#### 技術實現

**AddMonthlyDataView.swift**（新增債券時）：
```swift
// 年度配息 = 票面利率 × 持有面額
private var calculatedAnnualDividend: String {
    let couponRateValue = Double(couponRateStr) ?? 0
    let faceValue = Double(holdingFaceValue) ?? 0
    let result = (couponRateValue / 100) * faceValue
    return String(format: "%.2f", result)
}

// 單次配息 = 年度配息 / 配息次數
private var calculatedSingleDividend: String {
    let annualDividendValue = Double(calculatedAnnualDividend) ?? 0
    let paymentCount = countDividendPayments(dividendMonths)
    let result = annualDividendValue / Double(paymentCount)
    return String(format: "%.2f", result)
}
```

**CorporateBondsDetailView.swift**（表格編輯時）：
```swift
// 配息月份選擇器變更時自動重新計算
private func setBondValue(_ bond: CorporateBond, header: String, value: String) {
    // 通知物件即將變更（確保所有觀察此物件的視圖更新）
    bond.objectWillChange.send()

    bond.dividendMonths = value

    // 重新計算單次配息 = 年度配息 ÷ 配息次數
    let currentAnnual = Double(bond.annualDividend ?? "") ?? 0
    let paymentCount = countDividendPayments(value)

    if paymentCount > 0 && currentAnnual > 0 {
        let newSingle = currentAnnual / Double(paymentCount)
        bond.singleDividend = String(format: "%.2f", newSingle)
    }

    try? viewContext.save()

    // 刷新物件確保其他視圖（如 CustomerDetailView）更新
    viewContext.refresh(bond, mergeChanges: true)

    refreshTrigger = UUID()
}
```

#### Core Data 變更通知

為確保連續修改配息月份時視圖穩定更新，需要：

1. **objectWillChange.send()** - 通知 SwiftUI 物件即將變更
2. **viewContext.refresh()** - 刷新物件讓其他 @FetchRequest 視圖看到更新

這解決了第二次更改配息月份時需要切換客戶才能看到更新的問題。

**實作位置**：
- AddMonthlyDataView.swift（計算屬性）
- CorporateBondsDetailView.swift:454-482（setBondValue 函數）

### 計算範例

#### 範例 1：單一債券

**公司債資料：**
- 債券名稱：波克夏
- 配息月份：1月/7月
- 單次配息：5,200

**計算結果：**
- 1月配息：5,200
- 7月配息：5,200
- 其他月份：0
- **年配息總額：10,400**

#### 範例 2：多個債券累加

**公司債資料：**

| 債券名稱 | 配息月份 | 單次配息 |
|---------|---------|---------|
| 波克夏 | 1月/7月 | 5,200 |
| 迪士尼 | 1月/7月 | 3,600 |
| 高通 | 3月/9月 | 4,800 |

**計算結果：**
- 1月配息：5,200 + 3,600 = **8,800**
- 3月配息：4,800
- 7月配息：5,200 + 3,600 = **8,800**
- 9月配息：4,800
- 其他月份：0
- **年配息總額：27,200**

### 視覺化顯示

#### 卡片組件

```
┌─────────────────────────────────────────┐
│ 債券每月配息              年配息        │
│                          $10,400       │
│                                         │
│  ▓    ▓                                │
│  ▓    ▓                                │
│  ▓    ▓                                │
│  ▓    ▓    ▓    ▓    ▓    ▓    ▓    ▓ │
│  1  2  3  4  5  6  7  8  9 10 11 12   │
└─────────────────────────────────────────┘
```

**實作位置：** CustomerDetailView.swift:1183-1219

#### 長條圖高度計算

長條圖高度根據該月配息金額與最大配息金額的比例動態計算：

```swift
private func getMonthHeight(_ month: Int) -> CGFloat {
    let dividends = getMonthlyDividends()
    let maxDividend = dividends.max() ?? 1.0

    // 如果沒有任何配息，返回固定高度
    guard maxDividend > 0 else {
        return 20
    }

    // 根據配息金額計算高度（最小 10，最大 80）
    let dividend = dividends[month - 1]
    let normalizedHeight = (dividend / maxDividend) * 60 + 10
    return CGFloat(normalizedHeight)
}
```

**實作位置：** CustomerDetailView.swift:1611-1624

### 即時更新機制

卡片使用 SwiftUI 的 `@FetchRequest` 自動監聽公司債資料變化：

| 操作 | 結果 |
|------|------|
| ✅ 新增公司債 | 配息卡片自動更新 |
| ✅ 編輯配息月份 | 配息卡片自動更新 |
| ✅ 編輯單次配息 | 配息卡片自動更新 |
| ✅ 刪除公司債 | 配息卡片自動更新 |
| ✅ CSV匯入公司債 | 配息卡片自動更新 |

無需手動刷新，所有更新都是自動即時的。

### 除錯訊息

在開發模式下，控制台會顯示詳細的計算過程：

```
💰 債券配息：波克夏 - 配息月份：[1, 7] - 單次配息：5200.0
💰 債券配息：迪士尼 - 配息月份：[4, 10] - 單次配息：3600.0
💰 債券配息：高通 - 配息月份：[5, 11] - 單次配息：4800.0
📊 每月配息總計：[5200.0, 0.0, 0.0, 3600.0, 4800.0, 0.0, 5200.0, 0.0, 0.0, 3600.0, 4800.0, 0.0]
```

### 資料欄位對應

| 卡片顯示 | Core Data 欄位 | 計算方式 |
|---------|---------------|---------|
| 月份長條圖高度 | `singleDividend` × 配息次數 | 該月所有債券的單次配息總和 |
| 年配息總額 | `annualDividend` 或計算 | 12個月配息的總和 |
| 月份標記 | - | 1-12 固定顯示 |

### 注意事項

1. **配息月份格式**
   - 確保配息月份欄位填寫正確（1-12之間的數字）
   - 支援多種分隔符號（逗號、斜線）
   - 系統會自動過濾無效的月份數字

2. **單次配息金額**
   - 必須是數字格式
   - 可以包含千分位逗號（系統會自動移除）
   - 空值或非數字會被視為 0

3. **多個債券同月配息**
   - 系統會自動累加同一個月份的所有債券配息
   - 例如：3個債券都在1月配息，則1月的長條圖會顯示總和

4. **年度配息計算**
   - 年度配息 = 12個月配息的總和
   - 不依賴 `annualDividend` 欄位（該欄位僅供參考）
   - 確保配息數據的一致性

### 疑難排解

**問題：配息卡片顯示為 0**
- 檢查公司債明細是否有資料
- 確認「配息月份」欄位格式正確
- 確認「單次配息」欄位有數值
- 查看控制台除錯訊息

**問題：配息金額不正確**
- 檢查公司債明細中的「單次配息」數值
- 確認同一月份是否有多個債券配息（會自動累加）
- 查看控制台的計算過程訊息

**問題：長條圖高度異常**
- 長條圖高度是相對的（最高的月份為最高長條）
- 如果所有月份配息相同，長條高度會一致
- 最小高度為 10，最大高度為 80

## 自動計算欄位

### 總資產自動計算

#### 功能概述

月度資產明細表格中的「總資產」欄位會根據其他資產欄位自動計算，用戶無法手動修改。

#### 計算公式

```
總資產 = 現金 + 美股 + 定期定額 + 債券 + 結構型 + 台股折合
```

**注意：已領利息不計入總資產**

**實作位置：** MonthlyAssetDetailView.swift:508-523

#### 自動計算時機

| 時機 | 說明 |
|------|------|
| 編輯資產欄位 | 當編輯現金、美股、定期定額、債券、結構型、台股折合任一欄位時（已領利息不會觸發重新計算） |
| CSV 匯入 | 匯入 CSV 時自動計算，不讀取 CSV 中的總資產欄位 |
| 手動新增 | 新增記錄時自動設定為 0 |

#### 唯讀顯示

- 欄位背景顯示為灰色（`Color(.tertiarySystemBackground)`）
- 文字顏色為次要標籤顏色（`Color(.secondaryLabel)`）
- 無法點擊或編輯

**實作位置：** MonthlyAssetDetailView.swift:241-249

### 匯入累積自動計算

#### 功能概述

月度資產明細表格中的「匯入累積」欄位會自動計算從第一筆記錄到當前記錄的所有匯入金額總和，是一個累積總額的概念。用戶無法手動修改此欄位。

#### 計算公式

```
匯入累積 = 從最早到當前所有記錄的「匯入」欄位總和
```

例如：
- 第1筆（最早）: 匯入=310,000 → 匯入累積=310,000
- 第2筆: 匯入=0 → 匯入累積=310,000 (310,000 + 0)
- 第3筆: 匯入=500,000 → 匯入累積=810,000 (310,000 + 0 + 500,000)
- 第4筆: 匯入=117,200 → 匯入累積=927,200 (310,000 + 0 + 500,000 + 117,200)

**實作位置：** MonthlyAssetDetailView.swift:533-580

#### 計算邏輯

系統提供兩個計算函數：

##### 1. 批次重新計算所有記錄（用於手動編輯和資料修復）

```swift
private func recalculateAllDepositAccumulated() {
    // 1. 按日期升序排列所有記錄（從舊到新）
    let sortedAssets = monthlyAssets
        .filter { $0.createdDate != nil }
        .sorted { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }

    // 2. 用累積變數從0開始，逐筆加總
    var cumulativeDeposit: Double = 0
    for asset in sortedAssets {
        let currentDeposit = Double(asset.deposit ?? "0") ?? 0
        cumulativeDeposit += currentDeposit
        asset.depositAccumulated = String(format: "%.2f", cumulativeDeposit)
    }
}
```

##### 2. 計算單筆記錄（用於新增資料時）

```swift
private func recalculateDepositAccumulated(for asset: MonthlyAsset) {
    // 找出上一筆記錄並取得其匯入累積值
    let previousAsset = sortedAssets.last {
        ($0.createdDate ?? Date.distantPast) < currentDate
    }

    let currentDeposit = Double(asset.deposit ?? "0") ?? 0
    let previousDepositAccumulated = Double(previousAsset?.depositAccumulated ?? "0") ?? 0

    asset.depositAccumulated = String(format: "%.2f", currentDeposit + previousDepositAccumulated)
}
```

#### 自動計算時機

| 時機 | 使用函數 | 說明 |
|------|---------|------|
| 手動編輯「匯入」欄位 | `recalculateAllDepositAccumulated()` | 重新計算所有記錄，確保累積正確 |
| CSV 匯入 | 批次計算 | 匯入後按日期排序並批次計算所有匯入累積 |
| 頁面開啟時 | `recalculateAllDepositAccumulated()` | 自動修復所有記錄的匯入累積 |
| 手動新增記錄 | `recalculateDepositAccumulated(for:)` | 計算新記錄的匯入累積 |

**實作位置：**
- 手動編輯時：MonthlyAssetDetailView.swift:490-492
- CSV匯入時：MonthlyAssetDetailView.swift:753-778
- 頁面開啟時：MonthlyAssetDetailView.swift:82-96
- 手動新增時：MonthlyAssetDetailView.swift:376-377

#### CSV 匯入時的特殊處理

CSV 匯入時使用特殊的批次計算邏輯：

```swift
// 1. 先建立所有新記錄並儲存
for i in 1..<lines.count {
    let newAsset = MonthlyAsset(context: viewContext)
    // ... 設定各欄位
    newAsset.depositAccumulated = "0"  // 暫時設為0
    newAssets.append(newAsset)
}

// 2. 儲存到 Core Data
try viewContext.save()

// 3. 合併舊資料和新資料，按日期排序
let allAssets = (existingAssets + sortedNewAssets).sorted {
    ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast)
}

// 4. 依序計算每一筆的匯入累積
var cumulativeDeposit: Double = 0
for asset in allAssets {
    let currentDeposit = Double(asset.deposit ?? "0") ?? 0
    cumulativeDeposit += currentDeposit
    asset.depositAccumulated = String(format: "%.2f", cumulativeDeposit)
}

// 5. 最後儲存並同步到 iCloud
try viewContext.save()
PersistenceController.shared.save()
```

這種分階段處理確保：
1. 新舊資料都已存入 Core Data
2. 能正確找到所有相關記錄
3. 按正確的時間順序累加

#### 計算範例

假設有以下月度資產記錄（按日期從舊到新排序）：

| 日期 | 匯入 | 匯入累積（自動計算） | 計算過程 |
|------|------|---------------------|---------|
| 2023-09-30 | 310,000 | 310,000 | 0 + 310,000 = 310,000 |
| 2023-11-30 | 0 | 310,000 | 310,000 + 0 = 310,000 |
| 2023-12-31 | 0 | 310,000 | 310,000 + 0 = 310,000 |
| 2024-01-31 | 500,000 | 810,000 | 310,000 + 500,000 = 810,000 |
| 2024-02-29 | 0 | 810,000 | 810,000 + 0 = 810,000 |
| 2024-05-31 | 117,200 | 927,200 | 810,000 + 117,200 = 927,200 |

#### 唯讀顯示

與總資產欄位相同：
- 欄位背景顯示為灰色（`Color(.tertiarySystemBackground)`）
- 文字顏色為次要標籤顏色（`Color(.secondaryLabel)`）
- 無法點擊或編輯

**實作位置：** MonthlyAssetDetailView.swift:241-249

#### 除錯訊息

控制台會顯示計算過程：

**手動編輯時：**
```
📊 重算匯入累積：日期=Sep 30, 2023, 本次匯入=310000.0, 累積總額=310000.0
📊 重算匯入累積：日期=Jan 31, 2024, 本次匯入=500000.0, 累積總額=810000.0
📊 重算匯入累積：日期=May 31, 2024, 本次匯入=117200.0, 累積總額=927200.0
```

**CSV 匯入時：**
```
🔍 現有資料筆數: 5
🔍 新匯入資料筆數: 10
🔍 合併後總筆數: 15
📊 [第1筆] 日期=Sep 30, 2023, 本次匯入=310000.0, 累積總額=310000.0
📊 [第2筆] 日期=Nov 30, 2023, 本次匯入=0.0, 累積總額=310000.0
...
```

#### 注意事項

1. **日期順序的重要性**
   - 系統根據 `createdDate` 欄位來判斷記錄的先後順序
   - 匯入累積是按時間順序累加的，確保每筆記錄的日期正確設定非常重要

2. **連鎖重新計算**
   - 當手動編輯任何一筆記錄的「匯入」欄位時，系統會**重新計算所有記錄**的匯入累積
   - 這確保了累積值始終正確，即使修改歷史記錄也不會出錯

3. **自動修復機制**
   - 每次打開客戶詳細資料頁面時，系統會自動重新計算所有匯入累積
   - 這可以修復因資料遷移、程式碼更新等原因造成的不一致

4. **第一筆記錄**
   - 時間最早的記錄，其匯入累積 = 本次匯入（因為沒有上一筆）

5. **刪除記錄的影響**
   - 刪除記錄後，需要手動觸發一次重新計算（編輯任一記錄的匯入欄位即可）
   - 或者重新打開該客戶的詳細資料頁面，系統會自動修復

### 自動修復功能

#### 修復缺失的總資產

當打開月度資產明細表格時，系統會自動掃描並修復所有缺失或為 0 的總資產欄位。

**實作位置：** MonthlyAssetDetailView.swift:556-594

**觸發時機：** 表格 `.onAppear` 時（MonthlyAssetDetailView.swift:86-87）

```swift
private func fixMissingTotalAssets() {
    for asset in monthlyAssets {
        if asset.totalAssets == nil || asset.totalAssets?.isEmpty == true {
            // 重新計算總資產
            recalculateTotalAssets(for: asset)
        }
    }
}
```

**使用場景：**
- CSV 匯入的舊資料缺少總資產
- 資料庫遷移後需要補齊總資產
- 程式碼更新後的資料修復

## 刪除確認防呆機制

### 功能概述

為了防止用戶誤刪重要資料，月度資產明細和公司債明細表格的刪除按鈕都增加了確認對話框。

### 實作細節

#### 月度資產明細刪除確認

**實作位置：** MonthlyAssetDetailView.swift:89-105

```swift
.alert("確認刪除", isPresented: $showingDeleteConfirmation) {
    Button("取消", role: .cancel) {
        assetToDelete = nil
    }
    Button("刪除", role: .destructive) {
        if let asset = assetToDelete {
            deleteAsset(asset)
            assetToDelete = nil
        }
    }
} message: {
    Text("確定要刪除「\(asset.date ?? "此記錄")」的月度資產資料嗎？此操作無法復原。")
}
```

**確認對話框內容：**
- 標題：「確認刪除」
- 訊息：顯示要刪除的記錄日期（例如：「確定要刪除『Sep 30 2025』的月度資產資料嗎？」）
- 警告：「此操作無法復原」
- 按鈕：「取消」（灰色）、「刪除」（紅色）

#### 公司債明細刪除確認

**實作位置：** CorporateBondsDetailView.swift:84-100

```swift
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
    Text("確定要刪除「\(bond.bondName ?? "此債券")」嗎？此操作無法復原。")
}
```

**確認對話框內容：**
- 標題：「確認刪除」
- 訊息：顯示要刪除的債券名稱（例如：「確定要刪除『波克夏』嗎？」）
- 警告：「此操作無法復原」
- 按鈕：「取消」（灰色）、「刪除」（紅色）

### 使用流程

1. 用戶點擊紅色刪除按鈕（左側的 `-` 圖示）
2. 系統顯示確認對話框，顯示要刪除的項目名稱
3. 用戶選擇：
   - **取消**：關閉對話框，不執行刪除
   - **刪除**：確認刪除，從 Core Data 和 iCloud 中移除資料

### 安全特性

✅ **防止誤觸** - 需要兩次確認才能刪除
✅ **清楚標示** - 顯示要刪除的項目名稱
✅ **醒目警告** - 刪除按鈕為紅色，表示危險操作
✅ **明確提示** - 「此操作無法復原」警告訊息
✅ **易於取消** - 取消按鈕位置明顯，且有獨立的角色標記

## 結構型商品管理系統

### 功能概述

結構型商品管理支援進行中和已出場兩個獨立區域，提供完整的生命週期追蹤功能。

### 資料模型

#### StructuredProduct 實體

```xml
<entity name="StructuredProduct" representedClassName="StructuredProduct" syncable="YES" codeGenerationType="class">
    <!-- 基本資訊 -->
    <attribute name="tradePricingDate" attributeType="String" defaultValueString=""/>
    <attribute name="numberOfTargets" attributeType="Integer 16" defaultValueString="1" usesScalarValueType="YES"/>
    <attribute name="issueDate" attributeType="String" defaultValueString=""/>
    <attribute name="finalValuationDate" attributeType="String" defaultValueString=""/>
    <attribute name="interestRate" attributeType="String" defaultValueString=""/>
    <attribute name="monthlyRate" attributeType="String" defaultValueString=""/>
    <attribute name="transactionAmount" attributeType="String" defaultValueString=""/>

    <!-- 標的資訊（支援1-3個標的） -->
    <attribute name="target1" attributeType="String" defaultValueString=""/>
    <attribute name="target2" attributeType="String" defaultValueString=""/>
    <attribute name="target3" attributeType="String" defaultValueString=""/>

    <!-- 期初價格（對應1-3個標的） -->
    <attribute name="initialPrice1" attributeType="String" defaultValueString=""/>
    <attribute name="initialPrice2" attributeType="String" defaultValueString=""/>
    <attribute name="initialPrice3" attributeType="String" defaultValueString=""/>

    <!-- 執行價格（對應1-3個標的） -->
    <attribute name="strikePrice1" attributeType="String" defaultValueString=""/>
    <attribute name="strikePrice2" attributeType="String" defaultValueString=""/>
    <attribute name="strikePrice3" attributeType="String" defaultValueString=""/>

    <!-- 距離出場%（對應1-3個標的） -->
    <attribute name="distanceToExit1" attributeType="String" defaultValueString=""/>
    <attribute name="distanceToExit2" attributeType="String" defaultValueString=""/>
    <attribute name="distanceToExit3" attributeType="String" defaultValueString=""/>

    <!-- 已出場相關欄位 -->
    <attribute name="isExited" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES"/>
    <attribute name="exitDate" attributeType="String" defaultValueString=""/>
    <attribute name="holdingMonths" attributeType="String" defaultValueString=""/>
    <attribute name="actualReturn" attributeType="String" defaultValueString=""/>
    <attribute name="realProfit" attributeType="String" defaultValueString=""/>
    <attribute name="notes" attributeType="String" defaultValueString=""/>

    <!-- 系統欄位 -->
    <attribute name="createdDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    <relationship name="client" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Client" inverseName="structuredProducts" inverseEntity="Client"/>
</entity>
```

### 核心功能

#### 1. 多標的支援系統

**功能特點：**
- 每個結構型商品可包含 1-3 個標的
- 新增時可選擇標的數量（對話框選擇）
- 每個標的有獨立的：
  - 標的名稱（target1-3）
  - 期初價格（initialPrice1-3）
  - 執行價格（strikePrice1-3）
  - 距離出場%（distanceToExit1-3）

**實作位置：** StructuredProductsDetailView.swift

**選擇標的數量對話框：**
```swift
.confirmationDialog("選擇標的數量", isPresented: $showingTargetSelection) {
    Button("1 個標的") { createNewProduct(numberOfTargets: 1) }
    Button("2 個標的") { createNewProduct(numberOfTargets: 2) }
    Button("3 個標的") { createNewProduct(numberOfTargets: 3) }
    Button("取消", role: .cancel) { }
}
```

**動態欄位顯示：**
```swift
private func getEffectiveTargetCount(for product: StructuredProduct) -> Int {
    // 如果有設定 numberOfTargets，使用該值
    if product.numberOfTargets > 0 {
        return Int(product.numberOfTargets)
    }

    // 否則根據實際填寫的標的數量判斷（兼容舊資料）
    var count = 0
    if !(product.target1 ?? "").isEmpty { count = 1 }
    if !(product.target2 ?? "").isEmpty { count = 2 }
    if !(product.target3 ?? "").isEmpty { count = 3 }

    return max(count, 1)
}
```

#### 2. 進行中與已出場雙區域管理

**兩個獨立區域：**

| 區域 | 圖示 | 表頭欄位 | 用途 |
|-----|------|---------|------|
| **結構型明細**（進行中） | 📊 | 交易定價日、標的、發行日、最終評價日、期初價格、執行價格、距離出場%、利率、月利率、交易金額 | 追蹤進行中的結構型商品 |
| **結構型已出場** | ✓ | 交易定價日、標的、發行日、最終評價日、利率、月利率、出場日、持有月數、實際收益、交易金額、實質收益、備註 | 記錄已出場的歷史資料 |

**資料分離機制：**
```swift
// 進行中的結構型商品
_ongoingProducts = FetchRequest<StructuredProduct>(
    sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
    predicate: NSPredicate(format: "client == %@ AND isExited == NO", client)
)

// 已出場的結構型商品
_exitedProducts = FetchRequest<StructuredProduct>(
    sortDescriptors: [NSSortDescriptor(keyPath: \StructuredProduct.createdDate, ascending: false)],
    predicate: NSPredicate(format: "client == %@ AND isExited == YES", client)
)
```

#### 3. 複製到已出場功能

**功能說明：**
- 每列右側有藍色箭頭按鈕（→）
- 點擊後**複製**一份資料到已出場區域
- **原始資料保留在進行中區域**
- 使用者可自行決定是否刪除原始資料

**實作邏輯：**
```swift
private func moveToExited(_ product: StructuredProduct) {
    // 建立新的已出場產品（複製資料）
    let exitedProduct = StructuredProduct(context: viewContext)
    exitedProduct.client = product.client
    exitedProduct.isExited = true

    // 複製所有進行中的欄位
    exitedProduct.numberOfTargets = product.numberOfTargets
    exitedProduct.tradePricingDate = product.tradePricingDate
    exitedProduct.target1 = product.target1
    exitedProduct.target2 = product.target2
    exitedProduct.target3 = product.target3
    // ... (複製所有相關欄位)

    // 初始化已出場專屬欄位為空白（讓使用者填寫）
    exitedProduct.exitDate = ""
    exitedProduct.holdingMonths = ""
    exitedProduct.actualReturn = ""
    exitedProduct.realProfit = ""
    exitedProduct.notes = ""

    // 儲存並同步到 iCloud
    try viewContext.save()
    PersistenceController.shared.save()
}
```

**複製的欄位：**
- ✅ 標的數量和所有標的資訊
- ✅ 交易定價日、發行日、最終評價日
- ✅ 所有期初價格、執行價格、距離出場%
- ✅ 利率、月利率、交易金額

**已出場新欄位：**
- 📝 出場日（exitDate）
- 📝 持有月數（holdingMonths）
- 📝 實際收益（actualReturn）
- 📝 實質收益（realProfit）
- 📝 備註（notes）

#### 4. 直接新增已出場資料

**功能說明：**
- 已出場區域有獨立的 ➕ 按鈕
- 可直接在已出場區域新增歷史資料
- 支援選擇標的數量（1-3個）
- 自動標記為已出場狀態（isExited = true）

**實作邏輯：**
```swift
// 進行中新增
private func addNewRow() {
    isAddingToExited = false
    showingTargetSelection = true
}

// 已出場新增
private func addExitedRow() {
    isAddingToExited = true
    showingTargetSelection = true
}

// 統一的建立函數
private func createNewProduct(numberOfTargets: Int16, isExited: Bool = false) {
    let newProduct = StructuredProduct(context: viewContext)
    newProduct.numberOfTargets = numberOfTargets
    newProduct.isExited = isExited

    // 如果是已出場，初始化已出場欄位
    if isExited {
        newProduct.exitDate = ""
        newProduct.holdingMonths = ""
        newProduct.actualReturn = ""
        newProduct.realProfit = ""
        newProduct.notes = ""
    }
}
```

### 視覺化設計

#### 標的欄位顏色編碼

| 欄位類型 | 背景顏色 | 用途 |
|---------|---------|------|
| 標的名稱 | 綠色 (`Color.green.opacity(0.1)`) | 標的1、標的2、標的3 |
| 期初價格 | 橙色 (`Color.orange.opacity(0.1)`) | 價格1、價格2、價格3 |
| 執行價格 | 藍色 (`Color.blue.opacity(0.1)`) | 執行價1、執行價2、執行價3 |
| 距離出場% | 紫色 (`Color.purple.opacity(0.1)`) | 距離1、距離2、距離3 |

#### 按鈕設計

| 按鈕 | 圖示 | 顏色 | 功能 |
|-----|------|------|------|
| 新增進行中 | ➕ | 綠色 | 在進行中區域新增資料 |
| 新增已出場 | ➕ | 綠色 | 在已出場區域新增歷史資料 |
| 複製到已出場 | → | 藍色 | 複製資料到已出場區域 |
| 刪除 | ➖ | 紅色 | 刪除記錄（有確認對話框） |

### 資料流程

#### 新增進行中商品流程
```
1. 點擊「結構型明細」區域的 ➕ 按鈕
   ↓
2. 選擇標的數量（1/2/3）
   ↓
3. 建立新記錄（isExited = false）
   ↓
4. 根據標的數量顯示對應欄位
   ↓
5. 儲存到 Core Data 並同步 iCloud
```

#### 複製到已出場流程
```
1. 在進行中表格點擊 → 按鈕
   ↓
2. 複製所有進行中欄位資料
   ↓
3. 建立新記錄（isExited = true）
   ↓
4. 初始化已出場專屬欄位為空白
   ↓
5. 儲存到 Core Data 並同步 iCloud
   ↓
6. 資料出現在已出場區域
   ↓
7. 原始資料保留在進行中區域
```

#### 直接新增已出場流程
```
1. 點擊「結構型已出場」區域的 ➕ 按鈕
   ↓
2. 選擇標的數量（1/2/3）
   ↓
3. 建立新記錄（isExited = true）
   ↓
4. 初始化所有欄位為空白
   ↓
5. 儲存到 Core Data 並同步 iCloud
```

### CloudKit 索引設定

#### CD_StructuredProduct 索引

```
索引 1:
- Field: createdDate
- Type: SORTABLE
- Order: DESCENDING

索引 2:
- Field: CD_client
- Type: QUERYABLE

索引 3:
- Field: isExited
- Type: QUERYABLE
```

**說明：**
- `createdDate` 用於按時間排序
- `CD_client` 用於篩選特定客戶的資料
- `isExited` 用於區分進行中和已出場資料

### 技術特點

#### 1. 向後兼容機制

舊資料（沒有 `numberOfTargets` 欄位）會自動根據實際填寫的標的數量判斷：

```swift
private func getEffectiveTargetCount(for product: StructuredProduct) -> Int {
    if product.numberOfTargets > 0 {
        return Int(product.numberOfTargets)
    }

    // 兼容舊資料：根據實際填寫判斷
    var count = 0
    if !(product.target1 ?? "").isEmpty { count = 1 }
    if !(product.target2 ?? "").isEmpty { count = 2 }
    if !(product.target3 ?? "").isEmpty { count = 3 }

    return max(count, 1)  // 至少顯示1個欄位
}
```

#### 2. 千分位格式化

所有數字欄位自動支援千分位顯示：
- 輸入：1000000
- 顯示：1,000,000

#### 3. 動態欄位渲染

根據 `numberOfTargets` 動態決定顯示幾組標的資訊：

```swift
private func targetsCell(for product: StructuredProduct) -> some View {
    let effectiveTargetCount = getEffectiveTargetCount(for: product)

    return VStack(alignment: .leading, spacing: 2) {
        if effectiveTargetCount >= 1 {
            // 顯示標的1
        }
        if effectiveTargetCount >= 2 {
            // 顯示標的2
        }
        if effectiveTargetCount >= 3 {
            // 顯示標的3
        }
    }
}
```

### 使用情境

#### 情境 1：新商品建立
1. 業務簽訂新的結構型商品合約
2. 點擊進行中區域的 ➕ 按鈕
3. 選擇標的數量（例如：2個標的）
4. 填寫兩組標的資訊和相關數據

#### 情境 2：商品出場
1. 商品到期或提前出場
2. 點擊該筆資料右側的 → 按鈕
3. 資料自動複製到已出場區域
4. 在已出場區域填寫出場資訊
5. 決定是否刪除進行中的原始資料

#### 情境 3：歷史資料補錄
1. 需要補錄過去已出場的商品資料
2. 點擊已出場區域的 ➕ 按鈕
3. 選擇標的數量
4. 直接填寫所有資料（包含出場資訊）

### 注意事項

1. **資料獨立性**
   - 進行中和已出場是完全獨立的記錄
   - 複製到已出場不會影響原始資料
   - 使用者需手動刪除不需要的進行中資料

2. **標的數量限制**
   - 最少 1 個標的
   - 最多 3 個標的
   - 建立後無法修改標的數量（需刪除重建）

3. **欄位對應**
   - 進行中和已出場共用的欄位會自動複製
   - 已出場專屬欄位需手動填寫
   - 千分位格式化會自動處理

4. **iCloud 同步**
   - 所有操作自動同步到 iCloud
   - 新增、複製、刪除都會立即推送
   - 跨設備資料保持一致

---

## UI/UX 設計 - 客戶管理面板

### 設計概述

客戶管理面板採用側邊欄覆蓋層設計，通過漢堡按鈕觸發，提供完整的客戶管理功能。

### 主要功能

#### 1. 面板觸發
- **位置**：主畫面左上角漢堡按鈕（☰）
- **動畫**：從左側滑入，帶有 easeInOut 動畫（0.3秒）
- **寬度**：75% 螢幕寬度，最大 320pt
- **背景遮罩**：半透明黑色背景（0.4 透明度），點擊可關閉面板
- **陰影**：輕柔陰影效果（opacity 0.05, radius 8）

#### 2. 頂部標題區域
- **標題**：「客戶管理」
- **副標題**：動態顯示
  - 正常模式：「選擇或管理客戶」
  - 排序模式：「拖動以重新排序」（橙色）
- **操作按鈕**（從左到右）：
  - ➕ **新增客戶**：綠色圓形圖標（size 22），點擊開啟新增表單
  - 📋 **排序按鈕**：切換拖拽排序模式
    - 未啟用：藍色「排序」+ 箭頭圖標
    - 已啟用：綠色「完成」+ 勾選圖標
  - ✕ **關閉按鈕**：灰色圓形背景

#### 3. 客戶列表設計

##### 視覺風格
- **卡片樣式**：
  - 圓角：12pt
  - 間距：8pt
  - 內邊距：水平 16pt，垂直 14pt
  - 背景：未選中時半透明灰色（systemGray6, opacity 0.5）
  - 選中背景：淡藍色（blue opacity 0.08）
  - 選中邊框：藍色半透明邊框（opacity 0.3, width 1.5pt）

##### 卡片內容
每個客戶卡片包含：
- **客戶名稱**：
  - 字體：17pt, semibold
  - 顏色：primary
  - 位置：左側
- **選中指示器**：
  - 圖標：checkmark.circle.fill
  - 大小：18pt
  - 顏色：藍色
  - 位置：右側（僅選中時顯示）
- **Email**（選填）：
  - 字體：caption
  - 顏色：secondary
- **創建時間**：
  - 格式：🕐 時鐘圖標 + 日期時間
  - 字體：caption2
  - 顏色：secondary（opacity 0.8）

#### 4. 互動功能

##### 點擊操作
- **單擊**：選擇客戶並關閉面板，切換到該客戶的詳情頁面
- **長按**：顯示上下文選單（Context Menu）
  - 📝 編輯客戶
  - 🗑️ 刪除客戶（紅色，destructive role）

##### 刪除確認
- **Alert 對話框**：
  - 標題：「刪除客戶」
  - 訊息：「確定要刪除客戶 '{客戶名稱}' 嗎？這個操作無法撤銷。」
  - 按鈕：取消 / 刪除（紅色）

##### 編輯模式
- **觸發**：長按選單選擇「編輯客戶」
- **UI 變化**：
  - 卡片變為編輯狀態
  - 顯示文字輸入框
  - 右側顯示 ✓ 保存 和 ✕ 取消按鈕
  - 卡片背景：淡黃色（yellow opacity 0.1）
  - 邊框：橙色（width 2pt）
- **自動聚焦**：文字框自動取得焦點

#### 5. 拖拽排序模式

##### 啟用方式
點擊頂部「排序」按鈕，切換到拖拽模式

##### UI 變化
- **列表切換**：從 ScrollView 切換到 List
- **拖拽指示器**：每個客戶卡片左側顯示
  - 圖標：三條橫線（line.3.horizontal）
  - 文字：「拖動」（8pt）
  - 顏色：橙色
- **卡片樣式**：
  - 背景：橙色半透明（opacity 0.05）
  - 邊框：橙色半透明（opacity 0.5）
  - 選中時：藍色背景和邊框

##### 排序邏輯
- **拖動**：使用 `.onMove(perform: moveClients)`
- **持久化**：
  - 更新每個客戶的 `sortOrder` 屬性
  - 立即保存到 Core Data
  - 自動同步到 iCloud
- **排序規則**：
  - 主要：`sortOrder`（升序）
  - 次要：`createdDate`（升序）

#### 6. 狀態管理

##### 關鍵狀態變數
```swift
@State private var showingClientPanel = false      // 控制面板顯示
@State private var showingAddCustomer = false      // 控制新增表單
@State private var editingClient: Client?          // 正在編輯的客戶
@State private var isDragModeEnabled = false       // 拖拽模式開關
@State private var clientsArray: [Client] = []     // 客戶列表數組
```

##### FetchRequest 配置
```swift
@FetchRequest(
    sortDescriptors: [
        NSSortDescriptor(keyPath: \Client.sortOrder, ascending: true),
        NSSortDescriptor(keyPath: \Client.createdDate, ascending: true)
    ],
    animation: .default
)
private var clients: FetchedResults<Client>
```

### 技術實作細節

#### 1. 動畫與過渡
```swift
// 面板進入/退出動畫
.transition(.move(edge: .leading))
.animation(.easeInOut(duration: 0.3))

// 面板層級
.zIndex(1000)
```

#### 2. 背景遮罩
```swift
Color.black.opacity(0.4)
    .ignoresSafeArea()
    .onTapGesture {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingClientPanel = false
        }
    }
```

#### 3. 長按選單
```swift
.contextMenu {
    Button(action: { /* 編輯 */ }) {
        Label("編輯客戶", systemImage: "pencil")
    }
    Button(role: .destructive, action: { /* 刪除 */ }) {
        Label("刪除客戶", systemImage: "trash")
    }
}
```

#### 4. iCloud 同步
所有操作（新增、編輯、刪除、排序）都會：
1. 更新 Core Data context
2. 調用 `try viewContext.save()`
3. 調用 `PersistenceController.shared.save()`
4. 自動推送到 iCloud

### 設計原則

1. **簡潔優先**：移除不必要的視覺元素（如頭像圓圈），保持介面清爽
2. **輕量陰影**：使用極輕的陰影效果，避免視覺負擔
3. **清晰反饋**：選中、編輯、拖拽等狀態都有明確的視覺回饋
4. **iOS 原生體驗**：使用 Context Menu、Alert 等 iOS 標準元件
5. **流暢動畫**：所有狀態變化都帶有平滑的動畫效果

### 響應式設計

- **面板寬度**：`min(UIScreen.main.bounds.width * 0.75, 320)`
- **適配 iPhone 和 iPad**：自動調整寬度
- **支援 Dark Mode**：使用系統顏色（systemBackground、systemGray6 等）

---

## 保險管理功能

### 功能概述

保險管理系統是投資儀表板的重要組成部分，專門用於追蹤和管理客戶的保險資料，包括壽險、醫療險、意外險和投資型保險。該功能提供完整的保單管理、類型分布統計、以及詳細的保險明細追蹤。

**主要特點：**
- 📊 保險總價值統計與走勢追蹤
- 🥧 保單類型分布圓餅圖視覺化
- 📋 詳細的保險明細表格管理
- 🔄 與資產配置自動整合
- 📱 響應式設計支援 iPad 和 iPhone

### 導航結構

**入口位置：** 在客戶詳情頁面（ContentView）右上角，「+」按鈕左側新增「保單」按鈕

**導航方式：**
- 點擊「保單」按鈕進入保險管理頁面
- 使用狀態管理（非 sheet 模式）實現主畫面切換
- 頂部顯示自定義導航欄，包含返回按鈕、標題（保單管理 + 客戶名稱）、以及新增按鈕

**技術實作：**
```swift
// ContentView.swift
@State private var showingInsurancePolicy = false

// 保單按鈕
Button(action: {
    showingInsurancePolicy = true
}) {
    Text("保單")
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(8)
}

// 條件式視圖切換
if showingInsurancePolicy {
    InsurancePolicyView(
        client: selectedClient,
        onBack: {
            withAnimation {
                showingInsurancePolicy = false
            }
        }
    )
} else {
    ClientDetailView(client: selectedClient)
}
```

### 頁面結構

#### 1. 保險總額大卡

顯示客戶的保險投資組合總覽，包含關鍵統計數據和走勢圖。

**組成元素：**
1. **標題區域**
   - 顯示「保險總價值」
   - 顯示總價值金額（大字體）

2. **時間篩選按鈕**
   - ALL（全部）
   - 7D（7天）
   - 1M（1個月）
   - 3M（3個月）
   - 1Y（1年）

3. **2x2 統計卡片**
   - 保單數量：顯示客戶擁有的保單總數
   - 年繳總額：每年需繳納的保費總額
   - 月繳總額：每月需繳納的保費總額
   - 保障額度：所有保單的保額總和

4. **保障額度走勢圖區域**

顯示保障額度隨保險年齡變化的趨勢，支援即時互動查看特定年齡的保障金額。

**主要功能：**
- ✅ **點擊/拖動互動**：在走勢圖上滑動手指，即時顯示該年齡的保障額度
- ✅ **自動隱藏**：手指放開後，資料點資訊顯示 5 秒後自動隱藏
- ✅ **視覺回饋**：
  - 垂直虛線指示器標記選中的年齡
  - 圓形標記點（白色填充，綠色外框）
  - 浮動標籤顯示年齡和保障金額
- ✅ **幣別同步**：自動根據選擇的幣別（美金/台幣）轉換顯示金額
- ✅ **漸層填充**：走勢線下方使用粉紅色漸層填充

**狀態變數**（InsurancePolicyView.swift: 35-39）：
```swift
// 走勢圖互動
@State private var selectedAge: Int? = nil
@State private var selectedDeathBenefit: Double? = nil
@State private var ageDeathBenefitCache: [Int: Double] = [:]
@State private var hideDataPointWorkItem: DispatchWorkItem? = nil
```

**互動功能實作**（InsurancePolicyView.swift: 636-654）：
```swift
.gesture(
    DragGesture(minimumDistance: 0)
        .onChanged { value in
            // 取消之前的隱藏任務
            hideDataPointWorkItem?.cancel()
            updateSelectedPoint(at: value.location, in: geometry.size)
        }
        .onEnded { _ in
            // 5秒後自動隱藏數據點
            let workItem = DispatchWorkItem {
                withAnimation {
                    selectedAge = nil
                    selectedDeathBenefit = nil
                }
            }
            hideDataPointWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)
        }
)
```

**視覺覆蓋層**（InsurancePolicyView.swift: 630-633）：
```swift
// 選中點的標記和數值
if let age = selectedAge, let benefit = selectedDeathBenefit {
    selectedPointOverlay(age: age, benefit: benefit, in: geometry.size)
}
```

**技術特點**：
- ✅ **DispatchWorkItem**：使用可取消的任務，避免重複執行隱藏動畫
- ✅ **動畫過渡**：使用 `withAnimation` 提供平滑的淡出效果
- ✅ **即時取消**：每次新的滑動都會取消之前的隱藏任務，計時器重新開始
- ✅ **數據快取**：使用 `ageDeathBenefitCache` 快取計算結果，提升效能
- ✅ **多保單聚合**：自動加總所有保單在該年齡的保障額度

**使用方式**：
1. 在保障額度走勢圖上滑動手指
2. 系統自動計算最接近的年齡點
3. 顯示垂直指示線和圓形標記
4. 浮動標籤顯示該年齡的總保障額度
5. 手指放開後，資訊持續顯示 5 秒
6. 5 秒後自動隱藏，保持畫面清爽

**程式碼位置：**
- 走勢圖主體：`InsurancePolicyView.swift:614-663`
- 互動手勢處理：第 636-654 行
- 視覺覆蓋層：第 630-633 行
- 數據點更新函數：第 899-955 行

**卡片規格：**
- 圓角：20
- 內邊距：20
- 背景：白色帶陰影
- 尺寸：與主儀表板的總額大卡一致

**程式碼位置：** `InsurancePolicyView.swift:125-185`

#### 2. 保單類型分布區域

採用與主儀表板相同的佈局：左側圓餅圖 + 右側四張類型卡片

**左側：保單類型分布圓餅圖卡片**

- **圓餅圖組成**
  - 壽險：40%（紅色漸層）
  - 醫療險：30%（藍色漸層）
  - 意外險：20%（綠色漸層）
  - 投資型：10%（橙色漸層）

- **中心顯示**
  - 最高佔比百分比（40%）
  - 對應類型名稱（壽險）

- **圖例區域**
  - 顏色圓點 + 類型名稱 + 百分比
  - 四種保險類型依序排列

- **卡片規格**
  - 最大寬度：380
  - 最大高度：585
  - 圓餅圖內容高度：455
  - 與資產配置卡片大小一致

**右側：四張保險類型卡片**

每張卡片包含：
1. **圖標區域**
   - 壽險：heart.fill（愛心）
   - 醫療險：cross.case.fill（醫療箱）
   - 意外險：exclamationmark.shield.fill（警示盾牌）
   - 投資型：chart.line.uptrend.xyaxis（上升趨勢圖）

2. **資訊區域**
   - 保險類型名稱
   - 該類型的總金額

3. **走勢圖佔位**
   - 顯示「走勢」標籤的矩形區域

**卡片規格：**
- 高度：120
- 內邊距：20
- 圓角：20
- 與美股、台股、債券、每月配息卡片大小一致

**響應式佈局：**
```swift
if geometry.size.width > 600 {
    // iPad 佈局：左右並排
    HStack(alignment: .top, spacing: 16) {
        insurancePieChartCard
        VStack(spacing: 16) {
            // 四張保險類型卡片
        }
    }
} else {
    // iPhone 佈局：垂直堆疊
    VStack(spacing: 16) {
        insurancePieChartCard
        // 四張保險類型卡片
    }
}
```

**程式碼位置：**
- 圓餅圖卡片：`InsurancePolicyView.swift:227-340`
- 類型卡片：`InsurancePolicyView.swift:359-400`

#### 3. 保險明細表格

採用與月度資產明細相同的橫向滾動表格設計，包含 10 個欄位。

**表格欄位：**

| 欄位名稱 | 寬度 | 對齊方式 | 說明 |
|---------|------|---------|------|
| 保險種類 | 120 | 左對齊 | 壽險、醫療險、意外險、投資型 |
| 保險公司 | 120 | 左對齊 | 保險公司名稱 |
| 保單號碼 | 150 | 左對齊 | 保單編號（如 POL-0001） |
| 保險名稱 | 150 | 左對齊 | 保單商品名稱 |
| 被保險人 | 120 | 左對齊 | 被保險人姓名 |
| 保單始期 | 120 | 左對齊 | 保單生效日期 |
| 繳費月份 | 100 | 置中 | 每月繳費月份（1-12） |
| 保額 | 120 | 右對齊 | 保障金額 |
| 年繳保費 | 120 | 右對齊 | 年度保費金額 |
| 繳費年期 | 100 | 置中 | 繳費期限（年數） |

**視覺設計：**
- 表頭：灰色背景（systemGray6）+ 粗體字
- 資料行：交替顯示白色和淡灰色背景
- 水平滾動：支援寬表格橫向瀏覽
- 圓角：12
- 字體大小：表頭 14pt、資料 13pt

**程式碼位置：**
- 表格容器：`InsurancePolicyView.swift:403-438`
- 表頭：`InsurancePolicyView.swift:442-497`
- 資料行：`InsurancePolicyView.swift:500-545`

### 與資產配置整合

保險資料已整合到客戶詳情頁面的資產配置圓餅圖中。

**整合方式：**

1. **MonthlyAsset 實體新增欄位**
   - `insurance`: 保險金額（String）
   - `fund`: 基金金額（String）

2. **資產配置圓餅圖更新**
   - 原有 6 種資產類型：美股、債券、美金、台幣、台股、結構型
   - 新增 2 種資產類型：保險、基金
   - 共 8 種資產類型

3. **百分比計算函數**
```swift
// CustomerDetailView.swift
private func getInsurancePercentage() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let insuranceStr = latestAsset.insurance,
          let totalStr = latestAsset.totalAssets,
          let insurance = Double(insuranceStr),
          let total = Double(totalStr),
          total > 0 else {
        return 0.0
    }
    return (insurance / total) * 100
}

private func getFundPercentage() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let fundStr = latestAsset.fund,
          let totalStr = latestAsset.totalAssets,
          let fund = Double(fundStr),
          let total = Double(totalStr),
          total > 0 else {
        return 0.0
    }
    return (fund / total) * 100
}
```

4. **智能百分比顯示**
   - ≥ 1%：顯示整數（如「5%」）
   - < 1%：顯示兩位小數（如「0.25%」）
   - = 0%：不顯示在圖例中

```swift
private func formatPercentage(_ percentage: Double) -> String {
    if percentage >= 1.0 {
        return String(format: "%.0f%%", percentage)
    } else if percentage > 0 {
        return String(format: "%.2f%%", percentage)
    } else {
        return "0%"
    }
}
```

5. **條件式圖例顯示**
```swift
if getFundPercentage() > 0 {
    simpleLegendItem(color: ..., title: "基金", percentage: formatPercentage(getFundPercentage()))
}
if getInsurancePercentage() > 0 {
    simpleLegendItem(color: ..., title: "保險", percentage: formatPercentage(getInsurancePercentage()))
}
```

**修改檔案：** `CustomerDetailView.swift:968-1000, 1674-1729`

### 資料流程（待實作）

目前保險管理功能使用佔位資料，完整的 Core Data 整合尚待開發。

**未來實作計劃：**

1. **建立 InsurancePolicy 實體**
```xml
<entity name="InsurancePolicy" representedClassName="InsurancePolicy" syncable="YES">
    <attribute name="insuranceType" attributeType="String"/>      <!-- 保險種類 -->
    <attribute name="insuranceCompany" attributeType="String"/>   <!-- 保險公司 -->
    <attribute name="policyNumber" attributeType="String"/>       <!-- 保單號碼 -->
    <attribute name="policyName" attributeType="String"/>         <!-- 保險名稱 -->
    <attribute name="insuredPerson" attributeType="String"/>      <!-- 被保險人 -->
    <attribute name="policyStartDate" attributeType="String"/>    <!-- 保單始期 -->
    <attribute name="paymentMonth" attributeType="String"/>       <!-- 繳費月份 -->
    <attribute name="coverageAmount" attributeType="String"/>     <!-- 保額 -->
    <attribute name="annualPremium" attributeType="String"/>      <!-- 年繳保費 -->
    <attribute name="paymentPeriod" attributeType="String"/>      <!-- 繳費年期 -->
    <attribute name="createdDate" attributeType="Date"/>
    <relationship name="client" maxCount="1" deletionRule="Nullify"
                 destinationEntity="Client" inverseName="insurancePolicies"/>
</entity>
```

2. **更新 Client 實體關聯**
```xml
<relationship name="insurancePolicies" toMany="YES" deletionRule="Cascade"
             destinationEntity="InsurancePolicy" inverseName="client"/>
```

3. **實作 CRUD 操作**
   - 新增保單資料
   - 編輯保單資料
   - 刪除保單資料
   - CloudKit 同步

4. **連接計算函數**
   - `getTotalInsuranceValue()`: 計算所有保單的總價值
   - `getPolicyCount()`: 統計保單數量
   - `getAnnualPremium()`: 計算年繳總額
   - `getMonthlyPremium()`: 計算月繳總額
   - `getTotalCoverage()`: 計算總保障額度

5. **動態圓餅圖數據**
   - 根據實際保單資料計算各類型佔比
   - 動態更新圓餅圖顏色和百分比

### 技術特點

1. **狀態管理導航**
   - 使用 `@State` 變數控制視圖切換
   - 非模態（non-modal）導航體驗
   - 保持在主畫面層級

2. **條件式 UI 渲染**
   - 根據螢幕寬度調整佈局（iPad vs iPhone）
   - 根據資料百分比決定是否顯示圖例項目
   - 智能百分比格式化

3. **一致的設計語言**
   - 卡片尺寸與主儀表板保持一致
   - 圓角、陰影、字體規格統一
   - 顏色系統對應不同保險類型

4. **可擴展架構**
   - 預留 Core Data 整合接口
   - TODO 註解標示待實作功能
   - 模組化元件設計

### 檔案清單

**新增檔案：**
- `InsurancePolicyView.swift` - 保險管理完整介面（新增）

**修改檔案：**
- `ContentView.swift` - 添加保單按鈕和導航邏輯
- `CustomerDetailView.swift` - 資產配置整合保險和基金

### 使用情境

1. **查看客戶保險概況**
   - 從客戶詳情頁點擊「保單」按鈕
   - 查看保險總價值和各項統計
   - 瀏覽保單類型分布

2. **管理保單明細**
   - 查看所有保單的詳細資訊
   - 橫向滾動查看完整欄位
   - 比較不同保單的條件

3. **追蹤保費支出**
   - 監控年繳和月繳總額
   - 規劃保費預算
   - 評估保障額度

4. **資產配置分析**
   - 在主儀表板查看保險在總資產中的佔比
   - 與其他投資類型比較
   - 調整資產配置策略

### 注意事項

1. **資料完整性**
   - 目前使用佔位數據
   - 實際使用前需完成 Core Data 整合
   - 確保欄位驗證和錯誤處理

2. **CloudKit 同步**
   - InsurancePolicy 實體需添加到 CloudKit schema
   - 設定適當的索引和權限
   - 測試跨設備同步

3. **效能優化**
   - 大量保單資料時考慮分頁載入
   - 圓餅圖計算快取
   - 表格虛擬化渲染

4. **未來功能**
   - 保單到期提醒
   - 繳費記錄追蹤
   - 理賠記錄管理
   - 保單文件上傳

## 貸款管理功能（2025-11-10）

完整的貸款追蹤與利率調整管理系統，支援多期利率變動記錄。

### 核心功能

#### 1. 貸款基本管理
- **貸款資訊**
  - 貸款類型（房貸、車貸、信用貸款、學生貸款、其他）
  - 貸款名稱
  - 貸款金額（千分位格式）
  - 初始利率
  - 貸款期限（年）
  - 開始日期 / 結束日期
  - 初始月付金

- **智能日期計算**
  - 輸入開始日期和貸款期限，自動計算結束日期
  - 輸入開始和結束日期，自動計算貸款期限
  - 防止循環更新的邏輯保護

#### 2. 利率調整記錄（核心功能）

**設計理念：**
貸款在不同時期可能因利率調整而改變月付金。系統使用時間軸方式追蹤每一期的利率和月付金變化。

**利率調整包含：**
- 調整日期（生效日期）
- 新利率（調整後的年利率）
- 新月付金（用戶直接輸入，不自動計算）
- 當時剩餘本金
- 備註說明

**期數邏輯：**
- **第 1 期**：貸款開始日期 → 第一次調整日期（或貸款結束日期）
  - 使用初始利率和月付金
  - 永遠顯示（即使沒有利率調整）

- **第 2 期開始**：每次利率調整都會產生新的期數
  - 第 N 期調整日期 → 第 N+1 期調整日期（或貸款結束日期）
  - 使用調整後的新利率和新月付金

**時間軸顯示（參考提醒頁面設計）：**
```
🔸 第 1 期
📅 2025/01/01 → 2030/01/01 | $30,000

🔸 第 2 期
📅 2030/01/01 → 2035/01/01 | $32,000

🔸 第 3 期
📅 2035/01/01 → 2055/01/01 | $33,500
```

### 檔案結構

```
InvestmentDashboard/
├── LoanManagementView.swift           # 貸款管理主頁面
│   ├── 貸款總覽卡片（總額、每月還款）
│   ├── 貸款列表
│   │   ├── 貸款類型標籤 + 名稱
│   │   ├── 貸款金額 | 利率 | 期限
│   │   ├── 每月還款
│   │   └── 利率調整時間軸（包含第 1 期）
│   └── 新增貸款按鈕
├── LoanDetailView.swift               # 貸款詳情頁面（Sheet）
│   ├── 貸款基本資訊卡片
│   └── 利率調整歷史（完整時間軸）
├── AddLoanView.swift                  # 新增/編輯貸款
│   ├── 基本資訊表單
│   ├── 智能日期計算
│   └── 千分位格式化
└── AddLoanRateAdjustmentView.swift    # 新增利率調整
    ├── 調整日期
    ├── 新利率
    ├── 新月付金（用戶輸入）
    ├── 剩餘本金
    └── 備註
```

### Core Data 模型

#### Loan 實體
```swift
entity Loan {
    loanType: String              // 貸款類型
    loanName: String              // 貸款名稱
    loanAmount: String            // 貸款金額
    interestRate: String          // 初始利率
    loanTerm: String              // 貸款期限（年）
    startDate: String             // 開始日期
    endDate: String               // 結束日期
    monthlyPayment: String        // 初始月付金
    totalPaid: String             // 已還款總額
    remainingBalance: String      // 剩餘本金
    notes: String                 // 備註
    createdDate: Date             // 建立日期

    // 關聯
    client: Client                // 所屬客戶
    rateAdjustments: [LoanRateAdjustment]  // 利率調整記錄（一對多）
}
```

#### LoanRateAdjustment 實體
```swift
entity LoanRateAdjustment {
    adjustmentDate: String        // 調整日期（字串格式 YYYY-MM-DD）
    adjustmentDateAsDate: Date    // 調整日期（Date 格式，用於排序）
    newInterestRate: String       // 新利率
    newMonthlyPayment: String     // 新月付金
    remainingBalance: String      // 當時剩餘本金
    notes: String                 // 備註
    createdDate: Date             // 建立日期

    // 關聯
    loan: Loan                    // 所屬貸款
}
```

### UI/UX 設計重點

#### 1. 貸款列表卡片
```
┌─────────────────────────────────────┐
│ 房貸  123            🔵 1 次調整  ⋯ │
│                                     │
│ 貸款金額    利率      貸款期限      │
│ 19,000,000  2.7%     30年         │
│                                     │
│ 每月還款                            │
│ 50,000                              │
│ ─────────────────────────────────   │
│ 🔸 第 1 期                          │
│ 2025/01/01 → 2030/01/01 | $50,000  │
│                                     │
│ 🔸 第 2 期                          │
│ 2030/01/01 → 2055/01/01 | $52,000  │
│                                     │
│            點擊查看詳情 →            │
└─────────────────────────────────────┘
```

#### 2. 貸款詳情頁面（Sheet）
- **導航標題**：貸款名稱
- **右上角**：+ 按鈕（新增利率調整）
- **內容區域**：
  1. 貸款基本資訊卡片（完整資訊）
  2. 利率調整歷史（時間軸格式，含刪除功能）

#### 3. 時間軸設計元素
- **左側**：橘色圓點 + 灰色連接線
- **右側內容**：
  - 期數標籤（綠色文件圖示）
  - 日期範圍（箭頭格式）
  - 新月付金（橘色強調）
  - 備註（如有）

### 技術實作細節

#### 1. 即時更新
```swift
// LoanDetailView 使用 @ObservedObject 監聽變化
@ObservedObject var loan: Loan

// 新增調整記錄後自動更新列表
try viewContext.save()
PersistenceController.shared.save()
```

#### 2. 排序邏輯
```swift
// 利率調整按日期排序
let sortedAdjustments = adjustments.sorted { adj1, adj2 in
    if let date1 = adj1.adjustmentDateAsDate,
       let date2 = adj2.adjustmentDateAsDate {
        return date1 < date2  // 升序排列
    }
    return (adj1.adjustmentDate ?? "") < (adj2.adjustmentDate ?? "")
}
```

#### 3. 千分位格式化
```swift
private func formatNumber(_ value: String) -> String {
    guard let number = Double(value.replacingOccurrences(of: ",", with: "")) else {
        return value
    }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: number)) ?? value
}
```

### 使用場景範例

**場景：30 年房貸，期間有 2 次利率調整**

1. **初始貸款（2025/01/01）**
   - 貸款金額：$19,000,000
   - 初始利率：2.7%
   - 月付金：$50,000
   - 期限：30 年

2. **第一次調整（2030/01/01）**
   - 新利率：3.0%
   - 新月付金：$52,000
   - 剩餘本金：$17,500,000

3. **第二次調整（2035/01/01）**
   - 新利率：3.2%
   - 新月付金：$53,500
   - 剩餘本金：$15,800,000

**時間軸顯示：**
```
第 1 期: 2025/01/01 → 2030/01/01 | $50,000  (初始利率 2.7%)
第 2 期: 2030/01/01 → 2035/01/01 | $52,000  (調整至 3.0%)
第 3 期: 2035/01/01 → 2055/01/01 | $53,500  (調整至 3.2%)
```

### 設計考量

1. **不自動計算月付金**
   - 不同銀行的貸款公式可能不同
   - 可能包含各種費用和保險
   - 讓用戶直接輸入實際應繳金額更準確

2. **永遠顯示第 1 期**
   - 即使沒有利率調整，也要顯示初始期數
   - 讓用戶清楚了解貸款的完整時間軸

3. **時間軸視覺設計**
   - 參考提醒功能的設計語言
   - 橘色圓點代表時間節點
   - 箭頭格式清楚表達時間範圍

4. **Sheet vs NavigationLink**
   - 使用 Sheet 彈出詳情頁，避免 iPad 雙欄問題
   - 保持與其他功能（保險管理）的一致性

### CloudKit 索引設定

#### CD_Loan 索引
```
索引 1:
- Field: createdDate
- Type: SORTABLE
- Order: DESCENDING

索引 2:
- Field: CD_client
- Type: QUERYABLE
```

#### CD_LoanRateAdjustment 索引
```
索引 1:
- Field: adjustmentDateAsDate
- Type: SORTABLE
- Order: ASCENDING

索引 2:
- Field: CD_loan
- Type: QUERYABLE
```

### 後續可能的功能擴充

1. **提前還款記錄**
   - 追蹤提前還款金額
   - 自動調整剩餘本金

2. **還款計劃表**
   - 計算每期本金和利息分配
   - 顯示累計已付利息

3. **還款提醒**
   - 整合到提醒系統
   - 每月自動提醒繳款

4. **多種計算模式**
   - 本息平均攤還
   - 本金平均攤還
   - 只繳利息

---

## 最新更新（2025-10-31）

### 1. 美股價格自動更新功能

新增了美股現價自動更新功能，使用 Yahoo Finance API 批量獲取最新股價，並自動重新計算市值、損益和報酬率。

**功能特點：**
- 🔄 **一鍵更新**：點擊刷新按鈕批量更新所有股票的現價
- ✏️ **保留手動輸入**：仍可隨時手動修改現價欄位
- 📊 **自動計算**：更新現價後自動重新計算市值、損益、報酬率
- 🌐 **Yahoo Finance API**：使用免費的 Yahoo Finance 數據源
- ⚡ **並發請求**：使用 Swift Concurrency 並發獲取多支股票價格，提高效率

**使用方式：**
1. 在「股票名稱」欄位輸入股票代碼（如：AAPL, TSLA, NVDA）
2. 點擊綠色刷新按鈕（位於排序按鈕左側）
3. 系統自動獲取最新價格並更新所有相關計算

**技術實作：**

1. **StockPriceService.swift** - 股價獲取服務
```swift
class StockPriceService {
    // 獲取單個股票價格
    func fetchStockPrice(symbol: String) async throws -> String

    // 批量獲取多個股票價格（並發）
    func fetchMultipleStockPrices(symbols: [String]) async -> [String: String]
}
```

2. **USStockDetailView.swift** - 界面更新
```swift
// 新增狀態變數
@State private var isRefreshing = false  // 刷新狀態
@State private var showingRefreshAlert = false  // 結果提示
@State private var refreshMessage = ""  // 結果消息

// 刷新按鈕（位於排序按鈕左側）
Button(action: { refreshAllStockPrices() }) {
    if isRefreshing {
        ProgressView()  // 顯示載入中
    } else {
        Image(systemName: "arrow.clockwise")
            .foregroundColor(.green)
    }
}
```

3. **刷新邏輯流程**
```swift
private func refreshAllStockPrices() {
    // 1. 收集所有股票代碼（從 name 欄位）
    let symbols = usStocks.compactMap { $0.name?.uppercased() }

    // 2. 批量獲取股價（並發）
    let prices = await StockPriceService.shared.fetchMultipleStockPrices(symbols: symbols)

    // 3. 更新現價並重新計算
    for stock in usStocks {
        if let newPrice = prices[stock.name] {
            stock.currentPrice = newPrice
            recalculateStock(stock: stock)  // 自動計算市值、損益、報酬率
        }
    }

    // 4. 保存到 Core Data 和 iCloud
    try viewContext.save()
    PersistenceController.shared.save()

    // 5. 顯示更新結果
    showingRefreshAlert = true
}
```

**API 資訊：**
- **數據源**：Yahoo Finance Public API
- **請求格式**：`https://query1.finance.yahoo.com/v8/finance/chart/{SYMBOL}?interval=1d&range=1d`
- **回傳資料**：JSON 格式，包含 `regularMarketPrice` 欄位
- **費用**：免費使用（無需 API Key）
- **限制**：無官方限制，建議合理使用避免過於頻繁請求

**錯誤處理：**
- 無效的股票代碼：跳過並繼續處理其他股票
- 網路錯誤：顯示錯誤訊息並標示失敗數量
- 完成後顯示結果摘要：「成功更新 X 個股票，Y 個失敗」

**影響檔案：**
- 新增：`StockPriceService.swift` - 股價獲取服務
- 修改：`USStockDetailView.swift` - 添加刷新按鈕和邏輯

### 2. 結構型商品價格自動更新功能

為結構型明細（僅進行中）新增股價自動更新功能，從「標的」欄位讀取股票代碼並批量更新現價。

**功能特點：**
- 🔄 **僅進行中商品支援**：只有進行中表格有刷新按鈕（已出場商品不需要股價更新）
- 🎯 **多標的支援**：自動識別 1-3 個標的並分別更新對應的現價
- ✏️ **保留手動輸入**：仍可隨時手動修改現價欄位
- 🌐 **複用服務**：使用相同的 StockPriceService 服務
- ⚡ **智能映射**：自動將股票代碼映射到對應的 currentPrice1/2/3

**使用方式：**
1. 在「標的」欄位輸入股票代碼（如：AAPL, TSLA, SPY）
2. 點擊綠色刷新按鈕（位於進行中表格的排序按鈕左側）
3. 系統自動獲取所有標的的最新價格並更新對應的現價欄位

**技術實作：**

1. **狀態管理**
```swift
@State private var isRefreshingOngoing = false  // 進行中商品刷新狀態
@State private var showingRefreshAlert = false  // 刷新結果提示
@State private var refreshMessage = ""  // 刷新結果消息
```

2. **刷新按鈕（僅進行中表格顯示）**
```swift
Button(action: { refreshOngoingPrices() }) {
    if isRefreshingOngoing {
        ProgressView()  // 顯示載入中
    } else {
        Image(systemName: "arrow.clockwise")
            .foregroundColor(.green)
    }
}
```

3. **標的映射邏輯**
```swift
// 收集所有標的代碼並建立映射關係
var symbolMap: [String: [(product: StructuredProduct, index: Int)]] = [:]

for product in ongoingProducts {
    // target1 -> currentPrice1
    if let target1 = product.target1, !target1.isEmpty {
        symbolMap[target1.uppercased(), default: []].append((product, 1))
    }
    // target2 -> currentPrice2
    if let target2 = product.target2, !target2.isEmpty {
        symbolMap[target2.uppercased(), default: []].append((product, 2))
    }
    // target3 -> currentPrice3
    if let target3 = product.target3, !target3.isEmpty {
        symbolMap[target3.uppercased(), default: []].append((product, 3))
    }
}
```

4. **批量更新現價**
```swift
// 批量獲取股價
let prices = await StockPriceService.shared.fetchMultipleStockPrices(symbols: symbols)

// 更新對應的現價欄位
for (symbol, mappings) in symbolMap {
    if let newPrice = prices[symbol] {
        for mapping in mappings {
            switch mapping.index {
            case 1: mapping.product.currentPrice1 = newPrice
            case 2: mapping.product.currentPrice2 = newPrice
            case 3: mapping.product.currentPrice3 = newPrice
            }
        }
    }
}
```

**智能特性：**
- 自動去除標的代碼的空格並轉換為大寫
- 相同標的在多個商品中出現時，一次請求更新所有
- 顯示成功更新的標的數量和失敗數量

**影響檔案：**
- 修改：`StructuredProductsDetailView.swift` - 添加刷新按鈕和邏輯（僅進行中）

### 3. 台股價格與名稱自動更新功能

新增了台股現價和股票名稱自動更新功能，使用 Yahoo Finance API 批量獲取最新股價和中文股票名稱。

**功能特點：**
- 🔄 **一鍵更新**：點擊「更新股價」按鈕批量更新所有台股的現價和名稱
- 🏷️ **自動命名**：新增台股時自動從 Yahoo Finance 獲取中文股票名稱
- 📊 **自動計算**：更新現價後自動重新計算市值、損益、報酬率
- 🌐 **Yahoo Finance API**：使用免費的 Yahoo Finance 數據源
- 🇹🇼 **台股支援**：自動處理 .TW（上市）和 .TWO（上櫃）股票代碼

**使用方式：**

**方式一：新增股票時自動獲取名稱**
1. 在「新增台股」表單中輸入股票代碼（如：2330）
2. 點擊「新增持股」按鈕
3. 系統自動從 Yahoo Finance 獲取股票名稱（如：台積電）
4. 顯示時自動顯示中文名稱（上方）和代碼（下方）

**方式二：手動更新股價和名稱**
1. 在台股持倉明細視圖中點擊「更新股價」按鈕
2. 系統批量獲取所有台股的最新價格和名稱
3. 自動更新並重新計算所有相關數據

**顯示格式：**
```
台積電          ← 股票名稱（stockName，粗體顯示）
2330            ← 股票代碼（name，灰色小字）
```

**技術實作：**

1. **StockPriceService.swift** - 擴充股價服務支援股票名稱
```swift
// 擴充 Meta 結構以支援股票名稱
struct Meta: Codable {
    let regularMarketPrice: Double?
    let symbol: String?
    let longName: String?      // 完整股票名稱
    let shortName: String?     // 簡短股票名稱
}

// 獲取股票價格和名稱
func fetchStockInfo(symbol: String) async throws -> (price: String, name: String) {
    let result = try await fetchFromYahooFinance(symbol)
    let price = String(format: "%.2f", result.meta.regularMarketPrice)
    let name = result.meta.longName ?? result.meta.shortName ?? symbol
    return (price, name)
}

// 批量獲取多個股票的完整資訊
func fetchMultipleStockInfos(symbols: [String]) async -> [String: (price: String, name: String)]
```

2. **Core Data 模型更新**
```xml
<entity name="TWStock">
    <attribute name="name" attributeType="String"/>           <!-- 股票代碼 -->
    <attribute name="stockName" attributeType="String"/>      <!-- 股票名稱（新增）-->
    <attribute name="shares" attributeType="String"/>
    <attribute name="costPerShare" attributeType="String"/>
    <attribute name="currentPrice" attributeType="String"/>
    <!-- 其他欄位... -->
</entity>
```

3. **TWStockInventoryView.swift** - 股價更新邏輯
```swift
private func refreshStockPrices() {
    Task {
        // 收集所有台股代碼，添加 .TW 或 .TWO 後綴
        let symbols = twStocks.compactMap { stock -> String? in
            guard let symbol = stock.name else { return nil }
            return symbol.contains(".") ? symbol : "\(symbol).TW"
        }

        // 批量獲取股價和名稱
        let stockInfos = await StockPriceService.shared.fetchMultipleStockInfos(symbols: symbols)

        // 更新每個股票的現價和名稱
        for stock in twStocks {
            let symbolTW = "\(stock.name).TW"
            let symbolTWO = "\(stock.name).TWO"

            // 優先嘗試 .TW（上市），失敗則嘗試 .TWO（上櫃）
            if let info = stockInfos[symbolTW] ?? stockInfos[symbolTWO] {
                stock.currentPrice = info.price
                stock.stockName = info.name      // 更新股票名稱
                recalculateStock(stock: stock)
            }
        }

        // 保存到 Core Data
        try viewContext.save()
    }
}
```

4. **AddTWStockView** - 新增時自動獲取名稱
```swift
private func addStock() {
    let newStock = TWStock(context: viewContext)
    newStock.name = name  // 儲存股票代碼
    // ... 設定其他欄位

    // 自動獲取股票名稱
    Task {
        await fetchStockName(for: newStock)
    }

    try viewContext.save()
}

private func fetchStockName(for stock: TWStock) async {
    let symbolTW = "\(stock.name).TW"

    do {
        let info = try await StockPriceService.shared.fetchStockInfo(symbol: symbolTW)
        stock.stockName = info.name
        try viewContext.save()
    } catch {
        // 如果 .TW 失敗，嘗試 .TWO（上櫃）
        let symbolTWO = "\(stock.name).TWO"
        if let info = try? await StockPriceService.shared.fetchStockInfo(symbol: symbolTWO) {
            stock.stockName = info.name
            try viewContext.save()
        }
    }
}
```

5. **顯示邏輯**
```swift
// 股票名稱和代碼顯示
VStack(alignment: .leading, spacing: 2) {
    // 股票名稱（上方，粗體）
    Text(stock.stockName?.isEmpty == false ? stock.stockName! : (stock.name ?? "未知"))
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.primary)

    // 股票代號（下方，小字灰色）
    Text(stock.name ?? "")
        .font(.system(size: 12))
        .foregroundColor(.secondary)
}
```

**API 資訊：**
- **數據源**：Yahoo Finance Public API
- **台股格式**：需添加 `.TW`（上市）或 `.TWO`（上櫃）後綴
- **請求範例**：
  - 上市股票：`https://query1.finance.yahoo.com/v8/finance/chart/2330.TW`
  - 上櫃股票：`https://query1.finance.yahoo.com/v8/finance/chart/6547.TWO`
- **回傳資料**：包含 `regularMarketPrice`（現價）、`longName`（完整名稱）、`shortName`（簡稱）

**錯誤處理：**
- 自動嘗試 .TW 和 .TWO 後綴（上市/上櫃）
- 無效股票代碼：跳過並繼續處理其他股票
- 網路錯誤：顯示錯誤訊息並標示失敗數量
- 名稱獲取失敗：顯示股票代碼作為後備

**影響檔案：**
- 修改：`StockPriceService.swift` - 新增 `fetchStockInfo()` 和 `fetchMultipleStockInfos()` 方法
- 修改：`TWStockInventoryView.swift` - 更新股價邏輯支援名稱更新、新增時自動獲取名稱
- 修改：`TWStockLoanSyncSelectionView.swift` - 顯示邏輯支援股票名稱
- 修改：`DataModel.xcdatamodeld` - TWStock 實體新增 `stockName` 屬性

### 4. iPhone 響應式工具列佈局（美股/台股持倉視圖）

針對 iPhone 小螢幕優化美股和台股持倉視圖的工具列按鈕佈局，使用 Menu 選單解決按鈕過多導致顯示不全的問題。

**問題背景：**
- 原先在導航列右側橫向排列 4 個按鈕：月度同步、貸款同步、更新股價、新增持股
- iPhone 螢幕空間有限，導致部分按鈕被截斷或不顯示
- iPad 上顯示正常，但 iPhone 上使用體驗不佳

**解決方案：**
將前 3 個功能按鈕整合到 Menu 選單中，保留新增按鈕獨立顯示。

**新佈局：**
```
導航列右側：
┌─────────────────────────┐
│  [⋯ 選單]  [➕ 新增]     │
└─────────────────────────┘

點擊 ⋯ 選單後展開：
┌─────────────────────────┐
│ 🔄 同步至月度資產        │
│ 🏢 同步至貸款            │
│ ────────────            │
│ ↻  更新股價              │
└─────────────────────────┘
```

**技術實作：**

**修改前（橫向排列 4 個按鈕）：**
```swift
ToolbarItem(placement: .navigationBarTrailing) {
    HStack(spacing: 8) {
        // 月度同步按鈕
        Button(action: { showingSyncConfirmation = true }) {
            HStack { /* ... */ }
        }

        // 貸款同步按鈕
        Button(action: { showingLoanSyncSelection = true }) {
            HStack { /* ... */ }
        }

        // 更新股價按鈕
        Button(action: { showingRefreshConfirmation = true }) {
            HStack { /* ... */ }
        }

        // 新增按鈕
        Button(action: { addNewStock() }) {
            Image(systemName: "plus.circle.fill")
        }
    }
}
```

**修改後（Menu + 新增按鈕）：**
```swift
ToolbarItem(placement: .navigationBarTrailing) {
    HStack(spacing: 12) {
        // 功能選單
        Menu {
            // 同步到月度資產
            Button(action: { showingSyncConfirmation = true }) {
                Label("同步至月度資產", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(stocks.isEmpty)

            // 貸款同步
            Button(action: { showingLoanSyncSelection = true }) {
                Label("同步至貸款", systemImage: "building.columns")
            }
            .disabled(stocks.isEmpty)

            Divider()

            // 更新股價
            Button(action: { showingRefreshConfirmation = true }) {
                Label("更新股價", systemImage: "arrow.clockwise")
            }
            .disabled(stocks.isEmpty || isRefreshing)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 22))
                .foregroundColor(.blue)
        }

        // 新增按鈕（保持獨立顯示）
        Button(action: { addNewStock() }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.blue)
        }
    }
}
```

**優點：**
- ✅ iPhone 和 iPad 上都能正常顯示所有功能
- ✅ 減少導航列視覺雜亂
- ✅ 新增按鈕保持快速訪問（最常用操作）
- ✅ Menu 選單提供清晰的文字標籤（比小圖標更易理解）
- ✅ 自動支援深色模式和系統字體大小

**影響檔案：**
- 修改：`USStockInventoryView.swift` - 工具列按鈕改為 Menu 佈局
- 修改：`TWStockInventoryView.swift` - 工具列按鈕改為 Menu 佈局

### 5. 美股/台股小卡智能顯示邏輯（時間戳追蹤）

實作基於時間戳的智能顯示邏輯，解決「更新股價後小卡未更新報酬率」的用戶體驗問題。小卡會自動比較「股價更新時間」和「月度資產時間」，優先顯示較新的數據源。

**問題背景：**
- 原先小卡只從 MonthlyAsset（月度資產）讀取數據
- 用戶點擊「更新股價」後，持倉明細更新了，但小卡仍顯示舊的月度資產數據
- 用戶困惑：明明更新股價了，為什麼報酬率沒變？

**解決方案：**
追蹤兩個時間戳，自動選擇較新的數據源顯示。

**運作邏輯：**

```
┌─────────────────────────────────────────┐
│  用戶操作                               │
├─────────────────────────────────────────┤
│  1. 點擊「更新股價」                    │
│     → 記錄時間戳到 UserDefaults         │
│     → 小卡比較時間，顯示持倉明細        │
│                                         │
│  2. 點擊「月度同步」                    │
│     → 更新 MonthlyAsset.createdDate     │
│     → 小卡比較時間，顯示月度資產        │
└─────────────────────────────────────────┘

小卡顯示規則：
- 股價更新時間 > 月度資產時間 → 顯示持倉明細（即時數據）
- 月度資產時間 >= 股價更新時間 → 顯示月度資產（歷史快照）
```

**使用場景範例：**

| 日期 | 用戶操作 | 小卡顯示數據源 | 說明 |
|------|---------|---------------|------|
| 11/01 | 建立月度資產 | MonthlyAsset | 初始狀態，顯示月度快照 |
| 11/18 | 點擊「更新股價」 | **持倉明細**（即時） | 股價更新較新，立即顯示最新報酬率 ✅ |
| 11/25 | （未操作） | 持倉明細（即時） | 仍顯示 11/18 更新的即時數據 |
| 11/30 | 點擊「月度同步」 | MonthlyAsset | 月底同步較新，切換回月度資產 ✅ |

**技術實作：**

**1. 記錄股價更新時間（TWStockInventoryView.swift）**
```swift
private func refreshStockPrices() {
    Task {
        // ... 更新股價邏輯 ...

        if successCount > 0 {
            try viewContext.save()

            // ✅ 記錄股價更新時間
            if let client = client {
                let key = "twStockPriceUpdateTime_\(client.objectID.uriRepresentation().absoluteString)"
                UserDefaults.standard.set(Date(), forKey: key)
                print("✅ 已記錄台股價更新時間")
            }
        }
    }
}
```

**2. 記錄股價更新時間（USStockInventoryView.swift）**
```swift
private func refreshAllStockPrices() {
    Task {
        // ... 更新股價邏輯 ...

        if successCount > 0 {
            saveContext()

            // ✅ 記錄股價更新時間
            if let client = client {
                let key = "usStockPriceUpdateTime_\(client.objectID.uriRepresentation().absoluteString)"
                UserDefaults.standard.set(Date(), forKey: key)
                print("✅ 已記錄美股價更新時間")
            }
        }
    }
}
```

**3. 時間戳比較邏輯（CustomerDetailView.swift）**
```swift
/// 判斷是否應該使用持倉明細數據（基於時間戳比較）
private func shouldUseInventoryData(stockType: String) -> Bool {
    guard let client = client else { return false }

    // 1️⃣ 獲取股價更新時間
    let key = "\(stockType)StockPriceUpdateTime_\(client.objectID.uriRepresentation().absoluteString)"
    guard let priceUpdateTime = UserDefaults.standard.object(forKey: key) as? Date else {
        // 沒有股價更新記錄，使用月度資產
        return false
    }

    // 2️⃣ 獲取月度資產時間
    guard let latestAsset = monthlyAssets.first,
          let assetTime = latestAsset.createdDate else {
        // 沒有月度資產，使用持倉明細
        return true
    }

    // 3️⃣ 比較時間戳
    let useInventory = priceUpdateTime > assetTime

    if useInventory {
        print("📊 \(stockType == "us" ? "美股" : "台股")小卡：使用持倉明細數據（股價更新時間：\(priceUpdateTime) > 月度資產時間：\(assetTime)）")
    } else {
        print("📊 \(stockType == "us" ? "美股" : "台股")小卡：使用月度資產數據（月度資產時間：\(assetTime) >= 股價更新時間：\(priceUpdateTime)）")
    }

    return useInventory
}
```

**4. 美股小卡顯示邏輯**
```swift
private func getUSStockValue() -> Double {
    // 比較時間戳，選擇較新的數據源
    if shouldUseInventoryData(stockType: "us") {
        // 股價更新較新 → 使用持倉明細
        return getUSStockValueFromInventory()
    }

    // 月度資產較新 → 使用月度資產
    if let latestAsset = monthlyAssets.first,
       let usStockStr = latestAsset.usStock,
       let usStock = Double(usStockStr) {
        return usStock
    }

    return 0.0
}

private func getUSStockReturnRate() -> Double {
    // 比較時間戳，選擇較新的數據源
    if shouldUseInventoryData(stockType: "us") {
        // 股價更新較新 → 計算持倉明細報酬率
        return getUSStockReturnRateFromInventory()
    }

    // 月度資產較新 → 使用月度資產報酬率
    if let latestAsset = monthlyAssets.first,
       let usStockStr = latestAsset.usStock,
       let usStockCostStr = latestAsset.usStockCost,
       let usStock = Double(usStockStr),
       let usStockCost = Double(usStockCostStr),
       usStockCost > 0 {
        return ((usStock - usStockCost) / usStockCost) * 100
    }

    return 0.0
}
```

**5. 台股小卡顯示邏輯**
```swift
private func getTWStockValue() -> Double {
    // 比較時間戳，選擇較新的數據源
    if shouldUseInventoryData(stockType: "tw") {
        return getTWStockValueFromInventory()
    }

    if let latestAsset = monthlyAssets.first,
       let twStockStr = latestAsset.taiwanStock,
       let twStock = Double(twStockStr) {
        return twStock
    }

    return 0.0
}

private func getTWStockReturnRate() -> Double {
    // 比較時間戳，選擇較新的數據源
    if shouldUseInventoryData(stockType: "tw") {
        return getTWStockReturnRateFromInventory()
    }

    if let latestAsset = monthlyAssets.first,
       let twStockStr = latestAsset.taiwanStock,
       let twStockCostStr = latestAsset.taiwanStockCost,
       let twStock = Double(twStockStr),
       let twStockCost = Double(twStockCostStr),
       twStockCost > 0 {
        return ((twStock - twStockCost) / twStockCost) * 100
    }

    return 0.0
}
```

**數據流程圖：**

```
用戶點擊「更新股價」
    ↓
更新持倉明細 (USStock/TWStock)
    ↓
記錄時間戳到 UserDefaults
    ↓
小卡調用 shouldUseInventoryData()
    ↓
比較：股價更新時間 vs 月度資產時間
    ↓
┌─────────────┬─────────────────┐
│ 股價較新    │   月度資產較新   │
│    ↓        │        ↓        │
│ 使用持倉明細 │  使用月度資產    │
│ (即時數據)  │   (歷史快照)    │
└─────────────┴─────────────────┘
```

**時間戳儲存格式：**
- **Key**: `usStockPriceUpdateTime_<客戶ObjectID>` 或 `twStockPriceUpdateTime_<客戶ObjectID>`
- **Value**: Date 物件
- **儲存位置**: UserDefaults
- **用途**: 與 MonthlyAsset.createdDate 比較

**除錯日誌範例：**

```
✅ 已記錄美股價更新時間
📊 美股小卡：使用持倉明細數據（股價更新時間：2025-11-18 14:30:00 > 月度資產時間：2025-11-01 00:00:00）

✅ 已記錄台股價更新時間
📊 台股小卡：使用持倉明細數據（股價更新時間：2025-11-18 14:30:00 > 月度資產時間：2025-11-01 00:00:00）
```

**優點：**

✅ **完美用戶體驗**
- 點擊「更新股價」→ 小卡立即顯示最新報酬率
- 點擊「月度同步」→ 小卡顯示月度快照
- 無需手動選擇，系統自動判斷

✅ **邏輯清晰**
- 使用時間戳自動判斷，無歧義
- 兩個按鈕互不衝突
- 永遠顯示「最新」的數據

✅ **保留歷史記錄**
- 月度資產作為歷史快照保持不變
- 股價更新不會覆蓋歷史數據
- 只是顯示邏輯更智能

✅ **除錯友善**
- 每次比較都輸出日誌
- 清楚顯示使用哪個數據源
- 方便追蹤和驗證邏輯

**影響檔案：**
- 修改：`TWStockInventoryView.swift` - 股價更新後記錄時間戳
- 修改：`USStockInventoryView.swift` - 股價更新後記錄時間戳
- 修改：`CustomerDetailView.swift` - 新增時間戳比較邏輯和智能顯示邏輯
  - 新增函數：`shouldUseInventoryData(stockType:)` - 時間戳比較
  - 修改函數：`getUSStockValue()` - 智能選擇數據源
  - 修改函數：`getUSStockReturnRate()` - 智能選擇數據源
  - 修改函數：`getTWStockValue()` - 智能選擇數據源
  - 修改函數：`getTWStockReturnRate()` - 智能選擇數據源
  - 保留函數：`getUSStockValueFromInventory()` - 從持倉明細計算市值
  - 保留函數：`getUSStockReturnRateFromInventory()` - 從持倉明細計算報酬率
  - 保留函數：`getTWStockValueFromInventory()` - 從持倉明細計算市值
  - 保留函數：`getTWStockReturnRateFromInventory()` - 從持倉明細計算報酬率

### 6. 結構型明細新增「現價」欄位

為結構型商品（僅進行中）新增現價欄位，支援最多 3 個標的的現價記錄。

**功能特點：**
- 支援 1-3 個標的的現價輸入
- 使用青色背景區分
- 支援千分位格式化顯示
- 僅進行中表格支援（已出場商品不需要現價）

**Core Data 更新：**
```xml
<attribute name="currentPrice1" attributeType="String" defaultValueString=""/>
<attribute name="currentPrice2" attributeType="String" defaultValueString=""/>
<attribute name="currentPrice3" attributeType="String" defaultValueString=""/>
```

**UI 實現：**
```swift
private func currentPricesCell(for product: StructuredProduct) -> some View {
    VStack(spacing: 2) {
        // 現價1、現價2、現價3（根據標的數量顯示）
        TextField("現價1", text: Binding(
            get: { formatNumberWithCommas(product.currentPrice1) },
            set: { product.currentPrice1 = removeCommas($0); saveContext() }
        ))
        .background(Color.cyan.opacity(0.1))
    }
}
```

**影響檔案：**
- 修改：`DataModel.xcdatamodel/contents` - 新增 currentPrice1/2/3 欄位
- 修改：`StructuredProductsDetailView.swift` - 實現現價輸入框和數據綁定（僅進行中表格）

### 4. 結構型商品「距離出場%」自動計算

為結構型商品的「距離出場%」欄位新增自動計算功能，根據現價和期初價格自動計算百分比。

**功能特點：**
- 📊 **自動計算**：距離出場% = (現價 / 期初價格) × 100
- ✏️ **保留手動輸入**：用戶仍可隨時手動修改距離出場%
- 🔄 **智能觸發**：在以下情況自動重新計算
  - 股價刷新後
  - 現價手動更新時
  - 期初價格手動更新時
- 🎯 **多標的支援**：支持 1-3 個標的分別計算

**計算邏輯：**

```swift
private func calculateDistanceToExit(for product: StructuredProduct) {
    // 計算標的1的距離出場%
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

    // 標的2、標的3 同理...
}
```

**觸發時機：**

1. **股價刷新後**
```swift
// 刷新股價後自動計算
for product in updatedProducts {
    calculateDistanceToExit(for: product)
}
```

2. **現價手動更新時**
```swift
TextField("現價1", text: Binding(
    get: { formatNumberWithCommas(product.currentPrice1) },
    set: {
        product.currentPrice1 = removeCommas($0)
        calculateDistanceToExit(for: product)  // 自動計算
        saveContext()
    }
))
```

3. **期初價格手動更新時**
```swift
TextField("價格1", text: Binding(
    get: { formatNumberWithCommas(product.initialPrice1) },
    set: {
        product.initialPrice1 = removeCommas($0)
        calculateDistanceToExit(for: product)  // 自動計算
        saveContext()
    }
))
```

**使用示例：**

假設有以下數據：
- 期初價格：100
- 現價：110

系統自動計算：
- 距離出場% = (110 / 100) × 100 = 110.00%

**安全特性：**
- 只有當現價和期初價格都有值時才計算
- 期初價格為 0 時不計算（避免除以零）
- 自動去除千分位後計算
- 結果保留兩位小數並加上 % 符號

**影響檔案：**
- 修改：`StructuredProductsDetailView.swift` - 新增自動計算邏輯

---

## 最新更新（2025-10-08）

### 1. 表格預設收起狀態
所有表格（月度資產明細、公司債明細、結構型明細、已出場、美股明細、損益表）在 APP 開啟時預設為收起狀態，提供更簡潔的初始介面。

**修改文件：**
- `MonthlyAssetDetailView.swift:9` - `isExpanded = false`
- `CorporateBondsDetailView.swift:9` - `isExpanded = false`
- `StructuredProductsDetailView.swift:9` - `isExpanded = false`
- `StructuredProductsDetailView.swift:57` - `isExitedExpanded = false`
- `USStockDetailView.swift:6` - `isExpanded = false`
- `ProfitLossTableView.swift:9` - `isExpanded = false`

### 2. 結構型表格自動高度調整
結構型明細和結構型已出場表格移除了高度限制（原本 `maxHeight: 400`），現在會根據資料數量自動展開，讓所有資料都能完整顯示。

**修改內容：**
- 移除 `ScrollView` 包裝
- 移除 `.frame(maxHeight: 400)` 限制
- 保留 `LazyVStack` 實現列表渲染
- 外層 ContentView 的 ScrollView 負責整體滾動

**影響檔案：**
- `StructuredProductsDetailView.swift:272-336` (進行中)
- `StructuredProductsDetailView.swift:432-472` (已出場)

### 3. 交易定價日排序功能
為結構型明細和結構型已出場表格新增了「交易定價日」欄位的排序功能。

**功能特點：**
- 點擊「交易定價日」欄位標題可切換排序方向
- ⬇️ 箭頭 = 降序（新到舊，預設）
- ⬆️ 箭頭 = 升序（舊到新）
- 進行中和已出場的排序狀態獨立（互不影響）

**技術實作：**

1. **排序狀態管理**
```swift
@State private var sortAscending = false  // 進行中的排序方向
@State private var exitedSortAscending = false  // 已出場的排序方向
```

2. **可點擊的表頭欄位**
```swift
Button(action: {
    sortAscending.toggle()
}) {
    HStack(spacing: 4) {
        Text("交易定價日")
        Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
            .foregroundColor(.blue)
    }
}
```

3. **排序邏輯**
```swift
private var sortedOngoingProducts: [StructuredProduct] {
    return ongoingProducts.sorted { product1, product2 in
        let date1 = parseTradePricingDate(product1.tradePricingDate ?? "")
        let date2 = parseTradePricingDate(product2.tradePricingDate ?? "")
        return sortAscending ? date1 < date2 : date1 > date2
    }
}
```

4. **多格式日期解析**
支援以下日期格式：
- `Sep 8 2023` / `Sep 08 2023` (MMM d yyyy)
- `2023-09-08` (yyyy-MM-dd)
- `2023/09/08` (yyyy/MM/dd)
- `2025/3/4` (yyyy/M/d) ⭐ 支援單位數月日
- `2025-3-4` (yyyy-M-d)
- `3/4/2025` (M/d/yyyy)
- `08/09/2023` (dd/MM/yyyy)

**特殊處理：**
- 空白日期會排在最後
- 無法解析的日期也會排在最後（使用 `Date(timeIntervalSince1970: 0)`）

**修改檔案：**
- `StructuredProductsDetailView.swift:16-17` - 新增排序狀態變數
- `StructuredProductsDetailView.swift:250-277` - 進行中表頭排序按鈕
- `StructuredProductsDetailView.swift:438-465` - 已出場表頭排序按鈕
- `StructuredProductsDetailView.swift:737-802` - 排序計算屬性與日期解析函數
- `StructuredProductsDetailView.swift:296` - 使用 `sortedOngoingProducts`
- `StructuredProductsDetailView.swift:476` - 使用 `sortedExitedProducts`

### 4. 結構型已出場分類頁籤功能

**功能說明：**
結構型已出場表格新增了分類頁籤功能，讓使用者可以依照年份或其他自訂分類來組織已出場的結構型商品資料。

**主要特點：**
1. **預設「全部」頁籤**：顯示所有已出場資料
2. **自訂分類頁籤**：可新增任意分類名稱（例如：2024、2025、2026）
3. **分類管理方式**：
   - 點擊頁籤區的「➕ 新增分類」按鈕：直接建立空白分類頁籤
   - 點擊資料列的「分類」按鈕：將已出場資料歸檔到指定分類
4. **持久化儲存**：自訂分類列表儲存在 UserDefaults 中
5. **自動顯示**：當有資料使用某分類或手動新增分類時，該分類頁籤會自動出現

**實作細節：**
- `StructuredProductsDetailView.swift:26` - `customCategories` 狀態變數，儲存自訂分類列表
- `StructuredProductsDetailView.swift:496-540` - 頁籤選擇器 UI
- `StructuredProductsDetailView.swift:516-532` - 新增分類按鈕
- `StructuredProductsDetailView.swift:645-656` - 資料列的分類按鈕
- `StructuredProductsDetailView.swift:893-897` - `availableCategories` 計算屬性，合併產品分類與自訂分類
- `StructuredProductsDetailView.swift:900-907` - `filteredExitedProducts` 根據選中分類篩選資料
- `StructuredProductsDetailView.swift:210-230` - 新增分類對話框邏輯
- `StructuredProductsDetailView.swift:1250-1316` - `confirmMoveToExited` 移動/更改分類函數
- `StructuredProductsDetailView.swift:1407-1416` - 自訂分類的儲存與載入函數

**使用方式：**
1. **新增空白分類**：點擊頁籤區的「➕ 新增分類」→ 輸入分類名稱 → 確定
2. **將資料歸檔到分類**：點擊資料列的「📁 分類」按鈕 → 選擇或新增分類
3. **切換分類檢視**：點擊不同的頁籤即可切換顯示該分類的資料

### 5. 修復：結構型明細與已出場新增標的時崩潰問題

**問題描述：**
- 在**結構型明細（進行中）**和**結構型已出場**區域新增標的資料時會崩潰
- 問題演變過程：
  - 初始：新增1-2個標的會崩潰，3個標的正常
  - 第一次修復後：新增1個標的正常，2-3個標的會崩潰
  - 第二次修復後：結構型明細1-3個標的正常，但結構型已出場2-3個標的偶爾會崩潰
- 重啟後資料已正確儲存，但使用者體驗不佳

**根本原因分析：**
1. **強制解包問題**：程式碼中使用 `newProduct.exitCategory!` 強制解包，當值為 nil 時導致崩潰
2. **UI 更新時序問題**：動態 UI 渲染與 iCloud 同步的時序衝突
3. **多個 TextField 同時初始化衝突**：
   - 進行中：每個標的有4個欄位（標的名稱、期初價格、執行價格、距離出場%）
   - 已出場：每個標的有4個欄位 + 額外8個已出場欄位（出場日、持有月數、實際收益、實質收益等）
   - 當有2-3個標的時，總共8-12個 TextField（進行中）或 12-16個 TextField（已出場）同時初始化
   - 每個 TextField 的 Binding 都可能觸發 `saveContext()`，導致短時間內多次 iCloud 同步引發衝突
4. **已出場表格的額外複雜度**：
   - 「實質收益」欄位的自動計算（實際收益 × 交易金額）在每次 get 時執行
   - 更多欄位導致更多的 UI 更新和計算負擔

**解決方案：**
1. **移除強制解包**：所有 optional 值改用安全的 `??` 運算子
2. **使用 DispatchQueue.main.asyncAfter 延遲 iCloud 同步**：
   - 新增商品時使用動態延遲：
     - 已出場 + 2-3個標的：延遲 0.3 秒（欄位更多，計算更複雜）
     - 進行中 + 2-3個標的：延遲 0.2 秒
     - 1個標的：延遲 0.1 秒
   - saveContext 函數：延遲 0.05 秒（避免短時間內多次保存）
   - 其他操作（刪除、更改分類、複製）：使用 `DispatchQueue.main.async`

**修改檔案：**
- `StructuredProductsDetailView.swift:1393-1409` - 新增商品時使用動態延遲策略
- `StructuredProductsDetailView.swift:1204-1206` - saveContext 函數使用 asyncAfter(deadline: .now() + 0.05)
- `StructuredProductsDetailView.swift:1241-1244` - 刪除商品時使用 DispatchQueue.main.async
- `StructuredProductsDetailView.swift:1275-1278` - 更改分類時使用 DispatchQueue.main.async
- `StructuredProductsDetailView.swift:1324-1327` - 複製到已出場時使用 DispatchQueue.main.async
- `StructuredProductsDetailView.swift:1407、1410` - 移除強制解包，改用 optional binding

**修復後行為：**
- 結構型明細（進行中）新增1、2、3個標的都能正常運作
- 結構型已出場新增資料時偶爾仍會崩潰（發生機率大幅降低）
- 資料保存成功，重啟後可正常顯示
- 編輯、刪除、更改分類等操作穩定

**已知問題：**
- 結構型已出場新增2-3個標的時仍有小機率崩潰（時序相關問題，難以完全避免）
- 建議未來考慮：
  1. 減少初始化時的自動計算（如「實質收益」可改為手動觸發計算）
  2. 使用 debounce 機制減少頻繁的 saveContext 調用
  3. 考慮使用 batch update 來減少 Core Data 的保存次數

### 6. 結構型已出場頁籤拖拽排序功能

**功能說明：**
結構型已出場的分類頁籤支援拖拽排序，使用者可以自訂頁籤的顯示順序。

**主要特點：**
1. **拖拽排序**：長按頁籤可拖拽到想要的位置
2. **持久化儲存**：排序會儲存到 UserDefaults，重啟 APP 後保持
3. **智慧排序**：
   - 「全部」頁籤固定在最左邊，不可移動
   - 已排序的分類按自訂順序顯示
   - 新建的分類會自動加到已排序分類的後面（按字母排序）

**實作細節：**
- `StructuredProductsDetailView.swift:27` - `categoryOrder` 狀態變數，儲存頁籤排序
- `StructuredProductsDetailView.swift:900-915` - `availableCategories` 計算屬性，使用自訂排序
- `StructuredProductsDetailView.swift:526-538` - 頁籤的 `.onDrag` 和 `.onDrop` 實作
- `StructuredProductsDetailView.swift:1468-1476` - 儲存和載入頁籤排序函數
- `StructuredProductsDetailView.swift:156` - 在 `onAppear` 中載入頁籤排序
- `StructuredProductsDetailView.swift:1480-1516` - `CategoryDropDelegate` 實作拖拽邏輯

**使用方式：**
1. 展開「結構型已出場」區域
2. 長按任何分類頁籤（除了「全部」）
3. 拖拽到想要的位置
4. 放開後自動儲存排序

**技術實作：**
- 使用 SwiftUI 的 `.onDrag` 和 `.onDrop` API
- 透過 `CategoryDropDelegate` 處理拖拽事件
- 使用 `NSItemProvider` 傳遞拖拽的分類名稱
- 排序資料儲存在 UserDefaults 的 `StructuredProducts_CategoryOrder` key

### 7. 結構型已出場 - 頁籤拖曳排序功能（已實作）✅

**實作日期：** 2025-10-09

**功能描述：**
在「結構型已出場」區域實作了完整的分類頁籤拖曳排序功能，每個客戶的頁籤排序獨立儲存。

**核心功能：**
1. **拖曳排序**：可透過拖曳調整頁籤順序
2. **客戶獨立儲存**：每個客戶的頁籤順序分別儲存，互不影響
3. **新增分類**：透過「新增分類」按鈕建立新的分類頁籤
4. **刪除分類**：長按頁籤顯示選單，可刪除空白分類
5. **自動處理新分類**：新增的分類會自動加入排序系統

**相關檔案和程式碼位置：**

`StructuredProductsDetailView.swift`:
- Line 28: `@State private var draggingCategory: String?` - 追蹤正在拖曳的頁籤
- Line 29-30: 刪除分類確認對話框相關狀態
- Line 519-559: 頁籤 UI 實作，包含拖曳和右鍵選單
- Line 532-542: `.contextMenu` 實作刪除功能
- Line 543-558: `.onDrag` 和 `.onDrop` 實作拖曳功能
- Line 244-276: 刪除分類確認對話框
- Line 965-981: `availableCategories` 計算屬性，整合排序邏輯
- Line 1509-1538: `deleteCategory()` 函數實作
- Line 1540-1574: 頁籤排序管理函數（儲存、載入、產生 key）
- Line 1577-1637: `CategoryDropDelegate` 實作完整拖拽邏輯

**使用方式：**

1. **新增分類頁籤：**
   - 點擊「新增分類」按鈕
   - 輸入分類名稱（如：2024、2025）
   - 確定後即建立新頁籤

2. **拖曳排序：**
   - 長按任何分類頁籤（除了「全部」）
   - 拖拽到想要的位置
   - 放開後自動儲存排序

3. **刪除分類：**
   - 長按分類頁籤（除了「全部」）
   - 在彈出選單中選擇「刪除分類」
   - 如果分類中有商品，會顯示警告無法刪除
   - 如果分類為空，確認後即可刪除

**技術實作：**

1. **拖曳機制：**
   - 使用 SwiftUI 的 `.onDrag` 和 `.onDrop` API
   - 透過 `@State var draggingCategory` 追蹤拖曳項目（不依賴 `NSItemProvider` 的數據傳輸）
   - `CategoryDropDelegate` 實作 `DropDelegate` 協議處理拖拽事件

2. **客戶獨立儲存：**
   ```swift
   private func categoryOrderKey() -> String {
       if let client = client {
           return "StructuredProducts_CategoryOrder_\(client.objectID.uriRepresentation().absoluteString)"
       } else {
           return "StructuredProducts_CategoryOrder_AllClients"
       }
   }
   ```
   - 使用客戶的 `objectID` 作為 key 的一部分
   - 確保不同客戶的排序設定完全獨立

3. **自動處理新分類：**
   ```swift
   // 確保新分類自動加入排序列表
   if !categories.contains(fromCategoryName) {
       categories.append(fromCategoryName)
   }
   ```
   - 第一次拖曳新分類時自動加入 `categoryOrder`
   - 解決新分類無法拖曳的問題

4. **刪除保護機制：**
   - 檢查分類中是否有商品
   - 有商品時顯示警告訊息，阻止刪除
   - 刪除後自動清理 `customCategories` 和 `categoryOrder`
   - 如果刪除的是當前選擇的分類，自動切換到「全部」

**已解決的問題：**

1. **問題：** `NSItemProvider` 的 `loadObject` 無法正確載入字串資料
   - **解決方案：** 使用 `@State var draggingCategory` 直接追蹤拖曳項目

2. **問題：** 新增的頁籤無法拖曳排序
   - **原因：** 新分類未加入 `categoryOrder` 陣列
   - **解決方案：** 在 `dropEntered` 中自動檢查並添加缺失的分類

3. **問題：** 不同客戶的頁籤順序互相影響
   - **原因：** 所有客戶共用同一個 UserDefaults key
   - **解決方案：** 使用客戶 `objectID` 產生獨立的儲存 key

**資料儲存：**
- **儲存位置：** UserDefaults
- **Key 格式：** `StructuredProducts_CategoryOrder_{clientObjectID}` 或 `StructuredProducts_CategoryOrder_AllClients`
- **資料格式：** `[String]` 陣列，儲存排序後的分類名稱
- **自訂分類：** `StructuredProducts_CustomCategories` key 儲存所有自訂分類

**排序邏輯流程：**
1. `availableCategories` 計算屬性整合所有分類來源
2. 如果 `categoryOrder` 不為空，優先使用自訂排序
3. 已排序的分類在前，新分類按字母順序排在後面
4. 「全部」頁籤永遠在最前面且不可移動

### 8. 關於客戶獨立列排序的考量
目前列排序（Column Reorder）使用 `@State` 儲存，所有客戶共用相同的排序設定。如需實現每個客戶獨立的列排序，有兩個方案：

**方案 1（推薦）：** 在 Client 實體中新增欄位
- 在 Core Data 的 Client 實體中新增 `structuredProductsColumnOrder`、`corporateBondsColumnOrder` 等欄位
- 可同步到 iCloud，跨設備保持一致

**方案 2：** 使用 UserDefaults + 客戶 ID
- 以客戶 ID 作為 key 儲存到 UserDefaults
- 不會同步到 iCloud

---

## 保單管理功能

### 1. 保單 Core Data + iCloud 整合（已實作）✅

**實作日期：** 2025-10-14

**功能描述：**
實作保單資料的 Core Data 持久化儲存與 iCloud 自動同步功能，取代原本的 UserDefaults 暫存方案。保單資料現在會自動儲存到本地資料庫並同步到 iCloud，支援跨設備資料共享。

**核心功能：**
1. **Core Data 持久化儲存**：保單資料永久儲存在本地資料庫
2. **iCloud 自動同步**：透過 NSPersistentCloudKitContainer 自動同步到 iCloud
3. **客戶關聯**：保單與客戶建立一對多關係，支援級聯刪除
4. **即時更新**：使用 @FetchRequest 實現資料變更的即時 UI 更新
5. **OCR 辨識整合**：支援從保單影像自動辨識並儲存資料
6. **手動新增**：支援手動輸入保單資料
7. **刪除確認**：刪除保單前顯示確認對話框，防止誤刪

**Core Data 實體結構：**

`InsurancePolicy` 實體包含以下欄位：
```xml
<entity name="InsurancePolicy" representedClassName="InsurancePolicy" syncable="YES" codeGenerationType="class">
    <attribute name="policyType" attributeType="String" defaultValueString=""/>        <!-- 保險種類 -->
    <attribute name="insuranceCompany" attributeType="String" defaultValueString=""/>  <!-- 保險公司 -->
    <attribute name="policyNumber" attributeType="String" defaultValueString=""/>      <!-- 保單號碼 -->
    <attribute name="policyName" attributeType="String" defaultValueString=""/>        <!-- 保險名稱 -->
    <attribute name="insuredPerson" attributeType="String" defaultValueString=""/>     <!-- 被保險人 -->
    <attribute name="startDate" attributeType="String" defaultValueString=""/>         <!-- 保單始期 -->
    <attribute name="paymentMonth" attributeType="String" defaultValueString=""/>      <!-- 繳費月份 -->
    <attribute name="coverageAmount" attributeType="String" defaultValueString=""/>    <!-- 保額 -->
    <attribute name="annualPremium" attributeType="String" defaultValueString=""/>     <!-- 年繳保費 -->
    <attribute name="paymentPeriod" attributeType="String" defaultValueString=""/>     <!-- 繳費年期 -->
    <attribute name="createdDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    <relationship name="client" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Client" inverseName="insurancePolicies" inverseEntity="Client"/>
</entity>
```

**Client 實體新增關聯：**
```xml
<relationship name="insurancePolicies" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="InsurancePolicy" inverseName="client" inverseEntity="InsurancePolicy"/>
```

**相關檔案和程式碼位置：**

`DataModel.xcdatamodeld/DataModel.xcdatamodel/contents`:
- Line 123-136: InsurancePolicy 實體定義
- Line 10: Client 實體的 insurancePolicies 關聯

`InsurancePolicyView.swift`:
- Line 18: `@FetchRequest var insurancePolicies: FetchedResults<InsurancePolicy>` - 使用 FetchRequest 查詢資料
- Line 43-62: `init()` 建構子，設定 FetchRequest 的 predicate 和 sortDescriptors
- Line 351-377: `saveToCoreData()` 函數，儲存保單到 Core Data
- Line 379-393: `deletePolicy()` 函數，從 Core Data 刪除保單
- Line 395-407: `getTotalInsuranceValue()` 函數，從 Core Data 計算總保額
- Line 409-411: `getPolicyCount()` 函數，從 Core Data 計算保單數量
- Line 413-419: `getAnnualPremium()` 函數，從 Core Data 計算年繳保費總額
- Line 268-293: 刪除確認對話框實作
- Line 23-24: `@State` 變數管理刪除確認狀態

`InsuranceOCRManager.swift`:
- Line 13-24: `InsurancePolicyData` 結構，用於 OCR 辨識和手動輸入的資料傳遞
- Line 70-184: `parseInsuranceData()` 函數，解析 OCR 文字為結構化資料
- Line 209-240: `validateData()` 函數，驗證資料完整度

`AddInsurancePolicyView.swift`:
- Line 244-283: `savePolicyData()` 函數，建立 InsurancePolicyData 並透過回調儲存

**資料流程：**

1. **OCR 辨識新增保單：**
   ```
   拍攝保單 → OCR 辨識文字 → 解析為 InsurancePolicyData →
   編輯確認 → saveToCoreData() → Core Data → iCloud 同步
   ```

2. **手動新增保單：**
   ```
   點擊「新增保單」→ 填寫表單 → 驗證必填欄位 →
   建立 InsurancePolicyData → saveToCoreData() → Core Data → iCloud 同步
   ```

3. **刪除保單：**
   ```
   點擊刪除按鈕 → 顯示確認對話框 → 確認刪除 →
   deletePolicy() → viewContext.delete() → Core Data → iCloud 同步
   ```

**Core Data 儲存實作：**

```swift
private func saveToCoreData(_ policyData: InsurancePolicyData) {
    guard let client = client else {
        print("❌ 無法儲存：沒有選中的客戶")
        return
    }

    let newPolicy = InsurancePolicy(context: viewContext)
    newPolicy.policyType = policyData.policyType
    newPolicy.insuranceCompany = policyData.insuranceCompany
    newPolicy.policyNumber = policyData.policyNumber
    newPolicy.policyName = policyData.policyName
    newPolicy.insuredPerson = policyData.insuredPerson
    newPolicy.startDate = policyData.startDate
    newPolicy.paymentMonth = policyData.paymentMonth
    newPolicy.coverageAmount = policyData.coverageAmount
    newPolicy.annualPremium = policyData.annualPremium
    newPolicy.paymentPeriod = policyData.paymentPeriod
    newPolicy.createdDate = Date()
    newPolicy.client = client

    do {
        try viewContext.save()
        print("✅ 保單已儲存到 Core Data 並自動同步到 iCloud")
    } catch {
        print("❌ 儲存保單失敗：\(error.localizedDescription)")
    }
}
```

**FetchRequest 實作：**

```swift
init(client: Client?, onBack: @escaping () -> Void) {
    self.client = client
    self.onBack = onBack

    // 設定 FetchRequest 的 predicate，只顯示該客戶的保單
    let predicate: NSPredicate
    if let client = client {
        predicate = NSPredicate(format: "client == %@", client)
    } else {
        predicate = NSPredicate(value: false)
    }

    _insurancePolicies = FetchRequest<InsurancePolicy>(
        entity: InsurancePolicy.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \InsurancePolicy.createdDate, ascending: false)],
        predicate: predicate
    )
}
```

**刪除確認對話框實作：**

```swift
@State private var policyToDelete: InsurancePolicy? = nil
@State private var showingDeleteConfirmation = false

.alert("確認刪除", isPresented: $showingDeleteConfirmation) {
    Button("取消", role: .cancel) {
        policyToDelete = nil
    }
    Button("刪除", role: .destructive) {
        if let policy = policyToDelete {
            deletePolicy(policy)
            policyToDelete = nil
        }
    }
} message: {
    if let policy = policyToDelete {
        Text("確定要刪除「\(policy.policyName ?? "此保單")」的資料嗎？此操作無法復原。")
    } else {
        Text("確定要刪除此保單資料嗎？此操作無法復原。")
    }
}
```

**刪除按鈕實作：**

保單表格最左側新增了刪除按鈕欄位：

```swift
// 表頭
Text("")
    .frame(width: 40, alignment: .center)

// 資料列
Button(action: {
    policyToDelete = policy
    showingDeleteConfirmation = true
}) {
    Image(systemName: "minus.circle.fill")
        .font(.system(size: 16))
        .foregroundColor(.red)
}
.padding(.horizontal, 8)
.frame(width: 40, alignment: .center)
```

**統計資料計算：**

所有統計資料現在從 Core Data 即時計算：

```swift
// 總保額
private func getTotalInsuranceValue() -> Double {
    return insurancePolicies.reduce(0.0) { total, policy in
        let amount = Double(policy.coverageAmount ?? "0") ?? 0.0
        return total + amount
    }
}

// 保單數量
private func getPolicyCount() -> Int {
    return insurancePolicies.count
}

// 年繳保費總額
private func getAnnualPremium() -> Double {
    return insurancePolicies.reduce(0.0) { total, policy in
        let premium = Double(policy.annualPremium ?? "0") ?? 0.0
        return total + premium
    }
}
```

**iCloud 同步機制：**

透過 `NSPersistentCloudKitContainer` 自動處理 iCloud 同步：

```swift
// PersistenceController.swift
lazy var container: NSPersistentCloudKitContainer = {
    let container = NSPersistentCloudKitContainer(name: "DataModel")

    // 啟用歷史追蹤和遠端變更通知
    guard let description = container.persistentStoreDescriptions.first else {
        fatalError("Failed to retrieve a persistent store description.")
    }

    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

    container.loadPersistentStores { _, error in
        if let error = error {
            fatalError("Core Data failed to load: \(error.localizedDescription)")
        }
    }

    // 自動合併來自父上下文的變更
    container.viewContext.automaticallyMergesChangesFromParent = true

    return container
}()
```

**優點：**
1. ✅ 資料持久化：保單資料永久儲存，不會遺失
2. ✅ iCloud 同步：多設備自動同步，資料一致性高
3. ✅ 即時更新：使用 @FetchRequest，資料變更立即反映在 UI
4. ✅ 關聯管理：與客戶建立關聯，支援級聯刪除
5. ✅ 刪除保護：確認對話框防止誤刪重要資料
6. ✅ 類型安全：使用 Core Data 生成的類別，編譯時期檢查
7. ✅ 效能優化：支援分頁查詢和批次操作

**使用方式：**

1. **新增保單（OCR）：**
   - 點擊「OCR 辨識」按鈕
   - 拍攝或選擇保單照片
   - 系統自動辨識並填入資料
   - 確認並編輯後儲存

2. **新增保單（手動）：**
   - 點擊「新增保單」按鈕
   - 填寫所有必填欄位（標示 * 的欄位）
   - 點擊「儲存」按鈕

3. **刪除保單：**
   - 點擊保單列最左側的紅色刪除按鈕
   - 在確認對話框中確認刪除
   - 資料從 Core Data 刪除並同步到 iCloud

4. **查看統計：**
   - 總保額、保單數量、年繳保費等統計自動計算
   - 資料來源為 Core Data，即時更新

**注意事項：**
- 刪除客戶時會級聯刪除該客戶的所有保單（deletionRule: Cascade）
- 刪除保單時客戶資料保持不變（deletionRule: Nullify）
- 所有保單必須關聯到一個客戶
- iCloud 同步需要使用者登入 iCloud 帳號
- 首次同步可能需要一些時間，視資料量而定

---

## 投資提醒功能 (ReminderDashboardView)

### 功能概述

投資提醒功能提供了一個直觀的月份頁籤式介面，幫助用戶追蹤未來三個月（當月 + 未來兩個月）的債券配息和保險繳費提醒。

### 主要特性

#### 1. **頁籤式月份選擇器**
- 頂部顯示可橫向滾動的月份頁籤
- 支援三個月份：當月、下個月、再下個月
- 選中月份：藍色背景 + 白色文字
- 未選中月份：灰色背景 + 黑色文字
- 點擊頁籤立即切換並更新內容

#### 2. **智能數據過濾**
- 根據選中月份自動篩選配息和保費提醒
- 統計卡片即時顯示該月份的提醒數量
- 支援配息月份格式：`/`、`、`、`,`（例如：5月/11月、5月、11月）

#### 3. **配息提醒卡片**
**卡片設計：**
```
┌────────────────────────────┐
│█  客戶名稱          $12,420│  ← 左側綠色色條
│   債券名稱                  │
└────────────────────────────┘
```

**顯示內容：**
- 客戶名稱（16pt 半粗體）
- 債券名稱（14pt 常規體，灰色）
- 配息金額（18pt 粗體，綠色）

**數據來源：**
- 從 `CorporateBond.dividendMonths` 解析配息月份
- 從 `CorporateBond.singleDividend` 顯示單次配息金額

#### 4. **保費提醒卡片**
**卡片設計：**
```
┌────────────────────────────┐
│█  客戶名稱      $1,215      │  ← 左側藍色色條
│   保單名稱 • 15日      TWD  │
└────────────────────────────┘
```

**顯示內容：**
- 客戶名稱（16pt 半粗體）
- 保單名稱（14pt 常規體，灰色）
- 繳費日期（14pt 常規體，灰色）
- 保費金額（18pt 粗體，藍色）
- 幣別（12pt 常規體，灰色）

**數據來源：**
- 從 `InsurancePolicy.paymentMonth` 解析繳費月份
- 從 `InsurancePolicy.annualPremium` 顯示年度保費
- 從 `InsurancePolicy.currency` 顯示幣別（TWD/USD）

### 技術實現

#### 檔案結構
```
InvestmentDashboard/
├── ReminderDashboardView.swift  # 主提醒視圖
├── ContentView.swift            # 整合提醒按鈕
└── DataModel.xcdatamodeld/      # Core Data 模型
```

#### Core Data 整合

**使用的 Entity：**
1. **Client** - 客戶資料
2. **CorporateBond** - 公司債資料
   - `dividendMonths`: 配息月份（String）
   - `singleDividend`: 單次配息金額（String）
   - `bondName`: 債券名稱（String）
3. **InsurancePolicy** - 保險保單資料
   - `paymentMonth`: 繳費月份（String）
   - `annualPremium`: 年度保費（String）
   - `currency`: 幣別（String）
   - `policyName`: 保單名稱（String）

#### 月份解析邏輯

**支援的配息月份格式：**
```swift
// 格式1: 斜線分隔
"5月/11月"  → [5, 11]

// 格式2: 頓號分隔
"5月、11月"  → [5, 11]

// 格式3: 逗號分隔
"5月,11月"   → [5, 11]

// 格式4: 單月
"5月"       → [5]
```

**解析函數：**
```swift
private func parseDividendMonths(_ monthsStr: String) -> [Int] {
    var months: [Int] = []

    // 支援斜線、頓號、逗號分隔
    if monthsStr.contains(",") || monthsStr.contains("、") || monthsStr.contains("/") {
        let normalized = monthsStr
            .replacingOccurrences(of: "、", with: ",")
            .replacingOccurrences(of: "/", with: ",")

        months = normalized.split(separator: ",")
            .compactMap { part -> Int? in
                let cleaned = part.trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "月", with: "")
                return Int(cleaned)
            }
            .filter { $0 >= 1 && $0 <= 12 }
    }

    return months
}
```

#### 月份篩選邏輯

**計算目標月份：**
```swift
private var availableMonths: [(monthKey: String, year: Int, month: Int)] {
    let calendar = Calendar.current
    let today = Date()

    var months: [(monthKey: String, year: Int, month: Int)] = []
    for i in 0...2 {  // 當月 + 未來兩個月
        if let date = calendar.date(byAdding: .month, value: i, to: today) {
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            months.append((monthKey: "\(year)年\(month)月", year: year, month: month))
        }
    }
    return months
}
```

**篩選當月配息：**
```swift
private var currentMonthDividends: [DividendReminder] {
    guard selectedMonthIndex < availableMonths.count else { return [] }
    let selectedMonth = availableMonths[selectedMonthIndex]

    return upcomingDividends
        .filter { $0.year == selectedMonth.year && $0.month == selectedMonth.month }
        .sorted { $0.customerName < $1.customerName }
}
```

### UI 組件

#### MonthTab（月份頁籤）
```swift
struct MonthTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
        }
    }
}
```

#### DividendReminderCard（配息提醒卡片）
```swift
struct DividendReminderCard: View {
    let reminder: DividendReminder

    var body: some View {
        HStack(spacing: 0) {
            // 左側綠色色條
            Rectangle()
                .fill(Color.green)
                .frame(width: 4)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.customerName)
                        .font(.system(size: 16, weight: .semibold))

                    Text(reminder.bondName)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(formatCurrency(reminder.amount))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.green)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}
```

#### InsuranceReminderCard（保費提醒卡片）
```swift
struct InsuranceReminderCard: View {
    let reminder: InsuranceReminder

    var body: some View {
        HStack(spacing: 0) {
            // 左側藍色色條
            Rectangle()
                .fill(Color.blue)
                .frame(width: 4)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.customerName)
                        .font(.system(size: 16, weight: .semibold))

                    HStack(spacing: 6) {
                        Text(reminder.policyName)
                            .font(.system(size: 14))
                        Text("•")
                        Text(formatDate(reminder.paymentDate))
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(reminder.amount))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)

                    Text(reminder.currency)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}
```

### 訪問方式

#### 在 ContentView 中整合

**導航欄按鈕配置：**
```swift
// 右側按鈕組
HStack(spacing: 8) {
    // 提醒按鈕
    Button(action: {
        showingReminder = true
    }) {
        Text("提醒")
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }

    // 保單按鈕
    Button(action: {
        showingInsurancePolicy = true
    }) {
        Text("保單")
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }

    // 新增資料按鈕
    Button(action: {
        showingAddMonthlyData = true
    }) {
        Image(systemName: "plus")
            .font(.system(size: 20, weight: .medium))
    }
}
```

**Sheet 呈現：**
```swift
.sheet(isPresented: $showingReminder) {
    ReminderDashboardView()
        .environment(\.managedObjectContext, viewContext)
}
```

### 設計特色

#### 色彩系統
- **配息主題色：** 綠色 (#00C853)
  - 左側色條
  - 金額文字

- **保費主題色：** 藍色 (#007AFF)
  - 左側色條
  - 金額文字

- **頁籤選中：** 藍色背景 + 白色文字
- **頁籤未選中：** 灰色背景 + 黑色文字

#### 排版規範
- **卡片內距：** 垂直 14pt，水平 16pt
- **卡片圓角：** 10pt
- **色條寬度：** 4pt
- **陰影：** rgba(0,0,0,0.03), radius 2, offset (0,1)

#### 字體層級
| 元素 | 字體大小 | 字重 | 顏色 |
|------|----------|------|------|
| 客戶名稱 | 16pt | Semibold | Primary |
| 副資訊 | 14pt | Regular | Secondary |
| 金額 | 18pt | Bold | 主題色 |
| 幣別 | 12pt | Regular | Secondary |

### 使用流程

#### 查看提醒步驟：
1. **打開提醒視窗**
   - 點擊右上角「提醒」按鈕
   - Sheet 從底部彈出

2. **查看當月提醒**
   - 預設顯示當月（10月）
   - 查看配息和保費提醒

3. **切換月份**
   - 點擊月份頁籤（11月、12月）
   - 內容立即切換到該月份
   - 統計卡片同步更新

4. **查看詳細資訊**
   - 配息卡片：客戶名稱、債券名稱、配息金額
   - 保費卡片：客戶名稱、保單名稱、繳費日期、金額、幣別

5. **關閉提醒視窗**
   - 向下滑動關閉 Sheet
   - 或點擊背景區域關閉

### 數據計算邏輯

#### 提醒數量統計
```swift
// 配息提醒數量（當月）
private var currentMonthDividends: [DividendReminder] {
    let selectedMonth = availableMonths[selectedMonthIndex]
    return upcomingDividends
        .filter { $0.year == selectedMonth.year && $0.month == selectedMonth.month }
        .sorted { $0.customerName < $1.customerName }
}

// 保費提醒數量（當月）
private var currentMonthInsurance: [InsuranceReminder] {
    let selectedMonth = availableMonths[selectedMonthIndex]
    let calendar = Calendar.current

    return upcomingInsurancePayments.filter { payment in
        let year = calendar.component(.year, from: payment.paymentDate)
        let month = calendar.component(.month, from: payment.paymentDate)
        return year == selectedMonth.year && month == selectedMonth.month
    }
}
```

#### 金額格式化
```swift
private func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2

    if let formatted = formatter.string(from: NSNumber(value: amount)) {
        return "$\(formatted)"
    }
    return "$\(amount)"
}
```

### 空狀態處理

當選中的月份沒有任何提醒時，顯示：

```swift
VStack(spacing: 16) {
    Image(systemName: "calendar.badge.clock")
        .font(.system(size: 60))
        .foregroundColor(.gray)

    Text("本月沒有即將到來的事項")
        .font(.headline)
        .foregroundColor(.secondary)

    Text("這個月沒有配息或保費提醒")
        .font(.subheadline)
        .foregroundColor(.secondary)
}
```

### iCloud 同步

提醒功能自動同步以下資料：
- ✅ 客戶資料（Client）
- ✅ 公司債資料（CorporateBond）
- ✅ 保險保單資料（InsurancePolicy）

**同步機制：**
- 使用 `@FetchRequest` 自動監聽 Core Data 變更
- 資料更新立即反映在提醒列表中
- 支援多設備即時同步

### 優點總結

1. ✅ **直觀的月份切換**：頁籤式設計，一目了然
2. ✅ **清晰的視覺層級**：色條、顏色、字體大小區分明確
3. ✅ **即時數據統計**：統計卡片隨月份動態更新
4. ✅ **多格式支援**：支援 `/`、`、`、`,` 三種月份分隔符
5. ✅ **幣別顯示**：保費提醒清楚顯示幣別（TWD/USD）
6. ✅ **自動排序**：配息按客戶名稱，保費按日期排序
7. ✅ **iCloud 同步**：多設備資料一致
8. ✅ **響應式設計**：適配不同螢幕尺寸

### 注意事項

1. **月份格式要求：**
   - 配息月份必須填寫在 `CorporateBond.dividendMonths` 欄位
   - 支援格式：`5月/11月`、`5月、11月`、`5月,11月`
   - 月份數字範圍：1-12

2. **保費月份要求：**
   - 繳費月份必須填寫在 `InsurancePolicy.paymentMonth` 欄位
   - 使用相同的月份格式

3. **金額顯示：**
   - 配息金額來自 `singleDividend`（單次配息）
   - 保費金額來自 `annualPremium`（年度保費）
   - 自動處理千位分隔符

4. **日期計算：**
   - 保費日期基於 `paymentDate` 欄位
   - 自動處理跨年月份（12月→1月）

5. **性能優化：**
   - 使用 Computed Properties 計算，避免重複運算
   - 按月份分頁顯示，減少記憶體使用

---

## App Store 提交指南

### 提交流程概覽

1. **上傳建置版本**（Xcode Archive → Upload）
2. **完成 App Store Connect 設定**
3. **提交審核**
4. **等待審核結果**（最長 48 小時）

### 1. 加密合規性設定

#### Info.plist 設定

在提交前必須在 `Info.plist` 中加入加密聲明，避免上傳時要求提供加密文件：

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

**說明：**
- 此 App 僅使用 Apple 提供的標準加密（HTTPS、CloudKit、Core Data）
- 不使用自定義加密演算法
- 設定為 `false` 表示不需要額外的出口合規文件

#### 建置版本時的加密問題

上傳建置版本後，系統會詢問「App 會使用哪種加密演算法？」

**正確選擇：**
- ✅ 選擇「未使用上方提及的任一種演算法」
- 原因：僅使用 Apple 作業系統提供的標準加密

### 2. App Store Connect 必填項目

#### App 資訊

**內容版權資訊：**
- 選擇「否，我的 App 未包含、顯示或存取第三方內容」
- 理由：App 內容皆為用戶自行輸入的資料

#### 年齡分級

完成 7 步驟問卷，對於本 App：

**第 1 步：功能**
- 分級保護控制：否
- 年齡確認：否
- 未加限制的網頁存取能力：否
- 使用者生成內容：否（資料為私人使用，不分享給其他用戶）
- 傳訊和聊天：否

**第 2-7 步：**
- 所有關於暴力、色情、賭博等內容的問題皆選「無」或「否」

**預期分級：** 4+（適合所有年齡）

#### App 隱私權

**隱私權政策：**
- 已設定 URL：`https://owen1221111.github.io/investmentdashboard-legal/privacy-zh.html`

**資料收集聲明：**
- ✅ 選擇「不收集資料」
- 理由：
  - 資料儲存在用戶本地（Core Data）
  - iCloud 同步為用戶私有資料
  - 訂閱由 Apple StoreKit 處理
  - 無第三方分析工具
  - 無傳送資料到開發者伺服器

**重要：** 填寫完成後必須點擊「發佈」按鈕

### 3. App 審查資訊

**登入資訊：**
- 本 App 不需要登入帳號系統
- 資料儲存在用戶本地裝置和 iCloud

**聯絡人資訊：**（必填）
- 填寫開發者的姓名、電話、電子郵件
- Apple 審查團隊可能會使用此資訊聯絡

**備註建議：**
```
這是一個投資管理工具，主要功能包括：
1. 客戶資料管理
2. 保險保單追蹤
3. 投資資產統計
4. OCR 掃描保單功能

資料儲存在使用者的本地裝置及 iCloud，不需要帳號系統。
```

### 4. 提交前檢查清單

確認以下項目都已完成：

- ✅ Info.plist 已加入 `ITSAppUsesNonExemptEncryption`
- ✅ 建置版本已上傳並選擇
- ✅ App 資訊已填寫完整
- ✅ App 預覽和截圖已上傳
- ✅ 描述、關鍵字已填寫
- ✅ 隱私權政策已設定並發佈
- ✅ 年齡分級問卷已完成
- ✅ App 審查資訊已填寫
- ✅ 定價和銷售地區已設定

### 5. 提交與審核

**提交步驟：**
1. 確認所有必填項目都完成（黃點變綠點）
2. 點擊頁面右上角「新增以供審查」按鈕
3. 確認提交

**審核時間：**
- 通常 1-3 天
- 最長可能需要 48 小時
- 審核完成會收到電子郵件通知

**審核狀態：**
- 「準備提交」→「等待審核」→「審核中」→「已批准」或「被拒絕」

### 6. 常見問題

#### Q: 為什麼上傳後要求加密文件？
A: 需要在 Info.plist 加入 `ITSAppUsesNonExemptEncryption` 設定，然後重新建置上傳。

#### Q: 隱私權設定要選「收集資料」嗎？
A: 本 App 資料僅存於用戶裝置和 iCloud，開發者無法存取，應選「不收集資料」。

#### Q: 需要提供測試帳號嗎？
A: 本 App 無帳號系統，不需要提供測試帳號。

#### Q: App Store 伺服器通知需要設定嗎？
A: 這是選填項目，初次上架可以先跳過，等上架後再設定。

### 7. 提交後注意事項

**如果被拒絕：**
1. 查看 App Store Connect 的拒絕原因
2. 根據回饋修改
3. 更新建置版本號（例如從 1.0 (2) 改成 1.0 (3)）
4. 重新上傳並提交

**如果通過審核：**
1. App 會進入「可供銷售」狀態
2. 可以手動發佈或設定自動發佈
3. 在 App Store 搜尋你的 App 名稱確認上架

---

## App Store 審核記錄

### 審核拒絕記錄 #1 (2025-11-09)

**審核ID:** ed6a0138-bdab-4f81-bdcd-4052d030abe7
**提交日期:** 2025-11-07
**審核日期:** 2025-11-09

#### 被拒絕的問題：

##### 1. Guideline 2.3.3 - iPad 截圖問題
**問題：** 13-inch iPad 截圖顯示的是 iPhone 設備框架

**修正方法：**
- 重新製作正確的 iPad 截圖
- 確保截圖顯示的是 iPad 上的實際畫面

##### 2. Guideline 2.1 - IAP 訂閱產品未提交審核
**問題：** App 中引用了「訂閱方案」但 IAP 產品未一起提交審核

**修正方法：**
- 在 App Store Connect → 訂閱 → Monthly Subscription
- 確認所有必填欄位已填寫：
  - ✅ 參照名稱
  - ✅ 產品ID: com.owenliu.investmentdashboard.monthly
  - ✅ 訂閱期間: 1個月
  - ✅ 價格: NT$100
  - ✅ 本地化版本（繁體中文）
  - ✅ 審查資訊（截圖和說明）
- 提交訂閱產品以供審核

##### 3. Guideline 2.1 - 30天免費試用未顯示
**問題：** 付款頁面沒有顯示廣告的30天免費試用

**修正方法：**
- App Store Connect → 訂閱 → Monthly Subscription → 訂閱價格
- 新增/確認「介紹性優惠」：
  - 優惠類型: 免費試用
  - 期間: 1個月
  - 狀態: 已啟用
- 確保所有地區都已設定

##### 4. Guideline 3.1.2 - 缺少 EULA 和隱私政策連結
**問題：** App 二進制文件和元數據缺少使用條款(EULA)和隱私政策的功能連結

**修正方法：**
- **代碼修正：**
  - 已在 `Configuration.storekit` 添加政策連結：
    ```json
    "eula": "https://owen1221111.github.io/investmentdashboard-legal/terms-zh.html",
    "policyURL": "https://owen1221111.github.io/investmentdashboard-legal/privacy-zh.html"
    ```
  - `SubscriptionView.swift` 已包含隱私政策和使用條款連結
  - `SidebarView.swift` 的「關於」區塊已包含連結

- **App Store Connect 設定：**
  - 在 App 描述底部加入：
    ```
    【法律資訊】
    使用條款 (EULA)：https://owen1221111.github.io/investmentdashboard-legal/terms-zh.html
    隱私權政策：https://owen1221111.github.io/investmentdashboard-legal/privacy-zh.html
    ```
  - 確認「隱私權政策 URL」欄位已填寫

##### 5. Guideline 2.3.2 - 付費內容標示不清
**問題：** App 元數據提到付費內容但未明確標示需要購買

**修正方法：**
- 在 App Store Connect 描述中加入訂閱說明：
  ```
  【訂閱資訊】
  本App採用訂閱制，提供完整功能使用。

  • 訂閱方案：月費 NT$100/月
  • 免費試用：首月免費試用 30 天
  • 自動續訂：試用期結束後自動續訂
  • 取消訂閱：可隨時在 iOS 設定中取消

  訂閱後即可無限制使用所有功能，包括：
  ✓ 無限制新增客戶和資產記錄
  ✓ 保單管理功能
  ✓ 保險試算表辨識
  ✓ 資料提醒功能
  ```

##### 6. Guideline 4.3 - App 圖示重複
**問題：** App 圖示與其他已提交的 App 相同

**修正方法：**
- 設計並更換全新的 App 圖示
- 使用獨特的設計元素避免與其他 App 重複

##### 7. 收據驗證邏輯
**問題：** 伺服器端收據驗證需要處理沙盒環境

**說明：**
- 本 App 使用 StoreKit 2 本地驗證
- `SubscriptionManager.swift` 使用 `Transaction.currentEntitlements` 和 `checkVerified()` 方法
- 不需要伺服器端驗證
- Apple 會自動處理生產環境和沙盒環境的收據

#### 程式碼修正清單：

**檔案修改：**

1. **Configuration.storekit**
   - 添加 EULA 連結
   - 添加隱私政策連結

2. **ContentView.swift** (Build 2)
   - 修復頂部導航欄按鈕佈局問題
   - 按鈕從「保單」「提醒」「貸款」改為「保險」「提醒」「貸款」
   - 增加按鈕間距從 4 到 6
   - 添加 `.fixedSize()` 防止文字壓縮
   - 優化 padding 和字體大小

3. **Info.plist**
   - 已包含 `ITSAppUsesNonExemptEncryption` 設定

#### 版本資訊：

**修正後版本：** 1.0 (Build 2)
**提交日期：** 2025-11-09
**主要變更：**
- 修復按鈕佈局問題
- 更新 StoreKit 配置文件
- Build 號從 1 增加到 2

#### App Store Connect 設定清單：

- ✅ 更新 App 描述，加入訂閱說明和法律連結
- ✅ 確認隱私政策 URL 已填寫
- ✅ 設定訂閱產品介紹性優惠（30天免費試用）
- ✅ 更換 App 圖示
- ✅ 更新 iPad 截圖
- ✅ 選擇新的 Build 2

#### 審核要點提醒：

**訂閱產品設定檢查：**
- 產品ID: `com.owenliu.investmentdashboard.monthly`
- 訂閱期間: 1個月
- 價格: NT$100/月
- 介紹性優惠: 30天免費試用
- 本地化: 繁體中文已設定
- 審查資訊: 截圖和說明已提供

**法律資訊連結：**
- EULA: https://owen1221111.github.io/investmentdashboard-legal/terms-zh.html
- 隱私政策: https://owen1221111.github.io/investmentdashboard-legal/privacy-zh.html

**沙盒測試說明：**
- Apple 審核人員使用沙盒環境測試
- 30天試用期在沙盒中為 5 分鐘
- 1個月訂閱在沙盒中為 5 分鐘
- StoreKit 2 自動處理環境切換

---

### 審核拒絕記錄 #2 (2025-11-11)

**審核ID:** ed6a0138-bdab-4f81-bdcd-4052d030abe7
**重新提交日期:** 2025-11-09
**審核日期:** 2025-11-11
**版本:** 1.0 (Build 2)

#### 審核結果：再次被拒絕

Apple 表示雖然部分問題已解決（EULA、隱私政策、App圖示），但仍有以下核心問題：

#### 仍存在的問題：

##### 1. Guideline 2.1 - IAP 訂閱產品仍未提交審核 ⚠️

**問題描述：**
```
We are still unable to complete the review of the app because one or
more of the in-app purchase products have not been submitted for review.

Specifically, the app includes references to monthly subscription but
the associated in-app purchase products have not been submitted for review.
```

**根本原因分析：**
- ❌ 訂閱產品（Monthly Subscription）在 App Store Connect 狀態為 **「缺少元資料」**
- ❌ 未在版本頁面的「App 內購買項目和訂閱項目」區段選取訂閱產品
- ❌ 因此 App 版本和訂閱產品沒有一起送審

**正確的提交流程：**

**步驟 1：完善訂閱產品資料**
在 App Store Connect → 訂閱 → 投資儀表板 Premium → Monthly Subscription：

1. **基本資訊**
   - ✅ 參照名稱：Monthly Subscription
   - ✅ 產品ID：com.owenliu.investmentdashboard.monthly
   - ✅ 訂閱期限：1個月

2. **本地化版本**（必填）
   - 點擊「本地化版本」旁的「+」按鈕
   - 選擇「繁體中文（台灣）」
   - 訂閱群組顯示名稱：`月費方案` 或 `Premium 月訂閱`
   - App 名稱：`投資儀表板`
   - 描述範例：
     ```
     解鎖完整功能，含30天免費試用
     • 無限制新增客戶和資產記錄
     • 保險管理功能
     • 保險試算表辨識
     • 資料提醒功能
     ```

3. **試賣優惠類型（推薦優惠）**（關鍵！）
   - 點擊「試賣優惠類型」
   - 選擇：☑️ **免費**
   - 期限：**1 個月**（等同於30天）
   - 這會在購買流程顯示「首月免費」
   - 狀態必須為「已啟用」

4. **訂閱價格**
   - 確認所有銷售地區的價格已設定
   - 台灣：NT$100/月

5. **影像（可留空）**
   - 可選：提供 1024x1024 訂閱宣傳圖
   - 會顯示在 App Store 產品頁面

6. **審查資訊**
   - ✅ 截圖：已提供訂閱頁面截圖
   - ✅ 審查備註：已說明訂閱功能和測試方式

7. **確認狀態**
   - 完成所有設定後，狀態應從 🟡 **缺少元資料** 變為 ✅ **準備提交**

**步驟 2：在版本頁面選取訂閱產品**（這是最關鍵的步驟！）

⚠️ **這是之前漏掉的步驟，導致連續兩次被拒！**

根據 Apple 官方文檔：
```
首個訂閱項目必須以新的 App 版本提交。請先建立訂閱項目，然後從
版本頁面的「App 內購買項目和訂閱項目」區段中選取該項目，再將
版本提交至「App 審查」。
```

操作步驟：
1. 進入 **App Store Connect → iOS App → 1.0 版本**
2. 向下滾動找到 **「App 內購買項目和訂閱項目」** 區段
3. 點擊該區段的 **「管理」** 或 **「+」** 按鈕
4. 在彈出選單中選擇 **「自動續訂型訂閱」**（不是「消耗性項目」）
5. **勾選** `Monthly Subscription`
6. 點擊「完成」儲存
7. 確認訂閱產品出現在版本頁面的列表中

**步驟 3：提交審核**
- 此時 App 版本和訂閱產品會一起送審
- Apple 審核人員可以測試訂閱功能

##### 2. Guideline 2.1 - 免費試用未顯示在購買流程 ⚠️

**問題描述：**
```
We still found that your in-app purchase products exhibited one or
more bugs which create a poor user experience.

Specifically, the free trial promoted was not included in the purchase flow.
```

**Apple 截圖證據：**
從 Apple 提供的截圖 `Screenshot-1111-101214.png` 可見：
- StoreKit 購買確認面板顯示：`$2.99 per month`
- **紅色虛線框處應顯示免費試用資訊，但卻是空白**
- 這表示系統沒有自動顯示介紹性優惠

**根本原因：**
訂閱產品的「試賣優惠類型」（Introductory Offer）未設定或未生效

**解決方法：**
按照上述「步驟 1 - 第3點」設定試賣優惠類型即可解決此問題

**驗證方式：**
設定完成後，在沙盒測試環境：
- 購買流程應顯示「免費試用 X 天」或「首月免費」
- 沙盒環境中 30 天會縮短為 5 分鐘

##### 3. Guideline 2.3.10 - 截圖包含非 iOS 狀態欄

**問題描述：**
```
The app or metadata includes information about third-party platforms
that may not be relevant for App Store users.

Revise the app's screenshots to remove non-iOS status bar images.
```

**問題截圖：**
`f6c83aaad8c72af9be0ed53c1d542651076187c0.png`
- 顯示 iPad 介面但套用了 iPhone 的設備外框
- 這被視為「非 iOS 狀態欄圖像」

**解決方法：**
1. 進入 App Store Connect → 1.0 版本 → App 預覽和截圖
2. 找到 **13 吋 iPad Pro** 或相關 iPad 尺寸的截圖區域
3. **刪除** 該張使用錯誤外框的截圖
4. 選項：
   - 上傳純 iPad 截圖（不加任何外框）
   - 或使用正確的 iPad Pro 外框模板重新製作

#### 已解決的問題（第一次 → 第二次）：

✅ **Guideline 3.1.2** - EULA 和隱私政策連結
✅ **Guideline 2.3.2** - 付費內容標示
✅ **Guideline 4.3** - App 圖示重複

#### 關鍵學習點：

1. **訂閱產品的提交流程**
   - ⚠️ 創建訂閱產品 ≠ 提交訂閱產品
   - 必須在版本頁面「選取」訂閱產品才能一起送審
   - 這是 Apple 的特殊要求，容易被忽略

2. **試賣優惠（免費試用）的設定**
   - 必須在訂閱產品中明確設定「試賣優惠類型」
   - 不能只在 App UI 中顯示，系統層面必須啟用
   - StoreKit 購買面板會自動顯示此優惠

3. **訂閱產品狀態檢查**
   - 🟡 缺少元資料：無法選取和提交
   - ✅ 準備提交：可以在版本頁面選取
   - 確保所有必填欄位完成才能變成「準備提交」

4. **截圖要求**
   - iPad 截圖必須使用 iPad 外框或無外框
   - 不能使用其他設備的外框
   - 截圖必須反映真實設備體驗

#### 下一步行動計劃：

**優先順序 1：完善訂閱產品**
- [ ] 補充本地化版本（繁體中文）
- [ ] 設定試賣優惠（1個月免費試用）
- [ ] 確認所有地區價格
- [ ] 確認狀態變為「準備提交」

**優先順序 2：選取訂閱產品**
- [ ] 在 1.0 版本頁面選取 Monthly Subscription
- [ ] 確認訂閱產品出現在「App 內購買項目和訂閱項目」區段

**優先順序 3：修正截圖**
- [ ] 刪除或更換有問題的 iPad 截圖

**優先順序 4：重新提交**
- [ ] 確認所有項目為綠色勾勾
- [ ] 可能需要上傳新的 Build 3（如果 Apple 要求）
- [ ] 提交審核

#### 重要提醒：

**關於 Build 版本：**
- 如果代碼沒有問題，可以使用現有的 Build 2 重新提交
- 只需完成訂閱產品設定和截圖修正即可
- 如果 Apple 堅持要求新的 binary，再上傳 Build 3

**沙盒測試注意事項：**
- Apple 審核人員使用 TestFlight 沙盒環境
- 必須確保訂閱在沙盒環境正常運作
- StoreKit Configuration 檔案已正確設定

**預期結果：**
完成以上修正後，Apple 應該能夠：
1. ✅ 看到訂閱產品隨 App 一起送審
2. ✅ 在購買流程看到 30 天免費試用
3. ✅ 看到正確的 iPad 截圖
4. ✅ 通過審核

---

## 2025-11-13 更新：貸款管理視覺化增強

### 新增功能

#### 1. 投資總覽卡片
在貸款管理頁面新增「投資總覽」卡片，提供快速的投資績效概覽。

**位置：** `LoanManagementView.swift`

**功能特點：**
- **投資總額顯示**
  - 從最新的 `LoanMonthlyData` 記錄中讀取 `totalInvestment`
  - 自動格式化為千分位顯示

- **報酬率計算**
  - 公式：`(投資總額 - 總成本) / 總成本 × 100%`
  - 總成本包含：台股成本 + 美股成本 + 債券成本 + 定期定額成本
  - 正報酬率顯示綠色，負報酬率顯示紅色
  - 顯示精度：小數點後兩位

**實現代碼：**
```swift
// 獲取最新的投資總額
private var latestInvestmentTotal: Double {
    // 從 LoanMonthlyData 獲取最新記錄的 totalInvestment
}

// 計算投資報酬率
private var investmentReturnRate: Double {
    // 計算公式：(投資總額 - 總成本) / 總成本 × 100
}

// 投資總覽卡片視圖
private var investmentSummaryCard: some View {
    // 顯示投資總額和報酬率
}
```

#### 2. 貸款/投資總覽線圖
新增視覺化線圖組件，展示貸款和投資的歷史趨勢。

**檔案：** `LoanInvestmentOverviewChart.swift`

**功能特點：**
- **雙線圖顯示**
  - 可透過下拉選單切換兩種模式：
    - 模式 1：已動用累積 vs 投資總額
    - 模式 2：貸款總額 vs 投資總額

- **數據來源**
  - 從 `LoanMonthlyData` 表格按日期排序讀取歷史數據
  - 已動用累積：`usedLoanAccumulated` 欄位
  - 投資總額：`totalInvestment` 欄位
  - 貸款總額：從所有 Loan 實體的 `loanAmount` 加總計算

- **視覺設計**
  - 採用漸層風格，與總資產大卡統一
  - 線條下方有漸層填充區域（opacity 0.3 → 0.02）
  - 線條本身有左右漸層效果（color → color.opacity(0.7)）
  - 線寬 2.5px
  - 移除網格線和 Y 軸刻度，更簡潔美觀
  - 顏色方案：
    - 已動用累積：橙色漸層
    - 貸款總額：藍色漸層
    - 投資總額：綠色漸層

- **交互功能**
  - 收合/展開功能
  - 圖表類型切換下拉選單
  - 圖例顯示
  - X 軸顯示日期標籤（YYYY/MM 格式）

**實現架構：**
```swift
struct LoanInvestmentOverviewChart: View {
    enum ChartType {
        case usedLoanVsInvestment    // 已動用累積/投資總額
        case totalLoanVsInvestment   // 貸款總額/投資總額
    }
}

struct GradientLineChartView: View {
    // 使用純 SwiftUI 繪製漸層風格線圖
    // 包含填充區域、漸層線條、數據點
}
```

#### 3. 頁面佈局優化
調整貸款管理頁面的卡片顯示順序，提供更好的信息層次。

**新的顯示順序：**
1. **貸款總覽卡片** - 貸款總額 / 每月還款
2. **投資總覽卡片** ✨ (新增) - 投資總額 / 報酬率
3. **貸款/投資總覽線圖** ✨ (新增) - 視覺化趨勢圖
4. **貸款列表** - 所有貸款項目詳情
5. **貸款/投資月度管理表格** - 詳細月度數據

#### 4. 快速編輯功能
為貸款總覽和投資總覽卡片添加快速編輯功能，可直接修改底層數據。

**檔案：**
- `EditLoanAmountsView.swift` - 貸款金額編輯視圖
- `EditInvestmentDataView.swift` - 投資數據編輯視圖

##### 貸款總覽編輯（EditLoanAmountsView）

**觸發方式：**
- 點擊貸款總覽卡片右上角的鉛筆圖示

**編輯內容：**
- 可逐一修改該客戶所有貸款的**原始貸款金額** (`Loan.loanAmount`)

**影響範圍：**
- ✅ **貸款總覽卡片** - 「貸款總額」顯示（所有 loanAmount 總和）
- ✅ **貸款列表** - 每筆貸款顯示的「原始貸款金額」
- ✅ **線圖** - 「貸款總額/投資總額」模式中的貸款總額數據
- ❌ 不影響「剩餘本金」（remainingBalance）
- ❌ 不影響月度管理表格

**實現代碼：**
```swift
struct EditableLoan: Identifiable {
    let loan: Loan
    var amount: String  // 可編輯的金額字串
}

private func saveChanges() {
    for editableLoan in editableLoans {
        editableLoan.loan.loanAmount = cleanedAmount  // 直接修改 Loan 實體
    }
    try viewContext.save()  // 儲存到 Core Data
}
```

##### 投資總覽編輯（EditInvestmentDataView）

**觸發方式：**
- 點擊投資總覽卡片右上角的鉛筆圖示

**編輯內容：**
- 修改**最新一筆** `LoanMonthlyData` 記錄的以下欄位：
  - `totalInvestment` - 投資總額
  - `taiwanStockCost` - 台股成本
  - `usStockCost` - 美股成本
  - `bondsCost` - 債券成本
  - `regularInvestmentCost` - 定期定額成本

**即時預覽功能：**
- 總成本自動計算（四項成本總和）
- 報酬率即時更新：`(投資總額 - 總成本) / 總成本 × 100%`

**影響範圍：**
- ✅ **投資總覽卡片** - 「投資總額」和「報酬率」顯示
- ✅ **月度管理表格** - 最新一筆記錄的所有相關欄位
- ✅ **線圖** - 兩種模式中的「投資總額」數據點
- ❌ 僅修改最新記錄，不影響歷史月份數據

**實現代碼：**
```swift
private func loadLatestData() {
    let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
    fetchRequest.fetchLimit = 1  // 只取最新一筆

    latestData = try viewContext.fetch(fetchRequest).first
}

private func saveChanges() {
    guard let data = latestData else { return }

    data.totalInvestment = removeCommas(totalInvestment)
    data.taiwanStockCost = removeCommas(taiwanStockCost)
    data.usStockCost = removeCommas(usStockCost)
    data.bondsCost = removeCommas(bondsCost)
    data.regularInvestmentCost = removeCommas(regularInvestmentCost)

    try viewContext.save()  // 儲存到 Core Data
}
```

**UI 優化：**
- 移除「點擊編輯」文字，僅保留鉛筆圖示
- 使用 `.minimumScaleFactor(0.7)` 和 `.lineLimit(1)` 防止大金額換行
- 數字輸入支援千分位自動格式化
- TextField 使用 `.decimalPad` 鍵盤類型

**重要提醒：**
- 投資總覽編輯只修改最新一筆月度記錄
- 如需修改其他月份數據，請到月度管理表格中直接編輯
- 編輯後數據會自動同步到 iCloud（透過 PersistenceController）

### 技術細節

#### 漸層線圖實現
為避免 Charts 框架的兼容性問題，使用純 SwiftUI 自繪線圖：

```swift
// 填充區域漸層
LinearGradient(
    gradient: Gradient(colors: [
        color.opacity(0.3),
        color.opacity(0.02)
    ]),
    startPoint: .top,
    endPoint: .bottom
)

// 線條漸層
LinearGradient(
    gradient: Gradient(colors: [
        color,
        color.opacity(0.7)
    ]),
    startPoint: .leading,
    endPoint: .trailing
)
```

#### 數據計算邏輯
```swift
// 投資報酬率計算
let taiwanStockCost = Double(data.taiwanStockCost ?? "0") ?? 0
let usStockCost = Double(data.usStockCost ?? "0") ?? 0
let bondsCost = Double(data.bondsCost ?? "0") ?? 0
let regularInvestmentCost = Double(data.regularInvestmentCost ?? "0") ?? 0
let totalCost = taiwanStockCost + usStockCost + bondsCost + regularInvestmentCost
let totalInvestment = Double(data.totalInvestment ?? "0") ?? 0

if totalCost > 0 {
    returnRate = ((totalInvestment - totalCost) / totalCost) * 100
}
```

### 使用情境

1. **快速查看投資績效**
   - 打開貸款管理頁面即可看到投資總覽卡片
   - 一目了然投資總額和報酬率

2. **分析貸款使用趨勢**
   - 切換到「已動用累積/投資總額」模式
   - 觀察貸款動用和投資的時間關係

3. **評估貸款投資策略**
   - 切換到「貸款總額/投資總額」模式
   - 比較貸款額度和實際投資規模

4. **快速調整貸款金額**
   - 點擊貸款總覽卡片的鉛筆圖示
   - 一次修改所有貸款的原始貸款金額
   - 無需逐一進入貸款詳情頁面

5. **即時更新投資數據**
   - 點擊投資總覽卡片的鉛筆圖示
   - 修改最新月份的投資總額和成本明細
   - 即時預覽報酬率變化
   - 適合快速記錄當月最新投資狀況

### 文件更新
- ✅ `LoanManagementView.swift` - 新增投資總覽卡片、計算邏輯、調整貸款總額計算方式、UI 優化
- ✅ `LoanInvestmentOverviewChart.swift` - 新建線圖視覺化組件（純 SwiftUI 實現）
- ✅ `EditLoanAmountsView.swift` - 新建貸款金額快速編輯視圖
- ✅ `EditInvestmentDataView.swift` - 新建投資數據快速編輯視圖
- ✅ 調整卡片顯示順序和數字顯示優化

---

## 2025-11-13 更新：月度管理數據同步優化

### 問題分析

原本的月度管理存在以下問題：
1. 貸款類型需要手動輸入，容易輸入錯誤
2. 已動用累積的計算邏輯不正確
3. 月度管理和貸款列表的數據不同步
4. 貸款列表和月度管理各自維護累積值，容易產生衝突

### 解決方案

#### 1. 貸款選擇改為下拉選單

**檔案：** `AddLoanMonthlyDataView.swift`

**功能改進：**
- 將「貸款類型」從手動輸入改為下拉選單（Picker）
- 下拉選單選項來自該客戶的貸款列表
- 選擇貸款後自動填充：
  - 貸款類型（`loanType`）
  - 貸款金額（`loanAmount`）
  - 已動用累積（基礎值）

**實現代碼：**
```swift
// 獲取客戶的貸款列表
private var loans: [Loan] {
    guard let loansSet = client.loans as? Set<Loan> else { return [] }
    return loansSet.sorted { ($0.createdDate ?? Date()) > ($1.createdDate ?? Date()) }
}

// 貸款選擇 Picker
Picker("貸款", selection: $selectedLoan) {
    Text("請選擇貸款").tag(nil as Loan?)
    ForEach(loans, id: \.self) { loan in
        Text(loan.loanName ?? "未命名貸款")
            .tag(loan as Loan?)
    }
}
```

**優點：**
- ✅ 避免手動輸入錯誤
- ✅ 確保貸款類型與貸款列表一致
- ✅ 提升用戶體驗

#### 2. 已動用累積計算邏輯修正

**核心原則：** 已動用累積應該從該貸款在月度管理中最早的記錄開始，按日期順序累加到最新。

**修正前的錯誤邏輯：**
```swift
// ❌ 錯誤：從 Loan.usedLoanAmount 讀取
baseAccumulated = Double(loan.usedLoanAmount ?? "0") ?? 0
```

**修正後的正確邏輯：**
```swift
// ✅ 正確：從月度管理表查詢最新記錄
let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
fetchRequest.predicate = NSPredicate(
    format: "client == %@ AND loanType == %@",
    client,
    loan.loanType ?? ""
)
fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
fetchRequest.fetchLimit = 1

if let latestRecord = try? viewContext.fetch(fetchRequest).first {
    baseAccumulated = Double(latestRecord.usedLoanAccumulated ?? "0") ?? 0
} else {
    baseAccumulated = 0  // 沒有歷史記錄，從 0 開始
}
```

**自動計算：**
```swift
// 輸入已動用貸款時，自動計算累積
TextField("已動用貸款", text: $usedLoanAmount)
    .onChange(of: usedLoanAmount) { oldValue, newValue in
        let currentUsed = Double(removeCommas(usedLoanAmount)) ?? 0
        let newAccumulated = baseAccumulated + currentUsed
        usedLoanAccumulated = formatNumber(newAccumulated)
    }
```

**使用範例：**
```
假設某貸款的月度記錄：
2024-01-01: 動用 100,000 → 累積 100,000
2024-02-01: 動用  50,000 → 累積 150,000  (100,000 + 50,000)
2024-03-01: 動用  30,000 → 累積 180,000  (150,000 + 30,000)

當新增 2024-04-01 記錄時：
- 查詢最新記錄（2024-03-01）的累積：180,000
- 輸入本次動用：20,000
- 自動計算新累積：200,000 (180,000 + 20,000)
```

#### 3. 數據雙向同步機制

**核心設計原則：**
- **單一數據源：** `LoanMonthlyData.usedLoanAccumulated`
- **快取機制：** `Loan.usedLoanAmount`（僅用於快速顯示）
- **同步規則：** 所有操作後，`Loan.usedLoanAmount` 必須等於月度管理最新記錄的累積值

**同步時機 1：月度管理保存後**
```swift
// AddLoanMonthlyDataView.swift: saveData()
do {
    try viewContext.save()

    // 保存後，查詢該貸款最新記錄，同步到 Loan
    if let loan = selectedLoan {
        let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "client == %@ AND loanType == %@",
            client,
            loan.loanType ?? ""
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
        fetchRequest.fetchLimit = 1

        if let latestRecord = try? viewContext.fetch(fetchRequest).first {
            loan.usedLoanAmount = latestRecord.usedLoanAccumulated ?? "0"
        }

        try viewContext.save()
    }
}
```

**同步時機 2：貸款列表動用後**
```swift
// LoanManagementView.swift: saveUsedAmount()
// 1. 查詢月度管理最新記錄的已動用累積
let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
// ... 查詢邏輯

// 2. 計算新累積
let newTotal = currentUsed + inputAmount

// 3. 更新 Loan（快取）
loan.usedLoanAmount = String(format: "%.2f", newTotal)

// 4. 創建月度記錄（真正的數據源）
monthlyData.usedLoanAccumulated = String(format: "%.2f", newTotal)
```

**數據流向圖：**
```
┌─────────────────────────────────────────┐
│     LoanMonthlyData（單一數據源）         │
│  ┌──────────────────────────────────┐   │
│  │ 2024-01-01: 累積 100,000        │   │
│  │ 2024-02-01: 累積 150,000        │   │
│  │ 2024-03-01: 累積 180,000 ← 最新 │   │
│  └──────────────────────────────────┘   │
└──────────────────┬──────────────────────┘
                   │ 同步
                   ↓
         ┌─────────────────┐
         │   Loan 快取      │
         │ usedLoanAmount  │
         │   = 180,000     │
         └─────────────────┘
                   │
                   ↓ 顯示
         ┌─────────────────┐
         │   貸款列表 UI    │
         │ 已動用累積顯示   │
         └─────────────────┘
```

#### 4. 編輯模式的特殊處理

**問題：** 編輯現有記錄時，基礎累積應該是什麼？

**解決方案：**
```swift
// 編輯模式下，基礎累積 = 當前累積 - 本次已動用
if let data = dataToEdit {
    // 載入數據...

    // 根據 loanType 找到對應的 Loan
    if let loansSet = client.loans as? Set<Loan> {
        let foundLoan = loansSet.first { $0.loanType == data.loanType }
        _selectedLoan = State(initialValue: foundLoan)

        // 設置基礎累積
        if let accumulated = Double(data.usedLoanAccumulated ?? "0"),
           let used = Double(data.usedLoanAmount ?? "0") {
            _baseAccumulated = State(initialValue: accumulated - used)
        }
    }
}
```

**範例：**
```
編輯 2024-02-01 的記錄：
- 當前記錄：動用 50,000，累積 150,000
- 前一筆記錄（2024-01-01）：累積 100,000
- 計算基礎累積：150,000 - 50,000 = 100,000 ✅

修改動用金額為 80,000：
- 新累積 = 100,000 + 80,000 = 180,000 ✅
```

### 技術細節

#### 數據一致性保證

**規則 1：** 所有累積計算都從月度管理表讀取
```swift
// ✅ 正確
let fetchRequest = LoanMonthlyData.fetchRequest()
fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
fetchRequest.fetchLimit = 1
let latestRecord = try? viewContext.fetch(fetchRequest).first
let baseValue = Double(latestRecord?.usedLoanAccumulated ?? "0") ?? 0

// ❌ 錯誤
let baseValue = Double(loan.usedLoanAmount ?? "0") ?? 0
```

**規則 2：** 每次操作後必須同步
```swift
// 保存順序：
// 1. 先保存 LoanMonthlyData
try viewContext.save()

// 2. 再查詢最新記錄
let latest = fetchLatestRecord()

// 3. 同步到 Loan
loan.usedLoanAmount = latest.usedLoanAccumulated

// 4. 最後保存 Loan
try viewContext.save()
```

**規則 3：** 按日期排序確保順序正確
```swift
fetchRequest.sortDescriptors = [
    NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)
]
```

### 使用情境

#### 情境 1：從零開始動用貸款

**步驟：**
1. 貸款列表沒有任何動用記錄
2. 在月度管理點擊「＋」新增記錄
3. 選擇貸款後，系統顯示：
   - 貸款金額：自動填充
   - 已動用累積：0（基礎值）
4. 輸入已動用貸款：100,000
5. 系統自動計算：已動用累積 = 0 + 100,000 = 100,000
6. 保存後：
   - 月度管理有一筆記錄（累積 100,000）
   - 貸款列表顯示已動用累積：100,000

#### 情境 2：持續動用貸款

**初始狀態：**
- 2024-01-01: 累積 100,000

**操作：**
1. 2024-02-01 新增記錄
2. 選擇貸款後，系統從月度管理查詢最新記錄
3. 顯示基礎累積：100,000
4. 輸入已動用：50,000
5. 自動計算：150,000
6. 保存後兩邊數據一致

#### 情境 3：修改歷史記錄

**初始狀態：**
- 2024-01-01: 動用 100,000，累積 100,000
- 2024-02-01: 動用 50,000，累積 150,000
- 2024-03-01: 動用 30,000，累積 180,000

**操作：編輯 2024-02-01**
1. 打開編輯，顯示：
   - 已動用貸款：50,000
   - 已動用累積：150,000
2. 修改已動用為：80,000
3. 自動計算：累積 = 100,000 + 80,000 = 180,000
4. 保存後：
   - 2024-02-01 更新為：動用 80,000，累積 180,000
   - 2024-03-01 不受影響（仍然是累積 180,000）
   - 貸款列表同步為最新記錄（2024-03-01）的累積：180,000

**注意：** 修改中間記錄不會自動更新後續記錄，用戶需要手動調整後續記錄。

#### 情境 4：從貸款列表動用

**步驟：**
1. 貸款列表點擊「動用」按鈕
2. 輸入金額：20,000
3. 系統自動：
   - 查詢月度管理最新記錄的累積
   - 創建新的月度記錄（今天日期）
   - 計算新累積並同步到貸款列表
4. 結果：
   - 月度管理新增一筆記錄
   - 貸款列表累積值更新

### 重要提醒

1. **數據源唯一性**
   - `LoanMonthlyData.usedLoanAccumulated` 是唯一真實數據源
   - `Loan.usedLoanAmount` 只是快取，用於快速顯示
   - 所有計算都應從月度管理表讀取

2. **編輯歷史記錄的影響**
   - 修改中間月份的記錄不會自動更新後續月份
   - 如需調整，應按日期順序逐月更新
   - 或刪除後續記錄重新輸入

3. **刪除記錄的處理**
   - 刪除月度記錄後，應重新計算並同步 Loan 的累積值
   - 建議刪除後自動觸發同步

4. **多筆相同日期記錄**
   - 目前設計允許同一天多次動用
   - 每次動用都會累加到累積值
   - 查詢最新記錄時只取日期最大的一筆

### 文件更新
- ✅ `AddLoanMonthlyDataView.swift` - 貸款選擇改為 Picker、修正累積計算邏輯、實現數據同步
- ✅ `LoanManagementView.swift` - 修正動用功能的累積計算邏輯
- ✅ 建立以月度管理表為單一數據源的同步機制

---

## 2025-11-13 更新：貸款/投資月度管理欄位排序功能

### 功能概述

為「貸款/投資月度管理」表格新增欄位排序功能，允許用戶自訂欄位顯示順序，提升使用體驗和工作效率。

### 實現功能

#### 1. 欄位排序按鈕

**檔案：** `LoanMonthlyDataTableView.swift`

**位置：** 工具列（line 118-128）

**按鈕樣式：**
```swift
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
```

**樣式統一：** 與「月度資產明細」的排序按鈕保持一致設計
- 圖示：`arrow.up.arrow.down`
- 顏色：藍色 (`.blue`)
- 背景：淺藍色圓形背景

#### 2. 動態欄位渲染

**新增狀態變數：**
```swift
@State private var showingColumnReorder = false  // 控制排序畫面顯示
@State private var columnOrder: [String] = []    // 儲存用戶自訂的欄位順序
```

**預設欄位順序：**
```swift
private let defaultHeaders = [
    "日期", "貸款類型", "貸款金額", "已動用貸款", "已動用累積",
    "台股", "美股", "債券", "定期定額",
    "台股成本", "美股成本", "債券成本", "定期定額成本",
    "匯率", "美股加債券折合台幣", "投資總額"
]
```

**計算屬性（取得當前欄位順序）：**
```swift
private var currentColumnOrder: [String] {
    if columnOrder.isEmpty {
        return defaultHeaders
    }
    return columnOrder
}
```

#### 3. 欄位排序介面整合

**Sheet 展示：**
```swift
.sheet(isPresented: $showingColumnReorder) {
    ColumnReorderView(
        headers: defaultHeaders,
        initialOrder: columnOrder.isEmpty ? defaultHeaders : columnOrder,
        onSave: { newOrder in
            columnOrder = newOrder
            UserDefaults.standard.set(newOrder, forKey: "LoanMonthlyData_ColumnOrder")
        }
    )
}
```

**持久化儲存：**
```swift
.onAppear {
    if let savedOrder = UserDefaults.standard.array(forKey: "LoanMonthlyData_ColumnOrder") as? [String],
       !savedOrder.isEmpty {
        columnOrder = savedOrder
    }
}
```

**儲存鍵值：** `"LoanMonthlyData_ColumnOrder"`（與月度資產明細的 `"MonthlyAsset_ColumnOrder"` 獨立）

#### 4. 表格表頭動態渲染

**修改前（固定欄位）：**
```swift
ForEach(headers, id: \.self) { header in
    // 渲染表頭
}
```

**修改後（動態欄位）：**
```swift
ForEach(currentColumnOrder, id: \.self) { header in
    Button(action: {
        toggleSort(for: header)
    }) {
        HStack(spacing: 4) {
            Text(header)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

            if sortColumn == header {
                Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .frame(minWidth: getColumnWidth(for: header), alignment: .leading)
    }
    .buttonStyle(PlainButtonStyle())
}
```

#### 5. 資料行動態渲染

**建立欄位視圖建構器：**
```swift
// MARK: - 數據行
private func dataRow(data: LoanMonthlyData, index: Int) -> some View {
    HStack(spacing: 0) {
        // 刪除按鈕
        Button(action: {
            deleteData(data)
        }) {
            Image(systemName: "trash.fill")
                .font(.system(size: 12))
                .foregroundColor(.red)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(PlainButtonStyle())

        // 根據 currentColumnOrder 動態渲染欄位
        ForEach(currentColumnOrder, id: \.self) { header in
            cellView(for: header, data: data)
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
```

**欄位視圖函數：**
```swift
// MARK: - 欄位視圖
@ViewBuilder
private func cellView(for header: String, data: LoanMonthlyData) -> some View {
    let defaultColor = Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0))
    let greenColor = Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0))

    switch header {
    case "日期":
        Text(data.date ?? "")
            .font(.system(size: 12))
            .foregroundColor(defaultColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

    case "貸款類型":
        Text(data.loanType ?? "")
            .font(.system(size: 12))
            .foregroundColor(defaultColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

    // ... 其他欄位（共 16 個欄位）

    case "已動用累積":
        Text(formatNumber(data.usedLoanAccumulated ?? ""))
            .font(.system(size: 12))
            .foregroundColor(.orange)  // 特殊顏色
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

    case "投資總額":
        Text(formatNumber(data.totalInvestment ?? ""))
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(greenColor)  // 特殊顏色 + 粗體
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(minWidth: getColumnWidth(for: header), alignment: .leading)

    default:
        Text("")
            .frame(minWidth: getColumnWidth(for: header), alignment: .leading)
    }
}
```

### 技術實現細節

#### 使用的元件

**ColumnReorderView** - 可重用的欄位排序元件
- 位置：`InvestmentDashboard/ColumnReorderView.swift`
- 功能：拖放排序介面
- 使用 SwiftUI List 的 `.onMove` modifier 實現拖放功能

**參數說明：**
```swift
ColumnReorderView(
    headers: [String],           // 所有可用的欄位名稱
    initialOrder: [String],      // 初始欄位順序
    onSave: ([String]) -> Void   // 儲存回調函數
)
```

#### 資料流程

```
使用者點擊排序按鈕
    ↓
開啟 ColumnReorderView sheet
    ↓
使用者拖放調整欄位順序
    ↓
點擊「完成」按鈕
    ↓
觸發 onSave 回調
    ↓
更新 columnOrder 狀態
    ↓
儲存到 UserDefaults
    ↓
關閉 sheet
    ↓
表格自動重新渲染（使用新順序）
```

#### 持久化機制

**儲存位置：** `UserDefaults.standard`

**儲存鍵值：** `"LoanMonthlyData_ColumnOrder"`

**資料格式：** `[String]` 陣列

**範例：**
```swift
// 儲存
UserDefaults.standard.set(
    ["日期", "貸款金額", "已動用貸款", "台股", "美股"],
    forKey: "LoanMonthlyData_ColumnOrder"
)

// 讀取
if let savedOrder = UserDefaults.standard.array(forKey: "LoanMonthlyData_ColumnOrder") as? [String] {
    columnOrder = savedOrder
}
```

### 使用者操作流程

1. **開啟欄位排序**
   - 點擊工具列上的藍色排序按鈕（圖示：上下箭頭）
   - 彈出「調整欄位順序」畫面

2. **調整欄位順序**
   - 長按欄位右側的拖動圖示（三橫線）
   - 上下拖動到目標位置
   - 釋放手指完成調整

3. **儲存設定**
   - 點擊右上角「完成」按鈕
   - 欄位順序立即生效
   - 設定自動儲存

4. **取消變更**
   - 點擊左上角「取消」按鈕
   - 放棄此次調整，維持原順序

5. **恢復預設順序**
   - 在排序畫面中，將欄位調整回預設順序
   - 或刪除 App 重新安裝（清除 UserDefaults）

### 與月度資產明細的一致性

| 特性 | 月度資產明細 | 貸款/投資月度管理 |
|------|-------------|------------------|
| 排序按鈕圖示 | `arrow.up.arrow.down` | `arrow.up.arrow.down` ✅ |
| 按鈕顏色 | 藍色 | 藍色 ✅ |
| 背景樣式 | 淺藍圓形 | 淺藍圓形 ✅ |
| 排序元件 | `ColumnReorderView` | `ColumnReorderView` ✅ |
| 儲存機制 | UserDefaults | UserDefaults ✅ |
| 儲存鍵值 | `MonthlyAsset_ColumnOrder` | `LoanMonthlyData_ColumnOrder` |
| 拖放功能 | 支援 | 支援 ✅ |

### 優點與好處

1. **個人化體驗**
   - ✅ 用戶可依照工作習慣調整欄位順序
   - ✅ 常用欄位可移到前面，提升查看效率

2. **一致性設計**
   - ✅ 與月度資產明細功能和樣式完全一致
   - ✅ 降低學習成本，提升用戶熟悉度

3. **持久化設定**
   - ✅ 欄位順序自動儲存
   - ✅ App 重啟後保持用戶設定

4. **靈活性**
   - ✅ 支援 16 個欄位的任意排序
   - ✅ 可隨時調整，立即生效

5. **程式碼可維護性**
   - ✅ 使用可重用元件 `ColumnReorderView`
   - ✅ 使用 `@ViewBuilder` 建構動態視圖
   - ✅ Switch-case 結構清晰，易於擴充

### 技術重點

1. **動態渲染**
   - 使用 `ForEach(currentColumnOrder, ...)` 動態生成欄位
   - 使用 `@ViewBuilder` 函數返回不同的視圖

2. **狀態管理**
   - `@State` 管理欄位順序和 sheet 顯示狀態
   - `UserDefaults` 實現跨啟動持久化

3. **計算屬性**
   - `currentColumnOrder` 提供簡潔的介面
   - 自動處理空值情況（返回預設順序）

4. **元件重用**
   - `ColumnReorderView` 同時服務多個表格
   - 統一的排序體驗

### 文件更新

- ✅ `LoanMonthlyDataTableView.swift` - 新增欄位排序功能、動態表頭與資料行渲染、統一按鈕樣式
- ✅ 使用 `ColumnReorderView` 可重用元件
- ✅ 實現 UserDefaults 持久化儲存
- ✅ 與月度資產明細保持一致的使用者體驗

---

## 2025-11-13 更新：修正貸款月度管理投資總額計算公式

### 問題發現

在「貸款/投資月度管理」的投資總額計算公式中發現錯誤。

### 錯誤的計算公式

**檔案**：`AddLoanMonthlyDataView.swift` (line 51-60)

**錯誤公式**：
```swift
投資總額 = 台股 + 美股 + 債券 + 定期定額
```

**問題**：
- 美股和債券應該先轉換為台幣（乘以匯率），再與台股相加
- 目前的公式將不同幣別的金額直接相加，導致計算錯誤

### 正確的計算公式

**修正後**：
```swift
// 計算屬性：投資總額 = 台股 + 美股加債券折合台幣
private var calculatedTotalInvestment: String {
    let taiwanStockValue = Double(removeCommas(taiwanStock)) ?? 0
    let usStockBondsInTwdValue = Double(removeCommas(calculatedUsStockBondsInTwd)) ?? 0

    let result = taiwanStockValue + usStockBondsInTwdValue
    return formatWithCommas(String(format: "%.2f", result))
}
```

**計算邏輯**：
1. 先計算「美股加債券折合台幣」= (美股 + 債券) × 匯率
2. 投資總額 = 台股 + 美股加債券折合台幣

### 計算範例

假設輸入數據：
- 台股：500,000
- 美股：10,000（美元）
- 債券：5,000（美元）
- 匯率：32

**修正前（錯誤）**：
```
投資總額 = 500,000 + 10,000 + 5,000 + 0 = 515,000  ❌ 錯誤
```

**修正後（正確）**：
```
美股加債券折合台幣 = (10,000 + 5,000) × 32 = 480,000
投資總額 = 500,000 + 480,000 = 980,000  ✅ 正確
```

### 影響範圍

此修正影響以下功能：
1. **新增月度數據**：`AddLoanMonthlyDataView.swift` 的投資總額計算
2. **編輯月度數據**：使用相同的計算邏輯
3. **月度數據顯示**：表格中顯示的投資總額會自動更新為正確值

### 資料一致性

**已儲存的歷史資料**：
- 如果之前已經儲存了月度數據，這些數據的投資總額可能是錯誤的
- 建議重新編輯這些記錄，系統會自動重新計算並儲存正確的值

**新增的資料**：
- 所有新增的月度數據都會使用正確的計算公式
- 投資總額會正確反映台幣總值

### 相關欄位說明

| 欄位名稱 | 幣別 | 說明 |
|---------|------|------|
| 台股 | TWD | 台幣金額 |
| 美股 | USD | 美元金額 |
| 債券 | USD | 美元金額 |
| 定期定額 | TWD | 台幣金額 |
| 匯率 | - | 美元對台幣匯率 |
| 美股加債券折合台幣 | TWD | (美股 + 債券) × 匯率 |
| 投資總額 | TWD | 台股 + 美股加債券折合台幣 |

### 文件更新

- ✅ `AddLoanMonthlyDataView.swift` - 修正投資總額計算公式（line 51-58）

---

## 2025-11-13 更新：App Store 審核問題修正

### 審核回饋

**審核編號**：ed6a0138-bdab-4f81-bdcd-4052d030abe7
**審核日期**：2025年11月13日
**審核版本**：1.0
**測試設備**：iPad Air 11-inch (M3), iPadOS 26.0.1

### 審核問題總覽

#### 問題 1：免費試用資訊未在 StoreKit 付款頁面顯示
**準則**：Guideline 2.1 - Performance - App Completeness
**問題描述**：審核團隊在測試內購時，發現 StoreKit 付款頁面沒有顯示「免費試用資訊」

**根本原因**：
1. 本地 `Configuration.storekit` 文件的 localizations 欄位為空
2. App Store Connect 的訂閱產品可能沒有正確設定介紹性優惠（免費試用期）

#### 問題 2：促銷圖片不符合規範
**準則**：Guideline 2.3.2 - Performance - Accurate Metadata
**問題描述**：促銷圖片（promotional image）是從 App 直接截圖，不符合 Apple 規範

**Apple 要求**：
- 促銷圖片應該是獨特設計的圖片
- 不能使用 App 截圖
- 應準確代表內購產品的價值

#### 問題 3：內購描述包含價格引用
**準則**：Guideline 2.3.2 - Performance - Accurate Metadata
**問題描述**：「月費方案」的描述中包含價格引用（如「NT$100」）

**Apple 規定**：
- 價格已在產品頁面顯示，描述中不應重複
- 價格可能因國家/地區不同而不準確
- 顯示名稱最多 30 字元，描述最多 45 字元

### 修正方案

#### 修正 1：更新 Configuration.storekit 本地化資訊

**檔案**：`Configuration.storekit`

**修改前**：
```json
"localizations" : [
  {
    "description" : "",
    "displayName" : "",
    "locale" : "en_US"
  }
]
```

**修改後**：
```json
"localizations" : [
  {
    "description" : "Unlock all premium features",
    "displayName" : "Monthly Subscription",
    "locale" : "en_US"
  },
  {
    "description" : "解鎖所有進階功能",
    "displayName" : "月費方案",
    "locale" : "zh_TW"
  }
]
```

**重要性**：這些本地化資訊會被 StoreKit 2 用於顯示訂閱詳情

#### 修正 2：App Store Connect 設定檢查清單

需要在 App Store Connect 確認以下設定：

1. **訂閱產品 ID**：`com.owenliu.investmentdashboard.monthly`

2. **免費試用期設定**：
   - 介紹性優惠類型：免費試用（Free Trial）
   - 期限：1 個月（1 Month）
   - 確認顯示：「首月免費，之後每月 NT$100」

3. **本地化資訊**（**不包含價格**）：
   ```
   繁體中文 (zh-Hant):
   - 顯示名稱：月費方案（≤30 字元）
   - 描述：解鎖所有進階功能（≤45 字元）

   英文 (en-US):
   - Display Name: Monthly Subscription
   - Description: Unlock all premium features
   ```

4. **促銷圖片**：
   - 選項 A：設計獨特的 1024x1024 圖片（推薦）
   - 選項 B：刪除促銷圖片（如不打算推廣）

#### 修正 3：審查備註建議

提交時在「審查備註」中說明修正內容（英文版本）：

```
Dear App Review Team,

Thank you for your feedback. We have made the following changes:

1. Free Trial Information (Guideline 2.1):
   - Updated subscription product configuration in App Store Connect
   - Ensured introductory offer (1-month free trial) is properly set
   - Verified free trial information now appears on StoreKit payment sheet

2. Promotional Image (Guideline 2.3.2):
   - Replaced screenshot with unique designed promotional image
   OR
   - Removed promotional image as we don't plan to promote this IAP

3. IAP Description (Guideline 2.3.2):
   - Removed all price references from subscription description
   - Updated description to: "Unlock all premium features"

Attached screenshots show free trial information correctly displayed.

Thank you for your time and consideration.
```

### 技術實現說明

#### StoreKit 2 購買流程（已正確實現）

**檔案**：`SubscriptionManager.swift` (line 66-93)

```swift
func purchase() async throws {
    guard let product = products.first else {
        throw SubscriptionError.productNotFound
    }

    // 使用 StoreKit 2 API，會自動顯示 Apple 標準付款頁面
    let result = try await product.purchase()

    switch result {
    case .success(let verification):
        let transaction = try Self.checkVerified(verification)
        await updateSubscriptionStatus()
        await transaction.finish()

    case .userCancelled:
        throw SubscriptionError.userCancelled

    case .pending:
        throw SubscriptionError.purchasePending

    @unknown default:
        throw SubscriptionError.unknown
    }
}
```

**關鍵點**：
- `product.purchase()` 會自動顯示 Apple 的標準付款頁面
- 付款頁面會自動顯示免費試用資訊（前提是 App Store Connect 設定正確）
- 不需要自訂付款 UI

#### 訂閱產品配置（已確認正確）

**檔案**：`Configuration.storekit` (line 57-62)

```json
"introductoryOffer" : {
  "displayPrice" : "0",
  "internalID" : "2854A36E",
  "paymentMode" : "free",
  "subscriptionPeriod" : "P1M"  // 1個月免費試用
}
```

### 測試驗證步驟

在重新提交前，請完成以下測試：

1. **沙箱測試帳號測試**：
   - 創建新的沙箱測試帳號
   - 在真機上測試購買流程
   - 確認付款頁面顯示「首月免費，之後每月 NT$100」

2. **截圖準備**：
   - 付款頁面顯示免費試用資訊
   - 訂閱管理頁面顯示試用期狀態
   - App Store Connect 設定頁面

3. **功能驗證**：
   - 免費試用期內所有功能可用
   - 試用期結束後轉為付費訂閱
   - 恢復購買功能正常運作

### 預計審查時程

| 階段 | 預計時間 |
|------|----------|
| 完成 App Store Connect 修改 | 30 分鐘 |
| 本地測試驗證 | 1 小時 |
| 構建並上傳新版本（Build 2） | 30 分鐘 |
| Apple 審查時間 | 1-3 天 |
| **總計** | **2-4 天** |

### Apple 審查準則引用

**2.1 - Performance - App Completeness**
> Apps should contain all necessary information and clearly disclose all costs upfront, including subscription pricing and trial information.

**2.3.2 - Performance - Accurate Metadata**
> App metadata should accurately represent the app's content and functionality. Promotional images must be unique and not simple screenshots.

### 相關資源

- **詳細修正指南**：`App_Store_審核問題修正指南.md`
- **StoreKit 2 文件**：https://developer.apple.com/documentation/storekit
- **訂閱最佳實踐**：https://developer.apple.com/app-store/subscriptions/
- **App Store 審查準則**：https://developer.apple.com/app-store/review/guidelines/

### 文件更新

- ✅ `Configuration.storekit` - 新增本地化資訊（英文、繁體中文）
- ✅ `App_Store_審核問題修正指南.md` - 詳細的修正步驟與說明
- ⚠️ App Store Connect 設定需要手動更新（必須完成）
- ⚠️ 促銷圖片需要設計或刪除（必須完成）

### 後續步驟

1. ✅ 已完成本地代碼修改
2. ⚠️ **待完成**：更新 App Store Connect 訂閱設定
3. ⚠️ **待完成**：處理促銷圖片（設計新圖或刪除）
4. ⚠️ **待完成**：修改內購描述移除價格
5. ⚠️ **待完成**：測試驗證並截圖
6. ⚠️ **待完成**：構建 Build 2 並重新提交審查

---

## 2025-11-13：修正貸款月度管理「已動用累積」計算邏輯

### 問題描述

在「貸款/投資月度管理」中，當用戶在既有數據中間插入新資料時，「已動用累積」欄位會計算錯誤。後續資料的累積值沒有自動更新。

**問題場景範例：**

原始數據：
- 2024-01-01: 已動用 100 → 已動用累積 100
- 2024-03-01: 已動用 50 → 已動用累積 150
- 2024-05-01: 已動用 30 → 已動用累積 180

插入新資料：
- 2024-02-01: 已動用 20

**期望結果：**
- 2024-01-01: 已動用 100 → 已動用累積 100 ✅
- 2024-02-01: 已動用 20 → 已動用累積 120 ✅
- 2024-03-01: 已動用 50 → 已動用累積 170 ✅
- 2024-05-01: 已動用 30 → 已動用累積 200 ✅

**實際結果（修正前）：**
- 2024-01-01: 已動用 100 → 已動用累積 100 ✅
- 2024-02-01: 已動用 20 → 已動用累積 120 ✅
- 2024-03-01: 已動用 50 → 已動用累積 150 ❌（應為 170）
- 2024-05-01: 已動用 30 → 已動用累積 180 ❌（應為 200）

### 根本原因

**AddLoanMonthlyDataView.swift:320-383（修正前）**

原本的 `saveData()` 函數只保存當前資料，沒有重新計算後續資料的累積值：

```swift
private func saveData() {
    // ... 保存當前資料

    // 只更新 Loan 的最新累積值，沒有更新中間資料
    if let loan = selectedLoan {
        let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
        fetchRequest.fetchLimit = 1

        if let latestRecord = try? viewContext.fetch(fetchRequest).first {
            loan.usedLoanAmount = latestRecord.usedLoanAccumulated ?? "0"
        }
    }
}
```

### 解決方案

**AddLoanMonthlyDataView.swift:385-412（新增）**

新增 `recalculateAccumulatedAmounts(for:)` 函數，在保存後自動重新計算該貸款類型所有資料的累積值：

```swift
/// 重新計算該貸款類型所有月度資料的已動用累積
private func recalculateAccumulatedAmounts(for loanType: String) {
    let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
    fetchRequest.predicate = NSPredicate(
        format: "client == %@ AND loanType == %@",
        client,
        loanType
    )
    // 按日期升序排列（從舊到新）
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: true)]

    do {
        let allRecords = try viewContext.fetch(fetchRequest)
        var accumulated: Double = 0

        // 依序重新計算每筆資料的累積值
        for record in allRecords {
            let usedAmount = Double(record.usedLoanAmount ?? "0") ?? 0
            accumulated += usedAmount
            record.usedLoanAccumulated = String(format: "%.2f", accumulated)
        }

        try viewContext.save()
        print("已重新計算 \(loanType) 的累積值，共 \(allRecords.count) 筆資料")
    } catch {
        print("重新計算累積值時發生錯誤: \(error)")
    }
}
```

**AddLoanMonthlyDataView.swift:320-383（修正後）**

在 `saveData()` 中調用重新計算函數：

```swift
private func saveData() {
    // ... 保存當前資料

    try viewContext.save()

    // ✅ 新增：保存後，重新計算該貸款類型所有資料的累積值
    if let loan = selectedLoan {
        recalculateAccumulatedAmounts(for: loan.loanType ?? "")

        // 更新 Loan 的累積值為最新記錄
        let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "client == %@ AND loanType == %@",
            client,
            loan.loanType ?? ""
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
        fetchRequest.fetchLimit = 1

        if let latestRecord = try? viewContext.fetch(fetchRequest).first {
            loan.usedLoanAmount = latestRecord.usedLoanAccumulated ?? "0"
        }

        try viewContext.save()
    }
}
```

### 計算邏輯

1. **查詢該貸款類型所有資料**：
   ```swift
   fetchRequest.predicate = NSPredicate(
       format: "client == %@ AND loanType == %@",
       client,
       loanType
   )
   ```

2. **按日期升序排序（從舊到新）**：
   ```swift
   fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: true)]
   ```

3. **依序累加計算**：
   ```swift
   var accumulated: Double = 0
   for record in allRecords {
       let usedAmount = Double(record.usedLoanAmount ?? "0") ?? 0
       accumulated += usedAmount  // 累加
       record.usedLoanAccumulated = String(format: "%.2f", accumulated)
   }
   ```

### 計算範例

**資料按日期排序後：**
```
2024-01-01: 已動用 100 → accumulated = 0 + 100 = 100
2024-02-01: 已動用 20  → accumulated = 100 + 20 = 120
2024-03-01: 已動用 50  → accumulated = 120 + 50 = 170
2024-05-01: 已動用 30  → accumulated = 170 + 30 = 200
```

**最終結果：**
- 2024-01-01: 已動用累積 = 100 ✅
- 2024-02-01: 已動用累積 = 120 ✅
- 2024-03-01: 已動用累積 = 170 ✅
- 2024-05-01: 已動用累積 = 200 ✅

### 優點

1. **自動修正**：
   - 無論新增、編輯、刪除任何資料
   - 保存後自動重新計算所有累積值
   - 確保數據一致性

2. **歷史數據修正**：
   - 即使編輯舊資料，也會正確更新後續所有記錄
   - 不需要手動重新輸入

3. **簡化用戶操作**：
   - 用戶只需輸入「已動用貸款」
   - 系統自動計算並更新所有累積值

### 影響範圍

**修改檔案**：
- `AddLoanMonthlyDataView.swift`
  - 新增 `recalculateAccumulatedAmounts(for:)` 函數（line 385-412）
  - 修改 `saveData()` 函數（line 320-383）

**相關功能**：
- 新增月度數據
- 編輯月度數據
- 貸款列表的累積值同步更新

**測試建議**：
1. 新增一筆較早日期的資料，確認後續資料累積值正確更新
2. 編輯中間某筆資料的已動用金額，確認後續累積值正確更新
3. 刪除中間某筆資料，確認後續累積值正確更新（需額外實現刪除時也調用重新計算）

### 注意事項

目前的實現在新增和編輯時會自動重新計算。如果未來新增刪除功能，也需要在刪除後調用 `recalculateAccumulatedAmounts(for:)` 以確保數據一致性。

---

## 2025-11-13：優化投資月度管理輸入體驗

### 問題描述

在「投資月度管理」新增資料時，用戶遇到兩個體驗問題：

1. **缺少預填功能**：每次新增都要重新輸入所有欄位，特別是投資資產數據（台股、美股、債券等）通常與上一筆相似
2. **欄位辨識困難**：當輸入框已有數值時，無法快速分辨是哪個欄位，因為欄位名稱顯示在 placeholder 中

### 解決方案

#### 1. 新增時自動預填前一筆資料

**AddLoanMonthlyDataView.swift:100-120（新增）**

在 `init` 函數中新增新增模式的預填邏輯：

```swift
} else {
    // 新增模式：查詢最新一筆資料並預填
    let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "client == %@", client)
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
    fetchRequest.fetchLimit = 1

    let context = PersistenceController.shared.container.viewContext
    if let latestData = try? context.fetch(fetchRequest).first {
        // 預填投資資產數據（不包含貸款資訊）
        _taiwanStock = State(initialValue: Self.formatNumberForDisplay(latestData.taiwanStock ?? ""))
        _usStock = State(initialValue: Self.formatNumberForDisplay(latestData.usStock ?? ""))
        _bonds = State(initialValue: Self.formatNumberForDisplay(latestData.bonds ?? ""))
        _regularInvestment = State(initialValue: Self.formatNumberForDisplay(latestData.regularInvestment ?? ""))
        _taiwanStockCost = State(initialValue: Self.formatNumberForDisplay(latestData.taiwanStockCost ?? ""))
        _usStockCost = State(initialValue: Self.formatNumberForDisplay(latestData.usStockCost ?? ""))
        _bondsCost = State(initialValue: Self.formatNumberForDisplay(latestData.bondsCost ?? ""))
        _regularInvestmentCost = State(initialValue: Self.formatNumberForDisplay(latestData.regularInvestmentCost ?? ""))
        _exchangeRate = State(initialValue: latestData.exchangeRate ?? "32")
    }
}
```

**預填邏輯**：
- 查詢該客戶最新一筆月度資料
- 預填投資資產相關欄位（台股、美股、債券、定期定額）
- 預填成本資訊（台股成本、美股成本、債券成本、定期定額成本）
- 預填匯率
- **不預填**貸款相關資訊（貸款金額、已動用貸款、已動用累積）

**為什麼不預填貸款資訊？**
- 貸款資訊需要用戶選擇貸款後自動填入
- 已動用累積會根據所選貸款自動計算
- 避免混淆不同貸款的數據

#### 2. 調整 UI 布局：欄位名稱在左、輸入框在右

**問題**：原本使用 `TextField("欄位名稱", text: $binding)` 的方式，欄位名稱顯示在 placeholder 中，當有預填值時看不到欄位名稱。

**解決方案**：改用 HStack 布局，左側顯示固定的欄位名稱，右側是輸入框。

**修改前**：
```swift
TextField("台股", text: $taiwanStock)
    .keyboardType(.decimalPad)
```

**修改後**：
```swift
HStack {
    Text("台股")
        .frame(width: 100, alignment: .leading)
    TextField("", text: $taiwanStock)
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.trailing)
        .onChange(of: taiwanStock) { oldValue, newValue in
            formatNumberField(&taiwanStock, newValue)
        }
}
```

**布局特點**：
- `Text` 固定在左側，寬度 100pt
- `TextField` placeholder 為空字串
- 數值靠右對齊（`.multilineTextAlignment(.trailing)`）
- 清楚顯示欄位名稱，即使有預填值也能清楚辨識

**修改範圍**：
- 基本資訊：貸款金額、已動用貸款、已動用累積
- 投資資產：台股、美股、債券、定期定額
- 成本資訊：台股成本、美股成本、債券成本、定期定額成本
- 匯率與計算：匯率

### 實際效果

#### 修改前

**新增資料**：
- 所有欄位都是空的
- 需要重新輸入所有數值
- 當開始輸入後，欄位名稱（placeholder）消失，不易辨識

```
┌─────────────────────────┐
│ [     100,000          ] │ ← 輸入後看不到這是哪個欄位
│ [     50,000           ] │
│ [     20,000           ] │
└─────────────────────────┘
```

#### 修改後

**新增資料**：
- 自動帶入前一筆的投資資產數據
- 只需修改有變化的欄位
- 欄位名稱永遠顯示在左側

```
┌──────────────────────────┐
│ 台股      [   100,000   ] │ ← 清楚知道是台股
│ 美股      [    50,000   ] │ ← 清楚知道是美股
│ 債券      [    20,000   ] │ ← 清楚知道是債券
└──────────────────────────┘
```

### 使用場景範例

**場景**：用戶每月記錄投資資產

**2024-11-01 第一筆資料**：
- 台股：500,000
- 美股：10,000
- 債券：5,000
- 匯率：32

**2024-12-01 新增第二筆**：
1. 點擊「新增月度數據」
2. 系統自動預填：
   - 台股：500,000
   - 美股：10,000
   - 債券：5,000
   - 匯率：32
3. 用戶只需修改有變化的欄位：
   - 台股改為：520,000（+20,000）
   - 其他保持不變
4. 選擇貸款並輸入已動用金額
5. 保存

### 技術細節

#### 預填數據查詢

**查詢條件**：
```swift
fetchRequest.predicate = NSPredicate(format: "client == %@", client)
fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
fetchRequest.fetchLimit = 1
```

- 過濾該客戶的資料
- 按日期降序排列（最新的在前）
- 只取第一筆（最新一筆）

#### UI 布局實現

**HStack 結構**：
```
┌──────────────────────────────┐
│ HStack {                     │
│   Text("欄位名稱")            │ ← 固定 100pt 寬度
│     .frame(width: 100)       │
│   TextField("", text: $value)│ ← 填滿剩餘空間
│     .multilineTextAlignment  │ ← 數值靠右對齊
│         (.trailing)          │
│ }                            │
└──────────────────────────────┘
```

### 優點

1. **提升輸入效率**：
   - 減少重複輸入
   - 只需修改變化的欄位
   - 特別適合定期記錄的場景

2. **改善視覺識別**：
   - 欄位名稱永遠可見
   - 左右對齊，清晰明瞭
   - 數值靠右，便於比較

3. **保持數據一致性**：
   - 匯率等固定值自動延續
   - 減少輸入錯誤
   - 成本資訊自動延續

4. **不干擾編輯模式**：
   - 編輯模式仍然載入原始資料
   - 預填只在新增模式生效
   - 保持編輯邏輯不變

### 影響範圍

**修改檔案**：
- `AddLoanMonthlyDataView.swift`
  - 修改 `init` 函數（line 60-121）
  - 修改所有輸入欄位的 UI 布局（line 217-371）

**相關功能**：
- 新增月度數據
- 編輯月度數據（UI 布局改善）

**不影響**：
- 數據保存邏輯
- 累積值計算
- 資料查詢與顯示

### 測試建議

1. **測試新增預填**：
   - 先新增一筆完整資料
   - 再新增第二筆，確認投資資產欄位已預填
   - 確認貸款欄位沒有預填

2. **測試編輯模式**：
   - 編輯既有資料，確認顯示原始數據
   - 確認不受預填邏輯影響

3. **測試無歷史資料**：
   - 新客戶第一筆資料
   - 確認沒有預填（因為沒有前一筆資料）

4. **測試 UI 布局**：
   - 輸入不同長度的數值
   - 確認欄位名稱永遠可見
   - 確認數值靠右對齊

---

## 2025-11-13：統一綠色＋按鈕的預填行為

### 問題描述

在「貸款/投資月度管理」中有兩種新增方式：
1. **藍色「新增」按鈕**：打開表單，已實現預填功能 ✅
2. **綠色＋按鈕**：直接在表格中新增空白行，沒有預填功能 ❌

用戶反饋：透過綠色＋按鈕新增的行沒有前一筆資料的預填，導致體驗不一致。

### 根本原因

**LoanMonthlyDataTableView.swift:475-535（修正前）**

綠色＋按鈕調用 `addNewRow()` 函數，直接在 Core Data 中創建空白資料：

```swift
private func addNewRow() {
    let newData = LoanMonthlyData(context: viewContext)

    // 只設定空字串，沒有查詢前一筆資料
    newData.taiwanStock = ""
    newData.usStock = ""
    newData.bonds = ""
    // ...
}
```

**與藍色按鈕的差異**：
- 藍色按鈕：打開 AddLoanMonthlyDataView 表單 → 表單的 init 有預填邏輯 ✅
- 綠色按鈕：直接創建 Core Data 物件 → 沒有預填邏輯 ❌

### 解決方案

**LoanMonthlyDataTableView.swift:474-535（修正後）**

修改 `addNewRow()` 函數，加入查詢最新資料並預填的邏輯：

```swift
// MARK: - 新增空白行（預填前一筆資料）
private func addNewRow() {
    withAnimation {
        let newData = LoanMonthlyData(context: viewContext)

        // 設定今天的日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        newData.date = dateFormatter.string(from: Date())

        // 查詢最新一筆資料並預填
        let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "client == %@", client)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
        fetchRequest.fetchLimit = 1

        if let latestData = try? viewContext.fetch(fetchRequest).first {
            // 預填投資資產數據（不包含貸款資訊）
            newData.taiwanStock = latestData.taiwanStock ?? ""
            newData.usStock = latestData.usStock ?? ""
            newData.bonds = latestData.bonds ?? ""
            newData.regularInvestment = latestData.regularInvestment ?? ""
            newData.taiwanStockCost = latestData.taiwanStockCost ?? ""
            newData.usStockCost = latestData.usStockCost ?? ""
            newData.bondsCost = latestData.bondsCost ?? ""
            newData.regularInvestmentCost = latestData.regularInvestmentCost ?? ""
            newData.exchangeRate = latestData.exchangeRate ?? "32"
        } else {
            // 沒有前一筆資料，設定預設值
            newData.taiwanStock = ""
            newData.usStock = ""
            // ...
            newData.exchangeRate = "32"
        }

        // 貸款相關欄位設為空（需要用戶選擇貸款）
        newData.loanType = ""
        newData.loanAmount = ""
        newData.usedLoanAmount = ""
        newData.usedLoanAccumulated = ""

        // 計算結果欄位設為空
        newData.usStockBondsInTwd = ""
        newData.totalInvestment = ""

        newData.createdDate = Date()
        newData.client = client

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("已成功新增行並預填前一筆資料")
        }
    }
}
```

### 預填邏輯

**與 AddLoanMonthlyDataView 保持一致**：

1. **查詢最新一筆資料**：
   ```swift
   fetchRequest.predicate = NSPredicate(format: "client == %@", client)
   fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
   fetchRequest.fetchLimit = 1
   ```

2. **預填投資資產相關欄位**：
   - 台股、美股、債券、定期定額
   - 台股成本、美股成本、債券成本、定期定額成本
   - 匯率

3. **不預填貸款資訊**：
   - 貸款類型、貸款金額、已動用貸款、已動用累積
   - 這些欄位需要用戶手動輸入或選擇

4. **不預填計算結果**：
   - 美股加債券折合台幣、投資總額
   - 這些會在用戶輸入後自動計算

### 實際效果

#### 修正前

**綠色＋按鈕**：
```
日期      貸款類型  台股  美股  債券
2024-11-01  房貸   500k  10k   5k
2024-12-01              ← 全空，需要重新輸入
```

**藍色新增按鈕**：
```
日期      貸款類型  台股  美股  債券
2024-11-01  房貸   500k  10k   5k
2024-12-01        500k  10k   5k  ← 已預填
```

體驗不一致 ❌

#### 修正後

**綠色＋按鈕**：
```
日期      貸款類型  台股  美股  債券
2024-11-01  房貸   500k  10k   5k
2024-12-01        500k  10k   5k  ← 已預填 ✅
```

**藍色新增按鈕**：
```
日期      貸款類型  台股  美股  債券
2024-11-01  房貸   500k  10k   5k
2024-12-01        500k  10k   5k  ← 已預填 ✅
```

體驗一致 ✅

### 兩種新增方式的對比

| 特性 | 綠色＋按鈕 | 藍色「新增」按鈕 |
|------|-----------|----------------|
| **操作方式** | 直接在表格新增行 | 打開表單輸入 |
| **預填功能** | ✅ 支持（修正後） | ✅ 支持 |
| **適用場景** | 快速新增，直接編輯 | 完整輸入，逐項填寫 |
| **UI 體驗** | 表格內編輯 | 表單視圖 |
| **貸款選擇** | 表格內下拉選單 | 表單內 Picker |
| **欄位驗證** | 即時編輯 | 表單提交時 |

### 優點

1. **體驗一致性**：
   - 無論使用哪個按鈕，都能自動預填
   - 減少用戶困惑
   - 提升整體使用體驗

2. **提高效率**：
   - 綠色＋按鈕用於快速新增
   - 預填功能讓快速新增更快速
   - 適合大量數據輸入場景

3. **保持靈活性**：
   - 用戶可以選擇喜歡的新增方式
   - 兩種方式功能一致
   - 滿足不同使用習慣

### 影響範圍

**修改檔案**：
- `LoanMonthlyDataTableView.swift`
  - 修改 `addNewRow()` 函數（line 474-535）

**相關功能**：
- 綠色＋按鈕快速新增
- 表格內直接編輯

**不影響**：
- 藍色「新增」按鈕（表單方式）
- 編輯既有資料
- 數據保存邏輯

### 測試建議

1. **測試綠色＋按鈕預填**：
   - 先新增一筆完整資料
   - 點擊綠色＋按鈕
   - 確認新行已預填投資資產數據
   - 確認貸款欄位為空

2. **測試藍色按鈕預填**：
   - 點擊藍色「新增」按鈕
   - 確認表單已預填投資資產數據
   - 確認預填行為與綠色＋按鈕一致

3. **測試無歷史資料**：
   - 新客戶首次新增
   - 綠色＋按鈕應創建空白行（匯率預設 32）
   - 藍色按鈕應打開空白表單（匯率預設 32）

4. **測試後續編輯**：
   - 使用綠色＋按鈕新增後
   - 在表格中直接編輯
   - 確認保存功能正常

---

## 2025-11-13：投資總覽卡片新增報酬率顯示

### 問題描述

用戶反饋：「投資總覽卡片目前看不到報酬率」

**LoanInvestmentOverviewChart.swift** 只顯示貸款/投資總覽的線圖，沒有顯示投資報酬率等統計資訊，用戶無法快速了解投資表現。

### 解決方案

在投資總覽卡片上方添加統計卡片，顯示：
1. **投資總額**：最新一筆月度資料的投資總額
2. **投資成本**：最新一筆月度資料的投資成本總額
3. **報酬率**：根據投資總額和成本計算的百分比

#### 1. 新增報酬率計算邏輯

**LoanInvestmentOverviewChart.swift:63-89（新增）**

```swift
// 計算報酬率相關數據
private var returnStatistics: (totalInvestment: Double, totalCost: Double, returnRate: Double)? {
    guard let latestData = monthlyDataList.sorted(by: { ($0.date ?? "") > ($1.date ?? "") }).first else {
        return nil
    }

    // 投資總額
    let totalInvestment = Double(latestData.totalInvestment ?? "0") ?? 0

    // 投資成本總額 = 台股成本 + (美股成本 + 債券成本) × 匯率
    let taiwanStockCost = Double(latestData.taiwanStockCost ?? "0") ?? 0
    let usStockCost = Double(latestData.usStockCost ?? "0") ?? 0
    let bondsCost = Double(latestData.bondsCost ?? "0") ?? 0
    let exchangeRate = Double(latestData.exchangeRate ?? "32") ?? 32

    let totalCost = taiwanStockCost + (usStockCost + bondsCost) * exchangeRate

    // 報酬率 = (投資總額 - 投資成本) / 投資成本 × 100%
    let returnRate: Double
    if totalCost > 0 {
        returnRate = ((totalInvestment - totalCost) / totalCost) * 100
    } else {
        returnRate = 0
    }

    return (totalInvestment: totalInvestment, totalCost: totalCost, returnRate: returnRate)
}
```

**計算公式**：

1. **投資總額**：
   - 直接取最新月度資料的 `totalInvestment`
   - 公式：`台股 + 美股加債券折合台幣`

2. **投資成本總額**：
   ```swift
   台股成本 + (美股成本 + 債券成本) × 匯率
   ```

3. **報酬率**：
   ```swift
   ((投資總額 - 投資成本) / 投資成本) × 100%
   ```

#### 2. 新增統計卡片 UI

**LoanInvestmentOverviewChart.swift:189-244（新增）**

在圖表上方添加統計卡片：

```swift
// 報酬率統計卡片
if let stats = returnStatistics {
    HStack(spacing: 12) {
        // 投資總額
        VStack(alignment: .leading, spacing: 4) {
            Text("投資總額")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formatCurrency(stats.totalInvestment))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(darkGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Divider()

        // 投資成本
        VStack(alignment: .leading, spacing: 4) {
            Text("投資成本")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formatCurrency(stats.totalCost))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(darkGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Divider()

        // 報酬率
        VStack(alignment: .leading, spacing: 4) {
            Text("報酬率")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                Text(String(format: "%.2f%%", stats.returnRate))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(stats.returnRate >= 0 ? green : red)
                Image(systemName: stats.returnRate >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(stats.returnRate >= 0 ? green : red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(lightGray)
    )
    .padding(.horizontal, 16)
    .padding(.top, 12)
}
```

**UI 設計特點**：
- 三欄式佈局，平均分配空間
- 使用 Divider 分隔不同統計項目
- 報酬率根據正負顯示不同顏色：
  - 正數：綠色 + 向上箭頭 ↗
  - 負數：紅色 + 向下箭頭 ↘
- 淺灰色背景，圓角卡片設計

#### 3. 新增貨幣格式化函數

**LoanInvestmentOverviewChart.swift:100-107（新增）**

```swift
// 格式化貨幣顯示
private func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? "0"
}
```

格式化為千分位顯示，不顯示小數點。

### 實際效果

#### 修改前

```
┌──────────────────────────────┐
│ 貸款/投資總覽           [v] │
├──────────────────────────────┤
│                              │
│  [圖表圖例]                   │
│                              │
│  [線圖]                       │
│                              │
└──────────────────────────────┘
```

#### 修改後

```
┌──────────────────────────────┐
│ 貸款/投資總覽           [v] │
├──────────────────────────────┤
│ ┌────────────────────────┐  │
│ │ 投資總額 | 投資成本 | 報酬率│
│ │ 980,000 | 850,000 | +15.29%↗│
│ └────────────────────────┘  │
│                              │
│  [圖表圖例]                   │
│                              │
│  [線圖]                       │
│                              │
└──────────────────────────────┘
```

### 範例計算

**假設最新月度資料**：
- 台股：500,000
- 美股：10,000 USD
- 債券：5,000 USD
- 匯率：32
- 台股成本：450,000
- 美股成本：9,000 USD
- 債券成本：4,500 USD

**計算過程**：

1. **投資總額**：
   ```
   美股加債券折合台幣 = (10,000 + 5,000) × 32 = 480,000
   投資總額 = 500,000 + 480,000 = 980,000
   ```

2. **投資成本總額**：
   ```
   投資成本 = 450,000 + (9,000 + 4,500) × 32
            = 450,000 + 432,000
            = 882,000
   ```

3. **報酬率**：
   ```
   報酬率 = (980,000 - 882,000) / 882,000 × 100%
         = 98,000 / 882,000 × 100%
         = 11.11%
   ```

4. **顯示結果**：
   ```
   投資總額：980,000
   投資成本：882,000
   報酬率：+11.11% ↗ (綠色)
   ```

### 顏色設計

**報酬率顏色邏輯**：
- **正報酬率（≥ 0%）**：
  - 顏色：綠色 `Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0))`
  - 圖示：`arrow.up.right` ↗

- **負報酬率（< 0%）**：
  - 顏色：紅色 `.red`
  - 圖示：`arrow.down.right` ↘

### 優點

1. **一目了然**：
   - 用戶可快速了解投資表現
   - 報酬率以百分比顯示，直觀易懂
   - 顏色和箭頭提供視覺化反饋

2. **資訊完整**：
   - 顯示投資總額、成本、報酬率三項關鍵指標
   - 數據來自最新月度資料，保持即時性

3. **設計一致**：
   - 卡片風格與其他組件保持一致
   - 顏色使用符合整體設計規範
   - 字體大小和間距協調

4. **動態更新**：
   - 隨著月度資料更新自動重新計算
   - 無需手動刷新

### 影響範圍

**修改檔案**：
- `LoanInvestmentOverviewChart.swift`
  - 新增 `returnStatistics` 計算屬性（line 63-89）
  - 新增 `formatCurrency()` 函數（line 100-107）
  - 新增統計卡片 UI（line 189-244）

**相關功能**：
- 投資總覽圖表顯示
- 報酬率即時計算

**不影響**：
- 月度管理數據輸入
- 圖表數據計算
- 其他卡片顯示

### 測試建議

1. **測試報酬率計算**：
   - 新增一筆月度資料
   - 確認投資總額、成本、報酬率計算正確

2. **測試正負報酬率顯示**：
   - 創建正報酬率數據（投資總額 > 成本）
   - 創建負報酬率數據（投資總額 < 成本）
   - 確認顏色和箭頭正確顯示

3. **測試無數據狀態**：
   - 新客戶沒有月度資料
   - 確認統計卡片不顯示

4. **測試數據更新**：
   - 編輯最新月度資料
   - 確認統計卡片自動更新

5. **測試極端值**：
   - 成本為 0 的情況
   - 非常大的投資金額
   - 確認格式化正確

---

## 2025-11-13：修正投資總覽卡片報酬率計算錯誤

### 問題描述

用戶反饋：「投資總覽卡片目前看不到報酬率」

經檢查發現，投資總覽卡片（在貸款總覽卡片下方）的報酬率計算有兩個錯誤：

1. **沒有考慮匯率轉換**：直接把美元成本（美股成本、債券成本）加到台幣成本上
2. **包含了定期定額成本**：但投資總額計算公式中不包含定期定額

### 根本原因

**LoanManagementView.swift:86-118（修正前）**

```swift
// 計算總成本
let taiwanStockCost = Double(latestData.taiwanStockCost ?? "0") ?? 0
let usStockCost = Double(latestData.usStockCost ?? "0") ?? 0
let bondsCost = Double(latestData.bondsCost ?? "0") ?? 0
let regularInvestmentCost = Double(latestData.regularInvestmentCost ?? "0") ?? 0
let totalCost = taiwanStockCost + usStockCost + bondsCost + regularInvestmentCost  // ❌ 錯誤
```

**問題分析**：

1. **幣別不一致**：
   ```
   台股成本：500,000 TWD
   美股成本：10,000 USD  ← 直接相加
   債券成本：5,000 USD   ← 直接相加
   ```
   這樣會得到 515,000，但實際上應該是：
   ```
   500,000 + (10,000 + 5,000) × 32 = 980,000
   ```

2. **公式不一致**：
   - 投資總額 = 台股 + 美股加債券折合台幣
   - 投資成本 = 台股成本 + 美股成本 + 債券成本 + 定期定額成本 ❌

   兩者不對應，導致報酬率計算錯誤。

### 解決方案

**LoanManagementView.swift:86-119（修正後）**

```swift
// 計算投資成本總額 = 台股成本 + (美股成本 + 債券成本) × 匯率
let taiwanStockCost = Double(latestData.taiwanStockCost ?? "0") ?? 0
let usStockCost = Double(latestData.usStockCost ?? "0") ?? 0
let bondsCost = Double(latestData.bondsCost ?? "0") ?? 0
let exchangeRate = Double(latestData.exchangeRate ?? "32") ?? 32

let totalCost = taiwanStockCost + (usStockCost + bondsCost) * exchangeRate  // ✅ 正確
```

**修正重點**：

1. **新增匯率參數**：
   ```swift
   let exchangeRate = Double(latestData.exchangeRate ?? "32") ?? 32
   ```

2. **修正成本計算公式**：
   ```swift
   totalCost = taiwanStockCost + (usStockCost + bondsCost) * exchangeRate
   ```

3. **移除定期定額成本**：
   - 不再包含 `regularInvestmentCost`
   - 與投資總額的計算邏輯保持一致

### 計算範例

**假設最新月度資料**：
- 台股：500,000 TWD
- 美股：10,000 USD
- 債券：5,000 USD
- 匯率：32
- 台股成本：450,000 TWD
- 美股成本：9,000 USD
- 債券成本：4,500 USD

**修正前（錯誤）**：
```
投資成本 = 450,000 + 9,000 + 4,500 = 463,500  ❌
投資總額 = 980,000
報酬率 = (980,000 - 463,500) / 463,500 × 100% = 111.47%  ❌ 明顯錯誤
```

**修正後（正確）**：
```
投資成本 = 450,000 + (9,000 + 4,500) × 32
         = 450,000 + 432,000
         = 882,000  ✅

投資總額 = 500,000 + (10,000 + 5,000) × 32
         = 500,000 + 480,000
         = 980,000  ✅

報酬率 = (980,000 - 882,000) / 882,000 × 100%
       = 98,000 / 882,000 × 100%
       = 11.11%  ✅ 合理
```

### 數據來源

所有數據都來自**投資月度管理**的最新一筆資料：

```
投資月度管理（LoanMonthlyData）
    ↓ 查詢最新一筆
┌─────────────────────────────┐
│ 投資總額：totalInvestment    │
│ 台股成本：taiwanStockCost    │
│ 美股成本：usStockCost        │
│ 債券成本：bondsCost          │
│ 匯率：exchangeRate           │
└─────────────────────────────┘
    ↓ 計算
┌─────────────────────────────┐
│ 投資成本 = 台股成本 +        │
│           (美股成本 + 債券成本)│
│           × 匯率             │
│                             │
│ 報酬率 = (投資總額 - 投資成本)│
│         / 投資成本 × 100%    │
└─────────────────────────────┘
    ↓ 顯示
投資總覽卡片
```

### 公式一致性

修正後，投資總額和投資成本的計算邏輯完全一致：

| 項目 | 公式 |
|------|------|
| **投資總額** | 台股 + (美股 + 債券) × 匯率 |
| **投資成本** | 台股成本 + (美股成本 + 債券成本) × 匯率 |
| **報酬率** | (投資總額 - 投資成本) / 投資成本 × 100% |

### 實際效果

#### 修正前

```
投資總覽
┌────────────────────┐
│ 投資總額  報酬率    │
│ 980,000  111.47%  │ ← 錯誤，太高了
└────────────────────┘
```

#### 修正後

```
投資總覽
┌────────────────────┐
│ 投資總額  報酬率    │
│ 980,000   11.11%  │ ← 正確，合理
└────────────────────┘
```

### 影響範圍

**修改檔案**：
- `LoanManagementView.swift`
  - 修改 `investmentReturnRate` 計算屬性（line 86-119）

**相關功能**：
- 投資總覽卡片的報酬率顯示
- 報酬率顏色判斷（正數綠色、負數紅色）

**不影響**：
- 投資月度管理的數據輸入
- 貸款總覽卡片
- 貸款/投資總覽線圖

### 測試建議

1. **測試正常報酬率**：
   - 新增一筆月度資料（投資總額 > 成本）
   - 確認報酬率為正數，顯示綠色

2. **測試負報酬率**：
   - 編輯月度資料（投資總額 < 成本）
   - 確認報酬率為負數，顯示紅色

3. **測試匯率影響**：
   - 修改匯率（例如從 32 改為 30）
   - 確認報酬率重新計算

4. **測試極端值**：
   - 成本為 0：報酬率應顯示 0%
   - 非常大的投資金額：確認計算正確

5. **驗證與投資總額一致性**：
   - 手動計算投資成本
   - 與投資總額對比，確認報酬率合理

### 注意事項

修正後，如果用戶之前有看到異常高或異常低的報酬率，現在會顯示正確的數值。建議用戶重新檢查一下投資總覽卡片的報酬率是否符合預期。

---

## 2025-11-14：移除圖表區統計卡片，保持介面簡潔

### 問題描述

用戶反饋：「我只需要投資總覽卡片就好了，圖表區只需要線圖」

**LoanInvestmentOverviewChart.swift** 的圖表區域中有統計卡片顯示投資總額、成本和報酬率，但這些資訊與上方的投資總覽卡片重複，造成畫面冗余。

### 解決方案

移除 `LoanInvestmentOverviewChart` 線圖區域中的統計卡片，保持介面簡潔專注。

#### 移除內容

**LoanInvestmentOverviewChart.swift**

1. **移除報酬率統計計算邏輯**（line 63-89）
   ```swift
   // 移除 returnStatistics 計算屬性
   // 移除投資總額、成本、報酬率的計算
   ```

2. **移除貨幣格式化函數**（line 100-107）
   ```swift
   // 移除 formatCurrency() 函數
   ```

3. **移除統計卡片 UI**（line 189-244）
   ```swift
   // 移除整個統計卡片視圖區塊
   // 包含三個統計項目：投資總額、投資成本、報酬率
   ```

#### 保留內容

**LoanInvestmentOverviewChart.swift** 保留以下核心功能：

1. ✅ **工具列**
   - 標題「貸款/投資總覽」
   - 收合/展開按鈕
   - 圖表類型切換選單

2. ✅ **圖例**
   - 顯示兩條線的顏色和名稱
   - 根據圖表類型動態變化

3. ✅ **漸層線圖**（GradientLineChartView）
   - 雙線顯示
   - 漸層填充效果
   - X 軸日期標籤

4. ✅ **空狀態提示**
   - 無數據時顯示提示文字

### 最終架構

**貸款管理頁面佈局**：

```
┌─────────────────────────────┐
│    貸款總覽卡片              │
│  - 貸款總額                  │
│  - 每月還款                  │
└─────────────────────────────┘
         ↓
┌─────────────────────────────┐
│    投資總覽卡片 ✨           │
│  - 投資總額                  │
│  - 報酬率（已修正計算）      │
└─────────────────────────────┘
         ↓
┌─────────────────────────────┐
│ 貸款/投資總覽線圖            │
│  [工具列]                    │
│  - 標題                      │
│  - 收合/展開按鈕             │
│  - 圖表類型選單              │
│                              │
│  [圖例]                      │
│  ● 已動用累積 / 貸款總額     │
│  ● 投資總額                  │
│                              │
│  [漸層線圖] 📈               │
│  (純視覺化，無統計資訊)      │
└─────────────────────────────┘
         ↓
┌─────────────────────────────┐
│    貸款列表                  │
│  - 貸款項目詳情              │
└─────────────────────────────┘
         ↓
┌─────────────────────────────┐
│    月度管理表格              │
│  - 詳細月度數據              │
└─────────────────────────────┘
```

### 設計理念

1. **資訊不重複**
   - 統計數據集中在投資總覽卡片
   - 圖表區專注於趨勢視覺化

2. **介面簡潔**
   - 減少視覺負擔
   - 提升閱讀體驗

3. **功能分離**
   - 卡片：快速查看當前數值
   - 圖表：分析歷史趨勢

### 影響範圍

**修改檔案**：
- `LoanInvestmentOverviewChart.swift`
  - 移除 `returnStatistics` 計算屬性
  - 移除 `formatCurrency()` 函數
  - 移除統計卡片 UI 區塊

**不影響**：
- ✅ 投資總覽卡片（LoanManagementView）- 繼續顯示完整統計資訊
- ✅ 線圖功能 - 所有圖表功能正常運作
- ✅ 圖表類型切換 - 繼續支援兩種模式
- ✅ 數據計算 - 報酬率計算邏輯在投資總覽卡片中正確運作

### 測試項目

1. **檢查投資總覽卡片**：
   - 確認顯示投資總額
   - 確認顯示報酬率（正確的計算公式）

2. **檢查線圖區域**：
   - 確認沒有統計卡片
   - 確認圖例正常顯示
   - 確認線圖正常繪製

3. **檢查圖表類型切換**：
   - 切換到「已動用累積/投資總額」
   - 切換到「貸款總額/投資總額」
   - 確認圖例文字相應變化

4. **檢查收合/展開功能**：
   - 點擊收合按鈕
   - 確認線圖隱藏
   - 再次點擊確認展開

### 相關更新記錄

本次修改是以下功能演進的一部分：

1. **2025-11-13**：新增投資總覽線圖和統計卡片
2. **2025-11-13**：修正投資總覽卡片報酬率計算
3. **2025-11-14**：移除線圖區統計卡片，避免資訊重複 ✨

---

## 2025-11-14：貸款總覽卡片新增顯示模式切換功能

### 需求描述

用戶反饋：「現在貸款總覽卡片顯示的是貸款總額，然後有預留一個可以點進去的功能，我希望點進去後可以讓我選擇要顯示貸款總額或者已動用累積或者貸款餘額三個讓我選擇可以嗎」

原本貸款總覽卡片只顯示固定的「貸款總額」，用戶希望能夠在三種顯示模式間切換：
1. **貸款總額** - 所有貸款的原始金額總和
2. **已動用累積** - 已動用的貸款累積總額
3. **貸款餘額** - 貸款總額 - 已動用累積

### 解決方案

在貸款總覽卡片新增顯示模式切換功能，讓用戶可以根據需求查看不同的貸款統計資訊。

#### 1. 新增顯示模式枚舉

**LoanManagementView.swift:33-41（新增）**

```swift
// 貸款顯示模式
enum LoanDisplayMode: String, CaseIterable {
    case totalLoan = "貸款總額"
    case usedAccumulated = "已動用累積"
    case remainingLoan = "貸款餘額"

    var userDefaultsKey: String {
        return "LoanManagementView.loanDisplayMode"
    }
}
```

#### 2. 新增狀態變數和初始化邏輯

**LoanManagementView.swift:29-30, 43-50（新增）**

```swift
@State private var showingLoanDisplayModeOptions = false
@State private var loanDisplayMode: LoanDisplayMode

init(client: Client?, onBack: @escaping () -> Void) {
    self.client = client
    self.onBack = onBack

    // 從 UserDefaults 讀取保存的顯示模式
    let savedMode = UserDefaults.standard.string(forKey: LoanDisplayMode.totalLoan.userDefaultsKey) ?? LoanDisplayMode.totalLoan.rawValue
    _loanDisplayMode = State(initialValue: LoanDisplayMode(rawValue: savedMode) ?? .totalLoan)
}
```

#### 3. 新增三種計算邏輯

**LoanManagementView.swift:80-118（新增）**

```swift
// 計算已動用累積總額（從月度資料中取得最新的已動用累積）
private var totalUsedAccumulated: Double {
    guard let client = client else { return 0 }

    let fetchRequest: NSFetchRequest<LoanMonthlyData> = LoanMonthlyData.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "client == %@", client)
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LoanMonthlyData.date, ascending: false)]
    fetchRequest.fetchLimit = 1

    do {
        let results = try viewContext.fetch(fetchRequest)
        if let latestData = results.first,
           let usedAccumulated = latestData.usedLoanAccumulated,
           let value = Double(usedAccumulated) {
            return value
        }
    } catch {
        print("獲取已動用累積錯誤: \(error)")
    }

    return 0
}

// 計算貸款餘額（貸款總額 - 已動用累積）
private var remainingLoanAmount: Double {
    return totalLoanAmount - totalUsedAccumulated
}

// 根據顯示模式取得對應的金額
private var displayedLoanAmount: Double {
    switch loanDisplayMode {
    case .totalLoan:
        return totalLoanAmount
    case .usedAccumulated:
        return totalUsedAccumulated
    case .remainingLoan:
        return remainingLoanAmount
    }
}
```

#### 4. 修改卡片顯示邏輯

**LoanManagementView.swift:317-394（修改）**

將原本固定顯示「貸款總額」的卡片改為：
- 新增切換按鈕（藍色箭頭圖示）
- 保留編輯按鈕（灰色鉛筆圖示）
- 標籤文字動態顯示當前模式名稱
- 數值動態顯示對應的金額

```swift
HStack {
    // 顯示模式選擇按鈕
    Button(action: {
        showingLoanDisplayModeOptions = true
    }) {
        Image(systemName: "arrow.up.arrow.down.circle")
            .font(.system(size: 20))
            .foregroundColor(.blue)
    }

    // 編輯圖示
    Button(action: {
        showingEditLoanAmounts = true
    }) {
        Image(systemName: "pencil.circle")
            .font(.system(size: 20))
            .foregroundColor(.gray)
    }
}

// 內容區域
VStack(alignment: .leading, spacing: 8) {
    Text(loanDisplayMode.rawValue)  // 動態標籤
        .font(.caption)
        .foregroundColor(.secondary)
    Text("$\(formatDouble(displayedLoanAmount))")  // 動態金額
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.primary)
}
```

#### 5. 新增選項選擇視圖

**LoanManagementView.swift:955-1014（新增）**

創建 `LoanDisplayModeSelectionView` 視圖：

```swift
struct LoanDisplayModeSelectionView: View {
    @Binding var selectedMode: LoanManagementView.LoanDisplayMode
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(LoanManagementView.LoanDisplayMode.allCases, id: \.self) { mode in
                    Button(action: {
                        selectedMode = mode
                        onDismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.rawValue)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary)

                                Text(getModeDescription(for: mode))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("選擇顯示模式")
        }
        .presentationDetents([.height(300)])
    }
}
```

#### 6. 添加 Sheet 顯示邏輯

**LoanManagementView.swift:272-281（新增）**

```swift
.sheet(isPresented: $showingLoanDisplayModeOptions) {
    LoanDisplayModeSelectionView(
        selectedMode: $loanDisplayMode,
        onDismiss: {
            showingLoanDisplayModeOptions = false
            // 保存用戶選擇
            UserDefaults.standard.set(loanDisplayMode.rawValue, forKey: LoanDisplayMode.totalLoan.userDefaultsKey)
        }
    )
}
```

### 功能特點

1. **三種顯示模式**
   - ✅ 貸款總額：顯示所有貸款的原始金額總和
   - ✅ 已動用累積：顯示已動用的貸款累積總額（來自月度資料）
   - ✅ 貸款餘額：顯示貸款總額減去已動用累積

2. **持久化存儲**
   - 使用 UserDefaults 保存用戶選擇
   - App 重啟後仍保持上次選擇的模式

3. **直覺的 UI 設計**
   - 藍色箭頭圖示表示切換功能
   - 選項視圖使用半屏展示（.height(300)）
   - 每個選項附帶說明文字
   - 當前選中模式顯示藍色勾選圖示

4. **即時更新**
   - 切換模式後立即更新卡片顯示
   - 標籤文字和數值同步變化

### 使用流程

```
1. 用戶打開貸款管理頁面
   ↓
2. 查看貸款總覽卡片（顯示上次選擇的模式）
   ↓
3. 點擊藍色箭頭圖示
   ↓
4. 彈出選項視圖，顯示三種模式
   ↓
5. 用戶選擇想要的模式
   ↓
6. 卡片立即更新為選中的模式
   ↓
7. 選擇被保存，下次打開仍是該模式
```

### 計算公式

1. **貸款總額**
   ```
   totalLoanAmount = Σ(所有貸款的 loanAmount)
   ```

2. **已動用累積**
   ```
   totalUsedAccumulated = 最新一筆月度資料的 usedLoanAccumulated
   ```

3. **貸款餘額**
   ```
   remainingLoanAmount = totalLoanAmount - totalUsedAccumulated
   ```

### 影響範圍

**修改檔案**：
- `LoanManagementView.swift`
  - 新增 `LoanDisplayMode` 枚舉（line 33-41）
  - 新增狀態變數和初始化邏輯（line 29-30, 43-50）
  - 新增三種計算邏輯（line 80-118）
  - 修改卡片顯示邏輯（line 317-394）
  - 新增選項選擇視圖（line 955-1014）
  - 添加 sheet 顯示邏輯（line 272-281）

**不影響**：
- ✅ 投資總覽卡片
- ✅ 線圖功能
- ✅ 貸款列表
- ✅ 月度管理表格
- ✅ 編輯貸款金額功能（灰色鉛筆圖示仍正常運作）

### 測試項目

1. **顯示模式切換**
   - 點擊藍色箭頭圖示
   - 確認彈出選項視圖
   - 選擇「貸款總額」，確認卡片顯示正確金額
   - 選擇「已動用累積」，確認卡片顯示月度資料的累積值
   - 選擇「貸款餘額」，確認顯示正確的差額

2. **持久化存儲**
   - 選擇任一模式
   - 返回客戶列表
   - 再次進入貸款管理
   - 確認仍顯示上次選擇的模式

3. **計算正確性**
   - 記錄貸款總額、已動用累積、貸款餘額
   - 驗證：貸款餘額 = 貸款總額 - 已動用累積

4. **編輯功能不受影響**
   - 點擊灰色鉛筆圖示
   - 確認編輯貸款金額視圖正常打開

5. **無月度資料情況**
   - 新增客戶但未建立月度資料
   - 確認「已動用累積」顯示為 0
   - 確認「貸款餘額」等於「貸款總額」

### 設計考量

1. **數據來源**
   - 貸款總額：來自 `Loan` 實體的 `loanAmount` 總和
   - 已動用累積：來自最新一筆 `LoanMonthlyData` 的 `usedLoanAccumulated`
   - 確保數據一致性

2. **UI 設計**
   - 使用藍色箭頭圖示區分切換功能（與編輯功能分開）
   - 選項視圖高度固定為 300pt，避免佔據整個螢幕
   - 說明文字幫助用戶理解每個模式的意義

3. **用戶體驗**
   - 選擇後立即關閉視圖並更新
   - 保存用戶偏好，減少重複操作
   - 當前模式顯示勾選標記，清晰明瞭

---

## 授權

本專案程式碼可自由使用於其他專案中。
## 第六節：台股/美股小卡設計風格統一

### 問題背景

在 2025/11/18，用戶發現台股小卡和美股小卡的設計風格不一致：

**美股小卡特點**：
- ✅ 顯示幣別標籤（USD）
- ✅ 顯示股數資訊（"股數: 25"）
- ✅ 顯示成本資訊（"成本: $3,144.75"）
- ✅ 使用圓角卡片設計 + 陰影效果
- ✅ 卡片間距為 12pt

**台股小卡問題**：
- ❌ 無幣別標籤
- ❌ 不顯示股數和成本資訊
- ❌ 使用分隔線設計（Divider）
- ❌ 較為簡陋的視覺效果

### 解決方案

統一台股小卡設計，使其與美股小卡保持一致的視覺風格。

### 實作細節

#### 1. 更新 StockRowView 卡片主體設計

**檔案位置**：`TWStockInventoryView.swift` (lines 729-783)

**修改前**：
```swift
HStack(spacing: 12) {
    // 股票名稱和代碼
    VStack(alignment: .leading, spacing: 2) {
        Text(stock.stockName?.isEmpty == false ? stock.stockName! : (stock.name ?? "未知"))
            .font(.system(size: 16, weight: .semibold))
        Text(stock.name ?? "")
            .font(.system(size: 12))
    }

    VStack(alignment: .leading, spacing: 2) {
        Text(formatCurrency(...))
        Text(formatReturnRate(...))
    }

    Spacer()
    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
}
```

**修改後**：
```swift
HStack(spacing: 12) {
    VStack(alignment: .leading, spacing: 4) {
        HStack {
            Text(stock.stockName?.isEmpty == false ? stock.stockName! : (stock.name ?? "未知"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            // 新增：幣別標籤
            if let currency = stock.currency, !currency.isEmpty {
                Text(currency)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }

        // 新增：股數和成本資訊
        HStack(spacing: 8) {
            Text("股數: \(formatNumber(stock.shares))")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("成本: NT$\(formatNumber(stock.cost))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    Spacer()

    VStack(alignment: .trailing, spacing: 4) {
        Text("NT$\(formatNumber(stock.marketValue))")
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(.primary)

        let returnRate = Double(stock.returnRate ?? "0") ?? 0
        Text(formatReturnRate(returnRate))
            .font(.caption)
            .foregroundColor(returnRate >= 0 ? .green : .red)
    }

    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
        .font(.caption)
        .foregroundColor(.secondary)
}
.padding()
.background(Color(.systemBackground))
```

**改進項目**：
- ✅ 新增 TWD 幣別標籤，與美股 USD 標籤一致
- ✅ 顯示股數和成本資訊
- ✅ 字體大小從 16pt 增加到 17pt，與美股一致
- ✅ 添加 .padding() 和背景色

#### 2. 新增格式化輔助函數

**檔案位置**：`TWStockInventoryView.swift` (lines 943-952)

```swift
private func formatNumber(_ value: String?) -> String {
    guard let value = value, !value.isEmpty else { return "0" }
    if let number = Double(value) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? value
    }
    return value
}
```

**用途**：
- 格式化股數顯示（如：25 → "25"）
- 格式化成本顯示（如：3144.75 → "3,144.75"）
- 保持數字顯示一致性

#### 3. 更新卡片外觀樣式

**檔案位置**：`TWStockInventoryView.swift` (lines 878-880)

**修改前**：
```swift
}
.padding(.vertical, 8)
```

**修改後**：
```swift
}
.background(Color(.systemBackground))
.cornerRadius(12)
.shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
```

**視覺效果**：
- ✅ 12pt 圓角設計
- ✅ 輕微陰影效果（透明度 5%，模糊半徑 4pt）
- ✅ 與美股小卡完全一致的卡片樣式

#### 4. 更新持倉列表佈局

**檔案位置**：`TWStockInventoryView.swift` (lines 294-304)

**修改前**：
```swift
private var stockListView: some View {
    ScrollView {
        LazyVStack(spacing: 0) {
            ForEach(twStocks) { stock in
                StockRowView(stock: stock, viewContext: viewContext)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                if stock != twStocks.last {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
```

**修改後**：
```swift
private var stockListView: some View {
    ScrollView {
        LazyVStack(spacing: 12) {
            ForEach(twStocks) { stock in
                StockRowView(stock: stock, viewContext: viewContext)
            }
        }
        .padding()
    }
}
```

**改進項目**：
- ✅ 移除 Divider 分隔線
- ✅ 卡片間距改為 12pt
- ✅ 簡化佈局結構
- ✅ 與美股小卡列表佈局完全一致

### 設計對比

| 功能項目 | 修改前 | 修改後 |
|---------|-------|-------|
| 幣別標籤 | ❌ 無 | ✅ TWD 標籤 |
| 股數顯示 | ❌ 無 | ✅ "股數: 25" |
| 成本顯示 | ❌ 無 | ✅ "成本: NT$3,144.75" |
| 卡片圓角 | ❌ 無 | ✅ 12pt 圓角 |
| 卡片陰影 | ❌ 無 | ✅ 輕微陰影 |
| 分隔線 | ❌ 使用 Divider | ✅ 卡片間距 |
| 字體大小 | 16pt | 17pt |
| 卡片間距 | 0pt | 12pt |

### 使用場景

#### 場景 1：查看台股持倉詳情
```
用戶操作流程：
1. 打開客戶詳情頁面
   ↓
2. 點擊「台股持倉」小卡
   ↓
3. 查看台股列表
   ↓
4. 看到清晰的卡片設計：
   - 股票名稱顯示在上方
   - TWD 幣別標籤在名稱旁
   - 股數和成本資訊在下方
   - 市值和報酬率在右側
```

#### 場景 2：比較台股和美股設計
```
用戶操作流程：
1. 查看美股小卡列表
   ↓
2. 切換到台股小卡列表
   ↓
3. 發現兩者設計風格完全一致
   ↓
4. 視覺體驗統一、專業
```

### 影響範圍

**修改檔案**：
- `TWStockInventoryView.swift`
  - 更新 `StockRowView` 主體設計（lines 729-783）
  - 新增 `formatNumber` 函數（lines 943-952）
  - 更新卡片樣式（lines 878-880）
  - 更新列表佈局（lines 294-304）

**不影響**：
- ✅ 美股小卡功能和設計
- ✅ 展開詳情編輯功能
- ✅ 股價更新功能
- ✅ 同步到月度資產功能
- ✅ 同步到貸款功能

### 視覺一致性

現在台股小卡和美股小卡擁有完全一致的設計語言：

**統一的設計元素**：
1. ✅ 幣別標籤（TWD / USD）
2. ✅ 股數和成本資訊行
3. ✅ 17pt 粗體字顯示市值
4. ✅ 報酬率顏色標識（綠色/紅色）
5. ✅ 12pt 圓角卡片
6. ✅ 輕微陰影效果
7. ✅ 12pt 卡片間距
8. ✅ 統一的 padding 設計

**用戶體驗提升**：
- 視覺風格一致，更加專業
- 資訊層次清晰，易於閱讀
- 卡片設計現代化，符合 iOS 設計規範


## 第七節：公司債明細表格優化 - 排序功能與配息月份選擇器改進

### 問題背景

在 2025/11/18，用戶反饋公司債明細表格存在以下問題：

1. **配息月份選擇器設計突兀**
   - 原本使用 `MenuPickerStyle()` 的 Picker 組件
   - 視覺風格與表格其他欄位不一致
   - 缺乏明確的視覺提示

2. **缺少排序功能**
   - 用戶希望能快速查看：
     - 殖利率最高的債券
     - 申購金額最大的債券
     - 交易金額最大的債券
     - 現值最大的債券
   - 缺乏點擊表頭排序的功能

### 解決方案

#### 1. 改善配息月份選擇器設計

**檔案位置**：`CorporateBondsDetailView.swift` (lines 270-297)

**修改前**：
```swift
Picker("", selection: bindingForBond(bond, header: header)) {
    Text("1月、7月").tag("1月、7月")
    Text("2月、8月").tag("2月、8月")
    // ...
}
.pickerStyle(MenuPickerStyle())
.background(Color.clear)
```

**修改後**：
```swift
Menu {
    Button("1月、7月") { setBondValue(bond, header: header, value: "1月、7月") }
    Button("2月、8月") { setBondValue(bond, header: header, value: "2月、8月") }
    Button("3月、9月") { setBondValue(bond, header: header, value: "3月、9月") }
    Button("4月、10月") { setBondValue(bond, header: header, value: "4月、10月") }
    Button("5月、11月") { setBondValue(bond, header: header, value: "5月、11月") }
    Button("6月、12月") { setBondValue(bond, header: header, value: "6月、12月") }
} label: {
    HStack(spacing: 4) {
        Text(bond.dividendMonths?.isEmpty == false ? bond.dividendMonths! : "選擇配息月份")
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(bond.dividendMonths?.isEmpty == false ? .primary : .secondary)

        Spacer()

        Image(systemName: "chevron.down")
            .font(.system(size: 10))
            .foregroundColor(.secondary)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 12)
    .frame(minWidth: getBondColumnWidth(for: header), alignment: .leading)
    .background(Color(.systemGray6).opacity(0.3))
    .cornerRadius(4)
}
.buttonStyle(PlainButtonStyle())
```

**設計改進**：
- ✅ 使用 Menu 替代 Picker，提供更好的控制
- ✅ 添加淡灰色背景 `Color(.systemGray6).opacity(0.3)`
- ✅ 添加 4pt 圓角，與其他 UI 元素一致
- ✅ 顯示清晰的下箭頭圖示 `chevron.down`
- ✅ 未選擇時顯示提示文字「選擇配息月份」（灰色）
- ✅ 已選擇時顯示實際值（黑色）

#### 2. 添加表頭排序功能

**檔案位置**：`CorporateBondsDetailView.swift` (lines 16-17, 219-250)

**新增狀態變數**：
```swift
@State private var sortField: String? = nil
@State private var sortAscending: Bool = true
```

**更新表頭設計**：
```swift
ForEach(currentColumnOrder, id: \.self) { header in
    if isSortableField(header) {
        // 可排序欄位
        Button(action: {
            handleSort(for: header)
        }) {
            HStack(spacing: 4) {
                Text(header)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                if sortField == header {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 14)
            .frame(minWidth: getBondColumnWidth(for: header), alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    } else {
        // 不可排序欄位（保持原樣）
        Text(header)
            .font(.system(size: 15, weight: .semibold))
            // ...
    }
}
```

**排序邏輯實現**：

**1. 可排序欄位判斷** (lines 348-351)
```swift
private func isSortableField(_ header: String) -> Bool {
    return ["殖利率", "申購金額", "交易金額", "現值"].contains(header)
}
```

**2. 排序處理** (lines 353-363)
```swift
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
```

**3. 排序後的債券列表** (lines 330-346)
```swift
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
```

**4. 獲取數字值** (lines 365-387)
```swift
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
```

**5. 配息月份設置函數** (lines 389-400)
```swift
private func setBondValue(_ bond: CorporateBond, header: String, value: String) {
    bond.dividendMonths = value

    // 自動儲存變更
    do {
        try viewContext.save()
        PersistenceController.shared.save()
    } catch {
        print("❌ 儲存失敗: \(error)")
    }
}
```

### 使用場景

#### 場景 1：選擇配息月份
```
用戶操作流程：
1. 打開公司債明細表格
   ↓
2. 點擊「配息月份」欄位
   ↓
3. 看到淡灰色背景的按鈕，顯示「選擇配息月份」或當前值
   ↓
4. 點擊按鈕
   ↓
5. 彈出選單，顯示 6 個選項
   ↓
6. 選擇配息月份（如：「3月、9月」）
   ↓
7. 欄位立即更新，自動保存
```

#### 場景 2：按現值排序（查看庫存市值最大的債券）
```
用戶操作流程：
1. 打開公司債明細表格
   ↓
2. 點擊「現值」表頭
   ↓
3. 表頭顯示藍色向上箭頭 ↑（升序）
   ↓
4. 表格按現值從小到大排序
   ↓
5. 再次點擊「現值」表頭
   ↓
6. 箭頭變為向下箭頭 ↓（降序）
   ↓
7. 表格按現值從大到小排序
   ↓
8. 現值最大的債券顯示在最上方
```

#### 場景 3：按殖利率排序（查看報酬率最高的債券）
```
用戶操作流程：
1. 點擊「殖利率」表頭
   ↓
2. 表格按殖利率升序排列
   ↓
3. 再次點擊
   ↓
4. 表格按殖利率降序排列
   ↓
5. 殖利率最高的債券顯示在最上方
```

### 視覺設計對比

#### 配息月份選擇器

| 設計元素 | 修改前 | 修改後 |
|---------|-------|-------|
| 組件類型 | Picker (MenuPickerStyle) | Menu |
| 背景色 | 透明 | 淡灰色 (systemGray6, 30% 透明度) |
| 圓角 | 無 | 4pt |
| 下拉指示器 | 系統預設 | 自定義 chevron.down |
| 未選擇提示 | 無 | "選擇配息月份" (灰色) |
| 已選擇顯示 | 黑色文字 | 黑色文字 + 背景 |

#### 表頭排序

| 功能 | 修改前 | 修改後 |
|-----|-------|-------|
| 可排序欄位 | 無 | 殖利率、申購金額、交易金額、現值 |
| 點擊效果 | 無反應 | 觸發排序 |
| 視覺提示 | 無 | 藍色箭頭圖示 |
| 升序指示 | - | ↑ chevron.up |
| 降序指示 | - | ↓ chevron.down |
| 首次點擊 | - | 升序排列 |
| 再次點擊 | - | 切換為降序 |

### 排序行為

| 欄位 | 排序依據 | 數據處理 |
|-----|---------|----------|
| 殖利率 | 百分比數值 | 移除 % 符號和逗號 |
| 申購金額 | 金額數值 | 移除逗號 |
| 交易金額 | 金額數值 | 移除逗號 |
| 現值 | 金額數值 | 移除逗號 |

### 影響範圍

**修改檔案**：
- `CorporateBondsDetailView.swift`
  - 新增排序狀態變數（lines 16-17）
  - 更新表頭設計（lines 219-250）
  - 改善配息月份選擇器（lines 270-297）
  - 新增排序相關函數（lines 330-400）

**不影響**：
- ✅ 公司債資料的增刪改功能
- ✅ CSV 匯入功能
- ✅ 自動計算欄位（申購金額、交易金額、單次配息、年度配息、殖利率）
- ✅ 欄位重新排序功能
- ✅ 千分位格式化顯示

### 技術實現細節

#### 1. 排序狀態管理
使用兩個 `@State` 變數追蹤排序狀態：
- `sortField`: 當前排序的欄位名稱
- `sortAscending`: 是否為升序排列

#### 2. 計算屬性 `sortedBonds`
- 如果沒有選擇排序欄位，返回原始順序
- 如果有排序欄位，使用 `sorted` 方法排序
- 排序時會調用 `getNumericValue` 獲取數值

#### 3. 數值處理
排序前會清理數據：
- 移除千分位逗號（`,`）
- 移除百分比符號（`%`）
- 去除前後空格
- 轉換為 `Double` 類型

#### 4. Menu 組件優勢
相比 Picker：
- 更靈活的樣式控制
- 更好的視覺一致性
- 可自定義標籤外觀
- 支持複雜的佈局

### 用戶體驗提升

1. **配息月份選擇**：
   - 視覺風格統一，不再突兀
   - 清晰的選擇狀態指示
   - 友好的提示文字

2. **排序功能**：
   - 快速找到關鍵數據（最高殖利率、最大現值）
   - 直觀的點擊操作
   - 清晰的排序方向指示
   - 支持升降序切換

3. **整體體驗**：
   - 表格功能更完整
   - 數據分析更便捷
   - 操作更直觀高效


## 第八節：台股小卡即時刷新功能修復

### 問題背景

在 2025/11/18，用戶發現台股小卡在點擊「更新股價」按鈕後，報酬率沒有立即更新顯示：

**問題描述**：
- ✅ 美股小卡：點擊更新股價後，報酬率立即刷新 ✓
- ❌ 台股小卡：點擊更新股價後，報酬率沒有刷新 ✗

**根本原因**：
雖然時間戳正確記錄到 UserDefaults，但 CustomerDetailView 沒有監聽變化，導致視圖不會重新渲染。

### 解決方案

使用 **NotificationCenter** 通知機制，實現跨視圖的即時刷新。

#### 技術架構

```
TWStockInventoryView                CustomerDetailView
      (持倉視圖)                        (小卡視圖)
         |                                |
         | 1. 更新股價                      |
         ↓                                |
    儲存到 Core Data                       |
         ↓                                |
    記錄時間戳到 UserDefaults               |
         ↓                                |
    發送通知 📢                            |
         | "TWStockPriceUpdated"          |
         |--------------------------------→ 2. 接收通知
         |                                ↓
         |                          檢查客戶 ID
         |                                ↓
         |                          觸發刷新 (refreshTrigger)
         |                                ↓
         |                          視圖重新渲染 ✓
```

### 實作細節

#### 1. 添加刷新觸發器

**檔案位置**：`CustomerDetailView.swift` (line 30)

```swift
// 股價更新刷新觸發器
@State private var refreshTrigger = UUID()
```

**作用**：
- 當 `refreshTrigger` 改變時，綁定此 ID 的視圖會強制重新渲染
- 使用 UUID() 確保每次都是不同的值

#### 2. 發送通知（台股）

**檔案位置**：`TWStockInventoryView.swift` (lines 638-644)

```swift
// 記錄股價更新時間（用於小卡顯示邏輯）
if let client = client {
    let key = "twStockPriceUpdateTime_\(client.objectID.uriRepresentation().absoluteString)"
    UserDefaults.standard.set(Date(), forKey: key)
    print("✅ 已記錄台股價更新時間")

    // 發送通知，通知 CustomerDetailView 刷新
    NotificationCenter.default.post(
        name: NSNotification.Name("TWStockPriceUpdated"),
        object: nil,
        userInfo: ["clientID": client.objectID.uriRepresentation().absoluteString]
    )
}
```

**通知內容**：
- 通知名稱：`"TWStockPriceUpdated"`
- 攜帶數據：客戶 ID（用於識別哪個客戶的股價更新了）

#### 3. 發送通知（美股）

**檔案位置**：`USStockInventoryView.swift` (lines 485-491)

```swift
// 發送通知，通知 CustomerDetailView 刷新
NotificationCenter.default.post(
    name: NSNotification.Name("USStockPriceUpdated"),
    object: nil,
    userInfo: ["clientID": client.objectID.uriRepresentation().absoluteString]
)
```

#### 4. 監聽通知並刷新視圖

**檔案位置**：`CustomerDetailView.swift` (lines 104-123)

```swift
.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TWStockPriceUpdated"))) { notification in
    // 檢查是否是當前客戶的更新
    if let userInfo = notification.userInfo,
       let updatedClientID = userInfo["clientID"] as? String,
       updatedClientID == client.objectID.uriRepresentation().absoluteString {
        // 觸發視圖刷新
        refreshTrigger = UUID()
        print("🔄 收到台股價更新通知，刷新視圖")
    }
}
.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("USStockPriceUpdated"))) { notification in
    // 檢查是否是當前客戶的更新
    if let userInfo = notification.userInfo,
       let updatedClientID = userInfo["clientID"] as? String,
       updatedClientID == client.objectID.uriRepresentation().absoluteString {
        // 觸發視圖刷新
        refreshTrigger = UUID()
        print("🔄 收到美股價更新通知，刷新視圖")
    }
}
```

**關鍵邏輯**：
1. 使用 `.onReceive` 監聽通知
2. 檢查通知中的客戶 ID 是否與當前客戶匹配
3. 如果匹配，更新 `refreshTrigger` 觸發視圖刷新

#### 5. 綁定刷新觸發器到視圖

**檔案位置**：`CustomerDetailView.swift` (line 1581)

```swift
private var twStockCard: some View {
    VStack(spacing: 8) {
        // ... 台股小卡內容
    }
    .padding(20)
    .frame(height: 120)
    .background(
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.adaptiveCardBackground)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    )
    .id(refreshTrigger)  // 綁定刷新觸發器
}
```

**作用**：
- `.id(refreshTrigger)` 使視圖的身份與 `refreshTrigger` 綁定
- 當 `refreshTrigger` 改變時，SwiftUI 會將其視為新視圖並重新渲染
- 這會觸發 `getTWStockReturnRate()` 重新計算

### 執行流程

#### 完整刷新流程

```
1. 用戶點擊「台股持倉」小卡
   ↓
2. 打開 TWStockInventoryView
   ↓
3. 點擊「更新股價」按鈕
   ↓
4. 從 Yahoo Finance API 獲取最新股價
   ↓
5. 更新 Core Data 中的 TWStock 實體
   ↓
6. 記錄時間戳到 UserDefaults
   ↓
7. 發送通知 "TWStockPriceUpdated"
   ↓
8. CustomerDetailView 接收通知
   ↓
9. 檢查客戶 ID 是否匹配
   ↓
10. 更新 refreshTrigger = UUID()
   ↓
11. 台股小卡視圖重新渲染
   ↓
12. shouldUseInventoryData(stockType: "tw") 比較時間戳
   ↓
13. 返回 true（股價更新時間較新）
   ↓
14. getTWStockReturnRate() 從持倉明細計算報酬率
   ↓
15. 小卡顯示最新報酬率 ✓
```

### 時間戳比較邏輯

**檔案位置**：`CustomerDetailView.swift` (lines 2299-2326)

```swift
private func shouldUseInventoryData(stockType: String) -> Bool {
    guard let client = client else { return false }

    // 獲取股價更新時間
    let key = "\(stockType)StockPriceUpdateTime_\(client.objectID.uriRepresentation().absoluteString)"
    guard let priceUpdateTime = UserDefaults.standard.object(forKey: key) as? Date else {
        // 沒有股價更新記錄，使用月度資產
        return false
    }

    // 獲取月度資產時間
    guard let latestAsset = monthlyAssets.first,
          let assetTime = latestAsset.createdDate else {
        // 沒有月度資產，使用持倉明細
        return true
    }

    // 比較時間戳，返回股價更新是否較新
    let useInventory = priceUpdateTime > assetTime

    if useInventory {
        print("📊 \(stockType == "us" ? "美股" : "台股")小卡：使用持倉明細數據（股價更新時間：\(priceUpdateTime) > 月度資產時間：\(assetTime)）")
    } else {
        print("📊 \(stockType == "us" ? "美股" : "台股")小卡：使用月度資產數據（月度資產時間：\(assetTime) >= 股價更新時間：\(priceUpdateTime)）")
    }

    return useInventory
}
```

### 調試日誌

當功能正常運作時，會看到以下日誌：

```
✅ 成功更新 3 個台股的價格
✅ 已記錄台股價更新時間
🔄 收到台股價更新通知，刷新視圖
📊 台股小卡：使用持倉明細數據（股價更新時間：2025-11-18 14:30:45 > 月度資產時間：2025-11-18 09:00:00）
```

### 影響範圍

**修改檔案**：
1. `CustomerDetailView.swift`
   - 新增刷新觸發器 (line 30)
   - 新增通知監聽器 (lines 104-123)
   - 綁定刷新觸發器到台股小卡 (line 1581)

2. `TWStockInventoryView.swift`
   - 發送台股價更新通知 (lines 638-644)

3. `USStockInventoryView.swift`
   - 發送美股價更新通知 (lines 485-491)

**不影響**：
- ✅ 月度資產同步功能
- ✅ 貸款同步功能
- ✅ 股價更新的核心邏輯
- ✅ 時間戳記錄機制
- ✅ 其他小卡（定期定額、基金、債券等）

### 設計優勢

#### 1. 解耦合設計
- 持倉視圖和小卡視圖完全解耦
- 使用通知機制進行通信
- 各自職責清晰

#### 2. 精準更新
- 只有當前客戶的視圖會刷新
- 通過客戶 ID 精準匹配
- 避免不必要的刷新

#### 3. 即時響應
- 股價更新後立即刷新小卡
- 用戶體驗流暢
- 無需手動返回或重新進入頁面

#### 4. 易於擴展
- 可以輕鬆添加更多通知類型
- 其他視圖也可以監聽相同通知
- 支持一對多的通信模式

### 測試驗證

#### 測試步驟
1. 打開客戶詳情頁面
2. 觀察台股小卡當前報酬率
3. 點擊台股小卡進入持倉明細
4. 點擊「更新股價」按鈕
5. 等待股價更新完成
6. 關閉持倉明細頁面
7. 觀察台股小卡報酬率

**預期結果**：
- ✅ 報酬率立即更新為最新值
- ✅ 無需手動刷新或重新進入頁面
- ✅ 控制台輸出刷新日誌


## 第九節：美股/台股明細表格排序功能

### 問題背景

在 2025/11/18，用戶要求為美股明細和台股明細表格添加排序功能，以便快速找到關鍵數據：

**美股明細表格**需要排序的欄位：
- 市值 - 找出市值最大的持股
- 報酬率 - 找出報酬率最高的持股  
- 成本 - 找出成本最高的持股
- 損益 - 找出獲利最多的持股

**台股明細表格**需要排序的欄位：
- 市值 - 找出市值最大的持股
- 損益 - 找出獲利最多的持股
- 報酬率 - 找出報酬率最高的持股

### 解決方案

參考公司債明細表格的排序功能實現方式，為美股和台股明細表格添加點擊表頭排序功能。

### 實作細節

#### 1. 美股明細表格排序功能

**檔案位置**：`USStockDetailView.swift`

##### 1.1 新增排序狀態變數 (lines 12-13)

```swift
@State private var sortField: String? = nil
@State private var sortAscending: Bool = true
```

##### 1.2 更新表頭設計 (lines 193-224)

```swift
ForEach(currentColumnOrder, id: \.self) { header in
    if isSortableField(header) {
        // 可排序欄位
        Button(action: {
            handleSort(for: header)
        }) {
            HStack(spacing: 4) {
                Text(header)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                if sortField == header {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 14)
            .frame(minWidth: getColumnWidth(for: header), alignment: .center)
        }
        .buttonStyle(PlainButtonStyle())
    } else {
        // 不可排序欄位（保持原樣）
        Text(header)
            .font(.system(size: 15, weight: .semibold))
            // ...
    }
}
```

##### 1.3 排序邏輯實現

**可排序欄位判斷** (lines 332-335)：
```swift
private func isSortableField(_ header: String) -> Bool {
    return ["市值", "報酬率", "成本", "損益"].contains(header)
}
```

**處理排序點擊** (lines 337-347)：
```swift
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
```

**排序後的股票列表** (lines 314-330)：
```swift
private var sortedStocks: [USStock] {
    guard let sortField = sortField else {
        return Array(usStocks)
    }

    return usStocks.sorted { stock1, stock2 in
        let value1 = getNumericValue(stock: stock1, header: sortField)
        let value2 = getNumericValue(stock: stock2, header: sortField)

        if sortAscending {
            return value1 < value2
        } else {
            return value1 > value2
        }
    }
}
```

**獲取數字值** (lines 349-371)：
```swift
private func getNumericValue(stock: USStock, header: String) -> Double {
    let stringValue: String
    switch header {
    case "市值":
        stringValue = stock.marketValue ?? ""
    case "報酬率":
        stringValue = stock.returnRate ?? ""
    case "成本":
        stringValue = stock.cost ?? ""
    case "損益":
        stringValue = stock.profitLoss ?? ""
    default:
        return 0
    }

    // 移除 % 符號和逗號
    let cleanValue = removeCommas(stringValue)
        .replacingOccurrences(of: "%", with: "")
        .trimmingCharacters(in: .whitespaces)

    return Double(cleanValue) ?? 0
}
```

##### 1.4 更新資料顯示 (line 244)

```swift
ForEach(Array(sortedStocks.enumerated()), id: \.offset) { index, stock in
```

#### 2. 台股明細表格排序功能

**檔案位置**：`TWStockDetailView.swift`

##### 2.1 新增排序狀態變數 (lines 12-13)

```swift
@State private var sortField: String? = nil
@State private var sortAscending: Bool = true
```

##### 2.2 更新表頭設計 (lines 193-224)

與美股明細表格相同的表頭設計。

##### 2.3 排序邏輯實現

**可排序欄位判斷** (lines 332-335)：
```swift
private func isSortableField(_ header: String) -> Bool {
    return ["市值", "損益", "報酬率"].contains(header)
}
```

**排序後的股票列表** (lines 314-330)：
```swift
private var sortedStocks: [TWStock] {
    guard let sortField = sortField else {
        return Array(twStocks)
    }

    return twStocks.sorted { stock1, stock2 in
        let value1 = getNumericValue(stock: stock1, header: sortField)
        let value2 = getNumericValue(stock: stock2, header: sortField)

        if sortAscending {
            return value1 < value2
        } else {
            return value1 > value2
        }
    }
}
```

**獲取數字值** (lines 349-369)：
```swift
private func getNumericValue(stock: TWStock, header: String) -> Double {
    let stringValue: String
    switch header {
    case "市值":
        stringValue = stock.marketValue ?? ""
    case "損益":
        stringValue = stock.profitLoss ?? ""
    case "報酬率":
        stringValue = stock.returnRate ?? ""
    default:
        return 0
    }

    // 移除 % 符號和逗號
    let cleanValue = removeCommas(stringValue)
        .replacingOccurrences(of: "%", with: "")
        .trimmingCharacters(in: .whitespaces)

    return Double(cleanValue) ?? 0
}
```

### 使用場景

#### 場景 1：查找美股市值最大的持股

```
用戶操作流程：
1. 打開客戶詳情頁面
   ↓
2. 展開「美股明細」表格
   ↓
3. 點擊「市值」表頭
   ↓
4. 表頭顯示藍色向上箭頭 ↑（升序）
   ↓
5. 再次點擊「市值」表頭
   ↓
6. 箭頭變為向下箭頭 ↓（降序）
   ↓
7. 市值最大的美股顯示在最上方 ✓
```

#### 場景 2：查找台股報酬率最高的持股

```
用戶操作流程：
1. 展開「台股明細」表格
   ↓
2. 點擊「報酬率」表頭
   ↓
3. 表格按報酬率升序排列
   ↓
4. 再次點擊「報酬率」表頭
   ↓
5. 表格按報酬率降序排列
   ↓
6. 報酬率最高的台股顯示在最上方 ✓
```

#### 場景 3：查找美股成本最高的持股

```
用戶操作流程：
1. 展開「美股明細」表格
   ↓
2. 點擊「成本」表頭
   ↓
3. 再次點擊切換為降序
   ↓
4. 成本最高的美股顯示在最上方 ✓
```

### 排序功能對比表

| 表格類型 | 可排序欄位 | 排序方式 | 視覺提示 |
|---------|-----------|---------|---------|
| 美股明細 | 市值、報酬率、成本、損益 | 點擊表頭 | 藍色箭頭 ↑↓ |
| 台股明細 | 市值、損益、報酬率 | 點擊表頭 | 藍色箭頭 ↑↓ |
| 公司債明細 | 殖利率、申購金額、交易金額、現值 | 點擊表頭 | 藍色箭頭 ↑↓ |

### 排序行為

| 欄位 | 數據處理 | 排序邏輯 |
|-----|---------|---------|
| 市值 | 移除逗號 | 數字大小排序 |
| 報酬率 | 移除 % 和逗號 | 數字大小排序 |
| 成本 | 移除逗號 | 數字大小排序 |
| 損益 | 移除逗號 | 數字大小排序（支援負數）|

### 影響範圍

**修改檔案**：
1. `USStockDetailView.swift`
   - 新增排序狀態變數 (lines 12-13)
   - 更新表頭設計 (lines 193-224)
   - 新增排序相關函數 (lines 314-371)
   - 更新資料顯示 (line 244)

2. `TWStockDetailView.swift`
   - 新增排序狀態變數 (lines 12-13)
   - 更新表頭設計 (lines 193-224)
   - 新增排序相關函數 (lines 314-369)
   - 更新資料顯示 (line 244)

**不影響**：
- ✅ 股票資料的增刪改功能
- ✅ 自動計算欄位（市值、損益、報酬率）
- ✅ 欄位重新排序功能
- ✅ 千分位格式化顯示
- ✅ 股價更新功能
- ✅ CSV 匯入功能

### 設計一致性

所有明細表格（公司債、美股、台股）現在擁有統一的排序交互：

**統一的設計元素**：
1. ✅ 點擊表頭排序
2. ✅ 藍色箭頭指示排序方向
3. ✅ 首次點擊為升序 ↑
4. ✅ 再次點擊切換為降序 ↓
5. ✅ 不可排序欄位保持純文字顯示
6. ✅ 自動清理數據（移除逗號、百分比符號）

**用戶體驗提升**：
- 快速找到關鍵數據（最大市值、最高報酬率等）
- 直觀的點擊操作
- 清晰的排序方向指示
- 支持升降序切換
- 數據分析更便捷

### 測試驗證

#### 測試項目

1. **美股明細排序**
   - 點擊「市值」，確認按市值升序排列
   - 再次點擊，確認切換為降序
   - 點擊「報酬率」，確認排序切換到報酬率欄位
   - 驗證「成本」和「損益」排序功能

2. **台股明細排序**
   - 點擊「市值」，確認按市值升序排列
   - 點擊「損益」，確認正確處理負數
   - 點擊「報酬率」，確認百分比正確排序

3. **數據正確性**
   - 驗證移除逗號後的數字排序正確
   - 驗證百分比排序正確（移除 %）
   - 驗證負數損益排序正確

4. **視覺提示**
   - 確認藍色箭頭正確顯示
   - 確認升序顯示 ↑，降序顯示 ↓
   - 確認只有當前排序欄位顯示箭頭

---

## 10. 日期格式統一功能 (Date Format Standardization)

**開發日期**: 2025-11-18  
**狀態**: ✅ 已完成  
**影響範圍**: MonthlyAssetDetailView.swift, CorporateBondsDetailView.swift

### 功能概述

統一應用程式中所有日期顯示格式，將「月度資產明細」的日期欄位和「公司債明細」的申購日欄位，統一顯示為 `yyyy/MM/dd` 格式（例如：2025/11/18）。

### 實現細節

#### 1. 月度資產明細 - 日期欄位格式化

**檔案**: `MonthlyAssetDetailView.swift`  
**修改位置**: Lines 487-500

**實現邏輯**:
```swift
case "日期":
    // 格式化日期為 yyyy/MM/dd 格式
    if let dateStr = asset.date, !dateStr.isEmpty {
        if let date = parseDateString(dateStr) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            rawValue = formatter.string(from: date)
        } else {
            rawValue = dateStr
        }
    } else {
        rawValue = ""
    }
```

**處理流程**:
1. 檢查 asset.date 是否存在且非空
2. 使用 parseDateString() 解析原始日期字串
3. 創建 DateFormatter 並設定格式為 "yyyy/MM/dd"
4. 將解析後的 Date 轉換為統一格式字串
5. 如果解析失敗，保留原始字串
6. 如果日期為空，顯示空字串

#### 2. 公司債明細 - 申購日欄位格式化

**檔案**: `CorporateBondsDetailView.swift`  
**修改位置**: Lines 612-624

**實現邏輯**:
```swift
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
```

**處理流程**:
1. 檢查 bond.subscriptionDate 是否存在且非空
2. 使用 parseSubscriptionDate() 解析原始日期字串
3. 創建 DateFormatter 並設定格式為 "yyyy/MM/dd"
4. 將解析後的 Date 轉換為統一格式字串
5. 如果解析失敗，保留原始字串
6. 如果日期為空，顯示空字串

### 技術要點

#### 日期格式化策略

**顯示層格式化** (Display Layer Formatting):
- 格式化僅在視圖層 (get closure) 進行
- 原始資料保持不變，確保相容性
- 支援多種輸入格式的自動解析
- 輸出統一為 `yyyy/MM/dd` 格式

**優點**:
1. ✅ 不影響資料庫儲存格式
2. ✅ 保持向後相容性
3. ✅ 支援舊資料自動轉換顯示
4. ✅ 用戶輸入更加直觀
5. ✅ 提升應用一致性

#### 日期解析函數

**MonthlyAssetDetailView.swift**:
- 使用 `parseDateString()` 函數
- 支援多種日期格式解析
- 返回 Date? 類型

**CorporateBondsDetailView.swift**:
- 使用 `parseSubscriptionDate()` 函數
- 專門處理申購日期格式
- 返回 Date? 類型

### 使用場景

#### 場景 1：查看月度資產明細

```
用戶操作流程：
1. 進入「月度資產明細」頁面
   ↓
2. 查看「日期」欄位
   ↓
3. 所有日期統一顯示為「2025/11/18」格式 ✓
```

#### 場景 2：查看公司債申購日

```
用戶操作流程：
1. 進入「公司債明細」頁面
   ↓
2. 查看「申購日」欄位
   ↓
3. 所有申購日統一顯示為「2025/11/18」格式 ✓
```

#### 場景 3：輸入新日期

```
用戶操作流程：
1. 新增月度資產或公司債
   ↓
2. 輸入日期（支援多種格式）
   ↓
3. 儲存後自動顯示為「2025/11/18」格式 ✓
   ↓
4. 輸入更加直觀、易讀 ✓
```

### 日期格式對比表

| 欄位 | 原始格式（範例） | 統一後格式 | 檔案位置 |
|-----|---------------|-----------|---------|
| 月度資產日期 | 多種格式 | 2025/11/18 | MonthlyAssetDetailView.swift |
| 公司債申購日 | 多種格式 | 2025/11/18 | CorporateBondsDetailView.swift |

### 格式化前後對比

**格式化前**（可能的各種格式）:
- ❌ 2025-11-18
- ❌ 18/11/2025
- ❌ Nov 18, 2025
- ❌ 20251118

**格式化後**（統一格式）:
- ✅ 2025/11/18
- ✅ 2025/11/18
- ✅ 2025/11/18
- ✅ 2025/11/18

### 影響範圍

**修改檔案**：
1. `MonthlyAssetDetailView.swift`
   - 修改 bindingForAsset 的 get closure (lines 487-500)
   - 在「日期」case 中添加格式化邏輯
   - 使用 DateFormatter 轉換顯示格式

2. `CorporateBondsDetailView.swift`
   - 修改 bindingForBond 的 get closure (lines 612-624)
   - 在「申購日」case 中添加格式化邏輯
   - 使用 DateFormatter 轉換顯示格式

**不影響**：
- ✅ 資料庫儲存格式（Core Data）
- ✅ CloudKit 同步
- ✅ 日期的增刪改功能
- ✅ 日期計算邏輯
- ✅ 其他欄位的顯示
- ✅ 舊資料的讀取

### 設計一致性

#### 統一的顯示格式

**格式規範**:
- 年份：4位數字（例如：2025）
- 月份：2位數字，不足補0（例如：01, 11）
- 日期：2位數字，不足補0（例如：08, 18）
- 分隔符：斜線 `/`
- 完整格式：`yyyy/MM/dd`

#### 用戶體驗提升

**一致性**:
1. ✅ 所有日期欄位使用相同格式
2. ✅ 易讀易懂的顯示方式
3. ✅ 符合常見日期書寫習慣
4. ✅ 避免格式混亂造成的困惑

**直觀性**:
1. ✅ 用戶輸入後自動格式化
2. ✅ 無需記憶特定格式
3. ✅ 顯示格式清晰明確
4. ✅ 提升數據可讀性

### 測試驗證

#### 測試項目

1. **月度資產日期顯示**
   - 新增月度資產，確認日期顯示為 yyyy/MM/dd
   - 查看現有資料，確認舊日期正確轉換顯示
   - 編輯日期，確認格式保持一致

2. **公司債申購日顯示**
   - 新增公司債，確認申購日顯示為 yyyy/MM/dd
   - 查看現有債券，確認舊申購日正確轉換顯示
   - 編輯申購日，確認格式保持一致

3. **格式兼容性**
   - 測試各種輸入格式（2025-11-18、18/11/2025等）
   - 確認都能正確解析並統一顯示
   - 驗證解析失敗時的容錯處理

4. **資料完整性**
   - 確認格式化不影響資料儲存
   - 驗證 CloudKit 同步正常
   - 確認日期計算功能正常

### 用戶反饋

> "這樣用戶要輸入也比較直觀"

**用戶期望**:
- 希望所有日期顯示格式統一
- 期望格式為 `yyyy/MM/dd`（例如：2025/11/18）
- 要求格式化僅影響顯示，不改變儲存

**實現成果**:
- ✅ 統一了月度資產明細和公司債明細的日期格式
- ✅ 採用直觀的 `yyyy/MM/dd` 格式
- ✅ 僅在顯示層格式化，不影響資料儲存
- ✅ 提升了用戶體驗和數據可讀性

### 技術亮點

1. **非侵入式格式化**
   - 僅修改視圖層的 get closure
   - 不修改資料模型或儲存邏輯
   - 保持向後相容性

2. **容錯處理**
   - 解析失敗時保留原始字串
   - 空值情況正確處理
   - 不會造成崩潰或錯誤

3. **可擴展性**
   - 易於添加更多日期格式支援
   - DateFormatter 配置靈活
   - 可輕鬆調整顯示格式

4. **一致性設計**
   - 所有日期欄位使用相同邏輯
   - 代碼結構清晰易維護
   - 遵循 DRY 原則

### 維護建議

1. **新增日期欄位時**
   - 在 get closure 中添加格式化邏輯
   - 使用相同的 DateFormatter 配置
   - 保持 `yyyy/MM/dd` 格式一致

2. **修改日期格式時**
   - 只需修改 DateFormatter.dateFormat
   - 所有日期欄位會自動更新
   - 無需修改資料庫或模型

3. **除錯日期問題時**
   - 檢查日期解析函數是否正確
   - 驗證 DateFormatter 配置
   - 確認原始資料格式

---
