//
//  AddCategoryView.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-04-29.
//
import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let isIncome: Bool

    @State private var name = ""
    @State private var emoji = ""

    // A quick emoji picker palette
    let suggestedEmojis = [
        "🏋️","🎮","✈️","🎓","🐾","🌿","☕","🎵","🏖️","🛠️",
        "🎁","🖥️","📱","🚗","⚽","🏠","💊","🧴","👗","📚",
        "🍕","🍺","🎪","🧸","🌍","💳","🏦","🎯","🧹","💡"
    ]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !emoji.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category Name") {
                    TextField("e.g. Gym, Travel, Hobbies", text: $name)
                }

                Section("Emoji") {
                    TextField("Paste or type an emoji", text: $emoji)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(suggestedEmojis, id: \.self) { e in
                                Text(e)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(emoji == e
                                                ? Color.accentColor.opacity(0.2)
                                                : Color.secondary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(emoji == e ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture { emoji = e }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    HStack(spacing: 12) {
                        Text(emoji.isEmpty ? "?" : emoji)
                            .font(.title)
                            .frame(width: 52, height: 52)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name.isEmpty ? "Category Name" : name)
                                .font(.headline)
                                .foregroundStyle(name.isEmpty ? .tertiary : .primary)
                            Text(isIncome ? "Income" : "Expense")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle(isIncome ? "New Income Category" : "New Expense Category")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let cat = Category(
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji.trimmingCharacters(in: .whitespaces),
            isIncome: isIncome
        )
        modelContext.insert(cat)
        try? modelContext.save()
        dismiss()
    }
}
