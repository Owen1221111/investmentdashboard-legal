//
//  WhatsNewView.swift
//  InvestmentDashboard
//
//  版本更新功能介紹頁面
//

import SwiftUI

// MARK: - 版本管理器

class AppVersionManager: ObservableObject {
    static let shared = AppVersionManager()

    private let lastVersionKey = "LastAppVersion"
    private let hasSeenWhatsNewKey = "HasSeenWhatsNew_"

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var lastVersion: String {
        UserDefaults.standard.string(forKey: lastVersionKey) ?? ""
    }

    // 檢查是否需要顯示新功能介紹
    func shouldShowWhatsNew() -> Bool {
        let lastVer = lastVersion
        let currentVer = currentVersion

        // 首次安裝（沒有記錄過版本）
        if lastVer.isEmpty {
            return true
        }

        // 版本號變更
        if lastVer != currentVer {
            return true
        }

        return false
    }

    // 標記已查看新功能介紹
    func markWhatsNewAsSeen() {
        UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
        UserDefaults.standard.set(true, forKey: hasSeenWhatsNewKey + currentVersion)
    }

    // 重置（用於測試）
    func resetWhatsNew() {
        UserDefaults.standard.removeObject(forKey: lastVersionKey)
        UserDefaults.standard.removeObject(forKey: hasSeenWhatsNewKey + currentVersion)
    }
}

// MARK: - 新功能項目

struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let image: String? // 可選的截圖
}

// MARK: - 新功能介紹頁面

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var versionManager = AppVersionManager.shared

    // 當前版本的新功能列表（可根據版本動態調整）
    private var features: [WhatsNewFeature] {
        [
            WhatsNewFeature(
                icon: "slider.horizontal.3",
                iconColor: .blue,
                title: "左滑輸入區強化升級",
                description: "快速輸入各項目現值，支援多國匯率自動換算債券與結構型商品現值，簡易更新台美股股價並自動換算現值",
                image: "whats_new_left_swipe"
            ),
            WhatsNewFeature(
                icon: "circle.grid.3x3.fill",
                iconColor: .green,
                title: "浮動按鈕批量操作",
                description: "快速輸入多客戶 FCN 進場資訊，支援多幣別辨識，一鍵出場多筆 FCN 並提供建議試算",
                image: "whats_new_floating_menu"
            ),
            WhatsNewFeature(
                icon: "dollarsign.circle.fill",
                iconColor: .blue,
                title: "美股/台股批量新增",
                description: "一次為多個客戶添加相同股票，兩步驟快速完成，自動計算成本和初始市值",
                image: nil
            ),
            WhatsNewFeature(
                icon: "doc.text.fill",
                iconColor: Color(red: 0xC4/255.0, green: 0x45/255.0, blue: 0x36/255.0),
                title: "債券批量新增",
                description: "支援 11 種貨幣的債券批量添加，彈性金額輸入，自動計算報酬率",
                image: nil
            ),
            WhatsNewFeature(
                icon: "xmark.circle.fill",
                iconColor: .red,
                title: "可選項目移除功能",
                description: "定期定額、基金、保險項目現在可以自由移除，不再擔心誤加無法刪除",
                image: nil
            )
        ]
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 頂部標題區域
                    VStack(spacing: 12) {
                        // App 圖示（可選）
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 40)

                        Text("InvestmentDashboard")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Text("版本 \(versionManager.currentVersion)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("全新功能，更多便捷操作")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // 功能列表
                    VStack(spacing: 20) {
                        ForEach(features) { feature in
                            FeatureCard(feature: feature)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // 底部按鈕
                    Button(action: {
                        versionManager.markWhatsNewAsSeen()
                        dismiss()
                    }) {
                        Text("開始使用")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - 功能卡片

struct FeatureCard: View {
    let feature: WhatsNewFeature

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 如果有圖片，顯示圖片；否則顯示圖示
            if let imageName = feature.image {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
            } else {
                HStack(spacing: 16) {
                    // 圖示
                    Image(systemName: feature.icon)
                        .font(.system(size: 32))
                        .foregroundColor(feature.iconColor)
                        .frame(width: 60, height: 60)
                        .background(feature.iconColor.opacity(0.1))
                        .cornerRadius(12)

                    Spacer()
                }
            }

            // 文字內容
            VStack(alignment: .leading, spacing: 6) {
                Text(feature.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Text(feature.description)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    WhatsNewView()
}
