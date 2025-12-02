//
//  SubscriptionView.swift
//  InvestmentDashboard
//
//  Created by Owen Liu on 2025/11/4.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 頂部圖示和標題
                    headerSection

                    // 訂閱狀態卡片
                    if subscriptionManager.isSubscriptionActive {
                        subscriptionStatusCard
                    }

                    // 訂閱方案
                    if !subscriptionManager.isSubscriptionActive {
                        subscriptionPlanCard
                    }

                    // 按鈕區域
                    if !subscriptionManager.isSubscriptionActive {
                        purchaseButton
                    }

                    restorePurchaseButton

                    // 法律條款連結
                    legalLinksSection

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("訂閱方案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        // 標記用戶已經看過訂閱提示（即使沒有訂閱）
                        subscriptionManager.markSubscriptionPromptAsSeen()
                        dismiss()
                    }
                }
            }
            .alert("錯誤", isPresented: $showingError) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("訂閱方案")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding(.top, 20)
    }

    // MARK: - Subscription Status Card

    private var subscriptionStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriptionManager.subscriptionStatus == .inTrialPeriod ? "試用期中" : "已訂閱")
                        .font(.headline)
                        .foregroundColor(.primary)

                    if subscriptionManager.subscriptionStatus == .inTrialPeriod,
                       let days = subscriptionManager.remainingTrialDays() {
                        Text("試用期還剩 \(days) 天")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("感謝您的支持")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Subscription Plan Card

    private var subscriptionPlanCard: some View {
        VStack(spacing: 16) {
            // 標題
            VStack(spacing: 8) {
                Text("月費方案")
                    .font(.headline)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("NT$")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("100")
                        .font(.system(size: 48, weight: .bold))
                    Text("/ 月")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // 試用期說明
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.orange)
                    Text("首月免費試用")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }

                Text("• 試用 30 天後才開始收費\n• 試用期間隨時可在設定中取消\n• 取消後仍可使用至試用期結束")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
                .padding(.vertical, 8)

            // 開發者說明
            VStack(spacing: 6) {
                Text("此 App 是個人研發製作")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("因本身是金融從業人員，為了自己記錄方便開發此 App")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 4) {
                    Text("如有操作上需要優化請 Email：")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Link("stockbankapp@gmail.com", destination: URL(string: "mailto:stockbankapp@gmail.com")!)
                        .font(.caption2)
                        .foregroundColor(.blue)

                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button(action: {
            Task {
                await handlePurchase()
            }
        }) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("開始免費試用")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(isPurchasing)
    }

    // MARK: - Restore Purchase Button

    private var restorePurchaseButton: some View {
        Button(action: {
            Task {
                await handleRestore()
            }
        }) {
            Text("恢復購買")
                .font(.subheadline)
                .foregroundColor(.blue)
        }
    }

    // MARK: - Legal Links Section

    private var legalLinksSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Link("隱私權政策", destination: URL(string: "https://owen1221111.github.io/investmentdashboard-legal/privacy-zh.html")!)
                    .font(.caption)
                    .foregroundColor(.blue)

                Text("•")
                    .foregroundColor(.secondary)

                Link("使用條款", destination: URL(string: "https://owen1221111.github.io/investmentdashboard-legal/terms-zh.html")!)
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            Text("付款將從您的 Apple ID 帳戶收取")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func handlePurchase() async {
        isPurchasing = true

        do {
            try await subscriptionManager.purchase()
            // 標記用戶已經看過訂閱提示
            subscriptionManager.markSubscriptionPromptAsSeen()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isPurchasing = false
    }

    private func handleRestore() async {
        do {
            try await subscriptionManager.restorePurchases()

            if subscriptionManager.isSubscriptionActive {
                dismiss()
            } else {
                errorMessage = "沒有找到可恢復的訂閱"
                showingError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Preview

#Preview {
    SubscriptionView()
}
