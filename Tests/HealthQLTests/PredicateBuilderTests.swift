import Testing
import HealthKit
@testable import HealthQL

@Suite("PredicateBuilder Tests")
struct PredicateBuilderTests {

    @Test("Builds date greater than predicate")
    func dateGreaterThan() {
        let date = Date()
        let predicate = Predicate(field: .date, op: .greaterThan, value: .date(date))

        let builder = PredicateBuilder()
        let hkPredicate = builder.build(from: [predicate])

        #expect(hkPredicate != nil)
    }

    @Test("Builds date range predicate")
    func dateRange() {
        let start = Date().addingTimeInterval(-86400)
        let end = Date()
        let predicate = Predicate(field: .date, op: .between, value: .dateRange(start: start, end: end))

        let builder = PredicateBuilder()
        let hkPredicate = builder.build(from: [predicate])

        #expect(hkPredicate != nil)
    }

    @Test("Combines multiple predicates with AND")
    func multiplePredicates() {
        let date = Date()
        let predicates = [
            Predicate(field: .date, op: .greaterThan, value: .date(date)),
            Predicate(field: .value, op: .greaterThan, value: .double(60.0))
        ]

        let builder = PredicateBuilder()
        let hkPredicate = builder.build(from: predicates)

        #expect(hkPredicate != nil)
    }

    @Test("Returns nil for empty predicates")
    func emptyPredicates() {
        let builder = PredicateBuilder()
        let hkPredicate = builder.build(from: [])

        #expect(hkPredicate == nil)
    }
}
