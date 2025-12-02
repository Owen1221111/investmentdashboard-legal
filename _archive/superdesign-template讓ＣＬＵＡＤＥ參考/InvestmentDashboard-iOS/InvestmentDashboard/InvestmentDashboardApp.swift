import SwiftUI

// MARK: - 主要 App 結構 (只使用CloudKit，完全移除本地儲存)
@main
struct InvestmentDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
