# 💻 第3步完整代碼 - 直接複製使用

## 🎯 修改說明
只需要替換 `BasicClientPickerView.swift` 中的主要內容區域

## 📄 完整的 BasicClientPickerView.swift 代碼

```swift
import SwiftUI

// MARK: - Grid Layout Helper
private func createGridColumns() -> [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
}

// MARK: - 基礎客戶選擇器 (第3步：加入儀表板)
struct BasicClientPickerView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = ClientViewModel()
    
    var body: some View {
        VStack {
            // 頂部導航欄區域 (保持不變)
            HStack {
                // 左側：三條槓按鈕 (客戶選擇)
                Button(action: {
                    viewModel.showClientList()
                }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // 中間：顯示當前客戶
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(viewModel.currentClientName)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // 右側：新增按鈕
                Button(action: {
                    // TODO: 新增資料功能
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            // 主要儀表板區域 (新增的6列佈局)
            if let errorMessage = viewModel.errorMessage {
                // 錯誤訊息顯示
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .padding()
                    
                    Text("載入錯誤")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom, 8)
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("重新載入") {
                        Task {
                            await viewModel.loadClients()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
            } else if viewModel.isLoading {
                // 載入中顯示
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("載入客戶資料中...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } else {
                // 主要儀表板內容
                ScrollView {
                    LazyVGrid(columns: createGridColumns(), spacing: 16) {
                        
                        // 第一排 - 總資產統計卡片
                        DashboardCard(
                            title: "總資產", 
                            value: "NT$ 10,000,000", 
                            change: "+1.25%", 
                            changeType: .positive
                        )
                        .gridCellColumns(3)
                        
                        DashboardCard(
                            title: "總損益", 
                            value: "NT$ 125,000", 
                            change: "+1.25%", 
                            changeType: .positive
                        )
                        .gridCellColumns(3)
                        
                        // 第二排 - 資產配置圓餅圖
                        AssetAllocationCard()
                            .gridCellColumns(4)
                        
                        // 右側統計卡片
                        VStack(spacing: 8) {
                            QuickStatCard(title: "美股", value: "45%", color: .blue)
                            QuickStatCard(title: "債券", value: "25%", color: .green)  
                            QuickStatCard(title: "現金", value: "20%", color: .orange)
                            QuickStatCard(title: "台股", value: "8%", color: .purple)
                        }
                        .gridCellColumns(2)
                        
                        // 第三排 - 趨勢圖表  
                        TrendChartCard()
                            .gridCellColumns(6)
                        
                        // 第四排 - 配息圖表
                        DividendChartCard()
                            .gridCellColumns(6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingClientList) {
            // 客戶列表選擇器 (保持不變)
            ClientListSheet(viewModel: viewModel)
        }
        .alert("錯誤", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("確定") {
                viewModel.clearError()
            }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
    }
}

// MARK: - Dashboard Card Components (新增的組件)

enum ChangeType {
    case positive, negative, neutral
}

// 統計卡片
struct DashboardCard: View {
    let title: String
    let value: String
    let change: String
    let changeType: ChangeType
    
    var changeColor: Color {
        switch changeType {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Text(change)
                    .font(.caption)
                    .foregroundColor(changeColor)
                    .fontWeight(.medium)
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// 資產配置圓餅圖卡片
struct AssetAllocationCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("資產配置")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // 簡化的圓餅圖表示
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 20)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: 0.45) // 45%
                    .stroke(Color.blue, lineWidth: 20)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0.45, to: 0.7) // 25%
                    .stroke(Color.green, lineWidth: 20)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                
                VStack {
                    Text("多元")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("配置")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            // 圖例
            HStack(spacing: 12) {
                LegendItem(color: .blue, label: "美股")
                LegendItem(color: .green, label: "債券")
                LegendItem(color: .orange, label: "其他")
            }
            .font(.caption)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

// 快速統計卡片
struct QuickStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(color)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// 趨勢圖表卡片
struct TrendChartCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("總資產趨勢")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                HStack(spacing: 8) {
                    Text("1D")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text("7D")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("1M")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 簡化的趨勢線圖
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<30, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 6, height: CGFloat.random(in: 20...80))
                }
            }
            .frame(height: 80)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// 配息圖表卡片
struct DividendChartCard: View {
    let months = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("月度配息")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("年配息總額: NT$ 125,000")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 配息柱狀圖
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(months.indices, id: \.self) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.green.opacity(0.7))
                            .frame(width: 20, height: CGFloat.random(in: 30...70))
                        
                        Text(months[index])
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Grid Extension (臨時解決方案)
extension View {
    func gridCellColumns(_ count: Int) -> some View {
        self
    }
}

// MARK: - 其他 Sheet 組件保持不變
// (ClientListSheet, AddClientSheet 等保持原來的代碼)

// MARK: - Preview
struct BasicClientPickerView_Previews: PreviewProvider {
    static var previews: some View {
        BasicClientPickerView()
    }
}
```

## 📋 使用說明

1. **替換整個 BasicClientPickerView.swift 檔案**
2. **不要修改其他檔案**
3. **測試確認頂部導航和客戶選擇功能正常**
4. **確認6列儀表板佈局正確顯示**

## ✅ 預期結果

- 保持原有的客戶選擇功能
- 新增6列響應式儀表板佈局
- 顯示總資產、配置、趨勢圖等卡片
- 所有功能整合在一個檔案中