//
//  ReportDetailView.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-05-02.
//
import SwiftUI
import Charts

struct ReportDetailView: View {
    let accounts: [Account]
    let month: Date
    let title: String

    @Environment(\.dismiss) private var dismiss

    var monthString: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    var allTransactions: [Transaction] {
        accounts.flatMap { $0.transactions }
            .filter {
                Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month)
            }
            .sorted { $0.date < $1.date }
    }

    var payments: [Transaction] {
        allTransactions.filter { $0.type == .payment }
    }

    var deposits: [Transaction] {
        allTransactions.filter { $0.type == .deposit }
    }

    var totalIncome: Double {
        deposits.reduce(0) { $0 + $1.amount }
    }

    var totalExpenses: Double {
        payments.reduce(0) { $0 + $1.amount }
    }

    var netBalance: Double { totalIncome - totalExpenses }

    var categoryTotals: [(name: String, emoji: String, total: Double)] {
        var dict: [String: (emoji: String, total: Double)] = [:]
        for tx in payments {
            let existing = dict[tx.categoryName] ?? (emoji: tx.categoryEmoji, total: 0)
            dict[tx.categoryName] = (emoji: existing.emoji, total: existing.total + tx.amount)
        }
        return dict.map { (name: $0.key, emoji: $0.value.emoji, total: $0.value.total) }
            .sorted { $0.total > $1.total }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // ── Header ───────────────────────────────
                        VStack(spacing: 4) {
                            Text(title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            Text(monthString)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                        // ── Summary cards ─────────────────────────
                        HStack(spacing: 12) {
                            ReportSummaryCard(
                                title: "Income",
                                value: totalIncome,
                                color: .green,
                                icon: "arrow.down.circle.fill"
                            )
                            ReportSummaryCard(
                                title: "Expenses",
                                value: totalExpenses,
                                color: .red,
                                icon: "arrow.up.circle.fill"
                            )
                            ReportSummaryCard(
                                title: "Net",
                                value: netBalance,
                                color: netBalance >= 0 ? .green : .red,
                                icon: "equal.circle.fill"
                            )
                        }
                        .padding(.horizontal)

                        // ── Per-account breakdown ─────────────────
                        if accounts.count > 1 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Account Breakdown")
                                    .font(.headline)
                                    .padding(.horizontal)

                                VStack(spacing: 8) {
                                    ForEach(accounts) { account in
                                        let txs = account.transactions.filter {
                                            Calendar.current.isDate(
                                                $0.date, equalTo: month,
                                                toGranularity: .month
                                            )
                                        }
                                        let inc = txs.filter { $0.type == .deposit }
                                            .reduce(0.0) { $0 + $1.amount }
                                        let exp = txs.filter { $0.type == .payment }
                                            .reduce(0.0) { $0 + $1.amount }
                                        let net = inc - exp

                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(account.name)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                Text(account.currency)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("Net: \(account.currency) \(net, specifier: "%.2f")")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(net >= 0 ? Color.green : Color.red)
                                                HStack(spacing: 8) {
                                                    Text("+\(account.currency) \(inc, specifier: "%.2f")")
                                                        .font(.caption)
                                                        .foregroundStyle(Color.green)
                                                    Text("-\(account.currency) \(exp, specifier: "%.2f")")
                                                        .font(.caption)
                                                        .foregroundStyle(Color.red)
                                                }
                                            }
                                        }
                                        .padding(12)
                                        .background(.regularMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }

                        // ── Pie chart ─────────────────────────────
                        if !categoryTotals.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Spending by Category")
                                    .font(.headline)
                                    .padding(.horizontal)

                                // Donut chart
                                let totalSpend = categoryTotals.reduce(0) { $0 + $1.total }

                                Chart(categoryTotals, id: \.name) { item in
                                    SectorMark(
                                        angle: .value("Amount", item.total),
                                        innerRadius: .ratio(0.55),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(by: .value("Category", item.name))
                                    .cornerRadius(4)
                                }
                                .chartLegend(.hidden)
                                .frame(height: 240)
                                .padding(.horizontal)
                                .overlay {
                                    VStack(spacing: 2) {
                                        Text("Total")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(totalSpend, format: .number.precision(.fractionLength(2)))
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    }
                                }

                                // Category breakdown list
                                VStack(spacing: 8) {
                                    ForEach(categoryTotals, id: \.name) { item in
                                        HStack {
                                            Text(item.emoji)
                                            Text(item.name)
                                                .font(.subheadline)
                                            Spacer()
                                            Text(item.total, format: .number.precision(.fractionLength(2)))
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("(\(item.total / totalSpend * 100, specifier: "%.0f")%)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .frame(width: 40, alignment: .trailing)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(.regularMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }

                        // ── Transaction list ──────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Transactions")
                                .font(.headline)
                                .padding(.horizontal)

                            if allTransactions.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.tertiary)
                                    Text("No transactions this month")
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 20)
                            } else {
                                // Deposits
                                if !deposits.isEmpty {
                                    Text("Income")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.green)
                                        .padding(.horizontal)

                                    ForEach(deposits) { tx in
                                        ReportTransactionRow(
                                            transaction: tx,
                                            showAccount: accounts.count > 1
                                        )
                                        .padding(.horizontal)
                                    }
                                }

                                // Payments
                                if !payments.isEmpty {
                                    Text("Expenses")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.red)
                                        .padding(.horizontal)
                                        .padding(.top, 4)

                                    ForEach(payments) { tx in
                                        ReportTransactionRow(
                                            transaction: tx,
                                            showAccount: accounts.count > 1
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Report")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 600, minHeight: 700)
#endif
    }
}

// MARK: - Summary card
struct ReportSummaryCard: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value, format: .number.precision(.fractionLength(2)))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Transaction row for report
struct ReportTransactionRow: View {
    let transaction: Transaction
    let showAccount: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(transaction.categoryEmoji)
                .font(.title3)
                .frame(width: 38, height: 38)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(transaction.categoryName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if showAccount, let accountName = transaction.account?.name {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(accountName)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.type == .payment ? "-" : "+")\(transaction.currency) \(transaction.amount, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(transaction.type == .payment ? Color.red : Color.green)
                Text(transaction.date, format: .dateTime.day().month())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

