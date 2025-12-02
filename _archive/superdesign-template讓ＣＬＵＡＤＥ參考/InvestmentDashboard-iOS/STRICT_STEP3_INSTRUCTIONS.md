# 🚨 第3步嚴格執行指令 - 主要儀表板界面

## ⚠️ 重要提醒
**請嚴格按照以下步驟執行，不要自創新的組件或架構！**

## 🎯 第3步具體任務

### ✅ 保持不變的部分
1. **繼續使用現有的 BasicClientPickerView.swift**
2. **繼續使用現有的 ClientViewModel.swift** 
3. **保持現有的頂部導航欄設計**

### 🔄 第3步要修改的內容
**只需要替換 BasicClientPickerView.swift 中的「主要內容區域」**

#### 當前的主要內容區域：
```swift
// 主要內容區域 (暫時顯示選中的客戶)
VStack {
    Text("目前選擇的客戶:")
        .font(.title2)
        .padding()
    Text(selectedClientName)
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.blue)
        .padding()
    Text("(這裡之後會顯示儀表板內容)")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

#### 要替換成：
6列響應式儀表板佈局，包含：
1. 總資產統計卡片區域 (第1-2列)
2. 資產配置圓餅圖 (第3-4列) 
3. 統計小卡片 (第5-6列)
4. 趨勢圖表 (跨6列)

## 📋 詳細實現步驟

### Step 1: 修改 BasicClientPickerView.swift
**位置**: `Views/ClientSelection/BasicClientPickerView.swift`

**動作**: 找到「主要內容區域」的VStack，替換成：

```swift
// 主要儀表板區域 (6列響應式佈局)  
ScrollView {
    LazyVGrid(columns: createGridColumns(), spacing: 16) {
        // 在這裡加入儀表板卡片
    }
    .padding(.horizontal, 16)
}
```

### Step 2: 在同一個檔案中加入Grid輔助函數
**位置**: BasicClientPickerView.swift 檔案最上方

```swift
// Grid Layout Helper
private func createGridColumns() -> [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
}
```

### Step 3: 在同一個檔案中加入儀表板卡片組件
**位置**: BasicClientPickerView.swift 檔案最下方

加入以下組件：
- DashboardCard (統計卡片)
- AssetAllocationCard (資產配置)
- TrendChartCard (趨勢圖表)

### Step 4: 測試確認
- 確保頂部導航欄不變
- 確保客戶選擇功能正常
- 新的6列佈局正確顯示

## 🚫 嚴格禁止的行為

1. **不要創建新的 ViewModel** (如 LocalClientViewModel)
2. **不要創建新的 View 檔案** (如 BasicClientPickerViewLocal) 
3. **不要修改 ContentView.swift**
4. **不要創建新的 Client 模型** (如 LocalClient)
5. **不要改變現有的檔案結構**

## ✅ 允許的行為

1. **修改 BasicClientPickerView.swift 的主要內容區域**
2. **在同一個檔案中加入新的 View 組件**
3. **使用假數據進行展示** (暫時跳過CloudKit)
4. **保持現有的架構和設計**

## 🎯 預期結果

修改完成後：
- 頂部三條線 → 客戶名稱 → 加號 (不變)
- 中間變成6列儀表板佈局
- 客戶選擇功能正常運作
- 所有現有功能保持不變

## 📝 執行檢查清單

- [ ] 只修改了 BasicClientPickerView.swift 
- [ ] 沒有創建新的檔案
- [ ] 頂部導航欄保持原樣
- [ ] 客戶選擇功能正常
- [ ] 6列佈局正確顯示
- [ ] 沒有破壞現有架構

## 🚨 如果不確定，請詢問！

**不要自行創造或修改架構，嚴格按照指令執行！**