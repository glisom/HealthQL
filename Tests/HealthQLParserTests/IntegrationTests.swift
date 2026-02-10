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

    @Test("Custom date/time range query for active calories (issue #1)")
    func customDateTimeRange() throws {
        let query = try HQL.parse("""
            SELECT sum(value) FROM active_calories
            WHERE date BETWEEN '2026-02-05 16:00' AND '2026-02-05 17:00'
        """)

        #expect(query.source == .quantity(.activeCalories))
        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].field == .date)
        #expect(query.predicates[0].op == .between)
        if case .dateRange = query.predicates[0].value {
            // Success
        } else {
            Issue.record("Expected dateRange value")
        }
    }

    @Test("Date string literal comparison parses correctly")
    func dateStringComparison() throws {
        let query = try HQL.parse("""
            SELECT sum(value) FROM active_calories
            WHERE date > '2026-02-05' AND date < '2026-02-06'
        """)

        #expect(query.predicates.count == 2)
        #expect(query.predicates[0].op == .greaterThan)
        #expect(query.predicates[1].op == .lessThan)
    }

    @Test("Hour-based duration query parses correctly")
    func hourDurationQuery() throws {
        let query = try HQL.parse("""
            SELECT avg(value) FROM heart_rate
            WHERE date > today() - 4h
        """)

        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].field == .date)
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
