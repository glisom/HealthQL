import Testing
@testable import HealthQLParser
@testable import HealthQL

@Suite("Compiler Tests")
struct CompilerTests {

    @Test("Compiler converts simple query to IR")
    func simpleQuery() throws {
        let stmt = SelectStatement(
            selections: [.aggregate(.sum, .identifier("count"))],
            from: "steps",
            whereClause: nil,
            groupBy: nil,
            having: nil,
            orderBy: nil,
            limit: nil
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.source == .quantity(.steps))
        #expect(query.selections.count == 1)
    }

    @Test("Compiler maps table name to QuantityType")
    func tableNameMapping() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "heart_rate",
            whereClause: nil,
            groupBy: nil,
            having: nil,
            orderBy: nil,
            limit: nil
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.source == .quantity(.heartRate))
    }

    @Test("Compiler converts WHERE to predicates")
    func whereToPredicates() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "steps",
            whereClause: .binary(
                .identifier("date"),
                .greaterThan,
                .function(.today, [])
            ),
            groupBy: nil,
            having: nil,
            orderBy: nil,
            limit: nil
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].field == .date)
        #expect(query.predicates[0].op == .greaterThan)
    }

    @Test("Compiler converts GROUP BY period")
    func groupByPeriod() throws {
        let stmt = SelectStatement(
            selections: [.aggregate(.sum, .identifier("count"))],
            from: "steps",
            whereClause: nil,
            groupBy: .timePeriod(.day),
            having: nil,
            orderBy: nil,
            limit: nil
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.grouping == .day)
    }
}

@Suite("Compiler Selection Tests")
struct CompilerSelectionTests {

    @Test("Compiler handles star selection")
    func starSelection() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "steps"
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.selections.count == 1)
        #expect(query.selections[0] == .field(.value))
    }

    @Test("Compiler handles field selection")
    func fieldSelection() throws {
        let stmt = SelectStatement(
            selections: [.identifier("date")],
            from: "steps"
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.selections[0] == .field(.date))
    }

    @Test("Compiler handles multiple aggregate selections")
    func multipleAggregates() throws {
        let stmt = SelectStatement(
            selections: [
                .aggregate(.avg, .identifier("value")),
                .aggregate(.min, .identifier("value")),
                .aggregate(.max, .identifier("value"))
            ],
            from: "heart_rate"
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.selections.count == 3)
        #expect(query.selections[0] == .aggregate(.avg, .value))
        #expect(query.selections[1] == .aggregate(.min, .value))
        #expect(query.selections[2] == .aggregate(.max, .value))
    }

    @Test("Compiler handles count aggregate")
    func countAggregate() throws {
        let stmt = SelectStatement(
            selections: [.aggregate(.count, .star)],
            from: "steps"
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.selections[0] == .aggregate(.count, .value))
    }
}

@Suite("Compiler WHERE Tests")
struct CompilerWhereTests {

    @Test("Compiler handles AND in WHERE clause")
    func whereWithAnd() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "steps",
            whereClause: .binary(
                .binary(.identifier("date"), .greaterThan, .function(.today, [])),
                .and,
                .binary(.identifier("value"), .greaterThan, .number(1000))
            )
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates.count == 2)
    }

    @Test("Compiler handles IS NULL")
    func isNull() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "steps",
            whereClause: .isNull(.identifier("source"), negated: false)
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].op == .isNull)
    }

    @Test("Compiler handles IS NOT NULL")
    func isNotNull() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "steps",
            whereClause: .isNull(.identifier("source"), negated: true)
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].op == .isNotNull)
    }

    @Test("Compiler handles date arithmetic in WHERE")
    func dateArithmetic() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "steps",
            whereClause: .binary(
                .identifier("date"),
                .greaterThan,
                .binary(.function(.today, []), .minus, .duration(7, .days))
            )
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].field == .date)
        #expect(query.predicates[0].op == .greaterThan)
        // Value should be a date
        if case .date = query.predicates[0].value {
            // Success
        } else {
            Issue.record("Expected date value")
        }
    }

    @Test("Compiler handles numeric comparison")
    func numericComparison() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "steps",
            whereClause: .binary(
                .identifier("value"),
                .greaterThanOrEqual,
                .number(10000)
            )
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates[0].op == .greaterThanOrEqual)
        #expect(query.predicates[0].value == .double(10000))
    }
}

@Suite("Compiler ORDER BY Tests")
struct CompilerOrderByTests {

    @Test("Compiler handles ORDER BY ascending")
    func orderByAsc() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "steps",
            orderBy: [OrderByItem(expression: .identifier("date"), direction: .asc)]
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.ordering?.count == 1)
        #expect(query.ordering?[0].field == .date)
        #expect(query.ordering?[0].direction == .ascending)
    }

    @Test("Compiler handles ORDER BY descending")
    func orderByDesc() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "steps",
            orderBy: [OrderByItem(expression: .identifier("date"), direction: .desc)]
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.ordering?[0].direction == .descending)
    }
}

@Suite("Compiler Error Tests")
struct CompilerErrorTests {

    @Test("Compiler throws on unknown table")
    func unknownTable() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "unknown_table"
        )

        let compiler = Compiler()

        #expect(throws: CompilerError.unknownTable("unknown_table")) {
            try compiler.compile(stmt)
        }
    }

    @Test("Compiler throws on unknown field")
    func unknownField() throws {
        let stmt = SelectStatement(
            selections: [.identifier("unknown_field")],
            from: "steps"
        )

        let compiler = Compiler()

        #expect(throws: CompilerError.unknownField("unknown_field")) {
            try compiler.compile(stmt)
        }
    }
}
