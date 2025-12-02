//
//  MultipleImagePicker.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/14.
//

import SwiftUI
import PhotosUI

/// 支援多張照片選取的 ImagePicker
struct MultipleImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImages: [UIImage]
    var maxSelection: Int = 10 // 最多選取數量

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = maxSelection // 設定最多選取張數
        configuration.filter = .images // 只顯示圖片

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultipleImagePicker

        init(_ parent: MultipleImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()

            guard !results.isEmpty else {
                print("⚠️  沒有選取任何照片")
                return
            }

            print("📸 選取了 \(results.count) 張照片")

            // 清空之前的選取
            parent.selectedImages = []

            // 使用 DispatchGroup 來確保所有圖片都載入完成
            let group = DispatchGroup()
            var loadedImages: [Int: UIImage] = [:] // 使用 index 來保持順序

            for (index, result) in results.enumerated() {
                group.enter()

                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                    defer { group.leave() }

                    if let error = error {
                        print("❌ 載入第 \(index + 1) 張照片失敗：\(error.localizedDescription)")
                        return
                    }

                    if let image = image as? UIImage {
                        loadedImages[index] = image
                        print("✅ 成功載入第 \(index + 1) 張照片")
                    }
                }
            }

            // 所有圖片載入完成後，按順序加入陣列
            group.notify(queue: .main) {
                // 按照 index 排序並取出圖片
                let sortedImages = loadedImages.sorted { $0.key < $1.key }.map { $0.value }
                self.parent.selectedImages = sortedImages
                print("📋 總共成功載入 \(sortedImages.count) 張照片")
            }
        }
    }
}
