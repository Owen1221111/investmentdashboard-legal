# CloudKit 整合設定指南

## 🎯 CloudKit 設定步驟

### 1. Xcode 專案設定

#### 1.1 啟用 CloudKit Capability
1. 在 Xcode 中選擇專案檔案
2. 選擇 Target: `InvestmentDashboard`
3. 點擊 `Signing & Capabilities` 標籤
4. 點擊 `+ Capability` 按鈕
5. 搜尋並添加 `CloudKit`
6. 系統會自動建立一個 iCloud Container

#### 1.2 iCloud Container 設定
- Container ID: `iCloud.com.yourcompany.InvestmentDashboard`
- 確保 Container 已勾選並啟用

#### 1.3 背景模式設定 (選用)
1. 添加 `Background Modes` capability
2. 勾選 `Background App Refresh`
3. 勾選 `Remote notifications`

### 2. CloudKit Dashboard 設定

#### 2.1 存取 CloudKit Dashboard
1. 前往 [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. 登入你的 Apple Developer 帳號
3. 選擇你的 Container

#### 2.2 建立 Record Types
需要建立以下四個 Record Types：

##### Client Record Type
```
Record Type: Client
Fields:
- name (String, Indexed)
- email (String)
- createdDate (Date/Time, Indexed)
```

##### MonthlyAssetRecord Record Type
```
Record Type: MonthlyAssetRecord
Fields:
- clientID (String, Indexed)
- date (Date/Time, Indexed)
- cash (Double)
- usStock (Double)
- regularInvestment (Double)
- bonds (Double)
- structuredProducts (Double)
- twStock (Double)
- twStockConverted (Double)
- confirmedInterest (Double)
- deposit (Double)
- cashCost (Double)
- stockCost (Double)
- bondCost (Double)
- otherCost (Double)
- notes (String)
```

##### Bond Record Type
```
Record Type: Bond
Fields:
- clientID (String, Indexed)
- purchaseDate (Date/Time, Indexed)
- bondName (String, Indexed)
- couponRate (Double)
- yieldRate (Double)
- purchasePrice (Double)
- purchaseAmount (Double)
- holdingFaceValue (Double)
- tradeAmount (Double)
- currentValue (Double)
- receivedInterest (Double)
- dividendMonths (String)
- singleDividend (Double)
- annualDividend (Double)
```

##### StructuredProduct Record Type
```
Record Type: StructuredProduct
Fields:
- clientID (String, Indexed)
- tradeDate (Date/Time, Indexed)
- target (String, Indexed)
- executionDate (Date/Time)
- latestEvaluationDate (Date/Time)
- periodPrice (Double)
- executionPrice (Double)
- knockOutBarrier (Double)
- knockInBarrier (Double)
- yield (Double)
- monthlyYield (Double)
- tradeAmount (Double)
- notes (String)
- status (String, Indexed)
- exitDate (Date/Time)
- holdingMonths (Int64)
- actualYield (Double)
- exitAmount (Double)
- actualReturn (Double)
```

#### 2.3 設定索引 (Indexes)
為查詢效能，建議為以下欄位建立索引：
- `Client.name`
- `MonthlyAssetRecord.clientID`
- `MonthlyAssetRecord.date`
- `Bond.clientID`
- `Bond.purchaseDate`
- `Bond.bondName`
- `StructuredProduct.clientID`
- `StructuredProduct.tradeDate`
- `StructuredProduct.status`

#### 2.4 權限設定
1. 進入 `Security Roles`
2. 確認 `World` 權限設定：
   - Read: No Access (私人資料)
   - Write: No Access
3. 確認 `Authenticated` 權限設定：
   - Read: Full Access
   - Write: Full Access

### 3. 程式碼整合

#### 3.1 更新 App Entry Point
修改 `InvestmentDashboardApp.swift`：

```swift
import SwiftUI

@main
struct InvestmentDashboardApp: App {
    @StateObject private var dataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
```

#### 3.2 更新 ContentView
將現有的 ContentView 中的 `@StateObject private var viewModel = ClientViewModel()`
修改為使用新的 ViewModel：

```swift
@EnvironmentObject var dataManager: DataManager
@StateObject private var viewModel = ClientViewModelNew()
```

#### 3.3 資料遷移
在 ContentView 的適當位置添加遷移邏輯：

```swift
.onAppear {
    Task {
        // 遷移現有的債券資料
        if !bondDataList.isEmpty {
            await viewModel.migrateLegacyBondData(bondDataList)
        }
    }
}
```

### 4. 測試

#### 4.1 本地測試
1. 在模擬器中測試應用
2. 確認可以建立、讀取、更新、刪除資料
3. 測試離線功能

#### 4.2 多裝置測試
1. 在兩個不同的裝置上安裝應用
2. 使用相同的 Apple ID 登入 iCloud
3. 在一個裝置上新增資料
4. 確認另一個裝置可以同步到資料

#### 4.3 網路狀態測試
1. 測試離線新增資料
2. 恢復網路連線
3. 確認離線資料會自動同步

### 5. 注意事項

#### 5.1 iCloud 帳號要求
- 使用者必須在裝置上登入 iCloud
- 建議在應用中提供引導，協助使用者檢查 iCloud 狀態

#### 5.2 資料同步
- CloudKit 同步可能有延遲（通常幾秒到數分鐘）
- 大量資料同步可能需要較長時間

#### 5.3 錯誤處理
- 實作適當的錯誤提示
- 處理網路連線問題
- 處理 iCloud 配額不足等情況

#### 5.4 隱私權
- CloudKit 資料會儲存在使用者的 iCloud 中
- 資料會依照 Apple 的隱私權政策處理

### 6. 故障排除

#### 6.1 常見問題
- **問題**: CloudKit 同步失敗
  - **解決**: 檢查 iCloud 帳號狀態和網路連線

- **問題**: Record Type 不存在
  - **解決**: 確認在 CloudKit Dashboard 中已正確建立 Record Types

- **問題**: 權限被拒絕
  - **解決**: 檢查 CloudKit Dashboard 中的權限設定

#### 6.2 除錯工具
- 使用 Xcode Console 查看 CloudKit 相關日誌
- 在 CloudKit Dashboard 中查看資料庫內容
- 使用 CloudKit 的內建錯誤訊息進行診斷

---

## 🚀 準備上線

### 部署到 Production
1. 在 CloudKit Dashboard 中切換到 Production 環境
2. 複製 Development 的 Schema 到 Production
3. 更新應用的 CloudKit Container 設定
4. 進行完整測試

### App Store Review
- CloudKit 應用通常容易通過審核
- 確保應用在沒有 iCloud 帳號時有適當的提示
- 提供清楚的隱私權說明