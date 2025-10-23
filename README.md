# Paint My Town

An iOS app to track GPS locations where a user has exercised, displayed as an overlay on a map.

## Tech Stack

- **Swift** - Latest version with modern language features
- **SwiftUI** - Declarative UI framework for building native iOS interfaces
- **Swift Package Manager** - Dependency management
- **MapKit** - Native map display and GPS tracking
- **CoreLocation** - Location services and tracking
- **Combine** - Reactive programming framework

## Architecture

- **MVVM** pattern with SwiftUI
- Minimum iOS version: 16.0
- Supports iPhone and iPad

## Project Structure

```
PaintMyTown/
├── PaintMyTown.xcodeproj/       # Xcode project files
├── PaintMyTown/                 # Source code
│   ├── PaintMyTownApp.swift     # App entry point
│   ├── ContentView.swift        # Main view
│   ├── Assets.xcassets/         # App icons and assets
│   └── Preview Content/         # SwiftUI preview assets
└── README.md
```

## Getting Started

1. Open `PaintMyTown.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run on simulator or device

## Xcode Cloud & TestFlight

This project is configured for Xcode Cloud builds and TestFlight distribution. The shared scheme in `PaintMyTown.xcodeproj/xcshareddata/xcschemes/` is set up for CI/CD integration. 
