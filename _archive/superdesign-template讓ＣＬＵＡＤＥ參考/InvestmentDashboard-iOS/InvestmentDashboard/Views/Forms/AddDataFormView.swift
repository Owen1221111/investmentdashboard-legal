import SwiftUI

struct AddDataFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var formData = AssetFormData()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 客戶和日期資訊
                    clientDateSection
                    
                    // 資產資訊
                    assetInfoSection
                    
                    // 成本資訊
                    costInfoSection
                    
                    // 匯入資訊
                    depositInfoSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .navigationTitle("新增資產記錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveData()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - 客戶和日期資訊
    private var clientDateSection: some View {
        VStack(spacing: 16) {
            // 當前客戶
            HStack {
                Text("當前客戶")
                    .foregroundColor(.gray)
                Spacer()
                Text("Lily")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // 選擇日期 - 乾淨樣式，無背景
            HStack {
                Text("選擇日期")
                    .foregroundColor(.black)
                    .font(.system(size: 16))
                Spacer()
                DatePicker("", selection: $formData.date, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - 資產資訊
    private var assetInfoSection: some View {
        VStack(spacing: 0) {
            Text("資產資訊")
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
            
            VStack(spacing: 0) {
                simpleInputRow(title: "現金", value: $formData.cashString, placeholder: "3,264,395")
                simpleInputRow(title: "美股", value: $formData.usStockString, placeholder: "3,596,018")
                simpleInputRow(title: "定期定額", value: $formData.regularInvestmentString, placeholder: "定期定額")
                simpleInputRow(title: "債券", value: $formData.bondsString, placeholder: "2,739,362")
                simpleInputRow(title: "台股", value: $formData.twStockString, placeholder: "台股")
                simpleInputRow(title: "台股折合美金 匯率32", value: $formData.twStockConvertedString, placeholder: "0")
                simpleInputRow(title: "結構型商品", value: $formData.structuredProductsString, placeholder: "400,000")
                simpleInputRow(title: "已領利息", value: $formData.confirmedInterestString, placeholder: "164,048")
            }
        }
    }
    
    // MARK: - 成本資訊
    private var costInfoSection: some View {
        VStack(spacing: 0) {
            Text("成本資訊")
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
            
            simpleInputRow(title: "美股成本", value: $formData.usStockCostString, placeholder: "3,056,265")
            simpleInputRow(title: "定期定額成本", value: $formData.regularInvestmentCostString, placeholder: "定期定額成本")
            simpleInputRow(title: "債券成本", value: $formData.bondsCostString, placeholder: "2,906,035")
            simpleInputRow(title: "台股成本", value: $formData.twStockCostString, placeholder: "台股成本")
        }
    }
    
    // MARK: - 匯入資訊
    private var depositInfoSection: some View {
        VStack(spacing: 0) {
            Text("匯入資訊")
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
            
            simpleInputRow(title: "匯入", value: $formData.depositString, placeholder: "匯入")
        }
    }
    
    // MARK: - 輔助函數和組件
    private func simpleInputRow(title: String, value: Binding<String>, placeholder: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                Spacer()
                TextField(placeholder, text: value)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .cornerRadius(8)
            
            // 添加間距
            Spacer().frame(height: 8)
        }
    }
    
    private func saveData() {
        // TODO: 儲存資料到資料庫
        print("保存資料: \(formData)")
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 資料模型
struct AssetFormData {
    var date = Date()
    
    // 資產資訊
    var cashString = "3,264,395"
    var usStockString = "3,596,018"
    var regularInvestmentString = "定期定額"
    var bondsString = "2,739,362"
    var twStockString = "台股"
    var twStockConvertedString = "0"
    var structuredProductsString = "400,000"
    var confirmedInterestString = "164,048"
    
    // 成本資訊
    var usStockCostString = "3,056,265"
    var regularInvestmentCostString = "定期定額成本"
    var bondsCostString = "2,906,035"
    var twStockCostString = "台股成本"
    
    // 匯入資訊
    var depositString = "匯入"
}

struct AddDataFormView_Previews: PreviewProvider {
    static var previews: some View {
        AddDataFormView()
    }
}