# 將新檔案加入 Xcode 專案指南

## 需要加入的檔案

已為您創建了以下兩個新檔案，需要加入到 Xcode 專案中：

1. `FieldConfigurationManager.swift` - 欄位配置管理器
2. `AssetFieldConfigurationView.swift` - 欄位配置視圖

## 手動加入步驟

### 方法一：拖放加入（最簡單）

1. 在 Finder 中打開：
   ```
   /Users/chehungliu/Desktop/superdesign-template拷貝/InvestmentDashboard/InvestmentDashboard/
   ```

2. 在 Xcode 中打開專案

3. 在 Xcode 左側的專案導航器中，找到 `InvestmentDashboard` 資料夾

4. 將以下檔案從 Finder 拖放到 Xcode 的專案導航器中：
   - `FieldConfigurationManager.swift`
   - `AssetFieldConfigurationView.swift`

5. 在彈出的對話框中：
   - ✅ 勾選「Copy items if needed」
   - ✅ 確認「Add to targets」中勾選了 `InvestmentDashboard`
   - 點擊「Finish」

### 方法二：使用 Xcode 選單加入

1. 在 Xcode 中，右鍵點擊左側專案導航器中的 `InvestmentDashboard` 資料夾

2. 選擇「Add Files to "InvestmentDashboard"...」

3. 導航到：
   ```
   /Users/chehungliu/Desktop/superdesign-template拷貝/InvestmentDashboard/InvestmentDashboard/
   ```

4. 選擇以下檔案（按住 Command 鍵可多選）：
   - `FieldConfigurationManager.swift`
   - `AssetFieldConfigurationView.swift`

5. 點擊「Add」

## 驗證是否成功加入

1. 在 Xcode 左側的專案導航器中，應該可以看到這兩個新檔案

2. 點擊檔案，應該可以在右側看到檔案內容

3. 嘗試編譯專案（Command + B），應該沒有錯誤

## 功能說明

### 欄位配置功能已經完成：

1. **動態欄位順序**：資產輸入表單的欄位順序現在是動態的，可以自定義

2. **欄位顯示/隱藏**：可以選擇顯示或隱藏特定欄位

3. **設定按鈕**：在新增資產記錄表單的頂部導航欄，「保存」按鈕左側有一個設定圖示（三條橫線的滑桿圖示）

4. **拖拽排序**：在設定頁面可以拖動欄位以調整順序

5. **持久化保存**：所有設定會自動保存，下次打開 App 時會保持您的設定

### 使用方式：

1. 打開「新增資產記錄」表單
2. 點擊頂部導航欄的設定圖示（滑桿圖示）
3. 在欄位設定頁面：
   - 拖動欄位以調整順序
   - 點擊眼睛圖示以顯示/隱藏欄位
   - 點擊「重設」可恢復預設配置
4. 點擊「完成」保存設定

### 特殊欄位說明：

以下欄位標記為「自動」，表示這些值會自動計算：
- 台股折合
- 台幣折合美金
- 總資產

這些欄位無法編輯，但仍然可以調整顯示順序或隱藏。
