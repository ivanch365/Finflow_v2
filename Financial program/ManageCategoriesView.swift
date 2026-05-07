//
//  ManageCategoriesView.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-04-29.
//

import SwiftUI
import SwiftData

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allCategories: [Category]

    @State private var showAddCategory = false
    @State private var addingIncome = false

    var expenseCategories: [Category] {
        allCategories.filter { !$0.isIncome }.sorted { $0.name < $1.name }
    }
    var incomeCategories: [Category] {
        allCategories.filter { $0.isIncome }.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(expenseCategories) { cat in
                        CategoryRow(category: cat, onDelete: {
                            deleteCategory(cat)
                        })
#if os(iOS)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteCategory(cat)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
#endif
                    }
                    Button {
                        addingIncome = false
                        showAddCategory = true
                    } label: {
                        Label("Add Expense Category", systemImage: "plus")
                            .foregroundStyle(Color.accentColor)
                    }
                } header: {
                    Text("Expense Categories")
                }

                Section {
                    ForEach(incomeCategories) { cat in
                        CategoryRow(category: cat, onDelete: {
                            deleteCategory(cat)
                        })
#if os(iOS)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteCategory(cat)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
#endif
                    }
                    Button {
                        addingIncome = true
                        showAddCategory = true
                    } label: {
                        Label("Add Income Category", systemImage: "plus")
                            .foregroundStyle(Color.accentColor)
                    }
                } header: {
                    Text("Income Categories")
                }
            }
            .navigationTitle("Manage Categories")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView(isIncome: addingIncome)
        }
    }

    private func deleteCategory(_ cat: Category) {
        modelContext.delete(cat)
        try? modelContext.save()
    }
}

struct CategoryRow: View {
    let category: Category
    let onDelete: () -> Void
    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 12) {
            Text(category.emoji)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(category.name)
                .font(.subheadline)

            Spacer()

#if os(macOS)
            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Color.red.opacity(0.8))
                    .padding(6)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .confirmationDialog(
                "Delete \"\(category.name)\"?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { onDelete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Existing transactions using this category will keep the category name.")
            }
#endif
        }
    }
}
