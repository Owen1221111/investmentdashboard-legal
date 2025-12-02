# 🧪 第1步測試指南 - 基礎客戶選擇UI

## 🎯 這一步完成了什麼

**功能**：
- ✅ 基本的三條槓按鈕 (左上角)
- ✅ 客戶名稱顯示 (中間)
- ✅ 新增按鈕 (右上角，暫未功能)
- ✅ 點擊三條槓顯示客戶列表
- ✅ 選擇客戶後更新顯示

**檔案結構**：
```
InvestmentDashboard-iOS/Views/
├── InvestmentDashboardApp.swift     # App 入口
├── ContentView.swift                # 主視圖
└── ClientSelection/
    └── BasicClientPickerView.swift  # 基礎客戶選擇器
```

---

## 🔧 在Xcode中測試的步驟

### 1. 創建新的Xcode專案
```
1. 打開 Xcode
2. File → New → Project
3. 選擇 iOS → App
4. Product Name: InvestmentDashboard
5. Interface: SwiftUI
6. Language: Swift
7. 取消勾選 Core Data 和 CloudKit (我們之後手動加入)
```

### 2. 替換預設檔案
```
1. 刪除預設的 ContentView.swift 和 InvestmentDashboardApp.swift
2. 將我們的檔案複製到專案中：
   - InvestmentDashboardApp.swift
   - ContentView.swift
   - ClientSelection/BasicClientPickerView.swift
```

### 3. 預期的測試結果

**✅ 正常情況**：
- App啟動顯示頂部導航欄
- 中間顯示 "張先生" (預設客戶)
- 左上角有三條線圖標
- 右上角有加號圖標

**✅ 互動測試**：
- 點擊三條線 → 彈出客戶列表
- 客戶列表顯示4個範例客戶
- 點擊任一客戶 → 列表關閉，主畫面更新客戶名稱
- 選中的客戶有藍色勾勾

**✅ 視覺檢查**：
- 界面乾淨簡潔
- 按鈕可以正常點擊
- 文字清晰可讀

---

## 🚨 可能遇到的問題

### 問題1：編譯錯誤
```
錯誤: Cannot find 'BasicClientPickerView' in scope
解決: 確認 BasicClientPickerView.swift 檔案已正確加入專案
```

### 問題2：預覽不顯示
```
原因: Xcode Canvas 問題
解決: 
1. Product → Clean Build Folder
2. 重新啟動 Xcode
3. 或者直接在模擬器中測試
```

### 問題3：按鈕沒反應
```
檢查: 
- 點擊三條線按鈕是否彈出列表
- 如果沒有，查看 showingClientList 狀態
```

---

## 📱 測試檢查清單

### 基本功能測試
- [ ] App可以正常啟動
- [ ] 頂部導航欄顯示正確
- [ ] 三條線按鈕可以點擊
- [ ] 客戶列表可以顯示
- [ ] 可以選擇不同客戶
- [ ] 主畫面客戶名稱會更新

### UI測試
- [ ] 界面佈局正確
- [ ] 字體大小合適
- [ ] 顏色搭配正常
- [ ] 按鈕大小合適，容易點擊

### 響應式測試 (不同設備)
- [ ] iPhone SE (小螢幕) 正常顯示
- [ ] iPhone 14 Pro 正常顯示  
- [ ] iPad 正常顯示

---

## 🔍 代碼解析

### BasicClientPickerView.swift 關鍵代碼
```swift
// 狀態管理
@State private var selectedClientName = "張先生"
@State private var showingClientList = false

// 假數據 (第2步會替換成真實數據)
let sampleClients = ["張先生", "王女士", "李先生", "陳女士"]

// 三條線按鈕動作
Button(action: {
    showingClientList = true
}) {
    Image(systemName: "line.horizontal.3")
}

// 客戶列表彈窗
.sheet(isPresented: $showingClientList) {
    ClientListSheet(...)
}
```

---

## 📋 下一步準備

**第1步測試成功後，準備第2步**：
1. 確認基本UI正常運作
2. 記錄任何需要調整的地方
3. 準備整合真實的ViewModel和數據

**測試完成回報格式**：
```
✅ 基本功能: 正常
✅ UI顯示: 正常  
✅ 互動功能: 正常
⚠️ 發現問題: [描述問題]
```

---

**創建日期**: 2025-09-08  
**測試版本**: 第1步 - 基礎UI  
**下一步**: 整合ViewModel和真實數據