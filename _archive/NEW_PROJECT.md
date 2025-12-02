# InvestmentDashboard - 功能目錄文檔

## 專案概述

這是一個具有 iCloud 同步功能的 iOS 投資儀表板應用程式，使用 SwiftUI + Core Data + CloudKit 技術棧，支援客戶管理和投資數據展示。

## 🍔 漢堡按鈕客戶管理系統

### 功能位置
- **文件**: `ContentView.swift`
- **觸發**: 左上角 "☰" 按鈕
- **UI 組件**: `clientSelectionPanel` 私有視圖

### 核心功能

#### 1. 📱 **客戶選擇面板**
- **狀態變數**: `@State private var showingClientPanel: Bool`
- **動畫**: 0.3秒緩出動畫 `.easeInOut(duration: 0.3)`
- **佈局**: ZStack 覆蓋層，左側滑出，佔螢幕 75% 寬度
- **背景**: 半透明黑色遮罩，點擊關閉面板

#### 2. 📊 **客戶排序功能**
```swift
// 排序選項枚舉
enum SortOption: String, CaseIterable {
    case name = "名稱"
    case date = "創建日期"
    case email = "電子郵件"
}

// 狀態管理
@State private var currentSortOption: SortOption = .name
@State private var sortAscending = true
@State private var showingSortOptions = false

// 排序邏輯
private var sortedClients: [Client] { ... }
```

**UI 組件**:
- 排序按鈕：藍色背景，顯示當前排序方式和方向箭頭
- 下拉選單：點擊排序按鈕展開選項
- 動態排序：即時更新客戶列表順序

#### 3. 🗑️ **客戶刪除功能**
```swift
// 刪除函數
private func deleteClient(_ client: Client) {
    withAnimation {
        if selectedClient == client {
            selectedClient = nil  // 清除選中狀態
        }
        viewContext.delete(client)
        try viewContext.save()
        PersistenceController.shared.save()  // 同步到 CloudKit
    }
}
```

**UI 組件**:
- 刪除按鈕：紅色垃圾桶圖標
- 確認對話框：防止誤刪，顯示客戶名稱確認
- 安全機制：刪除當前選中客戶時自動清除選擇

#### 4. ✏️ **編輯客戶名稱功能**
```swift
// 編輯狀態
@State private var editingClient: Client?

// 更新函數
private func updateClientName(_ newName: String) {
    client.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    try viewContext.save()
    PersistenceController.shared.save()
}
```

**UI 組件**:
- 編輯按鈕：橙色鉛筆圖標
- 編輯模式：`EditingClientRow` 組件
- 內嵌編輯：文本框直接替換客戶名稱顯示
- 視覺提示：黃色背景 + 橙色邊框
- 操作按鈕：綠色勾號（保存）、紅色叉號（取消）

### 關鍵組件

#### 1. `ClientRowButton` 組件
```swift
struct ClientRowButton: View {
    let client: Client
    @Binding var selectedClient: Client?
    @Binding var editingClient: Client?
    let onClientSelected: () -> Void
    let onClientDelete: (Client) -> Void
    let onClientEdit: (Client) -> Void

    // UI 狀態
    @State private var showingDeleteAlert = false
    @Environment(\.managedObjectContext) private var viewContext
}
```

**功能**:
- 客戶信息顯示（名稱、郵件、創建時間）
- 選中狀態視覺反饋（藍色邊框和背景）
- 操作按鈕（編輯、刪除）
- 點擊選擇客戶並關閉面板

#### 2. `EditingClientRow` 組件
```swift
struct EditingClientRow: View {
    let client: Client
    @Binding var editingClient: Client?
    let onSave: (String) -> Void

    @State private var editingName: String
    @FocusState private var isTextFieldFocused: Bool
}
```

**功能**:
- 內嵌文本框編輯
- 自動聚焦到輸入框
- 保存/取消操作按鈕
- 編輯模式視覺區分

### 技術實現細節

#### 數據管理
- **Core Data**: `@FetchRequest` 自動獲取客戶數據
- **CloudKit**: 自動同步所有 CRUD 操作
- **狀態綁定**: 雙向數據綁定確保 UI 即時更新

#### 動畫效果
```swift
withAnimation(.easeInOut(duration: 0.3)) {
    showingClientPanel = true/false
}
```

#### 響應式設計
- 面板寬度：`min(UIScreen.main.bounds.width * 0.75, 320)`
- 支援 iPhone 和 iPad
- 安全區域適配：`.ignoresSafeArea()`

### 維護注意事項

#### 重要依賴
1. **PersistenceController**: CloudKit 同步控制器
2. **Client 實體**: Core Data 客戶模型
3. **環境變數**: `@Environment(\.managedObjectContext)`

#### 狀態管理
- `selectedClient`: 當前選中的客戶
- `showingClientPanel`: 面板顯示狀態
- `editingClient`: 正在編輯的客戶
- `showingSortOptions`: 排序選項顯示狀態

#### 性能優化
- 使用 `LazyVStack` 延遲加載客戶列表
- 計算屬性 `sortedClients` 動態排序
- 動畫使用 `withAnimation` 包裝確保流暢

## 🔄 與其他組件的整合

### 主視圖結構
```swift
ContentView {
    ZStack {
        VStack {
            customNavigationBar  // 包含漢堡按鈕
            ClientDetailView     // 主要內容區域
        }

        if showingClientPanel {
            clientSelectionPanel // 客戶管理面板
        }
    }
}
```

### 數據流向
1. **選擇客戶**: 漢堡面板 → `selectedClient` → `ClientDetailView`
2. **新增客戶**: 面板新增按鈕 → `AddClientView` → Core Data → CloudKit
3. **編輯客戶**: 面板編輯按鈕 → `EditingClientRow` → Core Data → CloudKit
4. **刪除客戶**: 面板刪除按鈕 → 確認對話框 → Core Data → CloudKit

## 🎨 視覺設計規範

### 投資儀表板設計
#### 小卡片群組佈局 (v1.1.0)
```
┌─────────────────────────────────────┐
│ 總資產 $10,163,000                  │
│ 總損益: +$125,000 +1.25%             │
│ [1D][7D][1M][3M][1Y]     ┌─────────┐│
│                          │總匯入(純文字)││
│                          │$0       ││
│ ┌─────走勢圖─────┐        │        ││
│ │       ╱╲      │        │現金     ││
│ │      ╱  ╲     │        │$3.2M    ││
│ │     ╱    ╲    │        └─────────┘│
│ └───────────────┘         總額報酬率  │
│                          +70.5% 綠色 │
└─────────────────────────────────────┘
```

#### 字體規範 (最新)
- **總匯入 (純文字)**:
  - 標題: 20pt, medium weight, 灰色
  - 數值: 24pt, bold weight, 黑色
- **現金卡片**:
  - 標題: 20pt, medium weight, 灰色
  - 數值: 24pt, bold weight, 黑色
  - 尺寸: 120x80pt
- **總額報酬率**:
  - 標題: 14pt, medium weight, 白色
  - 數值: 20pt, bold weight, 白色
  - 尺寸: 100x120pt

### 顏色系統
- **主色調**: 藍色（選中狀態、排序按鈕）
- **操作色彩**:
  - 編輯：橙色 `#FF8C00`
  - 刪除：紅色 `#FF0000`
  - 新增：綠色 `#32CD32`
  - 保存：綠色 `#32CD32`
  - 取消：紅色 `#FF0000`
- **投資儀表板**:
  - 獲利綠色: `#34C759`
  - 漸層: `rgba(0.27, 0.51, 0.38, 1.0)` → `rgba(0.20, 0.40, 0.30, 1.0)`

### 間距規範
- 面板內邊距：16pt
- 元素間距：8pt
- 按鈕尺寸：44x44pt（符合 Apple HIG）
- 卡片圓角：16-20pt
- 卡片間距：8pt

### 響應式設計
- **iPad 佈局**: 左側總資產，右側小卡片群組
- **iPhone 佈局**: 垂直堆疊，2x2 網格小卡片

## 📝 版本記錄

### v1.1.0 - 投資儀表板 UI 完成 (2025-09-26)
- ✅ 實現投資儀表板主要統計卡片設計
- ✅ 完成小卡片群組整合佈局
- ✅ 總匯入改為純文字顯示（無卡片背景）
- ✅ 移除總資產旁客戶名稱顯示
- ✅ 調整字體大小優化：
  - 總匯入：標題 20pt, 數值 24pt
  - 現金：標題 20pt, 數值 24pt
  - 現金卡片尺寸：120x80pt（擴大為左下四分之一區塊）
- ✅ 支援 iPad/iPhone 響應式佈局
- ✅ 完整走勢圖模擬展示

### v1.0.0 - 漢堡按鈕客戶管理系統 (2025-09-26)
- ✅ 實現左上角漢堡按鈕觸發客戶選擇面板
- ✅ 支援客戶拖拽排序功能
- ✅ 支援客戶刪除（含確認對話框）
- ✅ 支援客戶名稱編輯（內嵌編輯模式）
- ✅ 完整 CloudKit 同步功能
- ✅ 響應式設計適配 iPhone/iPad

## 🚀 未來擴展計劃

### 短期目標
- [ ] 批量刪除客戶功能
- [ ] 客戶搜尋/過濾功能
- [ ] 客戶匯出功能（CSV/Excel）

### 長期目標
- [ ] 客戶分組管理
- [ ] 客戶標籤系統
- [ ] 客戶統計分析
- [ ] 離線模式支援

## 📞 技術支援

### 常見問題
1. **客戶數據不同步**: 檢查 iCloud 登錄狀態和網絡連接
2. **面板動畫卡頓**: 確保動畫在主線程執行
3. **編輯模式無法退出**: 檢查 `editingClient` 狀態重置

### 調試建議
- 使用 `print()` 語句追蹤狀態變化
- 檢查 Core Data 和 CloudKit 錯誤日誌
- 使用 Xcode Instruments 分析性能瓶頸

---

**文檔最後更新**: 2025-09-26
**維護者**: Claude Code Assistant