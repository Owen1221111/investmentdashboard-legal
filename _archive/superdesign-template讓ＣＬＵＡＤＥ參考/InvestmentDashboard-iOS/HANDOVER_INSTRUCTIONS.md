# 🔄 專案交接指令 - 投資儀表板iOS App

## 📋 當前狀態
已完成數據層、服務層和基礎UI，正在進行**第2步：ViewModel整合**

## 🎯 給新Claude的完整指令

```
你好！請繼續開發投資儀表板iOS App。

【專案背景】
- 基於完整Web版本轉換的iOS原生App
- 多客戶投資組合管理系統
- 使用SwiftUI + CloudKit + MVVM架構

【已完成部分】
✅ Models層: Client.swift, MonthlyAssetRecord.swift, CalculatedMetrics.swift
✅ Services層: CloudKitService.swift, CalculationService.swift  
✅ 基礎UI: BasicClientPickerView.swift (使用假數據)
✅ 完整文檔: 01-DataModels-Guide.md, 02-Services-Guide.md

【當前任務 - 第2步】
需要將ClientViewModel.swift整合到BasicClientPickerView.swift，替換假數據為真實CloudKit數據。

【專案檔案位置】
InvestmentDashboard-iOS/ 資料夾包含所有代碼和文檔

【下一步具體要做】
1. 修改BasicClientPickerView.swift使用ClientViewModel
2. 測試真實數據載入功能  
3. 處理載入狀態和錯誤處理
4. 完成後繼續第3步：主要儀表板界面

請一步一步進行，確保每步都可以在Xcode中測試。
```

## ✅ 已完成的檔案清單

### Models/ (100%完成)
- Client.swift
- MonthlyAssetRecord.swift  
- CalculatedMetrics.swift

### Services/ (100%完成)
- CloudKitService.swift
- CalculationService.swift

### Views/ (50%完成)
- InvestmentDashboardApp.swift ✅
- ContentView.swift ✅  
- ClientSelection/BasicClientPickerView.swift ✅ (使用假數據)

### ViewModels/ (50%完成)
- ClientViewModel.swift ✅ (已寫好但未整合)

### Documentation/ (100%完成)
- README.md
- 01-DataModels-Guide.md
- 02-Services-Guide.md
- 03-Step1-BasicUI-TestGuide.md

## 🚧 待完成的任務

### 【優先級1 - 第2步】
1. **整合ClientViewModel到UI**
   - 修改BasicClientPickerView.swift
   - 替換假數據為真實CloudKit數據
   - 加入載入狀態和錯誤處理

### 【優先級2 - 第3步】  
2. **主要儀表板界面**
   - 6列響應式佈局
   - 資產統計卡片
   - 滑動配置圓餅圖

### 【優先級3 - 第4步】
3. **資料輸入表單**  
   - AddDataView.swift
   - 16個欄位的月度資產明細輸入

### 【優先級4 - 第5步】
4. **圖表整合**
   - Swift Charts
   - 趨勢線圖
   - 配息柱狀圖

## 🎯 立即下達的指令

將以下文字直接貼給新Claude:

---

**繼續開發投資儀表板iOS App的第2步：ViewModel整合。**

**當前狀況**: 基礎UI使用假數據正常運作，現在需要整合真實的ClientViewModel和CloudKit數據。

**具體任務**: 
1. 修改 BasicClientPickerView.swift，整合 ClientViewModel.swift
2. 替換sampleClients假數據為真實CloudKit載入
3. 加入載入狀態指示和錯誤處理  
4. 確保可以在Xcode中正常測試

**專案檔案**: 查看InvestmentDashboard-iOS/資料夾，參考Documentation/內的指南文檔。

**完成後**: 繼續第3步主要儀表板界面開發。

請一步一步進行並提供測試指南。

---

## 📄 需要的檔案已準備好

所有Models、Services、基礎Views和文檔都已完成，新Claude可以立即開始第2步整合工作。