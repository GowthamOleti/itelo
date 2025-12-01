//
//  Item.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
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
