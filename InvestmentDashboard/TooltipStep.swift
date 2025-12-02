//
//  TooltipStep.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/30.
//  定義提示引導的每個步驟
//

import SwiftUI

/// 提示步驟定義
struct TooltipStep: Identifiable {
    let id: Int
    let title: String
    let message: String
    let targetFrame: CGRect?  // 要高亮的區域
    let position: TooltipPosition  // 提示框的位置

    enum TooltipPosition {
        case top
        case bottom
        case center
        case leading
        case trailing
    }
}

/// 預設的引導步驟
class TooltipSteps {

    /// 首次啟動的引導步驟
    static func getWelcomeSteps() -> [TooltipStep] {
        return [
            // 步驟 1：歡迎訊息
            TooltipStep(
                id: 1,
                title: "歡迎使用投資管理系統！",
                message: "讓我們快速了解如何開始使用",
                targetFrame: nil,
                position: .center
            ),

            // 步驟 2：漢堡選單按鈕
            TooltipStep(
                id: 2,
                title: "開啟客戶管理",
                message: "請點擊這個選單按鈕，打開客戶管理面板",
                targetFrame: nil,  // 將在 ContentView 中動態設定
                position: .bottom
            ),

            // 步驟 3：新增客戶
            TooltipStep(
                id: 3,
                title: "新增客戶",
                message: "現在點擊這個綠色的「+」按鈕，就可以新增您的第一位客戶了！",
                targetFrame: nil,
                position: .bottom
            ),

            // 步驟 4：完成
            TooltipStep(
                id: 4,
                title: "開始使用！",
                message: "現在您可以開始新增客戶並管理投資資料了。之後可以隨時點擊選單旁的「？」按鈕重新觀看引導",
                targetFrame: nil,
                position: .center
            )
        ]
    }
}
