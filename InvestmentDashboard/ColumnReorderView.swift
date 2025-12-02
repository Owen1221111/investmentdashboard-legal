import SwiftUI

struct ColumnReorderView: View {
    @State private var currentOrder: [String] = []
    let headers: [String]
    let initialOrder: [String]
    let onSave: ([String]) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(currentOrder, id: \.self) { header in
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.gray)

                        Text(header)
                            .font(.system(size: 16, weight: .medium))

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .onMove(perform: moveItems)
            }
            .navigationTitle("調整欄位順序")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onSave(currentOrder)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if currentOrder.isEmpty {
                currentOrder = initialOrder
            }
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        currentOrder.move(fromOffsets: source, toOffset: destination)
    }
}

#Preview {
    ColumnReorderView(
        headers: ["日期", "現金", "美股", "債券"],
        initialOrder: ["日期", "現金", "美股", "債券"],
        onSave: { _ in }
    )
}