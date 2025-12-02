//
//  TooltipManager.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/30.
//  管理提示引導的流程和狀態
//

import SwiftUI

/// 提示管理器
class TooltipManager: ObservableObject {
    @Published var isShowingTooltip = false
    @Published var currentStepIndex = 0
    @Published var steps: [TooltipStep] = []

    private let hasSeenTooltipKey = "hasSeenWelcomeTooltip"

    // MARK: - 檢查是否已經看過引導
    func shouldShowTooltip() -> Bool {
        return !UserDefaults.standard.bool(forKey: hasSeenTooltipKey)
    }

    // MARK: - 開始引導
    func startTooltip(with steps: [TooltipStep]) {
        self.steps = steps
        self.currentStepIndex = 0
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isShowingTooltip = true
        }
    }

    // MARK: - 下一步
    func nextStep() {
        if currentStepIndex < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStepIndex += 1
            }
        } else {
            finishTooltip()
        }
    }

    // MARK: - 跳過
    func skipTooltip() {
        finishTooltip()
    }

    // MARK: - 完成引導
    private func finishTooltip() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowingTooltip = false
        }

        // 標記為已看過
        UserDefaults.standard.set(true, forKey: hasSeenTooltipKey)

        // 延遲清空步驟，避免動畫過程中閃爍
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentStepIndex = 0
            self.steps = []
        }
    }

    // MARK: - 重置（讓用戶可以重新觀看）
    func resetTooltip() {
        UserDefaults.standard.set(false, forKey: hasSeenTooltipKey)
    }

    // MARK: - 當前步驟
    var currentStep: TooltipStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    // MARK: - 更新步驟的目標區域
    func updateStepTargetFrame(stepId: Int, frame: CGRect) {
        if let index = steps.firstIndex(where: { $0.id == stepId }) {
            steps[index] = TooltipStep(
                id: steps[index].id,
                title: steps[index].title,
                message: steps[index].message,
                targetFrame: frame,
                position: steps[index].position
            )
        }
    }
}
