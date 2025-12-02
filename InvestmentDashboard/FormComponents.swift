//
//  FormComponents.swift
//  InvestmentDashboard
//
//  Created by Claude on 2025/10/14.
//

import SwiftUI

// MARK: - 表單欄位元件
struct FormField: View {
    let label: String
    let icon: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isRequired: Bool = false
    var onChange: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
            }

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(Color(.init(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(text.isEmpty && isRequired ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .onChange(of: text) { _ in
                    onChange?()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 選擇器欄位元件
struct PickerField: View {
    let label: String
    let icon: String
    @Binding var value: String
    let placeholder: String
    var isRequired: Bool = false
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)))
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
            }

            Button(action: onTap) {
                HStack {
                    Text(value.isEmpty ? placeholder : value)
                        .foregroundColor(value.isEmpty ? .gray : Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(Color(.init(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(value.isEmpty && isRequired ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 選擇器 Sheet
struct PickerSheet: View {
    @Environment(\.presentationMode) var presentationMode
    let title: String
    let options: [String]
    @Binding var selectedOption: String

    var body: some View {
        NavigationView {
            List {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selectedOption = option
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(option)
                                .font(.system(size: 16))
                                .foregroundColor(Color(.init(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)))
                            Spacer()
                            if selectedOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
