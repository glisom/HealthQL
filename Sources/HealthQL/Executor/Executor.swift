import Foundation
import HealthKit

/// Errors that can occur during query execution
public enum QueryError: Error, Equatable {
    case noSelections
    case groupByRequiresAggregate
    case healthKitNotAvailable
    case authorizationDenied
    case invalidQuery(String)
    case healthKitError(String)
}

/// Executes HealthQL queries against HealthKit
public final class HealthQueryExecutor: Sendable {
    private let healthStore: HKHealthStore?
    private let quantityHandler: QuantityQueryHandler?
    private let categoryHandler: CategoryQueryHandler?
    private let workoutHandler: WorkoutQueryHandler?
    private let sleepSessionHandler: SleepSessionHandler?

    public init() {
        if HKHealthStore.isHealthDataAvailable() {
            let store = HKHealthStore()
            self.healthStore = store
            self.quantityHandler = QuantityQueryHandler(healthStore: store)
            self.categoryHandler = CategoryQueryHandler(healthStore: store)
            self.workoutHandler = WorkoutQueryHandler(healthStore: store)
            self.sleepSessionHandler = SleepSessionHandler(healthStore: store)
        } else {
            self.healthStore = nil
            self.quantityHandler = nil
            self.categoryHandler = nil
            self.workoutHandler = nil
            self.sleepSessionHandler = nil
        }
    }

    /// Execute a query and return results
    public func execute(_ query: HealthQuery) async throws -> QueryResult {
        // Validate query
        try validate(query)

        // Check HealthKit availability
        guard healthStore != nil else {
            throw QueryError.healthKitNotAvailable
        }

        let startTime = Date()

        // Dispatch to appropriate handler
        let rows: [ResultRow]

        do {
            switch query.source {
            case .quantity(let type):
                rows = try await quantityHandler!.execute(query, type: type)
            case .category(let type):
                rows = try await categoryHandler!.execute(query, type: type)
            case .workout:
                rows = try await workoutHandler!.execute(query)
            case .sleepSession:
                rows = try await sleepSessionHandler!.execute(query)
            }
        } catch {
            throw QueryError.healthKitError(error.localizedDescription)
        }

        let executionTime = Date().timeIntervalSince(startTime)
        return QueryResult(rows: rows, executionTime: executionTime)
    }

    /// Validate a query before execution
    private func validate(_ query: HealthQuery) throws {
        // Must have at least one selection
        if query.selections.isEmpty {
            throw QueryError.noSelections
        }

        // If grouping, must have aggregate selections
        if query.grouping != nil {
            let hasAggregate = query.selections.contains { selection in
                if case .aggregate = selection {
                    return true
                }
                return false
            }
            if !hasAggregate {
                throw QueryError.groupByRequiresAggregate
            }
        }
    }
}
