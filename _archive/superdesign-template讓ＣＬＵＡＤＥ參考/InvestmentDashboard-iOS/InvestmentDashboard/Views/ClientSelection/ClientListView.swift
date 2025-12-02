import SwiftUI

struct ClientListView: View {
    @ObservedObject var viewModel: ClientViewModel
    @State private var sortByDateAscending = true

    var body: some View {
        VStack(spacing: 0) {
            // 標題區域
            HStack(spacing: 16) {
                Text("選擇客戶")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("+ 新增") {
                    viewModel.showAddClient()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.hideClientList()
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green)
                .cornerRadius(6)

                Button("✕") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.hideClientList()
                    }
                }
                .font(.title2)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)

            // 中間內容區域
            if viewModel.isLoading {
                VStack {
                    ProgressView("載入客戶資料...")
                        .padding()
                }
            } else if viewModel.clients.isEmpty {
                VStack(spacing: 16) {
                    Text("無客戶資料")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()

                    Button("創建測試客戶") {
                        Task {
                            await viewModel.createTestClients()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("重新載入") {
                        Task {
                            await viewModel.loadClients()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sortedClients, id: \.id) { client in
                            clientRow(for: client)
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }

        }
        .onAppear {
            print("🔍 ClientListView appeared - clients count: \(viewModel.clients.count)")
            print("🔍 ClientListView appeared - isLoading: \(viewModel.isLoading)")
            print("🔍 ClientListView appeared - isSignedInToiCloud: \(viewModel.isSignedInToiCloud)")
            Task {
                await viewModel.loadClients()
            }
        }
    }

    // MARK: - 輔助計算屬性和函數

    private var sortedClients: [Client] {
        viewModel.clients.sorted { client1, client2 in
            if sortByDateAscending {
                return client1.createdDate < client2.createdDate
            } else {
                return client1.createdDate > client2.createdDate
            }
        }
    }

    private func clientRow(for client: Client) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectClient(client)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.hideClientList()
            }
        }) {
            HStack(spacing: 12) {
                // 客戶頭像 (圓形圖標)
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(client.name.prefix(1)))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                    )

                // 客戶信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(client.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(client.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 選中狀態指示器
                if viewModel.selectedClient?.id == client.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("編輯客戶") {
                viewModel.showEditClient(client)
            }
            Button("刪除客戶", role: .destructive) {
                Task {
                    await viewModel.deleteClient(client)
                }
            }
        }
    }
}