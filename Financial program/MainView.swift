//
//  MainView.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-04-29.
//

import SwiftUI

struct MainView: View {
    let account: Account
    let onSwitchAccount: () -> Void
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TransactionsView(account: account, onSwitchAccount: onSwitchAccount)
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }
                .tag(0)

            ChartsView(account: account)
                .tabItem {
                    Label("Charts", systemImage: "chart.pie.fill")
                }
                .tag(1)

            ManageCategoriesView()
                .tabItem {
                    Label("Categories", systemImage: "tag")
                }
                .tag(2)
        }
    }
}
