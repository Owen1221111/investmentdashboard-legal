# 📚 InvestmentDashboard - 完整功能索引

> **最後更新：** 2025-12-02 - 🎯 **結構型商品編輯功能完成（浮動按鈕庫存區 + 彈性日期支援）**
> **版本：** 1.0.5 (Build 7)
> **Bundle ID：** com.owen.InvestmentDashboard

---

## 🏗️ 四區域架構核心設計

**InvestmentDashboard 的核心設計原則：每個投資項目都由四個區域組成**

每個投資項目（美股、台股、債券、結構型商品、基金、定期定額）都應具備以下四個完整功能區域：

| 區域 | 說明 | 功能 |
|------|------|------|
| **1️⃣ 小卡區** | Dashboard 儀表板卡片 | 快速總覽、一鍵進入庫存 |
| **2️⃣ 表格區** | 詳細資料表格 | 完整明細、排序、搜尋 |
| **3️⃣ 左滑輸入區** | 快速更新介面 | 批量輸入、編輯、更新 |
| **4️⃣ 浮動按鈕庫存區** | 跨客戶庫存管理 | 全局檢視、按商品/客戶切換 |

### 📊 四區域完成度進度表

| 投資項目 | 小卡區 | 表格區 | 左滑輸入區 | 浮動按鈕庫存區 | 完成度 |
|---------|--------|--------|-----------|--------------|---------|
| 💵 **美股** | ✅ | ✅ | ✅ | ✅ | **100%** 🎉 |
| 💹 **台股** | ✅ | ✅ | ✅ | ✅ | **100%** 🎉 |
| 💰 **債券** | ✅ | ✅ | ✅ | ✅ | **100%** 🎉 |
| 🏦 **結構型商品** | ✅ | ✅ | ✅ | ✅ | **100%** 🎉 |
| 📈 **基金** | ✅ | ✅ | ⏳ | ⏳ | **50%** |
| 💸 **定期定額** | ⏳ | ⏳ | ⏳ | ⏳ | **0%** |
| 🏥 **保險** | ✅ | ✅ | ⏳ | ⏳ | **50%** |
| 🏠 **貸款** | ✅ | ✅ | ✅ | ⏳ | **75%** |

**已完成四區域架構的項目（4個）：**
1. ✅ 美股 - 完整四區域架構
2. ✅ 台股 - 完整四區域架構
3. ✅ 債券 - 完整四區域架構（**最新完成** 2025-12-02）
4. ✅ 結構型商品 - 完整四區域架構

**下一個優先項目：** 定期定額（需要建立完整的四區域架構）

---

## ⚠️ 重要：文件維護提醒

> **📝 當您新增、修改或刪除功能時，請務必更新此主索引！**
>
> **需要更新的情況：**
> - ✅ 新增了新功能或頁面 → 在對應章節加入說明
> - ✅ 修改了檔案名稱或位置 → 更新檔案路徑
> - ✅ 刪除了功能 → 從索引中移除
> - ✅ 更新版本號 → 修改上方的版本資訊
> - ✅ 新增了文件 → 在相關章節加入連結
>
> **更新方式：**
> 1. 告訴 Claude：「我新增了 XXX 功能，請更新主索引」
> 2. Claude 會自動更新此文件
>
> **保持索引最新 = 未來維護更輕鬆！** 🎯

---

## 🎯 快速導航

| 類別 | 說明 | 文件連結 |
|------|------|----------|
| 📋 **待辦事項** | 未完成功能清單 | [跳轉](#待辦事項) |
| 📱 **核心功能** | App 主要功能說明 | [跳轉](#核心功能) |
| 🔧 **開發指南** | 技術實作與維護 | [跳轉](#開發指南) |
| 🚀 **上架部署** | App Store 相關 | [跳轉](#上架部署) |
| 📖 **用戶文件** | 隱私政策、使用條款 | [跳轉](#用戶文件) |
| 🗂️ **檔案結構** | 專案檔案清單 | [跳轉](#檔案結構) |
| 📊 **資料流與公式** | 資料同步機制、計算公式 | [資料流](📊_資料串流順序.md) \| [公式](📐_計算公式總覽.md) |

---

## 📋 待辦事項

### 🔄 投資項目多幣別折合美金功能

**優先級：** 🔴 高

**目標：** 實現投資項目（公司債、結構型商品、基金、定期定額）的多幣別支援和折合美金計算

**涵蓋範圍：**
1. **表格區（MonthlyAssetTableView）**
   - 在合計行顯示非美幣別的匯率
   - 顯示各幣別折合美金小計

2. **小卡區（Dashboard 小卡片）**
   - 公司債小卡：顯示非美幣別匯率
   - 結構型商品小卡：顯示非美幣別匯率
   - 點擊進入庫存時顯示完整匯率資訊

3. **左滑輸入區（QuickUpdateView）**
   - 投資項目輸入時自動計算折合美金
   - 支援多幣別投資項目的匯率轉換
   - 保存時只存美金總額（不存個別幣別明細）

4. **浮動按鈕庫存區（Inventory Views）**
   - CorporateBondsInventoryView：已完成 ✅
   - RegularInvestmentInventoryView（結構型商品）：待實作 ⏳
   - 其他庫存視圖：待評估 ⏳

**技術需求：**

**階段一：匯率更新智能化** ✅
- [x] 實現幣別自動辨識（掃描所有投資項目）
- [x] 只更新當前客戶使用的幣別（提升速度）

**階段二：公司債多幣別完整支援** ✅
- [x] CoreData CorporateBond 新增 exchangeRate、convertedToUSD 欄位
- [x] 公司債明細表新增匯率、折合美金欄位
- [x] 債券小卡顯示折合美金金額（編輯畫面：美金在上，原幣別+匯率在下）
- [x] 左滑輸入區債券項目顯示折合美金優先、幣別+金額在副標題
- [x] 左滑輸入區債券點擊可編輯（引用債券小卡編輯畫面）
- [x] 債券總資產計算使用折合美金

**階段三：結構型商品完整整合** ✅

*3.1 新增流程改善與多幣別支援* ✅
- [x] 左滑輸入區第一步：當前客戶更明顯且置頂（淺藍色背景標示）
- [x] 左滑輸入區第二步：金額上方新增幣別下拉選單（11種幣別）
- [x] 左滑輸入區第三步：PUT 上方新增 KO% 欄位
- [x] CoreData StructuredProduct 新增 currency、koPercentage 欄位
- [x] 結構型明細表新增 KO% 欄位（KO、PUT、KI 順序）
- [x] 結構型明細表新增「折合美金」欄位（含合計）
- [x] 結構型明細表新增合計行（交易金額總和 + 折合美金總和）
- [x] 浮動按鈕庫存：KO 顯示在 PUT 左邊
- [x] 左滑輸入區結構型商品統一顯示折合美金
- [x] InvestmentGroupRowView 群組內結構型商品使用折合美金計算

*3.2 新增小卡區功能* ✅
- [x] 在美股/台股/債券小卡左滑第二頁新增結構型小卡
- [x] 結構型小卡點進去顯示庫存（風格同美股/台股/債券）
- [x] 結構型小卡支援編輯功能（引用浮動按鈕編輯畫面）

**階段四：其他投資項目**

*4.1 定期定額多幣別支援* ✅
- [x] RegularInvestmentInventoryView 增加匯率變數
- [x] RegularInvestmentInventoryView 新增折合美金計算函數
- [x] 總市值、總成本使用折合美金計算
- [x] QuickUpdateView 新增定期定額 FetchRequest
- [x] QuickUpdateView 新增計算定期定額折合美金總額函數
- [x] 左滑輸入區定期定額卡片顯示折合美金總額
- [x] 總資產計算包含定期定額折合美金

*4.2 基金與保險多幣別支援* ⏳
- [ ] 基金多幣別支援（暫不處理）
- [ ] 保險多幣別支援

**資料流設計：**
```
投資項目庫存（詳細幣別資訊）
    ↓
QuickUpdateView（計算折合美金總額）
    ↓
MonthlyAsset（只儲存美金總額）
    ↓
表格區/小卡區（顯示時從庫存取得幣別資訊 + 匯率）
```

**參考文件：**
- 📊 匯率更新機制.md
- 📊 資料串流順序.md
- 📐 計算公式總覽.md

---

## 🔧 最近更新

### 🎯 結構型商品批量出場功能 (2025-12-02 - 最新)

**影響範圍：** FloatingMenuButton.swift (CrossClientStructuredProductView, 主選單)

**更新內容：**

#### ✅ 三種出場入口

**1. 浮動按鈕主選單「出場」按鈕 (lines 48-57)**
- **位置：** 浮動按鈕展開後，「新增」和「庫存」之間
- **外觀：** 子選單按鈕，圖示 `arrow.right.circle`
- **功能：** 點擊後直接打開庫存畫面，方便快速進入出場流程
- **適用：** 結構型、美股、台股、公司債

**2. 按商品模式出場按鈕 (lines 360-374)**
- **位置：** 「按商品模式」section header 的金額總和右側
- **外觀：** 橘色「出場」按鈕
- **功能：** 點擊後可將同一商品代號下的所有客戶資料批量移至已出場區域

**3. 按客戶模式出場按鈕 (lines 323-338)**
- **位置：** 「按客戶模式」section header 的筆數右側
- **外觀：** 橘色「出場」按鈕
- **功能：** 點擊後可將該客戶的所有商品批量移至已出場區域
- **應用場景：** 左滑輸入區使用此模式

**4. 優化的出場流程**

**步驟 1：選擇出場分類 - 智慧年份生成 (lines 532-550, 1122-1181)**
- **自動生成 5 個年份選項：**
  - 11-12 月：顯示當前年到未來 4 年（例如：2025, 2026, 2027, 2028, 2029）
  - 1-10 月：顯示上一年到未來 3 年（例如：2024, 2025, 2026, 2027, 2028）
- **客戶狀態標註：** 每個年份顯示「全部客戶已有」、「全部客戶新增」或「X客戶有, Y客戶新增」
- **自定義分類：** 提供「新增分類（自定義）」選項
- **取消功能：** 可隨時取消操作

**步驟 2：填寫出場詳細資料 (lines 573-663)**
```swift
NavigationView -> Form {
  Section: 出場資訊
    - 商品代碼
    - 出場客戶數
    - 出場分類

  Section: 出場日期
    - DatePicker（選擇出場日）

  Section: 持有月數
    - TextField（數字輸入）
    - ⚠️ Footer 提醒：「請注意：這裡輸入的是月數，不是天數」

  Section: 實際收益%
    - TextField（數字輸入）
    - 💡 建議收益計算顯示

  Section: 實質收益預覽
    - 每位客戶的交易金額
    - 每位客戶的實質收益（自動計算）
}
```

**3. 智慧計算與提示**

**建議收益計算 (lines 666-680)**
```swift
建議收益% = 月利率 × 持有月數
```
- **即時顯示：** 當用戶輸入持有月數後，自動計算建議收益
- **提示格式：** "💡 建議收益：X.XX%（月利率 X% × N 個月）"
- **數據來源：** 從商品的 monthlyRate 欄位提取

**實質收益計算 (lines 683-707)**
```swift
實質收益 = 交易金額 × 實際收益% ÷ 100
```
- **即時預覽：** 為每位客戶計算並顯示實質收益
- **格式化顯示：** 使用千分位格式化金額
- **列表呈現：** 客戶名稱 | 交易金額 | 實質收益

**4. 批量複製機制 (lines 1089-1162)**

**⭐️ 資料保留策略：**
- **不刪除進行中商品：** 只複製資料到已出場區域，保留原始進行中記錄
- **完整欄位複製：** 複製所有進行中的欄位資料到已出場記錄
- **新增出場資料：** 填入用戶輸入的出場日期、持有月數、實際收益%、實質收益

**執行流程：**
```swift
for each product in selectedProductCode {
  創建 exitedProduct (isExited = true)
  複製所有進行中欄位 → exitedProduct
  填入出場資料：
    - exitDate
    - holdingMonths
    - actualReturn
    - realProfit (計算值)
  保存到 CoreData
  // ⭐️ 不執行 delete(product)
}
```

**5. 表單驗證與用戶體驗**
- **確認按鈕禁用條件：** 持有月數或實際收益%為空時禁用
- **即時預覽：** 輸入實際收益%時立即顯示每位客戶的實質收益
- **取消功能：** 任一步驟可取消操作
- **自動重置：** 確認出場後自動重置表單狀態

**技術優勢：**
- 統一出場流程，減少重複操作
- 智慧計算輔助，降低錯誤率
- 資料保留策略，避免誤刪
- 即時預覽機制，提升確認準確度

---

### 🎯 結構型商品統一庫存介面 (2025-12-02)

**影響範圍：** CustomerDetailView.swift, QuickUpdateView.swift, FloatingMenuButton.swift (CrossClientStructuredProductView)

**更新內容：**

#### ✅ 統一庫存介面整合

**1. 小卡區統一使用 CrossClientStructuredProductView (CustomerDetailView.swift: line 256-259)**
- **修改前：** 點擊小卡打開 StructuredProductsInventoryView
- **修改後：** 點擊小卡打開 CrossClientStructuredProductView（傳入 client 參數）
- **優勢：** 與左滑區、浮動按鈕區使用相同介面，統一用戶體驗

**2. 左滑輸入區移除庫存按鈕 (QuickUpdateView.swift: lines 2053-2069 刪除)**
- **修改前：** 結構型商品區域有獨立的「庫存」按鈕
- **修改後：** 點擊商品項目直接打開 CrossClientStructuredProductView
- **操作流程：**
  - 左滑輸入區展開結構型商品卡片
  - 顯示商品列表（SmallCard）
  - 點擊任一商品
  - 直接打開 CrossClientStructuredProductView（客戶篩選模式）

**3. CrossClientStructuredProductView UI 優化**
- **客戶列表區統一藍色背景** (lines 414-453)
  - 整個客戶列表區域統一使用 `Color.blue.opacity(0.05)` 背景
  - 區分商品資訊區（白色背景）和客戶列表區（藍色背景）
  - 更清晰的視覺層次
- **交易金額總和顯示** (lines 315-327)
  - 「按商品模式」表頭顯示：`商品代碼 | X筆 $XXX,XXX`
  - 自動計算該商品代碼下所有客戶的交易金額總和
  - 使用千分位格式化
- **月領息自動計算** (lines 577-589)
  - 公式：月領息 = 交易金額 × 月利率 / 100
  - 即時計算並顯示
  - 使用千分位格式化

**統一入口點：**
```
儀表板小卡 → CrossClientStructuredProductView(client: client)
左滑輸入區商品項目 → CrossClientStructuredProductView(client: client)
浮動按鈕 → CrossClientStructuredProductView(client: nil)
```

**一致的用戶體驗：**
- 相同的 UI 佈局和操作邏輯
- 統一的「按商品/按客戶」切換功能
- 統一的編輯介面
- 減少維護成本，單一來源的真實

---

### 🎯 結構型商品編輯功能完成 (2025-12-02)

**影響範圍：** FloatingMenuButton.swift (BatchAddStructuredProductView, CrossClientStructuredProductView), ContentView.swift

**更新內容：**

#### ✅ 浮動按鈕庫存區編輯功能

**1. 結構型商品編輯模式 (BatchAddStructuredProductView)**
- **init 中預填資料** (lines 1454-1519)
  - 添加 `editingProduct: StructuredProduct?` 參數支援編輯模式
  - 編輯模式直接跳到步驟 4「輸入詳細資料」
  - 使用 `_variableName = State(initialValue: value)` 模式預填所有欄位
  - 支援欄位：基本資訊、利率參數、標的資訊、價格、日期、交易金額
- **save 邏輯更新** (lines 2115-2146)
  - `saveData()` 區分新增/編輯模式
  - `createProduct()` 創建新商品
  - `updateProduct()` 更新現有商品
  - `updateProductFields()` 統一更新欄位邏輯
  - 編輯模式保留原有的距離出場數據

**2. 庫存區可點擊編輯 (CrossClientStructuredProductView)**
- **按客戶模式** (lines 304-308)
  - 產品行可點擊,開啟編輯介面
- **按商品模式 - 空白代號** (lines 326-329)
  - 個別產品行可點擊編輯
- **按商品模式 - 客戶列表** (lines 416-453)
  - 客戶列表中每筆資料可點擊編輯
  - 點擊後開啟該筆資料的編輯介面
- **Sheet 呈現** (lines 476-479)
  - 使用 `.sheet(item: $editingProduct)` 呈現編輯介面
  - 自動傳入 CoreData context

#### ✅ 彈性日期格式支援

**3. 多格式日期解析 (parseFlexibleDate)**
- **靜態輔助函數** (lines 2258-2305)
  - 支援格式：
    - `yyyy-MM-dd` (標準格式)
    - `M/d` 或 `MM/dd` (無年份,自動補當年)
    - `yyyy/MM/dd`
    - `M/d/yyyy`
  - 解決表格區只輸入 "11/2" 無法正確載入的問題
  - 在 init 中調用 `Self.parseFlexibleDate()` 解析日期

#### ✅ 客戶區域視覺優化

**4. 按商品模式客戶列表改善** (lines 414-453)
- **整體區塊設計**
  - 使用 VStack 包裹所有客戶
  - 統一淡藍色背景 `Color.blue.opacity(0.05)`
  - 圓角設計 `cornerRadius(8)`
- **分隔線**
  - 客戶之間使用 Divider 分隔
  - 最後一個客戶不顯示分隔線
- **鉛筆圖示**
  - 放大至 13pt (原 10pt)
  - 顏色加深至 `0.7` (原 `0.6`)
  - 提示用戶可編輯

#### ✅ ContentView 編譯器優化

**5. 修復編譯器超時** (ContentView.swift lines 69-119)
- body 使用中間變數分解 modifier 鏈
- `step1`, `step2`, `step3` 逐步套用 modifier
- 避免 Swift 編譯器 type-checking 超時

**技術實作：**

**編輯流程：**
```swift
用戶點擊庫存中的結構型商品
    ↓
editingProduct = product (設置狀態)
    ↓
sheet 呈現 BatchAddStructuredProductView
    ↓
init 中預填所有資料 (使用 _state = State(initialValue:))
    ↓
跳到步驟4 顯示完整表單
    ↓
用戶修改後點擊儲存
    ↓
updateProduct() 更新現有記錄
    ↓
CoreData 保存變更
```

**日期解析優先順序：**
1. 嘗試標準格式 (yyyy-MM-dd)
2. 嘗試短格式 (M/d, MM/dd) → 自動補當年
3. 嘗試其他變體格式
4. 解析失敗返回 nil

**視覺效果：**
- 客戶區域現為統一卡片，不再是分散的單行
- 鉛筆圖示更明顯，提升可發現性
- 整體視覺更整齊、專業

**最後更新：** 2025-12-02 - 結構型商品編輯功能全面完成

---

### 🎯 債券浮動按鈕完成 (2025-12-02)

**影響範圍：** FloatingMenuButton.swift、ContentView.swift

**更新內容：**

#### ✅ 債券四區域整合完成 - 達到 100%

債券現在擁有完整的四個區域：

**1. 小卡區** ✅
- CustomerDetailView.swift 儀表板債券卡片
- 顯示現值、報酬率
- 支援批次更新/逐一更新兩種模式

**2. 表格區** ✅
- CorporateBondsDetailView.swift 完整明細表
- 顯示債券名稱、幣別、票面利率、現值、已領利息、報酬率等
- 支援多幣別（11種貨幣）
- 合計行自動計算

**3. 左滑輸入區** ✅
- QuickUpdateView.swift 債券卡片
- 支援批次輸入和逐一更新
- 群組管理功能

**4. 浮動按鈕庫存區** ✅ **新增**
- FloatingMenuButton 加入「債券」主選單按鈕
- 子選單：新增 / 庫存
- **新增功能：** 批量新增債券 (BatchAddCorporateBondView) - **最新更新 2025-12-02**
- **庫存功能：** 打開 CrossClientCorporateBondView 跨客戶債券庫存

**技術實作：**

**FloatingMenuButton.swift 修改：**
```swift
// 加入債券參數
let onCorporateBondAdd: () -> Void
let onCorporateBondInventory: () -> Void

// 主選單加入債券按鈕
MainMenuButton(title: "債券", icon: "doc.text.fill") {
    selectedCategory = "bond"
}

// 子選單加入債券 case
case "bond": onCorporateBondAdd()
case "bond": onCorporateBondInventory()
```

**CrossClientCorporateBondView（新增）：**
- 按債券名稱分組顯示所有客戶的債券
- 顯示：客戶名稱、幣別標籤、票面利率、現值、報酬率
- 支援搜尋功能
- 多幣別顯示（非 USD 幣別顯示橙色標籤）

**ContentView.swift 修改：**
```swift
// 加入狀態變數
@State private var showingCrossClientCorporateBond = false
@State private var showingBatchAddCorporateBond = false

// 加入 sheet 視圖
.sheet(isPresented: $showingCrossClientCorporateBond) {
    CrossClientCorporateBondView()
}
.sheet(isPresented: $showingBatchAddCorporateBond) {
    BatchAddCorporateBondView()  // 批量新增債券 (2025-12-02 更新)
}
```

**債券批量新增流程：**
1. **步驟 1/3：** 選擇客戶（多選）
2. **步驟 2/3：** 為各客戶輸入金額（可選，可留空在步驟 3 統一輸入）
3. **步驟 3/3：** 填寫債券詳細資訊
   - 基本資訊：債券名稱、幣別（11 種貨幣可選）
   - 票面與殖利率：票面利率、殖利率
   - 持倉資訊：認購價格、持有面額、前手利息、當前市值
   - 配息資訊：已收利息、配息月份
4. 自動計算並儲存：
   - 報酬率 = ((當前市值 - 成本) / 成本) × 100
   - 成本 = (認購價格 / 100) × 持有面額 + 前手利息
   - 為每個選中的客戶建立獨立的 CorporateBond 記錄

**最後更新：** 2025-12-02 - 實現債券批量新增功能，與美股/台股/結構型商品保持一致的批量操作模式
```

#### 🎯 債券達成 100% 完成度

債券現在是第 4 個達到 100% 四區域完成的投資項目：
1. ✅ 美股 - 100%
2. ✅ 台股 - 100%
3. ✅ 結構型商品 - 100%
4. ✅ **債券 - 100%**（新完成）

---

### 📊 結構型商品小卡區完成 (2025-12-02)

**影響範圍：** CustomerDetailView.swift、StructuredProductsInventoryView.swift（新增）、QuickUpdateView.swift

**更新內容：**

#### ✅ 結構型商品四區域整合完成

結構型商品現在和美股、台股、債券一樣，擁有完整的四個區域：

**1. 小卡區（CustomerDetailView.swift）** ✅ 新增
- 在美股、台股、債券小卡的左滑第二頁（page 1）新增結構型商品小卡
- 顯示內容：
  - 總成本（折合美金總額）
  - 平均利率（所有商品的平均年化利率）
  - 商品數量（未退出的商品數量）
- 點擊小卡打開結構型商品庫存視圖
- 整合位置：
  - 美股卡片：3 頁（0: 美股, 1: 結構型商品, 2: 基金）
  - 台股卡片：4 頁（0: 台股, 1: 結構型商品, 2: 定期定額, 3: 基金）
  - 債券卡片：4 頁（0: 債券, 1: 結構型商品, 2: 定期定額, 3: 基金）

**2. 表格區（StructuredProductsDetailView.swift）** ✅ 已存在
- 完整的結構型商品明細表
- 顯示所有商品資訊：產品代碼、標的、KO/PUT/KI、利率、金額、折合美金等
- 合計行顯示總額和總利率

**3. 左滑輸入區（QuickUpdateView.swift）** ✅ 已存在（2025-12-02 更新）
- 快速查看結構型商品列表
- **點擊商品項目**直接打開 CrossClientStructuredProductView（客戶篩選模式）
- 顯示折合美金總額
- **更新：** 移除「庫存」按鈕，改為點擊商品項目直接進入

**4. 浮動按鈕庫存區（FloatingMenuButton.swift）** ✅ 已存在
- 從浮動按鈕新增、編輯結構型商品
- 支援多客戶管理

**3. 結構型商品庫存視圖（StructuredProductsInventoryView.swift）** ✅ 新增
- 專屬的結構型商品庫存管理介面
- **標題統計區：**
  - 第一行：總成本、年化利率
  - 第二行：總現值、商品數量
  - 所有金額使用折合美金計算
  - 利率顯示平均值
- **商品列表：**
  - 展開式設計，點擊商品卡片展開編輯表單
  - 摺疊時顯示：產品代碼、標的、利率、交易金額
  - 展開後可編輯所有欄位
  - 支援刪除商品
- **計算邏輯：**
  - 總成本 = 所有商品的交易金額總和（折合美金）
  - 平均利率 = 所有商品利率的平均值
  - 總現值 = 當前價格計算（多標的加權平均）
- **自動同步：**
  - 編輯後自動保存到 CoreData
  - 自動更新小卡顯示
  - 自動刷新表格區

#### 🎯 四區域架構完成

至此，結構型商品已經擁有完整的四區域架構：
1. ✅ 小卡區：儀表板左滑頁面快速查看
2. ✅ 表格區：完整明細表格
3. ✅ 左滑輸入區：快速更新介面
4. ✅ 浮動按鈕庫存區：完整庫存管理

**資料流：**
```
浮動按鈕/左滑區 新增/編輯
    ↓
CoreData StructuredProduct 實體
    ↓
三處同步顯示：
  - 小卡區（即時計算總額和平均利率）
  - 表格區（完整明細）
  - 左滑區（摘要列表）
```

---

### 📊 表格合計行完成、結構型商品顯示優化 (2025-12-02)

**影響範圍：** ProfitLossTableView.swift、StructuredProductsDetailView.swift、TWStockDetailView.swift、FloatingMenuButton.swift

**更新內容：**

#### ✅ 損益表新增合計行功能

**1. 合計行顯示（ProfitLossTableView.swift:268-336）**
- 在損益表底部新增合計行
- 顯示黃色背景（0.15 透明度）突顯
- 橘色邊框（上下兩條）分隔資料行與合計行
- 自動計算並顯示以下欄位總和：
  - 交易金額：所有交易金額的總和
  - 投入成本：所有投入成本的總和
  - 損益：所有損益的總和（正數綠色、負數紅色）
  - 報酬率：自動計算 (總損益 / 總投入成本) × 100（正數綠色、負數紅色）
- 第一欄顯示「合計」文字

**2. 計算函數新增（ProfitLossTableView.swift:487-507）**
- `calculateTotalTransactionAmount()` - 計算交易金額總和
- `calculateTotalInvestedCost()` - 計算投入成本總和
- `calculateTotalProfitLoss()` - 計算損益總和
- 所有數字格式化，加上千分位符號
- 即時更新，新增/編輯/刪除資料時自動重新計算

#### ✅ 表格合計行功能完整總結

至此，所有需要合計行的表格都已完成：

**1. 結構型已出場表（StructuredProductsDetailView.swift）** ✅
- 合計欄位：實質收益
- 公式：實際報酬率 × 交易金額
- 顏色編碼：淺黃色背景

**2. 台股明細表（TWStockDetailView.swift）** ✅
- 合計欄位：成本、市值、損益、報酬率
- 報酬率公式：(總損益 / 總成本) × 100
- 顏色編碼：損益和報酬率（綠色正數/紅色負數）

**3. 損益表（ProfitLossTableView.swift）** ✅ 新增
- 合計欄位：交易金額、投入成本、損益、報酬率
- 報酬率公式：(總損益 / 總投入成本) × 100
- 顏色編碼：損益和報酬率（綠色正數/紅色負數）

#### ✅ 結構型商品顯示格式優化

**1. 標的顯示改為上下排列（FloatingMenuButton.swift:322-330, 469-477）**
- **修改前：** 標的名稱和距離出場%左右並排（HStack）
- **修改後：** 標的名稱在上、百分比在下（VStack）
- 間距設為 1，保持緊湊
- 應用於兩個位置：
  - 按商品分組顯示區域
  - 個別商品行顯示
- 提升閱讀性，讓每個標的資訊更清晰

**2. KO、PUT、KI 排列順序調整（FloatingMenuButton.swift:364-391, 525-552）**
- **修改前：** KO - PUT - (空白) - KI（KI 被推到最右側）
- **修改後：** KO - PUT - KI - (空白)（三者緊密排列）
- KI 緊跟在 PUT 右邊，間距統一為 8 點
- 視覺更整齊，資訊群組更明確
- 應用於所有結構型商品庫存顯示區域

#### 🎯 使用體驗提升

**表格合計行：**
- 一目了然的總額統計
- 即時計算，無需手動加總
- 顏色編碼快速識別盈虧狀況
- 統一的視覺風格（黃色背景 + 橘色邊框）

**結構型商品顯示：**
- 標的資訊更清晰（垂直排列）
- KO/PUT/KI 位置關係更合理
- 整體版面更整潔易讀

---

### 🎯 債券批次輸入功能與模式同步完成 (2025-12-01 晚)

**影響範圍：** QuickUpdateView.swift、CorporateBondsInventoryView.swift、CustomerDetailView.swift

**更新內容：**

#### ✅ 債券編輯模式跨視圖同步

**1. 模式同步機制（三個視圖）**
- QuickUpdateView.swift（左滑輸入區）
- CorporateBondsInventoryView.swift（債券小卡）
- CustomerDetailView.swift（儀表板）
- 使用 UserDefaults + NotificationCenter 實現即時同步
- 每個客戶有獨立的模式設定
- 切換模式時，其他視圖立即更新

**2. 預設改為逐一更新模式**
- 預設值從 `batchUpdate` 改為 `individualUpdate`
- 符合大多數使用者的操作習慣

**3. 模式切換器優化**
- 在左滑輸入區的債券展開內容中添加切換器
- 批次更新模式警語：「直接輸入總額和總利息」
- 逐一更新模式警語：「點選債券可更新現值和已領利息」

**4. 債券卡片縮回自動儲存**
- 批次更新模式下，輸入完成後縮回債券卡片自動儲存
- QuickUpdateView.swift:2641-2654 toggleSection 函數

#### ✅ 債券批次輸入功能

**1. 新增批次輸入畫面（QuickUpdateView.swift:2211-2255）**
- 一次顯示所有債券
- 每個債券有兩個輸入框（現值、已領利息）
- 不需要展開，一目了然
- 自動儲存到 CoreData

**2. 新增 BondBatchInputRow 組件（QuickUpdateView.swift:4346-4405）**
- 簡潔的輸入介面
- 顯示債券名稱和幣別
- 現值和已領利息輸入框
- 自動同步到 CoreData

**3. 修改債券列表點擊行為**
- 點擊債券列表中的任一債券
- 打開批次輸入畫面（而非單個編輯）
- 可以一次更新所有債券

**4. 移除新增群組按鈕**
- 簡化債券展開內容的介面
- 直接顯示群組列表和債券列表

#### 🎯 使用流程

**逐一更新模式：**
1. 展開債券卡片
2. 看到切換器和提示訊息
3. 點擊任一債券
4. 彈出批次輸入畫面，一次看到所有債券
5. 輸入現值和已領利息
6. 點擊「完成」自動儲存

**批次更新模式：**
1. 展開債券卡片
2. 切換到「更新總額、總利息」
3. 直接輸入總現值和總已領利息
4. 縮回債券卡片自動儲存

**模式同步：**
- 在債券小卡、左滑輸入區、儀表板任一處切換模式
- 其他兩處立即同步
- 每個客戶記住自己的偏好設定

---

### 💱 結構型商品與定期定額多幣別整合完成 (2025-12-01)

**影響範圍：** StructuredProductsDetailView.swift、QuickUpdateView.swift、InvestmentGroupRowView.swift、RegularInvestmentInventoryView.swift

**更新內容：**

#### ✅ 結構型商品多幣別完整支援

**1. StructuredProductsDetailView.swift 折合美金功能**
- 新增匯率 @AppStorage 變數（lines 41-51）
- headers 數組增加「折合美金」欄位（line 90）
- 新增 calculateConvertedToUSD 函數計算折合美金（lines 1698-1736）
- 新增 getTotalConvertedToUSD 函數計算總和（lines 1443-1463）
- 合計行增加「折合美金」總計顯示（綠色底線）

**2. QuickUpdateView.swift 統一顯示邏輯**
- 結構型商品 SmallCard 統一顯示折合美金（lines 1606-1626）
- subtitle 僅顯示利率，不顯示原幣別金額

**3. InvestmentGroupRowView.swift 群組內商品計算**
- 新增匯率 @AppStorage 變數（lines 19-29）
- 新增 calculateStructuredProductConvertedToUSD 函數（lines 340-379）
- calculateGroupTotal 和 itemValue 使用折合美金（lines 163-164, 310）

#### ✅ 定期定額多幣別完整支援

**1. RegularInvestmentInventoryView.swift 折合美金計算**
- 新增匯率 @AppStorage 變數（lines 20-30）
- 新增 calculateConvertedToUSD 函數（lines 440-471）
- getTotalMarketValue 和 getTotalCost 使用折合美金（lines 335-347）

**2. QuickUpdateView.swift 定期定額整合**
- 新增 regularInvestments FetchRequest（lines 35-36, 159-163）
- 新增 calculateRegularInvestmentTotal 函數（lines 1721-1756）
- 定期定額卡片顯示折合美金總額（line 610）
- 總資產計算包含定期定額折合美金（line 414）

---

### 💱 現金多外幣功能完成與匯率更新機制優化 (2025-11-30)

**影響範圍：** QuickUpdateView.swift、ExchangeRateService.swift、CorporateBondsInventoryView.swift

**更新內容：**

#### ✅ 完成現金多外幣功能

**1. 匯率變量改用 @AppStorage 實現跨視圖同步（QuickUpdateView.swift:75, 93-101）**
- 將匯率變量從 `@State` 改為 `@AppStorage`
- 確保 QuickUpdateView、債券庫存視圖等所有視圖都能同步看到最新匯率
- 支援 10 種貨幣的匯率同步

**2. 修復折合美金自動更新問題（QuickUpdateView.swift:726, 868）**
- 添加 `.id()` modifier 強制視圖在匯率或金額改變時重新渲染
- 台幣折合美金：`.id("\(tempTWDCash)-\(tempExchangeRate)")`
- 其他外幣折合美金：`.id("\(getCurrencyValue(currency))-\(getCurrencyRate(currency))")`
- 解決匯率更新後折合美金沒有自動重新計算的問題

**3. 債券庫存視圖顯示匯率（CorporateBondsInventoryView.swift:603-647）**
- 添加 @AppStorage 讀取所有幣別匯率
- 為非美幣別債券顯示匯率標籤（橙色標籤，格式：@ 32.5000）
- 實現匯率資訊的實時同步顯示

**4. 優化匯率更新策略（ExchangeRateService.swift:28-65）**
- 改為混合使用台灣銀行 API 和 ExchangeRate-API
- ExchangeRate-API 獲取所有貨幣匯率（10 種貨幣）
- 台灣銀行 API 覆蓋台幣匯率（使用官方數據，更準確）
- 完整的三層備援機制
- 資料來源清楚標示：「ExchangeRate-API + 台灣銀行」

**功能特點：**
- ✅ 支援 10 種貨幣（TWD, EUR, JPY, GBP, CNY, AUD, CAD, CHF, HKD, SGD）
- ✅ 雙 API 備援機制（台灣銀行 + ExchangeRate-API）
- ✅ 匯率更新後所有折合美金自動重新計算
- ✅ 跨視圖匯率同步（QuickUpdateView、庫存視圖等）
- ✅ 工作日顯示機制（週末顯示上週五匯率日期）
- ✅ 完整的資料流：匯率更新 → 折合美金計算 → 保存到月度資產

**參考文件：** 📊_匯率更新機制.md

---

### 💱 多幣別完整整合與資產配置顯示優化 (2025-11-30)

**影響範圍：** QuickUpdateView.swift、MonthlyAssetDetailView.swift、CustomerDetailView.swift、AddMonthlyDataView.swift

**更新內容：**

這次更新修復了多幣別功能的所有關鍵 bug，並優化了儀表板資產配置顯示邏輯。

---

#### 🐛 Bug 修復

**1. 總資產計算遺漏多幣別折合美金（QuickUpdateView.swift:1976-1993）**

**問題描述：**
- 用戶新增 AUD $10,000 @ 0.5 匯率 = $20,000 USD
- 儲存後總資產顯示 $191,541.98（應為 $591,541.98）
- 遺漏約 $400,000 來自多幣別的折合美金

**根本原因：**
`saveToMonthlyAsset()` 函數計算總資產時，只包含了基本資產（USD、TWD、美股、台股等），遺漏了所有 9 種多幣別的折合美金。

**修復方案：**
在總資產計算中加入所有多幣別折合美金：
```swift
// 計算多幣別折合美金
let eurToUsdValue = Double(calculateCurrencyToUsd(currency: "EUR")) ?? 0
let jpyToUsdValue = Double(calculateCurrencyToUsd(currency: "JPY")) ?? 0
let gbpToUsdValue = Double(calculateCurrencyToUsd(currency: "GBP")) ?? 0
let cnyToUsdValue = Double(calculateCurrencyToUsd(currency: "CNY")) ?? 0
let audToUsdValue = Double(calculateCurrencyToUsd(currency: "AUD")) ?? 0
let cadToUsdValue = Double(calculateCurrencyToUsd(currency: "CAD")) ?? 0
let chfToUsdValue = Double(calculateCurrencyToUsd(currency: "CHF")) ?? 0
let hkdToUsdValue = Double(calculateCurrencyToUsd(currency: "HKD")) ?? 0
let sgdToUsdValue = Double(calculateCurrencyToUsd(currency: "SGD")) ?? 0

// 計算總資產（美金）- 包含所有貨幣折合美金
let totalAssets = usd + twdToUsd + usStockTotal + twStockFolded + bondsTotal + structuredTotal + regularInvestment + fund + insurance +
                 eurToUsdValue + jpyToUsdValue + gbpToUsdValue + cnyToUsdValue + audToUsdValue +
                 cadToUsdValue + chfToUsdValue + hkdToUsdValue + sgdToUsdValue
```

**影響範圍：** QuickUpdateView.swift:1976-1993

---

**2. 切換客戶時多幣別資料污染（QuickUpdateView.swift:294-298, 2430-2472）**

**問題描述：**
在客戶 A 新增 AUD 資料後，切換到客戶 B，發現客戶 B 也顯示客戶 A 的 AUD 資料。

**根本原因：**
QuickUpdateView 只在 `.onAppear` 時載入資料，當切換客戶時（`client.objectID` 改變），並未清除舊客戶的狀態資料。

**修復方案：**
1. 新增 `.onChange(of: client.objectID)` 監聽器，偵測客戶切換
2. 新增 `clearAllData()` 函數，清除所有狀態變數

```swift
// 監聽客戶切換
.onChange(of: client.objectID) { _ in
    // 切換客戶時重新載入該客戶的資料
    clearAllData()
    loadInitialCashValues()
}

// 清除所有資料函數
private func clearAllData() {
    // 清除現金資料
    tempTWDCash = "0"
    tempUSDCash = "0"
    tempExchangeRate = "32"

    // 清除可選項目
    tempRegularInvestment = "0"
    tempFund = "0"
    tempInsurance = "0"
    showRegularInvestment = false
    showFund = false
    showInsurance = false

    // 清除所有多幣別現金
    tempEURCash = "0"
    tempJPYCash = "0"
    tempGBPCash = "0"
    tempCNYCash = "0"
    tempAUDCash = "0"
    tempCADCash = "0"
    tempCHFCash = "0"
    tempHKDCash = "0"
    tempSGDCash = "0"

    // 清除所有多幣別匯率
    tempEURRate = "0"
    tempJPYRate = "0"
    tempGBPRate = "0"
    tempCNYRate = "0"
    tempAUDRate = "0"
    tempCADRate = "0"
    tempCHFRate = "0"
    tempHKDRate = "0"
    tempSGDRate = "0"

    // 清除幣別集合
    addedCurrencies.removeAll()
    expandedCurrencies.removeAll()

    print("🧹 已清除所有快速更新資料")
}
```

**影響範圍：** QuickUpdateView.swift:294-298, 2430-2472

---

**3. fixMissingTotalAssets 覆蓋正確數值（MonthlyAssetDetailView.swift:975-1004）**

**問題描述：**
Console 顯示：`🔧 更新總資產：日期=2025-11-30, 舊值=20000.0, 新值=0.0`
正確的總資產被錯誤地覆蓋為 0。

**根本原因：**
`fixMissingTotalAssets()` 函數在每次 `.onAppear` 時執行，但計算總資產時遺漏了所有多幣別折合美金，導致重新計算的值比實際值小。

**修復方案：**
在 `fixMissingTotalAssets()` 的總資產計算中加入所有多幣別：

```swift
// 多幣別折合美金
let eurToUsdValue = Double(asset.eurToUsd ?? "0") ?? 0
let jpyToUsdValue = Double(asset.jpyToUsd ?? "0") ?? 0
let gbpToUsdValue = Double(asset.gbpToUsd ?? "0") ?? 0
let cnyToUsdValue = Double(asset.cnyToUsd ?? "0") ?? 0
let audToUsdValue = Double(asset.audToUsd ?? "0") ?? 0
let cadToUsdValue = Double(asset.cadToUsd ?? "0") ?? 0
let chfToUsdValue = Double(asset.chfToUsd ?? "0") ?? 0
let hkdToUsdValue = Double(asset.hkdToUsd ?? "0") ?? 0
let sgdToUsdValue = Double(asset.sgdToUsd ?? "0") ?? 0

let newTotalAssets = fundValue + insuranceValue + cashValue + usStockValue + regularInvestmentValue +
                bondsValue + structuredValue + taiwanStockFoldedValue + twdToUsdValue +
                eurToUsdValue + jpyToUsdValue + gbpToUsdValue + cnyToUsdValue + audToUsdValue +
                cadToUsdValue + chfToUsdValue + hkdToUsdValue + sgdToUsdValue
```

**影響範圍：** MonthlyAssetDetailView.swift:975-1004

---

**4. 編譯錯誤：Switch 語句不完整（AddMonthlyDataView.swift:723-731）**

**問題描述：**
編譯器錯誤：「Switch must be exhaustive」

**根本原因：**
`AssetFieldType` 枚舉新增了 `.date`、`.deposit`、`.depositAccumulated`、`.notes` 四個案例，但 `AddMonthlyDataView.swift` 的 switch 語句未處理這些案例。

**修復方案：**
新增遺漏的案例，返回 `EmptyView()`（這些欄位由其他區塊處理）：

```swift
// 月度資產明細特有欄位（在其他區塊處理，這裡返回空視圖）
case .date:
    EmptyView()
case .deposit:
    EmptyView()
case .depositAccumulated:
    EmptyView()
case .notes:
    EmptyView()
```

**影響範圍：** AddMonthlyDataView.swift:723-731

---

#### ✨ 功能優化

**1. 儀表板現金卡片包含所有幣別（CustomerDetailView.swift:2116-2137）**

**更新內容：**
`getCash()` 函數現在計算所有幣別的總和（折合美金）：

```swift
private func getCash() -> Double {
    guard let latestAsset = monthlyAssets.first else {
        return 0.0
    }

    let cash = Double(latestAsset.cash ?? "0") ?? 0.0
    let twdToUsd = Double(latestAsset.twdToUsd ?? "0") ?? 0.0

    // 多幣別折合美金
    let eurToUsd = Double(latestAsset.eurToUsd ?? "0") ?? 0.0
    let jpyToUsd = Double(latestAsset.jpyToUsd ?? "0") ?? 0.0
    let gbpToUsd = Double(latestAsset.gbpToUsd ?? "0") ?? 0.0
    let cnyToUsd = Double(latestAsset.cnyToUsd ?? "0") ?? 0.0
    let audToUsd = Double(latestAsset.audToUsd ?? "0") ?? 0.0
    let cadToUsd = Double(latestAsset.cadToUsd ?? "0") ?? 0.0
    let chfToUsd = Double(latestAsset.chfToUsd ?? "0") ?? 0.0
    let hkdToUsd = Double(latestAsset.hkdToUsd ?? "0") ?? 0.0
    let sgdToUsd = Double(latestAsset.sgdToUsd ?? "0") ?? 0.0

    return cash + twdToUsd + eurToUsd + jpyToUsd + gbpToUsd + cnyToUsd + audToUsd + cadToUsd + chfToUsd + hkdToUsd + sgdToUsd
}
```

**影響範圍：** CustomerDetailView.swift:2116-2137

---

**2. 資產配置圓餅圖區分貨幣顯示（CustomerDetailView.swift）**

**問題描述：**
當用戶有 AUD 資料時，圓餅圖仍顯示「美金 100%」，未能區分不同幣別。

**用戶需求：**
- 計算使用美金（因所有幣別已折合美金）
- 圓餅圖上需清楚顯示哪個是哪個幣別

**解決方案：**

**2.1 修改美金百分比計算（CustomerDetailView.swift:2178-2189）**

`getCashPercentage()` 現在只計算純 USD 現金：
```swift
private func getCashPercentage() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let cashStr = latestAsset.cash,
          let totalStr = latestAsset.totalAssets,
          let cash = Double(cashStr),
          let total = Double(totalStr),
          total > 0 else {
        return 0.0
    }
    // 只計算純 USD 現金
    return (cash / total) * 100
}
```

**2.2 新增其他貨幣百分比計算（CustomerDetailView.swift:2251-2274）**

新函數 `getOtherCurrenciesPercentage()` 計算所有其他貨幣的總佔比：
```swift
private func getOtherCurrenciesPercentage() -> Double {
    guard let latestAsset = monthlyAssets.first,
          let totalStr = latestAsset.totalAssets,
          let total = Double(totalStr),
          total > 0 else {
        return 0.0
    }

    // 計算所有其他貨幣折合美金的總和
    let eurToUsd = Double(latestAsset.eurToUsd ?? "0") ?? 0
    let jpyToUsd = Double(latestAsset.jpyToUsd ?? "0") ?? 0
    let gbpToUsd = Double(latestAsset.gbpToUsd ?? "0") ?? 0
    let cnyToUsd = Double(latestAsset.cnyToUsd ?? "0") ?? 0
    let audToUsd = Double(latestAsset.audToUsd ?? "0") ?? 0
    let cadToUsd = Double(latestAsset.cadToUsd ?? "0") ?? 0
    let chfToUsd = Double(latestAsset.chfToUsd ?? "0") ?? 0
    let hkdToUsd = Double(latestAsset.hkdToUsd ?? "0") ?? 0
    let sgdToUsd = Double(latestAsset.sgdToUsd ?? "0") ?? 0

    let otherCurrenciesTotal = eurToUsd + jpyToUsd + gbpToUsd + cnyToUsd + audToUsd +
                              cadToUsd + chfToUsd + hkdToUsd + sgdToUsd

    return (otherCurrenciesTotal / total) * 100
}
```

**2.3 圓餅圖新增「其他貨幣」區塊（CustomerDetailView.swift:1218-1233）**

新增淡藍色區塊顯示其他貨幣：
```swift
// 其他貨幣
Circle()
    .trim(from: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage()) / 100,
          to: (getUSStockPercentage() + getBondsPercentage() + getCashPercentage() + getTWDPercentage() + getOtherCurrenciesPercentage()) / 100)
    .stroke(
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.init(red: 0.3, green: 0.7, blue: 0.9, alpha: 1.0)),
                Color(.init(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0))
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        style: StrokeStyle(lineWidth: 20, lineCap: .round)
    )
    .frame(width: 140, height: 140)
    .rotationEffect(.degrees(-90))
```

**2.4 圖例新增「其他貨幣」項目（CustomerDetailView.swift:1328-1330）**

條件顯示其他貨幣圖例：
```swift
if getOtherCurrenciesPercentage() > 0 {
    simpleLegendItem(color: Color(.init(red: 0.35, green: 0.75, blue: 0.95, alpha: 1.0)), title: "其他貨幣", percentage: formatPercentage(getOtherCurrenciesPercentage()))
}
```

**2.5 更新所有後續圓餅圖區塊的起始位置**

結構型、定期定額、基金、保險等區塊的 `trim(from:to:)` 都需要加入 `getOtherCurrenciesPercentage()`，確保正確堆疊。

**視覺效果：**
- 美金：只顯示純 USD 現金
- 台幣：顯示台幣折合美金
- 其他貨幣：顯示 EUR、JPY、GBP、CNY、AUD、CAD、CHF、HKD、SGD 的折合美金總和
- 淡藍色漸層，易於區分

**影響範圍：** CustomerDetailView.swift:1218-1233, 2178-2189, 2251-2274, 1328-1330

---

#### 📝 技術總結

**支援的 9 種多幣別：**
1. EUR（歐元）
2. JPY（日圓）
3. GBP（英鎊）
4. CNY（人民幣）
5. AUD（澳幣）
6. CAD（加拿大幣）
7. CHF（瑞士法郎）
8. HKD（港幣）
9. SGD（新加坡幣）

**每種貨幣的 3 個欄位：**
- `{currency}Cash`：現金金額
- `{currency}Rate`：兌美金匯率
- `{currency}ToUsd`：折合美金 = Cash ÷ Rate

**資料架構決策：**
- 月度資產（MonthlyAsset）：多幣別使用獨立欄位
- 其他投資（美股、台股、債券等）：未來使用 JSON 格式

**自動顯示/隱藏邏輯：**
- FieldConfigurationManager 管理欄位可見性
- 新增幣別時自動顯示該貨幣的 3 個欄位
- 刪除幣別時自動隱藏

**客戶資料隔離：**
- 每個客戶的多幣別資料完全獨立
- 切換客戶時清除所有狀態，避免資料污染

---

### 🎨 左滑輸入區 UI 全面優化 (2025-11-29 - 深夜)

**影響範圍：** QuickUpdateView.swift（左滑快速輸入區域）

**更新內容：**

這是非常重要的功能區域，針對用戶體驗進行了全面的視覺優化。

**1. 卡片表頭布局優化**
- ✅ **標題文字放大 30%**（QuickUpdateView.swift:2069）
  - 從 16pt 增加到 21pt
  - 提升標題可讀性與視覺層次
- ✅ **更新日期位置調整**（QuickUpdateView.swift:2075-2083）
  - 從左側標題下方移到右側金額下方
  - 更符合用戶視覺習慣，右側對齊更整齊

**2. 卡片展開效果優化**
- ✅ **表頭圓角保持**（QuickUpdateView.swift:2087）
  - 展開後表頭保持四個角都圓潤（12pt）
  - 避免展開時邊角突兀
- ✅ **移除分割線**（QuickUpdateView.swift:2095）
  - 移除表頭和內容區域之間的 Divider
  - 視覺更簡潔流暢
- ✅ **表頭和內容間距**（QuickUpdateView.swift:2099）
  - 新增 8pt 間距（`.padding(.top, 8)`）
  - 避免展開時表頭和內容黏在一起
- ✅ **內容區域背景**（QuickUpdateView.swift:2097-2098）
  - 使用 `Color(.systemGroupedBackground)` 灰色背景
  - 與 APP 整體色調協調一致
  - 內容區域也保持 12pt 圓角

**3. 資產卡片配色調整**
- ✅ **現金 ↔ 保險 顏色對調**（QuickUpdateView.swift:357, 510）
  - 現金：改用 `.teal` 系統青綠色
  - 保險：改用 `#EDDDD4` Powder Petal 淺米色
- ✅ **債券 ↔ 基金 顏色對調**（QuickUpdateView.swift:445, 494）
  - 債券：改用 `#C44536` Tomato Jam 番茄醬紅
  - 基金：改用 `#283D3B` Dark Slate Grey 深板岩灰

**視覺效果總結：**
- 表頭文字更大更清晰
- 日期資訊右側對齊更整齊
- 展開時圓角保持完整不突兀
- 表頭和內容有適當間距不擁擠
- 背景色調與 APP 整體一致
- 配色更符合資產屬性特徵

---

### 🎨 資產卡片配色系統優化 (2025-11-29 - 晚上)

**影響範圍：** QuickUpdateView.swift

**更新內容：**

根據專業配色方案，重新設計所有資產類別的卡片顏色，提升視覺層次感與資產辨識度。

**配色系統：**

| 資產類別 | 新顏色 | Hex Code | 顏色名稱 | 設計理由 | 程式碼位置 |
|---------|--------|----------|---------|---------|-----------|
| **現金** | 🩵 青綠色 | `.teal` | 系統 Teal | 代表流動性（與保險對調） | QuickUpdateView.swift:357 |
| **美股** | 🔵 藍色 | `.blue` | 系統藍 | 保持原有配色 | QuickUpdateView.swift:396 |
| **台股** | 🟠 橙色 | `.orange` | 系統橙 | 保持原有配色 | QuickUpdateView.swift:413 |
| **債券** | 🔴 番茄醬紅 | `#C44536` | Tomato Jam | 代表積極成長（與基金對調） | QuickUpdateView.swift:445 |
| **結構型** | 🔷 暴風青 | `#197278` | Stormy Teal | 代表複雜性、專業、深度 | QuickUpdateView.swift:447 |
| **定期定額** | 🟫 栗色 | `#772E25` | Chestnut | 代表長期、穩重、持續 | QuickUpdateView.swift:463 |
| **基金** | 🟢 深板岩灰 | `#283D3B` | Dark Slate Grey | 代表穩健可靠（與債券對調） | QuickUpdateView.swift:494 |
| **保險** | 🟤 淺米色 | `#EDDDD4` | Powder Petal | 代表安全中性（與現金對調） | QuickUpdateView.swift:510 |

**技術實作：**

使用 SwiftUI Color RGB 初始化方式定義自訂顏色：
```swift
// 現金卡片 - Powder Petal
accentColor: Color(red: 0xED/255.0, green: 0xDD/255.0, blue: 0xD4/255.0)  // #EDDDD4

// 債券卡片 - Dark Slate Grey
accentColor: Color(red: 0x28/255.0, green: 0x3D/255.0, blue: 0x3B/255.0)  // #283D3B

// 結構型商品卡片 - Stormy Teal
accentColor: Color(red: 0x19/255.0, green: 0x72/255.0, blue: 0x78/255.0)  // #197278

// 定期定額卡片 - Chestnut
accentColor: Color(red: 0x77/255.0, green: 0x2E/255.0, blue: 0x25/255.0)  // #772E25

// 基金卡片 - Tomato Jam
accentColor: Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0)  // #C44536
```

**設計特點：**
- 所有顏色代碼內嵌註解，標註 Hex Code 和顏色名稱
- 色彩選擇基於資產屬性與投資特性
- 保持美股（藍色）和台股（橙色）的原有配色，確保用戶習慣不受影響
- 新配色來自專業色彩方案，視覺協調統一

---

### ✨ UI 優化與功能增強 (2025-11-29 - 下午)

**影響範圍：** QuickUpdateView.swift、FloatingMenuButton.swift、AddMonthlyDataView.swift、CorporateBondsDetailView.swift、InvestmentGroupRowView.swift

**更新內容：**

**1. 結構型產品客戶預選功能**
- ✅ **左滑區域結構型 + 按鈕優化**（QuickUpdateView.swift: lines 211-214）
  - 現在使用與浮動按鈕相同的 `BatchAddStructuredProductView`
  - 自動預選當前正在編輯的客戶（顯示為已勾選狀態）
  - 用戶可以取消勾選或選擇其他客戶
  - 確保左滑區域與浮動按鈕行為一致
- ✅ **BatchAddStructuredProductView 客戶預選**（FloatingMenuButton.swift: lines 1374, 1384-1393, 1490-1492）
  - 新增 `preselectedClient: Client?` 參數
  - 新增 `preselectClientIfNeeded()` 函數自動勾選預設客戶
  - 在 `.onAppear` 時執行預選邏輯
- ✅ **字典初始化修正**（FloatingMenuButton.swift: line 1381）
  - 修正 `clientAmounts` 字典初始化語法：`= [:]`

**2. 債券到期日欄位新增**
- ✅ **公司債明細表格新增到期日欄位**（CorporateBondsDetailView.swift）
  - 在 `bondHeaders` 陣列中新增「到期日」欄位（line 668）
  - 位置：債券名稱右側
  - 欄寬：110pt（line 677）
  - 完整支援：顯示、編輯、CSV 匯入
  - CSV 標頭別名：["到期日", "Maturity Date"]（line 1200）
  - 讀取邏輯：`bond.maturityDate ?? ""`（line 940）
  - 寫入邏輯：`bond.maturityDate = cleanValue`（line 975）
- ✅ **新增債券時輸入到期日**（AddMonthlyDataView.swift）
  - 新增 `@State private var maturityDate = Date()` 狀態變數（line 188）
  - 在債券名稱下方新增日期選擇器：`dateFormRow(label: "到期日", date: $maturityDate)`（line 765）
  - 儲存邏輯：`newBond.maturityDate = dateFormatter.string(from: maturityDate)`（line 1188）
  - 影響範圍：儀表板右上角 + 按鈕、左滑輸入區（共用 AddMonthlyDataView）

**3. 股票卡片展開時綠色高亮顯示**
- ✅ **ExpandableCard 綠色背景**（QuickUpdateView.swift: line 2023, 2062-2066）
  - 新增 `useGreenWhenExpanded: Bool = false` 參數
  - 展開時背景改為綠色（RGB: 0.27, 0.51, 0.38, alpha: 1.0, opacity: 0.15）
  - 美股卡片啟用：`useGreenWhenExpanded: true`（line 398）
  - 台股卡片啟用：`useGreenWhenExpanded: true`（line 415）
- ✅ **股票名稱綠色顯示**（QuickUpdateView.swift）
  - `ExpandableStockRow` 新增 `titleColor` 參數（line 2328）
  - 套用到股票名稱 Text：`.foregroundColor(titleColor)`（line 2391）
  - 未分組美股：當 `expandedSections.contains("usStock")` 時顯示綠色（line 753）
  - 未分組台股：當 `expandedSections.contains("twStock")` 時顯示綠色（line 843）
  - `EditableStockCard` 也新增 `titleColor` 支援（line 2231, 2262）
- ✅ **群組內股票綠色顯示**（InvestmentGroupRowView.swift）
  - 新增 `isParentExpanded: Bool = false` 參數（line 10）
  - 傳遞到群組內的 `ExpandableStockRow`（line 96）
  - 美股群組傳入：`isParentExpanded: expandedSections.contains("usStock")`（QuickUpdateView.swift: line 722）
  - 台股群組傳入：`isParentExpanded: expandedSections.contains("twStock")`（QuickUpdateView.swift: line 813）

**設計邏輯：**
- 參考範本「流動資金」選中時的顏色變化設計
- 當美股/台股卡片展開時：
  - 卡片背景轉為淡綠色
  - 內部所有股票名稱顯示為綠色
  - 提供清晰的視覺回饋，表示當前正在操作該資產類別

**技術實作：**
```swift
// 條件背景顏色
.background(
    isExpanded && useGreenWhenExpanded
        ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)).opacity(0.15)
        : (isExpanded ? Color(.systemGray6) : Color(.systemBackground))
)

// 條件標題顏色
titleColor: expandedSections.contains("usStock")
    ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0))
    : .primary
```

---

### ✨ 左滑快速更新區優化 (2025-11-29 - 上午)

**影響範圍：** QuickUpdateView.swift、AddMonthlyDataView.swift、DataModel（CorporateBond 實體）

**更新內容：**

**1. 按鈕顏色統一設計**
- ✅ **新增群組按鈕**改為淺綠色（`Color.green` + `opacity(0.08)` 背景）
  - 位置：QuickUpdateView.swift (lines 681-692, 770-781, 863-874, 949-960)
  - 影響：美股群組、台股群組、債券群組、結構型群組
- ✅ **所有 + 按鈕**統一改為藍色（`AddButton(color: .blue)`）
  - 位置：QuickUpdateView.swift (lines 756, 849, 939-942, 1046-1048)
  - 影響：美股、台股、債券、結構型商品新增按鈕
- ✅ **更新股價按鈕**改為淺灰色背景（`Color(.systemGray6)`）
  - 位置：QuickUpdateView.swift (line 2069)

**2. 債券新增與顯示功能**
- ✅ **債券 + 按鈕功能**（QuickUpdateView.swift: lines 939-942）
  - 點擊後打開 `AddMonthlyDataView`，直接顯示公司債表單
  - 隱藏分頁選擇器（`hideTabSelector: true`）
  - 自訂標題為「新增公司債」（`customTitle: "新增公司債"`）
- ✅ **債券顯示資訊更新**（QuickUpdateView.swift: lines 908-919）
  - 改為顯示：**票面利率**（couponRate）+ **到期日**（maturityDate）+ **幣別**
  - 格式：`"%.2f% | 到期日 | 幣別"`
  - 例如：`"3.50% | 2026/12/31 | USD"`
- ✅ **Core Data 模型更新**（DataModel.xcdatamodel/contents: line 34）
  - `CorporateBond` 實體新增 `maturityDate` 屬性（String 類型）
  - 用於儲存債券到期日

**3. 結構型商品客戶選擇功能**
- ✅ **客戶選擇對話框**（QuickUpdateView.swift: lines 2565-2631）
  - 新增 `ClientSelectionView` 組件
  - 點擊結構型 + 按鈕時先顯示客戶選擇介面
  - **當前客戶特殊顯示：**
    - 置頂顯示
    - 淡綠色背景（`Color.green.opacity(0.05)`）
    - 名稱加粗顯示
    - 顯示「(當前編輯)」綠色標籤
  - 其他客戶按照 sortOrder 排列
  - 選擇客戶後開啟對應客戶的新增表單
- ✅ **行為與浮動按鈕一致**
  - 與 `FloatingMenuButton` 中的結構型新增按鈕邏輯相同
  - 確保跨客戶操作的一致性

**4. AddMonthlyDataView 表單優化**
- ✅ **自訂標題功能**（AddMonthlyDataView.swift: lines 301, 303, 397）
  - 新增 `customTitle: String?` 參數
  - 支援不同入口顯示不同標題
  - 債券 +：顯示「新增公司債」
  - 結構型 +：顯示「新增結構型商品」
  - 儀表板 +：顯示預設「新增資產記錄」
- ✅ **隱藏分頁選擇器**（已實作於前次更新）
  - `hideTabSelector: Bool` 參數控制
  - 避免用戶混淆，直接進入對應表單

**技術實作細節：**

```swift
// QuickUpdateView - 債券新增按鈕
AddButton(color: .blue) {
    showingAddBond = true
}

// QuickUpdateView - 結構型新增按鈕
AddButton(color: .blue) {
    showingClientSelection = true  // 先選擇客戶
}

// QuickUpdateView - 債券顯示格式
SmallCard(
    title: bond.bondName ?? "",
    subtitle: "\(String(format: "%.2f", couponRate))% | \(maturityDate) | \(bond.currency ?? "USD")",
    amount: formatCurrency(currentValue),
    color: .purple
)

// AddMonthlyDataView - 自訂標題
Text(customTitle ?? "新增資產記錄")
    .font(.system(size: 17, weight: .semibold))

// ClientSelectionView - 當前客戶特殊樣式
.listRowBackground(isCurrent ? Color.green.opacity(0.05) : Color.clear)
```

**使用流程：**

**債券新增：**
1. 在左滑區展開債券卡片
2. 點擊藍色 + 按鈕
3. 直接進入公司債輸入表單（無分頁選擇器）
4. 標題顯示「新增公司債」
5. 輸入完成後保存

**結構型商品新增：**
1. 在左滑區展開結構型商品卡片
2. 點擊藍色 + 按鈕
3. 彈出客戶選擇對話框
4. 當前客戶置頂並以淡綠色背景標示
5. 選擇目標客戶
6. 進入該客戶的結構型商品表單（無分頁選擇器）
7. 標題顯示「新增結構型商品」
8. 輸入完成後保存到選中客戶

**相關檔案：**
- QuickUpdateView.swift (按鈕顏色、債券顯示、客戶選擇)
- AddMonthlyDataView.swift (自訂標題、隱藏分頁)
- DataModel.xcdatamodel/contents (CorporateBond.maturityDate)
- ClientSelectionView (新增組件，QuickUpdateView.swift: 2565-2631)

---

### 🔥 重大修復：資料格式錯誤 (2025-11-29)

**影響範圍：** QuickUpdateView.swift、CustomerDetailView.swift、月度資產表格、所有小卡折線圖

**問題描述：**
從左滑區保存至月度資產後，出現兩個嚴重問題：
1. ❌ **總資產只顯示台幣折合美金**，其他資產（美股、債券等）數值消失
2. ❌ **所有小卡折線圖完全消失**，無法顯示歷史趨勢

**根本原因：**

QuickUpdateView 的 `formatNumberWithoutDollarSign()` 函數使用 `NumberFormatter.decimal` 格式，會自動添加**千分位逗號**：

```swift
// ❌ 錯誤的實作
private func formatNumberWithoutDollarSign(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal  // ❌ 添加千分位逗號
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: value)) ?? "0.00"
}
```

保存到 Core Data 的數據格式：
```
totalAssets = "5,156.25"  // ❌ 包含逗號
usStock = "1,234.56"      // ❌ 包含逗號
bonds = "2,000.00"        // ❌ 包含逗號
```

但讀取數據的函數使用 `Double(string)` 轉換：
```swift
// CustomerDetailView.swift - getTotalAssets()
guard let totalAssetsStr = latestAsset.totalAssets,
      let totalAssets = Double(totalAssetsStr) else {  // ❌ Double("5,156.25") 返回 nil
    return 0.0
}

// CustomerDetailView.swift - getUSStockTrendData()
return filteredAssets.compactMap { asset -> Double? in
    guard let valueStr = asset.usStock else { return nil }
    return Double(valueStr)  // ❌ Double("1,234.56") 返回 nil，折線圖空陣列
}
```

**修復方案：**

QuickUpdateView.swift:1815-1818 - 移除千分位逗號格式化

```swift
// ✅ 修復後
private func formatNumberWithoutDollarSign(_ value: Double) -> String {
    // ⭐️ 不添加千分位逗號，因為 Core Data 讀取時使用 Double(string) 無法解析包含逗號的字串
    return String(format: "%.2f", value)
}
```

現在保存的數據格式：
```
totalAssets = "5156.25"  // ✅ 無逗號，可正常轉換
usStock = "1234.56"      // ✅ 無逗號，可正常轉換
bonds = "2000.00"        // ✅ 無逗號，可正常轉換
```

**修復結果：**
- ✅ 總資產正確顯示所有資產類型的總和
- ✅ 所有小卡折線圖恢復正常顯示
- ✅ 月度資產明細數據格式統一
- ✅ Double(string) 轉換不再失敗

**技術要點：**
1. Core Data 儲存的字串數值**不應包含格式化字符**（如千分位逗號）
2. 格式化應該只在**顯示層**進行，儲存層保持純數字字串
3. Swift 的 `Double(string)` 無法解析包含逗號的數字字串

**相關檔案：**
- QuickUpdateView.swift (修復點：line 1815-1818)
- CustomerDetailView.swift (受影響的讀取函數：getTotalAssets, getUSStockTrendData, getTWStockTrendData, getBondsTrendData 等)

---

### 📊 小卡資料來源架構調整 (2025-11-29)

**影響範圍：** CustomerDetailView.swift - 所有小卡計算函數

**調整目標：**
明確區分小卡的資料來源，實現混合架構：
- **即時資料**：小卡顯示的數字和報酬率
- **歷史資料**：總額數字、走勢圖、折線圖

**資料來源分配：**

**從月度資產表格讀取：**
- ✅ 總資產數字（getTotalAssets）
- ✅ 總資產走勢圖
- ✅ 小卡折線圖（getUSStockTrendData、getTWStockTrendData、getBondsTrendData 等）

**從即時持倉計算：**
- ✅ 美股小卡數字和報酬率（從 usStocks FetchRequest）
- ✅ 台股小卡數字和報酬率（從 TWStock 動態查詢）
- ✅ 債券小卡數字和報酬率（從 corporateBonds FetchRequest）

**修改內容：**

CustomerDetailView.swift - 簡化小卡計算函數 (lines 2264-2504)

```swift
// ✅ 修改前：使用時間戳比較決定資料來源
private func getUSStockValue() -> Double {
    if shouldUseInventoryData(stockType: "us") {
        return getUSStockValueFromInventory()
    }
    // 從月度資產讀取...
}

// ✅ 修改後：完全從即時持倉計算
private func getUSStockValue() -> Double {
    return getUSStockValueFromInventory()
}
```

**移除的邏輯：**
- ❌ 刪除 `shouldUseInventoryData()` 函數（時間戳比較不再需要）
- ❌ 刪除 UserDefaults 儲存的股價更新時間戳

**技術要點：**
1. 小卡數字永遠顯示最新的持倉市值（即時計算）
2. 折線圖顯示歷史趨勢（從月度資產明細讀取）
3. 兩者資料來源明確分離，不再混淆

**相關檔案：**
- CustomerDetailView.swift:2264-2504（修改所有小卡計算函數）
- CustomerDetailView.swift:2390-2421（刪除 shouldUseInventoryData 函數）

---

### ⭐️ 三區域同步功能完成 (2025-11-28)

**影響範圍：** QuickUpdateView.swift（左滑輸入區）、表格明細區、儀表板小卡區

**完成目標：**
現在投資 App 的三個核心區域可以完美同步更新：

1. **左滑輸入區**（QuickUpdateView）- 快速更新介面 ✅
   - 更新股價 ✅
   - 編輯股數和成本 ✅
   - 新增股票 ✅
   - 重新計算市值、損益、報酬率 ✅

2. **表格明細區**（USStockDetailView、TWStockDetailView）- 詳細表格 ✅
   - 更新股價 ✅
   - 編輯資料 ✅
   - 新增股票 ✅

3. **儀表板小卡區**（CustomerDetailView）- 投資總覽卡片 ✅
   - 自動同步顯示 ✅

**修復的問題：**
- ❌ 左滑區更新股價後，只更新了 `currentPrice`，沒有計算 `marketValue`、`profitLoss`、`returnRate`
- ❌ 類型轉換錯誤：`StockPriceService.fetchStockPrice()` 返回 String，但代碼誤以為是 Double
- ❌ 變量名稱衝突：`currentPrice` 同時作為 String 屬性和 Double 變量使用

**修復方案：**

**1. QuickUpdateView.swift - updateAllStockPrices() 函數** (lines 1620-1720)
```swift
// 美股更新邏輯
let fetchedPrice = try await StockPriceService.shared.fetchStockPrice(symbol: stockName)
await MainActor.run {
    // ⭐️ 更新股價
    stock.currentPrice = fetchedPrice  // fetchedPrice 是 String

    // ⭐️ 重新計算市值、損益、報酬率
    let sharesString = stock.shares ?? "0"
    let costPerShareString = stock.costPerShare ?? "0"
    let shares: Double = Double(sharesString) ?? 0.0
    let costPerShare: Double = Double(costPerShareString) ?? 0.0
    let priceDouble: Double = Double(fetchedPrice) ?? 0.0  // ✅ String → Double
    let marketValue = shares * priceDouble
    let cost = shares * costPerShare
    let profitLoss = marketValue - cost
    let returnRate = cost > 0 ? (profitLoss / cost) * 100.0 : 0.0

    stock.marketValue = String(format: "%.2f", marketValue)
    stock.cost = String(format: "%.2f", cost)
    stock.profitLoss = String(format: "%.2f", profitLoss)
    stock.returnRate = String(format: "%.2f", returnRate)
}

// 台股同樣邏輯...
```

**技術關鍵點：**
1. **類型轉換**：`let priceDouble: Double = Double(fetchedPrice) ?? 0.0`
   - `StockPriceService.fetchStockPrice()` 返回 String，必須先轉換成 Double
   - 避免變量名稱衝突（`priceDouble` vs `stock.currentPrice`）

2. **完整計算邏輯**：
   - 市值 = 股數 × 股價
   - 成本 = 股數 × 成本單價
   - 損益 = 市值 - 成本
   - 報酬率 = (損益 ÷ 成本) × 100

3. **Core Data 刷新**（已實作）：
   - `viewContext.save()` - 保存變更
   - `viewContext.refreshAllObjects()` - 刷新物件快取
   - `PersistenceController.shared.save()` - 同步到 iCloud

**資料流向：**
```
左滑區更新股價
  ↓
更新 currentPrice（String）
  ↓
轉換為 Double 計算市值、損益、報酬率
  ↓
保存到 Core Data（String 格式）
  ↓
viewContext.refreshAllObjects()
  ↓
表格區自動更新（@FetchRequest）
  ↓
儀表板小卡自動更新（@FetchRequest + .id(refreshTrigger)）
  ↓
✅ 三區域完美同步
```

**編譯錯誤修復：**
- 第 1636 行：`cannot convert value of type 'String' to specified type 'Double'` ✅
- 第 1683 行：`cannot convert value of type 'String' to specified type 'Double'` ✅

**測試結果：**
- ✅ BUILD SUCCEEDED
- ✅ 左滑區更新股價後，表格區和小卡區立即同步
- ✅ 市值、損益、報酬率正確計算

**相關文件：**
→ 參考新建的 `📊_資料串流順序.md` 了解完整資料流架構

---

### 儀表板刷新機制優化

**問題描述：**
- ❌ 在 QuickUpdateView（左滑快速更新區域）更新股價後，儀表板小卡不會更新
- ❌ 保存月度資產明細後，總資產、走勢圖、各投資小卡都不會更新
- ✅ 但從儀表板右上角「+」按鈕新增或更新資料時，卻能正常刷新

**根本原因：**
1. **新增物件 vs 修改物件的差異**：
   - 新增物件（如新增股票）→ @FetchRequest 自動偵測並更新 ✅
   - 修改現有物件（如更新股價）→ SwiftUI 可能不觸發 @FetchRequest 更新 ❌

2. **QuickUpdateView 缺少關鍵步驟**：
   - 只呼叫 `viewContext.save()`，沒有 `PersistenceController.shared.save()`
   - 沒有呼叫 `viewContext.refreshAllObjects()` 強制刷新物件
   - 通知發送時機不當（沒有給 Core Data 足夠時間完成保存）

**修復方案：**

**1. QuickUpdateView.swift - 更新股價函數** (lines 1653-1709)
```swift
// 3. 儲存並顯示結果
await MainActor.run {
    do {
        try viewContext.save()

        // ⭐️ 關鍵修復：強制刷新所有物件
        viewContext.refreshAllObjects()

        // ⭐️ 關鍵修復：同步到 iCloud
        PersistenceController.shared.save()

        // 更新時間戳
        let now = Date()
        let clientKey = client.objectID.uriRepresentation().absoluteString
        UserDefaults.standard.set(now, forKey: "usStockPriceUpdateTime_\(clientKey)")
        UserDefaults.standard.set(now, forKey: "twStockPriceUpdateTime_\(clientKey)")
    }
}

// ⭐️ 關鍵修復：給 Core Data 時間完成保存
try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒

await MainActor.run {
    // 發送通知讓儀表板刷新
    NotificationCenter.default.post(...)
}
```

**2. QuickUpdateView.swift - 保存月度資產函數** (lines 1360-1492)
```swift
private func saveToMonthlyAsset() async {  // ⭐️ 改為 async
    await MainActor.run {
        let newAsset = MonthlyAsset(context: viewContext)
        // ... 設定屬性

        do {
            try viewContext.save()

            // ⭐️ 關鍵修復：強制刷新所有物件
            viewContext.refreshAllObjects()

            // ⭐️ 關鍵修復：同步到 iCloud
            PersistenceController.shared.save()
        }
    }

    // ⭐️ 關鍵修復：延遲後再發送通知
    try? await Task.sleep(nanoseconds: 200_000_000)

    await MainActor.run {
        // 發送通知
        NotificationCenter.default.post(...)
    }
}
```

**3. CustomerDetailView.swift - 確保所有卡片響應刷新** (lines 399, 1128, 1560, 1762)
```swift
// 在所有需要刷新的視圖上添加 .id(refreshTrigger)
private var mainStatsCard: some View {
    VStack { ... }
    .id(refreshTrigger)  // ⭐️ 強制重繪
}

private var usStockCard: some View { ... }.id(refreshTrigger)
private var twStockCard: some View { ... }.id(refreshTrigger)
private var bondsCard: some View { ... }.id(refreshTrigger)
private var assetAllocationCard: some View { ... }.id(refreshTrigger)
```

**技術關鍵點：**
1. **`viewContext.refreshAllObjects()`** - 強制 Core Data 刷新所有物件的快取，確保 @FetchRequest 能偵測到變更
2. **`PersistenceController.shared.save()`** - 確保變更同步到 persistent store 和 iCloud
3. **`Task.sleep(200ms)`** - 給 Core Data 足夠時間完成保存和同步
4. **`.id(refreshTrigger)`** - 當 UUID 改變時，SwiftUI 會銷毀並重建視圖，強制重新計算所有屬性

**修復後的流程：**
```
QuickUpdateView 更新/保存資料
  ↓
viewContext.save() - 保存到 Core Data
  ↓
viewContext.refreshAllObjects() - 刷新物件快取
  ↓
PersistenceController.shared.save() - 同步到 persistent store
  ↓
Task.sleep(0.2秒) - 等待保存完成
  ↓
NotificationCenter.post(...) - 發送通知
  ↓
CustomerDetailView 收到通知
  ↓
refreshTrigger = UUID() - 觸發刷新
  ↓
所有帶 .id(refreshTrigger) 的視圖重建
  ↓
✅ 儀表板顯示最新資料
```

**影響範圍：**
- ✅ QuickUpdateView - 更新股價功能
- ✅ QuickUpdateView - 保存月度資產功能
- ✅ CustomerDetailView - 所有儀表板卡片（總資產、美股、台股、債券、資產配置）

---

## 📱 核心功能

### 1. 客戶管理（漢堡按鈕 - 左上角）
**位置：** `SidebarView.swift`
**相關文件：** `PROJECT.md` → Core Data 資料模型 → Client 實體

**功能清單：**
- ✅ 新增客戶資料（姓名、Email、生日）
- ✅ 編輯客戶資料
- ✅ 刪除客戶（級聯刪除所有關聯資料）
- ✅ iCloud 同步

**資料模型：**
- `Client` 實體 → 包含客戶基本資料
- 關聯：`monthlyAssets`、`corporateBonds`、`structuredProducts`、`usStocks`、`taiwanStocks`、`insurancePolicies`、`loans`

---

### 2. 月度資產明細表
**位置：** `MonthlyAssetTableView.swift`、`AddMonthlyDataView.swift`
**資料實體：** `MonthlyAsset`
**相關文件：** `PROJECT.md` → MonthlyAsset 實體

**功能清單：**
- ✅ 記錄每月資產狀況
- ✅ 自動計算總資產、報酬率
- ✅ 顯示歷史趨勢圖表
- ✅ 編輯、刪除資產記錄
- ✅ 可配置欄位顯示/隱藏（`AssetFieldConfigurationView.swift`）
- ✅ 欄位重新排序（`ColumnReorderView.swift`）
- ✅ **自動過濾即時快照記錄**（2025-11-27 更新）
  - FetchRequest 自動過濾掉 `isLiveSnapshot = true` 的記錄
  - 只顯示正式的月度資產記錄
  - 確保數據一致性和準確性
- ✅ **分組顯示優化**（新增資產記錄表單）
  - 資產資訊：台幣、美金、美股、定期定額、債券、台股、結構型商品、債券已領利息、總資產、基金、保險
  - 投資成本：基金成本、美股成本、定期定額成本、債券成本、台股成本
  - 美金匯率換算：匯率、台股折合美金、台幣折合美金
- ✅ **多幣別支援系統**（2025-11-26 新增）
  - 支援 9 種國際貨幣：歐元(EUR)、日圓(JPY)、英鎊(GBP)、人民幣(CNY)、澳幣(AUD)、加幣(CAD)、瑞士法郎(CHF)、港幣(HKD)、新加坡幣(SGD)
  - **雙區域顯示設計**：
    - **資產資訊區域**：顯示所有外幣現金欄位（與台幣、美金等並列）
    - **獨立換算區域**：每種貨幣有獨立的換算區域（如「歐元換算」、「日圓換算」等）
    - 換算區域只顯示：兌美金匯率（輸入）→ 折合美金（自動計算）
    - 只有啟用該貨幣的匯率或折合美金欄位時，才顯示對應的換算區域
  - **匯率欄位命名優化**：
    - 明確標示「XXX兌美金匯率」（如：歐元兌美金匯率）
    - 避免混淆，清楚表達是對美金的匯率
  - **自動計算邏輯**：折合美金 = 現金 ÷ 兌美金匯率
  - **預設隱藏設計**：新增的 27 個貨幣欄位預設隱藏，使用者可透過「欄位設定」按需開啟
  - **自動納入總資產**：啟用的貨幣折合美金金額會自動計入總資產統計
  - **資料持久化**：完整支援 Core Data 儲存、載入前筆資料、iCloud 同步
  - 實作檔案：
    - `FieldConfigurationManager.swift` (line 26-61)：欄位定義、順序與可見性管理
    - `AddMonthlyDataView.swift` (line 481-597)：獨立換算區域實現
    - `DataModel.xcdatamodel/contents` (line 72-98)：Core Data 模型
    - `ContentView.swift` (line 689-718)：資料儲存邏輯
- ✅ **欄位配置分組管理**
  - 按分組顯示所有欄位
  - 支援組內欄位排序
  - 支援組內欄位顯示/隱藏
- ✅ **快速更新與查看功能**（2025-11-26 新增）
  - 在新增資產記錄表單的特定欄位旁添加功能按鈕
  - **美股/美股成本欄位**：
    - 🔄 更新現值：自動更新股價 → 計算總市值 → 填入欄位
    - 👁️ 查看庫存：快速打開美股庫存明細頁面
  - **台股/台股成本欄位**：
    - 🔄 更新現值：自動更新股價 → 計算總市值 → 填入欄位
    - 👁️ 查看庫存：快速打開台股庫存明細頁面
  - **定期定額欄位**：
    - 🔄 更新現值：從庫存明細抓取市值和成本
    - 👁️ 查看庫存：快速打開定期定額庫存明細頁面
  - **債券欄位**：
    - 🔄 更新現值：從公司債明細加總現值（不更新股價）
    - 👁️ 查看庫存：快速打開公司債庫存明細頁面
  - **結構型商品欄位**：
    - 🔄 更新現值：從結構型商品明細加總未退出產品的交易金額
    - 👁️ 查看庫存：快速打開結構型商品明細頁面
  - **按鈕設計**：柔和灰色調（systemGray），24x24 圓形按鈕
  - **智能提示**：
    - 更新成功時顯示股價更新狀況和總市值
    - 沒有庫存時提示點擊 👁️ 按鈕新增記錄
    - 錯誤時顯示詳細錯誤訊息

**重要公式：**
```
總額報酬率 = 總資產 − 總匯入
現金 = 台幣 + 美金
美股報酬率 = (美股 − 美股成本) ÷ 美股成本
台股報酬率 = (台股 − 台股成本) ÷ 台股成本
債券報酬率 = (債券 − 債券成本 + 已領利息) ÷ 債券成本
```

---

### 3. 快速更新介面（左滑功能）🆕
**位置：** `QuickUpdateView.swift`、`CustomerDetailView.swift` (TabView 整合)
**資料實體：** `MonthlyAsset`、`USStock`、`TWStock`、`CorporateBond`、`StructuredProduct`
**相關文件：** `PROJECT.md` → QuickUpdateView 實作

**核心概念：**
- 從投資儀表板向左滑動進入快速更新介面
- 提供直觀的輸入/更新介面，方便快速編輯
- 所有資產一目了然，點擊即可編輯
- **保存按鈕會創建新的月度資產記錄**

**介面佈局：**
1. **頂部：總資產顯示區**
   - 顯示「總資產」標題
   - 大字體顯示總資產數值（36pt, bold）
   - 底部顯示幣別「USD」
   - 非卡片設計，純數字展示

2. **主體：五個可展開卡片**
   - 現金（綠色）
   - 美股（藍色）
   - 台股（橘色）
   - 債券（紫色）
   - 結構型商品（粉色）

**卡片功能設計：**

#### 📊 卡片標題顯示（摺疊狀態）
- **左側：** 資產類別名稱 + 最後更新日期
- **右側：** 該類別總金額
- **點擊：** 整個卡片區域可點擊展開/收合
- **展開效果：** 背景顯示重點顏色（5% 透明度）

#### 📝 現金卡片（展開後）
**元件：** `EditableSmallCard`

**顯示項目：**
- ✅ 台幣金額（可點擊編輯）
- ✅ 美金金額（可點擊編輯）
- 其他已啟用的幣別（可點擊編輯）

**編輯功能：**
- 點擊任一幣別卡片彈出輸入對話框
- 輸入新金額後自動更新 Core Data
- 自動重新計算總資產
- 右側顯示小鉛筆圖標提示可編輯

**底部：**
- ➕ 圓形新增按鈕（綠色）
- 點擊打開 `AddMonthlyDataView` 新增其他幣別

#### 📈 美股 + 台股組合區域（2025-11-27 更新）🆕
**佈局設計：** 長條更新按鈕 + 兩個卡片垂直排列

**左側：長條更新按鈕** ⚡
- **位置：** 橫跨美股和台股兩個卡片的左側
- **寬度：** 50pt
- **背景：** 綠色漸層（總報酬小卡同色系）
  - 上方：`rgb(0.27, 0.51, 0.38)`
  - 下方：`rgb(0.20, 0.40, 0.30)`
- **圖示：**
  - 平常：`arrow.triangle.2.circlepath.circle.fill`（圓圈更新符號，28pt）
  - 更新中：白色 ProgressView
- **功能：** 依序更新美股和台股價格
  - 第一步：更新所有美股股價
  - 第二步：更新所有台股股價（加 .TW 後綴）
  - 自動儲存到 Core Data
  - 自動更新即時快照
  - 顯示更新結果 alert（成功/失敗數量）
- **視覺回饋：**
  - 更新美股時：美股卡片透明度 60%
  - 更新台股時：台股卡片透明度 60%
  - 按鈕禁用時無法點擊

**右側：美股卡片（展開後）**
**元件：** `ExpandableCard` + `EditableStockCard`

**顯示項目：**
- ✅ 每支股票的名稱
- ✅ 股數 + 成本單價（副標題）
- ✅ 市值（右側大字）
- 右側顯示小鉛筆圖標提示可編輯

**編輯功能：**
- 點擊任一股票卡片彈出輸入框對話框
- 輸入「股數」和「成本單價」
- 自動計算並更新市值
- 自動保存到 Core Data

**底部：**
- ➕ 圓形新增按鈕（藍色）
- 點擊打開 `USStockInventoryView` 美股庫存區

**右側：台股卡片（展開後）**
**元件：** `ExpandableCard` + `EditableStockCard`（帶 "TWD" 前綴）

**顯示項目：**
- ✅ 每支股票的名稱
- ✅ 股數 + 成本單價（副標題）
- ✅ 市值（TWD $xxx,xxx.xx 格式）
- 右側顯示小鉛筆圖標提示可編輯

**編輯功能：**
- 點擊任一股票卡片彈出輸入框對話框
- 輸入「股數」和「成本單價」
- 自動計算並更新市值
- 自動保存到 Core Data

**底部：**
- ➕ 圓形新增按鈕（橘色）
- 點擊打開 `TWStockInventoryView` 台股庫存區

#### 💰 債券卡片（展開後）🆕
**元件：** `SmallCard`（目前唯讀）

**顯示項目：**
- ✅ 債券名稱
- ✅ **票面利率 + 到期日 + 幣別**（副標題）（2025-11-29 更新）
  - 格式：`票面利率% | 到期日 | 幣別`
  - 例如：`3.50% | 2026/12/31 | USD`
- ✅ 現值（右側）

**投資群組功能：**（2025-11-29 新增）
- ✅ 新增債券群組（淺綠色按鈕）
- ✅ 拖放操作：長按債券項目拖曳到群組
- ✅ 自動計算群組總現值
- ✅ 展開/收合群組查看內含債券

**底部：**
- ➕ 圓形新增按鈕（**藍色**）（2025-11-29 更新）
- 點擊打開 `AddMonthlyDataView` 的公司債表單
- **表單特性：**
  - 隱藏分頁選擇器（資產明細/公司債）
  - 直接顯示公司債輸入表單
  - 標題顯示「新增公司債」
  - 不影響儀表板右上 + 按鈕的原有功能

#### 🏦 結構型商品卡片（展開後）🆕
**元件：** `SmallCard`（目前唯讀）

**顯示項目：**
- ✅ 產品代碼
- ✅ 利率（副標題）
- ✅ 交易金額（右側）
- 只顯示未退出的產品

**投資群組功能：**（2025-11-29 新增）
- ✅ 新增結構型群組（淺綠色按鈕）
- ✅ 拖放操作：長按結構型項目拖曳到群組
- ✅ 自動計算群組總金額
- ✅ 展開/收合群組查看內含產品

**底部：**
- ➕ 圓形新增按鈕（**藍色**）（2025-11-29 更新）
- 點擊打開**客戶選擇對話框**（與浮動按鈕行為一致）
- **客戶選擇功能：**
  - 顯示所有客戶列表
  - 當前編輯的客戶置頂顯示
  - 當前客戶背景為淡綠色（`Color.green.opacity(0.05)`）
  - 當前客戶名稱加粗 + 顯示「(當前編輯)」綠色標籤
  - 選擇客戶後開啟該客戶的結構型商品新增表單
- **表單特性：**
  - 隱藏分頁選擇器
  - 標題顯示「新增結構型商品」
  - 使用選中客戶的資料

**互動功能：**
1. **一鍵更新股價** ⚡（2025-11-27 新增）
   - 點擊長條綠色按鈕更新美股和台股價格
   - **依序執行**（避免 API 衝突）：
     1. 先更新所有美股
     2. 等美股完成後再更新台股
   - 呼叫 `StockPriceService.shared.fetchStockPrice()`
   - 更新後自動保存到 Core Data
   - 顯示更新結果（成功 X 個，失敗 X 個）
   - **優勢：** 比下拉更新更穩定，成功率更高

2. **快速編輯**
   - 點擊股票卡片可展開編輯表單
   - 修改股數、成本單價等資訊
   - 自動保存到 Core Data

3. **保存至月度資產**
   - 點擊底部「保存至月度資產」按鈕
   - 創建新的月度資產記錄
   - 包含當前所有資產數據
   - 自動計算總資產和各項總額

**技術實作細節：**

**核心元件：**
```swift
// 可編輯小卡片（用於現金等單一數值）
struct EditableSmallCard: View {
    let title: String           // 項目名稱
    let amount: String          // 顯示金額
    let color: Color            // 主題色
    let onEdit: (String) -> Void  // 編輯 callback

    // 點擊後彈出輸入對話框
    // 自動移除貨幣符號和逗號
    // 右側顯示小鉛筆圖標
}

// 可編輯股票卡片（用於股票編輯）
struct EditableStockCard: View {
    let title: String           // 股票名稱
    let shares: Double          // 持股數量
    let price: Double           // 當前價格
    let color: Color            // 主題色
    var currencyPrefix: String  // 貨幣前綴（如 "TWD "）
    let onEdit: (String, String) -> Void  // 編輯 callback

    // 點擊後彈出雙輸入框對話框
    // 可同時編輯持股數量和當前價格
    // 自動計算並顯示市值
}

// 新增按鈕
struct AddButton: View {
    let color: Color            // 按鈕顏色
    let action: () -> Void      // 點擊 callback

    // 44x44 圓形按鈕
    // 白色加號圖標
}

// 長條更新按鈕佈局（2025-11-27 新增）
HStack(spacing: 8) {
    // 左側：長條綠色按鈕
    Button {
        Task { await updateAllStockPrices() }
    } label: {
        VStack {
            if isUpdatingAllStocks {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
        }
        .frame(maxHeight: .infinity)  // 垂直填滿
    }
    .frame(width: 50)
    .background(綠色漸層)
    .cornerRadius(12)
    .disabled(isUpdatingAllStocks)

    // 右側：美股 + 台股卡片
    VStack(spacing: 12) {
        ExpandableCard(美股)
            .opacity(isUpdatingUSStock ? 0.6 : 1.0)
        ExpandableCard(台股)
            .opacity(isUpdatingTWStock ? 0.6 : 1.0)
    }
}
```

**資料更新函數：**
- `updateCashValue(asset:field:value:)` - 更新現金數值
- `updateStockValues(stock:shares:price:)` - 更新股票資料
- `recalculateTotalAssets(for:)` - 重新計算總資產
- `updateUSStockPrices()` - 更新美股股價（2025-11-27 新增）
- `updateTWStockPrices()` - 更新台股股價（2025-11-27 新增）
- `updateAllStockPrices()` - 依序更新美股和台股（2025-11-27 新增）
- `saveToMonthlyAsset()` - 保存至月度資產（創建新記錄）

**導航整合：**
- 在 `CustomerDetailView.swift` (line 125-186) 使用 `TabView` 整合
- `.tabViewStyle(.page(indexDisplayMode: .never))` 隱藏指示器
- 第一頁：原始投資儀表板
- 第二頁：快速更新介面

**設計特點：**
- ✅ 最小化步驟：點擊 → 輸入 → 確定
- ✅ 視覺提示：小鉛筆圖標標示可編輯
- ✅ 即時反饋：編輯後立即更新顯示
- ✅ 顏色分類：不同資產類別使用不同顏色
- ✅ 一致性：與 iOS 設計規範一致

**使用流程：**
1. 在投資儀表板向左滑動進入快速更新介面
2. 查看當前各項資產總額
3. 點擊想要更新的資產卡片展開
4. 編輯現金、股票等資訊
5. 點擊「保存至月度資產」按鈕創建新記錄
6. 或點擊 ➕ 按鈕新增項目

**未來擴充方向：**
- [ ] 債券卡片可編輯功能
- [ ] 結構型商品卡片可編輯功能
- [ ] 批量編輯模式
- [ ] 歷史編輯記錄
- [ ] 編輯時的數值驗證和範圍檢查

#### 📁 投資群組管理功能（2025-11-27 新增）🆕
**位置：**
- `InvestmentGroupRowView.swift` - 群組行視圖
- `DraggableInvestmentItemRow.swift` - 可拖曳項目
- `GroupEditSheetView.swift` - 群組編輯介面
**資料實體：** `InvestmentGroup`（新增）
**整合位置：** `QuickUpdateView.swift` - 美股/台股內容區域

**核心概念：**
- 為投資項目創建群組/資料夾進行分類管理
- 一個投資項目可以屬於多個群組（多對多關係）
- 自動計算群組內所有項目的總價值
- 支援美股、台股、債券、結構型四種投資類型
- **拖放操作**：長按項目拖曳到群組即可加入

**使用方式：**
1. 在快速更新介面展開美股/台股卡片
2. 點擊「新增群組」按鈕
3. 輸入群組名稱並保存
4. **拖放操作**：長按任意投資項目，拖曳到目標群組上方
5. 放開後自動加入該群組
6. 點擊群組可展開查看內含項目
7. 將項目拖曳到未分組區域即可移除群組

**Core Data 模型：**

**InvestmentGroup 實體**（新增）
```
屬性：
- id: UUID（optional）- 唯一識別碼
- name: String - 群組名稱
- groupType: String - 群組類型（usStock/twStock/bond/structured）
- createdDate: Date - 創建日期
- orderIndex: Integer 16 - 排序索引

關係：
- client (To One) → Client - 所屬客戶
- usStocks (To Many) → USStock - 關聯的美股
- twStocks (To Many) → TWStock - 關聯的台股
- bonds (To Many) → CorporateBond - 關聯的債券
- structuredProducts (To Many) → StructuredProduct - 關聯的結構型商品
```

**修改的現有實體關係**
- `Client.investmentGroups` (To Many) → InvestmentGroup
- `USStock.groups` (To Many) → InvestmentGroup
- `TWStock.groups` (To Many) → InvestmentGroup
- `CorporateBond.groups` (To Many) → InvestmentGroup
- `StructuredProduct.groups` (To Many) → InvestmentGroup

**群組管理視圖功能：**
- ✅ 按投資類型分類顯示群組
- ✅ 創建新群組（輸入名稱）
- ✅ 編輯群組（Sheet 編輯介面）
- ✅ 刪除群組（編輯介面刪除）
- ✅ 從群組中移除項目
- ✅ 自動計算群組總金額
  - 美股/台股：`currentPrice × shares`
  - 債券：`currentValue`
  - 結構型：`transactionAmount`
- ✅ 拖放功能（drag & drop）
- ✅ 響應式更新（FetchRequest 自動刷新）
- ✅ iCloud 同步支援
- ✅ 項目計數顯示
- ✅ 展開/收合群組

**實作細節：**
- 群組列表使用 `FetchRequest` 動態載入，按 `createdDate` 排序
- 項目關係使用 `NSSet` 管理多對多關係
- 金額計算使用 `reduce` 函數加總
- 拖放使用 `NSItemProvider` 傳遞 objectID URI
- 震動回饋（UIImpactFeedbackGenerator）
- 內嵌在投資卡片展開內容中

**QuickUpdateView 整合（美股示例）：**
```swift
// 新增群組按鈕
Button(action: {
    currentGroupType = "usStock"
    showingAddGroupDialog = true
}) {
    HStack {
        Image(systemName: "folder.badge.plus")
        Text("新增群組")
    }
}

// 顯示所有群組（可展開/拖放）
ForEach(Array(usStockGroups), id: \.objectID) { group in
    InvestmentGroupRowView(
        group: group,
        groupType: .usStock,
        onEdit: { showingEditGroup = group },
        onDropItem: { item in addItemToGroup(item: item, group: group) },
        onUpdate: { saveContext() },
        onDeleteItem: { item in deleteStock(item as! USStock) }
    )
}

// 未分組項目（可拖曳）
ForEach(ungroupedStocks) { stock in
    ExpandableStockRow(stock: stock, ...)
        .onDrag {
            // 震動回饋 + 傳遞 objectID
        }
}
.onDrop { providers in
    handleDropToRemoveFromGroup(providers: providers)
}
```

**功能狀態：**
- ✅ Core Data 模型建立
- ✅ 群組 CRUD 功能
- ✅ 拖放操作介面
- ✅ 自動計算總金額
- ✅ 在投資列表內嵌顯示群組
- ✅ 群組展開/收合
- ✅ 項目可拖曳進出群組
- ✅ 震動回饋
- ✅ 美股群組功能完整實作
- ✅ 台股群組功能完整實作
- ⏳ 債券群組功能（待開發）
- ⏳ 結構型商品群組功能（待開發）

**資料遷移：**
- 新實體不影響現有資料
- 舊用戶的投資數據完全相容
- 群組功能為選擇性使用

---

### 4. 公司債明細
**位置：** `CorporateBondsDetailView.swift`、`CorporateBondsInventoryView.swift`、`EditCorporateBondView.swift`、`AddMonthlyDataView.swift`
**資料實體：** `CorporateBond`

**功能清單：**
- ✅ 記錄公司債投資
- ✅ 追蹤利息收入
- ✅ 到期日提醒
- ✅ 計算收益率（殖利率、單次配息、年度配息自動計算）
- ✅ **幣別支援**（USD、TWD、EUR、JPY、GBP、CNY、AUD、CAD、CHF、HKD、SGD）
- ✅ **配息月份選擇**
  - 半年配：1月&7月、2月&8月...等 6 種
  - 季配：1/4/7/10月、2/5/8/11月、3/6/9/12月
- ✅ CSV 匯入匯出
- ✅ 欄位排序
- ✅ **表格顯示優化**（2025-11-25 新增）
  - 欄位寬度調整，確保文字完整顯示
  - 字體大小優化為 14pt
  - 文字自動截斷（超過長度顯示...）
  - 債券名稱欄位加寬至 180pt
- ✅ **加總行顯示**（2025-11-25 新增）
  - 底部自動顯示「合計」行
  - 顯示申購金額、交易金額、已領利息、現值、報酬率的總和
  - 報酬率計算公式：((現值 - 交易金額 + 已領利息) / 交易金額) × 100
  - 總額數字使用粗體並加上底線（藍色/綠色/紅色依數值而定）
  - 淡藍色背景區隔
  - 自動更新（新增/編輯/刪除債券時）
- ✅ **庫存視圖功能**（`CorporateBondsInventoryView.swift`）（2025-11-25 新增）
  - **兩行標題佈局**
    - 第一行：總成本、總現值
    - 第二行：總已領利息、報酬率
  - **展開式編輯設計**（`BondInventoryRow.swift`）
    - 點擊債券卡片向下展開編輯表單（與美股風格一致）
    - 摺疊時顯示：債券名稱、幣別、成本、報酬率、現值、已領利息
    - 右側顯示向上/向下箭頭圖示
    - 展開後可直接編輯欄位：
      - 債券名稱、幣別
      - 現值、已領利息
      - 票面利率、殖利率
    - 展開區域底部有「刪除此債券」按鈕
    - 所有變更即時保存，自動更新總計
  - **重新計算報酬率** (2025-11-25 新增)
    - 用戶手動輸入各債券現值後使用
    - 自動計算所有債券報酬率
    - 公式: ((現值 - 交易金額 + 已領利息) / 交易金額) × 100
    - 更新標題區域總值和總報酬率
    - 顯示計算結果摘要
  - **從月度資產更新** (2025-11-25 強化)
    - 讀取月度資產的總現值 (bonds)
    - 讀取月度資產的總已領利息 (confirmedInterest)
    - 按成本比例分配現值到各債券
    - 按成本比例分配已領利息到各債券
    - **不會**重新計算個別債券報酬率 (保持原有數據)
    - 更新標題區域總值顯示
  - **同步至月度資產**
    - 將總現值和總成本同步至最新月度資產
  - **同步到公司債明細** (2025-11-25 新增)
    - 保存所有編輯變更
    - 確保數據同步到公司債明細表格
    - 更新標題區域總值顯示
- ✅ **客戶專屬債券資料儲存** (2025-12-01 新增)
  - **問題修復：** 修正 @AppStorage 全域性錯誤，防止不同客戶資料互相覆蓋
  - **實作方式：**
    - 將 `bondEditMode`、`bondsTotalValue`、`bondsTotalInterest` 從 @AppStorage 改為 @State
    - 使用客戶專屬的 UserDefaults 鍵值：`bondEditMode_\(clientID)`
    - 自動載入/儲存各客戶專屬的債券資料
    - 切換客戶時自動載入該客戶的資料
  - **影響檔案：**
    - `CustomerDetailView.swift`：儀表板主視圖
    - `QuickUpdateView.swift`：快速更新視圖
    - `CorporateBondsInventoryView.swift`：債券庫存視圖
  - **匯率資料：** 保持全域共用（所有客戶使用相同匯率）
- ✅ **債券批次更新架構重構 - 橘色行資料儲存方案** (2025-12-01 最新)
  - **問題修復：** 完全解決橘色行資料亂串問題，改用類似合計行的穩定架構
  - **技術決策：** 放棄 CoreData 橘色行記錄，改用 UserDefaults
  - **實作方式：**
    - **舊方案（已廢棄）：** 使用 CoreData 特殊記錄 `bondName = "__BATCH_UPDATE__"` 儲存批次更新資料
      - 問題：手動查詢時機不穩定，client 為 nil 時會取到其他客戶的橘色行記錄
      - 現象：資料亂串、橘色行顯示錯誤、切換客戶時資料殘留
    - **新方案（穩定）：** 使用客戶專屬的 UserDefaults 鍵值儲存
      - `bondsTotalValue_\(clientID)` - 儲存總現值（批次更新模式）
      - `bondsTotalInterest_\(clientID)` - 儲存總已領利息（批次更新模式）
      - 每個客戶擁有獨立的 key，完全隔離資料
      - 同步讀寫，無 CoreData 查詢時機問題
  - **架構優點：**
    - 簡單穩定，類似合計行（藍色行）的 @FetchRequest 穩定模式
    - 每個客戶獨立鍵值，絕對不會資料混亂
    - 無需複雜的 CoreData 查詢與 client 判斷邏輯
    - 即時讀寫，無延遲或時機問題
  - **影響檔案與變更：**
    - `CorporateBondsInventoryView.swift` (lines 61-88)
      - 移除 `getBatchUpdateBond()` CoreData 查詢邏輯
      - 新增 `clientSpecificTotalValueKey` 和 `clientSpecificTotalInterestKey` 屬性
      - 新增 `loadBatchData()` 和 `saveBatchData()` 方法
      - 儲存按鈕觸發 `saveBatchData()` 寫入 UserDefaults
    - `QuickUpdateView.swift` (lines 106-139)
      - 同樣新增客戶專屬 key 和讀寫方法
      - `onAppear` 載入資料、`onChange` 自動儲存
    - `CustomerDetailView.swift` (lines 2731-2744, 2755-2760)
      - 移除 `@FetchRequest batchUpdateBond` 和橘色行初始化邏輯
      - 移除 `getBatchUpdateBond()` 函式
      - 新增 `getBatchTotalValue()` 和 `getBatchTotalInterest()` 從 UserDefaults 讀取
      - 報酬率和債券金額計算直接從 UserDefaults 讀取
    - `CorporateBondsDetailView.swift` (lines 76-89, 114, 537-538, 672-725)
      - 新增 `getBatchTotalValue()` 和 `getBatchTotalInterest()` UserDefaults 讀取方法
      - FetchRequest 加入 `bondName != "__BATCH_UPDATE__"` 過濾條件，隱藏舊橘色行記錄
      - 重寫 `batchUpdateRow()` 函式，改為從 UserDefaults 讀取資料顯示
      - 移除對 CoreData 橘色行物件的依賴
  - **舊資料處理：**
    - 舊的 CoreData 橘色行記錄（`bondName = "__BATCH_UPDATE__"`）不會被刪除
    - 透過 FetchRequest predicate 過濾隱藏，不影響新架構運作
    - 用戶可自行選擇保留或刪除舊記錄
  - **使用者體驗改善：**
    - ✅ 修復資料亂串問題：每個客戶資料完全隔離
    - ✅ 橘色行即時更新：儲存後立即顯示正確數值
    - ✅ 切換客戶順暢：無資料殘留或混亂
    - ✅ 架構穩定可靠：類似藍色合計行的穩定模式
- ✅ **SwiftUI View 快取問題修正 - 強制重建機制** (2025-12-01 最終修正)
  - **問題修復：** 解決 SwiftUI 快取導致切換客戶時 view 未重建，造成資料殘留亂串
  - **根本原因分析：**
    - **SwiftUI Sheet 快取：** sheet 內的 view 可能被 SwiftUI 重用，不會自動重建
    - **TabView 預載快取：** TabView 會預先載入所有頁面並快取，切換客戶時不會重建頁面
    - **onChange 連鎖觸發：** loadBatchData() 更新 @State → 觸發 onChange → 在載入完成前就儲存舊資料
  - **解決方案：**
    - **方案 1：強制 View 重建（`.id()` modifier）**
      - 在所有包含客戶資料的 sheet 和 view 加上 `.id(client.objectID)`
      - SwiftUI 會在 client 變更時強制銷毀舊 view 並建立新 view
      - 確保每個客戶都有完全獨立的 view instance
    - **方案 2：防止載入時觸發儲存（`isLoadingBondData` 標記）**
      - 新增 `@State private var isLoadingBondData: Bool = false` 標記
      - 載入時設定 `isLoadingBondData = true`，完成後設定為 `false`
      - onChange 檢查標記，載入中不執行儲存
  - **實作細節：**
    - **CustomerDetailView.swift**
      - Line 218: CorporateBondsInventoryView sheet 加上 `.id(client.objectID)`
      - Line 224: QuickUpdateView 加上 `.id(client.objectID)`
      - Line 226: **TabView 本身**加上 `.id(client.objectID)` - 關鍵修正！
    - **QuickUpdateView.swift**
      - Line 87: 新增 `isLoadingBondData` 標記
      - Lines 120-124: loadBatchData() 設定/解除標記
      - Lines 394-407: onChange handlers 檢查標記才儲存
      - 移除無效的 `onChange(of: client.objectID)`（client 是常數不會變）
    - **AddMonthlyDataView.swift**
      - Line 373-377: CorporateBondsInventoryView sheet 加上 `if let` 解開 optional 並加 `.id()`
    - **CorporateBondsInventoryView.swift**
      - Line 82: loadBatchData() 後立即呼叫 updateEditableValues()
      - 加強 debug log 顯示完整 clientID key
  - **為何 TabView 需要 .id()：**
    - TabView 使用預載機制，所有頁面（包括 QuickUpdateView）都會預先建立並保留在記憶體中
    - 即使單一頁面有 `.id()`，TabView 容器本身沒有 `.id()` 就會重用整個結構
    - 必須在 TabView 層級加上 `.id()` 才能強制整個頁面結構重建
  - **資料流程（修正後）：**
    1. 使用者從客戶 A 切換到客戶 B
    2. TabView 檢測到 `.id(client.objectID)` 改變
    3. 銷毀整個舊 TabView（包括所有頁面）
    4. 建立新 TabView 與新的 QuickUpdateView(client: B)
    5. 新 view 的 `onAppear` 觸發
    6. `loadBatchData()` 設定 `isLoadingBondData = true`
    7. 從 UserDefaults 載入客戶 B 的資料到 @State
    8. @State 變更觸發 onChange，但檢查到 `isLoadingBondData = true` → **不儲存**
    9. `loadBatchData()` 設定 `isLoadingBondData = false` 完成
    10. 之後使用者編輯才會正常觸發儲存
  - **測試驗證：**
    - ✅ 債券小卡更新：不會亂串（已驗證）
    - 🔄 左滑輸入區更新：待使用者測試
- ✅ **債券實時計算與多幣別支援** (2025-12-01 強化)
  - **儀表板小卡顯示**（`CustomerDetailView.swift`）
    - 債券金額和報酬率改為從 CorporateBond 持倉實時計算
    - 支援批次更新和逐一更新兩種模式
    - 外幣債券自動折合美金（支援 11 種貨幣）
    - **批次更新模式：** 使用手動輸入的總現值和總利息
    - **逐一更新模式：** 從各債券明細加總計算
  - **貨幣轉換計算**
    - 成本計算：`calculateBondsTotalCost()` - 將所有債券成本折合美金
    - 現值計算：`calculateBondsTotalCurrentValue()` - 將所有債券現值折合美金
    - 利息計算：`calculateBondsTotalReceivedInterest()` - 將所有債券利息折合美金
    - 報酬率公式：`((總現值 + 總利息) - 總成本) / 總成本 * 100`
  - **資料來源切分**
    - ✅ 債券小卡（金額、報酬率）：實時計算
    - ✅ 資產配置圖表：讀取月度資產明細
    - ✅ 走勢圖：讀取月度資產明細
- ✅ **債券批次更新歷史記錄架構 - 完全重構** (2025-12-01 最新)
  - **問題根源：** 放棄 UserDefaults 橘色行方案，改用 CoreData 歷史記錄表，徹底解決資料串接問題
  - **核心概念：** 不再依賴單一「當前值」，改為保存完整歷史記錄，提供審計追蹤
  - **新架構設計：**
    - **新增 CoreData Entity：`BondUpdateRecord`**
      - `recordDate: Date?` - 記錄日期
      - `totalCurrentValue: String` - 總現值快照
      - `totalInterest: String` - 總已領利息快照
      - `createdDate: Date?` - 建立時間（可選）
      - `client: Client` - 所屬客戶關聯
    - **Client Entity 新增關聯**
      - `bondUpdateRecords` (To Many) → BondUpdateRecord
      - Cascade 刪除：客戶刪除時自動刪除所有記錄
  - **CorporateBondsInventoryView 批次更新模式 UI 設計**
    - **頂部資訊卡片佈局（2x2 Grid）**
      - 第一行：總成本（左上）| 報酬率（右上）
      - 第二行：總現值（左下，橙色背景提示）| 總已領利息（右下，橙色背景提示）
      - 輸入欄位使用 `Color.orange.opacity(0.12)` 背景凸顯
      - 報酬率顯示：綠色（正報酬）或紅色（負報酬）
    - **模式切換器：** 「更新總額、總利息」vs「逐一更新現值、已領息」
    - **儲存按鈕：** 位於模式切換器下方
      - 綠色漸層背景，全寬顯示
      - Icon + 文字：「儲存記錄」
      - 只在批次更新模式顯示
    - **歷史記錄表格區域**
      - 標題列：「最近 12 筆」+ 藍色 + 按鈕（新增空白記錄）
      - 表頭：日期 | 總現值 | 總已領利息
        - 背景：`Color(white: 0.95)` 淺灰色（區分於白色背景）
      - 記錄行：顯示最近 12 筆，按日期降序
      - **互動操作：**
        - 點擊記錄 → 直接打開編輯 sheet
        - 左滑 → 顯示刪除按鈕（紅色）和編輯按鈕（藍色）
        - 完全滑動可直接刪除
      - 編輯 sheet：兩個輸入欄位（總現值、總已領利息）+ 保存/取消按鈕
      - 空狀態提示：引導用戶點擊保存按鈕創建第一筆記錄
    - **逐一更新模式：** 顯示債券庫存列表（與原有一致）
  - **報酬率計算邏輯**
    - **批次更新模式：** 使用最新的 `BondUpdateRecord` 計算
      - 公式：`((總現值 + 總已領利息) - 總成本) / 總成本 * 100`
    - **無記錄時：** 回退到 UserDefaults（向下兼容）
    - **逐一更新模式：** 從各債券明細加總計算
  - **儀表板顯示**
    - `getBondsValue()` 和 `getBondsTotalReturnRate()` 更新
    - 優先讀取最新 `BondUpdateRecord`
    - 無記錄時回退到 UserDefaults 或個別計算
  - **QuickUpdateView 整合**
    - 左滑輸入區債券編輯按鈕直接打開 `CorporateBondsInventoryView`
    - 與債券小卡保持完全一致的體驗
  - **CorporateBondsDetailView 清理**
    - 移除橘色行顯示邏輯
    - 移除 `batchUpdateRow()` 函數
    - 保留 `__BATCH_UPDATE__` 過濾條件隱藏舊記錄
  - **架構優勢：**
    - ✅ 資料穩定性：CoreData 關聯確保資料不會串接
    - ✅ 歷史追蹤：完整保留每次更新記錄
    - ✅ 審計透明：表格直接顯示歷史，可隨時查看和修改
    - ✅ 一致性：遵循現有表格模式（MonthlyAsset、Bond 等）
    - ✅ 向下兼容：保留 UserDefaults 讀取作為備援
    - ✅ 直觀編輯：點擊即編輯、左滑刪除、+ 按鈕新增
    - ✅ 視覺引導：橙色背景提示輸入欄位、淺灰表頭區分內容
  - **使用流程：**
    1. 在債券小卡切換到「更新總額、總利息」模式
    2. 輸入總現值和總已領利息（橙色背景欄位）
    3. 點擊綠色「儲存記錄」按鈕
    4. 記錄立即顯示在底部歷史記錄表格第一行
    5. 點擊記錄直接編輯，或左滑刪除/編輯
    6. 點擊「最近 12 筆」旁的 + 按鈕可新增空白記錄
    7. 儀表板報酬率自動使用最新記錄計算
  - **影響檔案：**
    - `DataModel.xcdatamodel` - 新增 BondUpdateRecord entity
    - `CorporateBondsInventoryView.swift` - 完整重構批次更新 UI 與互動
    - `QuickUpdateView.swift` - 債券編輯按鈕改為打開完整小卡頁面
    - `CustomerDetailView.swift` - 讀取邏輯更新為優先使用 BondUpdateRecord
    - `CorporateBondsDetailView.swift` - 移除橘色行邏輯
  - **技術實作：**
    - 使用 `@FetchRequest` 查詢 BondUpdateRecord（按 recordDate 降序）
    - 視圖拆分避免編譯器類型檢查超時（`tableHeaderView`、`recordsListView` 等）
    - NSManagedObject 自動實現 Identifiable（透過 objectID）
    - 編輯介面使用 `.sheet(item:)` 綁定 optional BondUpdateRecord
    - 點擊手勢：`.onTapGesture` → 打開編輯 sheet
    - 滑動操作：`.swipeActions` → 刪除（紅色）、編輯（藍色）
    - 新增記錄：`addNewRecord()` 創建 totalCurrentValue="0"、totalInterest="0" 的空白記錄
    - 輸入欄位提示：`padding(8) + background(Color.orange.opacity(0.12)) + cornerRadius(6)`
    - 表頭對比：`background(Color(white: 0.95))` 淺灰色

**表格欄位順序：**
申購日 → 債券名稱 → **幣別** → 票面利率 → 殖利率 → 申購價 → 申購金額 → 持有面額 → 前手息 → 交易金額 → 現值 → 已領利息 → 含息損益 → 報酬率 → 配息月份 → 單次配息 → 年度配息

**輸入欄位（申購時）：**
- 申購日、債券名稱、幣別
- 票面利率、申購價、持有面額、前手息
- 配息月份

**自動計算欄位：**
- 殖利率 = 年度配息 ÷ 交易金額
- 申購金額 = 申購價 × 持有面額 ÷ 100
- 交易金額 = 申購金額 + 前手息
- 單次配息 = 票面利率 × 持有面額 ÷ 2
- 年度配息 = 單次配息 × 2

**注意：** 損益資訊（現值、已領利息、含息損益、報酬率）在申購時無需輸入，可在公司債明細表格中後續更新。

---

### 5. 結構型商品
**位置：** `StructuredProductsDetailView.swift`
**資料實體：** `StructuredProduct`

**功能清單：**
- ✅ 管理進行中的結構型商品
- ✅ 支援 1-4 個標的（每個商品可選擇標的數量）
- ✅ 自動抓取美股股價（需輸入正確股票代碼）
- ✅ 計算距離出場比例（現價 ÷ 期初價 × 100）
- ✅ **自動計算執行價和保護價**
- ✅ 出場後自動移至「已出場」分類
- ✅ 年份分類管理（建議：2024、2025）

**4 個標的欄位：**
- `target1-4`：標的代碼
- `initialPrice1-4`：期初價格
- `strikePrice1-4`：執行價格
- `protectionPrice1-4`：保護價
- `currentPrice1-4`：現價
- `distanceToExit1-4`：距離出場%

**自動計算公式：**
```
執行價 = 期初價格 × (PUT% / 100)
保護價 = 期初價格 × (KI% / 100)
距離出場% = (現價 / 期初價格) × 100
```

**觸發計算時機：**
- 輸入/修改期初價格時
- 輸入/修改 PUT% 時
- 輸入/修改 KI% 時

**新增欄位：**
- `productCode`：商品代號
- `putPercentage`：PUT%
- `kiPercentage`：KI%

**重要提醒：**
- ⚠️ 務必輸入正確的美股代號才能更新股價
- ⚠️ 點擊「更新」按鈕自動更新股票現值
- ⚠️ 輸入 PUT%/KI% 後會自動計算執行價/保護價

---

### 6. 美股投資
**位置：** `USStockInventoryView.swift`、`USStockDetailView.swift`
**資料實體：** `USStock`
**股價服務：** `StockPriceService.swift`

**功能清單：**
- ✅ 記錄美股持倉
- ✅ 自動抓取最新股價（Yahoo Finance API）
- ✅ 計算報酬率、未實現損益
- ✅ 與貸款數據同步（`USStockLoanSyncSelectionView.swift`）
- ✅ **加總行顯示**（2025-11-25 新增）
  - 底部自動顯示「合計」行
  - 顯示成本、市值、損益、報酬率的總和
  - 報酬率計算公式：(損益 / 成本) × 100
  - 總額數字使用粗體並加上底線（藍色/綠色/紅色依數值而定）
  - 淡藍色背景區隔
  - 自動更新（新增/編輯/刪除股票時）

**API 來源：**
- Yahoo Finance: `https://query1.finance.yahoo.com/v8/finance/chart/{symbol}`

---

### 7. 台股投資
**位置：** `TWStockInventoryView.swift`、`TWStockDetailView.swift`
**資料實體：** `TWStock`

**功能清單：**
- ✅ 記錄台股持倉
- ✅ 自動抓取台股股價
- ✅ 計算報酬率
- ✅ 與貸款數據同步（`TWStockLoanSyncSelectionView.swift`）

---

### 8. 定期定額
**位置：** `RegularInvestmentInventoryView.swift`
**資料實體：** `RegularInvestment`

**功能清單：**
- ✅ 新增定期定額標的（`AddRegularInvestmentView.swift`）
- ✅ 記錄損益與投入狀況
- ✅ 同步到月度資產
- ✅ 自動投入檢查（依週期自動計算）
- ✅ 週期設定（每月、每季、每半年等）

**使用方式：**
- 點擊「定期定額」進入管理頁面
- 點擊「+」新增標的
- 記錄每次投入金額與現值
- 可同步數據到月度資產表

---

### 9. 損益表（Profit/Loss Table）
**位置：** `ProfitLossTableView.swift`

**功能清單：**
- ✅ 顯示整體投資損益
- ✅ 分類顯示（美股、台股、債券、結構型）
- ✅ 時間區間篩選

---

### 10. 保險管理
**位置：** `InsurancePolicyView.swift`、`InsuranceCalculatorView.swift`
**資料實體：** `InsurancePolicy`
**相關文件：**
- `保險功能使用指南.md`
- `保險試算表功能說明.md`
- `OCR_Implementation_Guide.md`

**功能清單：**
- ✅ 新增保單資料（`AddInsurancePolicyView.swift`）
- ✅ 編輯保單（`EditInsurancePolicyView.swift`）
- ✅ **OCR 保單辨識**（`InsuranceOCRManager.swift`）
  - 拍照辨識保單資訊
  - 區域選取辨識（`ImageRegionSelector.swift`）
  - 批次保單處理（`MultiplePoliciesReviewView.swift`）
- ✅ **試算表計算器**（`InsuranceCalculatorView.swift`）
  - 保費試算
  - IRR 計算
  - 表格解析（`CalculatorTableParser.swift`）
  - 詳細檢視（`CalculatorTableDetailView.swift`）

**OCR 技術：**
- Vision Framework（Apple 原生）
- LiveText 整合（`LiveTextImageView.swift`）
- 區域 OCR（`RegionOCRManager.swift`）

**試算表功能：**
- 📄 參考：`README_試算表功能啟用.md`
- 📄 說明：`表格辨識功能說明.md`
- 🐛 除錯：`表格辨識除錯指南.md`

---

### 10. 貸款管理
**位置：** `LoanManagementView.swift`、`LoanDetailView.swift`
**資料實體：** `Loan`、`LoanRateAdjustment`、`LoanMonthlyData`

**功能清單：**
- ✅ 新增貸款（`AddLoanView.swift`）
- ✅ 貸款詳情（`LoanDetailView.swift`）
- ✅ 利率調整記錄（`AddLoanRateAdjustmentView.swift`）
- ✅ 月度還款資料（`AddLoanMonthlyDataView.swift`）
- ✅ 月度資料表格（`LoanMonthlyDataTableView.swift`）
- ✅ 貸款與投資概覽圖表（`LoanInvestmentOverviewChart.swift`）
- ✅ 編輯貸款金額（`EditLoanAmountsView.swift`）

**支援貸款類型：**
- 一般貸款
- 寬限期貸款
- 利率調整貸款

---

### 12. 提醒功能
**位置：** `ReminderDashboardView.swift`

**功能清單：**
- ✅ 公司債配息提醒
- ✅ 保費繳納提醒
- ✅ 月份分頁顯示（當月 + 未來兩個月）
- ✅ **幣別顏色區分**（每種幣別顯示不同顏色）
  - USD: 綠色、TWD: 藍色、EUR: 紫色
  - JPY: 橘色、GBP: 粉紅、CNY: 紅色
  - AUD: 黃色、CAD: 薄荷、CHF: 靛青
  - HKD: 青色、SGD: 藍綠

**提醒卡片顯示：**
- 客戶名稱、債券/保單名稱
- 配息/保費金額
- 幣別標籤

---

### 13. 教學導覽與版本更新
**位置：**
- `OnboardingView.swift`（首次使用）
- `DashboardTutorialView.swift`（儀表板）
- `StructuredProductTutorialView.swift`（結構型商品）
- `InsuranceTutorialView.swift`（保險功能）
- `WhatsNewView.swift`（版本更新介紹）⭐ **新增**
- `TooltipManager.swift`、`TooltipOverlayView.swift`、`TooltipStep.swift`

**功能清單：**
- ✅ 首次使用引導
- ✅ 功能提示（Tooltip）
- ✅ 分頁式教學
- ✅ 支援圖片 + 文字說明
- ✅ **截圖教學（已實作）** - 混合使用截圖與圖標
- ✅ **版本更新介紹（已實作）** - 自動檢測版本變更並顯示新功能 ⭐ **新增**

**教學截圖資源：**
- `tutorial_menu` - 客戶管理選單畫面
- `tutorial_add_customer` - 新增客戶表單
- `tutorial_dashboard` - 客戶管理主畫面
- `tutorial_dashboard_1` - 儀表板主畫面（+按鈕）
- `tutorial_dashboard_2` - 輸入資產資料表單
- `tutorial_dashboard_3` - 投資卡片（美股/台股/債券）
- `tutorial_dashboard_4` - 更新股價並同步選單
- `tutorial_structured_1` - 結構型明細表格（點選+按鈕）
- `tutorial_structured_2` - 選擇標的數量
- `tutorial_structured_3` - 輸入商品基本訊息
- `tutorial_structured_4` - 更新按鈕和距離出場%
- `tutorial_structured_5` - 出場按鈕
- `tutorial_structured_6` - 選擇分類
- `tutorial_structured_7` - 結構型已出場表格

**儀表板功能教學步驟：**
1. 點擊右上角＋按鈕，每次與客戶碰面前先輸入當前狀況
2. 輸入的資料會記錄在月度資產明細表格中（月度資產是投資項目的總額）
3. 儀表板顯示各類投資的現值與報酬率
4. 美股／台股卡片中可自動更新股價，更新後可同步到月度資產

**結構型商品教學步驟：**
1. 結構型明細點選＋按鈕
2. 選擇連結幾組標的（1-4個）
3. 輸入商品基本訊息：起單日、利率、期初價格、執行價格
4. 點選綠色更新按鈕，自動更新距離出場％
5. 當產品結束，點選最右手邊出場按鈕，新增分類（建議年度分類）
6. 已出場產品分類至結構型已出場，這邊只需要輸入實際收益即可

**設計策略：**
- 第 1 頁：使用圖標（歡迎畫面）
- 第 2-4 頁：使用實際截圖（操作示範）
- 第 5-6 頁：使用圖標（說明性質）

---

#### 🆕 版本更新介紹系統
**位置：** `WhatsNewView.swift`、`InvestmentDashboardApp.swift`
**版本管理：** `AppVersionManager`（單例模式）
**相關文件：** `🔄_版本更新管理.md`

**功能說明：**
- ✅ **自動版本檢測**：app 啟動時自動比對 `CFBundleShortVersionString`
- ✅ **首次安裝檢測**：首次安裝時顯示歡迎畫面
- ✅ **版本變更提示**：版本號變更時自動顯示新功能介紹
- ✅ **查看狀態記錄**：使用 `UserDefaults` 記錄已查看的版本
- ✅ **精美展示頁面**：全屏 modal，包含版本號、功能卡片、開始使用按鈕

**核心組件：**

1. **AppVersionManager (lines 12-59)**
   - `currentVersion`：讀取 Bundle 中的版本號
   - `shouldShowWhatsNew()`：判斷是否需要顯示
   - `markWhatsNewAsSeen()`：標記已查看
   - `resetWhatsNew()`：重置狀態（測試用）

2. **WhatsNewView (lines 74-183)**
   - 顯示 app 圖示和版本號
   - 功能列表（可動態調整）
   - 「開始使用」按鈕（關閉並標記已查看）

3. **WhatsNewFeature (lines 63-70)**
   - `icon`：SF Symbols 圖示名稱
   - `iconColor`：圖示顏色
   - `title`：功能標題
   - `description`：功能描述
   - `image`：可選截圖（未來可用）

4. **FeatureCard (lines 187-219)**
   - 漂亮的卡片式設計
   - 圖示 + 標題 + 描述
   - 圓角、陰影效果

**整合方式：**
```swift
// InvestmentDashboardApp.swift (lines 14-38)
@StateObject private var versionManager = AppVersionManager.shared
@State private var showWhatsNew = false

.onAppear {
    if versionManager.shouldShowWhatsNew() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showWhatsNew = true
        }
    }
}
.sheet(isPresented: $showWhatsNew) {
    WhatsNewView()
}
```

**使用流程：**
1. 用戶更新 app → 啟動 app
2. 系統檢測到版本變更 → 延遲 0.5 秒
3. 以 sheet 方式顯示 WhatsNewView
4. 用戶閱讀新功能 → 點擊「開始使用」
5. 系統記錄該版本已查看 → 下次不再顯示

**管理新功能：**
- 每次版本更新時，編輯 `WhatsNewView.swift` 的 `features` 陣列
- 參考 `🔄_版本更新管理.md` 管理歷史版本的功能列表
- 支援添加截圖：將 `image: nil` 改為實際圖片名稱

**最後更新：** 2025-12-02 - 新增版本更新介紹系統 ⭐

---

### 14. 浮動選單按鈕（跨客戶操作）
**位置：** `FloatingMenuButton.swift`
**相關視圖：** `ContentView.swift`

**功能清單：**
- ✅ 半透明浮動按鈕（三個垂直點）
- ✅ 可拖曳並自動吸附到螢幕邊緣
- ✅ 兩層選單：商品類別 → 新增/庫存
- ✅ 跨客戶搜尋庫存（結構型/美股/台股）
- ✅ 批次新增功能

**結構型商品批次新增流程：**
1. 選擇客戶（多選）
2. 輸入各客戶交易金額
3. 選擇標的數量（1-4個）
4. 輸入詳細資料：
   - 基本資料：商品代號、交易定價日、發行日、最終評價日
   - 利率參數：年化利率（自動算月利率）、PUT%、KI%
   - 標的資訊（表格式）：代號、期初價、執行價、保護價
5. 儲存到各客戶的結構型商品明細

**自動計算功能：**
- 月配息率 = 年化利率 ÷ 12
- 執行價 = 期初價 × PUT%
- 保護價 = 期初價 × KI%
- 支援自動取得股價（輸入代號後點「取得價格」）

**跨客戶搜尋視圖：**
- `CrossClientStructuredProductView` - 結構型商品搜尋
  - 支援按商品代號/客戶名排序
  - **更新股價按鈕**：一次更新所有客戶的結構型商品股價
  - **股價更新提示**：顯示成功更新的股票檔數
  - **按商品排序顯示格式**：
    - 第一行：股票代碼與距離出場%
    - 第二行：利率、發行日、到期日
    - 第三行：PUT、KI
    - 第四行：客戶名稱與金額
  - **按客戶排序顯示格式**：
    - 第一行：股票與距離出場%
    - 第二行：金額、利率
    - 第三行：發行日、到期日
    - 第四行：PUT、KI
- `CrossClientUSStockView` - 美股搜尋
  - **更新股價按鈕**：一次更新所有客戶的美股現價、市值、報酬率
  - **更新到月度資產按鈕**：將美股市值同步到所有客戶的月度資產
  - 顯示：客戶名、股數、成本（千分位）、現值（千分位）、報酬率
  - 報酬率公式：(現值 - 成本) / 成本 × 100
- `CrossClientTWStockView` - 台股搜尋
  - **更新股價按鈕**：一次更新所有客戶的台股現價、市值、報酬率
  - **更新到月度資產按鈕**：將台股市值同步到所有客戶的月度資產
  - 顯示：客戶名、股數、成本（千分位）、現值（千分位）、報酬率
  - 報酬率公式：(現值 - 成本) / 成本 × 100

**批次新增視圖：**
- `BatchAddStructuredProductView` - 結構型商品批次新增
- `BatchAddStockView` - 美股/台股批次新增

**美股/台股批次新增流程：**
1. **步驟 1/2：** 選擇客戶（多選）
2. **步驟 2/2：** 輸入股票資訊及各客戶股數
   - 股票代號（自動轉大寫）
   - 成本單價
   - 為每個客戶輸入股數
   - 即時顯示總成本計算預覽
3. 自動計算並儲存：
   - 成本 = 股數 × 成本單價
   - 初始市值 = 成本（初始當前價格設為成本單價）
   - 初始損益 = 0
   - 初始報酬率 = 0%
   - 幣別：美股固定為 USD，台股固定為 TWD

**重要提示：**
- ⚠️ 最終成本不含手續費，需在明細頁面手動調整
- 初始當前價格等於成本單價，可透過「刷新股價」功能更新

**最後更新：** 2025-12-02 - 簡化美股/台股批次新增為兩步驟，移除當前價格和幣別選擇，合併輸入流程

---

### 15. 訂閱功能（付費功能）
**位置：** `SubscriptionManager.swift`、`SubscriptionView.swift`
**設定檔：** `Configuration.storekit`
**相關文件：**
- `訂閱功能配置指南.md`
- `訂閱策略說明.md`

**功能清單：**
- ✅ StoreKit 2 整合
- ✅ 訂閱狀態管理
- ✅ 付費功能解鎖
- ✅ 本地測試環境

---

### 16. 備份與還原功能
**位置：** `BackupManager.swift`、`ContentView.swift`
**權限設定：** `InvestmentDashboard.entitlements`

**功能清單：**
- ✅ 匯出備份檔案（JSON 格式）
- ✅ 透過分享表單儲存到任意位置
- ✅ 從備份檔案還原資料
- ✅ 顯示最近備份時間

**備份使用方式：**
1. 點擊左上角「?」按鈕
2. 選擇「備份到 iCloud」
3. **分享表單彈出**，可選擇：
   - 「儲存到檔案」→ iCloud 雲碟、本機或其他位置
   - AirDrop 傳輸到其他裝置
   - 其他 App

**還原使用方式：**
1. 點擊左上角「?」按鈕
2. 選擇「從 iCloud 還原」
3. 確認還原
4. **文件選擇器彈出**，選擇備份的 JSON 檔案
5. 自動還原資料

**備份檔案格式：**
`InvestmentDashboard_backup_年-月-日_時-分-秒.json`

**與 CloudKit 的差異：**
- **CloudKit**：自動即時同步，Development/Production 環境分離
- **備份功能**：手動匯出 JSON 檔案，可自由選擇儲存位置

**適用情境：**
- 從 Xcode 安裝版本遷移到 App Store 版本
- 手動備份重要資料
- 跨裝置手動傳輸資料（透過 AirDrop 或檔案分享）

**備份資料包含：**
- 客戶資料
- 月度資產
- 公司債
- 結構型商品
- 美股/台股
- 保單
- 貸款

---

## 🔧 開發指南

### 資料流與同步機制
📄 **文件：** `📊_資料串流順序.md`

**核心概念：**
- 三個核心區域：儀表板小卡區、表格明細區、左滑輸入區
- Core Data 自動同步機制
- @FetchRequest 的使用方式
- 強制刷新物件快取的技巧
- NotificationCenter 通知機制

**適用場景：**
- 新增資料更新功能
- 修復同步問題
- 理解資料流向
- Debug 資料不同步問題

---

### 計算公式總覽
📄 **文件：** `📐_計算公式總覽.md`

**涵蓋範圍：**
- 月度資產計算公式
- 股票投資公式（市值、損益、報酬率）
- 債券投資公式（殖利率、含息損益）
- 結構型商品公式（執行價、保護價、距離出場%）
- 保險試算公式（IRR）
- 貸款計算公式
- 匯率換算公式

**適用場景：**
- 新增財務計算功能
- 驗證計算邏輯正確性
- 了解各項數值的計算方式

---

### 匯率更新機制
📄 **文件：** `📊_匯率更新機制.md`

**核心功能：**
- 即時匯率更新（台灣銀行 API + ExchangeRate-API 雙重備援）
- 支援 10 種幣別（TWD, EUR, JPY, GBP, CNY, AUD, CAD, CHF, HKD, SGD）
- 自動計算折合美金（台股、台幣、多幣別現金）
- 工作日顯示機制（週末顯示上週五匯率日期）

**資料流程：**
- 台股折合美金：台股市值（TWD） ÷ 匯率 → 美金計價
- 多幣別折合美金：各幣別現金 ÷ 對應匯率 → 美金計價
- 投資項目匯率處理：僅儲存美金價值，不重複記載匯率

**重要說明：**
- 匯率更新後**自動連動**所有折合美金欄位
- **無條件更新所有幣別匯率**，解決投資項目幣別與現金幣別不一致問題
- 用戶點擊「保存至月度資產」才儲存至 Core Data

**適用場景：**
- 理解匯率更新流程
- 新增投資項目匯率支援
- 除錯折合美金計算問題
- 查看資料如何流入月度資產明細

**相關檔案：**
- `ExchangeRateService.swift` - 匯率 API 服務
- `QuickUpdateView.swift` - 快速更新頁面匯率更新邏輯
- `AddMonthlyDataView.swift` - 月度資產輸入頁面計算邏輯

---

### Core Data 設定
📄 **文件：** `Core_Data_設定步驟.md`
📄 **資料模型：** `DataModel.xcdatamodeld/`
📄 **控制器：** `PersistenceController.swift`

**重要步驟：**
1. 建立資料模型
2. 設定關聯關係
3. 啟用 CloudKit 同步
4. 版本遷移

**更新模型指南：**
📄 `更新Core_Data模型指南.md`

---

### CloudKit & iCloud 同步
📄 **文件：**
- `iCloud_Setup_Guide.md`
- `CloudKit_Index_Setup_Guide.md`

**設定步驟：**
1. 啟用 iCloud 容器
2. 設定 CloudKit Dashboard
3. 建立索引（Index）
4. 測試同步功能

**重要提醒：**
- ⚠️ 必須在 Developer Portal 設定 CloudKit
- ⚠️ 需要啟用 iCloud 權限（`InvestmentDashboard.entitlements`）

---

### OCR 實作
📄 **文件：** `OCR_Implementation_Guide.md`

**核心技術：**
- Vision Framework
- VNRecognizeTextRequest
- 區域選取辨識

**檔案位置：**
- `InsuranceOCRManager.swift`（保單 OCR）
- `RegionOCRManager.swift`（區域 OCR）
- `ImageRegionSelector.swift`（選取工具）

---

### 新增檔案到 Xcode
📄 **文件：**
- `加入檔案到Xcode.md`
- `新增檔案到Xcode指南.md`

**自動化腳本：**
- `add_files_to_xcode.rb`（Ruby 腳本）
- `add_files_modern.rb`（現代化版本）

**使用方式：**
```bash
ruby add_files_to_xcode.rb
```

---

### 編譯錯誤修復
📄 **文件：** `修復編譯錯誤.md`

**常見問題：**
1. 檔案未加入 target
2. 缺少必要 framework
3. 版本號問題
4. 簽章錯誤

---

## 🚀 上架部署

### App Store 上架準備
📄 **文件：** `上架準備清單.md`

**檢查清單：**
- [ ] 版本號更新
- [ ] 建置號碼遞增
- [ ] 截圖準備（iPhone、iPad）
- [ ] App 描述、關鍵字
- [ ] 隱私政策網址
- [ ] 使用條款網址
- [ ] 測試完成

---

### App Store 審核問題
📄 **文件：** `App_Store_審核問題修正指南.md`

**常見拒絕原因：**
1. 缺少隱私政策
2. 功能不完整
3. UI 問題
4. 崩潰問題

---

### 版本號管理
**當前版本：** 1.0.1 (Build 3)

**位置：**
- `InvestmentDashboard.xcodeproj/project.pbxproj`
  - `MARKETING_VERSION = 1.0.1`
  - `CURRENT_PROJECT_VERSION = 3`

**更新方式：**
```bash
# 使用 agvtool
agvtool next-version -all  # 遞增 build number
agvtool new-marketing-version 1.0.2  # 更新版本號
```

---

### 網頁部署（隱私政策、使用條款）
📄 **文件：** `網頁部署指南.md`
📁 **網頁檔案：** `網頁檔案/`

**部署步驟：**
1. 準備 HTML 檔案
2. 上傳到主機（GitHub Pages、Netlify 等）
3. 更新 App Store Connect 連結

---

## 📖 用戶文件

### 隱私權政策
📄 **中文：** `隱私權政策.md`
📄 **英文：** `Privacy_Policy.md`

**必須包含：**
- 資料收集範圍
- 資料使用方式
- iCloud 同步說明
- 第三方服務（若有）

---

### 使用條款
📄 **中文：** `使用條款.md`
📄 **英文：** `Terms_of_Service.md`

---

## 🗂️ 檔案結構

### Swift 檔案清單（按功能分類）

#### 📱 核心 App
- `InvestmentDashboardApp.swift` - App 入口
- `ContentView.swift` - 主視圖
- `SidebarView.swift` - 客戶列表側邊欄

#### 👥 客戶管理
- `AddCustomerView.swift` - 新增客戶
- `EditCustomerView.swift` - 編輯客戶
- `CustomerDetailView.swift` - 客戶詳情

#### 💰 資產管理
- `MonthlyAssetTableView.swift` - 月度資產表
- `MonthlyAssetDetailView.swift` - 資產詳情
- `AddMonthlyDataView.swift` - 新增月度資料
- `EditInvestmentDataView.swift` - 編輯投資資料
- `AssetFieldConfigurationView.swift` - 欄位配置
- `ColumnReorderView.swift` - 欄位排序

#### 📊 投資項目
- `CorporateBondsDetailView.swift` - 公司債
- `StructuredProductsDetailView.swift` - 結構型商品
- `USStockInventoryView.swift` - 美股清單
- `USStockDetailView.swift` - 美股詳情
- `TWStockInventoryView.swift` - 台股清單
- `TWStockDetailView.swift` - 台股詳情
- `RegularInvestmentInventoryView.swift` - 定期定額清單
- `AddRegularInvestmentView.swift` - 新增定期定額
- `ProfitLossTableView.swift` - 損益表

#### 🏦 貸款管理
- `LoanManagementView.swift` - 貸款管理主頁
- `LoanDetailView.swift` - 貸款詳情
- `AddLoanView.swift` - 新增貸款
- `AddLoanRateAdjustmentView.swift` - 利率調整
- `AddLoanMonthlyDataView.swift` - 月度還款資料
- `LoanMonthlyDataTableView.swift` - 月度資料表
- `LoanInvestmentOverviewChart.swift` - 投資概覽圖表
- `EditLoanAmountsView.swift` - 編輯貸款金額

#### 🛡️ 保險管理
- `InsurancePolicyView.swift` - 保單列表
- `AddInsurancePolicyView.swift` - 新增保單
- `EditInsurancePolicyView.swift` - 編輯保單
- `InsuranceCalculatorView.swift` - 試算表計算器
- `InsuranceCalculatorRow.swift` - 計算器列
- `CalculatorTableParser.swift` - 表格解析器
- `CalculatorTableDetailView.swift` - 表格詳情
- `InsuranceOCRManager.swift` - OCR 管理器
- `InsuranceOCREditView.swift` - OCR 編輯
- `RegionOCRManager.swift` - 區域 OCR
- `ImageRegionSelector.swift` - 區域選取
- `MultiplePoliciesReviewView.swift` - 批次保單審查
- `InsuranceTutorialView.swift` - 保險教學

#### 📸 圖片工具
- `ImagePicker.swift` - 圖片選擇器
- `MultipleImagePicker.swift` - 多圖選擇器
- `LiveTextImageView.swift` - LiveText 整合

#### 🔔 提醒功能
- `ReminderDashboardView.swift` - 提醒儀表板

#### 📚 教學導覽
- `OnboardingView.swift` - 首次使用教學
- `DashboardTutorialView.swift` - 儀表板教學
- `StructuredProductTutorialView.swift` - 結構型商品教學
- `InsuranceTutorialView.swift` - 保險教學
- `WhatsNewView.swift` - 版本更新介紹 ⭐ **新增**
- `TooltipManager.swift` - 提示管理器
- `TooltipOverlayView.swift` - 提示覆蓋層
- `TooltipStep.swift` - 提示步驟定義

#### 💳 訂閱功能
- `SubscriptionManager.swift` - 訂閱管理器
- `SubscriptionView.swift` - 訂閱頁面

#### 🔧 服務與工具
- `PersistenceController.swift` - Core Data 控制器
- `StockPriceService.swift` - 股價服務
- `FieldConfigurationManager.swift` - 欄位配置管理
- `FormComponents.swift` - 表單組件
- `BackupManager.swift` - iCloud Documents 備份管理器

#### 🔄 同步功能
- `USStockLoanSyncSelectionView.swift` - 美股貸款同步
- `TWStockLoanSyncSelectionView.swift` - 台股貸款同步

---

### 資料模型（Core Data）
📁 **位置：** `DataModel.xcdatamodeld/`

**實體列表：**
1. `Client` - 客戶
2. `MonthlyAsset` - 月度資產
3. `CorporateBond` - 公司債
4. `StructuredProduct` - 結構型商品
5. `USStock` - 美股
6. `TWStock` - 台股
7. `RegularInvestment` - 定期定額
8. `InsurancePolicy` - 保單
9. `Loan` - 貸款
10. `LoanRateAdjustment` - 利率調整
11. `LoanMonthlyData` - 貸款月度資料

---

### 設定檔
- `Info.plist` - App 資訊
- `InvestmentDashboard.entitlements` - 權限設定
- `Configuration.storekit` - StoreKit 配置

---

## 📝 快速查找

### 我想要...

**新增一個功能：**
1. 查看 `PROJECT.md` 了解現有架構
2. 參考 `Core_Data_設定步驟.md` 更新資料模型
3. 使用 `add_files_to_xcode.rb` 加入新檔案

**修復資料同步問題：**
→ 參考 `📊_資料串流順序.md` - 了解三區域同步機制

**理解計算公式：**
→ 參考 `📐_計算公式總覽.md` - 查看所有財務計算公式

**修復編譯錯誤：**
→ 參考 `修復編譯錯誤.md`

**上架到 App Store：**
1. `上架準備清單.md` - 檢查清單
2. `App_Store_審核問題修正指南.md` - 常見問題

**設定 iCloud 同步：**
1. `iCloud_Setup_Guide.md` - 基本設定
2. `CloudKit_Index_Setup_Guide.md` - 索引設定

**實作 OCR 功能：**
→ `OCR_Implementation_Guide.md`

**更新資料模型：**
→ `更新Core_Data模型指南.md`

**設定訂閱功能：**
1. `訂閱功能配置指南.md` - 設定步驟
2. `訂閱策略說明.md` - 策略說明

---

## 🎨 UI/UX 設計

### 色彩設計
- 主色：藍色（Blue）
- 輔色：綠色（收入/增加）、紅色（支出/減少）、橙色（警告）
- 背景：系統背景色（支援深色模式）

### 響應式設計
- iPad：NavigationSplitView（三欄式）
- iPhone：NavigationStack（單欄堆疊）

---

## 🔐 安全性

### 資料加密
- ✅ iOS 本地加密
- ✅ iCloud 傳輸加密
- ✅ CloudKit 儲存加密

### 隱私保護
- ❌ 不收集用戶資料
- ❌ 不傳輸到第三方伺服器
- ✅ 完全本地 + iCloud 儲存

---

## 📊 技術統計

**Swift 檔案數量：** 60+ 個
**MD 文件數量：** 25+ 個
**Core Data 實體：** 10 個
**支援 iOS 版本：** iOS 17.0+
**支援裝置：** iPhone、iPad

---

## 🚧 已知問題與未來改進

### 教學優化
- [ ] 加入實際截圖到教學頁面
- [ ] 優化 Tooltip 互動體驗

### 功能增強
- [ ] 更多圖表分析
- [ ] 匯出報表功能
- [ ] Apple Watch 支援

### 文件整理
- [ ] 合併重複的 MD 檔案
- [ ] 翻譯所有文件為中英雙語

---

## 📞 聯絡資訊

**Developer：** Owen
**Bundle ID：** com.owen.InvestmentDashboard
**Team ID：** V43868D94M

---

**📌 提示：** 將此文件加入書籤，作為專案開發的快速參考！
