//
//  Item.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-04-29.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
