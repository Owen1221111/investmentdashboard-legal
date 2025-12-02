# Core Data 設定步驟 - InsuranceCalculatorRow

## ⚠️ 重要提示

目前專案中有 2 個編譯錯誤，原因是 `InsuranceCalculatorRow` 這個 Entity 還沒有在 Core Data 中建立。

請按照以下步驟在 Xcode 中建立這個 Entity。

## 📋 設定步驟

### 步驟 1：開啟 Core Data 模型

1. 在 Xcode 左側導航欄中找到 `DataModel.xcdatamodeld`
2. 點擊打開，會顯示目前的所有 Entity

### 步驟 2：新增 InsuranceCalculatorRow Entity

1. **點擊底部的「Add Entity」按鈕**（或按 Command + N）
2. 新 Entity 會出現，名稱預設為「Entity」
3. **選中這個新 Entity**，在右側 Inspector 中將名稱改為：`InsuranceCalculatorRow`

### 步驟 3：新增 Attributes（屬性）

選中 `InsuranceCalculatorRow` Entity 後，在下方的 Attributes 區域點擊「+」按鈕，依次新增以下 6 個屬性：

| 順序 | Attribute Name | Type | Optional | Default Value |
|-----|---------------|------|----------|---------------|
| 1 | policyYear | String | ❌ (取消勾選) | - |
| 2 | insuranceAge | String | ❌ (取消勾選) | - |
| 3 | cashValue | String | ❌ (取消勾選) | - |
| 4 | deathBenefit | String | ❌ (取消勾選) | - |
| 5 | rowOrder | Integer 16 | ❌ (取消勾選) | 0 |
| 6 | createdDate | Date | ❌ (取消勾選) | - |

**如何設定**：
- 點擊「+」新增一個 Attribute
- 雙擊名稱進行修改
- 在右側 Inspector 中選擇 Type
- 取消勾選「Optional」（讓欄位變成必填）

### 步驟 4：新增 Relationship（關聯）

在 Relationships 區域點擊「+」按鈕，新增以下關聯：

| Relationship Name | Destination | Type | Inverse | Delete Rule |
|------------------|-------------|------|---------|-------------|
| calculator | InsuranceCalculator | To One | rows | Nullify |

**設定方法**：
1. 新增一個 Relationship，命名為 `calculator`
2. Destination 選擇：`InsuranceCalculator`
3. Type 保持：`To One`
4. Inverse 會自動建議 `rows`（如果沒有，下一步會建立）
5. Delete Rule 選擇：`Nullify`

### 步驟 5：修改 InsuranceCalculator Entity

1. 選中現有的 `InsuranceCalculator` Entity
2. 在 Relationships 區域，應該會自動出現 `rows` 關聯
3. 如果沒有，手動新增：

| Relationship Name | Destination | Type | Inverse | Delete Rule |
|------------------|-------------|------|---------|-------------|
| rows | InsuranceCalculatorRow | To Many | calculator | **Cascade** |

**重要**：Delete Rule 必須設為 **Cascade**，這樣刪除試算表時會自動刪除所有關聯的資料行。

### 步驟 6：設定 Codegen

1. 選中 `InsuranceCalculatorRow` Entity
2. 在右側 Data Model Inspector 中找到「Codegen」
3. 選擇：**Class Definition**
4. Module 選擇：**Current Product Module**

### 步驟 7：編譯專案

1. 按 `Command + B` 編譯專案
2. Xcode 會自動生成 `InsuranceCalculatorRow` 類別
3. 編譯成功後，2 個錯誤應該會消失

### 步驟 8：取消註解相關代碼

編譯成功後，請執行以下操作：

#### 1. InsuranceCalculatorRow.swift

找到第 34-58 行的註解區塊，取消註解：

```swift
// 將這段註解移除：
/*
extension InsuranceCalculatorRow {
    ...
}
*/

// 改為：
extension InsuranceCalculatorRow {
    ...
}
```

#### 2. 重新編譯

再次按 `Command + B`，確認沒有任何錯誤。

## ✅ 驗證設定

完成後，您應該能看到：

1. ✅ `DataModel.xcdatamodeld` 中有 `InsuranceCalculatorRow` Entity
2. ✅ 該 Entity 有 6 個 Attributes
3. ✅ 該 Entity 有 1 個 Relationship 指向 `InsuranceCalculator`
4. ✅ `InsuranceCalculator` 有 1 個 Relationship 指向 `InsuranceCalculatorRow`
5. ✅ 專案可以正常編譯，沒有錯誤

## 📸 參考截圖說明

### Entity 設定應該看起來像這樣：

**InsuranceCalculatorRow**
```
Attributes:
  - policyYear (String)
  - insuranceAge (String)
  - cashValue (String)
  - deathBenefit (String)
  - rowOrder (Integer 16)
  - createdDate (Date)

Relationships:
  - calculator → InsuranceCalculator (To One, inverse: rows)
```

**InsuranceCalculator**
```
Relationships:
  - rows → InsuranceCalculatorRow (To Many, inverse: calculator, Delete Rule: Cascade)
  - client → Client (已存在)
```

## ❓ 常見問題

### Q: 找不到「Add Entity」按鈕？

A: 確認您已經打開 `DataModel.xcdatamodeld` 文件，按鈕在底部工具欄。

### Q: Inverse 找不到 rows？

A: 先完成 InsuranceCalculatorRow 的設定，然後去 InsuranceCalculator 手動新增 rows 關聯。

### Q: 編譯後還是有錯誤？

A:
1. 確認 Codegen 設為 Class Definition
2. 清理專案：Product → Clean Build Folder (Shift + Command + K)
3. 重新編譯：Command + B

### Q: 為什麼使用 String 而不是 Double/Int？

A: 為了保持數據的原始格式，避免精度損失，並且方便支援多種輸入格式（如「1,000,000」）。

## 🎉 完成後

設定完成後，您就可以：

1. ✅ 使用「存放」按鈕建立試算表
2. ✅ 點擊試算表卡片查看詳情
3. ✅ 匯入 CSV 文件
4. ✅ 匯入照片進行 OCR 辨識
5. ✅ 在表格中查看和編輯資料

---

**如有任何問題，請參考「保險試算表功能說明.md」文檔。**
