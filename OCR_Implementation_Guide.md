# 保險保單照片辨識功能實作指南

## 📋 功能概述

已完成保險保單的照片辨識（OCR）匯入功能，使用 Apple Vision Framework 進行文字辨識，並智能解析保單資料。

## 🎯 核心功能

1. **照片來源選擇**
   - 📷 拍照：直接使用相機拍攝保單
   - 🖼️ 相簿選擇：從相簿中選擇已拍攝的保單照片

2. **智能文字辨識**
   - 使用 Apple Vision Framework 進行 OCR
   - 支援繁體中文和英文辨識
   - 高準確度辨識模式

3. **智能資料解析**
   - 自動識別 10 個保單欄位：
     * 保險種類（壽險、醫療險、意外險、投資型）
     * 保險公司（支援台灣主要 15 家保險公司）
     * 保單號碼
     * 保險名稱
     * 被保險人
     * 保單始期
     * 繳費月份
     * 保額
     * 年繳保費
     * 繳費年期

4. **資料完整度驗證**
   - 即時計算資料完整度百分比
   - 顯示缺少的欄位
   - 視覺化進度條指示

5. **編輯確認介面**
   - 照片預覽
   - 表單欄位編輯
   - 必填欄位標示
   - 儲存前驗證

## 📁 新增檔案

### 1. ImagePicker.swift
**位置**: `InvestmentDashboard/InvestmentDashboard/ImagePicker.swift`

**功能**: SwiftUI 與 UIKit 的 UIImagePickerController 橋接器

**關鍵特性**:
- 支援相機和相簿兩種來源
- UIViewControllerRepresentable 協議實作
- 圖片選擇後自動關閉

### 2. InsuranceOCRManager.swift
**位置**: `InvestmentDashboard/InvestmentDashboard/InsuranceOCRManager.swift`

**功能**: OCR 文字辨識和資料解析核心邏輯

**關鍵特性**:
- Vision Framework 文字辨識
- 支援繁體中文 + 英文雙語言
- 智能解析 10 個保單欄位
- 關鍵字匹配演算法
- 正則表達式數據提取
- 資料完整度驗證

**主要方法**:
```swift
// 提取圖片文字
func extractText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void)

// 解析保單資料
func parseInsuranceData(from text: String) -> InsurancePolicyData

// 驗證資料完整度
func validateData(_ data: InsurancePolicyData) -> (completeness: Double, missingFields: [String])
```

### 3. InsuranceOCREditView.swift
**位置**: `InvestmentDashboard/InvestmentDashboard/InsuranceOCREditView.swift`

**功能**: OCR 辨識結果的預覽和編輯介面

**關鍵特性**:
- 照片預覽區域
- 資料完整度指示器（進度條 + 百分比）
- 10 個表單欄位
- 必填欄位標示（紅色星號）
- 即時完整度更新
- 儲存前驗證

### 4. InsurancePolicyView.swift (更新)
**位置**: `InvestmentDashboard/InvestmentDashboard/InsurancePolicyView.swift`

**新增內容**:
- OCR 相關狀態變數
- 照片選擇器整合
- OCR 處理流程
- 載入指示器（辨識中）
- 編輯視圖展示

## 🔧 如何加入到 Xcode 專案

### 方法一：使用 Xcode GUI（推薦）

1. **開啟專案**
   ```
   在 Finder 中找到：
   InvestmentDashboard/InvestmentDashboard.xcodeproj
   雙擊開啟
   ```

2. **加入新檔案**
   - 在左側專案導航器中，右鍵點擊 `InvestmentDashboard` 資料夾
   - 選擇 "Add Files to InvestmentDashboard..."
   - 選擇以下三個檔案：
     * `ImagePicker.swift`
     * `InsuranceOCRManager.swift`
     * `InsuranceOCREditView.swift`
   - 確認勾選：
     * ✅ Copy items if needed
     * ✅ Create groups
     * ✅ Add to targets: InvestmentDashboard
   - 點擊 "Add"

3. **驗證檔案已加入**
   - 在專案導航器中應該能看到三個新檔案
   - 每個檔案都應該有 InvestmentDashboard 目標勾選

### 方法二：手動編輯 project.pbxproj（進階）

如果需要手動加入，請參考專案中其他 Swift 檔案的配置方式。

## 🚀 使用流程

### 用戶操作流程

1. **進入保險管理頁面**
   - 選擇客戶 → 點擊「保單」按鈕

2. **展開保險明細表格**
   - 點擊「保險明細」右側的 ⌄ 圖示

3. **點擊照片匯入按鈕**
   - 點擊工具列的 📷 相機圖示
   - 選擇「拍照」或「從相簿選擇」

4. **拍攝或選擇保單照片**
   - 使用相機拍攝保單文件
   - 或從相簿中選擇已拍攝的照片

5. **等待辨識處理**
   - 畫面顯示「正在辨識保單內容...」
   - 自動提取文字並解析資料

6. **確認和編輯資料**
   - 查看照片預覽
   - 查看資料完整度（百分比 + 缺少欄位提示）
   - 編輯或補充資料
   - 點擊「儲存」

7. **儲存成功**
   - 顯示儲存成功訊息
   - 自動關閉編輯視圖

### 技術流程

```
1. 用戶點擊相機按鈕
   ↓
2. 顯示照片來源選擇對話框（拍照 / 相簿）
   ↓
3. 開啟 ImagePicker（相機或相簿）
   ↓
4. 用戶選擇照片
   ↓
5. 觸發 processImageWithOCR()
   ↓
6. 顯示載入指示器「正在辨識保單內容...」
   ↓
7. InsuranceOCRManager.extractText() - Vision Framework OCR
   ↓
8. InsuranceOCRManager.parseInsuranceData() - 智能解析
   ↓
9. InsuranceOCRManager.validateData() - 驗證完整度
   ↓
10. 顯示 InsuranceOCREditView 編輯視圖
    ↓
11. 用戶確認/編輯資料
    ↓
12. 點擊儲存按鈕
    ↓
13. 驗證必填欄位
    ↓
14. 回調 onSave() → 儲存到 Core Data（待實作）
    ↓
15. 顯示成功訊息並關閉
```

## 🔍 智能解析邏輯

### 保險種類識別

使用關鍵字匹配：
- **壽險**: 壽險、人壽、終身壽險、定期壽險
- **醫療險**: 醫療、住院、手術、實支實付
- **意外險**: 意外、傷害、意外險
- **投資型**: 投資型、變額、萬能、投資

### 保險公司識別

支援台灣主要 15 家保險公司：
- 國泰人壽、富邦人壽、南山人壽、新光人壽、中國人壽
- 台灣人壽、全球人壽、遠雄人壽、三商美邦、保誠人壽
- 安聯人壽、元大人壽、宏泰人壽、中華郵政、第一金人壽

### 保單號碼識別

使用兩種方式：
1. 關鍵字後提取：「保單號碼」、「契約號碼」、「Policy No」
2. 正則表達式：`[A-Z]{1,3}[0-9]{6,12}`（1-3 個英文字母 + 6-12 個數字）

### 日期識別

正則表達式：`(\d{4})[/-年](\d{1,2})[/-月](\d{1,2})[日]?`
- 支援格式：2024/01/01、2024-01-01、2024年1月1日

### 金額識別

支援多種格式：
- `$1,000,000 元`
- `NT$1,000,000`
- `TWD 1,000,000`
- 自動去除逗號和符號，提取純數字

## ⚠️ 待整合項目

### Core Data 整合

目前 OCR 功能已完整實作，但還需要整合 Core Data 來永久儲存資料。

**需要完成**:
1. 建立 `InsurancePolicy` Entity（在 DataModel.xcdatamodeld）
2. 新增 10 個屬性對應保單欄位
3. 建立與 `Client` 的關係
4. 在 `InsurancePolicyView.swift` 中實作 FetchRequest
5. 在 `InsuranceOCREditView.swift` 的 `savePolicyData()` 中實作 Core Data 儲存

**當前標記位置**:
- `InsurancePolicyView.swift:105` - TODO: 整合 Core Data 後在此儲存資料
- `InsuranceOCREditView.swift:290` - TODO: 儲存到 Core Data

## 📊 資料結構

```swift
struct InsurancePolicyData {
    var policyType: String = ""        // 保險種類
    var insuranceCompany: String = ""  // 保險公司
    var policyNumber: String = ""      // 保單號碼
    var policyName: String = ""        // 保險名稱
    var insuredPerson: String = ""     // 被保險人
    var startDate: String = ""         // 保單始期
    var paymentMonth: String = ""      // 繳費月份
    var coverageAmount: String = ""    // 保額
    var annualPremium: String = ""     // 年繳保費
    var paymentPeriod: String = ""     // 繳費年期
}
```

## 🎨 UI/UX 特性

### 資料完整度指示器
- 綠色進度條：完整度 ≥ 70%
- 橙色進度條：完整度 < 70%
- 百分比數字顯示
- 缺少欄位列表

### 表單欄位設計
- 必填欄位標示（紅色星號 *）
- 欄位圖示（視覺化）
- 佔位符文字（提示格式）
- 即時完整度更新
- 必填欄位未填時顯示紅色邊框

### 載入體驗
- 全螢幕半透明遮罩
- 旋轉載入指示器
- 「正在辨識保單內容...」文字提示

## 🔐 隱私保護

使用 Apple Vision Framework 的優勢：
- ✅ 完全本地處理，不上傳到雲端
- ✅ 保護客戶隱私資料
- ✅ 不需要網路連接
- ✅ 免費使用，無 API 費用

## 📝 Console 日誌

辨識過程會輸出詳細日誌：

```
✅ OCR 文字辨識成功
辨識文字：
[完整的辨識文字內容]

📊 資料完整度：80%
⚠️  缺少欄位：繳費月份、繳費年期

✅ 保單資料準備儲存：
  - 保險種類：壽險
  - 保險公司：國泰人壽
  - 保單號碼：ABC1234567
  - 保險名稱：終身壽險
  - 被保險人：張三
  - 保單始期：2024/01/01
  - 繳費月份：
  - 保額：1000000
  - 年繳保費：50000
  - 繳費年期：
```

## 🧪 測試建議

1. **測試不同照片品質**
   - 高清照片
   - 模糊照片
   - 傾斜照片
   - 不同光線條件

2. **測試不同保險公司**
   - 台灣各大保險公司保單
   - 不同格式的保單文件

3. **測試資料完整度**
   - 完整資訊的保單
   - 資訊不完整的保單
   - 手寫保單

4. **測試編輯功能**
   - 修改辨識結果
   - 補充缺少欄位
   - 必填欄位驗證

## 🚀 未來改進方向

1. **AI 增強辨識**
   - 整合 Claude Vision API
   - 提供「AI 增強」選項
   - 處理更複雜的保單格式

2. **批次匯入**
   - 一次選擇多張保單照片
   - 批次處理和儲存

3. **OCR 歷史記錄**
   - 保存辨識歷史
   - 重新編輯已辨識的保單

4. **模板管理**
   - 為不同保險公司建立辨識模板
   - 提高準確度

5. **錯誤處理增強**
   - 更友善的錯誤訊息
   - 辨識失敗時的重試機制

## 📞 技術支援

如有問題，請檢查：
1. Xcode 編譯錯誤
2. Console 日誌輸出
3. Vision Framework 權限設定
4. 相機和相簿使用權限（Info.plist）

---

**實作時間**: 2025/10/14
**開發者**: Claude
**版本**: 1.0.0
