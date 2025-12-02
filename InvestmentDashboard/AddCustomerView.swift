import SwiftUI
import CoreData

struct AddClientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var birthDate = Date()
    @State private var hasBirthDate = false
    @State private var idNumber = ""
    @State private var phoneNumber = ""

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("客戶姓名", text: $name)
                    TextField("電子郵件", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("身分證", text: $idNumber)
                    TextField("手機", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("出生年月日") {
                    Toggle("已設定出生年月日", isOn: $hasBirthDate)

                    if hasBirthDate {
                        DatePicker(
                            "出生日期",
                            selection: $birthDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.wheel)
                        .environment(\.locale, Locale(identifier: "zh_TW"))
                    }
                }
            }
            .navigationTitle("新增客戶")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveClient()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveClient() {
        withAnimation {
            let newClient = Client(context: viewContext)
            newClient.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            newClient.email = email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
            newClient.idNumber = idNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : idNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            newClient.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            newClient.birthDate = hasBirthDate ? birthDate : nil
            newClient.createdDate = Date()
            newClient.recordName = UUID().uuidString

            // 設定排序順序：取得目前最大的 sortOrder，新客戶排在最後
            let fetchRequest: NSFetchRequest<Client> = Client.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Client.sortOrder, ascending: false)]
            fetchRequest.fetchLimit = 1

            if let maxSortOrderClient = try? viewContext.fetch(fetchRequest).first {
                newClient.sortOrder = maxSortOrderClient.sortOrder + 1
            } else {
                newClient.sortOrder = 0
            }

            do {
                try viewContext.save()
                // 強制推送到 CloudKit
                PersistenceController.shared.save()
                print("客戶已成功儲存到 iCloud（sortOrder: \(newClient.sortOrder)）")
                dismiss()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}