import SwiftUI

struct BasicClientPickerView: View {
    @StateObject private var viewModel = ClientViewModel()

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    if geometry.size.width > 700 {
                        // iPad 佈局
                        iPadLayout
                    } else {
                        // iPhone 佈局
                        iPhoneLayout
                    }
                }
                .background(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.init(red: 0.98, green: 0.99, blue: 1.0, alpha: 1.0)),
                        Color(.init(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0))
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            }
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
        .sheet(isPresented: $viewModel.showingClientList) {
            ClientListView(viewModel: viewModel)
        }
    }

    // MARK: - iPad 佈局
    private var iPadLayout: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top, spacing: 24) {
                // 左側：主要統計卡片
                mainStatsCardForDesktop
                    .frame(width: 400)

                // 右側：資產配置圓餅圖
                assetAllocationCard
                    .frame(width: 280)
            }
            .frame(maxWidth: .infinity)

            // 投資卡片行
            HStack(spacing: 16) {
                investmentCard(
                    title: "美股投資",
                    amount: "4,500,000",
                    percentage: "45%",
                    change: "+2.3%",
                    isPositive: true,
                    color: Color(.init(red: 0.33, green: 0.73, blue: 0.46, alpha: 1.0))
                )

                investmentCard(
                    title: "債券投資",
                    amount: "2,500,000",
                    percentage: "25%",
                    change: "+1.8%",
                    isPositive: true,
                    color: Color(.init(red: 0.20, green: 0.51, blue: 0.85, alpha: 1.0))
                )

                simpleBondDividendCard
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)

            // 底部：月度資產明細表格 - 暫時移除
            // MonthlyAssetTableView()
            //     .padding(.horizontal, 24)
            //     .padding(.bottom, 20)
        }
    }

    // MARK: - iPhone 佈局
    private var iPhoneLayout: some View {
        VStack(spacing: 16) {
            // 主要統計卡片
            mainStatsCard

            // 資產配置卡片
            assetAllocationCard

            // 投資卡片行
            investmentCardsRow

            // iPhone 版本也加入表格（暫時移除）
            // MonthlyAssetTableView()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - 主要統計卡片（桌面版）
    private var mainStatsCardForDesktop: some View {
        VStack(spacing: 0) {
            // 上半部：整合統計卡片
            integratedStatsCard

            // 下半部：走勢圖
            simpleTrendChart
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - 主要統計卡片（手機版）
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 底部統計行
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("總匯入")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                    Text("9,875,000")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("現金")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                    Text("2,000,000")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("總額報酬率")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                    Text("+1.2%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(.init(red: 0.27, green: 0.51, blue: 0.38, alpha: 1.0)))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - 整合統計卡片
    private var integratedStatsCard: some View {
        VStack(spacing: 24) {
            // 總資產標題
            HStack {
                Text("總資產")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)))
                Spacer()
            }

            // 主要數字
            HStack {
                Text("10,000,000")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(Color(.init(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)))
                Spacer()
            }

            // 損益資訊
            HStack {
                Text("總損益: ")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)))
                + Text("+125,000 (+1.25%)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.init(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0)))
                Spacer()
            }

            // 統計網格
            HStack(spacing: 20) {
                // 總匯入卡片
                VStack(alignment: .leading, spacing: 8) {
                    Text("總匯入")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                    Text("9,875,000")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(.init(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.init(red: 0.97, green: 0.98, blue: 1.0, alpha: 1.0)))
                )

                // 現金卡片
                VStack(alignment: .leading, spacing: 8) {
                    Text("現金")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                    Text("2,000,000")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(.init(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.init(red: 0.95, green: 0.97, blue: 0.98, alpha: 1.0)))
                )

                // 報酬率卡片
                VStack(alignment: .leading, spacing: 8) {
                    Text("總額報酬率")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                    Text("+1.2%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(.init(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0)))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.init(red: 0.9, green: 0.98, blue: 0.93, alpha: 1.0)),
                            Color(.init(red: 0.92, green: 1.0, blue: 0.95, alpha: 1.0))
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .mask(RoundedRectangle(cornerRadius: 12))
                )

                Spacer()
            }
        }
        .padding(24)
    }

    // MARK: - 資產配置卡片
    private var assetAllocationCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("資產配置")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(.init(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)))
                Spacer()
                Text("總投資")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
            }

            // 圓餅圖區域
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 12)
                    .frame(width: 140, height: 140)

                // 美股 45%
                Circle()
                    .trim(from: 0, to: 0.45)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)),
                                Color(.init(red: 0.4, green: 0.9, blue: 0.5, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 債券 25%
                Circle()
                    .trim(from: 0.45, to: 0.70)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)),
                                Color(.init(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 現金 20%
                Circle()
                    .trim(from: 0.70, to: 0.90)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.9, green: 0.4, blue: 0.4, alpha: 1.0)),
                                Color(.init(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 台股 8%
                Circle()
                    .trim(from: 0.90, to: 0.98)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.6, green: 0.3, blue: 0.8, alpha: 1.0)),
                                Color(.init(red: 0.7, green: 0.4, blue: 0.9, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 結構型 2%
                Circle()
                    .trim(from: 0.98, to: 1.0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.init(red: 0.9, green: 0.6, blue: 0.1, alpha: 1.0)),
                                Color(.init(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // 中心文字
                VStack(spacing: 2) {
                    Text("總額")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                    Text("10M")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(.init(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)))
                }
            }

            // 圖例
            VStack(alignment: .leading, spacing: 10) {
                legendItem(color: Color(.init(red: 0.3, green: 0.85, blue: 0.45, alpha: 1.0)), title: "美股", percentage: "45%", amount: "4,500,000")
                legendItem(color: Color(.init(red: 0.25, green: 0.5, blue: 0.85, alpha: 1.0)), title: "債券", percentage: "25%", amount: "2,500,000")
                legendItem(color: Color(.init(red: 0.95, green: 0.45, blue: 0.45, alpha: 1.0)), title: "現金", percentage: "20%", amount: "2,000,000")
                legendItem(color: Color(.init(red: 0.65, green: 0.35, blue: 0.85, alpha: 1.0)), title: "台股", percentage: "8%", amount: "800,000")
                legendItem(color: Color(.init(red: 0.95, green: 0.65, blue: 0.15, alpha: 1.0)), title: "結構型", percentage: "2%", amount: "200,000")
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }

    // 圖例項目
    private func legendItem(color: Color, title: String, percentage: String, amount: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)))
                Text(amount)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
            }

            Spacer()

            Text(percentage)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.1))
                )
        }
    }

    // MARK: - 投資卡片行（手機版）
    private var investmentCardsRow: some View {
        HStack(spacing: 12) {
            investmentCard(
                title: "美股投資",
                amount: "4,500,000",
                percentage: "45%",
                change: "+2.3%",
                isPositive: true,
                color: Color(.init(red: 0.33, green: 0.73, blue: 0.46, alpha: 1.0))
            )

            investmentCard(
                title: "債券投資",
                amount: "2,500,000",
                percentage: "25%",
                change: "+1.8%",
                isPositive: true,
                color: Color(.init(red: 0.20, green: 0.51, blue: 0.85, alpha: 1.0))
            )
        }
    }

    // 投資卡片
    private func investmentCard(title: String, amount: String, percentage: String, change: String, isPositive: Bool, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題與百分比
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(.init(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)))
                    Text("投資組合")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)))
                }
                Spacer()
                Text(percentage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(10)
            }

            // 金額
            Text(amount)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(.init(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)))

            // 變動與趨勢
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isPositive ? Color(.init(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0)) : Color(.init(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)))
                    Text(change)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isPositive ? Color(.init(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0)) : Color(.init(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill((isPositive ? Color(.init(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0)) : Color(.init(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0))).opacity(0.1))
                )

                Spacer()
            }

            // 簡化的趨勢圖
            HStack(spacing: 2) {
                ForEach(0..<8) { index in
                    Rectangle()
                        .fill(color.opacity(0.6))
                        .frame(width: 3, height: CGFloat.random(in: 8...20))
                        .cornerRadius(1.5)
                }
            }
            .frame(height: 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            color.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        )
    }

    // MARK: - 簡單債券配息卡片
    private var simpleBondDividendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("債券每月配息")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                Spacer()
            }

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<12) { month in
                        VStack {
                            Rectangle()
                                .fill(Color(.init(red: 0.33, green: 0.73, blue: 0.46, alpha: 1.0)))
                                .frame(width: 16, height: CGFloat.random(in: 20...40))
                                .cornerRadius(2)

                            Text("\(month + 1)")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("預期年配息")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.8))
                    Text("+1.2%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.init(red: 0.33, green: 0.73, blue: 0.46, alpha: 1.0)),
                                    Color(.init(red: 0.18, green: 0.52, blue: 0.29, alpha: 1.0))
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: 280, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - 簡化走勢圖
    private var simpleTrendChart: some View {
        ZStack {
            // 背景漸層
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.init(red: 0.96, green: 0.45, blue: 0.45, alpha: 0.3)),
                            Color(.init(red: 0.96, green: 0.45, blue: 0.45, alpha: 0.1))
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // 簡化線條
            Path { path in
                let points: [(CGFloat, CGFloat)] = [
                    (0, 0.7), (0.2, 0.5), (0.4, 0.6), (0.6, 0.3), (0.8, 0.4), (1.0, 0.2)
                ]

                for (index, point) in points.enumerated() {
                    let x = point.0 * 350
                    let y = point.1 * 60 + 20

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color(.init(red: 0.96, green: 0.45, blue: 0.45, alpha: 1.0)), lineWidth: 2)

            // 標題
            VStack {
                HStack {
                    Text("總資產走勢")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                    Spacer()
                }
                Spacer()
            }
            .padding(16)
        }
        .frame(height: 100)
        .background(Color.white)
    }
}

// MARK: - 客戶列表視圖
struct ClientListView: View {
    @ObservedObject var viewModel: ClientViewModel

    var body: some View {
        NavigationView {
            List(viewModel.clients) { client in
                VStack(alignment: .leading) {
                    Text(client.name)
                        .font(.headline)
                    Text(client.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onTapGesture {
                    viewModel.selectClient(client)
                    viewModel.showingClientList = false
                }
            }
            .navigationTitle("選擇客戶")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        viewModel.showingClientList = false
                    }
                }
            }
        }
    }
}

struct BasicClientPickerView_Previews: PreviewProvider {
    static var previews: some View {
        BasicClientPickerView()
    }
}