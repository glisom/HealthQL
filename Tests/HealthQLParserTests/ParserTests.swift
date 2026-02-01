import Testing
@testable import HealthQLParser

@Suite("Parser Tests")
struct ParserTests {

    @Test("Parser parses SELECT * FROM table")
    func selectStarFrom() throws {
        let parser = try Parser("SELECT * FROM steps")
        let stmt = try parser.parse()

        #expect(stmt.from == "steps")
        #expect(stmt.selections.count == 1)
        #expect(stmt.selections[0] == .star)
    }

    @Test("Parser parses SELECT column FROM table")
    func selectColumnFrom() throws {
        let parser = try Parser("SELECT value FROM heart_rate")
        let stmt = try parser.parse()

        #expect(stmt.from == "heart_rate")
        #expect(stmt.selections[0] == .identifier("value"))
    }

    @Test("Parser parses SELECT with aggregate")
    func selectAggregate() throws {
        let parser = try Parser("SELECT sum(count) FROM steps")
        let stmt = try parser.parse()

        #expect(stmt.selections[0] == .aggregate(.sum, .identifier("count")))
    }

    @Test("Parser parses multiple selections")
    func multipleSelections() throws {
        let parser = try Parser("SELECT avg(value), min(value), max(value) FROM heart_rate")
        let stmt = try parser.parse()

        #expect(stmt.selections.count == 3)
    }
}

@Suite("Parser Complex Query Tests")
struct ParserComplexTests {

    @Test("Parser handles WHERE with date arithmetic")
    func whereWithDateArithmetic() throws {
        let parser = try Parser("SELECT sum(count) FROM steps WHERE date > today() - 7d")
        let stmt = try parser.parse()

        #expect(stmt.whereClause != nil)
        guard case .binary(let left, let op, let right) = stmt.whereClause! else {
            Issue.record("Expected binary expression")
            return
        }
        #expect(op == .greaterThan)
        #expect(left == .identifier("date"))
        guard case .binary(_, .minus, .duration(7, .days)) = right else {
            Issue.record("Expected date arithmetic")
            return
        }
    }

    @Test("Parser handles GROUP BY day")
    func groupByDay() throws {
        let parser = try Parser("SELECT sum(count) FROM steps GROUP BY day")
        let stmt = try parser.parse()

        #expect(stmt.groupBy == .timePeriod(.day))
    }

    @Test("Parser handles ORDER BY with direction")
    func orderByWithDirection() throws {
        let parser = try Parser("SELECT value FROM heart_rate ORDER BY date DESC")
        let stmt = try parser.parse()

        #expect(stmt.orderBy?.count == 1)
        #expect(stmt.orderBy?[0].direction == .desc)
    }

    @Test("Parser handles LIMIT")
    func limitClause() throws {
        let parser = try Parser("SELECT * FROM steps LIMIT 10")
        let stmt = try parser.parse()

        #expect(stmt.limit == 10)
    }

    @Test("Parser handles full complex query")
    func fullComplexQuery() throws {
        let query = """
            SELECT avg(value), min(value), max(value)
            FROM heart_rate
            WHERE date > start_of_month()
            GROUP BY day
            ORDER BY date DESC
            LIMIT 30
            """
        let parser = try Parser(query)
        let stmt = try parser.parse()

        #expect(stmt.selections.count == 3)
        #expect(stmt.from == "heart_rate")
        #expect(stmt.whereClause != nil)
        #expect(stmt.groupBy == .timePeriod(.day))
        #expect(stmt.orderBy?.count == 1)
        #expect(stmt.limit == 30)
    }
}
