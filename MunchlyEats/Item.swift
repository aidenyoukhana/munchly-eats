//
//  Item.swift
//  MunchlyEats
//
//  Created by Aiden Youkhana on 1/18/26.
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
