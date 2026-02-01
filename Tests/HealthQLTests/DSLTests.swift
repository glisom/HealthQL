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
