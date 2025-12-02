import Foundation

// Yahoo Finance API 服务
class StockPriceService {
    static let shared = StockPriceService()

    // 使用自定義 URLSession 配置，避免共享實例的請求衝突
    private let urlSession: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.urlSession = URLSession(configuration: config)
    }

    /// 获取单个股票的现价
    /// - Parameter symbol: 股票代码（如：AAPL, TSLA）
    /// - Returns: 股票现价（String格式）
    func fetchStockPrice(symbol: String) async throws -> String {
        // 清理股票代码（去除空格、转大写）
        let cleanSymbol = symbol.trimmingCharacters(in: .whitespaces).uppercased()

        guard !cleanSymbol.isEmpty else {
            throw StockPriceError.invalidSymbol
        }

        // Yahoo Finance API URL
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(cleanSymbol)?interval=1d&range=1d"

        guard let url = URL(string: urlString) else {
            throw StockPriceError.invalidURL
        }

        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StockPriceError.networkError
        }

        // 解析 JSON
        let decoder = JSONDecoder()
        let result = try decoder.decode(YahooFinanceResponse.self, from: data)

        guard let chart = result.chart.result.first,
              let regularMarketPrice = chart.meta.regularMarketPrice else {
            throw StockPriceError.noData
        }

        // 返回现价（保留2位小数）
        return String(format: "%.2f", regularMarketPrice)
    }

    /// 批量获取多个股票的现价
    /// - Parameter symbols: 股票代码数组
    /// - Returns: 字典，键为股票代码，值为现价
    func fetchMultipleStockPrices(symbols: [String]) async -> [String: String] {
        var results: [String: String] = [:]

        // 并发获取所有股票价格
        await withTaskGroup(of: (String, String?).self) { group in
            for symbol in symbols {
                group.addTask {
                    do {
                        let price = try await self.fetchStockPrice(symbol: symbol)
                        return (symbol, price)
                    } catch {
                        print("❌ 获取 \(symbol) 价格失败: \(error.localizedDescription)")
                        return (symbol, nil)
                    }
                }
            }

            for await (symbol, price) in group {
                if let price = price {
                    results[symbol] = price
                }
            }
        }

        return results
    }

    /// 獲取開盤價或收盤價
    /// - Parameters:
    ///   - symbol: 股票代碼
    ///   - useClosingPrice: true = 收盤價, false = 開盤價
    ///   - dayOffset: 0 = 前一天, 1 = 前兩天
    /// - Returns: 價格字串
    func fetchStockPriceWithType(symbol: String, useClosingPrice: Bool, dayOffset: Int = 0) async throws -> String {
        let cleanSymbol = symbol.trimmingCharacters(in: .whitespaces).uppercased()

        guard !cleanSymbol.isEmpty else {
            throw StockPriceError.invalidSymbol
        }

        // 獲取歷史數據
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(cleanSymbol)?interval=1d&range=5d"

        guard let url = URL(string: urlString) else {
            throw StockPriceError.invalidURL
        }

        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StockPriceError.networkError
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(YahooFinanceResponseWithIndicators.self, from: data)

        guard let chart = result.chart.result.first,
              let quote = chart.indicators.quote.first else {
            throw StockPriceError.noData
        }

        // 根據 dayOffset 計算索引：0 = 前一天 (count-1), 1 = 前兩天 (count-2)
        let index = max(0, (quote.open?.count ?? 1) - 1 - dayOffset)

        if useClosingPrice {
            if let closes = quote.close, index < closes.count, let price = closes[index] {
                return String(format: "%.2f", price)
            }
        } else {
            if let opens = quote.open, index < opens.count, let price = opens[index] {
                return String(format: "%.2f", price)
            }
        }

        // 如果沒有歷史數據，回傳現價
        if let regularMarketPrice = chart.meta.regularMarketPrice {
            return String(format: "%.2f", regularMarketPrice)
        }

        throw StockPriceError.noData
    }

    /// 批量獲取開盤價或收盤價
    /// - Parameters:
    ///   - symbols: 股票代碼數組
    ///   - useClosingPrice: true = 收盤價, false = 開盤價
    ///   - dayOffset: 0 = 前一天, 1 = 前兩天
    /// - Returns: 字典，鍵為股票代碼，值為價格
    func fetchMultipleStockPricesWithType(symbols: [String], useClosingPrice: Bool, dayOffset: Int = 0) async -> [String: String] {
        var results: [String: String] = [:]

        await withTaskGroup(of: (String, String?).self) { group in
            for symbol in symbols {
                group.addTask {
                    do {
                        let price = try await self.fetchStockPriceWithType(symbol: symbol, useClosingPrice: useClosingPrice, dayOffset: dayOffset)
                        return (symbol, price)
                    } catch {
                        print("❌ 獲取 \(symbol) 價格失敗: \(error.localizedDescription)")
                        return (symbol, nil)
                    }
                }
            }

            for await (symbol, price) in group {
                if let price = price {
                    results[symbol] = price
                }
            }
        }

        return results
    }

    /// 获取股票完整信息（价格、名称和市场时间）
    /// - Parameter symbol: 股票代码
    /// - Returns: 包含价格、名称和市场时间的元组
    func fetchStockInfo(symbol: String) async throws -> (price: String, name: String, marketTime: Date?) {
        let cleanSymbol = symbol.trimmingCharacters(in: .whitespaces).uppercased()

        guard !cleanSymbol.isEmpty else {
            throw StockPriceError.invalidSymbol
        }

        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(cleanSymbol)?interval=1d&range=1d"

        guard let url = URL(string: urlString) else {
            throw StockPriceError.invalidURL
        }

        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StockPriceError.networkError
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(YahooFinanceResponse.self, from: data)

        guard let chart = result.chart.result.first,
              let regularMarketPrice = chart.meta.regularMarketPrice else {
            throw StockPriceError.noData
        }

        let price = String(format: "%.2f", regularMarketPrice)

        // 優先使用 longName，如果沒有則使用 shortName，都沒有則使用代號
        let name = chart.meta.longName ?? chart.meta.shortName ?? cleanSymbol

        // 轉換 Unix timestamp 為 Date
        var marketTime: Date? = nil
        if let timestamp = chart.meta.regularMarketTime {
            marketTime = Date(timeIntervalSince1970: TimeInterval(timestamp))
        }

        return (price, name, marketTime)
    }

    /// 批量获取多个股票的完整信息
    /// - Parameter symbols: 股票代码数组
    /// - Returns: 字典，键为股票代码，值为 (价格, 名称, 市场时间) 元组
    func fetchMultipleStockInfos(symbols: [String]) async -> [String: (price: String, name: String, marketTime: Date?)] {
        var results: [String: (price: String, name: String, marketTime: Date?)] = [:]

        await withTaskGroup(of: (String, (String, String, Date?)?).self) { group in
            for symbol in symbols {
                group.addTask {
                    do {
                        let info = try await self.fetchStockInfo(symbol: symbol)
                        return (symbol, info)
                    } catch {
                        print("❌ 获取 \(symbol) 信息失败: \(error.localizedDescription)")
                        return (symbol, nil)
                    }
                }
            }

            for await (symbol, info) in group {
                if let info = info {
                    results[symbol] = info
                }
            }
        }

        return results
    }
}

// MARK: - Error Types
enum StockPriceError: LocalizedError {
    case invalidSymbol
    case invalidURL
    case networkError
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidSymbol:
            return "无效的股票代码"
        case .invalidURL:
            return "无效的 URL"
        case .networkError:
            return "网络请求失败"
        case .noData:
            return "未找到股票数据"
        }
    }
}

// MARK: - Yahoo Finance Response Models
struct YahooFinanceResponse: Codable {
    let chart: Chart
}

struct Chart: Codable {
    let result: [ChartResult]
}

struct ChartResult: Codable {
    let meta: Meta
}

struct Meta: Codable {
    let regularMarketPrice: Double?
    let regularMarketTime: Int?
    let symbol: String?
    let longName: String?
    let shortName: String?
}

// MARK: - Yahoo Finance Response With Indicators (for OHLC data)
struct YahooFinanceResponseWithIndicators: Codable {
    let chart: ChartWithIndicators
}

struct ChartWithIndicators: Codable {
    let result: [ChartResultWithIndicators]
}

struct ChartResultWithIndicators: Codable {
    let meta: Meta
    let indicators: Indicators
}

struct Indicators: Codable {
    let quote: [Quote]
}

struct Quote: Codable {
    let open: [Double?]?
    let high: [Double?]?
    let low: [Double?]?
    let close: [Double?]?
    let volume: [Int?]?
}
