//
//  FilterSheetView.swift
//  PaintMyTown
//
//  Filter sheet for coverage visualization filtering
//

import SwiftUI

/// Sheet view for filtering coverage data
struct FilterSheetView: View {
    @Binding var filter: CoverageFilter
    let onApply: (CoverageFilter) -> Void
    let onClear: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var workingFilter: CoverageFilter

    init(
        filter: Binding<CoverageFilter>,
        onApply: @escaping (CoverageFilter) -> Void,
        onClear: @escaping () -> Void
    ) {
        self._filter = filter
        self.onApply = onApply
        self.onClear = onClear
        self._workingFilter = State(initialValue: filter.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Date Range Section
                Section {
                    Toggle("Filter by date", isOn: Binding(
                        get: { workingFilter.dateRange != nil },
                        set: { enabled in
                            if enabled {
                                workingFilter.dateRange = .lastWeek
                            } else {
                                workingFilter.dateRange = nil
                            }
                        }
                    ))

                    if workingFilter.dateRange != nil {
                        Picker("Date Range", selection: Binding(
                            get: { workingFilter.dateRange ?? .lastWeek },
                            set: { workingFilter.dateRange = $0 }
                        )) {
                            Text("Last Week").tag(DateRange.lastWeek)
                            Text("Last Month").tag(DateRange.lastMonth)
                            Text("This Year").tag(DateRange.thisYear)
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Date Range")
                } footer: {
                    if let range = workingFilter.dateRange {
                        Text("From \(range.start.formatted(date: .abbreviated, time: .omitted)) to \(range.end.formatted(date: .abbreviated, time: .omitted))")
                    }
                }

                // Activity Types Section
                Section {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Toggle(type.displayName, isOn: Binding(
                            get: { workingFilter.activityTypes.contains(type) },
                            set: { enabled in
                                if enabled {
                                    workingFilter.activityTypes.insert(type)
                                } else {
                                    workingFilter.activityTypes.remove(type)
                                }
                            }
                        ))
                    }
                } header: {
                    Text("Activity Types")
                } footer: {
                    Text("\(workingFilter.activityTypes.count) of \(ActivityType.allCases.count) types selected")
                }

                // Distance Filter Section
                Section {
                    Toggle("Filter by distance", isOn: Binding(
                        get: { workingFilter.minDistance != nil },
                        set: { enabled in
                            if enabled {
                                workingFilter.minDistance = 1000 // 1 km
                            } else {
                                workingFilter.minDistance = nil
                            }
                        }
                    ))

                    if workingFilter.minDistance != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Minimum Distance: \(formatDistance(workingFilter.minDistance ?? 0))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Slider(
                                value: Binding(
                                    get: { workingFilter.minDistance ?? 0 },
                                    set: { workingFilter.minDistance = $0 }
                                ),
                                in: 0...50000,
                                step: 100
                            )
                        }
                    }
                } header: {
                    Text("Distance")
                }

                // Duration Filter Section
                Section {
                    Toggle("Filter by duration", isOn: Binding(
                        get: { workingFilter.minDuration != nil },
                        set: { enabled in
                            if enabled {
                                workingFilter.minDuration = 300 // 5 minutes
                            } else {
                                workingFilter.minDuration = nil
                            }
                        }
                    ))

                    if workingFilter.minDuration != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Minimum Duration: \(formatDuration(workingFilter.minDuration ?? 0))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Slider(
                                value: Binding(
                                    get: { workingFilter.minDuration ?? 0 },
                                    set: { workingFilter.minDuration = $0 }
                                ),
                                in: 0...7200,
                                step: 60
                            )
                        }
                    }
                } header: {
                    Text("Duration")
                }

                // Quick Filters Section
                Section {
                    Button(action: {
                        // Last week filter
                        workingFilter = CoverageFilter(
                            dateRange: .lastWeek,
                            activityTypes: Set(ActivityType.allCases),
                            minDistance: nil,
                            minDuration: nil
                        )
                    }) {
                        Label("Last Week", systemImage: "calendar.badge.clock")
                    }

                    Button(action: {
                        // Runs only filter
                        workingFilter = CoverageFilter(
                            dateRange: nil,
                            activityTypes: [.run],
                            minDistance: nil,
                            minDuration: nil
                        )
                    }) {
                        Label("Runs Only", systemImage: "figure.run")
                    }

                    Button(action: {
                        // Long activities filter
                        workingFilter = CoverageFilter(
                            dateRange: nil,
                            activityTypes: Set(ActivityType.allCases),
                            minDistance: 5000, // 5 km
                            minDuration: nil
                        )
                    }) {
                        Label("Long Activities (5+ km)", systemImage: "ruler")
                    }
                } header: {
                    Text("Quick Filters")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Clear") {
                            workingFilter = .default
                            onClear()
                            dismiss()
                        }
                        .foregroundColor(.red)

                        Button("Apply") {
                            filter = workingFilter
                            onApply(workingFilter)
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helper Methods

    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000
        if km >= 1 {
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.0f m", meters)
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview

#Preview {
    FilterSheetView(
        filter: .constant(.default),
        onApply: { _ in },
        onClear: { }
    )
}
