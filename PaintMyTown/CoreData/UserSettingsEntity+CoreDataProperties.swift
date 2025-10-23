//
//  UserSettingsEntity+CoreDataProperties.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreData

extension UserSettingsEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettingsEntity> {
        return NSFetchRequest<UserSettingsEntity>(entityName: "UserSettingsEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var distanceUnit: String
    @NSManaged public var mapType: String
    @NSManaged public var coverageAlgorithm: String
    @NSManaged public var autoStartWorkout: Bool
    @NSManaged public var autoPauseEnabled: Bool
    @NSManaged public var healthKitEnabled: Bool
    @NSManaged public var defaultActivityType: String
}

extension UserSettingsEntity: Identifiable {
}
