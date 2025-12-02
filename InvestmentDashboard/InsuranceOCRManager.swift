//
//  InsuranceOCRManager.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/14.
//

import Foundation
import Vision
import UIKit

/// 保險單資料結構
struct InsurancePolicyData: Codable {
    var policyType: String = ""        // 保險種類
    var insuranceCompany: String = ""  // 保險公司
    var policyNumber: String = ""      // 保單號碼
    var policyName: String = ""        // 保險名稱
    var policyHolder: String = ""      // 要保人
    var insuredPerson: String = ""     // 被保險人
    var startDate: String = ""         // 保單始期
    var paymentMonth: String = ""      // 繳費月份
    var coverageAmount: String = ""    // 保額
    var annualPremium: String = ""     // 年繳保費
    var paymentPeriod: String = ""     // 繳費年期
    var beneficiary: String = ""       // 受益人
    var interestRate: String = ""      // 利率
    var currency: String = "TWD"       // 幣別
    var exchangeRate: String = "32"    // 匯率
    var twdAmount: String = ""         // 折合台幣
}

/// 表格方向
enum TableOrientation {
    case horizontal  // 橫向：表頭在上，資料在下（每列一個保單）
    case vertical    // 直向：表頭在左，資料在右（每欄一個保單）
    case unknown     // 無法判斷
}

class InsuranceOCRManager {

    /// 從圖片提取文字（支援自動方向檢測和優化）
    /// - Parameter image: 要辨識的圖片
    /// - Returns: 提取的完整文字內容
    func extractText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(NSError(domain: "InsuranceOCRManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "無法轉換圖片格式"])))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            // 步驟 1: 先嘗試多個方向辨識，找出最佳方向
            let orientations: [CGImagePropertyOrientation] = [.up, .right, .down, .left]
            var bestResult: (text: String, confidence: Double, orientation: CGImagePropertyOrientation)?

            for orientation in orientations {
                let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
                let request = VNRecognizeTextRequest()

                // 設定辨識語言（支援繁體中文和英文）
                request.recognitionLanguages = ["zh-Hant", "en-US"]
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                do {
                    try requestHandler.perform([request])

                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        continue
                    }

                    // 計算辨識信心度和文字內容
                    let recognizedItems = observations.compactMap { observation -> (text: String, confidence: Double)? in
                        guard let candidate = observation.topCandidates(1).first else { return nil }
                        return (candidate.string, Double(candidate.confidence))
                    }

                    let recognizedText = recognizedItems.map { $0.text }.joined(separator: "\n")
                    let avgConfidence = recognizedItems.isEmpty ? 0.0 : recognizedItems.map { $0.confidence }.reduce(0, +) / Double(recognizedItems.count)

                    // 檢查是否包含保險公司關鍵字，給予額外權重
                    let containsInsuranceCompany = self.detectInsuranceCompany(in: recognizedText)
                    let adjustedConfidence = containsInsuranceCompany ? avgConfidence * 1.5 : avgConfidence

                    print("📐 方向 \(self.orientationName(orientation)) - 信心度: \(String(format: "%.2f", avgConfidence * 100))% - 包含保險公司: \(containsInsuranceCompany)")

                    if bestResult == nil || adjustedConfidence > bestResult!.confidence {
                        bestResult = (recognizedText, adjustedConfidence, orientation)
                    }

                } catch {
                    print("⚠️  方向 \(self.orientationName(orientation)) 辨識失敗：\(error.localizedDescription)")
                    continue
                }
            }

            // 步驟 2: 使用最佳方向進行最終辨識
            guard let bestOrientation = bestResult?.orientation else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "InsuranceOCRManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "無法辨識文字"])))
                }
                return
            }

            print("✅ 選擇最佳方向：\(self.orientationName(bestOrientation)) - 信心度: \(String(format: "%.2f", (bestResult?.confidence ?? 0) * 100))%")

            // 使用最佳方向進行完整辨識
            let finalRequestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: bestOrientation, options: [:])
            let finalRequest = VNRecognizeTextRequest { request, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "InsuranceOCRManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "無法辨識文字"])))
                    }
                    return
                }

                // 提取所有候選文字（取前3個候選，提高準確度）
                let recognizedText = observations.compactMap { observation -> String? in
                    // 取得前3個候選文字，選擇最合適的
                    let candidates = observation.topCandidates(3)

                    // 優先選擇包含保險相關關鍵字的候選
                    for candidate in candidates {
                        if self.containsInsuranceKeywords(candidate.string) {
                            return candidate.string
                        }
                    }

                    // 否則選擇信心度最高的
                    return candidates.first?.string
                }.joined(separator: "\n")

                DispatchQueue.main.async {
                    completion(.success(recognizedText))
                }
            }

            // 設定辨識語言（支援繁體中文和英文）
            finalRequest.recognitionLanguages = ["zh-Hant", "en-US"]
            finalRequest.recognitionLevel = .accurate
            finalRequest.usesLanguageCorrection = true
            // 啟用自動語言檢測
            finalRequest.automaticallyDetectsLanguage = true

            do {
                try finalRequestHandler.perform([finalRequest])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// 檢測文字中是否包含保險公司名稱
    private func detectInsuranceCompany(in text: String) -> Bool {
        let insuranceCompanies = [
            "國泰人壽", "富邦人壽", "南山人壽", "新光人壽", "中國人壽",
            "台灣人壽", "全球人壽", "遠雄人壽", "三商美邦", "保誠人壽",
            "安聯人壽", "元大人壽", "宏泰人壽", "中華郵政", "第一金人壽",
            "國泰", "富邦", "南山", "新光", "遠雄", "全球"
        ]

        for company in insuranceCompanies {
            if text.contains(company) {
                return true
            }
        }
        return false
    }

    /// 檢測文字是否包含保險相關關鍵字
    private func containsInsuranceKeywords(_ text: String) -> Bool {
        let keywords = [
            "保險", "壽險", "醫療", "意外", "人壽", "保單", "保費", "保額",
            "被保險人", "契約", "繳費", "年繳", "保險公司"
        ]

        for keyword in keywords {
            if text.contains(keyword) {
                return true
            }
        }
        return false
    }

    /// 取得方向名稱（用於 debug）
    private func orientationName(_ orientation: CGImagePropertyOrientation) -> String {
        switch orientation {
        case .up: return "正向"
        case .right: return "右轉90度"
        case .down: return "倒轉180度"
        case .left: return "左轉90度"
        default: return "未知"
        }
    }

    /// 智能解析保險單文字並提取結構化資料（以保險公司為定位點）
    /// - Parameter text: OCR辨識的文字內容
    /// - Returns: 結構化的保險單資料
    func parseInsuranceData(from text: String) -> InsurancePolicyData {
        var data = InsurancePolicyData()
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }

        print("\n📄 開始解析保單資料...")
        print("辨識到的文字行數：\(lines.count)")

        // 保險公司清單（優先順序：完整名稱 > 簡稱）
        let insuranceCompanies = [
            "國泰人壽", "富邦人壽", "南山人壽", "新光人壽", "中國人壽",
            "台灣人壽", "全球人壽", "遠雄人壽", "三商美邦", "保誠人壽",
            "安聯人壽", "元大人壽", "宏泰人壽", "中華郵政", "第一金人壽"
        ]

        // 步驟 1: 優先識別保險公司（作為關鍵定位點）
        var companyLineIndex: Int? = nil
        for (index, line) in lines.enumerated() {
            for company in insuranceCompanies {
                if line.contains(company) {
                    data.insuranceCompany = company
                    companyLineIndex = index
                    print("✅ 找到保險公司：\(company) (第 \(index + 1) 行)")
                    break
                }
            }
            if data.insuranceCompany.isEmpty {
                // 檢查簡稱
                let shortNames = ["國泰", "富邦", "南山", "新光", "遠雄", "全球"]
                for shortName in shortNames {
                    if line.contains(shortName) && (line.contains("人壽") || line.contains("保險")) {
                        data.insuranceCompany = shortName + "人壽"
                        companyLineIndex = index
                        print("✅ 找到保險公司（簡稱）：\(data.insuranceCompany) (第 \(index + 1) 行)")
                        break
                    }
                }
            }
            if !data.insuranceCompany.isEmpty {
                break
            }
        }

        // 步驟 2: 根據保險公司位置，從上到下依序解析其他欄位
        let startIndex = companyLineIndex ?? 0

        // 保險種類關鍵字
        let lifeInsuranceKeywords = ["壽險", "人壽", "終身壽險", "定期壽險", "終身險"]
        let medicalKeywords = ["醫療", "住院", "手術", "實支實付", "醫療險"]
        let accidentKeywords = ["意外", "傷害", "意外險"]
        let investmentKeywords = ["投資型", "變額", "萬能", "投資"]

        for (offset, line) in lines.enumerated() where offset >= startIndex {
            let cleanLine = line

            // 識別保險種類
            if data.policyType.isEmpty {
                if lifeInsuranceKeywords.contains(where: { cleanLine.contains($0) }) {
                    data.policyType = "壽險"
                    print("✅ 找到保險種類：壽險")
                } else if medicalKeywords.contains(where: { cleanLine.contains($0) }) {
                    data.policyType = "醫療險"
                    print("✅ 找到保險種類：醫療險")
                } else if accidentKeywords.contains(where: { cleanLine.contains($0) }) {
                    data.policyType = "意外險"
                    print("✅ 找到保險種類：意外險")
                } else if investmentKeywords.contains(where: { cleanLine.contains($0) }) {
                    data.policyType = "投資型"
                    print("✅ 找到保險種類：投資型")
                }
            }

            // 識別保單號碼（通常包含英文+數字組合）
            if data.policyNumber.isEmpty {
                // 方法1: 尋找標籤後的號碼
                if cleanLine.contains("保單號碼") || cleanLine.contains("契約號碼") || cleanLine.contains("Policy No") || cleanLine.contains("保險單號碼") {
                    // 支援多種分隔符
                    let separators = CharacterSet(charactersIn: ":：\t ")
                    let components = cleanLine.components(separatedBy: separators).filter { !$0.isEmpty }
                    if components.count > 1 {
                        // 找到標籤後的第一個非標籤內容
                        for component in components {
                            if !component.contains("號碼") && !component.contains("保單") && !component.contains("契約") {
                                data.policyNumber = component
                                print("✅ 找到保單號碼（標籤）：\(component)")
                                break
                            }
                        }
                    }
                }
                // 方法2: 使用正則表達式匹配
                else if let match = cleanLine.range(of: #"[A-Z]{1,4}[0-9]{6,12}"#, options: .regularExpression) {
                    data.policyNumber = String(cleanLine[match])
                    print("✅ 找到保單號碼（正則）：\(data.policyNumber)")
                }
                // 方法3: 匹配純數字保單號碼（10位以上）
                else if let match = cleanLine.range(of: #"\d{10,}"#, options: .regularExpression) {
                    data.policyNumber = String(cleanLine[match])
                    print("✅ 找到保單號碼（數字）：\(data.policyNumber)")
                }
            }

            // 識別保單名稱（包含「保險」或「險」字）
            if data.policyName.isEmpty && (cleanLine.contains("保險") || cleanLine.contains("險")) {
                // 排除包含「公司」、「被保險人」的行
                if !cleanLine.contains("公司") && !cleanLine.contains("被保險人") &&
                   !cleanLine.contains("保險金額") && !cleanLine.contains("保額") &&
                   cleanLine.count > 3 && cleanLine.count < 50 {
                    data.policyName = cleanLine
                    print("✅ 找到保單名稱：\(cleanLine)")
                }
            }

            // 識別被保險人
            if data.insuredPerson.isEmpty {
                if cleanLine.contains("被保險人") || cleanLine.contains("被保人") {
                    let separators = CharacterSet(charactersIn: ":：\t ")
                    let components = cleanLine.components(separatedBy: separators).filter { !$0.isEmpty }
                    if components.count > 1 {
                        for component in components {
                            if !component.contains("被保險人") && !component.contains("被保人") {
                                data.insuredPerson = component
                                print("✅ 找到被保險人：\(component)")
                                break
                            }
                        }
                    }
                }
            }

            // 識別保單始期（日期格式）
            if data.startDate.isEmpty {
                if cleanLine.contains("保單生效日") || cleanLine.contains("契約生效日") ||
                   cleanLine.contains("始期") || cleanLine.contains("生效日期") {
                    // 支援多種日期格式
                    let datePatterns = [
                        #"(\d{4})[/-年](\d{1,2})[/-月](\d{1,2})[日]?"#,  // 2024/01/01 或 2024-01-01 或 2024年01月01日
                        #"(\d{3})[/-年](\d{1,2})[/-月](\d{1,2})[日]?"#,   // 民國 113/01/01
                    ]

                    for pattern in datePatterns {
                        if let match = cleanLine.range(of: pattern, options: .regularExpression) {
                            data.startDate = String(cleanLine[match])
                            print("✅ 找到保單始期：\(data.startDate)")
                            break
                        }
                    }
                }
            }

            // 識別保額
            if data.coverageAmount.isEmpty {
                if cleanLine.contains("保險金額") || cleanLine.contains("保額") ||
                   cleanLine.contains("Sum Insured") || cleanLine.contains("保險額") {
                    if let amount = extractAmount(from: cleanLine) {
                        data.coverageAmount = amount
                        print("✅ 找到保額：\(amount)")
                    }
                }
            }

            // 識別年繳保費
            if data.annualPremium.isEmpty {
                if cleanLine.contains("年繳") || cleanLine.contains("年保費") ||
                   cleanLine.contains("應繳保費") || cleanLine.contains("保險費") {
                    // 排除「繳費年期」的干擾
                    if !cleanLine.contains("年期") && !cleanLine.contains("繳費期") {
                        if let amount = extractAmount(from: cleanLine) {
                            data.annualPremium = amount
                            print("✅ 找到年繳保費：\(amount)")
                        }
                    }
                }
            }

            // 識別繳費年期
            if data.paymentPeriod.isEmpty {
                if cleanLine.contains("繳費年期") || cleanLine.contains("繳費期") || cleanLine.contains("繳別") {
                    if let yearMatch = cleanLine.range(of: #"\d{1,2}年"#, options: .regularExpression) {
                        let yearString = String(cleanLine[yearMatch])
                        data.paymentPeriod = yearString.replacingOccurrences(of: "年", with: "")
                        print("✅ 找到繳費年期：\(data.paymentPeriod)年")
                    }
                }
            }
        }

        // 如果保單名稱還是空的，嘗試從保險種類推測
        if data.policyName.isEmpty && !data.policyType.isEmpty {
            data.policyName = data.policyType
            print("⚠️  保單名稱空白，使用保險種類代替：\(data.policyType)")
        }

        print("\n📊 解析完成")
        return data
    }

    /// 從文字中提取金額（支援多種格式）
    private func extractAmount(from text: String) -> String? {
        // 匹配金額格式：包含逗號分隔的數字、小數點、各種貨幣符號
        let patterns = [
            // 完整格式：NT$1,000,000 或 $1,000,000 或 1,000,000元
            #"(?:NT\$?|TWD|\$)?\s*([0-9]{1,3}(?:,?[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:元|萬|萬元)?"#,
            // 僅數字加逗號：1,000,000
            #"([0-9]{1,3}(?:,?[0-9]{3})+)"#,
            // 僅數字（至少3位）：100000
            #"([0-9]{3,})"#
        ]

        var bestMatch: String? = nil
        var maxValue: Double = 0

        for pattern in patterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let matchString = String(text[match])
                // 提取純數字部分（移除逗號、貨幣符號等）
                let numberString = matchString.components(separatedBy: CharacterSet(charactersIn: "0123456789").inverted).joined()

                if !numberString.isEmpty {
                    // 檢查是否為萬元單位
                    if text.contains("萬") && !text.contains("萬元") {
                        // 如果是萬，需要乘以10000
                        if let value = Double(numberString) {
                            let actualValue = value * 10000
                            if actualValue > maxValue {
                                maxValue = actualValue
                                bestMatch = String(Int(actualValue))
                            }
                        }
                    } else {
                        // 選擇數值最大的匹配（通常保額和保費都是較大的數字）
                        if let value = Double(numberString), value > maxValue {
                            maxValue = value
                            bestMatch = numberString
                        }
                    }
                }
            }
        }

        return bestMatch
    }

    /// 驗證辨識結果的完整度
    /// - Parameter data: 辨識的保險單資料
    /// - Returns: (完整度百分比, 缺少的欄位列表)
    func validateData(_ data: InsurancePolicyData) -> (completeness: Double, missingFields: [String]) {
        var filledCount = 0
        var missingFields: [String] = []
        let totalFields = 10

        let fieldChecks: [(String, String)] = [
            (data.policyType, "保險種類"),
            (data.insuranceCompany, "保險公司"),
            (data.policyNumber, "保單號碼"),
            (data.policyName, "保險名稱"),
            (data.insuredPerson, "被保險人"),
            (data.startDate, "保單始期"),
            (data.paymentMonth, "繳費月份"),
            (data.coverageAmount, "保額"),
            (data.annualPremium, "年繳保費"),
            (data.paymentPeriod, "繳費年期")
        ]

        for (value, fieldName) in fieldChecks {
            if !value.isEmpty {
                filledCount += 1
            } else {
                missingFields.append(fieldName)
            }
        }

        let completeness = Double(filledCount) / Double(totalFields)
        return (completeness, missingFields)
    }

    // MARK: - 表格辨識功能

    /// 從表格照片中解析多筆保單資料
    /// - Parameter text: OCR辨識的文字內容
    /// - Returns: 多筆保單資料陣列
    func parseTableData(from text: String) -> [InsurancePolicyData] {
        print("\n📊 開始解析表格資料...")

        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        print("辨識到的文字行數：\(lines.count)")

        // 步驟 1: 尋找「保險公司」欄位，確定表格位置
        guard let companyHeaderIndex = findInsuranceCompanyHeader(in: lines) else {
            print("❌ 無法找到「保險公司」欄位，嘗試單筆解析")
            return [parseInsuranceData(from: text)]
        }

        print("✅ 找到「保險公司」欄位在第 \(companyHeaderIndex + 1) 行")

        // 步驟 2: 判斷表格方向
        let orientation = detectTableOrientation(lines: lines, headerIndex: companyHeaderIndex)
        print("📐 表格方向：\(orientationName(orientation))")

        // 步驟 3: 根據方向解析表格
        switch orientation {
        case .horizontal:
            return parseHorizontalTable(lines: lines, headerIndex: companyHeaderIndex)
        case .vertical:
            return parseVerticalTable(lines: lines, headerIndex: companyHeaderIndex)
        case .unknown:
            print("⚠️  無法判斷表格方向，使用單筆解析")
            return [parseInsuranceData(from: text)]
        }
    }

    /// 尋找「保險公司」欄位標題
    private func findInsuranceCompanyHeader(in lines: [String]) -> Int? {
        let keywords = ["保險公司", "保險", "公司名稱", "Company"]

        for (index, line) in lines.enumerated() {
            for keyword in keywords {
                if line.contains(keyword) {
                    // 檢查這行是否像表頭（包含多個欄位名稱）
                    let headerKeywords = ["保險", "保單", "被保險人", "保額", "保費", "日期", "始期"]
                    let matchCount = headerKeywords.filter { line.contains($0) }.count

                    if matchCount >= 2 {
                        return index
                    }
                }
            }
        }

        return nil
    }

    /// 判斷表格方向
    private func detectTableOrientation(lines: [String], headerIndex: Int) -> TableOrientation {
        let headerLine = lines[headerIndex]

        // 檢查表頭行的欄位數量
        let fieldKeywords = ["保險公司", "保單號碼", "被保險人", "保額", "保費", "保險種類"]
        let fieldCount = fieldKeywords.filter { headerLine.contains($0) }.count

        print("📊 表頭行包含 \(fieldCount) 個欄位關鍵字")

        // 方法 1: 如果表頭行包含多個欄位，判斷為橫向表格
        if fieldCount >= 3 {
            print("   ✅ 依據：表頭包含 ≥3 個欄位關鍵字")
            return .horizontal
        }

        // 方法 2: 檢查表頭下方是否有多行資料包含保險公司名稱（強化版）
        if headerIndex + 1 < lines.count {
            let maxCheckLines = min(headerIndex + 10, lines.count - 1)  // 檢查更多行
            let dataLines = Array(lines[(headerIndex + 1)...maxCheckLines])
            let insuranceCompanies = [
                "國泰", "富邦", "南山", "新光", "中國", "台灣", "全球", "遠雄", "三商", "保誠", "安聯", "元大"
            ]

            var companyLineCount = 0
            var detectedCompanies: [String] = []

            for (index, line) in dataLines.enumerated() {
                for company in insuranceCompanies {
                    if line.contains(company) {
                        companyLineCount += 1
                        detectedCompanies.append("\(company)(第\(headerIndex + index + 2)行)")
                        print("   🔍 第 \(headerIndex + index + 2) 行包含保險公司：\(company)")
                        break  // 每行只計算一次
                    }
                }
            }

            print("   📊 表頭下方共找到 \(companyLineCount) 行包含保險公司名稱")
            if !detectedCompanies.isEmpty {
                print("   📋 檢測到的公司：\(detectedCompanies.joined(separator: ", "))")
            }

            // 降低門檻：只要找到 ≥2 行包含公司名稱，就判定為橫向
            if companyLineCount >= 2 {
                print("   ✅ 依據：表頭下方有 \(companyLineCount) 行包含保險公司名稱（≥2）")
                return .horizontal
            }

            // 再降低門檻：如果只有 1 個欄位關鍵字（保險公司），但下方有至少 1 行公司名稱
            if fieldCount >= 1 && companyLineCount >= 1 {
                print("   ✅ 依據：表頭包含「保險公司」+ 下方有 \(companyLineCount) 行資料")
                return .horizontal
            }
        }

        // 方法 3: 檢查表頭行的長度和複雜度
        // 如果表頭行很長，可能包含多個欄位
        let headerLength = headerLine.count
        let separatorCount = headerLine.components(separatedBy: "\t").count +
                           headerLine.components(separatedBy: "  ").count

        if headerLength > 20 && separatorCount > 2 {
            print("   ✅ 依據：表頭行長度 \(headerLength) 字元，包含多個分隔符")
            return .horizontal
        }

        // 無法判斷時，預設為橫向（大多數表格都是橫向）
        print("   ⚠️  無法明確判斷，預設為橫向表格")
        return .horizontal  // 改為預設橫向，而非直向
    }

    /// 解析橫向表格（表頭在上，每列一個保單）
    private func parseHorizontalTable(lines: [String], headerIndex: Int) -> [InsurancePolicyData] {
        print("\n🔄 開始解析橫向表格...")

        var policies: [InsurancePolicyData] = []
        let headerLine = lines[headerIndex]

        // 解析表頭，找出各欄位的位置
        let headers = parseTableHeaders(headerLine)
        print("📋 找到 \(headers.count) 個表頭：\(headers.map { $0.0 }.joined(separator: ", "))")

        // 從表頭下一行開始解析資料
        for i in (headerIndex + 1)..<lines.count {
            let line = lines[i]

            // 跳過空行
            if line.isEmpty { continue }

            // 檢查是否為資料行（包含保險公司名稱）
            let insuranceCompanies = [
                "國泰", "富邦", "南山", "新光", "中國", "台灣", "全球", "遠雄", "三商", "保誠"
            ]

            let containsCompany = insuranceCompanies.contains(where: { line.contains($0) })
            if !containsCompany {
                print("⏭️  跳過非資料行（第 \(i + 1) 行）")
                continue
            }

            print("\n📝 解析第 \(i + 1) 行資料")
            let policyData = parseTableRow(line: line, headers: headers)

            if !policyData.insuranceCompany.isEmpty {
                policies.append(policyData)
                print("✅ 成功解析第 \(policies.count) 筆保單：\(policyData.insuranceCompany)")
            }
        }

        print("\n📊 共解析出 \(policies.count) 筆保單")
        return policies
    }

    /// 解析直向表格（表頭在左，每欄一個保單）
    private func parseVerticalTable(lines: [String], headerIndex: Int) -> [InsurancePolicyData] {
        print("\n🔄 開始解析直向表格...")

        // TODO: 實作直向表格解析
        // 目前先回傳單筆解析結果
        return [parseInsuranceData(from: lines.joined(separator: "\n"))]
    }

    /// 解析表頭，提取欄位名稱和位置
    private func parseTableHeaders(_ headerLine: String) -> [(String, Int)] {
        var headers: [(String, Int)] = []

        let fieldMappings: [String: [String]] = [
            "保險公司": ["保險公司", "公司", "Company"],
            "保險種類": ["保險種類", "險種", "Type"],
            "保單號碼": ["保單號碼", "契約號碼", "Policy No"],
            "保險名稱": ["保險名稱", "商品名稱", "Name"],
            "被保險人": ["被保險人", "被保人", "Insured"],
            "保單始期": ["保單始期", "始期", "生效日", "Start Date"],
            "保額": ["保額", "保險金額", "Sum Insured"],
            "年繳保費": ["年繳", "保費", "Premium"],
            "繳費年期": ["繳費年期", "年期", "Period"]
        ]

        for (standardName, variants) in fieldMappings {
            for variant in variants {
                if let range = headerLine.range(of: variant) {
                    let position = headerLine.distance(from: headerLine.startIndex, to: range.lowerBound)
                    headers.append((standardName, position))
                    break
                }
            }
        }

        // 按位置排序
        return headers.sorted { $0.1 < $1.1 }
    }

    /// 解析表格資料行（改用分隔符方法）
    private func parseTableRow(line: String, headers: [(String, Int)]) -> InsurancePolicyData {
        var data = InsurancePolicyData()

        print("   原始行：\(line)")

        // 方法 1: 嘗試使用 Tab 分隔
        var components = line.components(separatedBy: "\t").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        // 方法 2: 如果 Tab 不夠，嘗試使用多個空格分隔（使用正則表達式）
        if components.count < 2 {
            components = line.split(whereSeparator: { $0 == " " }).reduce(into: [String]()) { result, part in
                let trimmed = part.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    if result.isEmpty || !result.last!.isEmpty {
                        result.append(trimmed)
                    }
                }
            }

            // 如果還是不夠，改用手動切分多個空格
            if components.count < 2 {
                components = []
                var currentWord = ""
                var spaceCount = 0

                for char in line {
                    if char == " " {
                        spaceCount += 1
                        if spaceCount >= 2 && !currentWord.isEmpty {
                            components.append(currentWord)
                            currentWord = ""
                        }
                    } else {
                        if spaceCount >= 2 && !currentWord.isEmpty {
                            components.append(currentWord)
                            currentWord = ""
                        }
                        spaceCount = 0
                        currentWord.append(char)
                    }
                }
                if !currentWord.isEmpty {
                    components.append(currentWord)
                }
            }
        }

        // 方法 3: 如果還是不夠，嘗試使用單個空格
        if components.count < 2 {
            components = line.components(separatedBy: " ").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }

        print("   切分成 \(components.count) 個部分：\(components)")

        // 智能匹配：根據內容推測欄位
        for (index, component) in components.enumerated() {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            print("   分析第 \(index + 1) 個部分：\(trimmed)")

            // 檢查保險公司
            let insuranceCompanies = [
                "國泰人壽", "富邦人壽", "南山人壽", "新光人壽", "中國人壽",
                "台灣人壽", "全球人壽", "遠雄人壽", "三商美邦", "保誠人壽",
                "國泰", "富邦", "南山", "新光", "遠雄", "全球"
            ]

            if data.insuranceCompany.isEmpty {
                for company in insuranceCompanies {
                    if trimmed.contains(company) {
                        data.insuranceCompany = trimmed
                        print("      → 保險公司")
                        continue
                    }
                }
            }

            // 檢查保單號碼（英文+數字組合，或純數字10位以上）
            if data.policyNumber.isEmpty {
                if trimmed.range(of: #"^[A-Z]{1,4}[0-9]{6,12}$"#, options: .regularExpression) != nil ||
                   trimmed.range(of: #"^\d{10,}$"#, options: .regularExpression) != nil {
                    data.policyNumber = trimmed
                    print("      → 保單號碼")
                    continue
                }
            }

            // 檢查保險種類
            if data.policyType.isEmpty {
                let types = ["壽險", "醫療險", "意外險", "投資型"]
                for type in types {
                    if trimmed.contains(type) || trimmed == type {
                        data.policyType = trimmed
                        print("      → 保險種類")
                        break
                    }
                }
                if !data.policyType.isEmpty { continue }
            }

            // 檢查被保險人（通常是人名，2-4個中文字）
            if data.insuredPerson.isEmpty {
                if trimmed.range(of: #"^[\u{4e00}-\u{9fa5}]{2,4}$"#, options: .regularExpression) != nil {
                    data.insuredPerson = trimmed
                    print("      → 被保險人")
                    continue
                }
            }

            // 檢查日期（包含 /-年月日）
            if data.startDate.isEmpty {
                if trimmed.range(of: #"\d{2,4}[/-年]\d{1,2}[/-月]\d{1,2}"#, options: .regularExpression) != nil {
                    data.startDate = trimmed
                    print("      → 保單始期")
                    continue
                }
            }

            // 檢查金額（數字，可能帶逗號）
            if let _ = extractAmount(from: trimmed) {
                let amount = extractAmount(from: trimmed)!

                // 判斷是保額還是保費（通常保額較大）
                if let value = Double(amount) {
                    if value > 100000 && data.coverageAmount.isEmpty {
                        data.coverageAmount = amount
                        print("      → 保額：\(amount)")
                    } else if data.annualPremium.isEmpty {
                        data.annualPremium = amount
                        print("      → 年繳保費：\(amount)")
                    }
                }
                continue
            }

            // 檢查繳費年期
            if data.paymentPeriod.isEmpty {
                if let match = trimmed.range(of: #"\d{1,2}年"#, options: .regularExpression) {
                    data.paymentPeriod = String(trimmed[match]).replacingOccurrences(of: "年", with: "")
                    print("      → 繳費年期")
                    continue
                }
            }

            // 如果還沒有保單名稱，且包含「險」字，可能是保單名稱
            if data.policyName.isEmpty && trimmed.contains("險") && !trimmed.contains("保險公司") {
                data.policyName = trimmed
                print("      → 保單名稱")
                continue
            }
        }

        return data
    }

    /// 取得方向名稱
    private func orientationName(_ orientation: TableOrientation) -> String {
        switch orientation {
        case .horizontal: return "橫向表格（表頭在上）"
        case .vertical: return "直向表格（表頭在左）"
        case .unknown: return "無法判斷"
        }
    }
}
