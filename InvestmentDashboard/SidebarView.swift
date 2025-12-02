import SwiftUI
import CoreData

struct SidebarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>

    @Binding var selectedClient: Client?
    @Binding var showingAddCustomer: Bool

    @StateObject private var backupManager = BackupManager.shared
    @State private var showingBackupAlert = false
    @State private var showingRestoreAlert = false
    @State private var showingRestoreConfirm = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            List {
                Section("客戶列表") {
                    ForEach(clients, id: \.self) { client in
                        ClientRowView(client: client, selectedClient: $selectedClient)
                    }
                    .onDelete(perform: deleteClients)
                }

                Section("資料管理") {
                    // 備份按鈕
                    Button(action: {
                        performBackup()
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("備份到 iCloud")
                                if let lastBackup = backupManager.lastBackupDate {
                                    Text("最近備份：\(lastBackup, formatter: backupDateFormatter)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("尚未備份")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if backupManager.isBackingUp {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(backupManager.isBackingUp)

                    // 還原按鈕
                    Button(action: {
                        showingRestoreConfirm = true
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down.fill")
                                .foregroundColor(.orange)
                            Text("從 iCloud 還原")
                            Spacer()
                            if backupManager.isRestoring {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(backupManager.isRestoring)
                }

                Section("關於") {
                    Link(destination: URL(string: "https://owen1221111.github.io/investmentdashboard-legal/privacy-zh.html")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.blue)
                            Text("隱私權政策")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://owen1221111.github.io/investmentdashboard-legal/terms-zh.html")!) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                            Text("使用條款")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "mailto:stockbankapp@gmail.com")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            Text("聯絡我們")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("版本")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("客戶")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddCustomer = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                // 檢查 iCloud 狀態
                PersistenceController.shared.checkCloudKitStatus()
            }
            .alert("備份結果", isPresented: $showingBackupAlert) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .alert("還原結果", isPresented: $showingRestoreAlert) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .confirmationDialog("確認還原", isPresented: $showingRestoreConfirm, titleVisibility: .visible) {
                Button("還原資料", role: .destructive) {
                    performRestore()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("還原將會新增備份中的資料，建議先確認現有資料已備份。確定要繼續嗎？")
            }
        }
    }

    // MARK: - 備份功能

    private func performBackup() {
        backupManager.backup(context: viewContext) { success, error in
            if success {
                alertMessage = "備份成功！資料已儲存到 iCloud 雲碟"
            } else {
                alertMessage = "備份失敗：\(error ?? "未知錯誤")"
            }
            showingBackupAlert = true
        }
    }

    private func performRestore() {
        backupManager.restore(context: viewContext) { success, error in
            if success {
                alertMessage = "還原成功！請重新選擇客戶查看資料"
            } else {
                alertMessage = "還原失敗：\(error ?? "未知錯誤")"
            }
            showingRestoreAlert = true
        }
    }

    private var backupDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }


    private func deleteClients(offsets: IndexSet) {
        withAnimation {
            offsets.map { clients[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
                // 強制推送刪除到 CloudKit
                PersistenceController.shared.save()
                print("客戶已從 iCloud 刪除")
            } catch {
                print("Delete error: \(error)")
            }
        }
    }
}

struct ClientRowView: View {
    let client: Client
    @Binding var selectedClient: Client?

    var body: some View {
        Button(action: {
            selectedClient = client
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(client.name ?? "未知客戶")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    if selectedClient == client {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }

                if let email = client.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let createdDate = client.createdDate {
                    Text("創建於 \(createdDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
