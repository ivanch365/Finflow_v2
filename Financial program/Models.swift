//
//  Item.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-04-29.
//

import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case payment = "Payment"
    case deposit = "Deposit"

    var id: String { self.rawValue }
}

@Model
final class Category {
    var name: String
    var emoji: String
    var isIncome: Bool

    init(name: String, emoji: String, isIncome: Bool) {
        self.name = name
        self.emoji = emoji
        self.isIncome = isIncome
    }

    static func defaultCategories() -> [Category] {
        [
            // Expense
            Category(name: "Gas",           emoji: "⛽", isIncome: false),
            Category(name: "Groceries",     emoji: "🛒", isIncome: false),
            Category(name: "Dining",        emoji: "🍽️", isIncome: false),
            Category(name: "Shopping",      emoji: "🛍️", isIncome: false),
            Category(name: "Utilities",     emoji: "💡", isIncome: false),
            Category(name: "Rent",          emoji: "🏠", isIncome: false),
            Category(name: "Transport",     emoji: "🚌", isIncome: false),
            Category(name: "Health",        emoji: "❤️", isIncome: false),
            Category(name: "Entertainment", emoji: "🎬", isIncome: false),
            Category(name: "Other",         emoji: "📦", isIncome: false),
            // Income
            Category(name: "Salary",        emoji: "💼", isIncome: true),
            Category(name: "Investment",    emoji: "📈", isIncome: true),
            Category(name: "Other Income",  emoji: "💰", isIncome: true),
        ]
    }
}

@Model
final class Account {
    var id: UUID = UUID()
    var name: String
    var currency: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var transactions: [Transaction] = []

    init(name: String, currency: String) {
        self.name = name
        self.currency = currency
        self.createdAt = Date()
    }

    var balance: Double {
        transactions.reduce(0) { total, tx in
            tx.type == .deposit ? total + tx.amount : total - tx.amount
        }
    }
}

@Model
final class Transaction {
    var title: String
    var amount: Double
    var currency: String
    var categoryName: String
    var categoryEmoji: String
    var type: TransactionType
    var date: Date
    var account: Account?

    // Existing init — used when adding from UI
    init(title: String, amount: Double, currency: String,
         category: Category, type: TransactionType, date: Date) {
        self.title = title
        self.amount = amount
        self.currency = currency
        self.categoryName = category.name
        self.categoryEmoji = category.emoji
        self.type = type
        self.date = date
    }

    // New init — used when loading from a .finacct file
    init(title: String, amount: Double, currency: String,
         categoryName: String, categoryEmoji: String,
         type: TransactionType, date: Date) {
        self.title = title
        self.amount = amount
        self.currency = currency
        self.categoryName = categoryName
        self.categoryEmoji = categoryEmoji
        self.type = type
        self.date = date
    }
}
