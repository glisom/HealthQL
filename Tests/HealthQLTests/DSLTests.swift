import Testing
@testable import HealthQL
import Foundation

@Suite("DSL Tests")
struct DSLTests {

    @Test("Health.select creates a query builder")
    func selectCreatesBuilder() {
        let builder = Health.select(.steps)
        let query = builder.buildQuery()

        #expect(query.source == .quantity(.steps))
    }

    @Test("Aggregate selection is captured")
    func aggregateSelection() {
        let builder = Health.select(.steps, aggregate: .sum)
        let query = builder.buildQuery()

        #expect(query.selections.count == 1)
        #expect(query.selections[0] == .aggregate(.sum, .value))
    }

    @Test("Multiple aggregates can be selected")
    func multipleAggregates() {
        let builder = Health.select(.heartRate, aggregates: [.avg, .min, .max])
        let query = builder.buildQuery()

        #expect(query.selections.count == 3)
    }

    @Test("Where clause adds predicates")
    func whereClause() {
        let date = Date()
        let builder = Health.select(.steps)
            .where(.date, .greaterThan, .date(date))
        let query = builder.buildQuery()

        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].field == .date)
        #expect(query.predicates[0].op == .greaterThan)
    }

    @Test("GroupBy is captured")
    func groupBy() {
        let builder = Health.select(.steps, aggregate: .sum)
            .groupBy(.day)
        let query = builder.buildQuery()

        #expect(query.grouping == .day)
    }

    @Test("Limit is captured")
    func limit() {
        let builder = Health.select(.steps)
            .limit(10)
        let query = builder.buildQuery()

        #expect(query.limit == 10)
    }

    @Test("Full query chain works")
    func fullQueryChain() {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        let builder = Health.select(.steps, aggregate: .sum)
            .where(.date, .greaterThan, .date(sevenDaysAgo))
            .groupBy(.day)
            .orderBy(.date, .descending)
            .limit(7)

        let query = builder.buildQuery()

        #expect(query.source == .quantity(.steps))
        #expect(query.selections.count == 1)
        #expect(query.predicates.count == 1)
        #expect(query.grouping == .day)
        #expect(query.ordering?.count == 1)
        #expect(query.limit == 7)
    }
}

@Suite("Date Convenience Tests")
struct DateConvenienceTests {

    @Test("DateReference.daysAgo calculates correctly")
    func daysAgo() {
        let reference = DateReference.daysAgo(7)
        let expected = Calendar.current.date(byAdding: .day, value: -7, to: Calendar.current.startOfDay(for: Date()))!
        let referenceDate = reference.date

        // Compare to start of expected day
        let referenceDay = Calendar.current.startOfDay(for: referenceDate)
        #expect(referenceDay == expected)
    }

    @Test("DateReference.startOfMonth is first day of month")
    func startOfMonth() {
        let reference = DateReference.startOfMonth
        let date = reference.date

        let components = Calendar.current.dateComponents([.day], from: date)
        #expect(components.day == 1)
    }

    @Test("DateReference.today is start of today")
    func today() {
        let reference = DateReference.today
        let expected = Calendar.current.startOfDay(for: Date())

        #expect(reference.date == expected)
    }
}

@Suite("DSL Execute Tests")
struct DSLExecuteTests {

    @Test("QueryBuilder.execute returns QueryResult")
    func executeReturnsResult() async throws {
        do {
            let result = try await Health.select(.steps, aggregate: .sum)
                .where(.date, .greaterThan, .date(.daysAgo(7)))
                .groupBy(.day)
                .execute()

            // Result may be empty (no HealthKit data in test), but should not throw
            #expect(result.executionTime >= 0)
        } catch QueryError.healthKitNotAvailable {
            // Expected in test environment without HealthKit
            #expect(true)
        }
    }
}
