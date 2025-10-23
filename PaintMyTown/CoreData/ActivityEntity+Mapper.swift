//
//  ActivityEntity+Mapper.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreData

// MARK: - ActivityEntity ↔ Activity Mapper

extension ActivityEntity {
    /// Convert Core Data entity to domain model
    func toDomain() -> Activity? {
        guard let activityType = ActivityType(rawValue: type) else {
            return nil
        }

        // Convert locations
        let locationArray = (locations as? Set<LocationSampleEntity>)?
            .sorted { $0.timestamp < $1.timestamp }
            .compactMap { $0.toDomain() } ?? []

        // Convert splits
        let splitArray = (splits as? Set<SplitEntity>)?
            .compactMap { $0.toDomain() }
            .sorted { $0.distance < $1.distance } ?? []

        return Activity(
            id: id,
            type: activityType,
            startDate: startDate,
            endDate: endDate,
            distance: distance,
            duration: duration,
            elevationGain: elevationGain,
            elevationLoss: elevationLoss,
            averagePace: averagePace,
            notes: notes,
            locations: locationArray,
            splits: splitArray
        )
    }

    /// Update entity from domain model
    func update(from activity: Activity) {
        self.id = activity.id
        self.type = activity.type.rawValue
        self.startDate = activity.startDate
        self.endDate = activity.endDate
        self.distance = activity.distance
        self.duration = activity.duration
        self.elevationGain = activity.elevationGain
        self.elevationLoss = activity.elevationLoss
        self.averagePace = activity.averagePace
        self.notes = activity.notes
    }

    /// Create entity from domain model
    static func fromDomain(
        _ activity: Activity,
        context: NSManagedObjectContext
    ) -> ActivityEntity {
        let entity = ActivityEntity(context: context)
        entity.update(from: activity)

        // Create location entities
        for location in activity.locations {
            let locationEntity = LocationSampleEntity.fromDomain(location, context: context)
            entity.addToLocations(locationEntity)
        }

        // Create split entities
        for split in activity.splits {
            let splitEntity = SplitEntity.fromDomain(split, context: context)
            entity.addToSplits(splitEntity)
        }

        return entity
    }
}

// MARK: - LocationSampleEntity ↔ LocationSample Mapper

extension LocationSampleEntity {
    /// Convert Core Data entity to domain model
    func toDomain() -> LocationSample {
        LocationSample(
            id: id,
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            timestamp: timestamp,
            speed: speed
        )
    }

    /// Create entity from domain model
    static func fromDomain(
        _ location: LocationSample,
        context: NSManagedObjectContext
    ) -> LocationSampleEntity {
        let entity = LocationSampleEntity(context: context)
        entity.id = location.id
        entity.latitude = location.latitude
        entity.longitude = location.longitude
        entity.altitude = location.altitude
        entity.horizontalAccuracy = location.horizontalAccuracy
        entity.verticalAccuracy = location.verticalAccuracy
        entity.timestamp = location.timestamp
        entity.speed = location.speed
        return entity
    }
}

// MARK: - SplitEntity ↔ Split Mapper

extension SplitEntity {
    /// Convert Core Data entity to domain model
    func toDomain() -> Split {
        Split(
            id: id,
            distance: distance,
            duration: duration,
            pace: pace,
            elevationGain: elevationGain
        )
    }

    /// Create entity from domain model
    static func fromDomain(
        _ split: Split,
        context: NSManagedObjectContext
    ) -> SplitEntity {
        let entity = SplitEntity(context: context)
        entity.id = split.id
        entity.distance = split.distance
        entity.duration = split.duration
        entity.pace = split.pace
        entity.elevationGain = split.elevationGain
        return entity
    }
}

// MARK: - CoverageTileEntity ↔ CoverageTile Mapper

extension CoverageTileEntity {
    /// Convert Core Data entity to domain model
    func toDomain() -> CoverageTile {
        CoverageTile(
            geohash: geohash,
            latitude: latitude,
            longitude: longitude,
            visitCount: Int(visitCount),
            firstVisited: firstVisited,
            lastVisited: lastVisited
        )
    }

    /// Update entity from domain model
    func update(from tile: CoverageTile) {
        self.geohash = tile.geohash
        self.latitude = tile.latitude
        self.longitude = tile.longitude
        self.visitCount = Int32(tile.visitCount)
        self.firstVisited = tile.firstVisited
        self.lastVisited = tile.lastVisited
    }

    /// Create entity from domain model
    static func fromDomain(
        _ tile: CoverageTile,
        context: NSManagedObjectContext
    ) -> CoverageTileEntity {
        let entity = CoverageTileEntity(context: context)
        entity.update(from: tile)
        return entity
    }
}

// MARK: - UserSettingsEntity ↔ UserSettings Mapper

extension UserSettingsEntity {
    /// Convert Core Data entity to domain model
    func toDomain() -> UserSettings? {
        guard
            let distanceUnitEnum = DistanceUnit(rawValue: distanceUnit),
            let mapTypeEnum = MapType(rawValue: mapType),
            let coverageAlgorithmEnum = CoverageAlgorithmType(rawValue: coverageAlgorithm),
            let defaultActivityTypeEnum = ActivityType(rawValue: defaultActivityType)
        else {
            return nil
        }

        return UserSettings(
            id: id,
            distanceUnit: distanceUnitEnum,
            mapType: mapTypeEnum,
            coverageAlgorithm: coverageAlgorithmEnum,
            autoStartWorkout: autoStartWorkout,
            autoPauseEnabled: autoPauseEnabled,
            healthKitEnabled: healthKitEnabled,
            defaultActivityType: defaultActivityTypeEnum
        )
    }

    /// Update entity from domain model
    func update(from settings: UserSettings) {
        self.id = settings.id
        self.distanceUnit = settings.distanceUnit.rawValue
        self.mapType = settings.mapType.rawValue
        self.coverageAlgorithm = settings.coverageAlgorithm.rawValue
        self.autoStartWorkout = settings.autoStartWorkout
        self.autoPauseEnabled = settings.autoPauseEnabled
        self.healthKitEnabled = settings.healthKitEnabled
        self.defaultActivityType = settings.defaultActivityType.rawValue
    }

    /// Create entity from domain model
    static func fromDomain(
        _ settings: UserSettings,
        context: NSManagedObjectContext
    ) -> UserSettingsEntity {
        let entity = UserSettingsEntity(context: context)
        entity.update(from: settings)
        return entity
    }
}
