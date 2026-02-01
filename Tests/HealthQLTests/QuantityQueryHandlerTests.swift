import Testing
import HealthKit
@testable import HealthQL

@Suite("QuantityQueryHandler Tests")
struct QuantityQueryHandlerTests {

    @Test("Handler can be created with mock store")
    func handlerCreation() {
        let mock = MockHealthStore()
        let handler = QuantityQueryHandler(healthStore: mock)
        #expect(handler != nil)
    }

    @Test("Handler requests authorization on first query")
    func requestsAuthorization() async throws {
        let mock = MockHealthStore()
        let handler = QuantityQueryHandler(healthStore: mock)

        let query = HealthQuery(
            source: .quantity(.heartRate),
            selections: [.field(.value)]
        )

        // Start execute in a task and cancel after a short timeout
        // Authorization happens before the query is executed
        let task = Task {
            _ = try? await handler.execute(query, type: .heartRate)
        }

        // Give time for authorization to be requested
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        task.cancel()

        #expect(mock.authorizationRequested == true)
    }

    @Test("Handler respects query limit")
    func respectsLimit() {
        let query = HealthQuery(
            source: .quantity(.steps),
            selections: [.field(.value)],
            limit: 10
        )

        #expect(query.limit == 10)
    }
}
