//
//  OnboardingView.swift
//  InvestmentDashboard
//
//  截圖式導覽頁面
//

import SwiftUI

/// 導覽頁面模型
struct OnboardingPage: Identifiable {
    let id: Int
    let title: String
    let description: String
    let imageName: String?  // 可選的截圖名稱
    let icon: String?       // 可選的 SF Symbol 圖標
}

/// 導覽管理器
class OnboardingManager: ObservableObject {
    @Published var isShowingOnboarding = false
    private let hasSeenOnboardingKey = "hasSeenOnboarding"

    func shouldShowOnboarding() -> Bool {
        return !UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: hasSeenOnboardingKey)
        isShowingOnboarding = false
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: hasSeenOnboardingKey)
    }
}

/// 導覽主視圖
struct OnboardingView: View {
    @StateObject private var manager = OnboardingManager()
    @State private var currentPage = 0
    let onComplete: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "歡迎使用投資儀表板",
            description: "專業的投資管理工具\n幫您輕鬆追蹤所有投資資產",
            imageName: nil,  // 第 1 頁保持圖標（歡迎畫面）
            icon: "chart.line.uptrend.xyaxis"
        ),
        OnboardingPage(
            id: 1,
            title: "開啟客戶管理",
            description: "點擊左上角的 ☰ 選單按鈕\n即可打開客戶管理面板",
            imageName: "tutorial_menu",  // ✨ 使用截圖：選單打開的畫面
            icon: nil
        ),
        OnboardingPage(
            id: 2,
            title: "新增客戶資料",
            description: "點擊綠色的 ＋ 按鈕\n新增您的第一位客戶",
            imageName: "tutorial_add_customer",  // ✨ 使用截圖：新增客戶畫面
            icon: nil
        ),
        OnboardingPage(
            id: 3,
            title: "管理投資組合",
            description: "選擇客戶後，可以管理：\n• 月度資產明細\n• 公司債投資\n• 結構型商品\n• 美股投資\n• 損益表",
            imageName: "tutorial_dashboard",  // ✨ 使用截圖：客戶管理主畫面
            icon: nil
        ),
        OnboardingPage(
            id: 4,
            title: "隱私與資料安全",
            description: "您的資料儲存位置：\n\n• 本地：儲存在您的裝置上\n• 雲端：同步至您的 iCloud 帳戶\n• 加密：受 iOS 和 iCloud 加密保護\n\n我們不會將您的資料\n傳輸到開發者的伺服器!!!",
            imageName: nil,  // 隱私頁面保持圖標
            icon: "lock.shield.fill"
        ),
        OnboardingPage(
            id: 5,
            title: "重要提醒！",
            description: "點擊客戶後，您可以管理投資、保單\n\n各項頁面中的「？」按鈕\n會教您如何使用該功能",
            imageName: nil,  // 提醒頁面保持圖標
            icon: "exclamationmark.circle.fill"
        )
    ]

    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 頂部跳過按鈕
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage = pages.count - 1
                            }
                        }) {
                            Text("跳過")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .padding()
                        }
                    }
                }

                // 內容區域
                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        OnboardingPageView(page: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // 底部控制區
                VStack(spacing: 20) {
                    // 頁面指示器
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: currentPage)
                        }
                    }

                    // 下一步/完成按鈕
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            manager.completeOnboarding()
                            onComplete()
                        }
                    }) {
                        HStack {
                            Text(currentPage == pages.count - 1 ? "開始使用" : "下一步")
                                .font(.system(size: 18, weight: .semibold))

                            if currentPage < pages.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

/// 單頁視圖
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // 圖標或截圖
            if let imageName = page.imageName {
                // 使用截圖（之後可以添加）
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(20)
                    .shadow(radius: 20)
            } else if let icon = page.icon {
                // 使用 SF Symbol 圖標
                Image(systemName: icon)
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: {
                                if icon == "plus.circle.fill" {
                                    return [.green, .green.opacity(0.7)]
                                } else if icon == "exclamationmark.circle.fill" {
                                    return [.red, .red.opacity(0.7)]
                                } else if icon == "lock.shield.fill" {
                                    return [.purple, .purple.opacity(0.7)]
                                } else {
                                    return [.blue, .cyan]
                                }
                            }(),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }

            // 標題
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // 說明文字
            Text(page.description)
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(onComplete: {
        print("導覽完成")
    })
}
