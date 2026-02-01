import Testing
@testable import HealthQL
import Foundation

@Suite("Executor Tests")
struct ExecutorTests {

    @Test("Executor validates query has selections")
    func validatesSelections() async throws {
        let query = HealthQuery(
            source: .quantity(.steps),
            selections: []  // Empty selections - invalid
        )

        let executor = HealthQueryExecutor()

        await #expect(throws: QueryError.noSelections) {
            try await executor.execute(query)
        }
    }

    @Test("Executor validates groupBy requires aggregate")
    func validatesGroupByNeedsAggregate() async throws {
        let query = HealthQuery(
            source: .quantity(.steps),
            selections: [.field(.value)],  // Raw field, not aggregate
            grouping: .day  // But we have groupBy
        )

        let executor = HealthQueryExecutor()

        await #expect(throws: QueryError.groupByRequiresAggregate) {
            try await executor.execute(query)
        }
    }
}
