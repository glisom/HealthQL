import Testing
@testable import HealthQL
import Foundation

@Suite("Query Result Tests")
struct ResultTests {

    @Test("QueryResult holds rows with values")
    func basicResult() {
        let row = ResultRow(values: [
            "date": .date(Date()),
            "sum": .double(10000)
        ])

        let result = QueryResult(rows: [row], executionTime: 0.023)

        #expect(result.rows.count == 1)
        #expect(result.executionTime == 0.023)
    }

    @Test("ResultRow provides typed accessors")
    func typedAccessors() {
        let date = Date()
        let row = ResultRow(values: [
            "date": .date(date),
            "sum": .double(10000),
            "count": .int(7)
        ])

        #expect(row.date("date") == date)
        #expect(row.double("sum") == 10000)
        #expect(row.int("count") == 7)
    }

    @Test("ResultRow returns nil for missing keys")
    func missingKeys() {
        let row = ResultRow(values: [:])

        #expect(row.double("missing") == nil)
        #expect(row.date("missing") == nil)
    }
}
