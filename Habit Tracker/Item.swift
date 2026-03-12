//
//  Item.swift
//  Habit Tracker
//
//  Created by Dmitry Tkachev on 12.03.2026.
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
