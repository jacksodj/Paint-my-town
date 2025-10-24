//
//  CoreDataModel.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//
//  This file programmatically describes the Core Data model.
//  The actual .xcdatamodeld file needs to be created in Xcode with the following structure:

/*
 CORE DATA MODEL STRUCTURE (to be created in Xcode):

 Entity: ActivityEntity
 - id: UUID (Attribute)
 - type: String (Attribute, Indexed)
 - startDate: Date (Attribute, Indexed)
 - endDate: Date (Attribute)
 - distance: Double (Attribute)
 - duration: Double (Attribute)
 - elevationGain: Double (Attribute)
 - elevationLoss: Double (Attribute)
 - averagePace: Double (Attribute)
 - notes: String? (Attribute, Optional)
 - locations: Relationship (To-Many, LocationSampleEntity, Delete Rule: Cascade)
 - splits: Relationship (To-Many, SplitEntity, Delete Rule: Cascade)

 Entity: LocationSampleEntity
 - id: UUID (Attribute)
 - latitude: Double (Attribute)
 - longitude: Double (Attribute)
 - altitude: Double (Attribute)
 - horizontalAccuracy: Double (Attribute)
 - verticalAccuracy: Double (Attribute)
 - timestamp: Date (Attribute)
 - speed: Double (Attribute)
 - activity: Relationship (To-One, ActivityEntity, Delete Rule: Nullify, Inverse: locations)

 Entity: SplitEntity
 - id: UUID (Attribute)
 - distance: Double (Attribute)
 - duration: Double (Attribute)
 - pace: Double (Attribute)
 - elevationGain: Double (Attribute)
 - activity: Relationship (To-One, ActivityEntity, Delete Rule: Nullify, Inverse: splits)

 Entity: CoverageTileEntity
 - geohash: String (Attribute, Indexed, Primary Key)
 - latitude: Double (Attribute)
 - longitude: Double (Attribute)
 - visitCount: Integer 32 (Attribute)
 - firstVisited: Date (Attribute)
 - lastVisited: Date (Attribute)

 Entity: UserSettingsEntity
 - id: UUID (Attribute)
 - distanceUnit: String (Attribute)
 - mapType: String (Attribute)
 - coverageAlgorithm: String (Attribute)
 - autoStartWorkout: Boolean (Attribute)
 - autoPauseEnabled: Boolean (Attribute)
 - healthKitEnabled: Boolean (Attribute)
 - defaultActivityType: String (Attribute)

 INDEXES:
 - ActivityEntity: Composite index on (startDate, type)
 - CoverageTileEntity: Index on geohash

 DELETE RULES:
 - ActivityEntity -> LocationSampleEntity: Cascade (delete locations when activity is deleted)
 - ActivityEntity -> SplitEntity: Cascade (delete splits when activity is deleted)
 */

import Foundation
import CoreData

/// Programmatic Core Data model builder
class CoreDataModel {
    static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Create entities
        let activityEntity = createActivityEntity()
        let locationSampleEntity = createLocationSampleEntity()
        let splitEntity = createSplitEntity()
        let coverageTileEntity = createCoverageTileEntity()
        let userSettingsEntity = createUserSettingsEntity()

        // Set up relationships after all entities are created
        setupRelationships(
            activity: activityEntity,
            locationSample: locationSampleEntity,
            split: splitEntity
        )

        model.entities = [
            activityEntity,
            locationSampleEntity,
            splitEntity,
            coverageTileEntity,
            userSettingsEntity
        ]

        return model
    }

    // MARK: - Entity Creation

    private static func createActivityEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ActivityEntity"
        entity.managedObjectClassName = "ActivityEntity"

        // Attributes
        entity.properties = [
            createAttribute(name: "id", type: .UUIDAttributeType, isOptional: false),
            createAttribute(name: "type", type: .stringAttributeType, isOptional: false, isIndexed: true),
            createAttribute(name: "startDate", type: .dateAttributeType, isOptional: false, isIndexed: true),
            createAttribute(name: "endDate", type: .dateAttributeType, isOptional: false),
            createAttribute(name: "distance", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "duration", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "elevationGain", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "elevationLoss", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "averagePace", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "notes", type: .stringAttributeType, isOptional: true)
        ]

        return entity
    }

    private static func createLocationSampleEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "LocationSampleEntity"
        entity.managedObjectClassName = "LocationSampleEntity"

        entity.properties = [
            createAttribute(name: "id", type: .UUIDAttributeType, isOptional: false),
            createAttribute(name: "latitude", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "longitude", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "altitude", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "horizontalAccuracy", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "verticalAccuracy", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "timestamp", type: .dateAttributeType, isOptional: false),
            createAttribute(name: "speed", type: .doubleAttributeType, isOptional: false)
        ]

        return entity
    }

    private static func createSplitEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SplitEntity"
        entity.managedObjectClassName = "SplitEntity"

        entity.properties = [
            createAttribute(name: "id", type: .UUIDAttributeType, isOptional: false),
            createAttribute(name: "distance", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "duration", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "pace", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "elevationGain", type: .doubleAttributeType, isOptional: false)
        ]

        return entity
    }

    private static func createCoverageTileEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CoverageTileEntity"
        entity.managedObjectClassName = "CoverageTileEntity"

        entity.properties = [
            createAttribute(name: "geohash", type: .stringAttributeType, isOptional: false, isIndexed: true),
            createAttribute(name: "latitude", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "longitude", type: .doubleAttributeType, isOptional: false),
            createAttribute(name: "visitCount", type: .integer32AttributeType, isOptional: false),
            createAttribute(name: "firstVisited", type: .dateAttributeType, isOptional: false),
            createAttribute(name: "lastVisited", type: .dateAttributeType, isOptional: false)
        ]

        return entity
    }

    private static func createUserSettingsEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "UserSettingsEntity"
        entity.managedObjectClassName = "UserSettingsEntity"

        entity.properties = [
            createAttribute(name: "id", type: .UUIDAttributeType, isOptional: false),
            createAttribute(name: "distanceUnit", type: .stringAttributeType, isOptional: false),
            createAttribute(name: "mapType", type: .stringAttributeType, isOptional: false),
            createAttribute(name: "coverageAlgorithm", type: .stringAttributeType, isOptional: false),
            createAttribute(name: "autoStartWorkout", type: .booleanAttributeType, isOptional: false),
            createAttribute(name: "autoPauseEnabled", type: .booleanAttributeType, isOptional: false),
            createAttribute(name: "healthKitEnabled", type: .booleanAttributeType, isOptional: false),
            createAttribute(name: "defaultActivityType", type: .stringAttributeType, isOptional: false)
        ]

        return entity
    }

    // MARK: - Helpers

    private static func createAttribute(
        name: String,
        type: NSAttributeType,
        isOptional: Bool,
        isIndexed: Bool = false
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = isOptional
        attribute.isIndexed = isIndexed
        return attribute
    }

    private static func setupRelationships(
        activity: NSEntityDescription,
        locationSample: NSEntityDescription,
        split: NSEntityDescription
    ) {
        // Activity -> Locations (one-to-many)
        let activityToLocations = NSRelationshipDescription()
        activityToLocations.name = "locations"
        activityToLocations.destinationEntity = locationSample
        activityToLocations.minCount = 0
        activityToLocations.maxCount = 0 // 0 means unbounded (to-many)
        activityToLocations.deleteRule = .cascadeDeleteRule

        // Location -> Activity (many-to-one)
        let locationToActivity = NSRelationshipDescription()
        locationToActivity.name = "activity"
        locationToActivity.destinationEntity = activity
        locationToActivity.minCount = 0
        locationToActivity.maxCount = 1
        locationToActivity.deleteRule = .nullifyDeleteRule

        activityToLocations.inverseRelationship = locationToActivity
        locationToActivity.inverseRelationship = activityToLocations

        // Activity -> Splits (one-to-many)
        let activityToSplits = NSRelationshipDescription()
        activityToSplits.name = "splits"
        activityToSplits.destinationEntity = split
        activityToSplits.minCount = 0
        activityToSplits.maxCount = 0
        activityToSplits.deleteRule = .cascadeDeleteRule

        // Split -> Activity (many-to-one)
        let splitToActivity = NSRelationshipDescription()
        splitToActivity.name = "activity"
        splitToActivity.destinationEntity = activity
        splitToActivity.minCount = 0
        splitToActivity.maxCount = 1
        splitToActivity.deleteRule = .nullifyDeleteRule

        activityToSplits.inverseRelationship = splitToActivity
        splitToActivity.inverseRelationship = activityToSplits

        // Add relationships to entities
        activity.properties.append(contentsOf: [activityToLocations, activityToSplits])
        locationSample.properties.append(locationToActivity)
        split.properties.append(splitToActivity)
    }
}
