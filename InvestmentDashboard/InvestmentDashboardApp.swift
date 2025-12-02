//
//  InvestmentDashboardApp.swift
//  InvestmentDashboard
//
//  Created by CheHung Liu on 2025/9/25.
//

import SwiftUI

@main
struct InvestmentDashboardApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var versionManager = AppVersionManager.shared
    @State private var showWhatsNew = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(subscriptionManager)
                .task {
                    // App 啟動時檢查訂閱狀態
                    await subscriptionManager.checkSubscriptionStatus()
                    print("📱 訂閱狀態已檢查：\(subscriptionManager.isSubscriptionActive ? "已訂閱" : "未訂閱")")
                }
                .onAppear {
                    // 檢查是否需要顯示新功能介紹
                    if versionManager.shouldShowWhatsNew() {
                        // 延遲顯示，確保主界面已載入
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showWhatsNew = true
                        }
                    }
                }
                .sheet(isPresented: $showWhatsNew) {
                    WhatsNewView()
                }
        }
    }
}
