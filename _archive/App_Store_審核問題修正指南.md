# App Store 審核問題修正指南

**審核編號**：ed6a0138-bdab-4f81-bdcd-4052d030abe7
**審核日期**：2025年11月13日
**審核版本**：1.0
**測試設備**：iPad Air 11-inch (M3), iPadOS 26.0.1

---

## 📋 審核問題總覽

### 問題 1：免費試用資訊未在 StoreKit 付款頁面顯示 ⚠️
**準則**：2.1 - Performance - App Completeness
**嚴重程度**：高 - 必須修正

**審核團隊回饋**：
> We found that your in-app purchase products exhibited bugs which create a poor user experience. Specifically, the "free trial information" was not displayed on the in-app purchase payment sheet.

### 問題 2：促銷圖片不符合規範 ⚠️
**準則**：2.3.2 - Performance - Accurate Metadata
**嚴重程度**：中 - 必須修正

**審核團隊回饋**：
> Your promotional image is a screenshot taken from your app. The promotional image should be unique and accurately represent the associated promoted in-app purchase.

### 問題 3：內購描述包含價格引用 ⚠️
**準則**：2.3.2 - Performance - Accurate Metadata
**嚴重程度**：中 - 必須修正

**審核團隊回饋**：
> The Description for your promoted in-app purchase product, 月費方案, includes references to the price of your in-app purchase (e.g., NT$100), which is not appropriate.

---

## 🔧 修正方案

### 解決方案 1：修正免費試用資訊顯示

#### A. 本地 StoreKit Configuration 已更新 ✅

**修改文件**：`Configuration.storekit`

**已完成的修改**：
```json
{
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
}
```

#### B. App Store Connect 設定檢查清單 ⚠️ 需要手動執行

登入 [App Store Connect](https://appstoreconnect.apple.com/)，按照以下步驟檢查並修正：

**步驟 1：進入訂閱設定**
1. 選擇你的 App：「InvestmentDashboard」
2. 點擊左側選單「功能」→「App 內購買項目」
3. 找到訂閱群組：「InvestmentDashboard Premium」
4. 點擊訂閱產品：「月費方案」或「Monthly Subscription」

**步驟 2：確認訂閱產品 ID**
確保產品 ID 完全一致：
```
com.owenliu.investmentdashboard.monthly
```

**步驟 3：設定訂閱價格與免費試用** 🔴 最重要
1. 向下滾動到「訂閱價格」區域
2. 確認價格：NT$100 / 月
3. **關鍵步驟**：設定「介紹性優惠」（Introductory Offer）
   - 點擊「新增介紹性優惠」
   - 選擇類型：**免費試用（Free Trial）**
   - 期限：**1個月（1 Month）**
   - 確認顯示：「首月免費，之後每月 NT$100」
4. 點擊「儲存」

**步驟 4：設定訂閱本地化資訊**
1. 向下滾動到「App Store 本地化資訊」
2. 確保已設定以下語言：

**繁體中文 (zh-Hant)**
- 訂閱顯示名稱：`月費方案`（最多 30 字元）
- 描述：`解鎖所有進階功能`（最多 45 字元，**不包含價格**）

**英文 (en-US)**
- Subscription Display Name: `Monthly Subscription`
- Description: `Unlock all premium features`

**步驟 5：確認「審查資訊」**
1. 點擊「審查資訊」標籤
2. 確保有填寫：
   - 審查備註：說明免費試用期為 30 天
   - 截圖：上傳顯示免費試用資訊的截圖

**步驟 6：儲存並提交審查**
1. 點擊右上角「儲存」
2. 返回 App 版本頁面
3. 重新提交審查

#### C. 代碼檢查（已確認正常）✅

**SubscriptionManager.swift** - 使用 StoreKit 2 正確實現：
```swift
let result = try await product.purchase()
```

這個 API 會自動顯示 Apple 的標準付款頁面，包括免費試用資訊。

---

### 解決方案 2：修正促銷圖片

#### 選項 A：設計獨特的促銷圖片（推薦）

**要求**：
- 尺寸：1024 x 1024 像素
- 格式：PNG 或 JPG
- 內容：不能是 App 截圖，應該是設計圖片

**設計建議**：
```
┌───────────────────────────┐
│                           │
│    🏦  投資儀表板         │
│                           │
│    月費方案               │
│    NT$100 / 月           │
│                           │
│    ✨ 首月免費試用       │
│    📊 無限客戶管理       │
│    ☁️  iCloud 同步       │
│                           │
└───────────────────────────┘
```

**上傳步驟**：
1. App Store Connect → 你的 App → App 內購買項目
2. 選擇「月費方案」
3. 向下滾動到「推廣圖片」
4. 上傳新設計的圖片
5. 儲存

#### 選項 B：刪除促銷圖片（快速方法）

如果你不打算在 App Store 推廣此內購項目：
1. App Store Connect → App 內購買項目 → 月費方案
2. 找到「推廣圖片」區域
3. 點擊圖片旁的「X」刪除
4. 儲存

---

### 解決方案 3：修正內購描述（移除價格引用）

#### App Store Connect 修改步驟

1. App Store Connect → App 內購買項目 → 月費方案
2. 找到「本地化資訊」→ 繁體中文
3. **目前的描述（錯誤）**：
   ```
   月費方案 NT$100 / 月，首月免費試用
   ```

4. **修改為（正確）**：
   ```
   解鎖所有進階功能
   ```
   或
   ```
   無限客戶管理、iCloud 同步、OCR 辨識
   ```

5. **字數限制**：
   - 顯示名稱：最多 30 字元
   - 描述：最多 45 字元

6. 儲存變更

#### 為什麼不能包含價格？

Apple 的規定：
> 價格已經在產品頁面上顯示，在描述中包含價格可能在所有國家/地區不準確（因為貨幣和定價可能不同）。

---

## ✅ 修正檢查清單

在重新提交前，請確認：

### 本地代碼修改
- [x] ✅ 已更新 `Configuration.storekit` 本地化資訊
- [ ] 測試本地 StoreKit 是否正確顯示免費試用資訊

### App Store Connect 修改
- [ ] ⚠️ 確認訂閱產品 ID 正確
- [ ] ⚠️ 確認免費試用期設定為 1 個月
- [ ] ⚠️ 確認本地化資訊不包含價格
- [ ] ⚠️ 上傳新的促銷圖片或刪除現有圖片
- [ ] ⚠️ 確認「審查資訊」已填寫

### 測試驗證
- [ ] 在 TestFlight 測試免費試用流程
- [ ] 確認付款頁面顯示「首月免費，之後每月 NT$100」
- [ ] 截圖付款頁面，準備提供給審查團隊

---

## 📸 需要的截圖證明

為了加速審查，建議準備以下截圖：

1. **付款頁面截圖**
   - 顯示「首月免費試用」
   - 顯示「試用結束後每月 NT$100」
   - 顯示「可隨時取消」

2. **訂閱管理頁面截圖**
   - 顯示試用期剩餘天數
   - 顯示訂閱狀態

3. **App Store Connect 設定截圖**
   - 訂閱產品設定頁面
   - 顯示免費試用期設定

---

## 🔄 重新提交流程

### 步驟 1：完成所有修正
1. ✅ 更新本地 Configuration.storekit（已完成）
2. ⚠️ 更新 App Store Connect 訂閱設定
3. ⚠️ 修正/刪除促銷圖片
4. ⚠️ 修正內購描述

### 步驟 2：構建新版本
```bash
# 1. 更新 Build Number
# Xcode → Project Settings → General → Build: 2

# 2. Archive
Xcode → Product → Archive

# 3. Upload to App Store Connect
Xcode → Window → Organizer → Upload
```

### 步驟 3：提交審查
1. App Store Connect → 你的 App → 1.0 版本
2. 選擇新的 Build（Build 2）
3. 在「審查備註」中說明修正內容：

**建議的審查備註（英文）**：
```
Dear App Review Team,

Thank you for your feedback. We have made the following changes to address the issues:

1. Free Trial Information Display (Guideline 2.1):
   - Updated the subscription product configuration in App Store Connect
   - Ensured the introductory offer (1-month free trial) is properly set
   - Verified that the free trial information now appears on the StoreKit payment sheet

2. Promotional Image (Guideline 2.3.2):
   - [Option A: Replaced the screenshot with a unique designed promotional image]
   - [Option B: Removed the promotional image as we don't plan to promote this IAP]

3. IAP Description (Guideline 2.3.2):
   - Removed all price references from the subscription description
   - Updated description to: "Unlock all premium features"

Attached screenshots show the free trial information correctly displayed on the payment sheet.

Thank you for your time and consideration.
```

**中文版本**：
```
親愛的審查團隊：

感謝您的反饋。我們已針對問題進行以下修正：

1. 免費試用資訊顯示（準則 2.1）：
   - 已在 App Store Connect 更新訂閱產品設定
   - 確保介紹性優惠（1個月免費試用）正確設定
   - 驗證免費試用資訊現在會顯示在 StoreKit 付款頁面

2. 促銷圖片（準則 2.3.2）：
   - [選項 A：已替換為獨特設計的促銷圖片]
   - [選項 B：已刪除促銷圖片，因為我們不打算推廣此內購項目]

3. 內購描述（準則 2.3.2）：
   - 已從訂閱描述中移除所有價格引用
   - 更新描述為：「解鎖所有進階功能」

附件截圖顯示付款頁面正確顯示免費試用資訊。

感謝您的時間與審查。
```

4. 上傳相關截圖
5. 點擊「提交審查」

---

## ⏱️ 預計時程

| 階段 | 時間 |
|------|------|
| 完成 App Store Connect 修改 | 30 分鐘 |
| 本地測試驗證 | 1 小時 |
| 構建並上傳新版本 | 30 分鐘 |
| Apple 審查時間 | 1-3 天 |
| **總計** | **2-4 天** |

---

## 🆘 常見問題

### Q1: 為什麼付款頁面沒有顯示免費試用資訊？

**A**: 最常見的原因：
1. ❌ App Store Connect 中沒有設定介紹性優惠（免費試用）
2. ❌ 訂閱產品狀態不是「準備提交」或「已批准」
3. ❌ 使用的測試帳號之前已經用過試用期

**解決方法**：
1. 確認 App Store Connect 設定正確
2. 使用新的沙箱測試帳號
3. 在真機上測試（不是模擬器）

### Q2: 如何測試免費試用是否正常運作？

**A**:
1. 在 App Store Connect 創建沙箱測試帳號
2. 在真機上登出 App Store（設定 > App Store > 登出）
3. 運行你的 App
4. 點擊「開始免費試用」
5. 使用沙箱測試帳號登入
6. 確認付款頁面顯示：「首月免費，之後每月 NT$100」

### Q3: 促銷圖片可以用什麼設計？

**A**: 可以使用：
- ✅ 圖標 + 文字的設計圖
- ✅ 功能亮點的圖示設計
- ✅ 品牌形象圖

不可以使用：
- ❌ 直接截圖
- ❌ 包含完整 UI 介面的圖片

### Q4: 如果我不想設計促銷圖片怎麼辦？

**A**: 可以選擇刪除促銷圖片。促銷圖片是選填項目，只有在你想在 App Store 推廣內購項目時才需要。

---

## 📞 需要協助？

如果遇到問題，可以：

1. **聯繫 Apple 審查團隊**
   - 在 App Store Connect 回覆審查意見
   - 選擇語言：中文或英文
   - 說明你的疑問

2. **要求電話溝通**
   - 在審查回覆頁面點擊「Request a call」
   - Apple 會在 3-5 個工作日內致電
   - 時間：週二和週四的當地營業時間

3. **預約 App Review Appointment**
   - 前往 [Meet with Apple](https://developer.apple.com/contact/app-store/)
   - 選擇「App Review Appointment」
   - 與 Apple 工程師直接討論

---

## 📝 相關文件

- [StoreKit 2 文件](https://developer.apple.com/documentation/storekit)
- [訂閱最佳實踐](https://developer.apple.com/app-store/subscriptions/)
- [App Store 審查準則](https://developer.apple.com/app-store/review/guidelines/)
- [內購項目元數據規範](https://developer.apple.com/help/app-store-connect/reference/promotional-image-specifications)

---

最後更新：2025年11月13日
作者：Claude AI Assistant
