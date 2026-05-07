//
//  AccountDocument.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-05-01.
//
import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let finacct = UTType(filenameExtension: "finacct") ?? .data
}

struct AccountSnapshot: Codable {
    var name: String
    var currency: String
    var createdAt: Date
    var transactions: [TransactionSnapshot]
}

struct TransactionSnapshot: Codable {
    var title: String
    var amount: Double
    var currency: String
    var categoryName: String
    var categoryEmoji: String
    var type: String
    var date: Date
}

struct AccountDocument {
    static func encode(_ account: Account) throws -> Data {
        let snapshot = AccountSnapshot(
            name: account.name,
            currency: account.currency,
            createdAt: account.createdAt,
            transactions: account.transactions.map {
                TransactionSnapshot(
                    title: $0.title,
                    amount: $0.amount,
                    currency: $0.currency,
                    categoryName: $0.categoryName,
                    categoryEmoji: $0.categoryEmoji,
                    type: $0.type.rawValue,
                    date: $0.date
                )
            }
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(snapshot)
    }

    static func decode(_ data: Data) throws -> AccountSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AccountSnapshot.self, from: data)
    }
}
