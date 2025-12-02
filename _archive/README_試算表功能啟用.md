# 🔧 保險試算表功能啟用指南

## 📌 當前狀態

✅ **專案已成功編譯**
⚠️ **試算表詳情功能暫時停用**，等待 Core Data Entity 設定完成

## 🎯 需要完成的步驟

### 步驟 1：在 Core Data 中建立 InsuranceCalculatorRow Entity

請參考 `Core_Data_設定步驟.md` 文件，完成以下操作：

1. 開啟 `DataModel.xcdatamodeld`
2. 新增 `InsuranceCalculatorRow` Entity
3. 新增 6 個 Attributes
4. 新增 Relationship 到 `InsuranceCalculator`
5. 修改 `InsuranceCalculator` 新增反向 Relationship

### 步驟 2：還原暫時重命名的檔案

Core Data Entity 建立完成後，執行以下命令：

```bash
cd "/Users/chehungliu/Desktop/superdesign-template拷貝/InvestmentDashboard/InvestmentDashboard"
mv CalculatorTableDetailView.swift.temp CalculatorTableDetailView.swift
mv InsuranceCalculatorRow.swift.temp InsuranceCalculatorRow.swift
```

或在 Finder 中手動將 `.temp` 副檔名移除。

### 步驟 3：取消代碼註解

在以下檔案中，找到標註 `⚠️` 的註解區塊並取消註解：

#### 1. InsuranceCalculatorRow.swift (還原後)

```swift
// 第 34-58 行
// 將整段 extension 從註解中取出
extension InsuranceCalculatorRow {
    ...
}
```

#### 2. InsuranceCalculatorView.swift

```swift
// 第 711-728 行 - FetchRequest
@FetchRequest private var calculatorRows: FetchedResults<InsuranceCalculatorRow>

_calculatorRows = FetchRequest<InsuranceCalculatorRow>(
    sortDescriptors: [NSSortDescriptor(keyPath: \InsuranceCalculatorRow.rowOrder, ascending: true)],
    predicate: NSPredicate(format: "calculator == %@", calculator),
    animation: .default
)

// 第 732-735 行 - 按鈕動作
showingDetailView = true  // 取消這行的註解

// 第 757-759 行 - 顯示筆數
Label("\(calculatorRows.count) 筆", systemImage: "list.number")  // 取消這行的註解

// 第 801-807 行 - Sheet
.sheet(isPresented: $showingDetailView) {
    CalculatorTableDetailView(calculator: calculator, client: client)
        .environment(\.managedObjectContext, viewContext)
}
```

### 步驟 4：重新編譯

```bash
# 方法 1：使用 Xcode
按 Command + B

# 方法 2：使用命令列
cd "/Users/chehungliu/Desktop/superdesign-template拷貝/InvestmentDashboard"
xcodebuild -project InvestmentDashboard.xcodeproj -scheme InvestmentDashboard -destination 'generic/platform=iOS' build
```

## 📁 檔案狀態

### 已加入編譯的檔案

- ✅ `CalculatorRowData.swift` - 試算表資料結構
- ✅ `CalculatorTableParser.swift` - CSV/OCR 解析器
- ✅ `InsuranceCalculatorView.swift` - 試算表列表（部分功能註解）
- ✅ `InsurancePolicyView.swift` - 保單管理（存放功能已實現）

### 暫時排除編譯的檔案

- ⏸️ `CalculatorTableDetailView.swift.temp` - 試算表詳情視圖
- ⏸️ `InsuranceCalculatorRow.swift.temp` - Entity 擴展

## 🧪 測試計劃

完成所有步驟後，請測試以下功能：

### 1. 基本流程測試

1. ✅ 在保險明細填寫保單資料
2. ✅ 點擊「存放」按鈕
3. ✅ 確認試算表已建立
4. ✅ 點擊試算表卡片（應該打開詳情頁面）
5. ✅ 測試「匯入CSV」功能
6. ✅ 測試「匯入照片」功能
7. ✅ 確認表格正確顯示資料

### 2. CSV 匯入測試

準備測試 CSV 檔案：

```csv
保單年度,保險年齡,保單現金價值（解約金）,身故保險金
1,25,0,1000000
2,26,50000,1050000
3,27,100000,1100000
```

### 3. OCR 測試

使用您提供的保險試算表截圖進行測試。

## ❓ 常見問題

### Q: 編譯時還是出現 InsuranceCalculatorRow 錯誤？

A:
1. 確認 Core Data Entity 已正確建立
2. 確認已還原 `.temp` 檔案
3. 清理專案：Product → Clean Build Folder (Shift + Command + K)
4. 重新編譯

### Q: 點擊試算表卡片沒有反應？

A:
1. 確認已取消 InsuranceCalculatorView.swift 中的相關註解
2. 確認 CalculatorTableDetailView.swift 已加入專案
3. 檢查 Console 是否有錯誤訊息

### Q: 匯入 CSV 後沒有顯示資料？

A:
1. 檢查 CSV 格式是否正確（UTF-8 編碼）
2. 確認第一行是標題行
3. 確認每行至少有 4 個欄位
4. 查看 Console 輸出的錯誤訊息

## 📚 相關文件

- `Core_Data_設定步驟.md` - 詳細的 Entity 建立步驟
- `保險試算表功能說明.md` - 完整的功能說明
- `保險功能使用指南.md` - 保險管理功能總覽

## 🎉 完成確認

完成所有步驟後，您應該能夠：

- ✅ 點擊「存放」按鈕建立試算表
- ✅ 看到試算表卡片顯示正確的資訊
- ✅ 點擊卡片進入詳情頁面
- ✅ 使用「匯入CSV」按鈕
- ✅ 使用「匯入照片」按鈕
- ✅ 在表格中查看 4 個欄位的資料
- ✅ 刪除單行資料
- ✅ 資料正確儲存到 Core Data

---

**如有任何問題，請檢查 Console 輸出的錯誤訊息，或參考相關文件。**
