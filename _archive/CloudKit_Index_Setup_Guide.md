# CloudKit 索引設定教學

## 為什麼需要設定 CloudKit 索引？

當你的 app 使用 iCloud 同步資料時，CloudKit 需要知道如何有效地查詢和排序資料。索引可以：
1. **加快查詢速度** - 讓資料查詢更快速
2. **啟用排序功能** - 允許按特定欄位排序
3. **支援查詢條件** - 讓你能夠篩選資料

## 步驟 1: 登入 CloudKit Dashboard

1. 打開瀏覽器，前往 [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. 使用你的 Apple Developer 帳號登入
3. 選擇你的 app（InvestmentDashboard）

## 步驟 2: 選擇環境

CloudKit 有兩個環境：
- **Development** - 開發環境（測試用）
- **Production** - 正式環境（上線後使用）

**重要：開始時請選擇 Development 環境進行測試**

在頁面上方會看到環境選擇器，請選擇 **Development**。

## 步驟 3: 進入 Schema 設定

1. 在左側選單中，點選 **"Schema"**
2. 你會看到所有的 Record Types（資料表）

## 步驟 4: 找到你的 Record Type

在我們的 app 中，主要有這些 Record Types：
- **CD_Client** - 客戶資料
- **CD_MonthlyAsset** - 月度資產
- **CD_CorporateBond** - 公司債

點選你想要新增索引的 Record Type（例如：CD_MonthlyAsset）。

## 步驟 5: 新增索引

### 5.1 找到 Indexes 區塊

在 Record Type 詳細頁面中，向下捲動找到 **"Indexes"** 區塊。

### 5.2 點選 "Add Index"

會出現一個表單讓你設定索引。

### 5.3 設定索引欄位

對於 **CD_MonthlyAsset**，建議設定以下索引：

#### 索引 1: createdDate（排序用）
- **Field Name**: `createdDate`
- **Index Type**: `SORTABLE`
- **Order**: `DESCENDING`（新到舊）或 `ASCENDING`（舊到新）

#### 索引 2: client（查詢用）
- **Field Name**: `CD_client`（這是關聯欄位）
- **Index Type**: `QUERYABLE`

### 5.4 儲存索引

1. 點選 **"Add Index"** 按鈕
2. 確認設定正確
3. 點選 **"Save Changes"** 儲存

## 步驟 6: 為其他 Record Types 設定索引

重複步驟 4-5，為其他 Record Types 設定索引：

### CD_CorporateBond 建議索引：
- `createdDate` - SORTABLE, DESCENDING
- `CD_client` - QUERYABLE

### CD_Client 建議索引：
- `name` - QUERYABLE（如果需要搜尋客戶名稱）
- `createdDate` - SORTABLE, DESCENDING

## 步驟 7: 部署到 Production

當你在 Development 環境測試完成後，需要將 Schema 部署到 Production：

1. 在 CloudKit Dashboard 中，確保你在 **Development** 環境
2. 點選上方的 **"Deploy Schema Changes"**
3. 選擇要部署的變更
4. 確認部署到 **Production**

**警告：部署到 Production 後無法撤銷，請謹慎操作！**

## 步驟 8: 常見索引類型說明

### QUERYABLE
- 用於：需要查詢或篩選的欄位
- 範例：`CD_client`（找出特定客戶的所有記錄）
- FetchRequest 中的 `predicate`

### SORTABLE
- 用於：需要排序的欄位
- 範例：`createdDate`（按日期排序）
- FetchRequest 中的 `sortDescriptors`

### UNIQUE
- 用於：需要唯一值的欄位
- 範例：`email`（確保每個 email 只出現一次）

## 步驟 9: 驗證索引是否生效

1. 在 CloudKit Dashboard 中，切換到 **"Data"** 標籤
2. 選擇你的 Record Type
3. 嘗試使用查詢條件或排序
4. 如果索引正確設定，查詢應該會很快完成

## 步驟 10: 在 Xcode 中測試

1. 清除 app 的資料（重新安裝或清除 iCloud 資料）
2. 重新運行 app
3. 新增一些測試資料
4. 確認排序和查詢功能正常

## 疑難排解

### 問題 1: 索引沒有生效
**解決方法：**
- 等待 5-10 分鐘（CloudKit 需要時間更新索引）
- 確認你在正確的環境（Development 或 Production）
- 重新啟動 app

### 問題 2: 找不到 Record Type
**解決方法：**
- 確認 app 至少運行過一次並新增過資料
- CloudKit 會在第一次儲存資料時自動建立 Record Type
- 檢查是否使用了正確的 Container Identifier

### 問題 3: 無法儲存索引變更
**解決方法：**
- 確認你有該 app 的開發者權限
- 檢查網路連線
- 嘗試重新整理頁面

## 本專案建議的完整索引設定

### CD_MonthlyAsset
```
索引 1:
- Field: createdDate
- Type: SORTABLE
- Order: DESCENDING

索引 2:
- Field: CD_client
- Type: QUERYABLE
```

### CD_CorporateBond
```
索引 1:
- Field: createdDate
- Type: SORTABLE
- Order: DESCENDING

索引 2:
- Field: CD_client
- Type: QUERYABLE
```

### CD_Client
```
索引 1:
- Field: createdDate
- Type: SORTABLE
- Order: DESCENDING

索引 2:
- Field: name
- Type: QUERYABLE
```

## 參考資料

- [CloudKit Dashboard 官方文件](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/Introduction/Introduction.html)
- [CloudKit 索引最佳實踐](https://developer.apple.com/documentation/cloudkit/designing_and_creating_a_cloudkit_database)

---

**注意事項：**
1. 索引會消耗儲存空間，不要為不需要查詢或排序的欄位建立索引
2. Development 和 Production 環境的索引是獨立的
3. 修改索引後，建議進行完整的測試
