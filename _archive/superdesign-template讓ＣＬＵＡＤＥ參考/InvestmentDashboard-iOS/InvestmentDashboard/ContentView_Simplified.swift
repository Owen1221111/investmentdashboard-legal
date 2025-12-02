import SwiftUI

// MARK: - 主要內容視圖 (App的根視圖)
struct ContentView: View {
    @StateObject private var viewModel = ClientViewModel()
    @State private var showingAddForm = false

    // 表格展開狀態
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

    var body: some View {
        GeometryReader { geometry in
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadLayout(geometry: geometry)
            } else {
                iPhoneLayout
            }
        }
        .background(Color(.init(red: 0.97, green: 0.97, blue: 0.975, alpha: 1.0)))
        .onAppear {
            loadSampleBondData()
            loadSampleStructuredProducts()
        }
    }

    // MARK: - iPad 佈局
    private func iPadLayout(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 24) {
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
        .padding(.bottom, 20)
    }

    // MARK: - 主要統計卡片
    private var mainStatsCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("總資產")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                Text(viewModel.currentTotalAssets)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))

                Text("總損益: \(viewModel.currentTotalPnL)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - 資產配置卡片
    private var assetAllocationCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("資產配置")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - 月度資產明細表格
    private var monthlyAssetDetailTable: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isAssetTableExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                        Text("月度資產明細")
                            .font(.system(size: 18, weight: .semibold))

                        if !viewModel.monthlyAssetData.isEmpty {
                            Text("（\(viewModel.monthlyAssetData.count)筆）")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Image(systemName: isAssetTableExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Button(action: {
                    showingMonthlyForm = true
                    isEditingMode = false
                    selectedMonthlyRecord = nil
                }) {
                    Text("新增")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }

            if isAssetTableExpanded {
                Text("月度資產明細表格內容")
                    .padding()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
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
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 14))
                        Text("公司債明細")
                            .font(.system(size: 18, weight: .semibold))

                        if !bondRecords.isEmpty {
                            Text("（\(bondRecords.count)筆）")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Image(systemName: isBondTableExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Button(action: {
                    showingBondForm = true
                    isEditingMode = false
                    selectedBondRecord = nil
                }) {
                    Text("新增")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }

            if isBondTableExpanded {
                Text("公司債明細表格內容")
                    .padding()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - 結構型明細表格
    private var structuredProductsDetailTable: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isStructuredTableExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 14))
                        Text("結構型明細")
                            .font(.system(size: 18, weight: .semibold))

                        if !structuredProducts.isEmpty {
                            Text("（\(structuredProducts.count)筆）")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Image(systemName: isStructuredTableExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()
            }

            if isStructuredTableExpanded {
                VStack(spacing: 16) {
                    // 進行中區塊
                    ongoingStructuredProductsSection

                    // 已出場區塊
                    exitedStructuredProductsSection
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            loadSampleStructuredProducts()
        }
        .sheet(isPresented: $showingExitForm) {
            if let selectedProduct = selectedProductToExit {
                ExitStructuredProductForm(
                    isPresented: $showingExitForm,
                    product: selectedProduct,
                    onExit: { exitedProduct in
                        handleProductExit(exitedProduct)
                    }
                )
            }
        }
    }

    // MARK: - 進行中結構型商品區塊
    private var ongoingStructuredProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("進行中")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                Spacer()
                Text("\(ongoingProducts.count) 筆")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            if ongoingProducts.isEmpty {
                Text("目前沒有進行中的結構型商品")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    LazyHStack(spacing: 12) {
                        ForEach(ongoingProducts) { product in
                            structuredProductCard(product: product, isOngoing: true)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    // MARK: - 已出場結構型商品區塊
    private var exitedStructuredProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)

            HStack {
                Text("已出場")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                Spacer()
                Text("\(exitedProducts.count) 筆")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            if exitedProducts.isEmpty {
                Text("目前沒有已出場的結構型商品")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    LazyHStack(spacing: 12) {
                        ForEach(exitedProducts) { product in
                            structuredProductCard(product: product, isOngoing: false)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    private func structuredProductCard(product: StructuredProduct, isOngoing: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(product.target)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                Spacer()
                if isOngoing {
                    Button("出場") {
                        selectedProductToExit = product
                        showingExitForm = true
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("本金: \(formatStructuredCurrency(product.tradeAmount))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text("發行日: \(DateFormatter.structuredDate.string(from: product.executionDate))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                if let exitDate = product.exitDate {
                    Text("出場日: \(DateFormatter.structuredDate.string(from: exitDate))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                if let actualReturn = product.actualReturn {
                    Text("實際收益: \(formatStructuredCurrency(actualReturn))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(actualReturn >= 0 ? .green : .red)
                }
            }

            if !product.notes.isEmpty {
                Text(product.notes)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .frame(width: 200)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.98, green: 0.98, blue: 0.99, opacity: 1.0))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - 結構型商品輔助函數
    private var ongoingProducts: [StructuredProduct] {
        structuredProducts.filter { $0.status == .ongoing }
    }

    private var exitedProducts: [StructuredProduct] {
        structuredProducts.filter { $0.status == .exited }
    }

    private func loadSampleStructuredProducts() {
        let sampleClientID = UUID()
        var allProducts: [StructuredProduct] = []
        allProducts.append(contentsOf: StructuredProduct.sampleOngoingProducts(for: sampleClientID))
        allProducts.append(contentsOf: StructuredProduct.sampleExitedProducts(for: sampleClientID))
        self.structuredProducts = allProducts
    }

    private func handleProductExit(_ exitedProduct: StructuredProduct) {
        if let index = structuredProducts.firstIndex(where: { $0.id == exitedProduct.id }) {
            structuredProducts[index] = exitedProduct
        }
        selectedProductToExit = nil
    }

    private func formatStructuredCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func loadSampleBondData() {
        // 簡化的範例債券資料
        let sampleBonds = [
            BondRecord(
                id: UUID(),
                issuer: "台積電",
                issueDate: Date(),
                maturityDate: Calendar.current.date(byAdding: .year, value: 3, to: Date()) ?? Date(),
                couponRate: 2.5,
                faceValue: 1000000,
                purchasePrice: 980000,
                currentValue: 1020000,
                notes: "範例債券"
            )
        ]
        self.bondRecords = sampleBonds
    }
}

// MARK: - 債券記錄模型
struct BondRecord: Identifiable, Codable {
    let id: UUID
    let issuer: String
    let issueDate: Date
    let maturityDate: Date
    let couponRate: Double
    let faceValue: Double
    let purchasePrice: Double
    let currentValue: Double
    let notes: String
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let structuredDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d"
        return formatter
    }()
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
