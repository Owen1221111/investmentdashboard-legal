//
//  RegionOCRManager.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/17.
//  區域OCR辨識管理器（針對性辨識特定區域的數字）
//

import Foundation
import UIKit
import Vision
import CoreImage

/// 欄位類型
enum CalculatorColumn: String, CaseIterable {
    case cashValue = "保單現金價值（解約金）"
    case deathBenefit = "身故保險金"

    var displayName: String {
        return self.rawValue
    }
}

/// 區域OCR辨識管理器
class RegionOCRManager {

    /// 辨識指定區域的數字
    /// - Parameters:
    ///   - image: 原始圖片
    ///   - region: 要辨識的區域（圖片座標）
    ///   - completion: 完成回調，返回辨識到的數字陣列
    func recognizeNumbers(
        in image: UIImage,
        region: CGRect,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        print("\n🔍 開始區域辨識...")
        print("   原始圖片大小：\(image.size)")
        print("   選取區域：\(region)")

        // 裁切圖片
        guard let croppedImage = cropImage(image, toRect: region) else {
            completion(.failure(NSError(domain: "RegionOCRManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "無法裁切圖片"])))
            return
        }

        print("   裁切後圖片大小：\(croppedImage.size)")

        // 儲存裁切後的圖片（除錯用）
        saveCroppedImageForDebug(croppedImage)

        // 圖片預處理（提高對比度和清晰度）
        let processedImage = preprocessImage(croppedImage)
        print("   預處理完成")

        // 儲存預處理後的圖片（除錯用）
        saveCroppedImageForDebug(processedImage, suffix: "_processed")

        guard let cgImage = processedImage.cgImage else {
            completion(.failure(NSError(domain: "RegionOCRManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "無法取得圖片"])))
            return
        }

        // 建立文字辨識請求
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("❌ 辨識失敗：\(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("❌ 無法取得辨識結果")
                completion(.failure(NSError(domain: "RegionOCRManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "無法辨識文字"])))
                return
            }

            print("\n📋 辨識到 \(observations.count) 個文字區塊")

            // 提取所有文字（包含信心度）
            var allTexts: [(text: String, y: CGFloat, confidence: Float)] = []
            for (index, observation) in observations.enumerated() {
                if let candidate = observation.topCandidates(3).first(where: { self.containsNumber($0.string) }) {
                    allTexts.append((text: candidate.string, y: observation.boundingBox.midY, confidence: candidate.confidence))
                    let cleaned = self.cleanNumberString(candidate.string)
                    print("   [\(index)] 辨識文字：\(candidate.string) → 清理後：\(cleaned) | 信心度：\(String(format: "%.2f", candidate.confidence)) | Y:\(String(format: "%.3f", observation.boundingBox.midY))")
                }
            }

            // 過濾出數字並按 Y 座標排序（從上到下）
            let numbers = allTexts
                .filter { $0.confidence > 0.3 } // 過濾低信心度的結果
                .sorted { $0.y > $1.y } // Vision 座標系統 Y 軸反轉
                .map { self.cleanNumberString($0.text) }
                .filter { !$0.isEmpty && self.isValidNumber($0) && !self.isTooShort($0) } // 過濾太短的數字

            print("\n✅ 辨識到 \(numbers.count) 個有效數字")
            for (index, number) in numbers.enumerated() {
                print("   [\(index + 1)] \(number)")
            }

            if numbers.isEmpty {
                print("⚠️ 未辨識到任何數字，可能原因：")
                print("   1. 選取區域不正確")
                print("   2. 圖片解析度太低")
                print("   3. 數字過小或模糊")
            }

            completion(.success(numbers))
        }

        // 設定辨識參數（針對數字優化）
        request.recognitionLevel = .accurate // 使用精確模式
        request.recognitionLanguages = ["en-US"] // 數字用英文模式
        request.usesLanguageCorrection = false // 關閉語言修正
        request.minimumTextHeight = 0.01 // 降低最小文字高度，辨識較小的數字
        request.customWords = [] // 清空自定義詞典

        // 執行辨識
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("❌ 執行辨識失敗：\(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - 圖片處理

    /// 裁切圖片
    private func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        // 確保座標在圖片範圍內
        let clampedRect = CGRect(
            x: max(0, rect.minX),
            y: max(0, rect.minY),
            width: min(rect.width, image.size.width - rect.minX),
            height: min(rect.height, image.size.height - rect.minY)
        )

        // 檢查裁切區域是否有效
        guard clampedRect.width > 0 && clampedRect.height > 0 else {
            print("❌ 裁切區域無效：\(clampedRect)")
            return nil
        }

        guard let croppedCGImage = cgImage.cropping(to: clampedRect) else {
            print("❌ 裁切失敗")
            return nil
        }

        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// 圖片預處理（提高對比度和清晰度）
    private func preprocessImage(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        let context = CIContext()

        // 1. 增強對比度
        let contrastFilter = CIFilter(name: "CIColorControls")
        contrastFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        contrastFilter?.setValue(1.5, forKey: kCIInputContrastKey) // 對比度增強
        contrastFilter?.setValue(0.1, forKey: kCIInputBrightnessKey) // 稍微提亮

        var outputImage = contrastFilter?.outputImage ?? ciImage

        // 2. 銳化
        let sharpenFilter = CIFilter(name: "CISharpenLuminance")
        sharpenFilter?.setValue(outputImage, forKey: kCIInputImageKey)
        sharpenFilter?.setValue(0.8, forKey: kCIInputSharpnessKey)

        outputImage = sharpenFilter?.outputImage ?? outputImage

        // 3. 轉回 UIImage
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }

        return image
    }

    // MARK: - 輔助函數

    /// 檢查文字是否包含數字
    private func containsNumber(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: .decimalDigits) != nil
    }

    /// 驗證是否為有效數字
    private func isValidNumber(_ text: String) -> Bool {
        // 檢查是否全是數字
        let onlyDigits = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return onlyDigits.count >= 1
    }

    /// 檢查數字是否太短（可能是誤辨識）
    private func isTooShort(_ text: String) -> Bool {
        // 保險金額通常至少有4位數以上，太短的可能是誤辨識
        return text.count < 4
    }

    /// 儲存裁切後的圖片供除錯（會儲存到相簿）
    private func saveCroppedImageForDebug(_ image: UIImage, suffix: String = "") {
        // 在背景執行，避免阻塞主線程
        DispatchQueue.global(qos: .utility).async {
            let filename = "ocr_debug\(suffix)_\(Date().timeIntervalSince1970).jpg"

            if let data = image.jpegData(compressionQuality: 0.9) {
                // 儲存到暫存目錄
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent(filename)

                do {
                    try data.write(to: fileURL)
                    print("   💾 除錯圖片已儲存：\(fileURL.path)")
                } catch {
                    print("   ⚠️ 無法儲存除錯圖片：\(error)")
                }
            }
        }
    }

    /// 清理數字字串（保留小數點）
    private func cleanNumberString(_ string: String) -> String {
        var cleaned = string
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "NT$", with: "")
            .replacingOccurrences(of: "TWD", with: "")
            .trimmingCharacters(in: .whitespaces)

        // 移除所有非數字和小數點的字元
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
        cleaned = cleaned.components(separatedBy: allowedCharacters.inverted).joined()

        // 移除小數點（保險金額通常是整數）
        cleaned = cleaned.replacingOccurrences(of: ".", with: "")

        return cleaned
    }
}
