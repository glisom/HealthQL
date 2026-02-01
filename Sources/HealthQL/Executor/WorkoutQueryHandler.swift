import Foundation
import HealthKit

/// Executes workout queries against HealthKit
public actor WorkoutQueryHandler {
    private let healthStore: any HealthStoreProtocol
    private let predicateBuilder: PredicateBuilder
    private var authorized: Bool = false

    public init(healthStore: any HealthStoreProtocol) {
        self.healthStore = healthStore
        self.predicateBuilder = PredicateBuilder()
    }

    /// Execute a workout query
    public func execute(_ query: HealthQuery) async throws -> [ResultRow] {
        // Request authorization if needed
        if !authorized {
            try await healthStore.requestAuthorization(toShare: nil, read: [HKObjectType.workoutType()])
            authorized = true
        }

        return try await executeSampleQuery(query)
    }

    private func executeSampleQuery(_ query: HealthQuery) async throws -> [ResultRow] {
        let predicate = predicateBuilder.build(from: query.predicates)
        let limit = query.limit ?? HKObjectQueryNoLimit

        let sortDescriptors = buildSortDescriptors(from: query.ordering)

        return try await withCheckedThrowingContinuation { continuation in
            let sampleQuery = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let rows = self.transformWorkouts(samples as? [HKWorkout] ?? [], selections: query.selections)
                continuation.resume(returning: rows)
            }

            self.healthStore.execute(sampleQuery)
        }
    }

    private func buildSortDescriptors(from ordering: [OrderBy]?) -> [NSSortDescriptor] {
        guard let ordering = ordering else {
            return [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        }

        return ordering.map { order in
            let key: String
            switch order.field {
            case .date: key = HKSampleSortIdentifierStartDate
            case .endDate: key = HKSampleSortIdentifierEndDate
            case .duration: key = HKWorkoutSortIdentifierDuration
            case .totalCalories: key = HKWorkoutSortIdentifierTotalEnergyBurned
            default: key = HKSampleSortIdentifierStartDate
            }
            return NSSortDescriptor(key: key, ascending: order.direction == .ascending)
        }
    }

    private nonisolated func transformWorkouts(_ workouts: [HKWorkout], selections: [Selection]) -> [ResultRow] {
        workouts.map { workout in
            var values: [String: ResultValue] = [:]

            for selection in selections {
                if case .field(let field) = selection {
                    switch field {
                    case .activityType:
                        let typeName = WorkoutType.allCases.first { $0.activityType == workout.workoutActivityType }?.displayName ?? "unknown"
                        values["activity_type"] = .string(typeName)
                    case .duration:
                        values["duration"] = .double(workout.duration)
                    case .totalCalories:
                        if let energy = workout.totalEnergyBurned {
                            values["total_calories"] = .double(energy.doubleValue(for: .kilocalorie()))
                        } else {
                            values["total_calories"] = .null
                        }
                    case .distance:
                        if let distance = workout.totalDistance {
                            values["distance"] = .double(distance.doubleValue(for: .meter()))
                        } else {
                            values["distance"] = .null
                        }
                    case .date:
                        values["date"] = .date(workout.startDate)
                    case .endDate:
                        values["end_date"] = .date(workout.endDate)
                    case .source:
                        values["source"] = .string(workout.sourceRevision.source.name)
                    case .device:
                        if let device = workout.device {
                            values["device"] = .string(device.name ?? "Unknown")
                        } else {
                            values["device"] = .null
                        }
                    default:
                        break
                    }
                }
            }

            return ResultRow(values: values)
        }
    }
}
