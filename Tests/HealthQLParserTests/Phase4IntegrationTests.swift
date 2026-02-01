import Testing
@testable import HealthQL
@testable import HealthQLParser

@Suite("Phase 4 Integration Tests")
struct Phase4IntegrationTests {

    @Test("Parse and compile sleep_analysis query")
    func sleepAnalysisQuery() throws {
        let query = try HQL.parse("SELECT * FROM sleep_analysis WHERE date > today() - 7d")

        if case .category(let type) = query.source {
            #expect(type == .sleepAnalysis)
        } else {
            Issue.record("Expected category source")
        }
        #expect(query.predicates.count == 1)
    }

    @Test("Parse and compile workouts query")
    func workoutsQuery() throws {
        let query = try HQL.parse("SELECT duration, total_calories FROM workouts")

        if case .workout = query.source {
            // Pass
        } else {
            Issue.record("Expected workout source")
        }
        #expect(query.selections.count == 2)
    }

    @Test("Parse and compile sleep session query")
    func sleepSessionQuery() throws {
        let query = try HQL.parse("SELECT duration, deep, rem FROM sleep WHERE date > today() - 30d")

        if case .sleepSession = query.source {
            // Pass
        } else {
            Issue.record("Expected sleepSession source")
        }
    }

    @Test("Parse and compile symptom query with aggregation")
    func symptomAggregateQuery() throws {
        let query = try HQL.parse("SELECT count(*) FROM headache GROUP BY week")

        if case .category(let type) = query.source {
            #expect(type == .headache)
        } else {
            Issue.record("Expected category source")
        }
        #expect(query.grouping == .week)
    }

    @Test("Parse and compile workout query with ORDER BY")
    func workoutOrderByQuery() throws {
        let query = try HQL.parse("SELECT * FROM workouts ORDER BY date DESC LIMIT 10")

        if case .workout = query.source {
            // Pass
        } else {
            Issue.record("Expected workout source")
        }
        #expect(query.limit == 10)
        #expect(query.ordering?.first?.direction == .descending)
    }
}
