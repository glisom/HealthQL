import Testing
@testable import HealthQL
import Foundation

@Suite("Intermediate Representation Tests")
struct IRTests {

    @Test("HealthQuery can be constructed with source and selections")
    func basicQueryConstruction() {
        let query = HealthQuery(
            source: .quantity(.steps),
            selections: [.aggregate(.sum, .value)]
        )

        #expect(query.source == .quantity(.steps))
        #expect(query.selections.count == 1)
    }

    @Test("Predicate can express date comparisons")
    func datePredicates() {
        let predicate = Predicate(
            field: .date,
            op: .greaterThan,
            value: .date(Date.distantPast)
        )

        #expect(predicate.field == .date)
        #expect(predicate.op == .greaterThan)
    }

    @Test("GroupBy supports time periods")
    func groupByPeriods() {
        let groupBy = GroupBy.day
        #expect(groupBy == .day)

        let weekGroup = GroupBy.week
        #expect(weekGroup == .week)
    }
}
