import SwiftUI

struct CompactClientPickerView: View {
    @StateObject private var viewModel = ClientViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 主要統計區域
                    mainStatsCard
                    
                    // 資產配置卡片
                    assetAllocationCard
                    
                    // 投資卡片行
                    investmentCardsRow
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Color(.init(red: 0.97, green: 0.97, blue: 0.975, alpha: 1.0)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("☰") { viewModel.showClientList() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("+") { }
                }
            }
        }
    }
    
    // MARK: - 主要統計卡片
    private var mainStatsCard: some View {
        VStack(spacing: 16) {
            // 頂部總資產區域
            VStack(alignment: .leading, spacing: 12) {
                Text("總資產")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                
                Text("10,000,000")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                
                Text("總損益: +125,000 (+1.25%)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
                
                // 時間按鈕
                HStack(spacing: 8) {
                    ForEach(["1D", "7D", "1M", "3M", "1Y"], id: \.self) { period in
                        Button(period) { }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(period == "1D" ? Color.black : Color.gray.opacity(0.2))
                            .foregroundColor(period == "1D" ? .white : .black)
                            .clipShape(Capsule())
                    }
                }
            }
            
            // 2x2 統計卡片
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                // 總匯入
                statsCard(title: "總匯入", value: "1,500,000", subtitle: "本月 +5.2%", isHighlight: false)
                
                // 總額報酬率 (高亮)
                statsCard(title: "總額報酬率", value: "+8.5%", subtitle: "較上月 +1.2%", isHighlight: true)
                
                // 現金
                statsCard(title: "現金", value: "250,000", subtitle: "活存 0.5%", isHighlight: false)
                
                // 本月收益
                statsCard(title: "本月收益", value: "+25,000", subtitle: "+2.8%", isHighlight: false)
            }
            
            // 走勢圖
            trendChart
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - 統計卡片
    private func statsCard(title: String, value: String, subtitle: String, isHighlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isHighlight ? .white.opacity(0.9) : Color(.init(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)))
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(isHighlight ? .white : Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
            
            Text(subtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(isHighlight ? .white.opacity(0.8) : Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isHighlight ? 
                    LinearGradient(
                        colors: [
                            Color(.init(red: 0.33, green: 0.73, blue: 0.46, alpha: 1.0)),
                            Color(.init(red: 0.18, green: 0.52, blue: 0.29, alpha: 1.0))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(colors: [Color.white], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: isHighlight ? Color(.init(red: 0.18, green: 0.52, blue: 0.29, alpha: 0.3)) : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - 走勢圖
    private var trendChart: some View {
        ZStack {
            // 簡化趨勢線
            HStack(alignment: .bottom, spacing: 1) {
                ForEach(0..<50, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.init(red: 0.40, green: 0.62, blue: 0.47, alpha: 0.6)),
                                    Color(.init(red: 0.40, green: 0.62, blue: 0.47, alpha: 0.2))
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: CGFloat.random(in: 12...36))
                }
            }
            
            // 浮動標籤
            VStack {
                HStack {
                    Spacer()
                    Text("+1.25%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
                }
                Spacer()
                HStack {
                    Text("過去 24 小時")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
            .padding(8)
        }
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
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
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i == 0 ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            ZStack {
                // 圓餅圖
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 120, height: 120)
                
                // 各段
                Circle()
                    .trim(from: 0, to: 0.2)
                    .stroke(Color.orange, lineWidth: 20)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0.2, to: 0.45)
                    .stroke(Color.gray, lineWidth: 20)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0.45, to: 0.9)
                    .stroke(Color.red, lineWidth: 20)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0.9, to: 0.98)
                    .stroke(Color.green, lineWidth: 20)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                
                // 中心文字
                VStack {
                    Text("45%")
                        .font(.system(size: 18, weight: .bold))
                    Text("美股")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            // 圖例
            VStack(spacing: 4) {
                legendItem(color: .orange, title: "現金", percentage: "20%")
                legendItem(color: .gray, title: "債券", percentage: "25%")
                legendItem(color: .red, title: "美股", percentage: "45%")
                legendItem(color: .green, title: "台股", percentage: "8%")
                legendItem(color: .blue, title: "結構型", percentage: "2%")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    private func legendItem(color: Color, title: String, percentage: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(percentage)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black)
        }
    }
    
    // MARK: - 投資卡片行
    private var investmentCardsRow: some View {
        HStack(spacing: 12) {
            // 美股卡片
            investmentCard(title: "美股", value: "4,500,000", change: "+12%", isPositive: true)
            
            // 債券卡片
            investmentCard(title: "債券", value: "2,500,000", change: "+3%", isPositive: true)
        }
    }
    
    private func investmentCard(title: String, value: String, change: String, isPositive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                Text(change)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isPositive ? Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)) : .red)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
            
            // 簡化走勢
            HStack(alignment: .bottom, spacing: 1) {
                ForEach(0..<15, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color(.init(red: 0.40, green: 0.62, blue: 0.47, alpha: 0.6)))
                        .frame(width: 2, height: CGFloat.random(in: 4...16))
                }
            }
            .frame(height: 20)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

struct CompactClientPickerView_Previews: PreviewProvider {
    static var previews: some View {
        CompactClientPickerView()
    }
}