//
//  CalculatorTableParser.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/16.
//  保險試算表解析器（支援CSV和OCR圖片）
//

import Foundation
import UIKit
import Vision

/// 試算表解析器
class CalculatorTableParser {

    // MARK: - CSV 解析

    /// 從CSV檔案解析試算表資料
    /// - Parameter fileURL: CSV檔案路徑
    /// - Returns: 解析後的資料行陣列
    func parseCSV(from fileURL: URL) -> Result<[CalculatorRowData], Error> {
        do {
            let csvContent = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = parseCSVContent(csvContent)
            return .success(rows)
        } catch {
            return .failure(error)
        }
    }

    /// 從CSV內容字串解析試算表資料
    /// - Parameter content: CSV內容
    /// - Returns: 解析後的資料行陣列
    func parseCSVContent(_ content: String) -> [CalculatorRowData] {
        var rows: [CalculatorRowData] = []

        // 分割成行
        let lines = content.components(separatedBy: .newlines)

        // 跳過標題行（第一行）
        let dataLines = lines.dropFirst().filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        for line in dataLines {
            // 分割欄位（支援逗號和Tab分隔）
            let fields = line.components(separatedBy: CharacterSet(charactersIn: ",\t"))
                .map { $0.trimmingCharacters(in: .whitespaces) }

            guard fields.count >= 4 else { continue }

            let row = CalculatorRowData(
                policyYear: fields[0],
                insuranceAge: fields[1],
                cashValue: cleanNumberString(fields[2]),
                deathBenefit: cleanNumberString(fields[3])
            )

            if row.isValid {
                rows.append(row)
            }
        }

        return rows
    }

    // MARK: - OCR 圖片辨識

    /// 從圖片辨識試算表資料
    /// - Parameters:
    ///   - image: 要辨識的圖片
    ///   - completion: 完成回調，返回解析後的資料行陣列
    func parseImageTable(
        from image: UIImage,
        completion: @escaping (Result<[CalculatorRowData], Error>) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(.failure(NSError(domain: "CalculatorTableParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "無法取得圖片"])))
            return
        }

        // 建立文字辨識請求
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(NSError(domain: "CalculatorTableParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "無法辨識文字"])))
                return
            }

            // 提取文字及其位置資訊
            let textBlocks = observations.compactMap { observation -> TextBlock? in
                guard let text = observation.topCandidates(1).first?.string else { return nil }
                return TextBlock(text: text, boundingBox: observation.boundingBox)
            }

            print("📋 OCR 辨識到 \(textBlocks.count) 個文字區塊")

            // 解析表格資料（使用位置資訊）
            let rows = self.parseTableWithPositions(textBlocks)
            completion(.success(rows))
        }

        // 設定辨識語言（繁體中文 + 英文 + 數字）
        request.recognitionLanguages = ["zh-Hant", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        // 執行辨識
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// 文字區塊（包含文字和位置）
    private struct TextBlock {
        let text: String
        let boundingBox: CGRect

        var centerY: CGFloat { boundingBox.midY }
        var centerX: CGFloat { boundingBox.midX }
        var minX: CGFloat { boundingBox.minX }
    }

    /// 使用位置資訊解析表格（新方法）
    /// - Parameter textBlocks: 包含文字和位置的區塊陣列
    /// - Returns: 解析後的資料行陣列
    private func parseTableWithPositions(_ textBlocks: [TextBlock]) -> [CalculatorRowData] {
        print("\n🔍 開始解析表格...")

        // 步驟1：找到「保單年度」和「保險年齡」標題（先用原始方法）
        guard let policyYearHeader = findHeaderColumn(in: textBlocks, keywords: ["保單年度", "年度"]),
              let insuranceAgeHeader = findHeaderColumn(in: textBlocks, keywords: ["保險年齡", "年齡"]) else {
            print("❌ 找不到「保單年度」或「保險年齡」欄位標題")
            return fallbackParse(textBlocks)
        }

        print("✅ 找到核心欄位標題：")
        print("   保單年度：x=\(policyYearHeader.centerX), y=\(policyYearHeader.centerY)")
        print("   保險年齡：x=\(insuranceAgeHeader.centerX), y=\(insuranceAgeHeader.centerY)")

        // 檢查位置是否合理（保單年度應該在保險年齡左邊）
        if policyYearHeader.centerX > insuranceAgeHeader.centerX {
            print("⚠️ 欄位位置可能有誤，保單年度應該在保險年齡左邊")
            print("   嘗試交換兩個欄位...")
            // 暫時不交換，先看看實際數據
        }

        // 步驟2：找出標題行的 Y 座標
        let headerY = policyYearHeader.centerY

        // 步驟3：提取所有數字區塊（Y座標在標題下方）
        let numberBlocks = textBlocks.filter { block in
            block.centerY < headerY - 0.02 && // 在標題下方（Vision 座標系統是反的）
            containsNumber(block.text)
        }

        print("\n🔢 找到 \(numberBlocks.count) 個數字區塊")

        // 步驟4：按 Y 座標分組（相同行）
        let groupedByRow = groupBlocksByRow(numberBlocks)
        print("📋 分組為 \(groupedByRow.count) 行")

        // 步驟5：提取每一行的資料（保單年度直接用行號 1~100）
        var rows: [CalculatorRowData] = []

        for (index, rowBlocks) in groupedByRow.enumerated() {
            // 保單年度直接使用行號（從1開始）
            let policyYear = String(index + 1)

            // 如果超過100行，停止處理
            guard index < 100 else {
                print("   ⚠️ 已達到最大行數（100行），停止處理")
                break
            }

            // 按 X 座標排序所有區塊（從左到右）
            let sortedBlocks = rowBlocks.sorted { $0.centerX < $1.centerX }

            // 至少要有1個數字（保險年齡）
            guard sortedBlocks.count >= 1 else {
                print("   ⚠️ 第\(policyYear)行：沒有找到數字，跳過此行")
                continue
            }

            // 第1個數字是保險年齡
            let insuranceAgeRaw = sortedBlocks[0].text

            // 清理保險年齡（自動修正OCR錯誤，如69→9）
            let insuranceAge = cleanInsuranceAge(insuranceAgeRaw, expectedMinAge: 60)

            // 驗證保險年齡
            guard isValidInsuranceAge(insuranceAge) else {
                print("   ⚠️ 第\(policyYear)行：保險年齡[\(insuranceAgeRaw)]不合理，跳過此行")
                continue
            }

            print("   ✅ 第\(policyYear)行：保單年度[\(policyYear)] | 保險年齡[\(insuranceAge)]")

            // 第2個數字是保單現金價值，第3個是身故保險金
            let cashValue = sortedBlocks.count >= 2 ? sortedBlocks[1].text : ""
            let deathBenefit = sortedBlocks.count >= 3 ? sortedBlocks[2].text : ""

            let row = CalculatorRowData(
                policyYear: policyYear,
                insuranceAge: insuranceAge,
                cashValue: cleanNumberString(cashValue),
                deathBenefit: cleanNumberString(deathBenefit)
            )
            rows.append(row)
            print("      完整資料：\(policyYear) | \(insuranceAge) | \(cleanNumberString(cashValue)) | \(cleanNumberString(deathBenefit))")
        }

        print("\n✅ 解析完成，共 \(rows.count) 行資料\n")
        return rows
    }

    /// 清理整數字串（只保留數字，移除小數點和其他符號）
    private func cleanIntegerString(_ string: String) -> String {
        // 只保留數字
        let digits = string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return digits
    }

    /// 清理保險年齡（處理OCR錯誤）
    /// - Parameters:
    ///   - ageString: 原始年齡字串
    ///   - expectedMinAge: 預期的最小年齡（例如60）
    /// - Returns: 清理後的年齡字串
    private func cleanInsuranceAge(_ ageString: String, expectedMinAge: Int) -> String {
        let cleaned = cleanIntegerString(ageString)
        guard let age = Int(cleaned) else { return cleaned }

        // 如果是個位數（9, 10, 11...），可能是69, 70, 71被OCR誤認
        // 例如：9 → 69, 10 → 70（假設最小年齡是60）
        if age < 30 && age >= 0 {
            let correctedAge = expectedMinAge + age
            if correctedAge <= 120 {
                print("      🔧 修正年齡：\(age) → \(correctedAge)")
                return String(correctedAge)
            }
        }

        return cleaned
    }

    /// 驗證保險年齡是否合理
    private func isValidInsuranceAge(_ ageString: String) -> Bool {
        guard let age = Int(ageString) else {
            return false
        }
        return age >= 0 && age <= 120
    }

    /// 尋找欄位標題
    private func findHeaderColumn(in blocks: [TextBlock], keywords: [String], minX: CGFloat = 0) -> TextBlock? {
        return blocks.first { block in
            block.minX >= minX &&
            keywords.contains { keyword in
                block.text.contains(keyword)
            }
        }
    }

    /// 檢查文字是否包含數字
    private func containsNumber(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: .decimalDigits) != nil
    }

    /// 按行分組（Y座標相近的視為同一行）
    private func groupBlocksByRow(_ blocks: [TextBlock]) -> [[TextBlock]] {
        var groups: [[TextBlock]] = []
        var sortedBlocks = blocks.sorted { $0.centerY > $1.centerY } // 從上到下排序

        while !sortedBlocks.isEmpty {
            let current = sortedBlocks.removeFirst()
            var rowGroup = [current]

            // 找出 Y 座標相近的所有區塊（容差0.02）
            sortedBlocks.removeAll { block in
                if abs(block.centerY - current.centerY) < 0.02 {
                    rowGroup.append(block)
                    return true
                }
                return false
            }

            // 按 X 座標排序
            rowGroup.sort { $0.centerX < $1.centerX }
            groups.append(rowGroup)
        }

        return groups
    }

    /// 在指定欄位位置附近找數值
    private func findValueInColumn(_ blocks: [TextBlock], nearX: CGFloat, tolerance: CGFloat) -> String {
        // 找最接近目標 X 座標的區塊
        let candidate = blocks.min { block1, block2 in
            abs(block1.centerX - nearX) < abs(block2.centerX - nearX)
        }

        // 檢查是否在容差範圍內
        if let block = candidate, abs(block.centerX - nearX) <= tolerance {
            return block.text
        }

        return ""
    }

    /// 備用解析方法（當找不到標題時使用）
    private func fallbackParse(_ textBlocks: [TextBlock]) -> [CalculatorRowData] {
        print("⚠️ 使用備用解析方法...")

        // 提取所有數字
        let numberBlocks = textBlocks.filter { containsNumber($0.text) }
        let groupedByRow = groupBlocksByRow(numberBlocks)

        var rows: [CalculatorRowData] = []
        for rowBlocks in groupedByRow {
            let numbers = rowBlocks.map { $0.text }

            // 如果有4個或以上的數字，視為有效行
            if numbers.count >= 4 {
                let row = CalculatorRowData(
                    policyYear: numbers[0],
                    insuranceAge: numbers[1],
                    cashValue: cleanNumberString(numbers[2]),
                    deathBenefit: cleanNumberString(numbers[3])
                )
                rows.append(row)
            }
        }

        return rows
    }

    /// 清理數字字串（移除逗號、空格等）
    /// - Parameter string: 輸入字串
    /// - Returns: 清理後的數字字串
    private func cleanNumberString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "NT$", with: "")
            .replacingOccurrences(of: "TWD", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - 資料驗證

    /// 驗證試算表資料是否有效
    /// - Parameter rows: 資料行陣列
    /// - Returns: 驗證結果
    func validateRows(_ rows: [CalculatorRowData]) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []

        if rows.isEmpty {
            errors.append("沒有有效的資料行")
            return (false, errors)
        }

        // 檢查每一行的資料
        for (index, row) in rows.enumerated() {
            let rowNumber = index + 1

            if row.policyYear.isEmpty {
                errors.append("第 \(rowNumber) 行：缺少保單年度")
            }

            if row.insuranceAge.isEmpty {
                errors.append("第 \(rowNumber) 行：缺少保險年齡")
            }

            // 檢查數字格式
            if !row.cashValue.isEmpty, Double(row.cashValue) == nil {
                errors.append("第 \(rowNumber) 行：保單現金價值格式錯誤")
            }

            if !row.deathBenefit.isEmpty, Double(row.deathBenefit) == nil {
                errors.append("第 \(rowNumber) 行：身故保險金格式錯誤")
            }
        }

        return (errors.isEmpty, errors)
    }
}
