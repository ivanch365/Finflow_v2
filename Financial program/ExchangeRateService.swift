//
//  ExchangeRateService.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-05-01.
//
import Foundation
import Combine

@MainActor
class ExchangeRateService: ObservableObject {
    @Published var rates: [String: Double] = [:]
    @Published var isLoading = false
    @Published var lastUpdated: Date? = nil
    @Published var errorMessage: String? = nil

    static let shared = ExchangeRateService()
    private let baseURL = "https://api.exchangerate-api.com/v4/latest/"

    let supportedCurrencies = ["USD", "EUR", "GBP", "CAD", "AUD", "CHF", "JPY", "CNY"]

    // Fetch rates with USD as base, then we can convert between any pair
    func fetchRates() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let url = URL(string: "\(baseURL)USD") else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            rates = response.rates
            lastUpdated = Date()
        } catch {
            errorMessage = "Could not fetch rates: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // Convert amount from one currency to another
    func convert(_ amount: Double, from: String, to: String) -> Double? {
        guard !rates.isEmpty else { return nil }
        guard from != to else { return amount }

        // All rates are relative to USD base
        // Convert from -> USD -> to
        let fromRate = rates[from] ?? 1.0
        let toRate = rates[to] ?? 1.0
        let inUSD = amount / fromRate
        return inUSD * toRate
    }

    func formattedRate(from: String, to: String) -> String {
        guard let rate = convert(1.0, from: from, to: to) else { return "—" }
        return String(format: "%.4f", rate)
    }
}

struct ExchangeRateResponse: Codable {
    let base: String
    let rates: [String: Double]
}
