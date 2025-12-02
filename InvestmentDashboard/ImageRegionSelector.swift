//
//  ImageRegionSelector.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/17.
//  圖片區域選擇器（讓用戶框選要辨識的區域）
//

import SwiftUI

struct ImageRegionSelector: View {
    let image: UIImage
    let columnName: String
    let onRegionSelected: (CGRect) -> Void
    let onCancel: () -> Void

    @State private var selectedRegion: CGRect?
    @State private var imageSize: CGSize = .zero
    @State private var isDraggingBox = false
    @State private var isResizingBox = false

    // 縮放和平移狀態
    @State private var currentScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero

    // 編輯模式
    @State private var editMode: EditMode = .none

    enum EditMode {
        case none
        case drawing
        case moving
        case resizing
    }

    var body: some View {
        VStack(spacing: 0) {
            // 導航列
            navigationBar

            // 說明文字
            instructionText

            // 圖片區域
            imageView

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

            Text("選擇辨識區域")
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
            Text("框選「\(columnName)」欄位")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            if selectedRegion == nil {
                Text("用手指拖曳框選要辨識的數字區域")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            } else {
                Text("可拖動選取框或拉動角落調整大小")
                    .font(.system(size: 14))
                    .foregroundColor(.green.opacity(0.9))
            }

            Text("雙指縮放照片 • 請從第一年保單開始框選")
                .font(.system(size: 12))
                .foregroundColor(.yellow.opacity(0.9))
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.8))
    }

    // MARK: - 圖片視圖
    private var imageView: some View {
        GeometryReader { geometry in
            ZStack {
                // 圖片（支援縮放和平移）
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(currentScale)
                    .offset(currentOffset)
                    .background(
                        GeometryReader { imageGeometry in
                            Color.clear.onAppear {
                                imageSize = imageGeometry.size
                            }
                        }
                    )
                    .gesture(
                        // 雙指縮放
                        MagnificationGesture()
                            .onChanged { value in
                                currentScale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = currentScale
                            }
                            .simultaneously(with:
                                // 雙指平移
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if editMode == .none {
                                            currentOffset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = currentOffset
                                    }
                            )
                    )

                // 選取框
                if let region = selectedRegion {
                    SelectionBox(
                        region: region,
                        geometry: geometry,
                        currentScale: currentScale,
                        currentOffset: currentOffset,
                        onMove: { delta in
                            moveSelectionBox(by: delta)
                        },
                        onResize: { newRegion in
                            selectedRegion = newRegion
                        }
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 選取框視圖
    struct SelectionBox: View {
        let region: CGRect
        let geometry: GeometryProxy
        let currentScale: CGFloat
        let currentOffset: CGSize
        let onMove: (CGSize) -> Void
        let onResize: (CGRect) -> Void

        @State private var isDragging = false
        @State private var dragStart: CGPoint = .zero
        @State private var resizeHandle: ResizeHandle?

        enum ResizeHandle {
            case topLeft, topRight, bottomLeft, bottomRight
        }

        var body: some View {
            let viewRegion = convertToViewSpace(region)

            ZStack {
                // 選取框主體
                Rectangle()
                    .stroke(Color.green, lineWidth: 3)
                    .background(Color.green.opacity(0.2))
                    .frame(width: viewRegion.width, height: viewRegion.height)
                    .position(x: viewRegion.midX, y: viewRegion.midY)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    dragStart = value.startLocation
                                }
                                let delta = CGSize(
                                    width: value.location.x - dragStart.x,
                                    height: value.location.y - dragStart.y
                                )
                                onMove(delta)
                                dragStart = value.location
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )

                // 四個角落的調整控制點
                ForEach([ResizeHandle.topLeft, .topRight, .bottomLeft, .bottomRight], id: \.self) { handle in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.green, lineWidth: 3)
                        )
                        .position(handlePosition(for: handle, in: viewRegion))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    resizeRegion(handle: handle, location: value.location)
                                }
                        )
                }
            }
        }

        private func convertToViewSpace(_ rect: CGRect) -> CGRect {
            // 轉換圖片座標到視圖座標（考慮縮放和平移）
            let centerX = geometry.size.width / 2 + currentOffset.width + rect.midX * currentScale
            let centerY = geometry.size.height / 2 + currentOffset.height + rect.midY * currentScale
            let width = rect.width * currentScale
            let height = rect.height * currentScale

            return CGRect(
                x: centerX - width / 2,
                y: centerY - height / 2,
                width: width,
                height: height
            )
        }

        private func handlePosition(for handle: ResizeHandle, in viewRegion: CGRect) -> CGPoint {
            switch handle {
            case .topLeft:
                return CGPoint(x: viewRegion.minX, y: viewRegion.minY)
            case .topRight:
                return CGPoint(x: viewRegion.maxX, y: viewRegion.minY)
            case .bottomLeft:
                return CGPoint(x: viewRegion.minX, y: viewRegion.maxY)
            case .bottomRight:
                return CGPoint(x: viewRegion.maxX, y: viewRegion.maxY)
            }
        }

        private func resizeRegion(handle: ResizeHandle, location: CGPoint) {
            // 將視圖座標轉換回圖片座標
            let imageLocation = CGPoint(
                x: (location.x - geometry.size.width / 2 - currentOffset.width) / currentScale,
                y: (location.y - geometry.size.height / 2 - currentOffset.height) / currentScale
            )

            var newRegion = region

            switch handle {
            case .topLeft:
                newRegion = CGRect(
                    x: imageLocation.x,
                    y: imageLocation.y,
                    width: region.maxX - imageLocation.x,
                    height: region.maxY - imageLocation.y
                )
            case .topRight:
                newRegion = CGRect(
                    x: region.minX,
                    y: imageLocation.y,
                    width: imageLocation.x - region.minX,
                    height: region.maxY - imageLocation.y
                )
            case .bottomLeft:
                newRegion = CGRect(
                    x: imageLocation.x,
                    y: region.minY,
                    width: region.maxX - imageLocation.x,
                    height: imageLocation.y - region.minY
                )
            case .bottomRight:
                newRegion = CGRect(
                    x: region.minX,
                    y: region.minY,
                    width: imageLocation.x - region.minX,
                    height: imageLocation.y - region.minY
                )
            }

            // 確保寬高為正數
            if newRegion.width > 0 && newRegion.height > 0 {
                onResize(newRegion)
            }
        }
    }

    // MARK: - 底部按鈕
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // 第一排：新增/重新選擇 + 重置縮放
            HStack(spacing: 16) {
                // 新增/重新選擇選取框按鈕
                if selectedRegion == nil {
                    Button(action: {
                        createDefaultSelectionBox()
                    }) {
                        HStack {
                            Image(systemName: "plus.viewfinder")
                            Text("新增選取框")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(12)
                    }
                } else {
                    Button(action: {
                        selectedRegion = nil
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重新框選")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(12)
                    }
                }

                // 重置縮放按鈕
                Button(action: {
                    withAnimation {
                        currentScale = 1.0
                        currentOffset = .zero
                        lastScale = 1.0
                        lastOffset = .zero
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                        Text("重置縮放")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.6))
                    .cornerRadius(12)
                }
            }

            // 第二排：確認按鈕
            Button(action: {
                if let region = selectedRegion {
                    // 轉換為原始圖片座標（相對於圖片左上角的絕對座標）
                    let imageRect = convertToAbsoluteImageCoordinates(region)
                    print("📍 選取區域（相對座標）：\(region)")
                    print("📍 轉換後（絕對座標）：\(imageRect)")
                    onRegionSelected(imageRect)
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("確認辨識")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(selectedRegion == nil ? Color.gray.opacity(0.3) : Color.green)
                .cornerRadius(12)
            }
            .disabled(selectedRegion == nil)
        }
        .padding()
        .background(Color.black.opacity(0.9))
    }

    // MARK: - 輔助函數

    /// 創建預設選取框（在畫面中央）
    private func createDefaultSelectionBox() {
        // 創建一個在圖片中央的選取框（相對於圖片的大小）
        // 增加寬度以確保能框到完整的數字欄位
        let boxWidth: CGFloat = 300  // 從 200 增加到 300
        let boxHeight: CGFloat = 800 // 從 300 增加到 800，可以框到更多行

        selectedRegion = CGRect(
            x: -boxWidth / 2,
            y: -boxHeight / 2,
            width: boxWidth,
            height: boxHeight
        )
    }

    /// 移動選取框
    private func moveSelectionBox(by delta: CGSize) {
        guard var region = selectedRegion else { return }

        // 將視圖座標的移動量轉換為圖片座標
        let imageDelta = CGSize(
            width: delta.width / currentScale,
            height: delta.height / currentScale
        )

        region.origin.x += imageDelta.width
        region.origin.y += imageDelta.height

        selectedRegion = region
    }

    /// 規範化矩形（確保寬高為正數）
    private func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxX = max(start.x, end.x)
        let maxY = max(start.y, end.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// 將視圖座標轉換為圖片座標
    private func convertToImageSpace(_ point: CGPoint, in geometry: GeometryProxy) -> CGPoint {
        // 考慮縮放和平移
        let x = (point.x - geometry.size.width / 2 - currentOffset.width) / currentScale
        let y = (point.y - geometry.size.height / 2 - currentOffset.height) / currentScale

        return CGPoint(x: x, y: y)
    }

    /// 將相對於圖片中心的座標轉換為絕對座標（相對於圖片左上角）
    private func convertToAbsoluteImageCoordinates(_ relativeRect: CGRect) -> CGRect {
        // 將相對於中心的座標轉換為相對於左上角的座標
        let absoluteX = relativeRect.minX + image.size.width / 2
        let absoluteY = relativeRect.minY + image.size.height / 2

        return CGRect(
            x: absoluteX,
            y: absoluteY,
            width: relativeRect.width,
            height: relativeRect.height
        )
    }
}

#Preview {
    ImageRegionSelector(
        image: UIImage(systemName: "photo")!,
        columnName: "保單現金價值",
        onRegionSelected: { _ in },
        onCancel: { }
    )
}
