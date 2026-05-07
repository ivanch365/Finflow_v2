//
//  ReportView.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-05-02.
//
import SwiftUI

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    let accounts: [Account]
    let fixedAccount: Account?

    @State private var selectedMonth: Date = {
        Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        ) ?? Date()
    }()
    @State private var selectedAccountID: String = "all"
    @State private var showReport = false

    var accountsToReport: [Account] {
        if let fixed = fixedAccount { return [fixed] }
        if selectedAccountID == "all" { return accounts }
        return accounts.filter { $0.id.uuidString == selectedAccountID }
    }

    var reportTitle: String {
        if let fixed = fixedAccount { return fixed.name }
        if selectedAccountID == "all" { return "All Accounts" }
        return accounts.first { $0.id.uuidString == selectedAccountID }?.name ?? "Report"
    }

    var previewTransactions: [Transaction] {
        accountsToReport
            .flatMap { $0.transactions }
            .filter {
                Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
            }
    }

    var previewIncome: Double {
        previewTransactions.filter { $0.type == .deposit }.reduce(0.0) { $0 + $1.amount }
    }

    var previewExpenses: Double {
        previewTransactions.filter { $0.type == .payment }.reduce(0.0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Title bar
            Text("Monthly Report")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(spacing: 16) {

                    // Account picker
                    if fixedAccount == nil {
                        sectionCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Account")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)

                                Picker("", selection: $selectedAccountID) {
                                    Text("All Accounts").tag("all")
                                    ForEach(accounts) { account in
                                        Text(account.name).tag(account.id.uuidString)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                        }
                    }

                    // Month picker
                    sectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Month")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            DatePicker(
                                "",
                                selection: $selectedMonth,
                                in: ...Date(),
                                displayedComponents: [.date]
                            )
                            .labelsHidden()
#if os(macOS)
                            .datePickerStyle(.field)
#else
                            .datePickerStyle(.compact)
#endif
                        }
                    }

                    // Preview stats
                    sectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Preview")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Transactions")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(previewTransactions.count)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                Spacer()
                                VStack(alignment: .center, spacing: 2) {
                                    Text("Income")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(previewIncome,
                                         format: .number.precision(.fractionLength(2)))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.green)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Expenses")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(previewExpenses,
                                         format: .number.precision(.fractionLength(2)))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.red)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }

            Divider()

            // Bottom buttons
            HStack(spacing: 12) {
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    showReport = true
                } label: {
                    Label("View Report", systemImage: "chart.bar.doc.horizontal")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .keyboardShortcut(.defaultAction)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
#if os(macOS)
        .frame(minWidth: 420, minHeight: 360)
#endif
        .sheet(isPresented: $showReport) {
            ReportDetailView(
                accounts: accountsToReport,
                month: selectedMonth,
                title: reportTitle
            )
        }
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
}
