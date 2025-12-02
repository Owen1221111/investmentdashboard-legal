//
//  InsuranceTutorialView.swift
//  InvestmentDashboard
//
//  保險管理功能導覽
//

import SwiftUI

/// 保險導覽頁面模型
struct InsuranceTutorialPage: Identifiable {
    let id: Int
    let title: String
    let description: String
    let imageName: String?
    let icon: String?
}

/// 保險導覽管理器
class InsuranceTutorialManager: ObservableObject {
    @Published var isShowingTutorial = false
    private let hasSeenInsuranceTutorialKey = "hasSeenInsuranceTutorial"

    func shouldShowTutorial() -> Bool {
        return !UserDefaults.standard.bool(forKey: hasSeenInsuranceTutorialKey)
    }

    func completeTutorial() {
        UserDefaults.standard.set(true, forKey: hasSeenInsuranceTutorialKey)
        isShowingTutorial = false
    }

    func resetTutorial() {
        UserDefaults.standard.set(false, forKey: hasSeenInsuranceTutorialKey)
    }
}

/// 保險導覽主視圖
struct InsuranceTutorialView: View {
    @StateObject private var manager = InsuranceTutorialManager()
    @State private var currentPage = 0
    let onComplete: () -> Void

    private let pages: [InsuranceTutorialPage] = [
        InsuranceTutorialPage(
            id: 0,
            title: "保險管理功能介紹",
            description: "歡迎使用保單管理系統\n\n幫助您輕鬆管理客戶的\n各類保險保單",
            imageName: nil,
            icon: "shield.checkered"
        ),
        InsuranceTutorialPage(
            id: 1,
            title: "新增保單",
            description: "點擊右上角 ＋ 按鈕\n手動新增保單資料\n\n⚠️ 注意事項：\n• 繳費月份會放在提醒功能內\n• 身故受益人格式：\n  名字在前，比例在後，加逗號\n  例：tina50%，owen50%",
            imageName: nil,
            icon: "plus.circle.fill"
        ),
        InsuranceTutorialPage(
            id: 2,
            title: "保單資料移轉",
            description: "完成保單基本資訊後\n點選儲存按鈕\n\n資料會自動移轉至\n保單試算表區域",
            imageName: nil,
            icon: "arrow.right.circle.fill"
        ),
        InsuranceTutorialPage(
            id: 3,
            title: "保單試算表存放",
            description: "建議用保險公司名稱做分類\n\n請將試算表的保單現金價值（解約金）\n身故保險金用文字辨識功能直接複製\n\n💡 提示：\n直接截圖該欄位資訊\n比較好複製貼上\n\n系統會幫您計算身故保險金總額",
            imageName: nil,
            icon: "tablecells.fill"
        ),
        InsuranceTutorialPage(
            id: 4,
            title: "年齡計算與線圖",
            description: "❗ 重要提醒\n\n需要有出生年月日\n才會自動推算年齡\n\n線圖會幫忙帶出\n身故保障的加總線圖\n\n受益人輸入模式：\n名字＋比例加上逗號\n例：tina50%，owen50%",
            imageName: nil,
            icon: "chart.line.uptrend.xyaxis"
        ),
        InsuranceTutorialPage(
            id: 5,
            title: "開始管理保單",
            description: "現在您已了解\n保險管理的主要功能\n\n隨時點擊「？」按鈕\n重新查看教學說明",
            imageName: nil,
            icon: "checkmark.circle.fill"
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
                        InsuranceTutorialPageView(page: page)
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
struct InsuranceTutorialPageView: View {
    let page: InsuranceTutorialPage

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
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: {
                                if icon == "plus.circle.fill" {
                                    return [.green, .green.opacity(0.7)]
                                } else if icon == "camera.fill" {
                                    return [.orange, .orange.opacity(0.7)]
                                } else if icon == "checkmark.circle.fill" {
                                    return [.green, .green.opacity(0.7)]
                                } else if icon == "shield.checkered" {
                                    return [.purple, .purple.opacity(0.7)]
                                } else if icon == "chart.pie.fill" {
                                    return [.pink, .pink.opacity(0.7)]
                                } else if icon == "calendar.circle.fill" {
                                    return [.red, .red.opacity(0.7)]
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
    InsuranceTutorialView(onComplete: {
        print("保險導覽完成")
    })
}
