import SwiftUI
import UniformTypeIdentifiers

struct MonthlyAssetTableView: View {
    @State private var selectedTab = 0
    @State private var showingImportOptions = false
    @State private var showingFileImporter = false
    @State private var structuredProducts: [StructuredProduct] = []
    @State private var showingExitForm = false
    @State private var selectedProductToExit: StructuredProduct?

    private let tabs = ["月度資產", "公司債", "損益表"]
    let monthlyData: [[String]]
    let bondData: [[String]]
    
    init(monthlyData: [[String]] = [], bondData: [[String]] = []) {
        self.monthlyData = monthlyData.isEmpty ? defaultMonthlyAssetData : monthlyData
        self.bondData = bondData.isEmpty ? defaultBondData : bondData
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 主要表格容器
            VStack(spacing: 0) {
                // 標籤切換
                tabHeader

                // 工具列
                toolBar

                // 表格內容
                TabView(selection: $selectedTab) {
                    // 月度資產明細
                    monthlyAssetTable
                        .tag(0)

                    // 公司債明細
                    corporateBondsTable
                        .tag(1)

                    // 損益表
                    pnlTable
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)

            // 結構型明細獨立區塊
            structuredProductsSection
        }
        .confirmationDialog("匯入資料", isPresented: $showingImportOptions, titleVisibility: .visible) {
            Button("從 CSV 檔案匯入") {
                print("選擇了 CSV 檔案匯入")
                showingFileImporter = true
            }
            Button("手動新增資料") {
                print("選擇了手動新增資料")
                handleManualDataEntry()
            }
            Button("取消", role: .cancel) {
                print("取消了匯入操作")
            }
        } message: {
            Text("選擇匯入方式")
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.commaSeparatedText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
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
    
    // MARK: - 標籤切換
    private var tabHeader: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 0) {
                        Text(tabs[index])
                            .font(.system(size: 14, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundColor(selectedTab == index ? Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)) : Color.gray)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)) : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            Spacer()
        }
        .background(
            VStack {
                Spacer()
                Divider()
            }
        )
    }
    
    // MARK: - 工具列
    private var toolBar: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                Text(getTableTitle())
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    print("匯入按鈕被點擊了！")
                    showingImportOptions = true
                }) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 14))
                        .foregroundColor(.blue) // 改為藍色以便識別
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle()) // 確保按鈕樣式正確
                
                Button(action: {}) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            VStack {
                Spacer()
                Divider()
            }
        )
    }
    
    private func getTableTitle() -> String {
        switch selectedTab {
        case 0: return "月度資產明細"
        case 1: return "公司債明細"
        case 2: return "損益表"
        default: return "月度資產明細"
        }
    }
    
    // MARK: - 月度資產明細表格 (修復滾動同步)
    private var monthlyAssetTable: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                // 表頭 - 固定在頂部
                HStack(spacing: 0) {
                    ForEach(monthlyAssetHeaders, id: \.self) { header in
                        Text(header)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .frame(minWidth: getColumnWidth(for: header), alignment: .leading)
                    }
                }
                .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))
                
                // 分隔線
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                
                // 資料行容器 - 可垂直滾動
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(monthlyData.indices, id: \.self) { index in
                            HStack(spacing: 0) {
                                ForEach(Array(monthlyData[index].enumerated()), id: \.offset) { colIndex, value in
                                    Text(formatNumberString(value))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getColumnWidth(for: monthlyAssetHeaders[colIndex]), alignment: .leading)
                                }
                            }
                            .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.02))
                            .overlay(
                                VStack {
                                    Spacer()
                                    Divider()
                                        .opacity(0.3)
                                }
                            )
                        }
                    }
                }
                .frame(maxHeight: 200) // 限制高度，讓表格可垂直滾動
            }
        }
    }
    
    // MARK: - 公司債明細表格
    private var corporateBondsTable: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0) {
                // 表頭
                HStack(spacing: 0) {
                    ForEach(bondHeaders, id: \.self) { header in
                        Text(header)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .frame(minWidth: getBondColumnWidth(for: header), alignment: .leading)
                    }
                }
                .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))
                
                // 資料行
                ForEach(bondData.indices, id: \.self) { index in
                    HStack(spacing: 0) {
                        ForEach(Array(bondData[index].enumerated()), id: \.offset) { colIndex, value in
                            Text(value)
                                .font(.system(size: 12))
                                .foregroundColor(
                                    value.contains("+") ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) :
                                    value.contains("-") ? Color(.init(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)) :
                                    Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0))
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 10)
                                .frame(minWidth: getBondColumnWidth(for: bondHeaders[colIndex]), alignment: .leading)
                        }
                    }
                    .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.02))
                    .overlay(
                        VStack {
                            Spacer()
                            Divider()
                                .opacity(0.3)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - 損益表
    private var pnlTable: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0) {
                // 表頭
                HStack(spacing: 0) {
                    ForEach(pnlHeaders, id: \.self) { header in
                        Text(header)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .frame(minWidth: 100, alignment: .leading)
                    }
                }
                .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))
                
                // 資料行
                ForEach(pnlData.indices, id: \.self) { index in
                    HStack(spacing: 0) {
                        ForEach(Array(pnlData[index].enumerated()), id: \.offset) { colIndex, value in
                            Text(value)
                                .font(.system(size: 13))
                                .foregroundColor(
                                    value.contains("+") ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) :
                                    Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0))
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .frame(minWidth: 100, alignment: .leading)
                        }
                    }
                    .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.02))
                    .overlay(
                        VStack {
                            Spacer()
                            Divider()
                                .opacity(0.3)
                        }
                    )
                }
            }
        }
    }

    // MARK: - 結構型明細獨立區塊
    private var structuredProductsSection: some View {
        VStack(spacing: 0) {
            // 區塊標題
            structuredProductsHeader

            // 進行中區塊
            ongoingProductsSection

            // 分隔線
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 8)

            // 已出場區塊
            exitedProductsSection
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // 結構型明細標題
    private var structuredProductsHeader: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14))
                    Text("結構型明細")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))

                Spacer()

                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        print("結構型商品匯入按鈕被點擊了！")
                        showingImportOptions = true
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {}) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Button(action: {}) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
        }
    }

    private var ongoingProductsSection: some View {
        VStack(spacing: 0) {
            // 進行中標題
            HStack {
                Text("進行中")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    // 表頭
                    HStack(spacing: 0) {
                        ForEach(ongoingHeaders, id: \.self) { header in
                            Text(header)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                                .frame(minWidth: getStructuredColumnWidth(for: header), alignment: .leading)
                        }
                    }
                    .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

                    // 資料行
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(ongoingProducts) { product in
                                HStack(spacing: 0) {
                                    // 交易定價日
                                    Text(DateFormatter.shortDate.string(from: product.tradeDate))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "交易定價日"), alignment: .leading)

                                    // 標的
                                    Text(product.target)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "標的"), alignment: .leading)

                                    // 發行日
                                    Text(DateFormatter.shortDate.string(from: product.executionDate))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "發行日"), alignment: .leading)

                                    // 最終評價日
                                    Text(DateFormatter.shortDate.string(from: product.latestEvaluationDate))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "最終評價日"), alignment: .leading)

                                    // 期間價格
                                    Text(formatCurrency(product.periodPrice))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "期間價格"), alignment: .leading)

                                    // 執行價格
                                    Text(formatCurrency(product.executionPrice))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "執行價格"), alignment: .leading)

                                    // 敲出障礙
                                    Text(formatCurrency(product.knockOutBarrier))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "敲出障礙"), alignment: .leading)

                                    // 敲入障礙
                                    Text(formatCurrency(product.knockInBarrier))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "敲入障礙"), alignment: .leading)

                                    // 利率
                                    Text(formatPercentage(product.yield))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "利率"), alignment: .leading)

                                    // 月利率
                                    Text(formatPercentage(product.monthlyYield))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "月利率"), alignment: .leading)

                                    // 交易金額
                                    Text(formatCurrency(product.tradeAmount))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "交易金額"), alignment: .leading)

                                    // 備註
                                    Text(product.notes)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "備註"), alignment: .leading)

                                    // 操作按鈕
                                    Button("出場") {
                                        selectedProductToExit = product
                                        showingExitForm = true
                                    }
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red)
                                    .cornerRadius(4)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 10)
                                    .frame(minWidth: getStructuredColumnWidth(for: "操作"), alignment: .center)
                                }
                                .background(structuredProducts.firstIndex(of: product)! % 2 == 0 ? Color.clear : Color.gray.opacity(0.02))
                                .overlay(
                                    VStack {
                                        Spacer()
                                        Divider()
                                            .opacity(0.3)
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
            }
        }
    }

    private var exitedProductsSection: some View {
        VStack(spacing: 0) {
            // 已出場標題
            HStack {
                Text("已出場")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    // 表頭
                    HStack(spacing: 0) {
                        ForEach(exitedHeaders, id: \.self) { header in
                            Text(header)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                                .frame(minWidth: getStructuredColumnWidth(for: header), alignment: .leading)
                        }
                    }
                    .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))

                    // 資料行
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(exitedProducts) { product in
                                HStack(spacing: 0) {
                                    // 交易定價日
                                    Text(DateFormatter.shortDate.string(from: product.tradeDate))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "交易定價日"), alignment: .leading)

                                    // 標的
                                    Text(product.target)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "標的"), alignment: .leading)

                                    // 發行日
                                    Text(DateFormatter.shortDate.string(from: product.executionDate))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "發行日"), alignment: .leading)

                                    // 最終評價日
                                    Text(DateFormatter.shortDate.string(from: product.latestEvaluationDate))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "最終評價日"), alignment: .leading)

                                    // 利率
                                    Text(formatPercentage(product.yield))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "利率"), alignment: .leading)

                                    // 月利率
                                    Text(formatPercentage(product.monthlyYield))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "月利率"), alignment: .leading)

                                    // 出場日
                                    Text(product.exitDate != nil ? DateFormatter.shortDate.string(from: product.exitDate!) : "-")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "出場日"), alignment: .leading)

                                    // 持有月
                                    Text("\(product.holdingMonths ?? 0)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "持有月"), alignment: .leading)

                                    // 實際收益率
                                    Text(formatPercentage(product.actualYield ?? 0))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "實際收益率"), alignment: .leading)

                                    // 交易金額
                                    Text(formatCurrency(product.tradeAmount))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "交易金額"), alignment: .leading)

                                    // 實際收益
                                    Text(formatCurrency(product.actualReturn ?? 0))
                                        .font(.system(size: 12))
                                        .foregroundColor(
                                            (product.actualReturn ?? 0) >= 0 ?
                                            Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) :
                                            Color(.init(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0))
                                        )
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "實際收益"), alignment: .leading)

                                    // 備註
                                    Text(product.notes)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: getStructuredColumnWidth(for: "備註"), alignment: .leading)
                                }
                                .background(exitedProducts.firstIndex(of: product)! % 2 == 0 ? Color.clear : Color.gray.opacity(0.02))
                                .overlay(
                                    VStack {
                                        Spacer()
                                        Divider()
                                            .opacity(0.3)
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
            }
        }
    }

    // MARK: - 資料和輔助函數
    private let monthlyAssetHeaders = [
        "日期", "現金", "美股", "定期定額", "債券", "結構型商品", 
        "台股", "台股折合", "已確利息", "匯入", "美股成本", "定期定額成本", 
        "債券成本", "台股成本", "備註", "總資產"
    ]
    
    private let defaultMonthlyAssetData = [
        ["Sep-10", "2005", "6317.80", "10115.02", "15400.67", "215408.5", "0.0", "186501.0", "5703.15695", "13952.5", "6000.00", "9800.00", "15000.00", "0.0", "最新記錄", "260945.97"],
        ["Aug-08", "2105", "6420.15", "10205.30", "15500.20", "218500.0", "0.0", "187200.0", "5750.25", "14000.0", "6100.00", "9900.00", "15100.00", "0.0", "八月記錄", "264661.40"],
        ["Aug-09", "2200", "6525.30", "10295.75", "15600.85", "220000.0", "0.0", "188000.0", "5800.50", "14150.0", "6200.00", "10000.00", "15200.00", "0.0", "備註", "268372.70"]
    ]
    
    private let bondHeaders = [
        "申購日", "債券名稱", "票面利率", "殖利率", "申購價", "持有面額", 
        "前手息", "申購金額", "交易金額", "現值", "已領利息", "報酬率", 
        "配息月份", "單次配息", "年度配息"
    ]
    
    private let defaultBondData = [
        ["Mar-6", "2030債券", "5.2%", "2.34%", "100.00", "200,000", "1,500", "200,000", "201,500", "200,000.00", "3,104.0", "+7.84%", "3月/9月", "5,200", "10,400"],
        ["Apr-15", "2028債券", "4.8%", "3.1%", "102.50", "150,000", "800", "153,750", "154,550", "151,200.00", "2,400.0", "-0.1%", "4月/10月", "3,600", "7,200"],
        ["Jun-20", "2032債券", "6.0%", "2.8%", "98.75", "300,000", "2,200", "296,250", "298,450", "305,400.00", "4,500.0", "+4.61%", "6月/12月", "9,000", "18,000"]
    ]
    
    private let pnlHeaders = ["交易日期", "資產", "買入價格", "賣出價格", "損益", "手續費"]
    
    private let pnlData = [
        ["2024/12/01", "AAPL", "150.00", "165.50", "+15.50", "2.50"],
        ["2024/11/28", "MSFT", "280.00", "275.20", "-4.80", "2.50"],
        ["2024/11/25", "GOOGL", "132.50", "138.75", "+6.25", "2.50"]
    ]
    
    private func getColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "日期": return 70
        case "現金", "美股", "債券": return 80
        case "結構型商品": return 100
        case "台股折合", "已確利息": return 90
        case "美股成本", "定期定額成本", "債券成本", "台股成本": return 85
        case "備註": return 120
        case "總資產": return 100
        default: return 80
        }
    }
    
    // 數字格式化函數 (添加千分位分隔符)
    private func formatNumberString(_ value: String) -> String {
        // 檢查是否為純數字
        guard let doubleValue = Double(value), 
              !value.contains("-") || value.hasPrefix("-"),
              !value.contains("%"),
              !value.isEmpty else {
            return value // 非數字內容直接返回
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: doubleValue)) ?? value
    }
    
    private func getBondColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "申購日": return 70
        case "債券名稱": return 100
        case "票面利率", "殖利率", "報酬率": return 70
        case "申購價": return 70
        case "持有面額", "申購金額", "交易金額", "現值": return 90
        case "前手息", "已領利息", "單次配息", "年度配息": return 80
        case "配息月份": return 90
        default: return 80
        }
    }

    // MARK: - 匯入功能處理
    private func handleManualDataEntry() {
        print("開啟手動新增資料表單")
        print("當前選中的標籤：\(selectedTab)")
        // TODO: 實作手動新增資料的功能
        // 可以開啟 AddDataFormView 或類似的表單
    }

    private func handleFileImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("成功選擇檔案：\(url)")
            importCSVFile(from: url)
        case .failure(let error):
            print("檔案選擇失敗：\(error.localizedDescription)")
        }
    }

    private func importCSVFile(from url: URL) {
        do {
            // 讀取文件內容
            let content = try String(contentsOf: url)
            let lines = content.components(separatedBy: .newlines)

            // 根據當前選中的標籤決定匯入到哪個表格
            switch selectedTab {
            case 0: // 月度資產
                print("匯入月度資產資料")
                parseMonthlyAssetCSV(lines: lines)
            case 1: // 公司債
                print("匯入公司債資料")
                parseBondCSV(lines: lines)
            case 2: // 損益表
                print("匯入損益表資料")
                parsePnLCSV(lines: lines)
            default:
                break
            }

        } catch {
            print("讀取 CSV 檔案失敗：\(error.localizedDescription)")
        }
    }

    private func parseMonthlyAssetCSV(lines: [String]) {
        print("解析月度資產 CSV 資料")
        // TODO: 實作 CSV 解析邏輯
        // 這裡應該將解析的資料更新到 monthlyData
        for line in lines.prefix(3) { // 只顯示前3行作為示例
            print("月度資產行：\(line)")
        }
    }

    private func parseBondCSV(lines: [String]) {
        print("解析公司債 CSV 資料")
        // TODO: 實作 CSV 解析邏輯
        // 這裡應該將解析的資料更新到 bondData
        for line in lines.prefix(3) { // 只顯示前3行作為示例
            print("公司債行：\(line)")
        }
    }

    private func parsePnLCSV(lines: [String]) {
        print("解析損益表 CSV 資料")
        // TODO: 實作 CSV 解析邏輯
        for line in lines.prefix(3) { // 只顯示前3行作為示例
            print("損益表行：\(line)")
        }
    }

    // MARK: - 結構型商品相關資料和函數
    private let ongoingHeaders = [
        "交易定價日", "標的", "發行日", "最終評價日", "期間價格", "執行價格",
        "敲出障礙", "敲入障礙", "利率", "月利率", "交易金額", "備註", "操作"
    ]

    private let exitedHeaders = [
        "交易定價日", "標的", "發行日", "最終評價日", "利率", "月利率",
        "出場日", "持有月", "實際收益率", "交易金額", "實際收益", "備註"
    ]

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

    private func getStructuredColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "交易定價日", "發行日", "出場日": return 90
        case "標的": return 120
        case "最終評價日": return 100
        case "期間價格", "執行價格", "敲出障礙", "敲入障礙": return 80
        case "利率", "月利率", "實際收益", "實際收益率": return 70
        case "交易金額": return 90
        case "持有月": return 60
        case "備註": return 120
        case "操作": return 60
        default: return 80
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        if value == 0 {
            return "0.00"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func formatPercentage(_ value: Double) -> String {
        if value == 0 {
            return "0.00%"
        }
        return String(format: "%.2f%%", value)
    }

    private func handleProductExit(_ exitedProduct: StructuredProduct) {
        if let index = structuredProducts.firstIndex(where: { $0.id == exitedProduct.id }) {
            structuredProducts[index] = exitedProduct
        }
        selectedProductToExit = nil
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d"
        return formatter
    }()
}

struct MonthlyAssetTableView_Previews: PreviewProvider {
    static var previews: some View {
        MonthlyAssetTableView()
            .padding()
    }
}