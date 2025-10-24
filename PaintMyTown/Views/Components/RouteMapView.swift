//
//  RouteMapView.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI
import MapKit

/// Map view displaying current location and workout route
struct RouteMapView: View {
    @Binding var route: [CLLocationCoordinate2D]
    @Binding var userLocation: CLLocation?

    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    @State private var mapType: MKMapType = .standard

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Map
            Map(coordinateRegion: $mapRegion,
                showsUserLocation: true,
                annotationItems: annotations) { point in
                MapAnnotation(coordinate: point.coordinate) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .edgesIgnoringSafeArea(.horizontal)
            .onAppear {
                updateMapRegion()
            }
            .onChange(of: route) { _ in
                updateMapRegion()
            }
            .onChange(of: userLocation) { _ in
                updateMapRegion()
            }

            // Map type selector
            VStack(spacing: 12) {
                Button {
                    mapType = mapType == .standard ? .satellite : .standard
                } label: {
                    Image(systemName: mapType == .standard ? "map" : "map.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
    }

    // MARK: - Private Methods

    private var annotations: [RoutePoint] {
        route.enumerated().map { index, coordinate in
            RoutePoint(id: index, coordinate: coordinate)
        }
    }

    private func updateMapRegion() {
        if let location = userLocation {
            mapRegion.center = location.coordinate
            mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        } else if !route.isEmpty {
            // Center on route
            let coordinates = route
            let latitudes = coordinates.map { $0.latitude }
            let longitudes = coordinates.map { $0.longitude }

            if let minLat = latitudes.min(), let maxLat = latitudes.max(),
               let minLon = longitudes.min(), let maxLon = longitudes.max() {

                let centerLat = (minLat + maxLat) / 2
                let centerLon = (minLon + maxLon) / 2
                let spanLat = (maxLat - minLat) * 1.2 // Add 20% padding
                let spanLon = (maxLon - minLon) * 1.2

                mapRegion.center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
                mapRegion.span = MKCoordinateSpan(
                    latitudeDelta: max(spanLat, 0.01),
                    longitudeDelta: max(spanLon, 0.01)
                )
            }
        }
    }
}

// MARK: - Supporting Types

struct RoutePoint: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D

    init(id: Int, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.coordinate = coordinate
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - Preview

#Preview {
    RouteMapView(
        route: .constant([
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.7759, longitude: -122.4184),
            CLLocationCoordinate2D(latitude: 37.7769, longitude: -122.4174)
        ]),
        userLocation: .constant(CLLocation(latitude: 37.7769, longitude: -122.4174))
    )
}
