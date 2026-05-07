//
//  TransactionsView.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-04-29.
//

import SwiftUI
import SwiftData

struct TransactionsView: View {
    let account: Account
    let onSwitchAccount: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var activeTransactionType: TransactionType? = nil
    @State private var filterStart: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var filterEnd: Date = Date()
    @State private var isFiltering = false
    @State private var showFilterSheet = false
    @State private var showExitConfirm = false

    // Multi-select
    @State private var isSelecting = false
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var showDeleteSelectedConfirm = false

    var filteredTransactions: [Transaction] {
        let txs = account.transactions.sorted { $0.date > $1.date }
        if isFiltering {
            return txs.filter { $0.date >= filterStart && $0.date <= filterEnd }
        }
        return txs
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor").ignoresSafeArea()

                VStack(spacing: 0) {

                    // Balance card
                    balanceCard
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Filter badge
                    if isFiltering {
                        filterBadge
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    // Selection action bar
                    if isSelecting && !selectedIDs.isEmpty {
                        HStack {
                            Text("\(selectedIDs.count) selected")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(role: .destructive) {
                                showDeleteSelectedConfirm = true
                            } label: {
                                Label("Delete Selected", systemImage: "trash")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.red)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.08))
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Inline Add buttons
                    if !isSelecting {
                        HStack(spacing: 12) {
                            Button {
                                activeTransactionType = .payment
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill")
                                    Text("Add Payment")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.12))
                                .foregroundStyle(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)

                            Button {
                                activeTransactionType = .deposit
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Add Deposit")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green.opacity(0.12))
                                .foregroundStyle(Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }

                    // Transaction list or empty state
                    if filteredTransactions.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundStyle(.tertiary)
                            Text("No transactions")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredTransactions) { tx in
                                transactionRow(tx)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
#if os(iOS)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        if !isSelecting {
                                            Button(role: .destructive) {
                                                deleteTransaction(tx)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
#endif
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(account.name)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar { toolbarContent }
            .sheet(item: $activeTransactionType) { type in
                AddTransactionView(account: account, type: type)
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterView(start: $filterStart, end: $filterEnd, isFiltering: $isFiltering)
            }
            .confirmationDialog(
                "Are you sure you want to exit?",
                isPresented: $showExitConfirm,
                titleVisibility: .visible
            ) {
                Button("Exit App", role: .destructive) { exit(0) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The app will close.")
            }
            .confirmationDialog(
                "Delete \(selectedIDs.count) transaction\(selectedIDs.count == 1 ? "" : "s")?",
                isPresented: $showDeleteSelectedConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All Selected", role: .destructive) {
                    deleteSelected()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    // MARK: - Transaction row
    @ViewBuilder
    func transactionRow(_ tx: Transaction) -> some View {
        let isSelected = selectedIDs.contains(tx.persistentModelID)

        HStack(spacing: 12) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .font(.title3)
                    .onTapGesture { toggleSelection(tx) }
            }

            TransactionRow(transaction: tx)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isSelecting { toggleSelection(tx) }
                }

#if os(macOS)
            if !isSelecting {
                Button {
                    deleteTransaction(tx)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.red.opacity(0.7))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
#endif
        }
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
#if os(iOS)
        ToolbarItem(placement: .navigationBarLeading) {
            Button { onSwitchAccount() } label: {
                Label("Home", systemImage: "house.fill")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Button(role: .destructive) {
                    showExitConfirm = true
                } label: {
                    Label("Exit App", systemImage: "xmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                isSelecting.toggle()
                if !isSelecting { selectedIDs.removeAll() }
            } label: {
                Text(isSelecting ? "Done" : "Select")
                    .font(.subheadline)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { showFilterSheet = true } label: {
                Image(systemName: isFiltering
                      ? "line.3.horizontal.decrease.circle.fill"
                      : "line.3.horizontal.decrease.circle")
            }
        }
#else
        ToolbarItem {
            Button { onSwitchAccount() } label: {
                Label("Home", systemImage: "house.fill")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .help("Back to accounts")
        }
        ToolbarItem {
            Button(role: .destructive) { showExitConfirm = true } label: {
                Image(systemName: "xmark.circle")
            }
        }
        ToolbarItem {
            Button {
                isSelecting.toggle()
                if !isSelecting { selectedIDs.removeAll() }
            } label: {
                Text(isSelecting ? "Done" : "Select")
            }
        }
        ToolbarItem {
            Button { showFilterSheet = true } label: {
                Image(systemName: isFiltering
                      ? "line.3.horizontal.decrease.circle.fill"
                      : "line.3.horizontal.decrease.circle")
            }
        }
#endif
    }

    // MARK: - Helpers
    private func toggleSelection(_ tx: Transaction) {
        if selectedIDs.contains(tx.persistentModelID) {
            selectedIDs.remove(tx.persistentModelID)
        } else {
            selectedIDs.insert(tx.persistentModelID)
        }
    }

    private func deleteSelected() {
        let toDelete = account.transactions.filter { selectedIDs.contains($0.persistentModelID) }
        for tx in toDelete {
            account.transactions.removeAll { $0.persistentModelID == tx.persistentModelID }
            modelContext.delete(tx)
        }
        try? modelContext.save()
        selectedIDs.removeAll()
        isSelecting = false
    }

    private func deleteTransaction(_ tx: Transaction) {
        account.transactions.removeAll { $0.persistentModelID == tx.persistentModelID }
        modelContext.delete(tx)
        try? modelContext.save()
    }

    // MARK: - Subviews
    var balanceCard: some View {
        let income = account.transactions.filter { $0.type == .deposit }.reduce(0) { $0 + $1.amount }
        let expense = account.transactions.filter { $0.type == .payment }.reduce(0) { $0 + $1.amount }

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(account.currency) \(account.balance, specifier: "%.2f")")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(account.balance >= 0 ? Color.green : Color.red)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Label("\(account.currency) \(income, specifier: "%.2f")", systemImage: "arrow.down")
                    .font(.caption)
                    .foregroundStyle(Color.green)
                Label("\(account.currency) \(expense, specifier: "%.2f")", systemImage: "arrow.up")
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var filterBadge: some View {
        HStack {
            Image(systemName: "calendar").font(.caption)
            Text("\(filterStart, format: .dateTime.day().month().year()) – \(filterEnd, format: .dateTime.day().month().year())")
                .font(.caption)
            Spacer()
            Button("Clear") { isFiltering = false }
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(Color.accentColor)
    }
}

// MARK: - Transaction Row View
struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Text(transaction.categoryEmoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(transaction.categoryName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(transaction.type == .payment ? "-" : "+")\(transaction.currency) \(transaction.amount, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(transaction.type == .payment ? Color.red : Color.green)
                Text(transaction.date, format: .dateTime.day().month())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
