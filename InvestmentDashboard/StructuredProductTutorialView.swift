//
//  StructuredProductTutorialView.swift
//  InvestmentDashboard
//
//  結構型商品功能教學
//

import SwiftUI

/// 結構型商品教學頁面模型
struct StructuredProductTutorialPage: Identifiable {
    let id: Int
    let title: String
    let description: String
    let imageName: String?
    let icon: String?
}

/// 結構型商品教學管理器
class StructuredProductTutorialManager: ObservableObject {
    @Published var isShowingTutorial = false
    private let hasSeenStructuredProductTutorialKey = "hasSeenStructuredProductTutorial"

    func shouldShowTutorial() -> Bool {
        return !UserDefaults.standard.bool(forKey: hasSeenStructuredProductTutorialKey)
    }

    func completeTutorial() {
        UserDefaults.standard.set(true, forKey: hasSeenStructuredProductTutorialKey)
        isShowingTutorial = false
    }

    func resetTutorial() {
        UserDefaults.standard.set(false, forKey: hasSeenStructuredProductTutorialKey)
    }
}

/// 結構型商品教學主視圖
struct StructuredProductTutorialView: View {
    @StateObject private var manager = StructuredProductTutorialManager()
    @State private var currentPage = 0
    let onComplete: () -> Void

    private let pages: [StructuredProductTutorialPage] = [
        StructuredProductTutorialPage(
            id: 0,
            title: "結構型商品教學",
            description: "接下來為您介紹\n結構型商品的管理功能\n\n幫助您追蹤進行中的商品\n並管理已出場的紀錄",
            imageName: nil,
            icon: "chart.bar.doc.horizontal"
        ),
        StructuredProductTutorialPage(
            id: 1,
            title: "步驟 1：新增結構型商品",
            description: "在結構型明細中\n點選右上角的 ＋ 按鈕\n\n開始新增一筆結構型商品",
            imageName: "tutorial_structured_1",
            icon: nil
        ),
        StructuredProductTutorialPage(
            id: 2,
            title: "步驟 2：選擇標的數量",
            description: "選擇此結構型商品\n連結幾組標的\n\n支援 1 至 4 個標的",
            imageName: "tutorial_structured_2",
            icon: nil
        ),
        StructuredProductTutorialPage(
            id: 3,
            title: "步驟 3：輸入商品資訊",
            description: "輸入商品基本訊息：\n\n• 起單日（交易定價日）\n• 利率\n• 期初價格\n• 執行價格",
            imageName: "tutorial_structured_3",
            icon: nil
        ),
        StructuredProductTutorialPage(
            id: 4,
            title: "步驟 4：更新股價",
            description: "點選綠色更新按鈕\n\n系統會自動抓取最新股價\n並計算距離出場 %\n\n距離出場 = 現價 ÷ 期初價",
            imageName: "tutorial_structured_4",
            icon: nil
        ),
        StructuredProductTutorialPage(
            id: 5,
            title: "步驟 5：商品出場",
            description: "當產品結束時\n點選最右手邊的出場按鈕\n\n新增分類（建議使用年度分類）\n例如：2024、2025",
            imageName: "tutorial_structured_5",
            icon: nil
        ),
        StructuredProductTutorialPage(
            id: 6,
            title: "步驟 6：選擇分類",
            description: "選擇要將此商品\n歸檔到哪個分類\n\n可以選擇現有分類\n或新增分類",
            imageName: "tutorial_structured_6",
            icon: nil
        ),
        StructuredProductTutorialPage(
            id: 7,
            title: "步驟 7：管理已出場商品",
            description: "已出場產品會移至\n「結構型已出場」區域\n\n在這裡只需要\n輸入實際收益即可",
            imageName: "tutorial_structured_7",
            icon: nil
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
                        StructuredProductTutorialPageView(page: page)
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
                                .fill(currentPage == index ? Color.green : Color.gray.opacity(0.3))
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
                                colors: [Color.green, Color.green.opacity(0.8)],
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
struct StructuredProductTutorialPageView: View {
    let page: StructuredProductTutorialPage

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
                            colors: [.green, .green.opacity(0.7)],
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
    StructuredProductTutorialView(onComplete: {
        print("結構型商品教學完成")
    })
}
