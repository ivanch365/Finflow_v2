//
//  RootView.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-04-29.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @StateObject private var fxService = ExchangeRateService.shared
    @State private var selectedAccount: Account?
    @State private var showNewAccount = false
    @State private var showExitConfirm = false
    @State private var showFilePicker = false
    @State private var showReport = false
    @State private var importErrorMessage: String? = nil
    @State private var showImportError = false
    @State private var importSuccessMessage: String? = nil
    @State private var showImportSuccess = false
    @State private var totalBalanceCurrency = "USD"

#if os(iOS)
    @State private var saveFile: FinacctFile? = nil
    @State private var showSaveExporter = false
    @State private var saveFileName = "account"
#endif

    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @AppStorage("preferredTotalCurrency") private var preferredTotalCurrency = "USD"

    var totalBalance: Double? {
        guard !fxService.rates.isEmpty else { return nil }
        return accounts.reduce(0.0) { sum, account in
            let converted = fxService.convert(
                account.balance,
                from: account.currency,
                to: preferredTotalCurrency
            ) ?? 0
            return sum + converted
        }
    }

    var body: some View {
        Group {
            if let account = selectedAccount {
                MainView(account: account, onSwitchAccount: {
                    selectedAccount = nil
                })
                .environmentObject(fxService)
            } else {
                accountPickerScreen
#if os(macOS)
                    .frame(minWidth: 720, minHeight: 600)
#endif
            }
        }
        .task {
            await fxService.fetchRates()
        }
        .sheet(isPresented: $showNewAccount) {
            NewAccountView { newAccount in
                modelContext.insert(newAccount)
                try? modelContext.save()
                selectedAccount = newAccount
            }
            
#if os(macOS)
            .frame(minWidth: 360, minHeight: 280)
#endif
        }
        .sheet(isPresented: $showReport) {
            ReportView(accounts: accounts, fixedAccount: nil)
        }
#if os(iOS)
        .fileExporter(
            isPresented: $showSaveExporter,
            document: saveFile ?? FinacctFile(data: Data()),
            contentType: .finacct,
            defaultFilename: saveFileName
        ) { result in
            saveFile = nil
            if case .failure(let error) = result {
                importErrorMessage = error.localizedDescription
                showImportError = true
            }
        }
#endif
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.finacct, .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileOpen(result)
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
        .alert("Error", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage ?? "Unknown error")
        }
        .alert("Account loaded!", isPresented: $showImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importSuccessMessage ?? "")
        }
    }

    var accountPickerScreen: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ── (more compact)
                VStack(spacing: 4) {
                    Text("💰")
                        .font(.system(size: 40))
                        .padding(.top, 28)

                    Text(hasLaunchedBefore ? "Welcome back!" : "Welcome to Finance")
                        .font(.system(size: 26, weight: .bold, design: .rounded))

                    if !hasLaunchedBefore {
                        VStack(spacing: 4) {
                            Text("Here's how to get started:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                            OnboardingTip(icon: "plus.circle",
                                          text: "Create an account using the button below")
                            OnboardingTip(icon: "arrow.up.arrow.down.circle",
                                          text: "Add payments and deposits to track your money")
                            OnboardingTip(icon: "chart.pie",
                                          text: "View spending breakdowns by category")
                            OnboardingTip(icon: "line.3.horizontal.decrease.circle",
                                          text: "Filter transactions by any date range")
                        }
                        .padding(.horizontal)
                        .padding(.top, 2)
                    } else {
                        Text("Select an account to continue")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 12)

                // ── Total balance card ──
                if !accounts.isEmpty {
                    totalBalanceCard
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }

                // ── Account list — fixed height, always shows 2-3 accounts ──
                if accounts.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 36))
                            .foregroundStyle(.tertiary)
                        Text("No accounts yet")
                            .foregroundStyle(.secondary)
                        Text("Create a new account or open a saved file")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Accounts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(accounts) { account in
                                    AccountCardRow(
                                        account: account,
                                        fxService: fxService,
                                        onSelect: {
                                            hasLaunchedBefore = true
                                            selectedAccount = account
                                        },
                                        onDelete: { deleteAccount(account) },
                                        onSave: { triggerSave(for: account) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        // Fixed height — shows ~3 accounts comfortably, scrolls if more
                        .frame(minHeight: 180, maxHeight: 320)
                        .background(Color.secondary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }
                }

                Spacer()

                // ── Bottom actions ──
                VStack(spacing: 10) {
                    Button {
                        hasLaunchedBefore = true
                        showNewAccount = true
                    } label: {
                        Label("New Account", systemImage: "plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Open Account File", systemImage: "folder")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.12))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        showReport = true
                    } label: {
                        Label("Monthly Report", systemImage: "chart.bar.doc.horizontal")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.12))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        showExitConfirm = true
                    } label: {
                        Label("Exit App", systemImage: "xmark.circle")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Total balance card
    var totalBalanceCard: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Balance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if fxService.isLoading {
                        HStack(spacing: 6) {
                            ProgressView().scaleEffect(0.7)
                            Text("Fetching rates...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if let total = totalBalance {
                        Text("\(preferredTotalCurrency) \(total, specifier: "%.2f")")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(total >= 0 ? Color.green : Color.red)
                    } else {
                        Text("Rates unavailable")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Picker("", selection: $preferredTotalCurrency) {
                        ForEach(fxService.supportedCurrencies, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 90)

                    Button {
                        Task { await fxService.fetchRates() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .font(.caption2)
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)

                    if let updated = fxService.lastUpdated {
                        Text("Updated \(updated, format: .relative(presentation: .named))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if accounts.count > 1, !fxService.rates.isEmpty {
                Divider()
                VStack(spacing: 4) {
                    ForEach(accounts) { account in
                        HStack {
                            Text(account.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let converted = fxService.convert(
                                account.balance,
                                from: account.currency,
                                to: preferredTotalCurrency
                            ) {
                                Text("\(preferredTotalCurrency) \(converted, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundStyle(converted >= 0 ? Color.green : Color.red)
                            }
                        }
                    }
                }
            }

            if let error = fxService.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(Color.red)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Save
    private func triggerSave(for account: Account) {
        do {
            let data = try AccountDocument.encode(account)
#if os(macOS)
            Task { @MainActor in
                let fileName = "\(account.name).finacct"
                let documentsURL = FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                ).first!

                var destinationURL = documentsURL.appendingPathComponent(fileName)
                var counter = 1
                while FileManager.default.fileExists(atPath: destinationURL.path) {
                    destinationURL = documentsURL.appendingPathComponent(
                        "\(account.name)_\(counter).finacct"
                    )
                    counter += 1
                }

                do {
                    try data.write(to: destinationURL)
                    NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
                    importSuccessMessage = "Saved as \"\(destinationURL.lastPathComponent)\" in Documents."
                    showImportSuccess = true
                } catch {
                    importErrorMessage = "Could not write file: \(error.localizedDescription)"
                    showImportError = true
                }
            }
#else
            saveFile = FinacctFile(data: data)
            saveFileName = account.name
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showSaveExporter = true
            }
#endif
        } catch {
            importErrorMessage = "Could not save: \(error.localizedDescription)"
            showImportError = true
        }
    }

    // MARK: - Open
    private func handleFileOpen(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showImportError = true
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                let snapshot = try AccountDocument.decode(data)
                restoreAccount(from: snapshot)
            } catch {
                importErrorMessage = "Could not read file: \(error.localizedDescription)"
                showImportError = true
            }
        }
    }

    private func restoreAccount(from snapshot: AccountSnapshot) {
        let existingNames = accounts.map { $0.name }
        let finalName = existingNames.contains(snapshot.name)
            ? "\(snapshot.name) (imported)" : snapshot.name

        let newAccount = Account(name: finalName, currency: snapshot.currency)
        newAccount.createdAt = snapshot.createdAt
        modelContext.insert(newAccount)

        for txSnap in snapshot.transactions {
            let type = TransactionType(rawValue: txSnap.type) ?? .payment
            let tx = Transaction(
                title: txSnap.title,
                amount: txSnap.amount,
                currency: txSnap.currency,
                categoryName: txSnap.categoryName,
                categoryEmoji: txSnap.categoryEmoji,
                type: type,
                date: txSnap.date
            )
            tx.account = newAccount
            newAccount.transactions.append(tx)
            modelContext.insert(tx)
        }

        try? modelContext.save()
        importSuccessMessage = "Account \"\(finalName)\" loaded with \(snapshot.transactions.count) transaction(s)."
        showImportSuccess = true
    }

    private func deleteAccount(_ account: Account) {
        modelContext.delete(account)
        try? modelContext.save()
    }
}

// MARK: - Account card row
struct AccountCardRow: View {
    let account: Account
    let fxService: ExchangeRateService
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onSave: () -> Void

    @State private var showDeleteConfirm = false
    @State private var viewCurrency: String = ""

    var displayBalance: (amount: Double, currency: String) {
        let target = viewCurrency.isEmpty ? account.currency : viewCurrency
        if target == account.currency {
            return (account.balance, account.currency)
        }
        if let converted = fxService.convert(
            account.balance,
            from: account.currency,
            to: target
        ) {
            return (converted, target)
        }
        return (account.balance, account.currency)
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(account.currency)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(displayBalance.currency) \(displayBalance.amount, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundStyle(displayBalance.amount >= 0 ? Color.green : Color.red)

                        if !fxService.rates.isEmpty {
                            Picker("", selection: $viewCurrency) {
                                Text(account.currency).tag("")
                                ForEach(
                                    fxService.supportedCurrencies.filter { $0 != account.currency },
                                    id: \.self
                                ) {
                                    Text($0).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.caption)
                            .frame(width: 80)
                            .onTapGesture { }
                        }
                    }

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 4)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button { onSave() } label: {
                Image(systemName: "square.and.arrow.down")
                    .foregroundStyle(Color.accentColor)
                    .padding(10)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .help("Save account to file")

            Button { showDeleteConfirm = true } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Color.red.opacity(0.8))
                    .padding(10)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .confirmationDialog(
                "Delete \"\(account.name)\"?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) { onDelete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All transactions will also be deleted. This cannot be undone.")
            }
        }
    }
}

// MARK: - Onboarding tip
struct OnboardingTip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}
