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

    @Test("Parser handles BETWEEN with date strings")
    func betweenWithDateStrings() throws {
        let parser = try Parser("SELECT sum(value) FROM active_calories WHERE date BETWEEN '2026-02-05 16:00' AND '2026-02-05 17:00'")
        let stmt = try parser.parse()

        #expect(stmt.whereClause != nil)
        guard case .between(let field, let low, let high) = stmt.whereClause! else {
            Issue.record("Expected BETWEEN expression")
            return
        }
        #expect(field == .identifier("date"))
        #expect(low == .string("2026-02-05 16:00"))
        #expect(high == .string("2026-02-05 17:00"))
    }

    @Test("Parser handles BETWEEN with date-only strings")
    func betweenWithDateOnly() throws {
        let parser = try Parser("SELECT * FROM steps WHERE date BETWEEN '2026-02-01' AND '2026-02-07'")
        let stmt = try parser.parse()

        guard case .between(_, let low, let high) = stmt.whereClause! else {
            Issue.record("Expected BETWEEN expression")
            return
        }
        #expect(low == .string("2026-02-01"))
        #expect(high == .string("2026-02-07"))
    }

    @Test("Parser handles BETWEEN with date functions")
    func betweenWithDateFunctions() throws {
        let parser = try Parser("SELECT * FROM steps WHERE date BETWEEN today() - 7d AND today()")
        let stmt = try parser.parse()

        guard case .between(let field, _, _) = stmt.whereClause! else {
            Issue.record("Expected BETWEEN expression")
            return
        }
        #expect(field == .identifier("date"))
    }

    @Test("Parser handles hour duration")
    func hourDuration() throws {
        let parser = try Parser("SELECT * FROM heart_rate WHERE date > today() - 4h")
        let stmt = try parser.parse()

        guard case .binary(_, .greaterThan, let right) = stmt.whereClause! else {
            Issue.record("Expected binary expression")
            return
        }
        guard case .binary(_, .minus, .duration(4, .hours)) = right else {
            Issue.record("Expected hour duration arithmetic")
            return
        }
    }

    @Test("Parser handles date comparison with string literal")
    func dateComparisonWithStringLiteral() throws {
        let parser = try Parser("SELECT * FROM steps WHERE date > '2026-02-05'")
        let stmt = try parser.parse()

        guard case .binary(let left, .greaterThan, let right) = stmt.whereClause! else {
            Issue.record("Expected binary expression")
            return
        }
        #expect(left == .identifier("date"))
        #expect(right == .string("2026-02-05"))
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
