# Paint the Town — iOS App Development & Project Specs

Below is a practical, developer-ready specification to build **Paint the Town**: an iOS fitness app that GPS-tracks walking/running/biking routes, overlays them on a public map, and cumulatively "paints" (shades) areas you've traversed across days/activities with rich filtering.

---

## 1. Product Overview

**Goal:** Track outdoor activities and visualize cumulative geographic coverage over time ("painting the town").
**Platforms:** iOS 16+ (iPhone). Optional iPad adaptive layout.
**Map Providers:** Apple MapKit (default). Optional Google Maps SDK (stretch goal).

### Core Concepts
- **Activities:** GPS recordings tagged with type (walk/run/bike), duration, distance, date/time.
- **Coverage:** A cumulative, filterable overlay (line/heat/area shading) showing where the user has traversed.
- **Filters:** Date range, activity type, distance/time thresholds, pace zones.
- **Gamification (Phase 2):** Tiles/regions completed, streaks, badges.

---

## 2. Key User Stories (MVP)

1. Record activity (walk/run/bike)
2. Continue tracking in background
3. View shaded map with cumulative coverage
4. Filter by date, type, distance, etc.
5. Inspect details of any prior activity
6. Optional HealthKit integration
7. Export or delete data securely

---

## 3. Architecture

**Pattern:** MVVM + Coordinators
**UI:** SwiftUI + MapKit
**Data:** Core Data + optional CloudKit sync
**Services:** Location, Workout, Coverage, HealthKit, GPX

---

## 4. Data Model

**Entities**
- `Activity`
- `LocationSample`
- `Split`
- `CoverageTile`
- `Settings`

**Indexes:** `Activity.startDate`, `Activity.type`, `CoverageTile.geohash`

---

## 5. GPS Recording & Processing

- `CLLocationManager` (`activityType = .fitness`)
- Smoothing & filtering of noisy GPS points
- Distance, elevation, splits per km/mi

---

## 6. Coverage Algorithm ("Paint")

Two methods:
- **Heatmap:** Line density visualization
- **Area Fill:** Tile-based visited-area map

Implementation uses **geohash** or **grid-based rasterization**.

---

## 7. Filtering Model

```swift
struct CoverageFilter: Hashable {
  var dateStart: Date?
  var dateEnd: Date?
  var activityTypes: Set<ActivityType>
  var minDistanceMeters: Double?
  var minDurationSec: Double?
  var paceRangeSecPerKm: ClosedRange<Double>?
}
```

---

## 8. UI/UX Flow

**Tabs:** Record | Map | History | Profile
**Map Tab:** Toggle between Heatmap / Area Fill / Route Lines
**Filters:** Quick chips for date & activity type

---

## 9. HealthKit (Phase 1.5)

- Read/write workout data and routes
- Secure user permission and explain privacy impact

---

## 10. Import/Export

- Export GPX for any activity
- Bulk ZIP export
- GPX import for 3rd-party integration

---

## 11. Permissions & Privacy

- Always-on location (with explanation)
- Motion & Fitness (for auto-pause)
- HealthKit (optional)
- No 3rd-party ad SDKs

---

## 12. Analytics

- Apple MetricKit + OSLog
- Optional Firebase in Phase 2

---

## 13. Edge Cases

- GPS drift & outlier rejection
- Activity spanning midnight
- Long activities streamed to disk
- Offline-safe recording

---

## 14. Testing

Unit, Integration, UI, and Performance benchmarks including 5k-activity coverage stress test.

---

## 15. Milestones

| Milestone | Focus | Duration |
|------------|--------|----------|
| M0 | Setup & permissions | 1–2 wks |
| M1 | Recording engine | 2–3 wks |
| M2 | Coverage & filters | 3–4 wks |
| M3 | History & UI polish | 2 wks |
| M4 | QA & launch prep | 2 wks |
| M5 | HealthKit & import | 2 wks |

---

## 16. Optional Enhancements

- City "completion" metrics
- Achievements/badges
- Social overlays and map shares
- Strava import
- Apple Watch companion
- Time-lapse replay

---

## 17. Branding

**App Name:** Paint the Town
**Tagline:** *Move more. See more. Paint your world.*
**Icon:** Pin + brush motif over a tile grid.

---

*End of document.*
