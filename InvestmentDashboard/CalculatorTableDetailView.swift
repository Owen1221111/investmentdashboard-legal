//
//  CalculatorTableDetailView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/16.
//  保險試算表詳情視圖（顯示表格資料）
//

import SwiftUI
import CoreData

struct CalculatorTableDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let calculator: InsuranceCalculator
    let client: Client?

    // 試算表資料行
    @FetchRequest private var calculatorRows: FetchedResults<InsuranceCalculatorRow>

    // UI 狀態
    @State private var showingFileImporter = false
    @State private var showingImagePicker = false
    @State private var showingPhotoOptions = false
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingError = false

    // 第一年保險年齡編輯狀態
    @State private var firstYearInsuranceAge: String = ""
    @State private var isEditingFirstYearAge = false

    // 要保人和被保人編輯狀態
    @State private var policyHolder: String = ""
    @State private var insuredPerson: String = ""

    // 針對性辨識狀態
    @State private var showingColumnSelector = false
    @State private var showingRegionSelector = false
    @State private var selectedColumn: CalculatorColumn?
    @State private var regionImageForOCR: UIImage?

    // 貼上欄位狀態
    @State private var showingPasteColumnSelector = false

    // 原況文字辨識狀態
    @State private var showingLiveTextColumnSelector = false
    @State private var showingLiveTextView = false
    @State private var liveTextImage: UIImage?
    @State private var liveTextColumn: CalculatorColumn?

    // 表格欄位
    private let headers = ["保單年度", "保險年齡", "保單現金價值\n（解約金）", "身故保險金"]

    init(calculator: InsuranceCalculator, client: Client?) {
        self.calculator = calculator
        self.client = client

        // 設定 FetchRequest，只取得此試算表的資料行
        _calculatorRows = FetchRequest<InsuranceCalculatorRow>(
            sortDescriptors: [NSSortDescriptor(keyPath: \InsuranceCalculatorRow.rowOrder, ascending: true)],
            predicate: NSPredicate(format: "calculator == %@", calculator),
            animation: .default
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // 導航列
            navigationBar

            // 資訊卡片
            infoCard

            // 表格區域
            tableView

            // 底部工具列
            bottomToolbar
        }
        .background(Color(.systemGroupedBackground))
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .confirmationDialog("選擇匯入方式", isPresented: $showingPhotoOptions, titleVisibility: .visible) {
            Button("拍照") {
                showingImagePicker = true
            }
            Button("從相簿選擇") {
                showingImagePicker = true
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("請選擇要匯入試算表資料的方式")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .onChange(of: selectedImage) { image in
            guard let image = image else { return }

            // 如果是原況文字辨識
            if liveTextColumn != nil {
                liveTextImage = image
                showingLiveTextView = true
                selectedImage = nil // 重置
            }
            // 如果是針對性辨識，顯示區域選擇器
            else if selectedColumn != nil {
                regionImageForOCR = image
                showingRegionSelector = true
                selectedImage = nil // 重置
            }
            // 原本的全表格辨識
            else {
                processImageWithOCR(image)
            }
        }
        .overlay {
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("正在處理資料...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.8))
                    )
                }
            }
        }
        .alert("錯誤", isPresented: $showingError) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "發生未知錯誤")
        }
        .confirmationDialog("選擇要辨識的欄位", isPresented: $showingColumnSelector, titleVisibility: .visible) {
            ForEach(CalculatorColumn.allCases, id: \.self) { column in
                Button(column.displayName) {
                    selectedColumn = column
                    showingImagePicker = true
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("請選擇要辨識並填入的欄位")
        }
        .confirmationDialog("選擇要貼上的欄位", isPresented: $showingPasteColumnSelector, titleVisibility: .visible) {
            ForEach(CalculatorColumn.allCases, id: \.self) { column in
                Button(column.displayName) {
                    pasteIntoColumn(column)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("請先在照片 App 中用「原況文字」複製數字，然後選擇要貼上的欄位")
        }
        .confirmationDialog("選擇要辨識的欄位", isPresented: $showingLiveTextColumnSelector, titleVisibility: .visible) {
            ForEach(CalculatorColumn.allCases, id: \.self) { column in
                Button(column.displayName) {
                    liveTextColumn = column
                    showingImagePicker = true
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("使用 iPhone 原況文字功能選取照片中的數字")
        }
        .fullScreenCover(isPresented: $showingRegionSelector) {
            if let image = regionImageForOCR, let column = selectedColumn {
                ImageRegionSelector(
                    image: image,
                    columnName: column.displayName,
                    onRegionSelected: { region in
                        showingRegionSelector = false
                        processRegionOCR(image: image, region: region, column: column)
                    },
                    onCancel: {
                        showingRegionSelector = false
                        regionImageForOCR = nil
                        selectedColumn = nil
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showingLiveTextView) {
            if #available(iOS 16.0, *), let image = liveTextImage, let column = liveTextColumn {
                LiveTextImageView(
                    image: image,
                    columnName: column.displayName,
                    onTextExtracted: { numbers in
                        showingLiveTextView = false
                        if numbers.isEmpty {
                            showError("未選取任何數字\n\n請用手指長按照片，選取要複製的數字欄位")
                        } else {
                            fillColumnWithNumbers(numbers, column: column)
                        }
                        liveTextImage = nil
                        liveTextColumn = nil
                    },
                    onCancel: {
                        showingLiveTextView = false
                        liveTextImage = nil
                        liveTextColumn = nil
                    }
                )
            }
        }
        .onAppear {
            // 初始化要保人和被保人
            policyHolder = calculator.policyHolder ?? ""
            insuredPerson = calculator.insuredPerson ?? ""
        }
    }

    // MARK: - 導航列
    private var navigationBar: some View {
        HStack {
            // 返回按鈕
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 17, weight: .regular))
                }
                .foregroundColor(.blue)
            }

            Spacer()

            // 標題
            Text("試算表詳情")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // 佔位（保持標題居中）
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                Text("返回")
                    .font(.system(size: 17, weight: .regular))
            }
            .opacity(0)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 資訊卡片
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 公司和商品名稱
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(calculator.companyName ?? "未知公司")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))

                    Text(calculator.productName ?? "未知商品")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 資料筆數
                VStack(spacing: 4) {
                    Text("\(calculatorRows.count)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.blue)
                    Text("筆資料")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // 要保人和被保人
            HStack(spacing: 16) {
                // 要保人
                VStack(alignment: .leading, spacing: 4) {
                    Text("要保人")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    TextField("點擊輸入要保人", text: $policyHolder)
                        .font(.system(size: 14))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: policyHolder) { newValue in
                            calculator.policyHolder = newValue
                            saveContext()
                        }
                }

                // 被保人
                VStack(alignment: .leading, spacing: 4) {
                    Text("被保人")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    TextField("點擊輸入被保人", text: $insuredPerson)
                        .font(.system(size: 14))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: insuredPerson) { newValue in
                            calculator.insuredPerson = newValue
                            saveContext()
                        }
                }
            }

            Divider()

            // 建立時間
            if let createdDate = calculator.createdDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text("建立時間：\(formatDate(createdDate))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding()
    }

    // MARK: - 表格視圖
    private var tableView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                // 表頭（固定，跟著水平滾動）
                tableHeader

                // 表格內容（垂直滾動）
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if calculatorRows.isEmpty {
                            // 空狀態：顯示保單年度 1~100 的空白行
                            ForEach(1...100, id: \.self) { year in
                                emptyTableRow(year: year)
                            }
                        } else {
                            // 有資料：顯示實際資料
                            ForEach(Array(calculatorRows.enumerated()), id: \.offset) { index, row in
                                tableRow(row: row, index: index)
                            }
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal)
    }

    // 表頭
    private var tableHeader: some View {
        HStack(spacing: 0) {
            // 刪除按鈕欄
            Text("")
                .frame(width: 40, alignment: .center)

            // 各欄位標題
            ForEach(headers, id: \.self) { header in
                Text(header)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                    .frame(width: getColumnWidth(for: header), alignment: .center)
                    .padding(.vertical, 14)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .background(Color(.init(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)))
    }

    // 表格行（有資料）
    private func tableRow(row: InsuranceCalculatorRow, index: Int) -> some View {
        HStack(spacing: 0) {
            // 刪除按鈕
            Button(action: {
                deleteRow(row)
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            }
            .frame(width: 40, alignment: .center)

            // 保單年度
            Text(row.policyYear ?? "-")
                .font(.system(size: 15))
                .frame(width: getColumnWidth(for: "保單年度"), alignment: .center)

            // 保險年齡
            if index == 0 {
                // 第一年的保險年齡可以編輯
                TextField("", text: Binding(
                    get: {
                        row.insuranceAge ?? ""
                    },
                    set: { newValue in
                        updateFirstYearInsuranceAge(newValue)
                    }
                ))
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(.numberPad)
                .frame(width: getColumnWidth(for: "保險年齡"), alignment: .center)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                // 其他年度的保險年齡只顯示，不可編輯
                Text(row.insuranceAge ?? "-")
                    .font(.system(size: 15))
                    .frame(width: getColumnWidth(for: "保險年齡"), alignment: .center)
            }

            // 保單現金價值
            Text(formatCurrency(row.cashValue ?? "0"))
                .font(.system(size: 15))
                .frame(width: getColumnWidth(for: "保單現金價值\n（解約金）"), alignment: .trailing)

            // 身故保險金
            Text(formatCurrency(row.deathBenefit ?? "0"))
                .font(.system(size: 15))
                .frame(width: getColumnWidth(for: "身故保險金"), alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.02))
        .overlay(
            VStack {
                Spacer()
                Divider().opacity(0.3)
            }
        )
    }

    // 空白表格行（顯示保單年度）
    private func emptyTableRow(year: Int) -> some View {
        HStack(spacing: 0) {
            // 空白（沒有刪除按鈕）
            Text("")
                .frame(width: 40, alignment: .center)

            // 保單年度（顯示年份）
            Text("\(year)")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(width: getColumnWidth(for: "保單年度"), alignment: .center)

            // 保險年齡（空白）
            Text("-")
                .font(.system(size: 15))
                .foregroundColor(.secondary.opacity(0.5))
                .frame(width: getColumnWidth(for: "保險年齡"), alignment: .center)

            // 保單現金價值（空白）
            Text("-")
                .font(.system(size: 15))
                .foregroundColor(.secondary.opacity(0.5))
                .frame(width: getColumnWidth(for: "保單現金價值\n（解約金）"), alignment: .trailing)

            // 身故保險金（空白）
            Text("-")
                .font(.system(size: 15))
                .foregroundColor(.secondary.opacity(0.5))
                .frame(width: getColumnWidth(for: "身故保險金"), alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(year % 2 == 0 ? Color.clear : Color.gray.opacity(0.02))
        .overlay(
            VStack {
                Spacer()
                Divider().opacity(0.3)
            }
        )
    }


    // MARK: - 底部工具列
    private var bottomToolbar: some View {
        VStack(spacing: 12) {
            // 第一排：CSV 匯入按鈕
            Button(action: {
                showingFileImporter = true
            }) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("匯入CSV")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(12)
            }

            // 第二排：原況文字辨識按鈕（iOS 16+，僅在有資料時顯示）
            if !calculatorRows.isEmpty {
                if #available(iOS 16.0, *) {
                    Button(action: {
                        showingLiveTextColumnSelector = true
                    }) {
                        HStack {
                            Image(systemName: "text.viewfinder")
                            Text("原況文字辨識")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                }
            }

            // 第三排：補充保險年齡按鈕（僅在沒有資料時顯示）
            if calculatorRows.isEmpty {
                Button(action: {
                    generateInsuranceAgeData()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("自動生成保險年齡資料")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - 資料處理

    /// 處理CSV檔案匯入
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                showError("無法訪問檔案")
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            isProcessing = true

            let parser = CalculatorTableParser()
            let parseResult = parser.parseCSV(from: url)

            switch parseResult {
            case .success(let rows):
                // 驗證資料
                let validation = parser.validateRows(rows)
                if !validation.isValid {
                    showError("資料驗證失敗：\n" + validation.errors.joined(separator: "\n"))
                    isProcessing = false
                    return
                }

                // 儲存到 Core Data
                saveRows(rows)
                isProcessing = false

                print("✅ CSV 匯入成功：共 \(rows.count) 筆資料")

            case .failure(let error):
                showError("CSV 解析失敗：\(error.localizedDescription)")
                isProcessing = false
            }

        case .failure(let error):
            showError("檔案選擇失敗：\(error.localizedDescription)")
        }
    }

    /// 處理OCR圖片辨識
    private func processImageWithOCR(_ image: UIImage) {
        isProcessing = true

        let parser = CalculatorTableParser()
        parser.parseImageTable(from: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let rows):
                    // 驗證資料
                    let validation = parser.validateRows(rows)
                    if !validation.isValid {
                        showError("資料驗證失敗：\n" + validation.errors.joined(separator: "\n"))
                        isProcessing = false
                        return
                    }

                    // 儲存到 Core Data
                    saveRows(rows)
                    isProcessing = false

                    print("✅ OCR 辨識成功：共 \(rows.count) 筆資料")

                case .failure(let error):
                    showError("OCR 辨識失敗：\(error.localizedDescription)")
                    isProcessing = false
                }
            }
        }
    }

    /// 儲存資料行到 Core Data（只更新現金價值和身故保險金）
    private func saveRows(_ rows: [CalculatorRowData]) {
        // 如果已有資料，則更新現金價值和身故保險金，保留保單年度和保險年齡
        if !calculatorRows.isEmpty {
            print("📝 更新模式：保留保單年度和保險年齡，只更新現金價值和身故保險金")

            // 建立索引對應（保單年度 -> 資料）
            var dataMap: [String: CalculatorRowData] = [:]
            for rowData in rows {
                dataMap[rowData.policyYear] = rowData
            }

            // 更新現有資料行
            for existingRow in calculatorRows {
                guard let policyYear = existingRow.policyYear,
                      let newData = dataMap[policyYear] else {
                    continue
                }

                // 只更新現金價值和身故保險金
                existingRow.cashValue = newData.cashValue
                existingRow.deathBenefit = newData.deathBenefit

                print("   ✅ 更新第\(policyYear)年：現金價值=\(newData.cashValue), 身故保險金=\(newData.deathBenefit)")
            }

        } else {
            // 如果沒有資料，則新增完整資料（這是舊的匯入方式）
            print("📝 新增模式：建立完整資料（包含保單年度和保險年齡）")

            for (index, rowData) in rows.enumerated() {
                let newRow = InsuranceCalculatorRow(context: viewContext)
                newRow.calculator = calculator
                newRow.policyYear = rowData.policyYear
                newRow.insuranceAge = rowData.insuranceAge
                newRow.cashValue = rowData.cashValue
                newRow.deathBenefit = rowData.deathBenefit
                newRow.rowOrder = Int16(index)
                newRow.createdDate = Date()
            }
        }

        // 儲存
        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 試算表資料已儲存：共 \(calculatorRows.isEmpty ? rows.count : calculatorRows.count) 筆")
        } catch {
            showError("儲存失敗：\(error.localizedDescription)")
        }
    }

    /// 刪除單行資料
    private func deleteRow(_ row: InsuranceCalculatorRow) {
        viewContext.delete(row)

        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 已刪除一行資料")
        } catch {
            showError("刪除失敗：\(error.localizedDescription)")
        }
    }

    /// 處理區域OCR辨識
    private func processRegionOCR(image: UIImage, region: CGRect, column: CalculatorColumn) {
        isProcessing = true

        let ocrManager = RegionOCRManager()
        ocrManager.recognizeNumbers(in: image, region: region) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let numbers):
                    print("✅ 辨識到 \(numbers.count) 個數字")

                    // 從第一年保單開始填入數字
                    fillColumnWithNumbers(numbers, column: column)
                    isProcessing = false

                    // 清理狀態
                    regionImageForOCR = nil
                    selectedColumn = nil

                case .failure(let error):
                    showError("區域辨識失敗：\(error.localizedDescription)")
                    isProcessing = false

                    // 清理狀態
                    regionImageForOCR = nil
                    selectedColumn = nil
                }
            }
        }
    }

    /// 將辨識到的數字填入指定欄位
    private func fillColumnWithNumbers(_ numbers: [String], column: CalculatorColumn) {
        // 限制在試算表的行數範圍內
        let rowsToFill = min(numbers.count, calculatorRows.count)

        for index in 0..<rowsToFill {
            let row = calculatorRows[index]
            let number = numbers[index]

            switch column {
            case .cashValue:
                row.cashValue = number
                print("   填入第\(index + 1)年保單現金價值：\(number)")
            case .deathBenefit:
                row.deathBenefit = number
                print("   填入第\(index + 1)年身故保險金：\(number)")
            }
        }

        // 儲存
        do {
            try viewContext.save()
            PersistenceController.shared.save()
            print("✅ 已填入 \(rowsToFill) 筆資料到 \(column.displayName)")
        } catch {
            showError("儲存失敗：\(error.localizedDescription)")
        }
    }

    /// 從剪貼簿貼上數字到指定欄位
    private func pasteIntoColumn(_ column: CalculatorColumn) {
        // 讀取剪貼簿內容
        guard let pasteboardString = UIPasteboard.general.string else {
            showError("剪貼簿沒有內容")
            return
        }

        print("\n📋 剪貼簿內容：")
        print(pasteboardString)

        // 分割成行，並清理每個數字
        let lines = pasteboardString.components(separatedBy: .newlines)
        var numbers: [String] = []

        for line in lines {
            let cleaned = cleanPastedNumber(line)
            if !cleaned.isEmpty {
                numbers.append(cleaned)
            }
        }

        print("\n✅ 解析到 \(numbers.count) 個數字：")
        for (index, number) in numbers.enumerated() {
            print("   [\(index + 1)] \(number)")
        }

        if numbers.isEmpty {
            showError("剪貼簿中沒有找到有效的數字\n\n請確保：\n1. 已在照片 App 中用「原況文字」選取並複製數字\n2. 複製的是數字欄位（一行一個數字）")
            return
        }

        // 填入欄位
        fillColumnWithNumbers(numbers, column: column)
    }

    /// 清理貼上的數字字串
    private func cleanPastedNumber(_ string: String) -> String {
        var cleaned = string
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "NT$", with: "")
            .replacingOccurrences(of: "TWD", with: "")
            .replacingOccurrences(of: "元", with: "")
            .trimmingCharacters(in: .whitespaces)

        // 移除所有非數字和小數點的字元
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
        cleaned = cleaned.components(separatedBy: allowedCharacters.inverted).joined()

        // 移除小數點（保險金額通常是整數）
        cleaned = cleaned.replacingOccurrences(of: ".", with: "")

        // 過濾太短的數字（可能是誤選）
        if cleaned.count < 2 {
            return ""
        }

        return cleaned
    }

    // MARK: - 保險年齡更新

    /// 更新第一年保險年齡並自動計算後續年度
    private func updateFirstYearInsuranceAge(_ newValue: String) {
        // 驗證輸入是否為有效數字
        guard let firstAge = Int(newValue), firstAge > 0 else {
            // 如果不是有效數字，只更新第一年，不更新後續
            if let firstRow = calculatorRows.first {
                firstRow.insuranceAge = newValue
                saveContext()
            }
            return
        }

        // 更新所有年度的保險年齡
        for (index, row) in calculatorRows.enumerated() {
            let newAge = firstAge + index
            row.insuranceAge = "\(newAge)"
        }

        // 儲存更改
        saveContext()

        print("✅ 已更新保險年齡：第一年=\(firstAge)，總共更新 \(calculatorRows.count) 筆資料")
    }

    /// 儲存 Core Data 上下文
    private func saveContext() {
        do {
            try viewContext.save()
            PersistenceController.shared.save()
        } catch {
            showError("儲存失敗：\(error.localizedDescription)")
        }
    }

    // MARK: - 輔助函數

    /// 顯示錯誤訊息
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }

    /// 取得欄位寬度
    private func getColumnWidth(for header: String) -> CGFloat {
        switch header {
        case "保單年度": return 100
        case "保險年齡": return 100
        case "保單現金價值\n（解約金）": return 150
        case "身故保險金": return 150
        default: return 120
        }
    }

    /// 格式化貨幣
    private func formatCurrency(_ value: String) -> String {
        guard let number = Double(value) else { return "$0" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return "$" + (formatter.string(from: NSNumber(value: number)) ?? "0")
    }

    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - 自動生成保險年齡資料

    /// 自動生成100行保險年齡資料
    private func generateInsuranceAgeData() {
        guard let client = client else {
            showError("無法生成資料：找不到客戶資訊")
            return
        }

        // 檢查是否有保險始期
        let startDate = calculator.startDate
        guard let startDateString = startDate, !startDateString.isEmpty else {
            showError("無法生成資料：此試算表沒有保險始期\n請先從保險明細重新「存放」")
            return
        }

        // 檢查客戶是否有出生日期
        guard let birthDate = client.birthDate else {
            showError("無法生成資料：客戶未設定出生日期\n請先編輯客戶資料設定出生年月日")
            return
        }

        isProcessing = true

        // 計算第一年保險年齡
        let firstYearAge = calculateFirstYearInsuranceAge(birthDate: birthDate, startDate: startDateString)

        guard let baseAge = firstYearAge else {
            showError("無法計算保險年齡：日期格式錯誤")
            isProcessing = false
            return
        }

        // 生成100行資料
        for year in 1...100 {
            let row = InsuranceCalculatorRow(context: viewContext)
            row.calculator = calculator
            row.policyYear = "\(year)"
            row.rowOrder = Int16(year - 1)
            row.createdDate = Date()

            // 計算保險年齡（遞增）
            let currentAge = baseAge + (year - 1)
            row.insuranceAge = "\(currentAge)"

            // 其他欄位初始化為空
            row.cashValue = ""
            row.deathBenefit = ""
        }

        // 儲存
        do {
            try viewContext.save()
            PersistenceController.shared.save()
            isProcessing = false
            print("✅ 已自動生成100行保險年齡資料")
            print("   第一年保險年齡：\(baseAge)")
        } catch {
            showError("儲存失敗：\(error.localizedDescription)")
            isProcessing = false
        }
    }

    /// 計算第一年的保險年齡
    private func calculateFirstYearInsuranceAge(birthDate: Date, startDate: String) -> Int? {
        // 解析保險始期字串為 Date 物件
        guard let policyStartDate = parseDate(startDate) else {
            print("⚠️ 無法解析保險始期：\(startDate)")
            return nil
        }

        // 計算年齡差距
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: policyStartDate)

        guard let age = ageComponents.year else {
            print("⚠️ 計算年齡失敗")
            return nil
        }

        return age
    }

    /// 解析日期字串為 Date 物件
    private func parseDate(_ dateString: String) -> Date? {
        let dateFormatters: [DateFormatter] = {
            let formats = ["yyyy/MM/dd", "yyyy-MM-dd", "yyyy年M月d日", "yyyy/M/d", "yyyy-M-d"]
            return formats.map { format in
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "zh_TW")
                return formatter
            }
        }()

        for formatter in dateFormatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let calculator = InsuranceCalculator(context: context)
    calculator.companyName = "國泰人壽"
    calculator.productName = "終身壽險"
    calculator.createdDate = Date()

    return CalculatorTableDetailView(calculator: calculator, client: nil)
        .environment(\.managedObjectContext, context)
}
