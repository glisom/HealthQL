import Foundation
import Testing
@testable import HealthQLPlayground
@testable import HealthQL

@Suite("Result Formatter Tests")
struct ResultFormatterTests {

    @Test("Formats empty result")
    func emptyResult() {
        let result = QueryResult(rows: [], executionTime: 0.023)
        let formatter = ResultFormatter()
        let output = formatter.format(result)

        #expect(output.contains("0 rows"))
    }

    @Test("Formats single row result")
    func singleRow() {
        let row = ResultRow(values: [
            "date": .date(Date(timeIntervalSince1970: 0)),
            "sum": .double(8432)
        ])
        let result = QueryResult(rows: [row], executionTime: 0.015)
        let formatter = ResultFormatter()
        let output = formatter.format(result)

        #expect(output.contains("date"))
        #expect(output.contains("sum"))
        #expect(output.contains("8432") || output.contains("8,432"))
        #expect(output.contains("1 row"))
    }

    @Test("Formats multiple rows as table")
    func multipleRows() {
        let rows = [
            ResultRow(values: ["name": .string("steps"), "count": .double(100)]),
            ResultRow(values: ["name": .string("heart_rate"), "count": .double(500)]),
        ]
        let result = QueryResult(rows: rows, executionTime: 0.005)
        let formatter = ResultFormatter()
        let output = formatter.format(result)

        #expect(output.contains("steps"))
        #expect(output.contains("heart_rate"))
        #expect(output.contains("2 rows"))
    }

    @Test("Includes execution time")
    func executionTime() {
        let result = QueryResult(rows: [], executionTime: 0.023)
        let formatter = ResultFormatter()
        let output = formatter.format(result)

        #expect(output.contains("23ms") || output.contains("0.023"))
    }
}
