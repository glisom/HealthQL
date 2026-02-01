import Testing
@testable import HealthQLParser
@testable import HealthQL

@Suite("Integration Tests")
struct IntegrationTests {

    @Test("HQL.parse returns HealthQuery IR")
    func parseOnly() throws {
        let query = try HQL.parse("SELECT avg(value) FROM heart_rate")

        #expect(query.source == .quantity(.heartRate))
    }

    @Test("Complex query parses correctly")
    func complexQuery() throws {
        let query = try HQL.parse("""
            SELECT avg(value), min(value), max(value)
            FROM heart_rate
            WHERE date > start_of_month()
            GROUP BY day
            ORDER BY date DESC
            LIMIT 30
        """)

        #expect(query.selections.count == 3)
        #expect(query.grouping == .day)
        #expect(query.limit == 30)
    }

    @Test("HQL.query parses and executes")
    func queryEndToEnd() async throws {
        do {
            let result = try await HQL.query("SELECT sum(count) FROM steps WHERE date > today() - 7d GROUP BY day")

            // Result may be empty but should not throw
            #expect(result.executionTime >= 0)
        } catch QueryError.healthKitNotAvailable {
            // Expected in test environment without HealthKit
            #expect(true)
        }
    }
}
