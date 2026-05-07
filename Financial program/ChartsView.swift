//
//  ChartsView.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-04-29.
//

import SwiftUI
import Charts

struct ChartsView: View {
    let account: Account
    @State private var period: ChartPeriod = .month

    enum ChartPeriod: String, CaseIterable {
        case month = "1 Month"
        case year  = "1 Year"
    }

    var startDate: Date {
        let cal = Calendar.current
        switch period {
        case .month: return cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .year:  return cal.date(byAdding: .year,  value: -1, to: Date()) ?? Date()
        }
    }

    var filteredPayments: [Transaction] {
        account.transactions.filter { $0.type == .payment && $0.date >= startDate }
    }

    var categoryTotals: [(name: String, emoji: String, total: Double)] {
        var dict: [String: (emoji: String, total: Double)] = [:]
        for tx in filteredPayments {
            let existing = dict[tx.categoryName] ?? (emoji: tx.categoryEmoji, total: 0)
            dict[tx.categoryName] = (emoji: existing.emoji, total: existing.total + tx.amount)
        }
        return dict.map { (name: $0.key, emoji: $0.value.emoji, total: $0.value.total) }
            .sorted { $0.total > $1.total }
    }

    var totalSpend: Double {
        filteredPayments.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Picker("Period", selection: $period) {
                            ForEach(ChartPeriod.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        if categoryTotals.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.pie")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.tertiary)
                                Text("No spending data")
                                    .foregroundStyle(.secondary)
                                Text("Add some payments to see your chart")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.top, 60)
                        } else {
                            Chart(categoryTotals, id: \.name) { item in
                                SectorMark(
                                    angle: .value("Amount", item.total),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 2
                                )
                                .foregroundStyle(by: .value("Category", item.name))
                                .cornerRadius(4)
                            }
                            .frame(height: 260)
                            .padding(.horizontal)
                            .chartLegend(.hidden)
                            .overlay {
                                VStack(spacing: 2) {
                                    Text("Total")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(account.currency) \(totalSpend, specifier: "%.0f")")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                            }

                            VStack(spacing: 10) {
                                ForEach(categoryTotals, id: \.name) { item in
                                    HStack {
                                        Text(item.emoji)
                                        Text(item.name)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(account.currency) \(item.total, specifier: "%.2f")")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("(\(item.total / totalSpend * 100, specifier: "%.0f")%)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 40, alignment: .trailing)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Spending Breakdown")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }
}
