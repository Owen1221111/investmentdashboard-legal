//
//  DashboardTutorialView.swift
//  InvestmentDashboard
//
//  投資儀表板功能導覽
//

import SwiftUI

/// 儀表板導覽頁面模型
struct DashboardTutorialPage: Identifiable {
    let id: Int
    let title: String
    let description: String
    let imageName: String?
    let icon: String?
}

/// 儀表板導覽管理器
class DashboardTutorialManager: ObservableObject {
    @Published var isShowingTutorial = false
    private let hasSeenDashboardTutorialKey = "hasSeenDashboardTutorial"

    func shouldShowTutorial() -> Bool {
        return !UserDefaults.standard.bool(forKey: hasSeenDashboardTutorialKey)
    }

    func completeTutorial() {
        UserDefaults.standard.set(true, forKey: hasSeenDashboardTutorialKey)
        isShowingTutorial = false
    }

    func resetTutorial() {
        UserDefaults.standard.set(false, forKey: hasSeenDashboardTutorialKey)
    }
}

/// 儀表板導覽主視圖
struct DashboardTutorialView: View {
    @StateObject private var manager = DashboardTutorialManager()
    @State private var currentPage = 0
    let onComplete: () -> Void

    private let pages: [DashboardTutorialPage] = [
        DashboardTutorialPage(
            id: 0,
            title: "投資儀表板功能介紹",
            description: "接下來為您介紹\n投資儀表板的核心功能\n\n幫助您更有效地管理客戶投資",
            imageName: nil,
            icon: "chart.line.uptrend.xyaxis"
        ),
        DashboardTutorialPage(
            id: 1,
            title: "步驟 1：新增月度資產",
            description: "點擊右上角 ＋ 按鈕\n\n每次與客戶碰面前\n先輸入當前狀況\n\n建立長期追蹤紀錄",
            imageName: "tutorial_dashboard_1",
            icon: nil
        ),
        DashboardTutorialPage(
            id: 2,
            title: "步驟 2：輸入資產資料",
            description: "輸入的資料會記錄在\n月度資產明細表格中\n\n⚠️ 重要：月度資產是投資項目的總額\n（例如：美股的總額）\n如需記錄各項明細\n請點擊下方卡片進入更新",
            imageName: "tutorial_dashboard_2",
            icon: nil
        ),
        DashboardTutorialPage(
            id: 3,
            title: "步驟 3：查看投資卡片",
            description: "儀表板顯示各類投資的\n現值與報酬率\n\n總損益 = 總資產 − 匯入累積\n（匯入累積 = 投入成本）",
            imageName: "tutorial_dashboard_3",
            icon: nil
        ),
        DashboardTutorialPage(
            id: 4,
            title: "步驟 4：更新股價並同步",
            description: "美股／台股卡片中\n可自動更新股價\n\n⚠️ 務必輸入正確的股票代號\n\n更新後可同步到月度資產",
            imageName: "tutorial_dashboard_4",
            icon: nil
        ),
        DashboardTutorialPage(
            id: 5,
            title: "重要公式說明",
            description: "總額報酬率 = 總資產 − 總匯入\n現金 = 台幣 ＋ 美金\n\n美股報酬率 =\n（美股 − 美股成本）÷ 美股成本\n\n台股報酬率 =\n（台股 − 台股成本）÷ 台股成本\n\n債券報酬率 =\n（債券 − 債券成本 ＋ 已領利息）÷ 債券成本",
            imageName: nil,
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
                        DashboardTutorialPageView(page: page)
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
                            manager.completeTutorial()
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
struct DashboardTutorialPageView: View {
    let page: DashboardTutorialPage
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // 圖標或截圖
            if let imageName = page.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(20)
                    .shadow(radius: 20)
            } else if let icon = page.icon {
                // 使用 SF Symbol 圖標
                Image(systemName: icon)
                    .font(.system(size: horizontalSizeClass == .compact ? 60 : 80, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: {
                                if icon == "plus.circle.fill" || icon == "dollarsign.circle.fill" {
                                    return [.green, .green.opacity(0.7)]
                                } else if icon == "exclamationmark.circle.fill" {
                                    return [.red, .red.opacity(0.7)]
                                } else if icon == "arrow.right.circle.fill" {
                                    return [.orange, .orange.opacity(0.7)]
                                } else if icon == "arrow.triangle.2.circlepath.circle.fill" {
                                    return [.purple, .purple.opacity(0.7)]
                                } else if icon == "folder.fill" {
                                    return [.yellow, .yellow.opacity(0.7)]
                                } else {
                                    return [.blue, .cyan]
                                }
                            }(),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(horizontalSizeClass == .compact ? 30 : 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }

            // 標題
            Text(page.title)
                .font(.system(size: horizontalSizeClass == .compact ? 24 : 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // 說明文字
            Text(page.description)
                .font(.system(size: horizontalSizeClass == .compact ? 14 : 17))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(horizontalSizeClass == .compact ? 4 : 6)
                .padding(.horizontal, horizontalSizeClass == .compact ? 24 : 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview {
    DashboardTutorialView(onComplete: {
        print("儀表板導覽完成")
    })
}
