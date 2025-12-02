# CloudKit Debug 工具使用指南

## 🎯 概述

我已經為你的投資儀表板應用程式創建了一個完整的CloudKit debug工具，讓你可以在開發過程中方便地檢查和診斷iCloud同步問題。

## 🚀 如何啟用Debug模式

1. **啟用Debug模式**：
   - 在 `InvestmentDashboardApp.swift` 中，`isDebugMode` 已設定為 `true`
   - 這會啟用帶有debug功能的特殊界面

2. **切換回正常模式**：
   - 將 `InvestmentDashboardApp.swift` 中的 `isDebugMode` 改為 `false`

## 📱 Debug界面功能

當啟用debug模式時，應用程式會顯示兩個tab：

### Tab 1: 投資儀表板 (主要功能)
- 簡化版的主要應用界面
- 客戶管理功能
- 基本的資料檢視功能

### Tab 2: Debug (CloudKit診斷)
包含6個不同的檢查頁面：

#### 🔍 狀態頁面
顯示：
- CloudKit Container ID
- iCloud登入狀態
- 網路連線狀態
- 各類型資料的數量統計
- 最新記錄的時間

#### 👤 客戶頁面
顯示所有同步的客戶資料：
- 客戶姓名和Email
- 客戶ID (前8碼)
- 建立時間

#### 📊 資產記錄頁面
顯示所有月度資產記錄：
- 記錄ID和日期
- 關聯的客戶ID
- 各類資產金額

#### 💰 債券頁面
顯示所有債券記錄：
- 債券名稱和購入資訊
- 票面利率和金額
- 關聯的客戶ID

#### 🏗️ 結構型商品頁面
顯示所有結構型商品：
- 商品目標和狀態
- 交易金額和收益率
- 關聯的客戶ID

#### ⚙️ 操作頁面
提供各種debug操作：
- **🔄 強制同步**: 手動觸發CloudKit同步
- **📊 檢查iCloud狀態**: 詳細檢查iCloud帳號狀態
- **🧪 建立測試客戶**: 快速建立測試資料
- **🗑️ 清除測試資料**: 刪除名稱包含"測試"的資料

## 🔧 常見問題診斷

### 問題1: iCloud狀態顯示"未登入"
**可能原因**：
- 裝置未登入iCloud帳號
- iCloud Drive未啟用
- CloudKit權限問題

**解決方法**：
1. 前往「設定」→「[你的姓名]」→「iCloud」
2. 確認已登入iCloud
3. 確認「iCloud Drive」已啟用
4. 在debug界面點擊「檢查iCloud狀態」查看詳細錯誤

### 問題2: 資料數量為0
**可能原因**：
- CloudKit Container未正確設定
- Record Types未在CloudKit Dashboard中建立
- 權限設定問題

**解決方法**：
1. 檢查CloudKit Dashboard：https://icloud.developer.apple.com/dashboard/
2. 確認Container `iCloud.com.owen.InvestmentDashboard` 存在
3. 確認已建立所需的Record Types (依照 `CLOUDKIT_SETUP.md`)
4. 嘗試「建立測試客戶」來測試寫入功能

### 問題3: 同步失敗
**可能原因**：
- 網路連線問題
- iCloud服務暫時不可用
- 資料格式問題

**解決方法**：
1. 檢查網路連線
2. 點擊「強制同步」重新嘗試
3. 查看Xcode Console的錯誤訊息

## 📝 如何檢查同步狀態

### 步驟1: 基本狀態檢查
1. 開啟應用程式
2. 切換到「Debug」tab
3. 查看頂部的狀態指示器：
   - **綠色圓點**: iCloud已登入，網路正常
   - **紅色圓點**: iCloud未登入
   - **橙色圓點**: 網路離線

### 步驟2: 詳細狀態檢查
1. 點擊「狀態」頁面
2. 查看詳細的系統資訊
3. 記錄任何錯誤或異常狀態

### 步驟3: 測試資料同步
1. 點擊「操作」頁面
2. 點擊「建立測試客戶」
3. 檢查是否成功建立
4. 切換到「客戶」頁面確認資料顯示

### 步驟4: 多裝置測試
1. 在第一個裝置上建立測試資料
2. 在第二個裝置上點擊「強制同步」
3. 檢查資料是否出現在第二個裝置

## 🛠️ 開發者提示

### Console日誌
在Xcode中查看Console輸出，CloudKit相關的錯誤會顯示詳細資訊：
```
客戶記錄獲取失敗: [錯誤詳情]
iCloud 帳號狀態檢查失敗: [錯誤詳情]
```

### CloudKit Dashboard
定期檢查CloudKit Dashboard中的資料：
1. 前往 https://icloud.developer.apple.com/dashboard/
2. 選擇你的Container
3. 查看「Data」→「Records」確認資料是否正確儲存

### 測試建議
1. **先在模擬器測試**: 確保基本功能正常
2. **真機測試**: 確保iCloud同步正常
3. **多裝置測試**: 確保跨裝置同步正常
4. **離線測試**: 測試離線時的行為

## 🔒 安全提醒

- Debug功能僅用於開發階段
- 上架前記得將 `isDebugMode` 設為 `false`
- 不要在生產環境暴露debug功能
- 測試資料建議定期清理

## 📞 需要幫助？

如果你在使用debug工具時遇到問題：

1. **記錄錯誤訊息**: 截圖或複製具體的錯誤訊息
2. **檢查設定**: 確認CloudKit設定正確
3. **查看文件**: 參考 `CLOUDKIT_SETUP.md` 中的詳細設定步驟
4. **測試網路**: 確認裝置網路連線正常

這個debug工具應該能幫助你快速診斷和解決CloudKit相關的問題！