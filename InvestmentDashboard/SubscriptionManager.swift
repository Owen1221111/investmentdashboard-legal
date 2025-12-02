//
//  SubscriptionManager.swift
//  InvestmentDashboard
//
//  Created by Owen Liu on 2025/11/4.
//

import Foundation
import StoreKit

/// 訂閱狀態
enum SubscriptionStatus {
    case notSubscribed      // 未訂閱
    case inTrialPeriod      // 試用期中
    case subscribed         // 已訂閱
    case expired            // 已過期
}

/// 訂閱管理器 - 使用 StoreKit 2
@MainActor
class SubscriptionManager: ObservableObject {

    // MARK: - Published Properties

    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var isSubscriptionActive: Bool = false
    @Published var trialEndDate: Date?
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var hasSeenSubscriptionPrompt: Bool = false

    // MARK: - Properties

    /// 訂閱產品 ID（需要在 App Store Connect 和 StoreKit Configuration 中設定）
    private let subscriptionProductID = "com.owenliu.investmentdashboard.monthly"

    private var updateListenerTask: Task<Void, Error>?

    /// UserDefaults 鍵值
    private let hasSeenPromptKey = "hasSeenSubscriptionPrompt"

    // MARK: - Singleton

    static let shared = SubscriptionManager()

    private init() {
        // 讀取是否已經看過訂閱提示
        self.hasSeenSubscriptionPrompt = UserDefaults.standard.bool(forKey: hasSeenPromptKey)

        // 啟動交易監聽器
        updateListenerTask = listenForTransactions()

        // 載入產品和訂閱狀態
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    /// 購買訂閱
    func purchase() async throws {
        guard let product = products.first else {
            throw SubscriptionError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // 驗證交易
            let transaction = try Self.checkVerified(verification)

            // 更新訂閱狀態
            await updateSubscriptionStatus()

            // 完成交易
            await transaction.finish()

        case .userCancelled:
            throw SubscriptionError.userCancelled

        case .pending:
            throw SubscriptionError.purchasePending

        @unknown default:
            throw SubscriptionError.unknown
        }
    }

    /// 恢復購買
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }

    /// 檢查訂閱狀態
    func checkSubscriptionStatus() async {
        await updateSubscriptionStatus()
    }

    /// 取得試用期剩餘天數
    func remainingTrialDays() -> Int? {
        guard let trialEndDate = trialEndDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: trialEndDate).day
        return days
    }

    /// 是否可以使用所有功能（試用期或已訂閱）
    func canAccessPremiumFeatures() -> Bool {
        return isSubscriptionActive
    }

    /// 檢查是否需要顯示訂閱提示（首次打開 App）
    func shouldShowSubscriptionPrompt() -> Bool {
        // 如果已經訂閱或在試用期，不顯示
        if isSubscriptionActive {
            return false
        }

        // 如果已經看過提示，不再顯示
        if hasSeenSubscriptionPrompt {
            return false
        }

        return true
    }

    /// 標記用戶已經看過訂閱提示
    func markSubscriptionPromptAsSeen() {
        hasSeenSubscriptionPrompt = true
        UserDefaults.standard.set(true, forKey: hasSeenPromptKey)
        print("✅ 已標記用戶看過訂閱提示")
    }

    // MARK: - Private Methods

    /// 載入產品資訊
    private func loadProducts() async {
        do {
            let products = try await Product.products(for: [subscriptionProductID])
            self.products = products
            print("✅ 已載入訂閱產品: \(products.map { $0.displayName })")
        } catch {
            print("❌ 載入產品失敗: \(error)")
        }
    }

    /// 更新訂閱狀態
    private func updateSubscriptionStatus() async {
        var activeSubscription: Product?
        var isInTrialPeriod = false
        var trialEnd: Date?

        // 檢查所有活躍的自動續訂訂閱
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try Self.checkVerified(result)

                // 檢查是否為我們的訂閱產品
                if transaction.productID == subscriptionProductID {
                    // 檢查是否在試用期
                    if let introductoryOffer = transaction.offerType {
                        if introductoryOffer == .introductory {
                            isInTrialPeriod = true
                        }
                    }

                    // 獲取訂閱到期日
                    if let expirationDate = transaction.expirationDate {
                        trialEnd = expirationDate
                    }

                    // 查找對應的產品
                    if let product = products.first(where: { $0.id == transaction.productID }) {
                        activeSubscription = product
                    }
                }
            } catch {
                print("❌ 驗證交易失敗: \(error)")
            }
        }

        // 更新訂閱狀態
        if let _ = activeSubscription {
            if isInTrialPeriod {
                self.subscriptionStatus = .inTrialPeriod
                self.trialEndDate = trialEnd
                print("📱 用戶處於試用期，到期日：\(trialEnd?.description ?? "未知")")
            } else {
                self.subscriptionStatus = .subscribed
                print("✅ 用戶已訂閱")
            }
            self.isSubscriptionActive = true
        } else {
            self.subscriptionStatus = .notSubscribed
            self.isSubscriptionActive = false
            self.trialEndDate = nil
            print("⚠️ 用戶未訂閱")
        }
    }

    /// 監聽交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)

                    // 更新訂閱狀態
                    await self.updateSubscriptionStatus()

                    // 完成交易
                    await transaction.finish()
                } catch {
                    print("❌ 交易更新失敗: \(error)")
                }
            }
        }
    }

    /// 驗證交易簽名（不受 MainActor 隔離）
    nonisolated private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case productNotFound
    case userCancelled
    case purchasePending
    case failedVerification
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "找不到訂閱產品"
        case .userCancelled:
            return "用戶取消購買"
        case .purchasePending:
            return "購買待處理"
        case .failedVerification:
            return "交易驗證失敗"
        case .unknown:
            return "未知錯誤"
        }
    }
}
