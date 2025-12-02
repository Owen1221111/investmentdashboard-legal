# 🎯 專案上下文快速摘要 (給新Claude對話使用)

## 當前進度
我們正在開發**投資儀表板iOS App**，基於完整的Web版本轉換。

### ✅ 已完成
1. **數據模型** - Client.swift, MonthlyAssetRecord.swift, CalculatedMetrics.swift
2. **服務層** - CloudKitService.swift, CalculationService.swift  
3. **基礎UI** - BasicClientPickerView.swift (第1步)
4. **完整文檔** - 01-DataModels-Guide.md, 02-Services-Guide.md

### 🎯 當前任務
**第2步**: 整合ViewModel連接真實數據到UI

## 快速指令給新Claude
```
繼續開發投資儀表板iOS App。已完成數據模型和服務層，現在需要第2步：將ClientViewModel整合到BasicClientPickerView，替換假數據為真實CloudKit數據。

參考文檔: InvestmentDashboard-iOS/Documentation/ 資料夾內的指南
基礎架構: InvestmentDashboard-iOS/ 資料夾內已有Models/, Services/, Views/
```

## 專案特色
- 6列響應式佈局儀表板
- 滑動資產配置卡片
- CloudKit + iCloud 同步
- 多客戶投資組合管理

## 技術棧
SwiftUI + CloudKit + MVVM + Swift Charts