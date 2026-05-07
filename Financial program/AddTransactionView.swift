//
//  AddTransactionView.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-04-29.
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allCategories: [Category]

    let account: Account
    let type: TransactionType

    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var selectedCategory: Category?

    init(account: Account, type: TransactionType) {
        self.account = account
        self.type = type
    }

    var relevantCategories: [Category] {
        allCategories
            .filter { type == .deposit ? $0.isIncome : !$0.isIncome }
            .sorted { $0.name < $1.name }
    }

    var isValid: Bool {
        !title.isEmpty && Double(amount) != nil && Double(amount)! > 0 && selectedCategory != nil
    }

    var body: some View {
        VStack(spacing: 0) {

            // Title bar
            Text(type == .payment ? "Add Payment" : "Add Deposit")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(spacing: 24) {

                    // Details section
                    sectionCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Details")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            TextField(
                                type == .payment
                                    ? "What was it? (e.g. Shell, Walmart)"
                                    : "Source (e.g. Salary, Transfer)",
                                text: $title
                            )
                            .textFieldStyle(.roundedBorder)
#if os(iOS)
                            .keyboardType(.default)
#endif

                            HStack(spacing: 10) {
                                Text(account.currency)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 7))

                                TextField("Amount", text: $amount)
                                    .textFieldStyle(.roundedBorder)
#if os(iOS)
                                    .keyboardType(.decimalPad)
#endif
                            }
                        }
                    }

                    // Category section
                    sectionCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Category")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            if relevantCategories.isEmpty {
                                Text("No categories yet — add some in Manage Categories")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(relevantCategories) { cat in
                                            let isSelected = selectedCategory?.id == cat.id
                                            VStack(spacing: 6) {
                                                Text(cat.emoji)
                                                    .font(.title2)
                                                    .frame(width: 52, height: 52)
                                                    .background(isSelected
                                                        ? Color.accentColor.opacity(0.2)
                                                        : Color.secondary.opacity(0.1))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(isSelected
                                                                    ? Color.accentColor
                                                                    : Color.clear,
                                                                    lineWidth: 2)
                                                    )
                                                Text(cat.name)
                                                    .font(.caption2)
                                                    .foregroundStyle(isSelected
                                                                     ? Color.accentColor
                                                                     : .secondary)
                                                    .lineLimit(1)
                                            }
                                            .onTapGesture { selectedCategory = cat }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }

                    // Date section
                    sectionCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Date")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            DatePicker("", selection: $date, displayedComponents: [.date])
                                .labelsHidden()
#if os(macOS)
                                .datePickerStyle(.field)
#else
                                .datePickerStyle(.compact)
#endif
                        }
                    }
                }
                .padding(20)
            }

            Divider()

            // Bottom buttons
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isValid ? Color.accentColor : Color.accentColor.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .onAppear {
            if selectedCategory == nil {
                selectedCategory = relevantCategories.first
            }
        }
#if os(macOS)
        .frame(minWidth: 420, minHeight: 480)
#endif
    }

    // MARK: - Section card helper
    @ViewBuilder
    func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Save
    private func save() {
        guard let amt = Double(amount), let cat = selectedCategory else { return }
        let tx = Transaction(
            title: title,
            amount: amt,
            currency: account.currency,
            category: cat,
            type: type,
            date: date
        )
        tx.account = account
        account.transactions.append(tx)
        modelContext.insert(tx)
        try? modelContext.save()
        dismiss()
    }
}
