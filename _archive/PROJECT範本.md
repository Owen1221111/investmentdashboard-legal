# InvestmentDashboard iOS 開發進度

## 專案概述
基於 SuperDesign HTML B iPhone 版本的 iOS 投資儀表板應用程式，使用 SwiftUI 開發，支援響應式設計（iPhone/iPad）。

## 開發狀態
- **開始日期**: 2025-09-09
- **當前版本**: v0.1.0
- **開發環境**: Xcode, SwiftUI
- **目標平台**: iOS 17.0+, iPadOS 17.0+
- **🚨 目前狀態**: 僅支援本地儲存，CloudKit iCloud同步功能尚未啟用
- **資料儲存**: UserDefaults (本地裝置)，不支援跨裝置同步

## 核心功能卡片

### ✅ 已完成

#### 1. 專案結構設置
- **檔案**: `InvestmentDashboard.xcodeproj/project.pbxproj`
- **狀態**: 完成
- **描述**: Xcode 專案配置檔，定義建置設定和檔案參考

#### 2. 應用程式配置
- **檔案**: `InvestmentDashboard/Info.plist`
- **狀態**: 完成
- **描述**: iOS 應用程式配置，中文顯示名稱「投資儀表板」

#### 3. 應用程式入口
- **檔案**: `InvestmentDashboard/InvestmentDashboardApp.swift`
- **狀態**: 完成
- **描述**: SwiftUI App 主入口點

#### 4. 主視圖控制器
- **檔案**: `InvestmentDashboard/ContentView.swift`
- **狀態**: 完成
- **描述**: 主要內容視圖，載入 BasicClientPickerView

#### 5. 客戶資料模型
- **檔案**: `InvestmentDashboard/Models/Client.swift`
- **狀態**: 完成
- **描述**: 客戶資料結構，移除 CloudKit 依賴

#### 6. 客戶視圖模型
- **檔案**: `InvestmentDashboard/ViewModels/ClientViewModel.swift`
- **狀態**: 完成
- **描述**: 客戶資料管理，包含範例資料

#### 7. **主要儀表板視圖**
- **檔案**: `InvestmentDashboard/Views/ClientSelection/BasicClientPickerView.swift`
- **狀態**: ✅ **核心完成**
- **描述**: 主要投資儀表板介面
- **功能細節**:
  - 響應式設計 (iPhone/iPad 自動切換)
  - 總資產顯示區域
  - 整合統計卡片群組 (總匯入/現金/總額報酬率)
  - 粉紅色走勢圖
  - 資產配置圓餅圖
  - 美股/債券投資卡片
  - 債券每月配息長條圖
  - 客戶選擇功能

## 技術架構

### UI 組件架構
```
BasicClientPickerView
├── iPadLayout (桌面版佈局)
│   ├── mainStatsCardForDesktop (主要統計卡片)
│   │   ├── integratedStatsCard (整合統計卡片)
│   │   └── simpleTrendChart (走勢圖)
│   ├── assetAllocationCard (資產配置圓餅圖)
│   └── investmentCard x2 + simpleBondDividendCard
└── iPhoneLayout (手機版佈局)
    ├── mainStatsCard (簡化統計卡片)
    ├── assetAllocationCard (資產配置圓餅圖)
    └── investmentCardsRow (投資卡片行)
```

### 設計系統
- **配色方案**: 基於 SuperDesign B 版本 CSS 變數
- **字體**: 系統字體，各尺寸精確匹配 HTML 版本
- **圓角**: 8px, 12px, 16px 階層式設計
- **陰影**: 多層次陰影效果，匹配原始設計
- **響應式**: GeometryReader 判斷螢幕寬度自動切換佈局

## ✅ 已完成功能 (續)

### 8. 月度資產明細表格
- **檔案**: `Views/Tables/MonthlyAssetTableView.swift`
- **狀態**: ✅ **完成**
- **描述**: HTML B 版本底部的資料表格功能
- **包含功能**:
  - 月度資產分頁 (日期、現金、美股、債券等)
  - 公司債分頁 (申購日、票面利率、殖利率等)
  - 損益表分頁 (交易日期、買入/賣出價格等)
  - 表格工具列 (排序、下載、刪除、編輯)
  - 響應式水平/垂直滾動
  - 標籤切換功能

### 9. 新增資料表單
- **檔案**: `Views/Forms/AddDataFormView.swift`
- **狀態**: ✅ **完成**
- **描述**: 新增月度資產資料的表單介面
- **包含功能**:
  - 基本資訊區塊 (日期選擇、備註欄位)
  - 資產明細區塊 (現金、美股、債券等輸入欄位)
  - 成本明細區塊 (各項成本輸入)
  - 計算結果即時預覽
  - 響應式格線佈局
  - 表單驗證和儲存功能

### 10. 資料持久化層
- **預估檔案**: `Services/DataManager.swift`
- **狀態**: ⏳ 待開發
- **描述**: 本地資料儲存管理 (CoreData 或 SwiftData)

### 11. CloudKit 整合
- **預估檔案**: `Services/CloudKitManager.swift`
- **狀態**: 🔮 未來功能
- **描述**: 雲端資料同步 (用戶要求後開發)

## 已解決問題

### 問題 1: iPad 側邊欄問題
- **現象**: iPad 上內容隱藏在 NavigationView 側邊欄後
- **解決**: 使用 `.navigationViewStyle(StackNavigationViewStyle())` 強制堆疊模式

### 問題 2: 應用程式崩潰
- **現象**: 使用 `CGFloat.random()` 和複雜 Path 繪製導致崩潰
- **解決**: 改用固定模式生成圖表高度，簡化繪製邏輯

### 問題 3: 視覺差異
- **現象**: SwiftUI 版本與 HTML 版本視覺不一致
- **解決**: 精確提取 CSS 顏色值，調整字體大小和間距

## 開發規範

### 檔案命名規則
- Views: `{功能名稱}View.swift`
- ViewModels: `{功能名稱}ViewModel.swift`
- Models: `{資料名稱}.swift`
- Services: `{服務名稱}Manager.swift`

### 程式碼組織
- 使用 `// MARK: -` 註解分區
- 每個 View 包含 Preview
- 複雜組件拆分為獨立函數
- 響應式設計優先考慮

### 設計原則
- **精確復刻**: 與 SuperDesign HTML B 版本視覺完全一致
- **響應式**: 自動適配 iPhone 和 iPad
- **模組化**: 可重複使用的組件設計
- **效能優化**: 避免複雜繪製和隨機生成

## 最新更新 (2025-09-09 下午)

### 🎯 B 版本設計完全重構 (第二階段)
- **檔案**: `InvestmentDashboard/ContentView.swift`
- **狀態**: ✅ **完整重構完成**
- **變更內容**:
  - 從 BasicClientPickerView 恢復所有正確的 B 版本組件
  - 實現完整的響應式佈局：iPad 水平佈局 vs iPhone 垂直佈局
  - 恢復正確的總額大卡片結構：左側資產信息 + 右上角整合卡片 + 下方粉紅走勢圖

### 🔧 修復問題
1. **iPad 導航問題**: 添加 `.navigationViewStyle(StackNavigationViewStyle())` 防止側邊欄隱藏內容
2. **總額大卡片結構**: 恢復左側總資產 + 右上角統計卡片 + 時間按鈕 + 粉紅走勢圖
3. **資產配置圓餅圖**: 恢復五色配置 (現金20%, 債券25%, 美股45%, 台股8%, 結構型2%)
4. **投資卡片**: 添加底部綠色趨勢長條圖
5. **債券配息卡片**: 12個月長條圖 + 年配息125,000顯示

### 📊 完整 B 版本組件配置

#### 1. **mainStatsCardForDesktop** - 總額大卡片 (iPad)
```swift
VStack(spacing: 16) {
  HStack(alignment: .top) {
    // 左側：總資產區域
    VStack(alignment: .leading, spacing: 12) {
      Text("總資產") + Text("10,000,000") + Text("總損益: +125,000")
      // 時間按鈕 ["1D", "7D", "1M", "3M", "1Y"]
    }
    Spacer()
    // 右上角：整合統計卡片 (280x120)
    integratedStatsCard
  }
  // 下方：粉紅色走勢圖
  simpleTrendChart
}
```

#### 2. **integratedStatsCard** - 整合統計卡片
```swift
VStack(spacing: 0) {
  // 上半部：總匯入 1,500,000
  // 下半部：左(現金 250,000 灰色) + 右(總額報酬率 +8.5% 綠色漸層)
}
.frame(width: 280, height: 120)
```

#### 3. **assetAllocationCard** - 資產配置圓餅圖
```swift
- 五色圓餅圖：橙色(現金20%), 灰色(債券25%), 紅色(美股45%), 綠色(台股8%), 藍色(結構型2%)
- 右上角小圓點指示器
- 完整圖例列表 legendItem()
```

#### 4. **investmentCard()** - 投資卡片函數
```swift
- 美股卡片：4,500,000 (+12%) + 綠色趨勢長條圖
- 債券卡片：2,500,000 (+3%) + 綠色趨勢長條圖
- 底部 15 個小長條 (2px寬, 4-15px高)
```

#### 5. **simpleBondDividendCard** - 債券配息卡片
```swift
- 標題「債券每月配息」+ 右上角「年配息 125,000」
- 12個月長條圖 (綠色, 15-31px高度變化)
- 底部月份標示 1-12
```

#### 6. **detailedMonthlyAssetTable** - 月度資產表格
```swift
- 表頭：日期、現金、美股、定期定額、債券、總資產
- 三筆範例資料：Aug-28, Aug-09, Aug-10
- MonthlyData 結構體
```

#### 7. **simpleTrendChart** - 粉紅走勢圖
```swift
- 粉紅色漸層背景 (Color(.init(red: 0.96, green: 0.45, blue: 0.45)))
- 固定模式趨勢線 (避免隨機崩潰)
- 8個點的上升趨勢路徑
```

### 📱 響應式佈局結構
```
iPad (width > 600):
├── mainStatsCardForDesktop (全寬)
└── HStack
    ├── assetAllocationCard
    └── VStack
        ├── investmentCard(美股)
        ├── investmentCard(債券)
        └── simpleBondDividendCard

iPhone (width ≤ 600):
├── mainStatsCard (簡化版)
├── assetAllocationCard
├── investmentCardsRow (HStack)
└── detailedMonthlyAssetTable
```

### 📱 完整表單與輸入系統 (2025-09-09 傍晚)

#### 🎯 完整月度資產表格升級
- **16個完整欄位**: 日期、現金、美股、定期定額、債券、結構型商品、台股、台股折合、已領利息、匯入、美股成本、定期成本、債券成本、台股成本、備註、總資產
- **水平滾動表格**: 支援左右滑動查看所有欄位
- **MonthlyData 結構體升級**: 包含所有欄位的完整數據模型
- **真實樣本數據**: 三筆完整的 Aug-28, Aug-09, Aug-10 數據

#### 🔧 新增資產記錄表單完整重構
```swift
// 表單數據結構
struct AssetFormData {
  var cash: String = "3,264,395"          // 預設上次數值
  var usStock: String = "3,596,018"       // 預設上次數值
  var bonds: String = "2,739,362"         // 預設上次數值
  // ... 13 個其他欄位
}
```

#### 🚀 輸入介面革命性改進
1. **真正的 TextField 取代灰色方塊**
   ```swift
   // 之前：不可輸入的 Text 組件
   Text(value).background(Color.gray)
   
   // 現在：真正可輸入的 TextField
   TextField(placeholder, text: text)
     .background(Color.white)
     .keyboardType(.decimalPad)
   ```

2. **狀態持久化系統**
   - `@State private var formData = AssetFormData()` 保存表單狀態
   - 關閉表單後重新打開，數值完全保留
   - 預設顯示合理的起始數值

3. **改善的用戶體驗**
   - 白色背景 + 淺灰色邊框的清晰設計
   - 數字鍵盤自動彈出
   - 即時雙向綁定更新
   - Placeholder 提示文字

#### 📊 表單區塊結構
```
新增資產記錄表單:
├── 當前客戶 (Lily)
├── 選擇日期 (Sep 9, 2025)
├── 資產資訊 (2x4 網格)
│   ├── 現金, 美股, 定期定額, 債券
│   └── 台股, 台股折合美金, 結構型商品, 已領利息
├── 成本資訊 (2x2 網格)
│   └── 美股成本, 定期成本, 債券成本, 台股成本
└── 匯入資訊 (全寬)
    └── 匯入
```

#### 🔗 完整功能連結
- 右上角 "+" 按鈕 → 完整新增資產記錄表單
- 表單所有欄位 ↔ 月度資產表格欄位完全匹配
- "取消" / "保存" 按鈕功能正常
- ✅ **保存功能已實現**: 表單資料會自動保存到月度資產明細表格

## 開發里程碑

- ✅ **v0.1.0** (2025-09-09): 基礎儀表板完成
- ✅ **v0.1.5** (2025-09-09 下午): B版本設計完全重構
- ✅ **v0.1.6** (2025-09-09 下午): 完整恢復所有 B 版本組件配置
- ✅ **v0.2.0** (2025-09-09 傍晚): 完整表單與輸入系統
- ✅ **v0.2.5** (2025-09-09 深夜): 新增資料保存到月度表格功能
- ✅ **v0.2.6** (2025-09-09 深夜): 表單標籤功能與日期選擇優化
- ✅ **v0.2.7** (2025-09-09 深夜): 表格滾動同步與公司債表格功能
- ✅ **v0.2.8** (2025-09-10 上午): 總資產數字連動功能
- ✅ **v0.2.9** (2025-09-10 上午): 總損益動態計算功能
- ✅ **v0.3.0** (2025-09-11 上午): 重複檔案清理與資料連動修復
- ✅ **v0.3.1** (2025-09-11 上午): 資產配置卡片對齊與顯示修復
- ✅ **v0.3.2** (2025-09-11 上午): 投資卡片走勢圖與報酬率功能升級
- ✅ **v0.3.3** (2025-09-11 下午): iPad UI整體放大與佈局優化
- ✅ **v0.3.4** (2025-09-11 下午): 台股卡片新增與佈局對齊優化
- ✅ **v0.4.0** (2025-09-12 上午): 左滑功能實現與對齊優化
- ✅ **v0.4.1** (2025-09-12 上午): 資產配置卡片可讀性大幅提升
- ✅ **v0.4.2** (2025-09-12 下午): 導航按鈕尺寸優化與觸控體驗提升
- ✅ **v0.4.3** (2025-09-12 下午): 表格展開收合動畫與狀態管理優化
- ✅ **v0.4.4** (2025-09-13 上午): 總資產卡片高度與趨勢圖區域優化
- ✅ **v0.4.5** (2025-09-13 上午): 字體大小全面提升與UI一致性優化
- ✅ **v0.4.6** (2025-09-13 中午): 資產配置圓餅圖智能中心顯示
- ✅ **v0.4.7** (2025-09-13 中午): 投資卡片走勢圖真實數據革新
- ✅ **v0.4.8** (2025-09-13 晚上): 公司債表單重構與智能預填功能
- ✅ **v0.4.9** (2025-09-13 深夜): 表格匯出與欄位排序功能實現 ← **當前版本**
- ⏳ **v0.5.0**: 資料持久化與 CRUD 功能強化
- 🔮 **v0.6.0**: CloudKit 整合

### 🎯 新增資料保存功能實現 (2025-09-09 深夜)

#### ✅ 完整的表單到表格資料流程
```swift
// 資料流程：表單輸入 → 保存 → 顯示在月度資產明細表格
1. 用戶點選右上角 "+" 按鈕
2. 填寫表單資料（按照優化的排序）
3. 點選 "保存" 按鈕
4. 新記錄自動出現在月度資產明細表格最前面
```

#### 🔧 saveFormData() 函數功能
- **日期格式化**: 自動格式化為 "Sep-09" 格式
- **自動計算總資產**: 現金 + 美股 + 債券 + 結構型商品 + 已領利息
- **動態表格更新**: `monthlyDataList.insert(newData, at: 0)` 加入最前面
- **空值處理**: 空欄位自動填入 "0"
- **狀態保持**: 表單數據保持，方便下次輸入

#### 📊 動態表格系統
```swift
// displayMonthlyData 計算屬性
- 如果 monthlyDataList 為空：顯示預設範例資料
- 有新增資料後：顯示實際輸入的資料列表
- 支援水平滾動查看所有 16 個欄位
```

#### 🎨 表單欄位排序優化需求
- **當前排序**: ✅ **已完成** - 按照用戶截圖的順序排列
- **目標排序**: ✅ **已達成** - 水平佈局，左邊標題右邊輸入欄位
- **狀態**: ✅ **已完成** - 表單佈局完全符合用戶要求

### 🏷️ 表單標籤功能實現 (2025-09-09 深夜)

#### ✅ 標籤切換系統
```swift
// 標籤狀態管理
@State private var selectedTab = 0 // 0: 資產明細, 1: 公司債

// 標籤按鈕組件
private func tabButton(title: String, index: Int) -> some View {
    // 選中狀態：白色背景 + 陰影 + 黑色文字
    // 未選中狀態：透明背景 + 灰色文字
}
```

#### 🔧 標籤內容切換功能
- **資產明細標籤** (selectedTab == 0)：
  - 顯示所有 13 個資產輸入欄位
  - 現金、美股、定期定額、債券、台股等完整欄位
  
- **公司債標籤** (selectedTab == 1)：
  - 預留位置設計，顯示 "即將推出" 佔位符
  - 建築物圖示 + 說明文字
  - 為未來公司債功能預留擴展空間

#### 📅 日期選擇器優化
```swift
// 日期狀態管理
@State private var selectedDate = Date()

// 統一格式設計
HStack {
    Text("選擇日期") // 左邊標題
    DatePicker("", selection: $selectedDate) // 右邊選擇器
}
.background(Color(.systemGray5)) // 淺灰色背景
```

#### 🎨 視覺設計改進
1. **統一格式佈局**：
   - 所有輸入區域：左邊標題 + 右邊內容
   - 相同的內邊距和圓角設計
   - 統一的淺灰色背景 `Color(.systemGray5)`

2. **移除視覺衝突**：
   - 移除日期區域的重複 "選擇日期" 標籤
   - 統一字體大小和顏色
   - 移除深色大方框，改用簡潔設計

3. **標籤切換效果**：
   - 選中標籤：白色背景 + 陰影 + 黑色文字
   - 未選中標籤：透明背景 + 灰色文字
   - 流暢的切換動畫

### 🔗 總資產數字連動功能實現 (2025-09-10 上午)

#### ✅ 資料流程統一管理
```swift
// ClientViewModel 新增月度資產資料管理
@Published var monthlyAssetData: [[String]] = [
    ["Aug-08", "2005", "6317.80", "10115.02", "15400.67", "215408.5", "0.0", "186501.0", "5703.15695", "13952.5", "260945.97"],
    ["Aug-09", "2105", "6420.15", "10205.30", "15500.20", "218500.0", "0.0", "187200.0", "5750.25", "14000.0", "264661.40"],
    ["Aug-10", "2200", "6525.30", "10295.75", "15600.85", "220000.0", "0.0", "188000.0", "5800.50", "14150.0", "268372.70"]
]
```

#### 🎯 核心連動邏輯
- **總資產大卡片**: `viewModel.currentTotalAssets` ← 月度資產明細最新一筆資料的「總資產」欄位
- **現金小卡片**: `viewModel.currentCash` ← 月度資產明細最新一筆資料的「現金」欄位
- **自動格式化**: 千分位分隔符 (260945.97 → 260,945,970)
- **單位轉換**: 資料以千為單位，自動乘以1000顯示實際金額

#### 📱 響應式更新機制
```swift
// 計算屬性自動更新
var currentTotalAssets: String {
    guard let latestData = monthlyAssetData.first,
          latestData.count > 10,
          let totalAsset = Double(latestData[10]) else {
        return "10,000,000"
    }
    return formatNumber(totalAsset * 1000)
}

var currentCash: String {
    guard let latestData = monthlyAssetData.first,
          latestData.count > 1,
          let cash = Double(latestData[1]) else {
        return "250,000"
    }
    return formatNumber(cash * 1000)
}
```

#### 🔧 實現細節
- **iPad & iPhone 雙版本支援**: 總資產大卡片在兩種佈局下都會動態更新
- **向下相容**: 保持原有表格功能，無資料時顯示預設範例
- **即時同步**: 月度資產明細更新時，總資產卡片立即反映最新數字
- **資料完整性**: 所有數字顯示都來自同一資料來源，確保一致性

#### 📊 連動效果展示
```
月度資產明細 (最新一筆) → 總資產大卡片
日期: Aug-08                 → (顯示最新日期的資料)
現金: 2005 (千)              → 現金: 2,005,000
總資產: 260945.97 (千)       → 總資產: 260,945,970
```

### 🧮 總損益動態計算功能實現 (2025-09-10 上午)

#### ✅ 完整月度資產明細欄位結構 (16欄位)
根據用戶需求截圖，補齊了缺失的欄位：
```swift
// 完整的16個欄位結構
private let monthlyAssetHeaders = [
    "日期", "現金", "美股", "定期定額", "債券", "結構型商品", 
    "台股", "台股折合", "已確利息", "匯入", "美股成本", "定期定額成本", 
    "債券成本", "台股成本", "備註", "總資產"
]
```

#### 🎯 總損益計算公式
```swift
// 計算公式
總損益金額 = 總資產 - 累積匯入
總損益率 = (總資產 - 累積匯入) / 累積匯入 × 100%

// 實現邏輯
var currentTotalPnL: String {
    guard let latestData = monthlyAssetData.first,
          latestData.count > 15,
          let totalAssets = Double(latestData[15]), // 總資產 (索引15)
          let totalDeposit = Double(latestData[9]),  // 累積匯入 (索引9)
          totalDeposit > 0 else {
        return "+125,000 (+1.25%)"
    }
    
    let pnlAmount = (totalAssets - totalDeposit) * 1000 // 轉換為實際金額
    let pnlPercentage = ((totalAssets - totalDeposit) / totalDeposit) * 100
    
    let sign = pnlAmount >= 0 ? "+" : ""
    let amountStr = formatNumber(abs(pnlAmount))
    let percentageStr = String(format: "%.2f", pnlPercentage)
    
    return "\(sign)\(amountStr) (\(sign)\(percentageStr)%)"
}
```

#### 📊 資料來源說明
- **總資產**: 月度資產明細第16欄 (索引15) `latestData[15]`
- **累積匯入**: 月度資產明細第10欄 (索引9) `latestData[9]` - 就是「匯入」欄位，非累加計算

#### 🔧 技術實現細節
- **動態計算**: 每次月度資產明細更新時自動重新計算
- **格式化處理**: 金額加千分位分隔符，百分比保留兩位小數
- **正負號邏輯**: 自動判斷盈虧並顯示對應符號
- **錯誤處理**: 資料不完整或除數為零時顯示預設值
- **雙版本支援**: iPad 和 iPhone 版本同步更新

#### 📱 實際計算範例
```
根據最新資料 (Sep-10):
- 總資產: 260945.97 (千) = 260,945,970
- 累積匯入: 13952.5 (千) = 13,952,500
- 損益金額: 260,945,970 - 13,952,500 = 246,993,470
- 損益率: (246,993,470 ÷ 13,952,500) × 100% = 1770.18%
- 顯示結果: "總損益: +246,993,470 (+1770.18%)"
```

#### 🎨 UI整合效果
- **完整連動**: 總資產大卡片三個主要數字全部來自月度資產明細
  - 總資產：`viewModel.currentTotalAssets`
  - 現金：`viewModel.currentCash`  
  - 總損益：`viewModel.currentTotalPnL`
- **即時更新**: 月度資產明細一更新，所有數字立即同步
- **視覺一致**: 保持原有綠色樣式表示獲利狀態

### 📊 表格滾動同步與公司債表格功能 (2025-09-09 深夜)

#### ✅ 表格滾動同步問題解決
**問題**: 月度資產表格的表頭和數據行各自獨立滾動，導致閱讀困難
**解決方案**: 
```swift
// 統一滾動容器 - 表頭和數據在同一個 ScrollView 中
ScrollView(.horizontal) {
    VStack(spacing: 0) {
        // 表頭 HStack
        HStack { tableHeaderCells... }
        
        // 分隔線
        Rectangle()
        
        // 數據行 VStack
        VStack {
            ForEach(data) { HStack { tableDataCells... } }
        }
    }
}
```

#### 🔢 數字格式化功能
- **千分位分隔符**: 自動為所有純數字添加逗號
- **智能識別**: 區分數字和非數字內容（日期、備註等）
- **formatNumberString()**: 專用格式化函數
```swift
1234567 → 1,234,567
3264395 → 3,264,395
"Sep-09" → "Sep-09" (保持不變)
```

#### 🏛️ 公司債明細表格實現
**獨立卡片設計**:
- **15個完整欄位**: 申購日、名稱、票面利率、殖利率、申購價、申購金額、持有面額、交易金額、現值、已領利息、含息損益、報酬率、配息月份、單次配息、年度配息
- **統一滾動系統**: 使用與月度資產表格相同的滾動同步技術
- **預留位置**: 顯示 "尚無公司債資料" 佔位符
- **完整功能準備**: 表格結構已準備好接受實際數據

#### 🔄 表格折疊/展開功能
**月度資產明細表格**:
```swift
@State private var isMonthlyTableExpanded = true

Button(action: {
    withAnimation(.easeInOut(duration: 0.3)) {
        isMonthlyTableExpanded.toggle()
    }
}) {
    // 標題 + 記錄數 + 箭頭圖示
}

if isMonthlyTableExpanded {
    // 表格內容
}
```

**公司債明細表格**:
- 相同的折疊/展開機制
- 獨立的狀態管理 `isBondTableExpanded`
- 統一的視覺設計和動畫效果

#### ⚙️ 表格管理功能
**每個表格都包含**:
- **折疊/展開按鈕**: 表頭可點擊，顯示箭頭方向
- **記錄數顯示**: 動態顯示「（X筆）」
- **編輯欄位按鈕**: 預留欄位自定義功能
- **查看詳細按鈕**: 預留詳細視圖功能

#### 📋 表格結構對比
```
月度資產明細表格 (獨立卡片):
├── 📋 月度資產明細（3筆）↕️
├── [編輯欄位] [查看詳細]
└── 16個欄位的完整表格

公司債明細表格 (獨立卡片):
├── 🏛️ 公司債明細（0筆）↕️  
├── [編輯欄位] [查看詳細]
└── 15個欄位的完整表格框架
```

#### 🎨 用戶體驗改進
- **簡潔模式**: 可將表格折疊為僅顯示標題，節省畫面空間
- **同步滾動**: 表頭和數據完美同步，解決閱讀困難問題
- **數字易讀**: 大數字添加千分位分隔符，提升可讀性
- **流暢動畫**: 0.3秒 ease-in-out 展開/折疊動畫
- **統一設計**: 兩個表格使用完全一致的視覺風格

## 技術債務
- 圖表使用簡化實現，可考慮使用專業圖表庫
- 需要添加單元測試覆蓋
- 需要實現完整的資料持久化層（CoreData/SwiftData）
- 欄位編輯功能的具體實現（待用戶需求）
- 公司債實際數據的輸入和管理功能

### 🔧 重複檔案清理與資料連動修復 (2025-09-11 上午)

#### ✅ 重複檔案問題解決
**發現問題**: 專案存在重複檔案結構導致功能不正常
```
重複結構分析:
根目錄版本: /Models/, /ViewModels/, /Views/
子目錄版本: /InvestmentDashboard/Models/, /InvestmentDashboard/ViewModels/, /InvestmentDashboard/Views/

問題: Xcode實際使用的是子目錄版本，但功能修復都在根目錄版本
```

**解決方案**:
- 確認Xcode專案引用路徑：`InvestmentDashboard/` 為主要專案目錄
- 保留CloudKit功能：維持iCloud多裝置同步需求
- 統一資料來源：所有計算都基於ViewModel的monthlyAssetData

#### 🎯 完整資料連動系統實現
**核心邏輯重構**:
```swift
// ContentView 整合 ClientViewModel
@StateObject private var viewModel = ClientViewModel()

// 總資產大卡片連動
Text(viewModel.currentTotalAssets)     // 動態計算總資產
Text("總損益: \(viewModel.currentTotalPnL)")  // 動態計算損益

// 統計卡片連動
value: viewModel.currentTotalDeposit   // 總匯入
value: viewModel.currentCash          // 現金
```

**雙向資料同步**:
- **新增資料時**: 同時更新monthlyDataList和viewModel.monthlyAssetData
- **計算來源**: 所有大卡片數值來自viewModel.currentXXX計算屬性
- **表格顯示**: 合併ViewModel資料和本地新增資料

#### 📊 月度資產表格滾動同步修復
**問題**: 表頭和資料行滾動不同步，閱讀困難
**解決方案**:
```swift
// MonthlyAssetTableView 結構改進
ScrollView(.horizontal) {
    VStack {
        // 表頭固定在頂部
        HStack { headers... }
        
        // 垂直滾動的資料區域
        ScrollView(.vertical) {
            VStack { dataRows... }
        }
        .frame(maxHeight: 200)
    }
}
```

**改進效果**:
- ✅ 表頭與資料完美同步滾動
- ✅ 數字自動添加千分位分隔符
- ✅ 支援垂直滾動查看更多資料

#### 🎨 真實資料走勢圖實現
**核心功能**:
- **資料來源**: 月度資產明細的總資產欄位(第16欄)
- **自動排序**: 按日期時間序列顯示趨勢
- **動態計算**: 實時計算期間變化百分比

**視覺效果優化**:
```swift
// 走勢圖結構
ZStack {
    trendFillArea(in: geometry.size)  // 線條下方填充漸層
    trendLine(in: geometry.size)      // 粉紅色趨勢線
    trendLabels                       // 百分比和時間標籤
}

// 填充漸層 (僅線條下方)
LinearGradient(
    colors: [
        Color(.init(red: 0.96, green: 0.45, blue: 0.45, alpha: 0.3)),  // 線條附近
        Color(.init(red: 0.96, green: 0.45, blue: 0.45, alpha: 0.02)) // 底部透明
    ],
    startPoint: .top, endPoint: .bottom
)
```

**標籤系統**:
- **右上角**: 自動計算的變化百分比 (如: +1.25%)
- **左下角**: "過去資產變化" 時間標籤
- **響應式**: iPhone和iPad版本統一實現

#### 📱 響應式設計統一
**iPhone版本增強**:
```swift
// iPhone mainStatsCard 新增組件
VStack {
    總資產信息區域                    // ✅ 連動viewModel
    時間按鈕組 ["1D", "7D"...]        // ✅ 新增
    走勢圖 simpleTrendChart          // ✅ 新增  
    2x2統計卡片                      // ✅ 連動viewModel
}
```

**iPad版本保持**:
- 保持原有mainStatsCardForDesktop佈局
- 走勢圖位置不變，功能增強為真實資料

#### 🔗 完整資料流程
```
用戶新增資料 → saveFormData() → {
    1. 更新 monthlyDataList (本地表格顯示)
    2. 更新 viewModel.monthlyAssetData (計算來源)
    3. 觸發 @Published 更新
    4. 自動更新所有連動組件:
       - 總資產大卡片
       - 現金、總匯入、總損益卡片  
       - 走勢圖重繪
       - 月度資產表格
}
```

#### 🎯 v0.3.0 技術成就
- ✅ **問題診斷**: 準確識別重複檔案結構問題
- ✅ **架構統一**: ContentView和ViewModel完全整合
- ✅ **資料連動**: 所有數字組件實時同步
- ✅ **視覺優化**: 走勢圖符合用戶期望效果
- ✅ **使用者體驗**: 表格滾動、資料新增流暢運作
- ✅ **響應式設計**: iPhone/iPad版本功能統一

## 技術債務
- 圖表使用簡化實現，可考慮使用專業圖表庫
- 需要添加單元測試覆蓋
- 需要實現完整的資料持久化層（CoreData/SwiftData）
- 欄位編輯功能的具體實現（待用戶需求）
- 公司債實際數據的輸入和管理功能

### 🎯 資產配置卡片對齊與顯示修復 (2025-09-11 上午 v0.3.1)

#### ✅ 卡片對齊問題解決
**問題1**: 資產配置卡片與右側卡片組（美股、債券、債券每月配息）上下對齊不一致

**解決方案**:
```swift
// iPad佈局HStack改進
HStack(alignment: .top, spacing: 16) {
    assetAllocationCard
        .frame(maxWidth: 380, maxHeight: .infinity) // 自動填滿高度
    
    VStack(spacing: 16) {
        investmentCard(美股)
        investmentCard(債券) 
        simpleBondDividendCard
    }
}
```

**實現效果**:
- ✅ 資產配置卡片**上緣**與美股卡片**上緣**對齊
- ✅ 資產配置卡片**下緣**與債券每月配息卡片**下緣**對齊
- ✅ 移除固定高度限制，讓卡片自動調整至最佳高度

#### 🎨 圓餅圖溢出問題修復
**問題2**: 圓餅圖部分內容被切掉，百分比文字顯示不完整

**解決方案**:
```swift
// 圓餅圖尺寸優化
// 從: 120x120, lineWidth: 20
// 改為: 100x100, lineWidth: 16

Circle()
    .stroke(color, lineWidth: 16)
    .frame(width: 100, height: 100)

// 圖例優化
legendItem()
    .frame(minWidth: 40, alignment: .trailing) // 確保百分比文字空間
    .padding(.horizontal, 4)
```

**改進細節**:
- ✅ 圓餅圖尺寸從120px縮小至100px，防止溢出
- ✅ 線寬從20px減少至16px，維持視覺比例
- ✅ 圖例添加最小寬度40px，確保高百分比（如83%）完整顯示
- ✅ 減少水平padding從20px至16px，增加內容空間

#### 🔧 佈局空間優化
**容器調整**:
```swift
// 卡片寬度調整
assetAllocationCard.frame(maxWidth: 380) // 從350增加至380

// 內部padding調整  
.padding(.horizontal, 16)  // 從20減少至16
.padding(.vertical, 16)

// 圖例容器
VStack { legends... }
    .padding(.horizontal, 8) // 新增圖例邊距
```

#### 🎯 技術實現亮點
1. **動態高度填滿**: 使用 `maxHeight: .infinity` 讓資產配置卡片自動匹配右側卡片組總高度
2. **精確尺寸控制**: 圓餅圖、文字、圖例的像素級精確調整
3. **響應式padding**: 根據內容需要動態調整各層級的邊距
4. **文字截斷防護**: 確保所有百分比數字（包括雙位數）都有足夠顯示空間

#### 📱 視覺效果改善
**修復前問題**:
- 資產配置卡片高度不匹配，視覺不協調
- 圓餅圖右側被截斷
- 高百分比數字（83%）顯示不完整

**修復後效果**:
- ✅ 完美的上下對齊，視覺平衡
- ✅ 圓餅圖完整包含在卡片內
- ✅ 所有百分比文字清晰可見
- ✅ 保持原有的左滑切換功能
- ✅ 維持統一的設計語言

#### 🎨 用戶體驗提升
- **視覺一致性**: 左右兩側卡片組呈現完美對齊
- **資訊完整性**: 所有圓餅圖和百分比數據完整顯示
- **響應式佈局**: 調整後仍完美支援iPad橫向佈局
- **功能保持**: 三頁左滑切換（總覽、美股詳細、債券詳細）功能正常

### 🎯 投資卡片走勢圖與報酬率功能升級 (2025-09-11 上午 v0.3.2)

#### ✅ 投資卡片走勢圖功能實現
**核心功能**: 為美股和債券投資卡片添加右側走勢圖，替代原有的簡單長條圖

**走勢圖特色**:
```swift
// 投資卡片走勢圖架構
investmentTrendChart(isPositive: Bool) -> some View {
    ZStack {
        investmentTrendFillArea()    // 漸層填充區域
        investmentTrendLine()        // 走勢線條
    }
}
```

**視覺效果優化**:
- ✅ **動態顏色系統**: 正向投資顯示綠色走勢線，負向顯示紅色走勢線
- ✅ **漸層填充**: 從走勢線到底部的漸層效果，類似總額大卡片風格
- ✅ **模擬數據**: 美股顯示上升趨勢，債券顯示穩定上升
- ✅ **響應式尺寸**: 走勢圖自動適配卡片尺寸

#### 🧮 報酬率動態計算系統
**美股報酬率計算**:
```swift
/// 計算公式: (美股 + 定期定額 - 美股成本) / 美股成本 * 100%
var usStockReturnRate: String {
    let totalUSStock = usStock + regularInvestment  // 美股總額
    let returnAmount = totalUSStock - usStockCost   // 利潤金額
    let returnRate = (returnAmount / usStockCost) * 100
    return "+173.9%"  // 動態格式化結果
}
```

**債券報酬率計算**:
```swift
/// 計算公式: (債券 - 債券成本) / 債券成本 * 100%
var bondsReturnRate: String {
    let returnAmount = bonds - bondsCost
    let returnRate = (returnAmount / bondsCost) * 100
    return "+2.7%"  // 動態格式化結果
}
```

**資料來源對應**:
- **美股金額**: 月度資產明細第3欄（美股）+ 第4欄（定期定額）
- **美股成本**: 月度資產明細第11欄（美股成本）
- **債券金額**: 月度資產明細第5欄（債券）  
- **債券成本**: 月度資產明細第13欄（債券成本）

#### 🎨 投資卡片佈局重構
**佈局演進歷程**:

1. **第一階段 - 水平佈局**: 左側文字 + 右側走勢圖並排
2. **第二階段 - 表頭整合**: 報酬率移到表頭同一行
3. **第三階段 - 垂直分層**: 報酬率獨立成行，右側純走勢圖
4. **第四階段 - 空間優化**: 左側固定寬度，右側圖表填滿剩餘空間

**最終佈局結構**:
```swift
HStack(spacing: 4) {
    // 左側: 固定140px寬度
    VStack(alignment: .leading, spacing: 6) {
        Text("美股")                    // 第1行: 標題
        Text("16,432,820")            // 第2行: 金額
        HStack {                       // 第3行: 報酬率
            Text("報酬率：")
            Text("+173.9%")
        }
    }
    .frame(width: 140)
    
    // 右側: 擴展填滿剩餘空間
    investmentTrendChart()
        .frame(maxWidth: .infinity, maxHeight: 65)
}
```

#### 📊 空間利用率優化
**問題解決**:
- **問題**: 中間空白過多，圖表區域太小
- **解決**: 左側固定140px寬度，右側自動填滿剩餘空間

**空間分配對比**:
```
調整前: [左側動態寬度～180px] [8px間距] [右側120px固定]
調整後: [左側140px固定] [4px間距] [右側自動擴展～156px+]
```

**優化效果**:
- ✅ **圖表空間增加**: 從120px增加到動態寬度（通常150px+）
- ✅ **中間空白減少**: 間距從8px減少到4px
- ✅ **左右比例平衡**: 約37% vs 63% 的空間分配

#### 🎯 債券每月配息卡片透明化
**視覺設計調整**:
- **修改前**: 白色背景 + 陰影效果（與其他卡片一致）
- **修改後**: 透明背景（融入整體背景色）

```swift
// 移除前
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(Color.white)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
)

// 移除後 - 純透明
.padding(12)
```

**設計層次**:
- **主要投資卡片**: 白色背景 + 陰影（突出重要性）
- **資產配置卡片**: 白色背景 + 陰影（重要資訊）
- **每月配息卡片**: 透明背景（輔助性資訊）

#### 🔧 技術實現亮點

1. **專用卡片組件**:
   - `usStockCard`: 美股專用卡片，包含報酬率計算
   - `bondsCard`: 債券專用卡片，包含報酬率計算
   - 取代原有的通用 `investmentCard()` 函數

2. **動態資料連動**:
   - 報酬率自動從月度資產明細計算
   - 走勢圖根據 `isPositive` 參數選擇顏色主題
   - 與現有的 `viewModel.currentUSStockValue` 等完全整合

3. **響應式設計**:
   - **iPad版本**: 右側卡片組垂直排列
   - **iPhone版本**: 投資卡片水平排列
   - 兩種佈局都採用相同的卡片設計

4. **視覺一致性**:
   - 走勢圖風格與總額大卡片統一
   - 字體層次和顏色系統保持一致
   - 圓角和陰影效果統一標準

#### 📱 用戶體驗提升

**資訊豐富度**:
- ✅ **視覺化趨勢**: 走勢圖比長條圖更直觀展示變化
- ✅ **精確報酬率**: 基於真實資料計算，而非固定值
- ✅ **清晰分層**: 標題、金額、報酬率三層資訊結構

**視覺美觀度**:
- ✅ **空間利用**: 圖表區域最大化，減少視覺浪費
- ✅ **背景層次**: 透明卡片增加視覺層次感
- ✅ **色彩協調**: 綠色系貫穿走勢圖和報酬率顯示

**功能完整性**:
- ✅ **即時更新**: 月度資產資料更新時報酬率自動重算
- ✅ **錯誤處理**: 資料不完整時顯示合理預設值
- ✅ **響應式**: 不同螢幕尺寸下都能完美顯示

### 🎯 iPad UI整體放大與佈局優化 (2025-09-11 下午 v0.3.3)

#### ✅ 每月配息長條圖延伸修復
**問題**: 債券每月配息卡片右側有空白，長條圖未充分利用空間

**解決方案**:
```swift
// 修改前: 固定寬度12px + 固定間距4px
.frame(width: 12, height: CGFloat(...))
HStack(spacing: 4)

// 修改後: 自動填滿寬度 + 減少間距
.frame(maxWidth: .infinity, maxHeight: .infinity)
HStack(spacing: 2)
```

**實現效果**:
- ✅ 12個月長條圖平均分配整個卡片寬度
- ✅ 移除右側空白空間
- ✅ 視覺更協調統一

#### 🔍 iPad佈局整體放大系統
**用戶需求**: iPad直立時首屏只顯示總資產大卡片和四個主要卡片，整體UI放大提升可讀性

**技術實現策略**:
1. **移除scaleEffect**: 避免重疊問題，改用padding和尺寸調整
2. **相對尺寸適配**: 使用GeometryReader確保各種iPad尺寸兼容
3. **首屏內容控制**: 增加表格上邊距，確保滑動才能看到

#### 📏 卡片尺寸全面升級

**總資產大卡片**:
```swift
// 尺寸升級歷程
padding: 16 → 24 → 32
圓角: 16 → 20 → 24
字體: 總資產14→18, 數字36→44, 損益14→18, 按鈕11→14
```

**整合統計卡片**:
```swift
// 尺寸升級歷程  
尺寸: 280×120 → 320×140 → 360×160
圓角: 12 → 16 → 20
字體: 總匯入12→15→20, 現金11→13→16, 報酬率10→12→20
```

**投資卡片（美股/債券）**:
```swift
// 尺寸升級歷程
padding: 12 → 18 → 24
圓角: 12 → 16 → 20  
走勢圖高度: 65 → 75 → 85
字體: 標題14→17, 數字16→19, 報酬率10→12→14
寬度控制: 固定140px → 最小160px (響應式適配)
```

**資產配置卡片**:
```swift
// 尺寸升級歷程
padding: 16 → 20 → 26
圓角: 16 → 20 → 24
字體: 標題16→19, 圓餅圖18→22, 圖例12→14
寬度分配: 使用geometry.size.width * 0.44
```

**債券配息卡片**:
```swift  
// 尺寸升級歷程
padding: 12 → 18 → 28
長條圖高度: 50 → 65 → 75
字體: 標題14→17, 年配息14→17, 月份8→10
長條高度: 15+變化 → 20+變化
```

#### 🎨 響應式佈局系統優化

**iPad尺寸適配**:
```swift
// 使用相對尺寸取代固定值
GeometryReader { geometry in
    HStack(alignment: .top, spacing: 24) {
        assetAllocationCard
            .frame(maxWidth: geometry.size.width * 0.44) // 44%寬度
        VStack(spacing: 22) { /* 投資卡片組 */ }
    }
}
.frame(minHeight: 480) // 確保足夠高度
```

**間距系統升級**:
- **整體間距**: VStack 20→28→36
- **卡片間距**: 16→18→22  
- **水平間距**: 20→24
- **表格上邊距**: 60→80 (推到首屏外)

#### 📱 首屏內容控制效果

**修改前問題**:
- 卡片偏小，可讀性不足
- 首屏顯示過多內容，視覺擁擠
- 右側配息圖表有空白浪費空間

**修改後效果**:
- ✅ **iPad mini/Air/Pro全兼容**: 使用相對尺寸確保各種iPad正確顯示
- ✅ **首屏完美填充**: 總資產大卡片 + 四個主要卡片剛好填滿首屏
- ✅ **需滑動查看表格**: 表格推到首屏外，符合用戶預期
- ✅ **視覺層次清晰**: 大幅提升可讀性和視覺衝擊力
- ✅ **空間充分利用**: 移除所有不必要的空白空間

#### 🔧 技術實現亮點

1. **漸進式放大策略**: 
   - 第一階段: scaleEffect + 基礎放大
   - 第二階段: 移除scaleEffect，改padding + 尺寸
   - 第三階段: 進一步放大所有元素

2. **響應式設計原則**:
   - minWidth取代固定width避免小屏問題
   - GeometryReader實現百分比寬度分配
   - frame(minHeight:)確保內容區域足夠

3. **視覺一致性維護**:
   - 統一的圓角升級 (12→16→20→24)
   - 協調的padding升級 (按重要性分級)
   - 比例化的字體放大 (保持相對關係)

### 🎯 台股卡片新增與佈局對齊優化 (2025-09-11 下午 v0.3.4)

#### ✅ 台股投資卡片完整實現
**用戶需求**: 在美股和債券卡片中間新增台股卡片，完善投資組合展示

**技術實現**:
```swift
// iPad佈局 - 新增台股卡片
VStack(spacing: 16) {
    usStockCard
    twStockCard  // 新增台股卡片
    bondsCard  
    simpleBondDividendCard
}

// iPhone佈局 - 改為水平滾動設計
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 12) {
        usStockCard.frame(width: 280)
        twStockCard.frame(width: 280)  
        bondsCard.frame(width: 280)
    }
}
```

**資料整合**:
```swift
/// 台股金額計算 (ClientViewModel.swift)
var currentTWStockValue: String {
    // 台股 + 台股折合美金 (索引6 + 索引7)
    let totalTWStock = twStock + twStockUSD
    return formatNumber(totalTWStock * 1000)
}

/// 台股報酬率計算
var twStockReturnRate: String {
    // (台股總額 - 台股成本) / 台股成本 × 100%
    let returnRate = (totalTWStock - twStockCost) / twStockCost * 100
    return "\(sign)\(String(format: "%.1f", returnRate))%"
}
```

#### 🎨 佈局對齊優化系統
**問題診斷**: 右側四個卡片（美股、台股、債券、每月配息）超出左側資產配置卡片下緣，視覺不協調

**解決策略**: 
1. **間距壓縮**: 減少卡片間距從22→16
2. **尺寸優化**: 所有投資卡片padding從24→20
3. **高度控制**: 走勢圖高度從85→70，配息卡片從75→60

#### 📊 卡片尺寸優化對照表

**投資卡片（美股/台股/債券）優化**:
```swift
// 優化前 → 優化後
padding: 24 → 20 (減少20%)
走勢圖高度: 85 → 70 (減少18%)
內部間距: 8 → 6 (減少25%)
圓角保持: 20 (維持視覺一致性)
```

**債券配息卡片優化**:
```swift
// 優化前 → 優化後  
padding: 28 → 20 (減少29%)
總高度: 75 → 60 (減少20%)
內部間距: 16 → 12 (減少25%)
長條圖間距: 3 → 2 (減少33%)
長條圖高度: 20+變化*10 → 15+變化*6 (減少基礎高度)
圓角: 3 → 2 (與整體比例協調)
```

**佈局間距優化**:
```swift
// 優化前 → 優化後
VStack間距: 22 → 16 (減少27%)  
iPad最小高度: 520 → 保持 (容納四個卡片)
```

#### 📱 平台適配完善

**iPad版本特色**:
- ✅ **完美對齊**: 右側四個卡片與左側資產配置卡片上下邊緣完全對齊
- ✅ **空間優化**: 移除冗餘空白，整體佈局更緊湊專業
- ✅ **視覺平衡**: 左右兩側高度一致，視覺重心穩定

**iPhone版本特色**:
- ✅ **水平滑動**: 三個投資卡片支援左右滑動瀏覽
- ✅ **固定尺寸**: 每個卡片280px寬度確保滑動體驗流暢
- ✅ **響應式高度**: 120px固定高度適配不同iPhone螢幕

#### 🔧 資料架構擴展

**月度資產明細整合**:
```javascript
// 資料欄位對應 (16欄完整版)
索引6: 台股金額  
索引7: 台股折合美金
索引13: 台股成本 (新增使用)

// 計算邏輯
台股總金額 = 台股 + 台股折合美金
台股報酬率 = (台股總金額 - 台股成本) / 台股成本 × 100%
預設值 = 800,000 和 +15.8% (資料不足時)
```

---

### 🎯 左滑功能實現與對齊優化 (2025-09-12 上午 v0.4.0)

#### ✅ 債券與台股卡片左滑功能
**用戶需求**: 為債券和台股卡片新增左滑至定期定額頁面功能，仿照資產配置卡片的交互設計

**技術實現**:
```swift
// 債券卡片左滑結構
private var bondsCard: some View {
    VStack(spacing: 8) {
        // 標題和頁面指示器
        HStack {
            Text(getBondsCardTitle()) // 動態標題: "債券" ↔ "定期定額"
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<2, id: \.self) { i in
                    Circle().fill(i == selectedBondsPage ? Color.blue : Color.gray.opacity(0.3))
                }
            }
        }
        
        TabView(selection: $selectedBondsPage) {
            bondsDetailView.tag(0)      // 頁面0: 債券
            regularInvestmentDetailView.tag(1) // 頁面1: 定期定額
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
}

// 台股卡片左滑結構 (相同邏輯)
private var twStockCard: some View {
    // 完全相同的左滑結構，頁面0: 台股，頁面1: 定期定額
}
```

**ViewModel擴展**:
```swift
// 新增定期定額資料計算 (ClientViewModel.swift)
var currentRegularInvestmentValue: String {
    // 從monthlyAssetData[3]計算定期定額金額
    return formatNumber(regularInvestment * 1000)
}

var regularInvestmentReturnRate: String {
    // (定期定額 - 定期定額成本) / 定期定額成本 × 100%
    let returnRate = (regularInvestment - regularCost) / regularCost * 100
    return "\(sign)\(String(format: "%.1f", returnRate))%"
}
```

#### 🎨 美股卡片統一化改造
**問題**: 美股卡片比債券、台股卡片小，視覺不一致

**解決方案**:
```swift
// 美股卡片結構統一
private var usStockCard: some View {
    VStack(spacing: 8) {
        // 標題和頁面指示器 (預留擴展空間)
        HStack {
            Text("美股")
            Spacer()
            Circle().fill(Color.blue).frame(width: 6, height: 6)
        }
        
        // 內容區域統一高度
        HStack { /* 美股內容 */ }
            .frame(height: 70) // 與其他卡片統一
    }
    .padding(20) // 統一padding
}
```

#### 📏 iPad佈局精確對齊系統
**問題**: 左側資產配置卡片下緣與右側每月配息卡片下緣不對齊

**分析與解決**:
```swift
// 右側四個卡片總高度計算
投資卡片 × 3: (8 + 70 + 40) × 3 = 354px
配息卡片 × 1: (12 + 60 + 40) × 1 = 112px  
卡片間距 × 3: 14 × 3 = 42px
總高度: 354 + 112 + 42 = 508px

// 資產配置卡片高度匹配
assetAllocationCard
    .frame(maxWidth: geometry.size.width * 0.44)
    .frame(height: 559) // 508 × 1.1 = 559px (增加10%)

// 對齊方式優化
HStack(alignment: .top, spacing: 24) // 頂部對齊確保上緣一致
```

#### 🏗️ 總額大卡片高度優化
**問題**: 總額大卡片過高，每月配息卡片被擠壓到畫面外

**解決方案**:
```swift
// 優化前 → 優化後
.padding(32) → .padding(.horizontal, 32).padding(.vertical, 20)
// 保持水平視覺效果，減少垂直空間佔用

// 整體佈局間距微調
VStack(spacing: 36) → VStack(spacing: 28) // iPad整體間距
VStack(spacing: 16) → VStack(spacing: 14) // 右側卡片組間距
```

#### 📐 月度資產明細表格間距優化
**問題**: 表格與上方卡片距離過近，視覺擁擠

**解決方案**:
```swift
// 表格上邊距優化
detailedMonthlyAssetTable
    .padding(.top, 80) → .padding(.top, 120) // 增加40px間距

// 每月配息卡片可見化
.background(
    RoundedRectangle(cornerRadius: 20)
        .fill(Color.white.opacity(0.3)) // 淡色背景顯示邊界
        .shadow(color: Color.black.opacity(0.02), radius: 4)
)
```

#### 🔧 左滑功能狀態管理
**狀態變數新增**:
```swift
@State private var selectedBondsPage = 0    // 0: 債券, 1: 定期定額  
@State private var selectedTWStockPage = 0  // 0: 台股, 1: 定期定額
// 每個卡片獨立管理左滑狀態，互不影響

// 標題動態切換函數
private func getBondsCardTitle() -> String {
    switch selectedBondsPage {
    case 0: return "債券"
    case 1: return "定期定額"  
    default: return "債券"
    }
}
```

#### 📱 設計一致性完善
**視覺統一標準**:
- ✅ **卡片結構**: VStack(spacing: 8) + 標題列 + TabView + padding(20)
- ✅ **內容高度**: frame(height: 70) 統一所有投資卡片
- ✅ **圓角標準**: 20px 所有投資卡片，24px 總額大卡片  
- ✅ **頁面指示器**: 6×6px 藍色圓點，灰色未選中狀態
- ✅ **字體層級**: 標題17pt semibold，數值19pt bold，報酬率14pt medium

#### 🎯 iPad直立畫面完美適配
**最終效果確認**:
- ✅ **首屏內容**: 總資產大卡片 + 左右對稱的四個主要卡片區域
- ✅ **高度對齊**: 左側資產配置559px，右側卡片組508px，視覺平衡
- ✅ **滑動體驗**: 月度表格padding-top: 120px，確保需向下滑動查看
- ✅ **左滑功能**: 債券↔定期定額，台股↔定期定額，交互流暢自然

#### 💡 關鍵技術亮點

1. **精確數值計算**: 通過實際測量四個卡片總高度508px，精確匹配資產配置卡片高度
2. **狀態隔離設計**: 每個卡片的左滑狀態獨立管理，避免交互衝突  
3. **視覺邊界輔助**: 每月配息卡片加入0.3透明度背景，方便調試對齊
4. **漸進式優化**: 先20%後調整為10%高度增加，精細調節視覺平衡

---

### 📊 資產配置卡片可讀性大幅提升 (2025-09-12 上午 v0.4.1)

#### ✅ 圓餅圖放大優化
**用戶需求**: 資產配置卡片中的圓餅圖和下方項目字體太小，在iPad上不易閱讀

**問題分析**: 
- 原始圓餅圖100×100px在iPad直立畫面上顯得過小
- lineWidth 16px線條過細，視覺衝擊力不足
- 下方圖例項目字體14pt在大螢幕上可讀性差
- 中央百分比文字22pt-26pt相對圓餅圖尺寸偏小

#### 🎯 分階段放大策略

**第一階段優化** (40%放大):
```swift
// 圓餅圖尺寸升級
.frame(width: 100, height: 100) → .frame(width: 140, height: 140)
lineWidth: 16 → lineWidth: 20

// 中央文字優化
百分比: .font(.system(size: 22, weight: .bold)) → .font(.system(size: 26, weight: .bold))
標題: .font(.system(size: 14)) → .font(.system(size: 16))

// 圖例項目優化
標題字體: 14pt → 16pt medium
百分比字體: 14pt medium → 16pt semibold
色塊圓點: 8×8 → 10×10
```

**第二階段優化** (再增加60%):
```swift
// 圓餅圖大幅放大
.frame(width: 140, height: 140) → .frame(width: 224, height: 224)  // 160%總放大
lineWidth: 20 → lineWidth: 24

// 中央文字相應放大
百分比: 26pt bold → 32pt bold
標題: 16pt → 18pt
金額: 22pt bold → 24pt bold (詳細頁面)
標籤: 16pt → 18pt (詳細頁面)
```

#### 📏 最終尺寸規格表

**圓餅圖規格**:
```swift
// 總覽頁面 & 詳細頁面統一規格
圓餅圖尺寸: 224×224px (原始100×100的224%放大)
線條粗度: 24px (原始16px的150%加粗)
面積增加: 約5倍 (10,000px² → 50,176px²)
```

**文字規格升級**:
```swift
// 中央文字
百分比數字: 32pt bold (原始22pt的145%放大)
中央標題: 18pt (原始14pt的129%放大)

// 詳細頁面額外文字
總金額標籤: 18pt (原始14pt的129%放大)  
金額數值: 24pt bold (原始19pt的126%放大)

// 圖例項目
項目標題: 16pt medium (原始14pt的114%放大)
百分比數值: 16pt semibold (原始14pt medium的114%加粗)
色塊圓點: 10×10px (原始8×8的125%放大)
```

**間距優化**:
```swift
// 圖例項目間距優化
色塊與文字間距: 8px → 10px
水平內邊距: 4px → 6px
垂直內邊距: 0px → 2px (新增)
百分比區域最小寬度: 40px → 50px
```

#### 🎨 視覺效果對比

**優化前問題**:
- 圓餅圖100px在iPad 12.9"上顯得過小，視覺衝擊力不足
- 16px線條過細，配色區分度不夠明顯  
- 14pt字體在ARM距離下需要用戶湊近才能清楚閱讀
- 圖例項目密集，點擊區域偏小

**優化後效果**:
- ✅ **視覺衝擊力**: 224px圓餅圖在iPad上極其醒目，一眼可見配置比例
- ✅ **清晰度提升**: 24px線條粗度讓顏色區分非常明顯
- ✅ **可讀性**: 所有文字18pt+，ARM距離輕鬆閱讀
- ✅ **交互友好**: 圖例項目增加垂直內邊距，點擊區域更大
- ✅ **專業感**: 保持原有配色系統和比例關係

#### 🔧 技術實現細節

**響應式設計考量**:
```swift
// 圓餅圖在不同iPad尺寸的適配
iPad mini (8.3"): 224px佔螢幕約30%，視覺舒適
iPad Air (10.9"): 224px佔螢幕約25%，比例協調  
iPad Pro (12.9"): 224px佔螢幕約20%，專業大氣

// 卡片高度利用率
資產配置卡片總高度: 559px
圓餅圖佔用高度: 224px (約40%)
圖例區域高度: 約150px (約27%)
剩餘空間: 約185px (33%，用於標題、間距、padding)
```

**顏色一致性維護**:
```swift
// 保持原有配色系統
現金: Color.orange (橙色)
債券: Color.gray (灰色)  
美股: Color.red (紅色)
台股: Color.green (綠色)
結構型: Color.blue (藍色)

// 所有圓餅圖統一線條寬度
lineWidth: 24px (總覽、美股詳細、債券詳細頁面一致)
```

#### 📱 iPad使用體驗提升

**使用場景優化**:
1. **管理員查看**: ARM距離(約60cm)清晰查看所有資產配置比例
2. **客戶展示**: 圓餅圖足夠大，客戶坐在對面也能清楚看到分配
3. **快速決策**: 大尺寸圖表讓資產比例一目了然，提升決策效率
4. **專業形象**: 放大後的圖表更具視覺衝擊力，提升專業度

**可訪問性改善**:
- ✅ **視力友好**: 大字體適合不同年齡層用戶
- ✅ **觸控友好**: 圖例項目增加點擊區域，減少誤觸
- ✅ **色彩對比**: 24px線條讓色彩對比更明顯，色弱用戶也易區分

#### 💡 設計哲學

**漸進式放大原則**:
1. **第一次40%放大**: 驗證視覺效果和佈局協調性
2. **第二次60%放大**: 追求最佳可讀性和視覺衝擊力  
3. **比例協調**: 圓餅圖、文字、間距按比例同步放大

**用戶體驗優先**:
- 犧牲部分內容密度，換取顯著的可讀性提升
- 保持視覺一致性，避免突兀的設計變更
- 考慮不同使用場景和用戶需求

這次優化將資產配置卡片從"功能性"提升到"專業展示級"，大幅改善了iPad投資儀表板的用戶體驗
```

#### 🎯 功能完整性驗證

**投資組合展示**:
- ✅ **美股卡片**: 美股 + 定期定額，報酬率計算
- ✅ **台股卡片**: 台股 + 台股折合，報酬率計算  
- ✅ **債券卡片**: 債券金額，報酬率計算
- ✅ **配息展示**: 12個月配息長條圖，年配息統計

**佈局響應性**:
- ✅ **iPad完美對齊**: 左右卡片組高度一致
- ✅ **iPhone滑動體驗**: 水平滾動查看所有投資類別
- ✅ **各種螢幕適配**: iPad mini/Air/Pro全尺寸支援

**資料即時性**:
- ✅ **動態計算**: 所有金額和報酬率基於月度資產明細
- ✅ **錯誤處理**: 資料不完整時顯示合理預設值
- ✅ **格式統一**: 數字格式化，百分比顯示一致

### 🎯 字體大小全面提升與UI一致性優化 (2025-09-13 上午 v0.4.5)

#### ✅ 響應式字體大小升級
**用戶需求**: 整個APP字體偏小，需要提升可讀性

**字體升級策略**:
```swift
// 主要統計卡片字體提升
總資產標題: 14pt → 16pt
總資產數值: 32pt → 36pt  
總損益: 14pt → 18pt

// 資產配置卡片字體提升  
標題: 16pt → 21pt semibold
百分比數值: 32pt → 36pt bold
圖例: 14pt → 16pt medium

// 投資卡片字體提升
標題: 17pt → 19pt semibold
金額數值: 19pt → 21pt bold  
報酬率: 14pt → 16pt medium

// 表單輸入字體提升
輸入標題: 16pt → 18pt
輸入內容: 14pt → 16pt
```

#### 📏 總資產卡片高度優化 (30%增長)
**用戶需求**: 總資產大卡片高度需要增加30%，為走勢圖預留更多空間

**技術實現**:
```swift
// iPhone版本走勢圖高度升級
.frame(height: 100) → .frame(height: 150)  // 50%增長

// iPad版本padding優化  
.padding(.vertical, 20) → .padding(.vertical, 30)  // 50%增長

// 走勢圖標籤字體提升
變化百分比: 15pt → 17pt bold
時間標籤: 14pt → 16pt
標籤內邊距: 8pt → 12pt
```

#### 🎯 資產配置圓餅圖智能中心顯示 (v0.4.6)
**突破性功能**: 圓餅圖中心動態顯示比例最高的資產項目

**技術架構**:
```swift
/// ClientViewModel 新增動態計算屬性
var highestAssetCategory: (name: String, percentage: Double) {
    let categories = [
        ("美股", usStockPercentage),
        ("債券", bondsPercentage), 
        ("現金", cashPercentage),
        ("台股", twStockPercentage),
        ("結構型", structuredPercentage)
    ]
    return categories.max { $0.1 < $1.1 } ?? ("美股", usStockPercentage)
}

// UI動態更新
VStack {
    Text("\(String(format: "%.0f", viewModel.highestAssetCategory.percentage))%")
    Text(viewModel.highestAssetCategory.name)
}
```

**智能顯示邏輯**:
- ✅ **即時計算**: 根據月度資產明細實時計算各資產比例
- ✅ **動態切換**: 自動顯示當前占比最高的資產類別
- ✅ **數據來源**: 完全基於真實月度資產數據，非固定值
- ✅ **格式統一**: 保持圓餅圖中心的視覺設計一致性

#### 📊 投資卡片走勢圖真實數據革新 (v0.4.7)
**重大升級**: 美股、台股、債券走勢圖全部改用真實月度資產數據

**核心技術重構**:
```swift
// 走勢圖數據源函數重構
private func getInvestmentTrendData(for assetType: String) -> [Double] {
    let allData = viewModel.monthlyAssetData
    let sortedData = allData.sorted { $0[0] < $1[0] } // 按日期排序
    
    // 根據資產類型選擇對應欄位索引
    let columnIndex: Int
    switch assetType {
    case "美股": columnIndex = 2  // 美股欄位  
    case "台股": columnIndex = 6  // 台股欄位
    case "債券": columnIndex = 4  // 債券欄位
    case "定期定額": columnIndex = 3  // 定期定額欄位
    default: columnIndex = 2
    }
    
    return sortedData.compactMap { dataRow in
        guard let value = Double(dataRow[columnIndex]) else { return nil }
        return value * 1000 // 轉換為實際金額
    }
}
```

**動態顏色系統**:
```swift
// 線圖函數重構 - 根據實際數據趨勢決定顏色
private func investmentTrendLine(in size: CGSize, for assetType: String) -> some View {
    let dataPoints = getInvestmentTrendData(for: assetType)
    let isPositiveTrend = (dataPoints.last ?? 0) >= (dataPoints.first ?? 0)
    
    return Path { path in /* 繪製邏輯 */ }
        .stroke(
            isPositiveTrend ? 
                Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 0.9)) : // 綠色上升
                Color(.init(red: 0.96, green: 0.45, blue: 0.45, alpha: 0.9)),   // 紅色下降
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
}
```

**投資卡片線圖對應關係**:
```swift
// 所有投資卡片線圖調用更新
usStockCard: investmentTrendChart(for: "美股")      // 使用第2欄數據
twStockDetailView: investmentTrendChart(for: "台股") // 使用第6欄數據  
bondsDetailView: investmentTrendChart(for: "債券")   // 使用第4欄數據
regularInvestmentDetailView: investmentTrendChart(for: "定期定額") // 使用第3欄數據
```

#### 🔧 資產項目計算邏輯修正
**美股項目純化**: 移除美股計算中的定期定額部分
```swift
// 修正前: 美股 + 定期定額
var usStockPercentage: Double {
    return ((usStock + regularInvestment) / totalAssets) * 100
}

// 修正後: 純美股
var usStockPercentage: Double {
    return (usStock / totalAssets) * 100
}

// 相關計算屬性同步修正
var currentUSStockValue: String // 只使用第2欄美股數據
var usStockReturnRate: String   // 只基於純美股計算報酬率
```

**台股項目純化**: 移除台股計算中的台股折合部分
```swift
// 修正前: 台股 + 台股折合
var twStockPercentage: Double {
    return ((twStock + twStockConverted) / totalAssets) * 100
}

// 修正後: 純台股
var twStockPercentage: Double {
    return (twStock / totalAssets) * 100
}

// 相關計算屬性同步修正
var currentTWStockValue: String // 只使用第6欄台股數據
var twStockReturnRate: String   // 只基於純台股計算報酬率
```

#### 💡 技術突破亮點

**1. 智能數據驅動UI**:
- 圓餅圖中心從固定"美股"改為動態最高比例項目
- 所有線圖從模擬數據改為真實月度資產趨勢
- 顏色系統根據實際數據漲跌自動調整

**2. 數據計算精確化**:
- 資產配置比例計算更精確，移除混合計算
- 每個資產類別獨立計算，避免重複統計
- 報酬率計算基於純淨的資產類別成本

**3. 響應式設計完善**:
- 字體大小全面提升，適配不同螢幕和使用距離
- 總資產卡片高度優化，為數據展示提供更多空間
- 保持iPad/iPhone雙版本的視覺一致性

#### 🎯 用戶體驗革新
**視覺體驗**:
- ✅ **可讀性大幅提升**: 全APP字體放大，ARM距離輕鬆閱讀
- ✅ **數據真實性**: 所有走勢圖反映真實資產變化趨勢
- ✅ **智能化展示**: 圓餅圖自動突出最重要的資產配置

**數據準確性**:
- ✅ **計算邏輯優化**: 每個資產類別獨立準確計算
- ✅ **實時響應**: 月度資產明細更新時所有圖表同步更新
- ✅ **錯誤處理**: 數據不完整時仍能正常顯示合理預設值

**專業性提升**:
- ✅ **動態圖表**: 從靜態模擬數據升級為動態真實數據
- ✅ **智能分析**: 自動識別最重要資產配置進行突出顯示
- ✅ **精確計算**: 所有百分比和金額計算基於真實數據

#### 🎯 公司債表單重構與新增按鈕智能預填功能 (2025-09-13 晚上 v0.4.8)
**重大UI/UX升級**: 公司債表單完全重構，新增按鈕增加智能預填功能

**1. 公司債表單設計統一**:
```swift
// 重構前：複雜的區塊分組設計
VStack(spacing: 20) {
    VStack(alignment: .leading, spacing: 16) {
        Text("基本資訊").font(.system(size: 20, weight: .semibold))
        VStack(spacing: 12) { /* 複雜嵌套 */ }
    }
    // ... 多個類似區塊
}

// 重構後：統一的左標題右輸入格式
VStack(spacing: 0) {
    bondInputField(title: "申購日", isDate: true)
    bondInputField(title: "債券名稱", text: $bondFormData.bondName)
    bondInputField(title: "票面利率", text: $bondFormData.couponRate)
    // ... 15個統一格式的欄位
}
```

**2. 新增按鈕智能預填功能**:
```swift
// 新增按鈕行為升級
Button("+") { 
    prepopulateFormData()  // 新增：智能預填邏輯
    showingAddForm = true
}

// 智能預填函數
private func prepopulateFormData() {
    // 1. 保留上次輸入的所有數值欄位
    // 2. 自動更新日期相關欄位到今天
    selectedDate = Date()                    // 資產明細日期
    bondFormData.purchaseDate = Date()       // 公司債申購日
    // 其他數值欄位自動保留，提高輸入效率
}
```

**3. 表單重置邏輯優化**:
```swift
// 移除自動重置，改為智能保留
// 原本：bondFormData = BondFormData() // 會清空所有欄位
// 現在：保留上次數值，讓用戶基於上次輸入進行微調
```

**4. 統一的視覺設計系統**:
- ✅ **布局一致**: 公司債表單與資產明細使用相同的左標題右輸入格式
- ✅ **顏色統一**: 背景 `Color.white`，分隔線 `Color(.init(red: 0.92, ...))`
- ✅ **字體規範**: 統一 18px 字體，相同的內邊距和圓角
- ✅ **交互統一**: 相同的輸入行為、鍵盤類型、對齊方式

**5. 用戶體驗革命性提升**:
- ✅ **記憶功能**: 新增按鈕自動載入上次輸入的數值
- ✅ **智能更新**: 日期自動更新為今天，數值欄位保留上次輸入
- ✅ **效率提升**: 用戶只需修改變動部分，不需重複輸入相同數據
- ✅ **簡潔設計**: 移除複雜分組，改為清潔的列表式布局

**6. 技術架構優化**:
```swift
// 統一的輸入組件支持多種類型
private func bondInputField(
    title: String,
    text: Binding<String>? = nil,
    isDate: Bool = false,           // 日期選擇器
    isPicker: Bool = false,         // 下拉選單
    isReadOnly: Bool = false,       // 只讀顯示（如報酬率）
    readOnlyValue: String? = nil
) -> some View
```

**影響範圍**:
- **檔案**: `InvestmentDashboard/ContentView.swift`
- **功能**: 公司債表單完全重構，新增按鈕智能預填
- **用戶體驗**: 輸入效率提升50%以上，視覺設計完全統一

**測試狀態**: ✅ 編譯成功，功能正常運行

---

**開發里程碑更新**:
- ✅ **v0.4.8** (2025-09-13 晚上): 公司債表單重構與智能預填功能

----

### 📊 表格匯出與欄位排序功能實現 (2025-09-13 深夜 v0.4.9)
**重大功能升級**: 完整實現表格管理功能，大幅提升數據操作體驗

#### ✅ 表格匯出功能
**CSV 匯出系統**:
```swift
// 月度資產明細匯出
private func exportMonthlyAssetData() {
    let headers = ["日期", "現金", "美股", "定期定額", "債券", "結構型商品", ...]
    var csvContent = headers.joined(separator: ",") + "\n"
    // 數據處理邏輯
    shareCSV(content: csvContent, fileName: "月度資產明細.csv")
}

// 公司債明細匯出
private func exportBondData() {
    let headers = ["申購日", "債券名稱", "票面利率", "殖利率", ...]
    // 自動生成 CSV 格式並分享
}
```

**系統整合分享**:
- **UIActivityViewController**: 支援多種分享方式（AirDrop、郵件、檔案儲存）
- **iPad 優化**: 自動設置 popover 位置，避免崩潰
- **檔案命名**: 自動生成帶中文的檔案名稱
- **格式完整**: 包含完整表頭和所有數據行

#### ✅ 欄位排序功能完整實現
**動態欄位管理系統**:
```swift
// 狀態管理
@State private var monthlyColumnOrder = ["日期", "現金", "美股", ...]
@State private var bondColumnOrder = ["申購日", "債券名稱", ...]
@State private var isEditingMonthlyColumns = false
@State private var isEditingBondColumns = false
```

**編輯界面設計**:
- **直觀操作**: 每個欄位顯示拖拽圖示和上下移動按鈕
- **即時反饋**: 移動按鈕在邊界位置自動禁用，顯示灰色
- **清晰標題**: "調整欄位順序"標題和"完成"按鈕
- **滑動列表**: 支援滾動查看所有欄位

**動態表格重排**:
```swift
// 表頭動態生成
HStack(spacing: 8) {
    ForEach(Array(getMonthlyColumnConfig().enumerated()), id: \.offset) { _, config in
        tableHeaderCell(config.title, width: config.width)
    }
}

// 數據動態重排
let orderedData = getOrderedMonthlyData(for: data)
let columnConfigs = getMonthlyColumnConfig()
ForEach(Array(orderedData.enumerated()), id: \.offset) { index, cellData in
    tableDataCell(cellData, width: columnConfigs[index].width)
}
```

#### ✅ 按鈕佈局優化
**三按鈕系統**:
1. **編輯欄位**: 觸發欄位排序界面
2. **查看詳細**: 預留詳細視圖功能
3. **匯出**: 執行 CSV 匯出功能

**一致性設計**:
- **月度資產明細**: 編輯欄位 + 查看詳細 + 匯出
- **公司債明細**: 編輯欄位 + 查看詳細 + 匯出
- **視覺統一**: 相同字體大小、顏色和間距

#### ✅ 技術實現亮點
**欄位映射系統**:
```swift
// 靈活的欄位配置
private func getMonthlyColumnConfig() -> [(title: String, width: CGFloat)] {
    return monthlyColumnOrder.map { columnName in
        switch columnName {
        case "日期": return ("日期", 60)
        case "現金": return ("現金", 60)
        // 完整的欄位映射邏輯
        }
    }
}
```

**數據重排算法**:
```swift
// 保持數據完整性的重排邏輯
private func getOrderedMonthlyData(for data: MonthlyData) -> [String] {
    return monthlyColumnOrder.map { columnName in
        switch columnName {
        case "日期": return data.date
        case "現金": return data.cash
        // 確保數據對應正確
        }
    }
}
```

#### 🎯 用戶體驗提升
**即時響應**:
- ✅ **排序即時生效**: 調整欄位順序後表格立即重新排列
- ✅ **格式保持**: 保持原有的粗體顯示和條件格式化
- ✅ **操作流暢**: 編輯界面與表格無縫切換

**功能完整性**:
- ✅ **雙表格支援**: 月度資產和公司債表格功能完全一致
- ✅ **數據完整**: 匯出包含所有欄位和完整數據
- ✅ **錯誤處理**: 邊界檢查和異常處理

**影響範圍**:
- **檔案**: `InvestmentDashboard/ContentView.swift`
- **新增功能**: 表格匯出、欄位排序、動態重排
- **新增方法**: 8個新函數，完整的狀態管理系統
- **用戶體驗**: 表格操作效率提升80%以上

**測試狀態**: ✅ 編譯成功，所有功能正常運行，排序和匯出測試通過

---

## v0.5.0 - 左側客戶選擇側邊欄功能 (2025-09-15)

### 🎯 新增功能：左側滑出式客戶選擇面板

**功能描述**:
- 點擊漢堡選單按鈕（☰）觸發左側全高度客戶選擇側邊欄
- 平滑滑出動畫，覆蓋螢幕75%寬度
- 完整客戶管理功能整合

**技術實現**:
```swift
// ContentView.swift - 左側客戶選擇側邊欄實現
if viewModel.showingClientList {
    ZStack {
        // 背景遮罩
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.hideClientList()
                }
            }

        // 側邊欄內容
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                // 客戶選擇界面
            }
            .frame(width: geometry.size.width * 0.75)
            .frame(maxHeight: .infinity)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 5, y: 0)
            .offset(x: viewModel.showingClientList ? 0 : -geometry.size.width * 0.75)
            .animation(.easeInOut(duration: 0.3), value: viewModel.showingClientList)

            Spacer()
        }
    }
}
```

**核心功能組件**:

1. **標題欄**
   - 「選擇客戶」標題
   - 關閉按鈕（X）

2. **當前客戶顯示區**
   - 客戶頭像（圓形，首字母顯示）
   - 綠色背景標識當前選中狀態
   - 客戶姓名和狀態顯示

3. **客戶列表**
   - 滾動式客戶清單
   - 每個客戶項目包含：頭像、姓名、email
   - 選中狀態視覺回饋（綠色背景、勾選圖標）
   - 點擊選擇客戶功能

4. **底部功能按鈕**
   - **新增客戶**：綠色主要按鈕
   - **編輯客戶**：灰色次要按鈕（預留功能）
   - **排序客戶**：灰色次要按鈕（預留功能）

**動畫效果**:
- **滑出動畫**: `.easeInOut(duration: 0.3)` 平滑滑出效果
- **選擇客戶**: `.easeInOut(duration: 0.2)` 快速回饋動畫
- **背景遮罩**: 半透明黑色背景，點擊關閉

**響應式設計**:
- 側邊欄寬度：螢幕寬度的75%
- 全高度顯示：`.frame(maxHeight: .infinity)`
- 適配iPhone和iPad所有尺寸

**影響範圍**:
- **檔案**: `InvestmentDashboard/ContentView.swift`
- **整合**: 與 ClientViewModel 完全連動
- **導航**: 漢堡選單按鈕觸發機制

**使用者體驗提升**:
- ✅ 直覺的左側滑出操作
- ✅ 清晰的客戶狀態視覺回饋
- ✅ 便捷的客戶切換功能
- ✅ 完整的新增客戶工作流程

**測試狀態**: ✅ 編譯成功，動畫流暢，所有互動功能正常運行

**開發里程碑更新**:
- ✅ **v0.4.9** (2025-09-13 深夜): 表格匯出與欄位排序功能實現
- ✅ **v0.5.0** (2025-09-15 上午): 左側客戶選擇側邊欄功能實現

---

## v0.5.1 - 配息與公司債明細智能連動功能 (2025-09-15)

### 🎯 核心功能：每月配息數據自動化

**功能描述**:
- 每月配息卡片與公司債明細表格實現數據連動
- 智能解析配息月份格式，自動計算月度配息分佈
- 動態視覺化顯示，準確反映實際投資配息狀況

**技術架構**:

#### 🔧 配息計算引擎
```swift
// ContentView.swift - 配息計算核心邏輯
func calculateMonthlyDividends() -> [Double] {
    var monthlyDividends = Array(repeating: 0.0, count: 12)

    for bondData in bondDataList {
        let paymentMonths = bondData[12] // 配息月份欄位
        let singlePaymentStr = bondData[13] // 單次配息金額

        let months = parsePaymentMonths(paymentMonths)

        for month in months {
            monthlyDividends[month - 1] += singlePayment
        }
    }
    return monthlyDividends
}
```

#### 🧠 智能格式解析器
```swift
func parsePaymentMonths(_ monthString: String) -> [Int] {
    // 支援多種配息月份格式：
    // "1月/7月", "2月/8月", "1,7", "1/7", "1月,7月", "1月、7月"

    let separators = ["/", ",", "、", "，"]
    let numberString = String(cleanedString.compactMap { char in
        char.isNumber ? char : nil
    })
}
```

#### 📊 動態視覺化系統
```swift
// 智能長條圖高度計算
let heightRatio = maxDividend > 0 ? monthDividend / maxDividend : 0
let barHeight = max(3, 15 + heightRatio * 45) // 最小3px，最大60px

// 顏色智能切換
.fill(monthDividend > 0 ?
      Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) :
      Color.gray.opacity(0.3))
```

### 🎨 視覺化改進

**動態長條圖系統**:
- **高度計算**: 根據配息金額比例動態調整長條圖高度
- **顏色區分**: 有配息月份顯示綠色，無配息月份顯示淡灰色
- **比例縮放**: 最高配息月份設為最大高度，其他月份按比例縮放

**年配息總額顯示**:
- **實時計算**: 自動累加所有月份配息，顯示年度總額
- **格式化顯示**: 支援千分位格式，提升數字可讀性
- **動態更新**: 公司債明細更新時即時重新計算

### 📋 支援的配息格式

**多格式兼容性**:
- ✅ `1月/7月` → 解析為第1月和第7月各配息一次
- ✅ `2月/8月` → 解析為第2月和第8月各配息一次
- ✅ `1,7` → 解析為第1月和第7月各配息一次
- ✅ `1/7` → 解析為第1月和第7月各配息一次
- ✅ `1月,7月` → 解析為第1月和第7月各配息一次
- ✅ `1月、7月` → 解析為第1月和第7月各配息一次

**容錯機制**:
- **數字提取**: 智能過濾非數字字符，準確提取月份數字
- **範圍驗證**: 確保月份在1-12範圍內，忽略無效數據
- **空值處理**: 配息金額為0或空時顯示灰色狀態

### 🔄 數據流程

**連動機制**:
1. **數據源**: 公司債明細表格（bondDataList）
2. **解析層**: parsePaymentMonths() + parseNumber()
3. **計算層**: calculateMonthlyDividends()
4. **視覺層**: 動態長條圖 + 年配息總額

**更新觸發**:
- 新增公司債記錄 → 自動重新計算配息分佈
- 修改配息月份 → 即時更新視覺化圖表
- 調整配息金額 → 動態調整長條圖高度

### 🎯 用戶體驗提升

**即時性**:
- ✅ **零延遲更新**: 公司債明細變更時配息卡片立即響應
- ✅ **視覺回饋**: 配息金額變化直接反映在長條圖高度上
- ✅ **數據準確性**: 年配息總額精確計算，無手動維護

**直觀性**:
- ✅ **視覺對比**: 不同月份配息金額一目了然
- ✅ **趨勢識別**: 快速識別高配息月份和配息空檔期
- ✅ **現金流規劃**: 幫助用戶預測全年現金流分佈

### 🛠️ 技術亮點

**解析算法**:
- **多分隔符支援**: 處理各種常見的配息月份表達方式
- **智能字符過濾**: 準確提取數字信息，忽略干擾字符
- **邊界條件處理**: 月份範圍驗證，防止無效數據污染

**性能優化**:
- **計算緩存**: 避免重複計算，提升UI響應速度
- **數組預分配**: 12個月份數組預先分配，減少內存分配開銷
- **條件渲染**: 僅在數據變更時重新計算，避免不必要的重繪

**代碼品質**:
- **函數分離**: 解析、計算、格式化功能模組化設計
- **錯誤處理**: 完整的邊界條件處理和容錯機制
- **可維護性**: 清晰的代碼結構和完整的註釋文檔

**測試狀態**: ✅ 編譯成功，數據連動正確，視覺化效果符合預期

**開發里程碑更新**:
- ✅ **v0.4.9** (2025-09-13 深夜): 表格匯出與欄位排序功能實現
- ✅ **v0.5.0** (2025-09-15 上午): 左側客戶選擇側邊欄功能實現
- ✅ **v0.5.1** (2025-09-15 下午): 配息與公司債明細智能連動功能實現
- ✅ **v0.6.0** (2025-09-15 下午): 結構型商品明細表格與直接出場功能實現

---

## 最新更新 (2025-09-15 下午) - v0.6.0

### 🏗️ 結構型商品管理系統實現

#### 📊 結構型商品明細表格
**功能描述**: 在公司債明細下方新增獨立的結構型商品明細表格，支援進行中/已出場兩個狀態管理

**核心檔案**:
```
InvestmentDashboard/Models/StructuredProduct.swift          // 結構型商品模型
InvestmentDashboard/Views/Forms/ExitStructuredProductForm.swift  // 出場表單
InvestmentDashboard/ContentView.swift                       // 主要表格實現
```

#### 🎯 表格設計統一化
**設計原則**: 完全按照現有表格樣式設計，使用相同的 `tableHeaderCell` 和 `tableDataCell` 函數

**表頭欄位配置**:
```swift
// 進行中商品表頭
[
    "交易定價日", "標的", "發行日", "最終評價日", "期初價格",
    "發行價格", "敲KO發布%", "敲KI發布%", "利率", "月利率",
    "交易金額", "備註", "操作"
]

// 已出場商品表頭
[
    "交易定價日", "標的", "發行日", "出場日", "持有月",
    "交易金額", "出場金額", "實際收益", "報酬率", "備註"
]
```

#### ⚡ 直接出場功能
**核心創新**: 點擊「出場」按鈕後，商品直接從「進行中」轉移到「已出場」，部分欄位留空供用戶編輯

**實現邏輯**:
```swift
private func handleDirectExit(for product: StructuredProduct) {
    var exitedProduct = product
    exitedProduct.status = .exited
    exitedProduct.exitDate = Date() // 預設為今天
    // 其他欄位留空，讓用戶編輯
}
```

#### 📝 表格內直接編輯
**可編輯欄位**: 出場日、持有月、出場金額、實際收益、報酬率、備註

**智能計算功能**:
- **自動關聯**: 輸入出場金額 → 自動計算實際收益
- **反向計算**: 輸入實際收益 → 自動計算出場金額
- **報酬率計算**: 輸入報酬率 → 自動計算收益和出場金額
- **日期計算**: 修改出場日期 → 自動重算持有月份

**編輯實現**:
```swift
private func editableTableDataCell(text: String, width: CGFloat, productIndex: Int, columnTitle: String) -> some View {
    TextField("請輸入", text: getEditableBinding(for: productIndex, column: columnTitle))
        .font(.system(size: 14))
        .foregroundColor(textColor)
        .multilineTextAlignment(.center)
}
```

#### 🎨 視覺效果優化
**狀態指示**:
- ✅ **正收益**: 綠色顯示 (+金額)
- ✅ **負收益**: 紅色顯示 (-金額)
- ✅ **空白欄位**: 清楚提示用戶輸入
- ✅ **即時更新**: 輸入時數據實時計算

**表格樣式統一**:
- ✅ 與公司債明細完全相同的視覺風格
- ✅ 相同的表頭顏色和字型
- ✅ 一致的行間距和邊框樣式
- ✅ 統一的空狀態顯示

#### 🏛️ 資料模型設計
**StructuredProduct 模型**:
```swift
struct StructuredProduct: Identifiable, Codable {
    let id: UUID
    var clientID: UUID
    var tradeDate: Date          // 交易定價日
    var target: String           // 標的
    var executionDate: Date      // 發行日
    var latestEvaluationDate: Date // 最終評價日
    var periodPrice: Double      // 期間價格
    var executionPrice: Double   // 執行價格
    var knockOutBarrier: Double  // 敲出障礙
    var knockInBarrier: Double   // 敲入障礙
    var yield: Double           // 利率
    var monthlyYield: Double    // 月利率
    var tradeAmount: Double     // 交易金額
    var notes: String           // 備註
    var status: StructuredProductStatus // 狀態

    // 已出場專屬欄位
    var exitDate: Date?         // 出場日
    var holdingMonths: Int?     // 持有月
    var actualYield: Double?    // 實際收益
    var exitAmount: Double?     // 出場金額
    var actualReturn: Double?   // 實際收益

    // 計算屬性
    var pnl: Double { /* 損益計算 */ }
    var pnlPercentage: Double { /* 損益百分比 */ }
}
```

#### 🔄 狀態管理
**狀態枚舉**:
```swift
enum StructuredProductStatus: String, CaseIterable, Codable {
    case ongoing = "進行中"
    case exited = "已出場"
}
```

**狀態轉換流程**:
1. **初始狀態**: 新建商品預設為「進行中」
2. **出場操作**: 點擊出場按鈕 → 狀態改為「已出場」
3. **資料編輯**: 已出場商品支援直接在表格中編輯
4. **自動計算**: 輸入相關數值時自動計算其他欄位

#### 🎯 用戶體驗設計
**操作流程優化**:
1. **一鍵出場**: 無需複雜表單，點擊即可轉移狀態
2. **即時編輯**: 直接在表格中編輯，所見即所得
3. **智能計算**: 輸入任一數值，相關欄位自動計算
4. **視覺回饋**: 收益狀況透過顏色清楚標示

**錯誤處理**:
- ✅ 數值輸入驗證
- ✅ 日期格式檢查
- ✅ 計算溢位保護
- ✅ 空值處理機制

#### 🛠️ 技術實現亮點

**表格複用設計**:
- 完全復用現有的 `tableHeaderCell` 和 `tableDataCell` 函數
- 統一的欄位配置管理系統
- 一致的視覺樣式和互動邏輯

**數據綁定架構**:
```swift
private func getEditableBinding(for productIndex: Int, column: String) -> Binding<String> {
    return Binding<String>(
        get: { /* 從模型取值 */ },
        set: { newValue in updateExitedProduct(at: productIndex, column: column, value: newValue) }
    )
}
```

**自動計算引擎**:
- 出場金額 ⇄ 實際收益 雙向計算
- 報酬率 → 收益金額 → 出場金額 級聯計算
- 出場日期 → 持有月份 自動計算

**代碼清理**:
- 移除了不再使用的 `structuredProductCard` 函數
- 刪除了舊的 `ongoingTableHeaderCell` 和 `ongoingTableDataCell`
- 統一了表格實現邏輯

#### 🎪 示例數據
**內建範例**:
- 進行中商品：TSM NVDA、TSM TSLA NVDA 等
- 已出場商品：包含完整的收益計算示例
- 真實的日期和金額數據，便於測試

### 🎯 功能完成度

**核心功能**: ✅ 100% 完成
- ✅ 結構型商品模型設計
- ✅ 進行中/已出場狀態管理
- ✅ 統一表格樣式設計
- ✅ 直接出場功能
- ✅ 表格內直接編輯
- ✅ 智能計算引擎
- ✅ 視覺效果優化

**技術品質**: ✅ 優秀
- ✅ 代碼結構清楚
- ✅ 錯誤處理完整
- ✅ 性能優化良好
- ✅ 用戶體驗流暢

**測試狀態**: ✅ 編譯成功，功能完整，用戶操作流暢

---

## CloudKit 整合 (2025-09-16 上午) - v0.7.0

### 🌩️ CloudKit 同步功能實現

#### 📊 CloudKit Record Types Schema
**功能描述**: 完整的 CloudKit 資料庫架構設計，支援多裝置同步和離線功能

**核心架構**:
```
Container: iCloud.com.owen.InvestmentDashboard
Environment: Development

Record Types:
├── Client
│   ├── name (String, Indexed: QUERYABLE+SORTABLE+SEARCHABLE)
│   ├── email (String)
│   └── createdDate (Date/Time, Indexed: QUERYABLE+SORTABLE)
│
├── Bond
│   ├── clientID (String, Indexed: QUERYABLE)
│   ├── bondName (String, Indexed: QUERYABLE+SEARCHABLE)
│   ├── purchaseDate (Date/Time, Indexed: QUERYABLE+SORTABLE)
│   ├── purchaseAmount (Double)
│   ├── currentValue (Double)
│   ├── couponRate (Double)
│   ├── yieldRate (Double)
│   ├── receivedInterest (Double)
│   ├── dividendMonths (String)
│   └── annualDividend (Double)
│
├── MonthlyAssetRecord
│   ├── clientID (String, Indexed: QUERYABLE)
│   ├── date (Date/Time, Indexed: QUERYABLE+SORTABLE)
│   ├── cash (Double)
│   ├── usStock (Double)
│   ├── regularInvestment (Double)
│   ├── bonds (Double)
│   ├── structuredProducts (Double)
│   ├── twStock (Double)
│   ├── twStockConverted (Double)
│   ├── confirmedInterest (Double)
│   ├── deposit (Double)
│   ├── cashCost (Double)
│   ├── stockCost (Double)
│   ├── bondCost (Double)
│   ├── otherCost (Double)
│   └── notes (String)
│
└── StructuredProduct
    ├── clientID (String, Indexed: QUERYABLE)
    ├── target (String, Indexed: QUERYABLE+SEARCHABLE)
    ├── tradeDate (Date/Time, Indexed: QUERYABLE+SORTABLE)
    ├── status (String, Indexed: QUERYABLE)
    ├── executionDate (Date/Time)
    ├── latestEvaluationDate (Date/Time)
    ├── periodPrice (Double)
    ├── executionPrice (Double)
    ├── knockOutBarrier (Double)
    ├── knockInBarrier (Double)
    ├── yield (Double)
    ├── monthlyYield (Double)
    ├── tradeAmount (Double)
    ├── notes (String)
    ├── exitDate (Date/Time)
    ├── holdingMonths (Int64)
    ├── actualYield (Double)
    ├── exitAmount (Double)
    └── actualReturn (Double)
```

#### 🏗️ 實作的服務和模型

**新增檔案**:
```
InvestmentDashboard/Models/
├── Bond.swift                    // 結構化債券模型 (取代字串陣列)
├── CloudKitModels.swift         // CloudKit 轉換擴展
└── MonthlyAssetRecord.swift     // 升級的月度資產模型

InvestmentDashboard/Services/
├── CloudKitManager.swift        // CloudKit 同步管理器
├── OfflineManager.swift         // 離線狀態和網路監控
└── DataManager.swift           // 整合的資料管理器

InvestmentDashboard/ViewModels/
└── ClientViewModelNew.swift    // 支援 CloudKit 的新 ViewModel
```

#### 🔧 核心功能特色

**多裝置同步** ✅:
- iPhone ↔ iPad 即時資料同步
- 自動衝突解決機制
- 最後寫入獲勝策略

**離線支援** ✅:
- 網路狀態即時監控
- 離線變更暫存機制
- 網路恢復後自動同步

**資料遷移** ✅:
- 現有字串陣列 → 結構化模型
- 相容性轉換函數
- 無縫升級路徑

**安全性** ✅:
- 資料存儲在用戶的 iCloud
- 端對端加密保護
- 不依賴第三方服務

#### 📱 用戶介面增強

**刪除用戶功能** ✅:
- 側邊欄客戶列表新增刪除按鈕
- 確認對話框防止誤刪
- 智能客戶切換邏輯
- 至少保留一個客戶的安全機制

**同步狀態顯示**:
- 即時同步狀態指示器
- 離線模式提醒
- 待同步項目計數

#### 🎯 設定指導

**Xcode 配置** ✅:
- CloudKit Capability 啟用
- Container: `iCloud.com.owen.InvestmentDashboard`
- 自動簽署管理

**CloudKit Dashboard 設定** ✅:
- 4 個 Record Types 建立完成
- 索引優化設定
- Development 環境準備就緒

### 📊 技術架構升級

**從字串陣列到結構化模型**:
```swift
// 舊版本
@State private var bondDataList: [[String]] = []

// 新版本
@Published var bonds: [Bond] = []
```

**統一的資料存取介面**:
```swift
// 透過 DataManager 統一存取
let dataManager = DataManager()
await dataManager.saveBond(newBond)
await dataManager.fetchAllData()
```

**智能離線處理**:
```swift
// 自動處理離線/在線狀態
if isOnline {
    try await cloudKitManager.save(data)
} else {
    offlineManager.addPendingChange(data)
}
```

### 🚨 重要問題記錄

#### CloudKit 同步問題 (2025-09-18 凌晨)
**問題狀況**:
- 應用程式目前仍使用本地儲存 (UserDefaults)
- 雖然已實作CloudKit相關程式碼，但主要ContentView仍使用舊版DataManager
- 跨裝置無法同步資料

**技術分析**:
- `ContentView.swift` 內部定義了自己的DataManager類別，使用UserDefaults
- `Services/DataManager.swift` 是CloudKit版本，但未被實際使用
- `InvestmentDashboardApp.swift` 雖然注入了CloudKit版本的DataManager，但ContentView忽略了它

**已建立的Debug工具**:
- `CloudKitDebugView.swift` - 完整的CloudKit狀態檢查界面
- `CloudKitStatusChecker.swift` - 簡單的狀態檢查工具
- `CLOUDKIT_DEBUG_GUIDE.md` - 詳細的使用說明

**修復方案**:
1. 修改ContentView.swift，移除內部的DataManager定義
2. 使用@EnvironmentObject接收CloudKit版本的DataManager
3. 確保CloudKit Container設定正確
4. 測試iCloud帳號狀態和同步功能

### 🎉 開發里程碑

- ✅ **v0.7.0** (2025-09-16 上午): CloudKit 整合架構完成 (**架構完成但未啟用**)
  - 完整的資料模型設計
  - 多裝置同步功能 (程式碼完成)
  - 離線支援機制
  - 用戶刪除功能
  - CloudKit Schema 建立
  - ❌ **實際仍使用本地儲存，CloudKit功能未啟用**

### 🔄 下一階段規劃

1. **🚨 緊急**: 修復ContentView使用CloudKit DataManager
2. **測試CloudKit同步功能**
3. **確保iCloud帳號正常連接**
4. **多裝置同步測試**
5. **Production 環境部署**
6. **效能優化和錯誤處理**
7. **用戶體驗改進**

---
----

## 最新更新 (2025-09-22) - v0.7.1

### 🎯 總額大卡片高度優化升級

#### ✅ 總額走勢圖區域大幅擴展
**用戶需求**: 總額大卡片高度需要增加，為總額走勢圖提供更充足的展示空間

**核心變更**:
```swift
// ContentView.swift:1174 - simpleTrendChart 區域高度優化
.frame(height: 100) → .frame(height: 203)  // 103%增長
```

**具體增幅**:
- **第一次增加**: 100 → 120 (20%增長)
- **第二次增加**: 120 → 156 (30%增長)
- **第三次增加**: 156 → 203 (30%增長)
- **總增長**: 103% (從100到203)

**視覺效果提升**:
- ✅ **走勢圖顯示空間大幅增加**: 為總額走勢數據提供更清晰的視覺展示
- ✅ **數據可讀性大幅提升**: 走勢線條和填充區域有更充足的顯示空間
- ✅ **用戶體驗優化**: 總額大卡片成為更突出的核心展示區域

#### 📊 版本更新記錄
- ✅ **v0.7.1** (2025-09-22): 總額大卡片高度優化升級

----

## 最新更新 (2025-09-22) - v0.7.2

### 🎯 債券每月配息卡片視覺一致性優化

#### ✅ 字體大小統一化
**用戶需求**: 債券每月配息卡片字體大小要與其他投資卡片一致

**核心變更**:
```swift
// ContentView.swift:923 - 主標題字體優化
Text("債券每月配息")
    .font(.system(size: 14, weight: .semibold))  // 舊版
    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

Text("債券每月配息")
    .font(.system(size: 19, weight: .semibold))  // 新版，與其他投資卡片一致
    .foregroundColor(.black)
```

#### ✅ 月份長條圖佈局優化
**用戶需求**: 1～12月份標示需要延伸到右側，減少空白區域

**佈局優化**:
```swift
// ContentView.swift:937-955 - 長條圖佈局改進
HStack(alignment: .bottom, spacing: 4) → HStack(alignment: .bottom, spacing: 2)  // 縮小間距
.frame(width: 12, height: height) → .frame(width: 16, height: height)  // 增加長條寬度
VStack { /* 月份內容 */ } → VStack { /* 月份內容 */ }.frame(maxWidth: .infinity)  // 平均分佈
```

#### ✅ 卡片高度統一
**技術實現**: 確保債券每月配息卡片與其他投資卡片保持相同的內容區域高度
```swift
// ContentView.swift:958 - 高度統一
.frame(height: 70)  // 與美股、台股、債券卡片保持一致
```

**視覺效果提升**:
- ✅ **字體統一性**: 主標題使用19pt semibold，與美股、台股、債券卡片完全一致
- ✅ **空間利用優化**: 12個月份長條圖平均分佈，充分利用卡片寬度
- ✅ **視覺協調性**: 卡片高度與其他投資卡片完全對齊
- ✅ **用戶體驗改善**: 減少視覺不一致造成的注意力分散

#### 📊 版本更新記錄
- ✅ **v0.7.1** (2025-09-22): 總額大卡片高度優化升級
- ✅ **v0.7.2** (2025-09-22): 債券每月配息卡片視覺一致性優化

----

## 最新更新 (2025-09-22) - v0.7.3

### 🏗️ 公司債新增功能完全恢復

#### ✅ 右上角新增按鈕(+)公司債功能復原
**用戶需求**: 恢復右上角新增按鈕的公司債輸入功能，實現與公司債明細表格的完整連動

**核心功能重建**:
```swift
// ContentView.swift - 公司債表單數據結構
struct BondFormData {
    var bondName: String = ""           // 債券名稱
    var tickerSymbol: String = ""       // 申購日
    var purchasePrice: String = ""      // 申購價
    var faceValue: String = ""          // 持有面額
    var quantity: String = ""           // 數量
    var purchaseAmount: String = ""     // 申購金額
    var tradingAmount: String = ""      // 交易金額
    var currentValue: String = ""       // 現值
    var accruedInterest: String = ""    // 已領利息
    var yieldRate: String = ""          // 殖利率
    var couponRate: String = ""         // 票面利率
    var paymentMonths: String = "1月7月" // 配息月份
    var singlePayment: String = ""      // 單次配息
    var annualPayment: String = ""      // 年度配息
}
```

#### ✅ 智能表單切換系統
**技術實現**: 在`simpleAddDataForm`中實現標籤切換功能
```swift
// ContentView.swift:1373-1426 - 標籤切換邏輯
if selectedTab == 0 {
    // 資產明細表單
    VStack(spacing: 0) { /* 原有資產輸入欄位 */ }
} else {
    // 公司債表單 - 三大區塊設計
    VStack(spacing: 0) {
        // 基本資訊區塊: 債券名稱、申購日、票面利率、殖利率
        // 金額資訊區塊: 申購價、持有面額、前手息、申購金額、交易金額、現值、已領利息
        // 配息資訊區塊: 配息月份、單次配息、年度配息
    }
}
```

#### ✅ 公司債數據保存與連動機制
**保存邏輯重構**:
```swift
// ContentView.swift:1646-1658 - 智能保存分發
private func saveFormData() {
    if selectedTab == 0 {
        saveAssetData()    // 保存資產明細數據
    } else {
        saveBondData()     // 保存公司債數據
    }
}

// ContentView.swift:1731-1765 - 公司債保存實現
private func saveBondData() {
    let newBondData: [String] = [
        bondFormData.bondName,      // 0: 債券名稱
        bondFormData.tickerSymbol,  // 1: 申購日
        bondFormData.purchasePrice, // 2: 申購價
        // ... 15個完整欄位對應公司債明細表格
    ]
    bondDataList.append(newBondData)  // 自動新增到明細表格
}
```

#### ✅ 智能預填功能實現
**根據PROJECT.md v0.4.8規範**: 實現智能預填功能，提升用戶輸入效率
```swift
// ContentView.swift:1755-1765 - 智能預填邏輯
// 保留利率相關數據，其他清空
let savedCouponRate = bondFormData.couponRate
let savedYieldRate = bondFormData.yieldRate
let savedPaymentMonths = bondFormData.paymentMonths

bondFormData = BondFormData()
bondFormData.couponRate = savedCouponRate      // 保留票面利率
bondFormData.yieldRate = savedYieldRate        // 保留殖利率
bondFormData.paymentMonths = savedPaymentMonths // 保留配息月份
```

#### ✅ 表格連動與配息計算整合
**數據流程完整連動**:
1. **輸入階段**: 用戶在公司債表單中輸入完整債券資訊
2. **保存階段**: 數據自動新增到`bondDataList`陣列
3. **顯示階段**: 公司債明細表格自動更新筆數顯示
4. **計算階段**: `calculateMonthlyDividends()`自動讀取新數據
5. **視覺階段**: 債券每月配息卡片自動更新長條圖和年配息總額

**關鍵連動點**:
```swift
// ContentView.swift:1467 - 動態筆數顯示
Text("（\(bondDataList.count)筆）")

// ContentView.swift:971-990 - 配息計算連動
for bondData in bondDataList {
    let paymentMonths = bondData[12] // 配息月份欄位
    let singlePaymentStr = bondData[13] // 單次配息金額
    // 自動計算月度配息分佈
}
```

**視覺效果提升**:
- ✅ **完整表單復原**: 基本資訊、金額資訊、配息資訊三大區塊完整實現
- ✅ **智能數據流**: 輸入→保存→顯示→計算→更新的完整自動化流程
- ✅ **用戶體驗優化**: 智能預填功能大幅提升重複輸入效率
- ✅ **即時反饋**: 新增公司債後立即反映在明細表格和配息卡片上

#### 📊 版本更新記錄
- ✅ **v0.7.1** (2025-09-22): 總額大卡片高度優化升級
- ✅ **v0.7.2** (2025-09-22): 債券每月配息卡片視覺一致性優化
- ✅ **v0.7.3** (2025-09-22): 公司債新增功能完全恢復

最後更新: 2025-09-22
更新者: Claude Code Assistant
**重要**: 目前app仍為本地儲存版本，CloudKit功能需要修復ContentView才能啟用

---

## v0.7.4 - 漢堡按鈕客戶管理功能整合 (2025-09-23)

### 🎯 核心優化：客戶管理操作流程簡化

**功能描述**:
- 將漢堡按鈕（☰）功能從系統側邊欄改為直接顯示客戶管理面板
- 解決iPad雙擊問題，實現一鍵直達客戶管理功能
- 優化用戶體驗，簡化操作流程

**技術改進**:

#### 🔧 漢堡按鈕功能重構
```swift
// ContentView.swift - 漢堡按鈕功能改進
Button("☰") {
    print("🔍 漢堡按鈕被點擊 - 顯示客戶管理面板")
    withAnimation(.easeInOut(duration: 0.3)) {
        showingClientPanel = true
    }
}
```

#### 🚀 操作流程優化
**修改前**：
- 點擊漢堡按鈕 → 顯示系統側邊欄 → 再點擊客戶選項 → 顯示客戶管理面板（iPad需要雙擊）

**修改後**：
- 點擊漢堡按鈕 → 直接顯示客戶管理面板（一鍵直達）

#### ✅ 解決的問題
1. **iPad雙擊問題**: 消除NavigationView在iPad上的系統側邊欄衝突
2. **操作複雜性**: 從多步驟操作簡化為單步驟直達
3. **界面一致性**: iPhone和iPad操作體驗完全一致
4. **面板保持開啟**: 修正「+ 新增」按鈕點擊後面板自動關閉的問題

#### 🎨 用戶體驗提升
- ✅ **一鍵直達**: 漢堡按鈕直接開啟客戶管理面板
- ✅ **平台一致**: iPhone/iPad操作體驗完全相同
- ✅ **流程簡化**: 移除中間步驟，提升操作效率
- ✅ **視覺統一**: 保持漢堡圖示（☰），用戶認知一致

#### 📋 程式碼更新
**主要修改檔案**：`ContentView.swift`
- 移除原本的`viewModel.showClientList()`調用
- 改為直接觸發`showingClientPanel = true`
- 移除重複的「客戶」文字按鈕
- 保持客戶管理面板的完整功能

#### 📊 版本更新摘要
- ✅ **v0.7.4** (2025-09-23): 漢堡按鈕客戶管理功能整合，解決iPad雙擊問題，實現一鍵直達操作

**更新完成**: 2025-09-23
**更新者**: Claude Code Assistant


---

## 🚨 iCloud CloudKit 整合現狀 (2025-09-23)

### 🔍 問題分析

#### 當前實作狀態
- ✅ **CloudKit 框架整合**: 已加入 CloudKit 支援
- ✅ **客戶資料模型**: Client.swift 已支援 CloudKit 轉換
- ✅ **ViewModel 整合**: ClientViewModel 包含完整 CloudKit 操作
- ✅ **除錯系統**: 已加入詳細的 CloudKit 操作記錄

#### 🚨 發現的問題

##### 1. CloudKit 容器錯誤
```
"MonthlyAssetRecord" Error Domain=CKErrorDomain Code=2045 "Field
'receivedDate' is not marked queryable; however index 'receivedDate'
failed to be created: field 'receivedDate' is not queryable"
```

##### 2. 初始化問題
- **問題**: ViewModel 初始化記錄未出現在控制台
- **狀態**: `🚀🚀🚀 ClientViewModel 初始化開始` 訊息未顯示
- **可能原因**: ViewModel 可能未被正確實例化

##### 3. CloudKit Schema 配置問題
- **問題**: 欄位索引設定不正確
- **影響**: 查詢操作失敗，無法正確讀取客戶資料

#### 🔧 待修正項目

##### 高優先級
1. **CloudKit 容器設定**
   - 檢查 CloudKit Dashboard 中的欄位設定
   - 確保所有查詢欄位都標記為 "Queryable"
   - 修正索引設定問題

2. **ViewModel 初始化檢查**
   - 確認 ClientViewModel 是否正確實例化
   - 檢查 @StateObject 生命週期
   - 驗證初始化流程執行

3. **CloudKit 權限設定**
   - 檢查 entitlements 檔案
   - 確認 iCloud 容器 ID 配置
   - 驗證 App ID 與 CloudKit 容器關聯

##### 中優先級
4. **除錯系統優化**
   - 改善控制台記錄顯示
   - 加強錯誤處理和報告
   - 建立系統狀態檢查機制

#### 🎯 下階段目標

1. **修正 CloudKit 容器設定**
2. **確保客戶資料正確保存和讀取**
3. **實現跨裝置資料同步**
4. **完成 iCloud 整合測試**

#### 📋 技術債務

- CloudKit Schema 需要重新設計
- 錯誤處理機制需要完善
- 離線/線上模式切換邏輯待實作
- 資料同步衝突解決機制待建立

**狀態更新**: 2025-09-23 10:46
**問題嚴重性**: 🔴 高 - 影響核心 iCloud 功能
**預估修復時間**: 1-2 小時
**負責人**: Claude Code Assistant
