# 📦 投資群組功能 - Core Data 設置指南

## ⚠️ 重要：請在 Xcode 中完成以下操作

---

## 步驟1：打開 Core Data 模型

1. 在 Xcode 中打開項目
2. 找到 `DataModel.xcdatamodeld` 文件
3. 點擊打開模型編輯器

---

## 步驟2：創建新實體 - InvestmentGroup

### 2.1 添加實體
1. 點擊底部的 **「Add Entity」** 按鈕
2. 將新實體命名為：`InvestmentGroup`

### 2.2 添加屬性（Attributes）

點擊 InvestmentGroup 實體，在右側面板添加以下屬性：

| 屬性名稱 | 類型 | 可選 | 預設值 |
|---------|------|------|--------|
| `id` | UUID | ❌ 必填 | - |
| `name` | String | ❌ 必填 | - |
| `groupType` | String | ❌ 必填 | - |
| `createdDate` | Date | ❌ 必填 | - |
| `orderIndex` | Integer 16 | ❌ 必填 | 0 |

### 2.3 添加關係（Relationships）

在 Relationships 區域添加以下關係：

#### 2.3.1 與 Client 的關係
| 屬性 | 值 |
|------|-----|
| **名稱** | `client` |
| **Destination** | Client |
| **Type** | To One |
| **Delete Rule** | Nullify |
| **Inverse** | `investmentGroups` （需要在 Client 中添加） |

#### 2.3.2 與 USStock 的關係
| 屬性 | 值 |
|------|-----|
| **名稱** | `usStocks` |
| **Destination** | USStock |
| **Type** | To Many |
| **Delete Rule** | Nullify |
| **Inverse** | `groups` （需要在 USStock 中添加） |

#### 2.3.3 與 TWStock 的關係
| 屬性 | 值 |
|------|-----|
| **名稱** | `twStocks` |
| **Destination** | TWStock |
| **Type** | To Many |
| **Delete Rule** | Nullify |
| **Inverse** | `groups` （需要在 TWStock 中添加） |

#### 2.3.4 與 CorporateBond 的關係
| 屬性 | 值 |
|------|-----|
| **名稱** | `bonds` |
| **Destination** | CorporateBond |
| **Type** | To Many |
| **Delete Rule** | Nullify |
| **Inverse** | `groups` （需要在 CorporateBond 中添加） |

#### 2.3.5 與 StructuredProduct 的關係
| 屬性 | 值 |
|------|-----|
| **名稱** | `structuredProducts` |
| **Destination** | StructuredProduct |
| **Type** | To Many |
| **Delete Rule** | Nullify |
| **Inverse** | `groups` （需要在 StructuredProduct 中添加） |

---

## 步驟3：修改現有實體

### 3.1 Client 實體
添加新關係：
- **名稱**：`investmentGroups`
- **Destination**：InvestmentGroup
- **Type**：To Many
- **Delete Rule**：Cascade
- **Inverse**：`client`

### 3.2 USStock 實體
添加新關係：
- **名稱**：`groups`
- **Destination**：InvestmentGroup
- **Type**：To Many
- **Delete Rule**：Nullify
- **Inverse**：`usStocks`

### 3.3 TWStock 實體
添加新關係：
- **名稱**：`groups`
- **Destination**：InvestmentGroup
- **Type**：To Many
- **Delete Rule**：Nullify
- **Inverse**：`twStocks`

### 3.4 CorporateBond 實體
添加新關係：
- **名稱**：`groups`
- **Destination**：InvestmentGroup
- **Type**：To Many
- **Delete Rule**：Nullify
- **Inverse**：`bonds`

### 3.5 StructuredProduct 實體
添加新關係：
- **名稱**：`groups`
- **Destination**：InvestmentGroup
- **Type**：To Many
- **Delete Rule**：Nullify
- **Inverse**：`structuredProducts`

---

## 步驟4：生成 NSManagedObject 類別

1. 選中 `InvestmentGroup` 實體
2. 在右側 **Data Model Inspector** 中找到 **Codegen**
3. 選擇：**Class Definition**（讓 Xcode 自動生成類別）

---

## 步驟5：儲存並重新編譯

1. 按 `Cmd + S` 儲存模型
2. 按 `Cmd + B` 重新編譯項目
3. 確認沒有錯誤

---

## ✅ 完成後的驗證

編譯成功後，您應該能夠：
- 在代碼中使用 `InvestmentGroup` 類別
- 創建、讀取、更新、刪除群組
- 建立群組與投資項目的關聯

---

## 📝 注意事項

1. **iCloud 同步**：新的實體會自動支援 iCloud 同步
2. **資料遷移**：舊用戶的資料會自動遷移（因為新實體不影響舊資料）
3. **備份**：建議先備份項目，以防萬一

---

## 🐛 常見問題

### Q: 編譯時出現「Cannot find type 'InvestmentGroup' in scope」
**A:** 確保 Codegen 設置為 "Class Definition" 並重新編譯

### Q: 關係無法建立
**A:** 檢查 Inverse 關係是否正確設置

### Q: 資料無法儲存
**A:** 確認所有必填屬性都有值，且關係正確連結

---

## 🚀 下一步

完成 Core Data 設置後，我會繼續：
1. 修改 QuickUpdateView 支援群組顯示
2. 添加群組管理入口
3. 測試群組功能

準備好後請告訴我！
