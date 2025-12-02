# ⚙️ 服務層架構指南 (Services Guide)

## 🎯 功能概述
投資儀表板的核心業務邏輯層，包含CloudKit數據同步服務和計算服務。

## 📁 檔案路徑結構
```
InvestmentDashboard-iOS/Services/
├── CloudKitService.swift        # CloudKit 同步服務
└── CalculationService.swift     # 計算與分析服務
```

---

## 🔧 核心組件說明

### 1. CloudKitService.swift - 數據同步服務
**路徑**: `Services/CloudKitService.swift`

**主要功能**:
- iCloud 帳號狀態管理
- 客戶資料 CRUD 操作
- 月度資產記錄同步
- 即時訂閱更新

**核心方法**:
```swift
@MainActor
class CloudKitService: ObservableObject {
    // 帳號管理
    func checkAccountStatus()
    
    // 客戶操作
    func fetchClients() async throws -> [Client]
    func saveClient(_ client: Client) async throws
    func deleteClient(_ client: Client) async throws
    
    // 月度記錄操作
    func fetchMonthlyRecords(for clientID: String) async throws -> [MonthlyAssetRecord]
    func saveMonthlyRecord(_ record: MonthlyAssetRecord) async throws
    func saveMonthlyRecords(_ records: [MonthlyAssetRecord]) async throws
    
    // 同步管理
    func setupSubscriptions() async
    func forceSyncAllData() async
}
```

**使用範例**:
```swift
// 在 ViewModel 中使用
class DashboardViewModel: ObservableObject {
    @Published var cloudKitService = CloudKitService()
    
    func loadClientData() async {
        do {
            let clients = try await cloudKitService.fetchClients()
            // 更新 UI
        } catch {
            // 處理錯誤
        }
    }
}
```

---

### 2. CalculationService.swift - 計算分析服務
**路徑**: `Services/CalculationService.swift`

**主要功能**:
- 投資指標計算 (總資產、損益、報酬率)
- 資產配置分析
- 圖表數據生成
- 風險分析計算

**核心方法**:
```swift
class CalculationService {
    static let shared = CalculationService()
    
    // 主要計算
    func calculateMetrics(from records: [MonthlyAssetRecord]) -> CalculatedMetrics
    func calculateTotalAssets(from records: [MonthlyAssetRecord]) -> Double
    func calculateTotalPnL(from records: [MonthlyAssetRecord]) -> (amount: Double, percentage: Double)
    
    // 圖表數據
    func generatePieChartData(from record: MonthlyAssetRecord) -> [ChartDataPoint]
    func generateLineChartData(from records: [MonthlyAssetRecord]) -> [MonthlyTrendPoint]
    func generateDividendChartData(from records: [MonthlyAssetRecord]) -> [DividendDataPoint]
    
    // 進階分析
    func calculateReturnRate(from records: [MonthlyAssetRecord], period: TimePeriod) -> Double
    func calculateVolatility(from records: [MonthlyAssetRecord]) -> Double
    
    // 格式化工具
    func formatCurrency(_ amount: Double) -> String
    func formatPercentage(_ value: Double) -> String
}
```

**使用範例**:
```swift
// 計算客戶投資指標
let calculationService = CalculationService.shared
let metrics = calculationService.calculateMetrics(from: monthlyRecords)

// 顯示在 UI 上
Text(calculationService.formatCurrency(metrics.totalAssets))
Text(calculationService.formatPercentage(metrics.totalPnLPercentage))

// 生成圖表
let pieChartData = calculationService.generatePieChartData(from: latestRecord)
```

---

## 🔄 服務層互動流程

```mermaid
graph TD
    A[SwiftUI Views] --> B[ViewModels]
    B --> C[CloudKitService]
    B --> D[CalculationService]
    
    C --> E[CloudKit Database]
    D --> F[Business Logic]
    
    E --> G[iCloud Sync]
    F --> H[UI Updates]
    
    C -.-> I[@Published State]
    D -.-> J[Calculated Results]
    
    I --> A
    J --> A
```

---

## 🛠 維護指南

### CloudKitService 維護

**新增數據模型**:
1. 在相應的 CRUD 方法中添加新的 record type 處理
2. 更新 `setupSubscriptions()` 方法添加新訂閱
3. 處理相應的錯誤狀態

**錯誤處理優化**:
```swift
// 在 handleCloudKitError 方法中添加新錯誤類型
private func handleCloudKitError(_ error: Error) {
    if let ckError = error as? CKError {
        switch ckError.code {
        case .newErrorCase:
            errorMessage = "新錯誤類型處理"
        // ...
        }
    }
}
```

### CalculationService 維護

**新增計算邏輯**:
```swift
// 在 CalculationService 中添加新方法
func calculateNewMetric(from records: [MonthlyAssetRecord]) -> Double {
    // 實現新的計算邏輯
    return 0.0
}
```

**圖表數據擴展**:
```swift
// 新增圖表數據類型
struct NewChartDataPoint: Identifiable, Codable {
    let id = UUID()
    let name: String
    let value: Double
    // 其他屬性
}
```

---

## 🚀 整合建議

### ViewModel 整合模式
```swift
class ClientViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var isLoading = false
    
    private let cloudKitService = CloudKitService()
    private let calculationService = CalculationService.shared
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 載入數據
            clients = try await cloudKitService.fetchClients()
            
            // 計算指標
            for client in clients {
                let records = try await cloudKitService.fetchMonthlyRecords(for: client.id)
                let metrics = calculationService.calculateMetrics(from: records)
                // 更新 UI 狀態
            }
        } catch {
            // 錯誤處理
        }
    }
}
```

### 錯誤處理最佳實踐
```swift
// 統一錯誤處理
enum AppError: LocalizedError {
    case networkError
    case dataCorruption
    case calculationError
    
    var errorDescription: String? {
        switch self {
        case .networkError: return "網路連線問題"
        case .dataCorruption: return "數據損壞"
        case .calculationError: return "計算錯誤"
        }
    }
}
```

---

## ⚡ 效能優化

### CloudKit 批次處理
```swift
// 大量數據時使用批次處理
func saveMonthlyRecordsBatch(_ records: [MonthlyAssetRecord]) async throws {
    let batchSize = 100
    for batch in records.chunked(into: batchSize) {
        try await saveMonthlyRecords(Array(batch))
    }
}
```

### 計算結果快取
```swift
// 在 CalculationService 中加入快取
private var metricsCache: [String: CalculatedMetrics] = [:]

func calculateMetrics(from records: [MonthlyAssetRecord]) -> CalculatedMetrics {
    let cacheKey = records.map(\.id).joined()
    
    if let cached = metricsCache[cacheKey] {
        return cached
    }
    
    let metrics = CalculatedMetrics(from: records)
    metricsCache[cacheKey] = metrics
    return metrics
}
```

---

## ✅ 測試驗證

### CloudKit 同步測試
```swift
func testCloudKitSync() async {
    let service = CloudKitService()
    let testClient = Client(name: "測試客戶")
    
    // 儲存測試
    try await service.saveClient(testClient)
    
    // 讀取測試
    let clients = try await service.fetchClients()
    assert(clients.contains { $0.name == "測試客戶" })
}
```

### 計算邏輯測試
```swift
func testCalculations() {
    let service = CalculationService.shared
    let sampleRecord = MonthlyAssetRecord.sampleRecord(for: "test-client")
    
    let metrics = service.calculateMetrics(from: [sampleRecord])
    assert(metrics.totalAssets > 0)
    assert(metrics.allocationPercentages.usStockPercentage > 0)
}
```

---

## 📱 下一步整合

1. **ViewModels** - 將在 ViewModels 中使用這些服務
2. **SwiftUI Views** - Views 將透過 ViewModels 操作服務
3. **狀態管理** - 使用 @Published 和 @ObservedObject 管理狀態

---

**更新日期**: 2025-09-08  
**版本**: 1.0  
**負責模組**: 服務層 (Service Layer)