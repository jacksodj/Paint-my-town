//
//  ActivityEntity+CoreDataProperties.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreData

extension ActivityEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityEntity> {
        return NSFetchRequest<ActivityEntity>(entityName: "ActivityEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var type: String
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var distance: Double
    @NSManaged public var duration: Double
    @NSManaged public var elevationGain: Double
    @NSManaged public var elevationLoss: Double
    @NSManaged public var averagePace: Double
    @NSManaged public var notes: String?
    @NSManaged public var locations: NSSet?
    @NSManaged public var splits: NSSet?
}

// MARK: Generated accessors for locations
extension ActivityEntity {
    @objc(addLocationsObject:)
    @NSManaged public func addToLocations(_ value: LocationSampleEntity)

    @objc(removeLocationsObject:)
    @NSManaged public func removeFromLocations(_ value: LocationSampleEntity)

    @objc(addLocations:)
    @NSManaged public func addToLocations(_ values: NSSet)

    @objc(removeLocations:)
    @NSManaged public func removeFromLocations(_ values: NSSet)
}

// MARK: Generated accessors for splits
extension ActivityEntity {
    @objc(addSplitsObject:)
    @NSManaged public func addToSplits(_ value: SplitEntity)

    @objc(removeSplitsObject:)
    @NSManaged public func removeFromSplits(_ value: SplitEntity)

    @objc(addSplits:)
    @NSManaged public func addToSplits(_ values: NSSet)

    @objc(removeSplits:)
    @NSManaged public func removeFromSplits(_ values: NSSet)
}

extension ActivityEntity: Identifiable {
}
