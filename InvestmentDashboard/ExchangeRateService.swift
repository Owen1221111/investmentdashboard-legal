//
//  ExchangeRateService.swift
//  InvestmentDashboard
//
//  Created by CheHung Liu on 2025/11/30.
//

import Foundation

// 匯率服務：台灣銀行 API + ExchangeRate-API 雙重備援
class ExchangeRateService {
    static let shared = ExchangeRateService()

    // 使用自定義 URLSession 配置
    private let urlSession: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.urlSession = URLSession(configuration: config)
    }

    /// 取得匯率資料（混合使用台灣銀行 API 和 ExchangeRate-API）
    /// - Returns: (匯率字典, 資料來源, 匯率日期)
    func fetchExchangeRates() async -> (rates: [String: Double], source: String, date: String)? {
        var finalRates: [String: Double] = [:]
        var source = ""
        var dateString = ""

        // 1️⃣ 嘗試從 ExchangeRate-API 獲取所有貨幣匯率（包括 TWD）
        if let (exchangeRates, timestamp) = await fetchFromExchangeRateAPI() {
            print("✅ 成功從 ExchangeRate-API 取得所有貨幣匯率")
            finalRates = exchangeRates
            source = "ExchangeRate-API"
            dateString = formatTimestamp(timestamp)

            // 2️⃣ 嘗試從台灣銀行 API 獲取更準確的台幣匯率（覆蓋 TWD/USD）
            if let taiwanBankRates = await fetchFromTaiwanBank() {
                print("✅ 成功從台灣銀行取得台幣匯率，覆蓋原有數據")
                // 覆蓋台幣匯率（台灣銀行的數據更準確）
                if let twdRate = taiwanBankRates["TWD/USD"] {
                    finalRates["TWD/USD"] = twdRate
                    source = "ExchangeRate-API + 台灣銀行"
                    dateString = formatTaiwanBankDate()
                }
            }

            return (finalRates, source, dateString)
        }

        print("⚠️ ExchangeRate-API 失敗，嘗試僅使用台灣銀行 API")

        // 3️⃣ 備援：如果 ExchangeRate-API 失敗，至少取得台幣匯率
        if let taiwanBankRates = await fetchFromTaiwanBank() {
            print("✅ 成功從台灣銀行取得台幣匯率（其他貨幣無法取得）")
            dateString = formatTaiwanBankDate()
            return (taiwanBankRates, "台灣銀行（僅台幣）", dateString)
        }

        print("❌ 所有匯率 API 都失敗了")
        return nil
    }

    // MARK: - 台灣銀行 API
    /// 從台灣銀行取得匯率（CSV 格式）
    private func fetchFromTaiwanBank() async -> [String: Double]? {
        let urlString = "https://rate.bot.com.tw/xrt/flcsv/0/day"

        guard let url = URL(string: urlString) else {
            print("❌ 台灣銀行 URL 無效")
            return nil
        }

        do {
            let (data, response) = try await urlSession.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ 台灣銀行 API 請求失敗")
                return nil
            }

            // 將資料轉換為 Big5 編碼的字串
            guard let csvString = String(data: data, encoding: .utf8) ??
                                   String(data: data, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.big5.rawValue)))) else {
                print("❌ 無法解析台灣銀行 CSV 資料")
                return nil
            }

            return parseTaiwanBankCSV(csvString)
        } catch {
            print("❌ 台灣銀行 API 網路錯誤: \(error.localizedDescription)")
            return nil
        }
    }

    /// 解析台灣銀行 CSV 格式
    /// CSV 格式: 幣別,現金買入,現金賣出,即期買入,即期賣出
    private func parseTaiwanBankCSV(_ csvString: String) -> [String: Double]? {
        var rates: [String: Double] = [:]

        let lines = csvString.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }

        // 跳過第一行（標題行）
        for (index, line) in lines.enumerated() {
            guard index > 0 else { continue }

            let columns = line.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            guard columns.count >= 5 else { continue }

            let currency = columns[0]

            // 使用即期賣出匯率（第4欄，index 3）
            if let rate = Double(columns[3]) {
                // 轉換幣別代碼
                let currencyCode = mapBankCurrencyCode(currency)
                // TWD 對 USD 匯率
                if currencyCode == "USD" {
                    rates["TWD/USD"] = rate
                } else {
                    // 其他貨幣先不處理，因為台灣銀行給的是對台幣的匯率
                    // 如果需要其他貨幣對美金的匯率，需要額外計算
                }
            }
        }

        print("📊 台灣銀行匯率解析結果: \(rates)")
        return rates.isEmpty ? nil : rates
    }

    /// 映射台灣銀行幣別代碼
    private func mapBankCurrencyCode(_ bankCode: String) -> String {
        switch bankCode {
        case "美金": return "USD"
        case "歐元": return "EUR"
        case "日圓": return "JPY"
        case "英鎊": return "GBP"
        case "人民幣": return "CNY"
        case "澳幣": return "AUD"
        case "加拿大幣": return "CAD"
        case "瑞士法郎": return "CHF"
        case "港幣": return "HKD"
        case "新加坡幣": return "SGD"
        default: return bankCode
        }
    }

    // MARK: - ExchangeRate-API（備援）
    /// 從 ExchangeRate-API 取得匯率
    /// - Returns: (匯率字典, 時間戳)
    private func fetchFromExchangeRateAPI() async -> ([String: Double], Int)? {
        // 使用免費版本的 API（以 USD 為基準）
        let urlString = "https://api.exchangerate-api.com/v4/latest/USD"

        guard let url = URL(string: urlString) else {
            print("❌ ExchangeRate-API URL 無效")
            return nil
        }

        do {
            let (data, response) = try await urlSession.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ ExchangeRate-API 請求失敗")
                return nil
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(ExchangeRateAPIResponse.self, from: data)

            var rates: [String: Double] = [:]

            // TWD/USD 匯率（USD 對 TWD 的匯率）
            if let twdRate = result.rates["TWD"] {
                rates["TWD/USD"] = twdRate
            }

            // 其他貨幣對 USD 的匯率
            if let eurRate = result.rates["EUR"] {
                rates["EUR/USD"] = eurRate
            }
            if let jpyRate = result.rates["JPY"] {
                rates["JPY/USD"] = jpyRate
            }
            if let gbpRate = result.rates["GBP"] {
                rates["GBP/USD"] = gbpRate
            }
            if let cnyRate = result.rates["CNY"] {
                rates["CNY/USD"] = cnyRate
            }
            if let audRate = result.rates["AUD"] {
                rates["AUD/USD"] = audRate
            }
            if let cadRate = result.rates["CAD"] {
                rates["CAD/USD"] = cadRate
            }
            if let chfRate = result.rates["CHF"] {
                rates["CHF/USD"] = chfRate
            }
            if let hkdRate = result.rates["HKD"] {
                rates["HKD/USD"] = hkdRate
            }
            if let sgdRate = result.rates["SGD"] {
                rates["SGD/USD"] = sgdRate
            }

            print("📊 ExchangeRate-API 匯率解析結果: \(rates)")
            let timestamp = result.time_last_updated ?? Int(Date().timeIntervalSince1970)
            return rates.isEmpty ? nil : (rates, timestamp)
        } catch {
            print("❌ ExchangeRate-API 錯誤: \(error.localizedDescription)")
            return nil
        }
    }

    /// 格式化匯率更新訊息
    func formatUpdateMessage(rates: [String: Double], source: String, date: String) -> String {
        var message = "✅ 匯率更新成功\n\n"
        message += "📅 匯率日期: \(date)\n"
        message += "📡 資料來源: \(source)\n\n"
        message += "匯率資訊:\n"

        if let twdUsdRate = rates["TWD/USD"] {
            message += "💵 台幣/美金: \(String(format: "%.4f", twdUsdRate))\n"
        }

        // 其他貨幣
        let currencies = [
            ("EUR/USD", "歐元/美金"),
            ("JPY/USD", "日圓/美金"),
            ("GBP/USD", "英鎊/美金"),
            ("CNY/USD", "人民幣/美金"),
            ("AUD/USD", "澳幣/美金"),
            ("CAD/USD", "加幣/美金"),
            ("CHF/USD", "瑞士法郎/美金"),
            ("HKD/USD", "港幣/美金"),
            ("SGD/USD", "新加坡幣/美金")
        ]

        for (code, name) in currencies {
            if let rate = rates[code] {
                message += "\(name): \(String(format: "%.4f", rate))\n"
            }
        }

        return message
    }

    // MARK: - 日期格式化

    /// 格式化台灣銀行的匯率日期（當日或最近工作日）
    private func formatTaiwanBankDate() -> String {
        let calendar = Calendar.current
        let now = Date()

        // 取得今天是星期幾（1 = 週日, 2 = 週一, ..., 7 = 週六）
        let weekday = calendar.component(.weekday, from: now)

        var rateDate = now

        // 如果是週六（7）或週日（1），使用上週五的日期
        if weekday == 1 {  // 週日
            rateDate = calendar.date(byAdding: .day, value: -2, to: now) ?? now
        } else if weekday == 7 {  // 週六
            rateDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd (E)"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: rateDate)
    }

    /// 格式化 Unix 時間戳為日期字串
    private func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd (E)"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
}

// MARK: - API Response Models
struct ExchangeRateAPIResponse: Codable {
    let base: String
    let rates: [String: Double]
    let time_last_updated: Int?

    enum CodingKeys: String, CodingKey {
        case base
        case rates
        case time_last_updated = "time_last_updated"
    }
}

// MARK: - Error Types
enum ExchangeRateError: LocalizedError {
    case invalidURL
    case networkError
    case noData
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的 URL"
        case .networkError:
            return "網路請求失敗"
        case .noData:
            return "未找到匯率資料"
        case .parsingError:
            return "資料解析失敗"
        }
    }
}
