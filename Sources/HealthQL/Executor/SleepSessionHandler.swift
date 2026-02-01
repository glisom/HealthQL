import Foundation
import HealthKit

/// Aggregates sleep analysis samples into nightly sessions
public actor SleepSessionHandler {
    private let healthStore: any HealthStoreProtocol
    private let predicateBuilder: PredicateBuilder
    private var authorized: Bool = false

    public init(healthStore: any HealthStoreProtocol) {
        self.healthStore = healthStore
        self.predicateBuilder = PredicateBuilder()
    }

    /// Execute a sleep session query
    public func execute(_ query: HealthQuery) async throws -> [ResultRow] {
        let hkType = HKCategoryType(.sleepAnalysis)

        // Request authorization if needed
        if !authorized {
            try await healthStore.requestAuthorization(toShare: nil, read: [hkType])
            authorized = true
        }

        // Fetch raw sleep samples
        let samples = try await fetchSleepSamples(query)

        // Group into sessions by night
        let sessions = groupIntoSessions(samples)

        // Transform to result rows
        return sessions.map { session in
            transformSession(session, selections: query.selections)
        }
    }

    private func fetchSleepSamples(_ query: HealthQuery) async throws -> [HKCategorySample] {
        let hkType = HKCategoryType(.sleepAnalysis)
        let predicate = predicateBuilder.build(from: query.predicates)

        return try await withCheckedThrowingContinuation { continuation in
            let sampleQuery = HKSampleQuery(
                sampleType: hkType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKCategorySample] ?? [])
            }

            self.healthStore.execute(sampleQuery)
        }
    }

    /// Groups samples into sleep sessions (one per night)
    /// Night boundary: 6pm to 12pm next day
    private nonisolated func groupIntoSessions(_ samples: [HKCategorySample]) -> [SleepSession] {
        guard !samples.isEmpty else { return [] }

        var sessions: [Date: SleepSession] = [:]
        let calendar = Calendar.current

        for sample in samples {
            let nightDate = nightDateFor(sample.startDate, calendar: calendar)

            if sessions[nightDate] == nil {
                sessions[nightDate] = SleepSession(nightDate: nightDate)
            }

            sessions[nightDate]?.addSample(sample)
        }

        return sessions.values.sorted { $0.nightDate < $1.nightDate }
    }

    /// Returns the "night date" for a given timestamp
    /// 6pm-midnight: same day, midnight-noon: previous day
    private nonisolated func nightDateFor(_ date: Date, calendar: Calendar) -> Date {
        let hour = calendar.component(.hour, from: date)

        if hour < 12 {
            // Before noon, belongs to previous night
            let previousDay = calendar.date(byAdding: .day, value: -1, to: date)!
            return calendar.startOfDay(for: previousDay)
        } else {
            // After noon, belongs to this night
            return calendar.startOfDay(for: date)
        }
    }

    private nonisolated func transformSession(_ session: SleepSession, selections: [Selection]) -> ResultRow {
        var values: [String: ResultValue] = [:]

        for selection in selections {
            if case .field(let field) = selection {
                switch field {
                case .date:
                    values["date"] = .date(session.nightDate)
                case .endDate:
                    if let end = session.endDate {
                        values["end_date"] = .date(end)
                    }
                case .duration:
                    values["duration"] = .double(session.totalSleepDuration)
                case .inBedDuration:
                    values["in_bed_duration"] = .double(session.inBedDuration)
                case .remDuration:
                    values["rem"] = .double(session.remDuration)
                case .coreDuration:
                    values["core"] = .double(session.coreDuration)
                case .deepDuration:
                    values["deep"] = .double(session.deepDuration)
                case .awakeDuration:
                    values["awake"] = .double(session.awakeDuration)
                default:
                    break
                }
            }
        }

        return ResultRow(values: values)
    }
}

/// Represents a single night's sleep session
private struct SleepSession {
    let nightDate: Date
    var samples: [HKCategorySample] = []

    var startDate: Date? { samples.first?.startDate }
    var endDate: Date? { samples.last?.endDate }

    var inBedDuration: TimeInterval {
        durationFor(stage: .inBed)
    }

    var remDuration: TimeInterval {
        durationFor(stage: .asleepREM)
    }

    var coreDuration: TimeInterval {
        durationFor(stage: .asleepCore)
    }

    var deepDuration: TimeInterval {
        durationFor(stage: .asleepDeep)
    }

    var awakeDuration: TimeInterval {
        durationFor(stage: .awake)
    }

    var totalSleepDuration: TimeInterval {
        // Total sleep = all asleep stages (not in_bed, not awake)
        remDuration + coreDuration + deepDuration + durationFor(stage: .asleepUnspecified)
    }

    mutating func addSample(_ sample: HKCategorySample) {
        samples.append(sample)
    }

    private func durationFor(stage: SleepStage) -> TimeInterval {
        samples
            .filter { $0.value == stage.rawValue }
            .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
    }
}
