//
//  ActivityType.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Represents the type of physical activity
enum ActivityType: String, CaseIterable, Codable {
    case walk = "walk"
    case run = "run"
    case bike = "bike"

    var displayName: String {
        switch self {
        case .walk:
            return "Walk"
        case .run:
            return "Run"
        case .bike:
            return "Bike"
        }
    }
}
