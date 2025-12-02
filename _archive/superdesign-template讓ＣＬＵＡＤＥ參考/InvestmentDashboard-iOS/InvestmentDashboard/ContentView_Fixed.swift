import SwiftUI
import UniformTypeIdentifiers

// MARK: - ContentView現在使用CloudKit版本的DataManager
// MARK: - 主要內容視圖 (App的根視圖)
struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddForm = false

    // 表單數據狀態 - 保存上次輸入的值
    @State private var formData = AssetFormData()
    @State private var bondFormData = BondFormData()

    // 月度資料狀態 - 動態管理表格資料
    @State private var monthlyDataList: [MonthlyData] = []

    // 公司債資料狀態 - 動態管理公司債表格資料
    @State private var bondDataList: [[String]] = []

    // 標籤選擇狀態
    @State private var selectedTab = 0 // 0: 資產明細, 1: 公司債

    // 日期選擇狀態
    @State private var selectedDate = Date()

    // 表格展開/折疊狀態
    @State private var isTableExpanded = true
    @State private var isAssetTableExpanded = true
    @State private var isBondTableExpanded = true

    // 資料新增狀態
    @State private var showingMonthlyForm = false
    @State private var showingBondForm = false
    @State private var selectedMonthlyRecord: [String]?
    @State private var selectedBondRecord: BondRecord?
    @State private var isEditingMode = false

    // 公司債資料
    @State private var bondRecords: [BondRecord] = []

    // 滑動控制
    @State private var monthlyScrollOffset: CGFloat = 0
    @State private var bondScrollOffset: CGFloat = 0
    @State private var isMonthlyScrolling = false
    @State private var isBondScrolling = false

    // 匯入功能狀態
    @State private var showingMonthlyImportPicker = false
    @State private var showingBondImportPicker = false

    // 結構型商品狀態
    @State private var structuredProducts: [StructuredProduct] = []
    @State private var showingExitForm = false
    @State private var selectedProductToExit: StructuredProduct?
    @State private var isStructuredTableExpanded = true

    // CloudKit Debug狀態顯示
    @State private var showingCloudKitDebug = false

    var body: some View {
        GeometryReader { geometry in
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadLayout(geometry: geometry)
            } else {
                iPhoneLayout
            }
        }
        .background(Color(.init(red: 0.97, green: 0.97, blue: 0.975, alpha: 1.0)))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("🔍 CloudKit") {
                    showingCloudKitDebug = true
                }
            }
        }
        .sheet(isPresented: $showingCloudKitDebug) {
            CloudKitStatusChecker()
        }
        .onAppear {
            loadSampleBondData()
            loadSampleStructuredProducts()
        }
    }

    // MARK: - iPad 佈局
    private func iPadLayout(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // CloudKit狀態指示器
                cloudKitStatusBar

                // 頂部資產區域
                mainStatsCard
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)

                // 資產配置卡片
                assetAllocationCard
                    .padding(.horizontal, 32)

                // 月度資產明細表格
                monthlyAssetDetailTable
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)

                // 公司債明細表格
                bondDetailTable
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)

                // 結構型明細區塊
                structuredProductsDetailTable
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - iPhone 佈局
    private var iPhoneLayout: some View {
        VStack(spacing: 16) {
            // CloudKit狀態指示器
            cloudKitStatusBar

            // 主要統計區域
            mainStatsCard

            // 月度資產明細表格
            monthlyAssetDetailTable

            // 公司債明細表格
            bondDetailTable

            // 結構型明細表格
            structuredProductsDetailTable
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    // MARK: - CloudKit狀態指示器
    private var cloudKitStatusBar: some View {
        HStack {
            // iCloud狀態
            HStack(spacing: 4) {
                Circle()
                    .fill(dataManager.isSignedInToiCloud ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text("iCloud")
                    .font(.caption)
                    .foregroundColor(dataManager.isSignedInToiCloud ? .green : .red)
            }

            // 網路狀態
            HStack(spacing: 4) {
                Circle()
                    .fill(dataManager.isOnline ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text("網路")
                    .font(.caption)
                    .foregroundColor(dataManager.isOnline ? .green : .orange)
            }

            // 資料統計
            Text("客戶:\(dataManager.clients.count) 記錄:\(dataManager.monthlyAssetRecords.count)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("詳細") {
                showingCloudKitDebug = true
            }
            .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal, 16)
    }

    // 由於原始ContentView很長，我先提供主要的結構
    // 你需要把原來的其他View實作複製過來

    // MARK: - 主要統計卡片 (簡化版本)
    private var mainStatsCard: some View {
        VStack {
            Text("投資儀表板")
                .font(.title)
                .fontWeight(.bold)

            Text("CloudKit版本 - 支援跨裝置同步")
                .font(.caption)
                .foregroundColor(.secondary)

            if dataManager.clients.isEmpty {
                Text("尚無客戶資料")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Text("客戶數量: \(dataManager.clients.count)")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - 其他View的placeholder
    private var assetAllocationCard: some View {
        Text("資產配置卡片 (需要實作)")
            .padding()
            .background(Color.white)
            .cornerRadius(12)
    }

    private var monthlyAssetDetailTable: some View {
        Text("月度資產明細表格 (需要實作)")
            .padding()
            .background(Color.white)
            .cornerRadius(12)
    }

    private var bondDetailTable: some View {
        Text("公司債明細表格 (需要實作)")
            .padding()
            .background(Color.white)
            .cornerRadius(12)
    }

    private var structuredProductsDetailTable: some View {
        Text("結構型商品明細表格 (需要實作)")
            .padding()
            .background(Color.white)
            .cornerRadius(12)
    }

    // MARK: - 載入測試資料的方法
    private func loadSampleBondData() {
        // 原來的實作
    }

    private func loadSampleStructuredProducts() {
        // 原來的實作
    }
}

// MARK: - 支援的資料結構 (你需要根據原始檔案複製這些)
struct AssetFormData {
    // 原來的實作
}

struct BondFormData {
    // 原來的實作
}

struct MonthlyData {
    // 原來的實作
}

struct BondRecord {
    // 原來的實作
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DataManager())
    }
}