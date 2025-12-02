# 加入新檔案到 Xcode 專案

## 📁 需要加入的 5 個新檔案

請按照以下步驟將這 5 個檔案加入到 Xcode 專案中：

### 檔案清單

1. **FormComponents.swift** - 共用表單組件（FormField, PickerField, PickerSheet）
2. **ImagePicker.swift** - 照片選擇器（相機 + 相簿）
3. **InsuranceOCRManager.swift** - OCR 文字辨識引擎
4. **InsuranceOCREditView.swift** - OCR 結果編輯視圖
5. **AddInsurancePolicyView.swift** - 手動新增保單表單

## 🔧 加入步驟

### 方法：使用 Xcode GUI

1. **開啟專案**
   - 在 Finder 中找到：`InvestmentDashboard/InvestmentDashboard.xcodeproj`
   - 雙擊開啟

2. **加入檔案**
   - 在左側專案導航器中，右鍵點擊 `InvestmentDashboard` 資料夾（藍色圖示）
   - 選擇 **"Add Files to InvestmentDashboard..."**

3. **選擇檔案**
   - 在檔案選擇器中，找到 `InvestmentDashboard/InvestmentDashboard/` 資料夾
   - 按住 Command 鍵，依序選擇上面 5 個檔案：
     * FormComponents.swift
     * ImagePicker.swift
     * InsuranceOCRManager.swift
     * InsuranceOCREditView.swift
     * AddInsurancePolicyView.swift

4. **確認選項**
   - ✅ **Copy items if needed** - 勾選
   - ✅ **Create groups** - 選擇
   - ✅ **Add to targets: InvestmentDashboard** - 勾選

5. **完成**
   - 點擊 **"Add"** 按鈕
   - 在專案導航器中應該能看到這 5 個新檔案

## ✅ 驗證檔案已加入

加入完成後，請確認：

1. **檔案出現在專案導航器中**
   - 左側應該能看到這 5 個 .swift 檔案
   - 檔案應該在 `InvestmentDashboard` 群組內

2. **檔案已加入 target**
   - 點選任一新檔案
   - 在右側 File Inspector 中
   - 確認 **Target Membership** 中 `InvestmentDashboard` 有勾選

3. **編譯測試**
   - 按 **Cmd + B** 編譯專案
   - 應該不會有編譯錯誤

## 🚀 測試功能

編譯成功後，可以測試以下功能：

### 測試照片辨識（OCR）

1. 執行 App
2. 選擇一個客戶
3. 點擊「保單」按鈕
4. 展開「保險明細」表格
5. 點擊 **📷 相機按鈕**
6. 選擇「拍照」或「從相簿選擇」
7. 拍攝或選擇保單照片
8. 等待辨識完成
9. 確認和編輯資料
10. 點擊「儲存」

### 測試手動新增

1. 在保險明細表格中
2. 點擊 **➕ 加號按鈕**
3. 選擇保險種類和公司
4. 填寫其他欄位
5. 點擊「儲存」

## ⚠️ 可能的問題

### 問題 1：編譯錯誤 - "Cannot find type..."

**解決方法**：
- 確認所有 5 個檔案都已加入專案
- 特別是 `FormComponents.swift` 必須加入，否則會找不到 `FormField`、`PickerField`、`PickerSheet`

### 問題 2：編譯錯誤 - "Duplicate definition..."

**解決方法**：
- 這表示有重複定義的組件
- 確認你沒有手動修改過檔案
- 重新從 Finder 確認檔案內容

### 問題 3：執行時找不到檔案

**解決方法**：
- 點選檔案，檢查 **Target Membership**
- 確認 `InvestmentDashboard` 有勾選

## 📝 Console 輸出

功能正常時，Console 會輸出：

### OCR 辨識
```
✅ OCR 文字辨識成功
辨識文字：[辨識的文字內容]
📊 資料完整度：80%
✅ 保單資料已確認：終身壽險
```

### 手動新增
```
✅ 新增保單功能已觸發！客戶：張三
✅ 手動新增保單資料：
  - 保險種類：壽險
  - 保險公司：國泰人壽
  ...
```

## 🎯 下一步

檔案加入並測試成功後，下一步是：

1. **建立 Core Data Entity**
   - 在 `DataModel.xcdatamodeld` 中建立 `InsurancePolicy`
   - 新增 10 個屬性
   - 建立與 `Client` 的關係

2. **實作資料儲存**
   - 修改 `InsurancePolicyView.swift:105` 和 `:158`
   - 修改 `InsuranceOCREditView.swift:290`
   - 修改 `AddInsurancePolicyView.swift:254`

---

**日期**：2025/10/14
**狀態**：檔案準備完成，等待加入 Xcode
