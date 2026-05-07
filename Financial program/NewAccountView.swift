//
//  NewAccountView.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-04-29.
//

import SwiftUI

struct NewAccountView: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (Account) -> Void

    @State private var name = ""
    @State private var currency = "USD"

    let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "CHF", "JPY", "CNY"]

    var body: some View {
        VStack(spacing: 24) {
            Text("New Account")
                .font(.headline)
                .padding(.top, 16)

            Divider()

            VStack(spacing: 20) {
                // Account name field
                VStack(spacing: 8) {
                    Text("Account Name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("e.g. Main, Savings, Business", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }

                // Currency picker
                VStack(spacing: 8) {
                    Text("Currency")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
#if os(iOS)
                    Picker("", selection: $currency) {
                        ForEach(currencies, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: 280)
#else
                    Picker("", selection: $currency) {
                        ForEach(currencies, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
#endif
                }
            }

            Spacer()

            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("Create") {
                    onCreate(Account(name: name, currency: currency))
                    dismiss()
                }
                .disabled(name.isEmpty)
                .keyboardShortcut(.defaultAction)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(name.isEmpty ? Color.accentColor.opacity(0.4) : Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
#if os(macOS)
        .frame(width: 360, height: 280)
#endif
    }
}
