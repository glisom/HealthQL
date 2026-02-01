import Foundation
import HealthKit

/// Protocol abstracting HKHealthStore for testability
public protocol HealthStoreProtocol: Sendable {
    func execute(_ query: HKQuery)
    func stop(_ query: HKQuery)
    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?
    ) async throws
}

/// Extension to make HKHealthStore conform
extension HKHealthStore: HealthStoreProtocol {
    public func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.requestAuthorization(toShare: typesToShare, read: typesToRead) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

/// Mock implementation for testing
public final class MockHealthStore: HealthStoreProtocol, @unchecked Sendable {
    public var samples: [HKSample]
    public var error: Error?
    public var queryError: Error?
    public var executedQueries: [HKQuery] = []
    public var authorizationRequested: Bool = false

    public init(samples: [HKSample] = [], error: Error? = nil) {
        self.samples = samples
        self.error = error
    }

    public func execute(_ query: HKQuery) {
        executedQueries.append(query)

        // Invoke completion handlers for statistics collection queries
        if let statsQuery = query as? HKStatisticsCollectionQuery {
            DispatchQueue.main.async { [weak self] in
                statsQuery.initialResultsHandler?(statsQuery, nil, self?.queryError)
            }
        }
    }

    public func stop(_ query: HKQuery) {
        // No-op for mock
    }

    public func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?
    ) async throws {
        authorizationRequested = true
        if let error = error {
            throw error
        }
    }
}
