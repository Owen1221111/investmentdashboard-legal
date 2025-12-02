import SwiftUI

struct ExitStructuredProductForm: View {
    @Binding var isPresented: Bool
    @State var product: StructuredProduct
    let onExit: (StructuredProduct) -> Void

    @State private var exitDate = Date()
    @State private var exitAmount: String = ""
    @State private var actualYield: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("結構型商品出場")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("標的：\(product.target)")
                            .font(.system(size: 16, weight: .semibold))
                        Text("交易金額：\(formatCurrency(product.tradeAmount))")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("出場資訊")) {
                    DatePicker("出場日期", selection: $exitDate, displayedComponents: .date)

                    HStack {
                        Text("出場金額")
                        Spacer()
                        TextField("0.00", text: $exitAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("實際收益率")
                        Spacer()
                        TextField("0.00", text: $actualYield)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("%")
                    }

                    TextField("備註", text: $notes)
                }

                Section(header: Text("計算結果")) {
                    if let exitAmountValue = Double(exitAmount) {
                        let profit = exitAmountValue - product.tradeAmount
                        let profitPercentage = (profit / product.tradeAmount) * 100

                        HStack {
                            Text("損益金額")
                            Spacer()
                            Text(formatCurrency(profit))
                                .foregroundColor(profit >= 0 ? .green : .red)
                        }

                        HStack {
                            Text("損益百分比")
                            Spacer()
                            Text(String(format: "%.2f%%", profitPercentage))
                                .foregroundColor(profit >= 0 ? .green : .red)
                        }

                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.month], from: product.executionDate, to: exitDate)
                        let holdingMonths = components.month ?? 0

                        HStack {
                            Text("持有月份")
                            Spacer()
                            Text("\(holdingMonths) 個月")
                        }
                    }
                }
            }
            .navigationTitle("結構型商品出場")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("確認出場") {
                        handleExit()
                    }
                    .disabled(exitAmount.isEmpty)
                }
            }
        }
    }

    private func handleExit() {
        guard let exitAmountValue = Double(exitAmount) else { return }
        let actualYieldValue = Double(actualYield) ?? 0

        var updatedProduct = product
        updatedProduct.markAsExited(
            exitDate: exitDate,
            exitAmount: exitAmountValue,
            actualYield: actualYieldValue
        )

        if !notes.isEmpty {
            updatedProduct.notes = notes
        }

        onExit(updatedProduct)
        isPresented = false
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

struct ExitStructuredProductForm_Previews: PreviewProvider {
    static var previews: some View {
        ExitStructuredProductForm(
            isPresented: .constant(true),
            product: StructuredProduct.sampleOngoingProducts(for: UUID()).first!,
            onExit: { _ in }
        )
    }
}