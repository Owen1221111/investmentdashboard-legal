//
//  TooltipOverlayView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/30.
//  提示引導的浮層 UI 元件
//

import SwiftUI

/// 提示浮層視圖
struct TooltipOverlayView: View {
    let step: TooltipStep
    let currentStep: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // 更暗的背景遮罩（模擬舞台暗場）
            Color.black.opacity(0.88)
                .ignoresSafeArea()

            // 聚光燈效果
            if let targetFrame = step.targetFrame {
                SpotlightEffect(
                    targetFrame: targetFrame,
                    pulseAnimation: pulseAnimation
                )
            }

            // 提示卡片
            tooltipCard
                .position(cardPosition)
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }

    // MARK: - 提示卡片
    private var tooltipCard: some View {
        VStack(spacing: 16) {
            // 步驟指示器
            HStack {
                Text("\(currentStep)/\(totalSteps)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)

                Spacer()

                Button(action: onSkip) {
                    Text("跳過")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }

            // 標題
            Text(step.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // 說明內容
            Text(step.message)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // 按鈕
            Button(action: onNext) {
                HStack {
                    Text(currentStep == totalSteps ? "完成" : "下一步")
                        .font(.system(size: 16, weight: .semibold))

                    if currentStep != totalSteps {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
    }

    // MARK: - 卡片位置計算
    private var cardPosition: CGPoint {
        guard let screenSize = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.bounds.size else {
            return CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        }

        guard let targetFrame = step.targetFrame else {
            // 沒有目標區域時，顯示在畫面中央
            return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        }

        let cardHeight: CGFloat = 250  // 預估卡片高度
        let padding: CGFloat = 40

        switch step.position {
        case .top:
            // 顯示在目標區域上方
            return CGPoint(
                x: screenSize.width / 2,
                y: targetFrame.minY - cardHeight / 2 - padding
            )
        case .bottom:
            // 顯示在目標區域下方
            return CGPoint(
                x: screenSize.width / 2,
                y: targetFrame.maxY + cardHeight / 2 + padding
            )
        case .center:
            // 顯示在畫面中央
            return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        case .leading:
            return CGPoint(
                x: screenSize.width / 4,
                y: targetFrame.midY
            )
        case .trailing:
            return CGPoint(
                x: screenSize.width * 3 / 4,
                y: targetFrame.midY
            )
        }
    }
}

// MARK: - 聚光燈效果
struct SpotlightEffect: View {
    let targetFrame: CGRect
    let pulseAnimation: Bool

    var body: some View {
        ZStack {
            // 主要聚光區域
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.15),  // 中心較亮
                            Color.white.opacity(0.08),  // 中間
                            Color.clear                  // 邊緣透明
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: max(targetFrame.width, targetFrame.height) * 0.9
                    )
                )
                .frame(width: targetFrame.width + 40, height: targetFrame.height + 40)
                .position(x: targetFrame.midX, y: targetFrame.midY)

            // 內層光暈（呼吸效果）
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(pulseAnimation ? 0.3 : 0.2),
                            Color.yellow.opacity(pulseAnimation ? 0.15 : 0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: max(targetFrame.width, targetFrame.height) * 0.7
                    )
                )
                .frame(
                    width: targetFrame.width + (pulseAnimation ? 35 : 30),
                    height: targetFrame.height + (pulseAnimation ? 35 : 30)
                )
                .position(x: targetFrame.midX, y: targetFrame.midY)
                .blur(radius: 6)

            // 核心高亮邊框
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.yellow.opacity(0.7),
                            Color.white.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: targetFrame.width + 12, height: targetFrame.height + 12)
                .position(x: targetFrame.midX, y: targetFrame.midY)
                .shadow(
                    color: Color.yellow.opacity(pulseAnimation ? 0.7 : 0.4),
                    radius: pulseAnimation ? 20 : 12
                )

            // 外層光暈擴散
            RoundedRectangle(cornerRadius: 26)
                .stroke(
                    Color.white.opacity(pulseAnimation ? 0.2 : 0.1),
                    lineWidth: 2
                )
                .frame(
                    width: targetFrame.width + (pulseAnimation ? 60 : 50),
                    height: targetFrame.height + (pulseAnimation ? 60 : 50)
                )
                .position(x: targetFrame.midX, y: targetFrame.midY)
                .blur(radius: 5)
        }
    }
}

// MARK: - Preview
#Preview {
    TooltipOverlayView(
        step: TooltipStep(
            id: 1,
            title: "歡迎使用",
            message: "這是一個引導提示的範例",
            targetFrame: CGRect(x: 100, y: 100, width: 200, height: 50),
            position: .bottom
        ),
        currentStep: 1,
        totalSteps: 6,
        onNext: {},
        onSkip: {}
    )
}
