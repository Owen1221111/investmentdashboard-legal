import SwiftUI
import CoreData

struct EditClientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client

    @State private var name: String
    @State private var email: String
    @State private var birthDate: Date
    @State private var hasBirthDate: Bool
    @State private var idNumber: String
    @State private var phoneNumber: String

    init(client: Client) {
        self.client = client
        self._name = State(initialValue: client.name ?? "")
        self._email = State(initialValue: client.email ?? "")
        self._birthDate = State(initialValue: client.birthDate ?? Date())
        self._hasBirthDate = State(initialValue: client.birthDate != nil)
        self._idNumber = State(initialValue: client.idNumber ?? "")
        self._phoneNumber = State(initialValue: client.phoneNumber ?? "")
    }

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
            .navigationTitle("編輯客戶")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        updateClient()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func updateClient() {
        withAnimation {
            client.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            client.email = email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
            client.idNumber = idNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : idNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            client.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            client.birthDate = hasBirthDate ? birthDate : nil

            do {
                try viewContext.save()
                // 強制推送到 CloudKit
                PersistenceController.shared.save()
                print("客戶資料已更新到 iCloud")
                dismiss()
            } catch {
                print("Update error: \(error)")
            }
        }
    }
}
