import Testing
import HealthKit
@testable import HealthQL

@Suite("WorkoutQueryHandler Tests")
struct WorkoutQueryHandlerTests {

    @Test("Handler can be created with mock store")
    func handlerCreation() {
        let mock = MockHealthStore()
        let handler = WorkoutQueryHandler(healthStore: mock)
        #expect(handler != nil)
    }

    @Test("Handler requests authorization on first query")
    func requestsAuthorization() async throws {
        let mock = MockHealthStore()
        let handler = WorkoutQueryHandler(healthStore: mock)

        let query = HealthQuery(
            source: .workout,
            selections: [.field(.duration)]
        )

        // Start execute in a task and cancel after a short timeout
        // Authorization happens before the query is executed
        let task = Task {
            _ = try? await handler.execute(query)
        }

        // Give time for authorization to be requested
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        task.cancel()

        #expect(mock.authorizationRequested == true)
    }
}
