import SwiftUI

// MARK: - 主要內容視圖 (App的根視圖)
struct ContentView: View {
    @StateObject private var viewModel = ClientViewModel()
    @State private var showingAddForm = false

    // 表單數據狀態 - 保存上次輸入的值
    @State private var formData = AssetFormData()
    @State private var bondFormData = BondFormData()

    // 標籤選擇狀態
    @State private var selectedTab = 0 // 0: 資產明細, 1: 公司債

    // 日期選擇狀態
    @State private var selectedDate = Date()

    // 表格展開/折疊狀態
    @State private var isMonthlyTableExpanded = true
    @State private var isBondTableExpanded = true
    @State private var showingClientPanel = false // 新增：直接控制客戶面板

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // 自定義頂部導航欄
                    HStack {
                        Button("☰") {
                            print("🔍 漢堡按鈕被點擊 - 顯示客戶管理面板")
                            // 每次點擊都重新從CloudKit載入客戶資料
                            Task {
                                await viewModel.loadClients()
                            }
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingClientPanel = true
                            }
                        }
                        .font(.system(size: 32, weight: .medium))
                        .frame(width: 44, height: 44)

                        Spacer()

                        VStack(spacing: 2) {
                            Text("投資儀表板")
                                .font(.headline)
                                .fontWeight(.semibold)
                            if let client = viewModel.selectedClient {
                                Text("客戶：\(client.name)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("請選擇客戶")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }

                        Spacer()

                        // 調試按鈕
                        Button("🔍") {
                            Task {
                                await viewModel.diagnoseCloudKitIssues()
                            }
                        }
                        .font(.system(size: 24, weight: .medium))
                        .frame(width: 44, height: 44)

                        // 新增按鈕
                        Button("+") {
                            showingAddForm = true
                        }
                        .font(.system(size: 36, weight: .medium))
                        .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)

                    // 主要內容
                    ScrollView {
                        if geometry.size.width > 600 {
                            // iPad 佈局 - 水平排列
                            iPadLayout
                        } else {
                            // iPhone 佈局 - 垂直排列
                            iPhoneLayout
                        }
                    }
                    .background(Color(.init(red: 0.97, green: 0.97, blue: 0.975, alpha: 1.0)))
                }

                // 原本的系統側邊欄 (按照 PROJECT.md v0.5.0 規格)
                if viewModel.showingClientList {
                    ZStack {
                        // 背景遮罩
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.hideClientList()
                                }
                            }

                        // 側邊欄內容
                        HStack(spacing: 0) {
                            ClientListView(viewModel: viewModel)
                                .frame(width: geometry.size.width * 0.75)
                                .frame(height: geometry.size.height)
                                .background(Color.white)
                                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 5, y: 0)

                            Spacer()
                        }
                        .transition(.move(edge: .leading))
                    }
                    .zIndex(1000) // 確保在最上層
                }

                // 新的直接客戶面板 - 不依賴系統側邊欄
                if showingClientPanel {
                    ZStack {
                        // 背景遮罩
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingClientPanel = false
                                }
                            }

                        // 側邊欄內容
                        HStack(spacing: 0) {
                            // 直接內嵌客戶管理面板
                            VStack(spacing: 0) {
                                // 標題區域
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("客戶管理")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(.init(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)))
                                        Text("管理您的客戶資料")
                                            .font(.caption)
                                            .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                                    }

                                    Spacer()

                                    Button("+ 新增客戶") {
                                        viewModel.showAddClient()
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(.init(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0)),
                                                Color(.init(red: 0.15, green: 0.6, blue: 0.35, alpha: 1.0))
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(10)
                                    .shadow(color: Color(.init(red: 0.2, green: 0.7, blue: 0.4, alpha: 0.3)), radius: 4, x: 0, y: 2)

                                    Button("✕") {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showingClientPanel = false
                                        }
                                    }
                                    .font(.title3)
                                    .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(Color(.init(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0)))
                                    )
                                }
                                .padding(20)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white,
                                            Color(.init(red: 0.99, green: 0.99, blue: 1.0, alpha: 1.0))
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                                // 客戶列表或空白狀態
                                if viewModel.clients.isEmpty {
                                    VStack(spacing: 24) {
                                        Image(systemName: "person.2.circle")
                                            .font(.system(size: 48))
                                            .foregroundColor(Color(.init(red: 0.7, green: 0.7, blue: 0.75, alpha: 1.0)))

                                        VStack(spacing: 8) {
                                            Text("還沒有客戶資料")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color(.init(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)))
                                            Text("開始建立您的客戶檔案")
                                                .font(.body)
                                                .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                                        }

                                        Button("創建測試客戶") {
                                            Task {
                                                await viewModel.createTestClients()
                                            }
                                        }
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(.init(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)),
                                                    Color(.init(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0))
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(12)
                                        .shadow(color: Color(.init(red: 0.3, green: 0.6, blue: 0.9, alpha: 0.3)), radius: 6, x: 0, y: 3)
                                    }
                                    .padding(40)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(.init(red: 0.98, green: 0.99, blue: 1.0, alpha: 1.0)))
                                } else {
                                    ScrollView {
                                        LazyVStack(spacing: 12) {
                                            ForEach(viewModel.clients, id: \.id) { client in
                                                Button(action: {
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        viewModel.selectClient(client)
                                                    }
                                                }) {
                                                    HStack(spacing: 16) {
                                                        // 客戶頭像
                                                        Circle()
                                                            .fill(
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [
                                                                        Color(.init(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)),
                                                                        Color(.init(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0))
                                                                    ]),
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                )
                                                            )
                                                            .frame(width: 48, height: 48)
                                                            .overlay(
                                                                Text(String(client.name.prefix(1)))
                                                                    .font(.system(size: 18, weight: .semibold))
                                                                    .foregroundColor(.white)
                                                            )
                                                            .shadow(color: Color(.init(red: 0.3, green: 0.6, blue: 0.9, alpha: 0.3)), radius: 4, x: 0, y: 2)

                                                        // 客戶資訊
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(client.name)
                                                                .font(.system(size: 16, weight: .semibold))
                                                                .foregroundColor(Color(.init(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)))
                                                            Text(client.email)
                                                                .font(.system(size: 14))
                                                                .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                                                        }

                                                        Spacer()

                                                        // 選中狀態
                                                        if viewModel.selectedClient?.id == client.id {
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .font(.system(size: 22))
                                                                .foregroundColor(Color(.init(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0)))
                                                                .scaleEffect(viewModel.selectedClient?.id == client.id ? 1.1 : 1.0)
                                                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedClient?.id == client.id)
                                                        } else {
                                                            Circle()
                                                                .stroke(Color(.init(red: 0.8, green: 0.8, blue: 0.85, alpha: 1.0)), lineWidth: 2)
                                                                .frame(width: 22, height: 22)
                                                        }
                                                    }
                                                    .padding(.vertical, 16)
                                                    .padding(.horizontal, 20)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(
                                                                viewModel.selectedClient?.id == client.id ?
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [
                                                                        Color(.init(red: 0.9, green: 0.98, blue: 0.93, alpha: 1.0)),
                                                                        Color(.init(red: 0.92, green: 1.0, blue: 0.95, alpha: 1.0))
                                                                    ]),
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ) :
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [Color.white, Color.white]),
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                )
                                                            )
                                                            .shadow(
                                                                color: viewModel.selectedClient?.id == client.id ?
                                                                Color(.init(red: 0.2, green: 0.7, blue: 0.4, alpha: 0.2)) :
                                                                Color.black.opacity(0.05),
                                                                radius: viewModel.selectedClient?.id == client.id ? 8 : 4,
                                                                x: 0,
                                                                y: viewModel.selectedClient?.id == client.id ? 4 : 2
                                                            )
                                                    )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .scaleEffect(viewModel.selectedClient?.id == client.id ? 1.02 : 1.0)
                                                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedClient?.id == client.id)
                                            }
                                        }
                                        .padding(20)
                                    }
                                    .background(Color(.init(red: 0.98, green: 0.99, blue: 1.0, alpha: 1.0)))
                                }

                                Spacer()
                            }
                            .frame(width: geometry.size.width * 0.75)
                            .frame(height: geometry.size.height)
                            .background(Color.white)
                            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 5, y: 0)

                            Spacer()
                        }
                        .transition(.move(edge: .leading))
                    }
                    .zIndex(1001) // 比原本的更高層級
                }
            }
            .sheet(isPresented: $showingAddForm) {
                simpleAddDataForm
            }
            .sheet(isPresented: $viewModel.showingAddClient) {
                AddClientFormView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $viewModel.showingEditClient) {
                EditClientFormView()
                    .environmentObject(viewModel)
            }
            .onAppear {
                // App啟動時的初始化邏輯（不影響原本功能）
                Task {
                    print("🚀 App啟動 - 開始初始化客戶資料")

                    // 1. 檢查iCloud狀態並載入客戶資料
                    await viewModel.loadClients()

                    // 2. 如果沒有客戶資料，建立測試客戶（只執行一次）
                    if viewModel.clients.isEmpty {
                        print("📝 未找到客戶資料，建立測試客戶")
                        await viewModel.createTestClients()
                        await viewModel.loadClients()
                    }

                    print("✅ 客戶資料初始化完成，共 \(viewModel.clients.count) 位客戶")
                    print("💡 用戶可以點擊漢堡按鈕選擇客戶")
                }
            }
        }
    }

    // MARK: - iPad 佈局
    private var iPadLayout: some View {
        VStack(spacing: 20) {
            // 頂部：主要統計卡片 - 全寬
            mainStatsCardForDesktop
                .padding(.horizontal, 24)

            // 中間：資產配置和投資區域並排
            HStack(alignment: .top, spacing: 16) {
                // 左側：資產配置卡片
                assetAllocationCard
                    .frame(maxWidth: 380, maxHeight: .infinity) // 增加寬度確保百分比數字不被切掉，填滿高度與右側對齊

                // 右側：投資卡片組
                VStack(spacing: 16) {
                    usStockCard
                    twStockCard
                    bondsCard
                    simpleBondDividendCard
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)

            // 底部：月度資產明細表格
            detailedMonthlyAssetTable
                .padding(.horizontal, 24)

            // 公司債明細表格
            bondDetailTable
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
    }

    // MARK: - iPhone 佈局
    private var iPhoneLayout: some View {
        VStack(spacing: 16) {
            // 主要統計區域
            mainStatsCard

            // 資產配置卡片
            assetAllocationCard

            // 投資卡片行
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    usStockCard
                    twStockCard
                }
                HStack(spacing: 16) {
                    bondsCard
                    Spacer()
                }
            }

            // 月度資產表格（簡化版）
            detailedMonthlyAssetTable
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - 主要統計卡片
    private var mainStatsCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("總資產")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                Text(viewModel.currentTotalAssets)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))

                Text("總損益: \(viewModel.currentTotalPnL)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
            }

            // 時間按鈕
            HStack(spacing: 8) {
                ForEach(["1D", "7D", "1M", "3M", "1Y"], id: \.self) { period in
                    Button(period) { }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(period == "1D" ? Color.black : Color.gray.opacity(0.2))
                        .foregroundColor(period == "1D" ? .white : .black)
                        .clipShape(Capsule())
                }
            }

            // 走勢圖
            simpleTrendChart

            // 2x2 統計卡片
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                statsCard(title: "總匯入", value: viewModel.currentTotalDeposit, isHighlight: false)
                statsCard(title: "總額報酬率", value: "+8.5%", isHighlight: true)
                statsCard(title: "現金", value: viewModel.currentCash, isHighlight: false)
                statsCard(title: "本月收益", value: "+25,000", isHighlight: false)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    private func statsCard(title: String, value: String, isHighlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isHighlight ? .white.opacity(0.9) : Color(.init(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)))

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(isHighlight ? .white : Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isHighlight ?
                    LinearGradient(
                        colors: [
                            Color(.init(red: 0.33, green: 0.73, blue: 0.46, alpha: 1.0)),
                            Color(.init(red: 0.18, green: 0.52, blue: 0.29, alpha: 1.0))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(colors: [Color.white], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: isHighlight ? Color(.init(red: 0.18, green: 0.52, blue: 0.29, alpha: 0.3)) : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - 資產配置卡片 (支援左滑切換)
    @State private var selectedAllocationPage = 0

    // MARK: - 投資卡片左滑功能狀態 (根據 PROJECT.md 規範)
    @State private var selectedUSStockPage = 0  // 0: 美股, 1: 定期定額
    @State private var selectedBondsPage = 0    // 0: 債券, 1: 定期定額
    @State private var selectedTWStockPage = 0  // 0: 台股, 1: 定期定額

    // MARK: - 公司債數據 (根據 PROJECT.md 規範)
    @State private var bondDataList: [[String]] = []

    private var assetAllocationCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text(getAllocationTitle())
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == selectedAllocationPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }

            TabView(selection: $selectedAllocationPage) {
                // 頁面 0: 資產配置總覽
                allocationOverviewPage
                    .tag(0)

                // 頁面 1: 美股詳細配置
                allocationDetailPage(title: "美股", color: .red, percentage: viewModel.usStockPercentage, value: viewModel.currentUSStockValue)
                    .tag(1)

                // 頁面 2: 債券詳細配置
                allocationDetailPage(title: "債券", color: .gray, percentage: viewModel.bondsPercentage, value: viewModel.currentBondsValue)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .clipped()
        }
        .frame(minHeight: 480, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    // 取得配置頁面標題
    private func getAllocationTitle() -> String {
        switch selectedAllocationPage {
        case 0: return "資產配置"
        case 1: return "美股配置"
        case 2: return "債券配置"
        default: return "資產配置"
        }
    }

    // 資產配置總覽頁面
    private var allocationOverviewPage: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 400
            let circleSize: CGFloat = isCompact ? 200 : 250
            let lineWidth: CGFloat = isCompact ? 32 : 40

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                        .frame(width: circleSize, height: circleSize)

                    // 現金 (橙色)
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.cashPercentage / 100))
                        .stroke(Color.orange, lineWidth: lineWidth)
                        .rotationEffect(.degrees(-90))
                        .frame(width: circleSize, height: circleSize)

                    // 債券 (灰色)
                    Circle()
                        .trim(from: CGFloat(viewModel.cashPercentage / 100),
                              to: CGFloat((viewModel.cashPercentage + viewModel.bondsPercentage) / 100))
                        .stroke(Color.gray, lineWidth: lineWidth)
                        .rotationEffect(.degrees(-90))
                        .frame(width: circleSize, height: circleSize)

                    // 美股 (紅色) - 最大比例，顯示在中央
                    Circle()
                        .trim(from: CGFloat((viewModel.cashPercentage + viewModel.bondsPercentage) / 100),
                              to: CGFloat((viewModel.cashPercentage + viewModel.bondsPercentage + viewModel.usStockPercentage) / 100))
                        .stroke(Color.red, lineWidth: lineWidth)
                        .rotationEffect(.degrees(-90))
                        .frame(width: circleSize, height: circleSize)

                    // 台股 (綠色)
                    Circle()
                        .trim(from: CGFloat((viewModel.cashPercentage + viewModel.bondsPercentage + viewModel.usStockPercentage) / 100),
                              to: CGFloat((viewModel.cashPercentage + viewModel.bondsPercentage + viewModel.usStockPercentage + viewModel.twStockPercentage) / 100))
                        .stroke(Color.green, lineWidth: lineWidth)
                        .rotationEffect(.degrees(-90))
                        .frame(width: circleSize, height: circleSize)

                    // 結構型 (藍色)
                    Circle()
                        .trim(from: CGFloat((viewModel.cashPercentage + viewModel.bondsPercentage + viewModel.usStockPercentage + viewModel.twStockPercentage) / 100),
                              to: CGFloat((viewModel.cashPercentage + viewModel.bondsPercentage + viewModel.usStockPercentage + viewModel.twStockPercentage + viewModel.structuredPercentage) / 100))
                        .stroke(Color.blue, lineWidth: lineWidth)
                        .rotationEffect(.degrees(-90))
                        .frame(width: circleSize, height: circleSize)

                    VStack {
                        Text("\(String(format: "%.0f", viewModel.usStockPercentage))%")
                            .font(.system(size: isCompact ? 32 : 38, weight: .bold))
                        Text("美股")
                            .font(.system(size: isCompact ? 20 : 24))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
                VStack(spacing: 12) {
                    responsiveLegendItem(color: .orange, title: "現金", percentage: "\(String(format: "%.0f", viewModel.cashPercentage))%", isCompact: isCompact)
                    responsiveLegendItem(color: .gray, title: "債券", percentage: "\(String(format: "%.0f", viewModel.bondsPercentage))%", isCompact: isCompact)
                    responsiveLegendItem(color: .red, title: "美股", percentage: "\(String(format: "%.0f", viewModel.usStockPercentage))%", isCompact: isCompact)
                    responsiveLegendItem(color: .green, title: "台股", percentage: "\(String(format: "%.0f", viewModel.twStockPercentage))%", isCompact: isCompact)
                    responsiveLegendItem(color: .blue, title: "結構型", percentage: "\(String(format: "%.0f", viewModel.structuredPercentage))%", isCompact: isCompact)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
        }
        .frame(height: 440)
        .padding(.top, 20)
    }

    // 資產配置詳細頁面
    private func allocationDetailPage(title: String, color: Color, percentage: Double, value: String) -> some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 400
            let circleSize: CGFloat = isCompact ? 200 : 250
            let lineWidth: CGFloat = isCompact ? 32 : 40

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                        .frame(width: circleSize, height: circleSize)

                    Circle()
                        .trim(from: 0, to: CGFloat(percentage / 100))
                        .stroke(color, lineWidth: lineWidth)
                        .rotationEffect(.degrees(-90))
                        .frame(width: circleSize, height: circleSize)

                    VStack {
                        Text("\(String(format: "%.1f", percentage))%")
                            .font(.system(size: isCompact ? 32 : 38, weight: .bold))
                        Text(title)
                            .font(.system(size: isCompact ? 20 : 24))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
                VStack(spacing: 12) {
                    Text("總金額")
                        .font(.system(size: isCompact ? 16 : 18))
                        .foregroundColor(.gray)
                    Text(value)
                        .font(.system(size: isCompact ? 20 : 22, weight: .bold))
                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                }
                .padding(.bottom, 20)
            }
        }
        .frame(height: 420)
        .padding(.top, 20)
    }

    private func legendItem(color: Color, title: String, percentage: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 14, height: 14)
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(percentage)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.black)
                .frame(minWidth: 40, alignment: .trailing)
        }
        .padding(.horizontal, 4)
    }

    private func responsiveLegendItem(color: Color, title: String, percentage: String, isCompact: Bool) -> some View {
        HStack {
            HStack(spacing: 10) {
                Circle()
                    .fill(color)
                    .frame(width: isCompact ? 14 : 16, height: isCompact ? 14 : 16)
                Text(title)
                    .font(.system(size: isCompact ? 16 : 18))
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(percentage)
                .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                .foregroundColor(.black)
                .frame(minWidth: 50, alignment: .trailing)
        }
        .padding(.horizontal, 6)
    }

    // MARK: - 詳細月度資產表格
    private var detailedMonthlyAssetTable: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isMonthlyTableExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 14))
                        Text("月度資產明細")
                            .font(.system(size: 16, weight: .semibold))

                        if !displayMonthlyData.isEmpty {
                            Text("（\(displayMonthlyData.count)筆）")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }

                        Image(systemName: isMonthlyTableExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                    }
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                }

                Spacer()

                Button("編輯欄位") { }
                    .font(.system(size: 12))
                    .foregroundColor(.blue)

                Button("查看詳細") { }
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }

            // 可展開/折疊的表格內容
            if isMonthlyTableExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 表頭
                        HStack(spacing: 8) {
                            tableHeaderCell("日期", width: 60)
                            tableHeaderCell("現金", width: 60)
                            tableHeaderCell("美股", width: 60)
                            tableHeaderCell("定期定額", width: 80)
                            tableHeaderCell("債券", width: 60)
                            tableHeaderCell("結構型商品", width: 80)
                            tableHeaderCell("台股", width: 60)
                            tableHeaderCell("台股折合", width: 70)
                            tableHeaderCell("已領利息", width: 70)
                            tableHeaderCell("匯入", width: 60)
                            tableHeaderCell("美股成本", width: 70)
                            tableHeaderCell("定期成本", width: 70)
                            tableHeaderCell("債券成本", width: 70)
                            tableHeaderCell("台股成本", width: 70)
                            tableHeaderCell("備註", width: 60)
                            tableHeaderCell("總資產", width: 80)
                        }
                        .padding(.horizontal, 8)

                        // 分隔線
                        Rectangle()
                            .fill(Color(.init(red: 0.92, green: 0.92, blue: 0.93, alpha: 1.0)))
                            .frame(height: 1)
                            .padding(.vertical, 6)

                        // 數據行
                        VStack(spacing: 6) {
                            ForEach(displayMonthlyData) { data in
                                HStack(spacing: 8) {
                                    tableDataCell(data.date, width: 60)
                                    tableDataCell(data.cash, width: 60)
                                    tableDataCell(data.usStock, width: 60)
                                    tableDataCell(data.regularInvestment, width: 80)
                                    tableDataCell(data.bonds, width: 60)
                                    tableDataCell(data.structuredProducts, width: 80)
                                    tableDataCell(data.twStock, width: 60)
                                    tableDataCell(data.twStockUSD, width: 70)
                                    tableDataCell(data.interestReceived, width: 70)
                                    tableDataCell(data.deposit, width: 60)
                                    tableDataCell(data.usStockCost, width: 70)
                                    tableDataCell(data.regularCost, width: 70)
                                    tableDataCell(data.bondsCost, width: 70)
                                    tableDataCell(data.twStockCost, width: 70)
                                    tableDataCell(data.notes, width: 60)
                                    tableDataCell(data.totalAssets, width: 80, isBold: true)
                                }
                                .padding(.horizontal, 8)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    // CloudKit 資料顯示 - 純粹從 ViewModel 取得 (使用 monthlyAssetData)
    private var displayMonthlyData: [MonthlyData] {
        return viewModel.monthlyAssetData.map { dataArray in
            MonthlyData(
                date: dataArray.count > 0 ? dataArray[0] : "",
                cash: dataArray.count > 1 ? formatDisplayNumber(dataArray[1]) : "0",
                usStock: dataArray.count > 2 ? formatDisplayNumber(dataArray[2]) : "0",
                regularInvestment: dataArray.count > 3 ? formatDisplayNumber(dataArray[3]) : "0",
                bonds: dataArray.count > 4 ? formatDisplayNumber(dataArray[4]) : "0",
                structuredProducts: dataArray.count > 5 ? formatDisplayNumber(dataArray[5]) : "0",
                twStock: dataArray.count > 6 ? formatDisplayNumber(dataArray[6]) : "0",
                twStockUSD: dataArray.count > 7 ? formatDisplayNumber(dataArray[7]) : "0",
                interestReceived: dataArray.count > 8 ? formatDisplayNumber(dataArray[8]) : "0",
                deposit: dataArray.count > 9 ? formatDisplayNumber(dataArray[9]) : "0",
                usStockCost: dataArray.count > 10 ? formatDisplayNumber(dataArray[10]) : "0",
                regularCost: dataArray.count > 11 ? formatDisplayNumber(dataArray[11]) : "0",
                bondsCost: dataArray.count > 12 ? formatDisplayNumber(dataArray[12]) : "0",
                twStockCost: dataArray.count > 13 ? formatDisplayNumber(dataArray[13]) : "0",
                notes: dataArray.count > 14 ? dataArray[14] : "",
                totalAssets: dataArray.count > 15 ? formatDisplayNumber(dataArray[15]) : "0"
            )
        }
    }

    // 格式化顯示數字 (將千為單位轉換為實際顯示)
    private func formatDisplayNumber(_ value: String) -> String {
        guard let doubleValue = Double(value) else { return value }
        return String(format: "%.2f", doubleValue * 1000)
    }

    struct MonthlyData: Identifiable {
        let id = UUID()
        let date: String
        let cash: String
        let usStock: String
        let regularInvestment: String
        let bonds: String
        let structuredProducts: String
        let twStock: String
        let twStockUSD: String
        let interestReceived: String
        let deposit: String
        let usStockCost: String
        let regularCost: String
        let bondsCost: String
        let twStockCost: String
        let notes: String
        let totalAssets: String
    }

    // MARK: - 專用美股卡片 (含左滑功能，新佈局)
    private var usStockCard: some View {
        VStack(spacing: 8) {
            // 標題和頁面指示器
            HStack {
                Text(getUSStockCardTitle())
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<2, id: \.self) { i in
                        Circle()
                            .fill(i == selectedUSStockPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            TabView(selection: $selectedUSStockPage) {
                usStockDetailView.tag(0)      // 頁面0: 美股
                usStockRegularDetailView.tag(1) // 頁面1: 定期定額
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 70)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    // 美股詳細頁面 - 新佈局：左側報酬率，右側走勢圖
    private var usStockDetailView: some View {
        HStack(spacing: 8) {
            // 左側：金額和報酬率
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.currentUSStockValue)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.black)

                Text("報酬率：\(viewModel.usStockReturnRate)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
            }

            Spacer()

            // 右側：走勢圖
            investmentTrendChart(for: "美股", isPositive: true)
                .frame(width: 80)
        }
    }

    // 美股定期定額頁面
    private var usStockRegularDetailView: some View {
        HStack(spacing: 8) {
            // 左側：金額和報酬率
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.regularInvestmentValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)

                Text("報酬率：+0.0%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
            }

            Spacer()

            // 右側：走勢圖
            investmentTrendChart(for: "定期定額", isPositive: true)
                .frame(width: 80)
        }
    }

    // 取得美股卡片標題
    private func getUSStockCardTitle() -> String {
        switch selectedUSStockPage {
        case 0: return "美股"
        case 1: return "定期定額"
        default: return "美股"
        }
    }

    // MARK: - 專用台股卡片 (含左滑功能，統一佈局)
    private var twStockCard: some View {
        VStack(spacing: 8) {
            // 標題和頁面指示器
            HStack {
                Text(getTWStockCardTitle())
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<2, id: \.self) { i in
                        Circle()
                            .fill(i == selectedTWStockPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            TabView(selection: $selectedTWStockPage) {
                twStockDetailView.tag(0)      // 頁面0: 台股
                twStockRegularDetailView.tag(1) // 頁面1: 定期定額
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 70)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    // 台股詳細頁面 - 統一佈局：左側報酬率，右側走勢圖
    private var twStockDetailView: some View {
        HStack(spacing: 8) {
            // 左側：金額和報酬率
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.currentTWStockValue)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.black)

                Text("報酬率：\(viewModel.twStockReturnRate)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
            }

            Spacer()

            // 右側：走勢圖
            investmentTrendChart(for: "台股", isPositive: true)
                .frame(width: 80)
        }
    }

    // 台股定期定額頁面
    private var twStockRegularDetailView: some View {
        HStack(spacing: 8) {
            // 左側：金額和報酬率
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.regularInvestmentValue)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.black)

                Text("報酬率：+0.0%")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
            }

            Spacer()

            // 右側：走勢圖
            investmentTrendChart(for: "定期定額", isPositive: true)
                .frame(width: 80)
        }
    }

    // 取得台股卡片標題
    private func getTWStockCardTitle() -> String {
        switch selectedTWStockPage {
        case 0: return "台股"
        case 1: return "定期定額"
        default: return "台股"
        }
    }

    // MARK: - 專用債券卡片 (根據 PROJECT.md 規範)
    private var bondsCard: some View {
        VStack(spacing: 8) {
            // 標題和頁面指示器
            HStack {
                Text(getBondsCardTitle())
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<2, id: \.self) { i in
                        Circle()
                            .fill(i == selectedBondsPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            TabView(selection: $selectedBondsPage) {
                bondsDetailView.tag(0)      // 頁面0: 債券
                regularInvestmentDetailView.tag(1) // 頁面1: 定期定額
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 70)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    // 債券詳細頁面 - 統一佈局：左側報酬率，右側走勢圖
    private var bondsDetailView: some View {
        HStack(spacing: 8) {
            // 左側：金額和報酬率
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.currentBondsValue)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.black)

                Text("報酬率：\(viewModel.bondsReturnRate)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
            }

            Spacer()

            // 右側：走勢圖
            investmentTrendChart(for: "債券", isPositive: true)
                .frame(width: 80)
        }
    }

    // 定期定額詳細頁面 - 統一佈局：左側報酬率，右側走勢圖
    private var regularInvestmentDetailView: some View {
        HStack(spacing: 8) {
            // 左側：金額和報酬率
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.regularInvestmentValue)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.black)

                Text("報酬率：+0.0%")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
            }

            Spacer()

            // 右側：走勢圖
            investmentTrendChart(for: "定期定額", isPositive: true)
                .frame(width: 80)
        }
    }

    // 取得債券卡片標題
    private func getBondsCardTitle() -> String {
        switch selectedBondsPage {
        case 0: return "債券"
        case 1: return "定期定額"
        default: return "債券"
        }
    }

    // MARK: - 投資走勢圖 (基於真實數據)
    private func investmentTrendChart(for assetType: String, isPositive: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 1) {
            ForEach(0..<getInvestmentTrendData(for: assetType).count, id: \.self) { index in
                let data = getInvestmentTrendData(for: assetType)
                let maxHeight: CGFloat = 15
                let height = data.isEmpty ? 4 : CGFloat(4 + (data[index] / data.max()!) * (maxHeight - 4))

                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color(.init(red: 0.40, green: 0.62, blue: 0.47, alpha: 0.6)))
                    .frame(width: 2, height: height)
            }
        }
        .frame(height: 70)
    }

    // 取得投資走勢數據
    private func getInvestmentTrendData(for assetType: String) -> [Double] {
        let allData = viewModel.monthlyAssetData
        let sortedData = allData.sorted { $0[0] < $1[0] } // 按日期排序

        let columnIndex: Int
        switch assetType {
        case "美股": columnIndex = 2
        case "債券": columnIndex = 4
        case "定期定額": columnIndex = 3
        case "台股": columnIndex = 6
        default: columnIndex = 2
        }

        return sortedData.compactMap { dataRow in
            guard dataRow.count > columnIndex,
                  let value = Double(dataRow[columnIndex]) else { return nil }
            return value * 1000 // 轉換為實際金額
        }
    }

    // MARK: - 投資卡片 (正確版本) - 保留作為備用
    private func investmentCard(title: String, value: String, change: String, isPositive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                Text(change)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isPositive ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red)
            }

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)

            HStack(alignment: .bottom, spacing: 1) {
                ForEach(0..<15, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color(.init(red: 0.40, green: 0.62, blue: 0.47, alpha: 0.6)))
                        .frame(width: 2, height: CGFloat(4 + (index % 4) * 3))
                }
            }
            .frame(height: 70)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - 投資卡片行 (iPhone)
    private var investmentCardsRow: some View {
        HStack(spacing: 12) {
            investmentCard(title: "美股", value: viewModel.currentUSStockValue, change: "+12%", isPositive: true)
            investmentCard(title: "債券", value: viewModel.currentBondsValue, change: "+3%", isPositive: true)
        }
    }

    // MARK: - 債券配息卡片 (智能計算版本，根據 PROJECT.md v0.5.1 規範)
    private var simpleBondDividendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("債券每月配息")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("年配息")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text(formatCurrency(calculateYearlyDividend()))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
                }
            }

            // 基於真實數據的動態長條圖
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<12, id: \.self) { index in
                    let monthlyDividends = calculateMonthlyDividends()
                    let maxDividend = monthlyDividends.max() ?? 1
                    let currentDividend = monthlyDividends[index]
                    let hasAmount = currentDividend > 0
                    let height = hasAmount ? CGFloat(15 + (currentDividend / maxDividend) * 16) : CGFloat(4)

                    VStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(hasAmount ?
                                  Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) :
                                  Color.gray.opacity(0.3))
                            .frame(width: 16, height: height)
                        Text("\(index + 1)")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 70)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.clear)
        )
    }

    // MARK: - 配息計算引擎 (根據 PROJECT.md v0.5.1 規範)
    private func calculateMonthlyDividends() -> [Double] {
        var monthlyDividends = Array(repeating: 0.0, count: 12)

        for bondData in bondDataList {
            guard bondData.count > 13 else { continue }
            let paymentMonths = bondData[12] // 配息月份欄位
            let singlePaymentStr = bondData[13] // 單次配息金額

            let months = parsePaymentMonths(paymentMonths)
            let singlePayment = parseNumber(singlePaymentStr)

            for month in months {
                if month >= 1 && month <= 12 {
                    monthlyDividends[month - 1] += singlePayment
                }
            }
        }

        return monthlyDividends
    }

    private func calculateYearlyDividend() -> Double {
        return calculateMonthlyDividends().reduce(0, +)
    }

    // MARK: - 智能格式解析器 (根據 PROJECT.md v0.5.1 規範)
    private func parsePaymentMonths(_ monthString: String) -> [Int] {
        let separators = ["/", ",", "、", "，"]
        var components = [monthString]

        for separator in separators {
            components = components.flatMap { $0.components(separatedBy: separator) }
        }

        return components.compactMap { component in
            let cleanedComponent = component.replacingOccurrences(of: "月", with: "")
                                           .trimmingCharacters(in: .whitespacesAndNewlines)
            return Int(cleanedComponent)
        }.filter { $0 >= 1 && $0 <= 12 }
    }

    private func parseNumber(_ numberString: String) -> Double {
        let cleanedString = numberString.replacingOccurrences(of: ",", with: "")
                                       .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleanedString) ?? 0.0
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    // MARK: - 桌面版主統計卡片 (正確版本)
    private var mainStatsCardForDesktop: some View {
        VStack(spacing: 16) {
            // 頂部區域：總資產 + 右上角整合卡片
            HStack(alignment: .top) {
                // 左側：總資產區域
                VStack(alignment: .leading, spacing: 12) {
                    Text("總資產")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                    Text(viewModel.currentTotalAssets)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))

                    Text("總損益: \(viewModel.currentTotalPnL)")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))

                    // 時間按鈕
                    HStack(spacing: 8) {
                        ForEach(["1D", "7D", "1M", "3M", "1Y"], id: \.self) { period in
                            Button(period) { }
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(period == "1D" ? Color.black : Color.gray.opacity(0.2))
                                .foregroundColor(period == "1D" ? .white : .black)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                // 右上角：整合卡片
                integratedStatsCard
            }

            // 走勢圖 - 簡化版本
            simpleTrendChart
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - 整合統計卡片
    private var integratedStatsCard: some View {
        VStack(spacing: 0) {
            // 上半部：總匯入
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("總匯入")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)))
                    Text(viewModel.currentTotalDeposit)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                }
                Spacer()
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)

            // 下半部：現金 + 總額報酬率
            HStack(spacing: 8) {
                // 現金卡片
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("現金")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(.init(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)))
                        Spacer()
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                    }
                    Text(viewModel.currentCash)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.init(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)))
                )

                // 總額報酬率卡片
                VStack(alignment: .leading, spacing: 2) {
                    Text("總額報酬率")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    Text(viewModel.currentTotalReturnRate)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("較上月")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.8))
                    Text("+1.2%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.init(red: 0.33, green: 0.73, blue: 0.46, alpha: 1.0)),
                                    Color(.init(red: 0.18, green: 0.52, blue: 0.29, alpha: 1.0))
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: 360, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - 真實資料走勢圖
    private var simpleTrendChart: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

            GeometryReader { geometry in
                ZStack {
                    // 走勢填充區域 (只在線條下方) - 添加尺寸檢查
                    if geometry.size.width > 0 && geometry.size.height > 0 {
                        trendFillArea(in: geometry.size)

                        // 真實資料走勢線
                        trendLine(in: geometry.size)
                    }

                    // 標籤
                    trendLabels
                }
            }
        }
        .frame(height: 203)
        .cornerRadius(8)
    }

    // 走勢線路徑
    private func trendLine(in size: CGSize) -> some View {
        Path { path in
            let dataPoints = getTrendDataPoints()
            guard dataPoints.count > 1, size.width > 0, size.height > 0 else { return }

            let width = size.width
            let height = size.height

            // 找出數值範圍用於歸一化
            let minValue = dataPoints.map(\.value).min() ?? 0
            let maxValue = dataPoints.map(\.value).max() ?? 1
            let valueRange = maxValue - minValue

            // 繪製線條
            for (index, point) in dataPoints.enumerated() {
                let x = (CGFloat(index) / CGFloat(dataPoints.count - 1)) * width
                let normalizedValue = valueRange > 0 ? (point.value - minValue) / valueRange : 0.5
                let y = height - (normalizedValue * height * 0.8 + height * 0.1) // 留10%邊距

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(
            Color(.init(red: 0.96, green: 0.45, blue: 0.45, alpha: 0.9)),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
    }

    // 走勢填充區域
    private func trendFillArea(in size: CGSize) -> some View {
        Path { path in
            let dataPoints = getTrendDataPoints()
            guard dataPoints.count > 1, size.width > 0, size.height > 0 else { return }

            let width = size.width
            let height = size.height

            let minValue = dataPoints.map(\.value).min() ?? 0
            let maxValue = dataPoints.map(\.value).max() ?? 1
            let valueRange = maxValue - minValue

            // 開始路徑 (從底部開始)
            path.move(to: CGPoint(x: 0, y: height))

            // 繪製上邊界線
            for (index, point) in dataPoints.enumerated() {
                let x = (CGFloat(index) / CGFloat(dataPoints.count - 1)) * width
                let normalizedValue = valueRange > 0 ? (point.value - minValue) / valueRange : 0.5
                let y = height - (normalizedValue * height * 0.8 + height * 0.1)
                path.addLine(to: CGPoint(x: x, y: y))
            }

            // 回到底部閉合路徑
            path.addLine(to: CGPoint(x: width, y: height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    Color(.init(red: 0.96, green: 0.45, blue: 0.45, alpha: 0.3)),
                    Color(.init(red: 0.96, green: 0.45, blue: 0.45, alpha: 0.02))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // 標籤覆層
    private var trendLabels: some View {
        VStack {
            HStack {
                Spacer()
                Text(getTrendPercentageChange())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.96, green: 0.45, blue: 0.45, alpha: 1.0)))
            }
            Spacer()
            HStack {
                Text("過去資產變化")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding(8)
    }

    // 取得走勢資料點
    private func getTrendDataPoints() -> [(value: Double, date: String)] {
        let allData = viewModel.monthlyAssetData

        // 按日期排序 (最舊的在前) - 使用倒序排列，讓最舊的在前面
        let sortedData = allData.sorted { first, second in
            guard first.count > 0 && second.count > 0 else { return false }
            return first[0] > second[0] // 按日期倒序排列
        }.reversed() // 然後反轉，讓最舊的在前面

        return Array(sortedData).compactMap { dataRow in
            guard dataRow.count > 15,
                  let totalAssets = Double(dataRow[15]) else { return nil }
            return (value: totalAssets * 1000, date: dataRow[0]) // 轉換為實際金額
        }
    }

    // 計算變化百分比
    private func getTrendPercentageChange() -> String {
        let dataPoints = getTrendDataPoints()
        guard dataPoints.count >= 2 else { return "+0.00%" }

        let firstValue = dataPoints.first?.value ?? 0
        let lastValue = dataPoints.last?.value ?? 0

        guard firstValue > 0 else { return "+0.00%" }

        let changePercentage = ((lastValue - firstValue) / firstValue) * 100
        let sign = changePercentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", changePercentage))%"
    }

    // MARK: - 完整新增資產記錄表單
    private var simpleAddDataForm: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 當前客戶區塊
                    VStack(alignment: .leading, spacing: 8) {
                        Text("當前客戶")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                        HStack {
                            Text(viewModel.selectedClient?.name ?? "未選擇客戶")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                            Spacer()
                        }
                        .padding()
                        .background(Color(.init(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)))
                        .cornerRadius(8)
                    }

                    // 選擇日期區塊 - 統一格式
                    HStack {
                        Text("選擇日期")
                            .font(.system(size: 16))
                            .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)

                    // 標籤選擇器
                    HStack(spacing: 0) {
                        tabButton(title: "資產明細", index: 0)
                        tabButton(title: "公司債", index: 1)
                        Spacer()
                    }
                    .background(Color(.init(red: 0.97, green: 0.97, blue: 0.975, alpha: 1.0)))

                    // 根據選擇的標籤顯示不同內容
                    if selectedTab == 0 {
                        // 資產明細標籤內容
                        VStack(spacing: 0) {
                            inputField(title: "現金", text: $formData.cash)
                            inputField(title: "美股", text: $formData.usStock)
                            inputField(title: "定期定額", text: $formData.regularInvestment, placeholder: "定期定額")
                            inputField(title: "債券", text: $formData.bonds)
                            inputField(title: "台股", text: $formData.twStock, placeholder: "台股")
                            inputField(title: "台股折合美金 匯率32", text: $formData.twStockUSD)
                            inputField(title: "結構型商品", text: $formData.structuredProducts)
                            inputField(title: "已領利息", text: $formData.interestReceived)
                            inputField(title: "美股成本", text: $formData.usStockCost)
                            inputField(title: "定期定額成本", text: $formData.regularCost, placeholder: "定期定額成本")
                            inputField(title: "債券成本", text: $formData.bondsCost)
                            inputField(title: "台股成本", text: $formData.twStockCost, placeholder: "台股成本")
                            inputField(title: "匯入", text: $formData.deposit, placeholder: "匯入")
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    } else {
                        // 公司債表單內容
                        VStack(spacing: 0) {
                            // 基本資訊區塊
                            VStack(alignment: .leading, spacing: 0) {
                                Text("基本資訊")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .padding(.bottom, 12)

                                bondInputField(title: "債券名稱", text: $bondFormData.bondName)
                                bondInputField(title: "申購日", text: $bondFormData.tickerSymbol)
                                bondInputField(title: "票面利率", text: $bondFormData.couponRate, placeholder: "5.875 %")
                                bondInputField(title: "殖利率", text: $bondFormData.yieldRate)
                            }

                            // 金額資訊區塊
                            VStack(alignment: .leading, spacing: 0) {
                                Text("金額資訊")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .padding(.bottom, 12)

                                bondInputField(title: "申購價", text: $bondFormData.purchasePrice)
                                bondInputField(title: "持有面額", text: $bondFormData.faceValue)
                                bondInputField(title: "前手息", text: $bondFormData.accruedInterest)
                                bondInputField(title: "申購金額", text: $bondFormData.purchaseAmount)
                                bondInputField(title: "交易金額", text: $bondFormData.tradingAmount)
                                bondInputField(title: "現值", text: $bondFormData.currentValue, placeholder: "現值")
                                bondInputField(title: "已領利息", text: $bondFormData.accruedInterest)
                            }

                            // 配息資訊區塊
                            VStack(alignment: .leading, spacing: 0) {
                                Text("配息資訊")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .padding(.bottom, 12)

                                paymentMonthsPicker(title: "配息月份", selection: $bondFormData.paymentMonths)
                                bondInputField(title: "單次配息", text: $bondFormData.singlePayment)
                                bondInputField(title: "年度配息", text: $bondFormData.annualPayment)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                }
                .padding()
            }
            .background(Color(.init(red: 0.97, green: 0.97, blue: 0.975, alpha: 1.0)))
            .navigationTitle("新增資產記錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingAddForm = false
                    }
                    .foregroundColor(.blue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveFormData()
                        showingAddForm = false
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - 公司債明細表格
    private var bondDetailTable: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isBondTableExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "building.columns")
                            .font(.system(size: 14))
                        Text("公司債明細")
                            .font(.system(size: 16, weight: .semibold))

                        Text("（\(bondDataList.count)筆）")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        Image(systemName: isBondTableExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                    }
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                }

                Spacer()

                Button("編輯欄位") { }
                    .font(.system(size: 12))
                    .foregroundColor(.blue)

                Button("查看詳細") { }
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }

            // 可展開/折疊的表格內容
            if isBondTableExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 表頭
                        HStack(spacing: 8) {
                            tableHeaderCell("申購日", width: 70)
                            tableHeaderCell("名稱", width: 80)
                            tableHeaderCell("票面利率", width: 70)
                            tableHeaderCell("殖利率", width: 60)
                            tableHeaderCell("申購價", width: 60)
                            tableHeaderCell("申購金額", width: 80)
                            tableHeaderCell("持有面額", width: 80)
                            tableHeaderCell("交易金額", width: 80)
                            tableHeaderCell("現值", width: 60)
                            tableHeaderCell("已領利息", width: 80)
                            tableHeaderCell("含息損益", width: 80)
                            tableHeaderCell("報酬率", width: 70)
                            tableHeaderCell("配息月份", width: 80)
                            tableHeaderCell("單次配息", width: 80)
                            tableHeaderCell("年度配息", width: 80)
                        }
                        .padding(.horizontal, 8)

                        // 分隔線
                        Rectangle()
                            .fill(Color(.init(red: 0.92, green: 0.92, blue: 0.93, alpha: 1.0)))
                            .frame(height: 1)
                            .padding(.vertical, 6)

                        // 預留位置顯示
                        VStack {
                            Image(systemName: "building.columns")
                                .font(.system(size: 24))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("尚無公司債資料")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding(20)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - 輸入欄位組件 (簡潔水平佈局版)
    private func inputField(title: String, text: Binding<String>, placeholder: String? = nil, fullWidth: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField(placeholder ?? title, text: text)
                .font(.system(size: 16))
                .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(.init(red: 0.92, green: 0.92, blue: 0.93, alpha: 1.0)))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - 公司債輸入欄位
    private func bondInputField(title: String, text: Binding<String>, placeholder: String? = nil) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField(placeholder ?? title, text: text)
                .font(.system(size: 16))
                .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(.init(red: 0.92, green: 0.92, blue: 0.93, alpha: 1.0)))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - 配息月份選擇器
    private func paymentMonthsPicker(title: String, selection: Binding<String>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("", selection: selection) {
                Text("1月/7月").tag("1月7月")
                Text("2月/8月").tag("2月8月")
                Text("3月/9月").tag("3月9月")
                Text("4月/10月").tag("4月10月")
                Text("5月/11月").tag("5月11月")
                Text("6月/12月").tag("6月12月")
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(.init(red: 0.92, green: 0.92, blue: 0.93, alpha: 1.0)))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - 標籤按鈕組件
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: {
            selectedTab = index
        }) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(selectedTab == index ? .black : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedTab == index ? Color.white : Color.clear)
                        .shadow(color: selectedTab == index ? Color.black.opacity(0.08) : Color.clear, radius: 4, x: 0, y: 2)
                )
        }
    }

    // MARK: - 表格輔助函數
    private func tableHeaderCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(Color(.init(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)))
            .frame(width: width, alignment: .center)
    }

    private func tableDataCell(_ text: String, width: CGFloat, isBold: Bool = false) -> some View {
        Text(formatNumberString(text))
            .font(.system(size: 11, weight: isBold ? .semibold : .regular))
            .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
            .frame(width: width, alignment: .center)
    }

    // MARK: - 數字格式化輔助函數
    private func formatNumberString(_ text: String) -> String {
        // 如果是日期格式 (包含 "-") 或非純數字，直接返回原文字
        if text.contains("-") || text.isEmpty || text == "0" {
            return text
        }

        // 嘗試轉換為數字並格式化
        let cleanedText = text.replacingOccurrences(of: ",", with: "")
        if let number = Double(cleanedText) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: number)) ?? text
        }

        return text
    }

    // MARK: - 保存表單資料函數
    private func saveFormData() {
        if selectedTab == 0 {
            // 保存資產明細數據
            saveAssetData()
        } else {
            // 保存公司債數據
            saveBondData()
        }
    }

    private func saveAssetData() {
        guard let selectedClient = viewModel.selectedClient else {
            return
        }

        // 格式化選擇的日期為 Sep-09 格式
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd"
        let dateString = formatter.string(from: selectedDate)

        // 計算總資產
        let cash = Double(formData.cash.replacingOccurrences(of: ",", with: "")) ?? 0
        let usStock = Double(formData.usStock.replacingOccurrences(of: ",", with: "")) ?? 0
        let bonds = Double(formData.bonds.replacingOccurrences(of: ",", with: "")) ?? 0
        let structuredProducts = Double(formData.structuredProducts.replacingOccurrences(of: ",", with: "")) ?? 0
        let interestReceived = Double(formData.interestReceived.replacingOccurrences(of: ",", with: "")) ?? 0
        let regularInvestment = Double(formData.regularInvestment.replacingOccurrences(of: ",", with: "")) ?? 0
        let twStock = Double(formData.twStock.replacingOccurrences(of: ",", with: "")) ?? 0
        let twStockUSD = Double(formData.twStockUSD.replacingOccurrences(of: ",", with: "")) ?? 0
        let deposit = Double(formData.deposit.replacingOccurrences(of: ",", with: "")) ?? 0
        let usStockCost = Double(formData.usStockCost.replacingOccurrences(of: ",", with: "")) ?? 0
        let regularCost = Double(formData.regularCost.replacingOccurrences(of: ",", with: "")) ?? 0
        let bondsCost = Double(formData.bondsCost.replacingOccurrences(of: ",", with: "")) ?? 0
        let twStockCost = Double(formData.twStockCost.replacingOccurrences(of: ",", with: "")) ?? 0

        // 創建 MonthlyAssetRecord
        let newRecord = MonthlyAssetRecord(
            clientID: selectedClient.id,
            date: selectedDate,
            cash: cash,
            usStock: usStock,
            regularInvestment: regularInvestment,
            bonds: bonds,
            structuredProducts: structuredProducts,
            twStock: twStock,
            twStockConverted: twStockUSD,
            confirmedInterest: interestReceived,
            deposit: deposit,
            cashCost: usStockCost,
            stockCost: usStockCost,
            bondCost: bondsCost,
            otherCost: 0,
            notes: "新增記錄"
        )

        // 儲存到 CloudKit (不再使用本地儲存)
        Task {
            await viewModel.addMonthlyAssetRecord(newRecord)
        }

        // 同時更新 monthlyAssetData 用於即時顯示
        let newDataArray: [String] = [
            dateString, // 日期
            String(format: "%.0f", cash / 1000), // 現金 (轉為千為單位)
            String(format: "%.0f", usStock / 1000), // 美股
            String(format: "%.0f", regularInvestment / 1000), // 定期定額
            String(format: "%.0f", bonds / 1000), // 債券
            String(format: "%.0f", structuredProducts / 1000), // 結構型商品
            String(format: "%.0f", twStock / 1000), // 台股
            String(format: "%.0f", twStockUSD / 1000), // 台股折合
            String(format: "%.0f", interestReceived / 1000), // 已領利息
            String(format: "%.0f", deposit / 1000), // 匯入
            String(format: "%.0f", usStockCost / 1000), // 美股成本
            String(format: "%.0f", regularCost / 1000), // 定期成本
            String(format: "%.0f", bondsCost / 1000), // 債券成本
            String(format: "%.0f", twStockCost / 1000), // 台股成本
            "新增記錄", // 備註
            String(format: "%.0f", (cash + usStock + bonds + structuredProducts + interestReceived + regularInvestment + twStock) / 1000) // 總資產 (轉為千為單位)
        ]

        // 將新資料加入到 ViewModel
        viewModel.monthlyAssetData.insert(newDataArray, at: 0)
    }

    // MARK: - 保存公司債數據
    private func saveBondData() {
        // 創建公司債數據陣列，對應公司債明細表格的各個欄位
        let newBondData: [String] = [
            bondFormData.bondName,                    // 0: 債券名稱
            bondFormData.tickerSymbol,                // 1: 申購日
            bondFormData.purchasePrice,               // 2: 申購價
            bondFormData.faceValue,                   // 3: 持有面額
            bondFormData.quantity,                    // 4: 數量
            bondFormData.purchaseAmount,              // 5: 申購金額
            bondFormData.tradingAmount,               // 6: 交易金額
            bondFormData.currentValue,                // 7: 現值
            bondFormData.accruedInterest,             // 8: 已領利息
            bondFormData.yieldRate,                   // 9: 殖利率
            bondFormData.couponRate,                  // 10: 票面利率
            "",                                       // 11: 預留欄位
            bondFormData.paymentMonths,               // 12: 配息月份
            bondFormData.singlePayment,               // 13: 單次配息
            bondFormData.annualPayment                // 14: 年度配息
        ]

        // 將新的公司債數據加入到 bondDataList
        bondDataList.append(newBondData)

        // 智能預填功能（根據PROJECT.md v0.4.8規範）
        // 保留所有數值欄位，只清空債券名稱
        let savedTickerSymbol = bondFormData.tickerSymbol
        let savedPurchasePrice = bondFormData.purchasePrice
        let savedFaceValue = bondFormData.faceValue
        let savedQuantity = bondFormData.quantity
        let savedPurchaseAmount = bondFormData.purchaseAmount
        let savedTradingAmount = bondFormData.tradingAmount
        let savedCurrentValue = bondFormData.currentValue
        let savedAccruedInterest = bondFormData.accruedInterest
        let savedYieldRate = bondFormData.yieldRate
        let savedCouponRate = bondFormData.couponRate
        let savedPaymentMonths = bondFormData.paymentMonths
        let savedSinglePayment = bondFormData.singlePayment
        let savedAnnualPayment = bondFormData.annualPayment

        bondFormData = BondFormData()
        // 恢復所有數值欄位，只有債券名稱會被清空
        bondFormData.tickerSymbol = savedTickerSymbol
        bondFormData.purchasePrice = savedPurchasePrice
        bondFormData.faceValue = savedFaceValue
        bondFormData.quantity = savedQuantity
        bondFormData.purchaseAmount = savedPurchaseAmount
        bondFormData.tradingAmount = savedTradingAmount
        bondFormData.currentValue = savedCurrentValue
        bondFormData.accruedInterest = savedAccruedInterest
        bondFormData.yieldRate = savedYieldRate
        bondFormData.couponRate = savedCouponRate
        bondFormData.paymentMonths = savedPaymentMonths
        bondFormData.singlePayment = savedSinglePayment
        bondFormData.annualPayment = savedAnnualPayment
    }

    // MARK: - 表單數據結構
    struct AssetFormData {
        var cash: String = "3,264,395"
        var usStock: String = "3,596,018"
        var regularInvestment: String = ""
        var bonds: String = "2,739,362"
        var twStock: String = ""
        var twStockUSD: String = "0"
        var structuredProducts: String = "400,000"
        var interestReceived: String = "164,048"
        var usStockCost: String = "3,056,265"
        var regularCost: String = ""
        var bondsCost: String = "2,906,035"
        var twStockCost: String = ""
        var deposit: String = ""
    }

    // MARK: - 公司債表單數據結構
    struct BondFormData {
        var bondName: String = ""
        var tickerSymbol: String = ""
        var purchasePrice: String = ""
        var faceValue: String = ""
        var quantity: String = ""
        var purchaseAmount: String = ""
        var tradingAmount: String = ""
        var currentValue: String = ""
        var accruedInterest: String = ""
        var yieldRate: String = ""
        var couponRate: String = ""
        var paymentMonths: String = "1月7月"
        var singlePayment: String = ""
        var annualPayment: String = ""
    }
}

// MARK: - 新增客戶表單
struct AddClientFormView: View {
    @EnvironmentObject var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Form {
                Section("客戶資訊") {
                    TextField("姓名", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                // 錯誤訊息顯示
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                // 載入狀態顯示
                if isLoading {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在保存...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // iCloud狀態顯示
                Section("iCloud狀態") {
                    HStack {
                        Image(systemName: viewModel.isSignedInToiCloud ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.isSignedInToiCloud ? .green : .red)
                        Text(viewModel.statusDescription)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("新增客戶")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        Task {
                            print("🔥🔥🔥 儲存按鈕被點擊了！🔥🔥🔥")
                            print("🔄 開始保存客戶：\(name), email: \(email)")
                            print("📱 iCloud狀態：\(viewModel.isSignedInToiCloud ? "已登入" : "未登入")")
                            print("👥 目前客戶數量：\(viewModel.clients.count)")

                            isLoading = true
                            viewModel.errorMessage = nil // 清除之前的錯誤訊息

                            await viewModel.addClient(name: name, email: email)
                            isLoading = false
                            print("✅ addClient 呼叫完成")

                            if viewModel.errorMessage == nil {
                                print("✅ 客戶保存成功，關閉表單")
                                dismiss()
                            } else {
                                print("❌ 客戶保存失敗：\(viewModel.errorMessage ?? "未知錯誤")")
                            }
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
        .onAppear {
            // 清除之前的錯誤訊息
            viewModel.errorMessage = nil
            print("📝 新增客戶表單已顯示")
        }
    }
}

// MARK: - 編輯客戶表單
struct EditClientFormView: View {
    @EnvironmentObject var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Form {
                Section("客戶資訊") {
                    TextField("姓名", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("編輯客戶")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("更新") {
                        Task {
                            isLoading = true
                            await viewModel.updateClient(name: name, email: email)
                            isLoading = false
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
        .onAppear {
            if let editingClient = viewModel.editingClient {
                name = editingClient.name
                email = editingClient.email
            }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
