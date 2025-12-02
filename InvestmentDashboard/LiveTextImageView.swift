//
//  LiveTextImageView.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/17.
//  使用 iOS 原況文字（Live Text）功能的圖片檢視器
//

import SwiftUI
import VisionKit

@available(iOS 16.0, *)
struct LiveTextImageView: View {
    let image: UIImage
    let columnName: String
    let onTextExtracted: ([String]) -> Void
    let onCancel: () -> Void

    @State private var selectedText: String = ""
    @State private var showingConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // 導航列
            navigationBar

            // 說明文字
            instructionText

            // 圖片檢視器（支援原況文字）
            ImageAnalysisView(image: image, selectedText: $selectedText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 底部按鈕
            bottomButtons
        }
        .background(Color.black)
    }

    // MARK: - 導航列
    private var navigationBar: some View {
        HStack {
            Button(action: onCancel) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("取消")
                        .font(.system(size: 17))
                }
                .foregroundColor(.white)
            }

            Spacer()

            Text("原況文字辨識")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // 佔位
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                Text("取消")
                    .font(.system(size: 17))
            }
            .opacity(0)
        }
        .padding()
        .background(Color.black.opacity(0.9))
    }

    // MARK: - 說明文字
    private var instructionText: some View {
        VStack(spacing: 8) {
            Text("選取「\(columnName)」欄位數字")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("用手指長按圖片，選取要複製的數字欄位")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))

            Text("雙指縮放照片 • 請從第一年保單開始選取")
                .font(.system(size: 12))
                .foregroundColor(.yellow.opacity(0.9))
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.8))
    }

    // MARK: - 底部按鈕
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // 提示文字
            VStack(spacing: 8) {
                Text("使用步驟：")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text("1. 長按圖片上的數字欄位")
                    Text("2. 拖動選取框，框選整欄數字")
                    Text("3. 點擊「拷貝」")
                    Text("4. 點擊下方「讀取並填入」按鈕")
                }
                .font(.system(size: 12))
                .foregroundColor(.yellow)
            }
            .padding(.horizontal)

            Button {
                print("🔘 按鈕被點擊")
                checkClipboardAndProcess()
            } label: {
                HStack {
                    Image(systemName: "doc.on.clipboard.fill")
                    Text("讀取剪貼簿並填入")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
    }

    // MARK: - 讀取剪貼簿
    private func checkClipboardAndProcess() {
        print("\n🔍 檢查剪貼簿...")

        guard let clipboardText = UIPasteboard.general.string else {
            print("❌ 剪貼簿是空的")
            onTextExtracted([]) // 觸發錯誤提示
            return
        }

        print("✅ 剪貼簿有內容")
        print("內容長度：\(clipboardText.count) 字元")

        selectedText = clipboardText
        processSelectedText()
    }

    // MARK: - 處理選取的文字
    private func processSelectedText() {
        print("\n📋 原況文字選取內容：")
        print(selectedText)

        // 分割成行，並清理每個數字
        let lines = selectedText.components(separatedBy: .newlines)
        var numbers: [String] = []

        for line in lines {
            let cleaned = cleanNumber(line)
            if !cleaned.isEmpty {
                numbers.append(cleaned)
            }
        }

        print("\n✅ 解析到 \(numbers.count) 個數字：")
        for (index, number) in numbers.enumerated() {
            print("   [\(index + 1)] \(number)")
        }

        onTextExtracted(numbers)
    }

    /// 清理數字字串
    private func cleanNumber(_ string: String) -> String {
        print("   🔧 清理前：\(string)")

        // 先移除貨幣符號和空格
        var cleaned = string
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "NT$", with: "")
            .replacingOccurrences(of: "TWD", with: "")
            .replacingOccurrences(of: "元", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)

        // 移除千位分隔符（逗號）
        cleaned = cleaned.replacingOccurrences(of: ",", with: "")

        // 處理小數點：判斷是真正的小數點還是被誤認的千位分隔符
        // 規則：最後一個小數點如果後面只有1-2位數字，就是真的小數點；否則都是千位分隔符
        let dotCount = cleaned.filter { $0 == "." }.count

        if dotCount > 0 {
            if let lastDotIndex = cleaned.lastIndex(of: ".") {
                let afterLastDot = cleaned[cleaned.index(after: lastDotIndex)...]

                // 如果最後一個點後面只有1-2位數字，這是真的小數點
                if afterLastDot.count <= 2 && afterLastDot.allSatisfy({ $0.isNumber }) {
                    // 先移除前面所有的點（千位分隔符）
                    let beforeLastDot = cleaned[..<lastDotIndex]
                    let integerPart = beforeLastDot.replacingOccurrences(of: ".", with: "")
                    cleaned = integerPart
                    print("   💡 偵測到小數：\(string) → 取整數部分：\(cleaned)")
                } else {
                    // 所有點都是千位分隔符，全部移除
                    cleaned = cleaned.replacingOccurrences(of: ".", with: "")
                    print("   💡 所有點都是千位分隔符，已移除")
                }
            }
        }

        // 移除所有非數字字元
        let allowedCharacters = CharacterSet.decimalDigits
        cleaned = cleaned.components(separatedBy: allowedCharacters.inverted).joined()

        // 過濾太短的數字
        if cleaned.count < 2 {
            print("   ⚠️ 數字太短（\(cleaned.count) 位），忽略")
            return ""
        }

        print("   ✅ 清理後：\(cleaned)")
        return cleaned
    }
}

// MARK: - ImageAnalysisView (UIKit 包裝器)

@available(iOS 16.0, *)
struct ImageAnalysisView: UIViewRepresentable {
    let image: UIImage
    @Binding var selectedText: String

    func makeUIView(context: Context) -> ImageAnalysisUIView {
        let view = ImageAnalysisUIView()
        view.delegate = context.coordinator
        view.setImage(image)
        return view
    }

    func updateUIView(_ uiView: ImageAnalysisUIView, context: Context) {
        // 不需要更新
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedText: $selectedText)
    }

    class Coordinator: NSObject, ImageAnalysisUIViewDelegate {
        @Binding var selectedText: String

        init(selectedText: Binding<String>) {
            _selectedText = selectedText
        }

        func didSelectText(_ text: String) {
            selectedText = text
        }
    }
}

// MARK: - ImageAnalysisUIView (基於 UIScrollView + ImageAnalysisInteraction)

@available(iOS 16.0, *)
protocol ImageAnalysisUIViewDelegate: AnyObject {
    func didSelectText(_ text: String)
}

@available(iOS 16.0, *)
class ImageAnalysisUIView: UIView {
    weak var delegate: ImageAnalysisUIViewDelegate?

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let analyzer = ImageAnalyzer()
    private let interaction = ImageAnalysisInteraction()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        // 設定 ScrollView
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        addSubview(scrollView)

        // 設定 ImageView
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)

        // 設定 ImageAnalysisInteraction
        imageView.addInteraction(interaction)
        interaction.preferredInteractionTypes = [.textSelection]

        // 監聽文字選取
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTextSelection),
            name: NSNotification.Name("ImageAnalysisInteractionDidSelectText"),
            object: nil
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        updateImageViewFrame()
    }

    func setImage(_ image: UIImage) {
        imageView.image = image
        updateImageViewFrame()
        analyzeImage(image)
    }

    private func updateImageViewFrame() {
        guard let image = imageView.image else { return }

        let imageSize = image.size
        let scrollViewSize = scrollView.bounds.size

        let widthRatio = scrollViewSize.width / imageSize.width
        let heightRatio = scrollViewSize.height / imageSize.height
        let scale = min(widthRatio, heightRatio)

        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        // 圖片從 (0, 0) 開始放置
        imageView.frame = CGRect(
            x: 0,
            y: 0,
            width: scaledWidth,
            height: scaledHeight
        )

        scrollView.contentSize = CGSize(width: scaledWidth, height: scaledHeight)

        // 計算置中所需的 contentInset
        let xInset = max(0, (scrollViewSize.width - scaledWidth) / 2)
        let yInset = max(0, (scrollViewSize.height - scaledHeight) / 2)

        scrollView.contentInset = UIEdgeInsets(
            top: yInset,
            left: xInset,
            bottom: yInset,
            right: xInset
        )

        // 設定初始的 contentOffset 讓圖片置中
        scrollView.contentOffset = CGPoint(x: -xInset, y: -yInset)
    }

    private func analyzeImage(_ image: UIImage) {
        Task {
            do {
                let configuration = ImageAnalyzer.Configuration([.text])
                let analysis = try await analyzer.analyze(image, configuration: configuration)

                await MainActor.run {
                    interaction.analysis = analysis
                    interaction.preferredInteractionTypes = [.textSelection]
                    print("✅ 原況文字分析完成")
                }
            } catch {
                print("❌ 原況文字分析失敗：\(error.localizedDescription)")
            }
        }
    }

    @objc private func handleTextSelection(_ notification: Notification) {
        // 這個方法會在用戶選取文字時被呼叫
        // 但 ImageAnalysisInteraction 不提供直接的選取回調
        // 我們需要使用 UIPasteboard 來取得選取的文字

        // 延遲一下，等待文字被複製到剪貼簿
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if let text = UIPasteboard.general.string {
                self?.delegate?.didSelectText(text)
            }
        }
    }
}

@available(iOS 16.0, *)
extension ImageAnalysisUIView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        LiveTextImageView(
            image: UIImage(systemName: "photo")!,
            columnName: "保單現金價值",
            onTextExtracted: { numbers in
                print("提取到的數字：\(numbers)")
            },
            onCancel: { }
        )
    }
}
