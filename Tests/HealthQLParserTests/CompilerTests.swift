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

@Suite("Compiler Source Resolution Tests")
struct CompilerSourceResolutionTests {

    @Test("Compiler resolves sleep_analysis to category source")
    func compileSleepAnalysis() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "sleep_analysis",
            whereClause: nil,
            groupBy: nil,
            orderBy: nil,
            limit: nil
        )
        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        if case .category(let type) = query.source {
            #expect(type == .sleepAnalysis)
        } else {
            Issue.record("Expected category source")
        }
    }

    @Test("Compiler resolves workouts to workout source")
    func compileWorkouts() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "workouts",
            whereClause: nil,
            groupBy: nil,
            orderBy: nil,
            limit: nil
        )
        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        if case .workout = query.source {
            // Pass
        } else {
            Issue.record("Expected workout source")
        }
    }

    @Test("Compiler resolves sleep to sleepSession source")
    func compileSleepSession() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "sleep",
            whereClause: nil,
            groupBy: nil,
            orderBy: nil,
            limit: nil
        )
        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        if case .sleepSession = query.source {
            // Pass
        } else {
            Issue.record("Expected sleepSession source")
        }
    }

    @Test("Compiler resolves headache to category source")
    func compileHeadache() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "headache",
            whereClause: nil,
            groupBy: nil,
            orderBy: nil,
            limit: nil
        )
        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        if case .category(let type) = query.source {
            #expect(type == .headache)
        } else {
            Issue.record("Expected category source")
        }
    }
}

@Suite("Compiler Field Resolution Tests")
struct CompilerFieldResolutionTests {

    @Test("Compiler resolves duration field")
    func compileDurationField() throws {
        let stmt = SelectStatement(
            selections: [.identifier("duration")],
            from: "workouts",
            whereClause: nil,
            groupBy: nil,
            orderBy: nil,
            limit: nil
        )
        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        if case .field(let field) = query.selections[0] {
            #expect(field == .duration)
        } else {
            Issue.record("Expected field selection")
        }
    }

    @Test("Compiler resolves activity_type field")
    func compileActivityTypeField() throws {
        let stmt = SelectStatement(
            selections: [.identifier("activity_type")],
            from: "workouts",
            whereClause: nil,
            groupBy: nil,
            orderBy: nil,
            limit: nil
        )
        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        if case .field(let field) = query.selections[0] {
            #expect(field == .activityType)
        } else {
            Issue.record("Expected field selection")
        }
    }

    @Test("Compiler resolves total_calories field")
    func compileTotalCaloriesField() throws {
        let stmt = SelectStatement(
            selections: [.identifier("total_calories")],
            from: "workouts",
            whereClause: nil,
            groupBy: nil,
            orderBy: nil,
            limit: nil
        )
        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        if case .field(let field) = query.selections[0] {
            #expect(field == .totalCalories)
        } else {
            Issue.record("Expected field selection")
        }
    }
}

@Suite("Compiler Date/Time Literal Tests")
struct CompilerDateTimeLiteralTests {

    @Test("Compiler parses date string literal as date value")
    func dateStringLiteral() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "steps",
            whereClause: .binary(
                .identifier("date"),
                .greaterThan,
                .string("2026-02-05")
            )
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].field == .date)
        #expect(query.predicates[0].op == .greaterThan)
        if case .date = query.predicates[0].value {
            // Success - string was parsed as a date
        } else {
            Issue.record("Expected date value from date string literal")
        }
    }

    @Test("Compiler parses datetime string literal with time")
    func datetimeStringLiteral() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "active_calories",
            whereClause: .binary(
                .identifier("date"),
                .greaterThan,
                .string("2026-02-05 16:00")
            )
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates.count == 1)
        if case .date = query.predicates[0].value {
            // Success
        } else {
            Issue.record("Expected date value from datetime string literal")
        }
    }

    @Test("Compiler parses datetime string literal with seconds")
    func datetimeWithSeconds() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "heart_rate",
            whereClause: .binary(
                .identifier("date"),
                .greaterThan,
                .string("2026-02-05 16:30:45")
            )
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        if case .date = query.predicates[0].value {
            // Success
        } else {
            Issue.record("Expected date value from datetime with seconds")
        }
    }

    @Test("Compiler keeps non-date string as string value")
    func nonDateString() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "heart_rate",
            whereClause: .binary(
                .identifier("source"),
                .equal,
                .string("Apple Watch")
            )
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates[0].value == .string("Apple Watch"))
    }

    @Test("Compiler handles BETWEEN with date strings")
    func betweenDateStrings() throws {
        let stmt = SelectStatement(
            selections: [.aggregate(.sum, .identifier("value"))],
            from: "active_calories",
            whereClause: .between(
                .identifier("date"),
                .string("2026-02-05 16:00"),
                .string("2026-02-05 17:00")
            )
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].op == .between)
        if case .dateRange = query.predicates[0].value {
            // Success
        } else {
            Issue.record("Expected dateRange value for BETWEEN")
        }
    }

    @Test("Compiler handles BETWEEN with date functions")
    func betweenDateFunctions() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "steps",
            whereClause: .between(
                .identifier("date"),
                .binary(.function(.today, []), .minus, .duration(7, .days)),
                .function(.today, [])
            )
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].op == .between)
        if case .dateRange = query.predicates[0].value {
            // Success
        } else {
            Issue.record("Expected dateRange value for BETWEEN with functions")
        }
    }

    @Test("Compiler handles hour duration")
    func hourDuration() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "heart_rate",
            whereClause: .binary(
                .identifier("date"),
                .greaterThan,
                .binary(.function(.today, []), .minus, .duration(4, .hours))
            )
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.predicates.count == 1)
        if case .date = query.predicates[0].value {
            // Success
        } else {
            Issue.record("Expected date value from hour duration")
        }
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

// MARK: - Phase 4 Quantity Types Compiler Tests

@Suite("Phase 4 Quantity Types Compiler Tests")
struct Phase4CompilerTests {

    @Test("Compiler resolves vo2_max to quantity source")
    func vo2Max() throws {
        let stmt = SelectStatement(
            selections: [.star],
            from: "vo2_max"
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.source == .quantity(.vo2Max))
    }

    @Test("Compiler resolves resting_heart_rate to quantity source")
    func restingHeartRate() throws {
        let stmt = SelectStatement(
            selections: [.identifier("value")],
            from: "resting_heart_rate"
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.source == .quantity(.restingHeartRate))
    }

    @Test("Compiler resolves body_mass_index to quantity source")
    func bodyMassIndex() throws {
        let stmt = SelectStatement(
            selections: [.aggregate(.avg, .identifier("value"))],
            from: "body_mass_index"
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.source == .quantity(.bodyMassIndex))
    }

    @Test("Compiler resolves distance_swimming to quantity source")
    func distanceSwimming() throws {
        let stmt = SelectStatement(
            selections: [.aggregate(.sum, .identifier("value"))],
            from: "distance_swimming",
            groupBy: .timePeriod(.day)
        )

        let compiler = Compiler()
        let query = try compiler.compile(stmt)

        #expect(query.source == .quantity(.distanceSwimming))
        #expect(query.grouping == .day)
    }

    @Test("All Phase 4 quantity types are recognized")
    func allPhase4Types() throws {
        let phase4Types = [
            ("resting_heart_rate", QuantityType.restingHeartRate),
            ("walking_heart_rate_average", QuantityType.walkingHeartRateAverage),
            ("basal_body_temperature", QuantityType.basalBodyTemperature),
            ("peripheral_perfusion_index", QuantityType.peripheralPerfusionIndex),
            ("electrodermal_activity", QuantityType.electrodermalActivity),
            ("blood_alcohol_content", QuantityType.bloodAlcoholContent),
            ("vo2_max", QuantityType.vo2Max),
            ("distance_swimming", QuantityType.distanceSwimming),
            ("swimming_stroke_count", QuantityType.swimmingStrokeCount),
            ("distance_wheelchair", QuantityType.distanceWheelchair),
            ("push_count", QuantityType.pushCount),
            ("distance_downhill_snow_sports", QuantityType.distanceDownhillSnowSports),
            ("lean_body_mass", QuantityType.leanBodyMass),
            ("body_mass_index", QuantityType.bodyMassIndex),
            ("waist_circumference", QuantityType.waistCircumference),
        ]

        let compiler = Compiler()

        for (sqlName, expectedType) in phase4Types {
            let stmt = SelectStatement(selections: [.star], from: sqlName)
            let query = try compiler.compile(stmt)
            #expect(query.source == .quantity(expectedType), "Failed for \(sqlName)")
        }
    }
}
