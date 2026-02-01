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

    @Test("HealthSource supports category type")
    func healthSourceCategory() {
        let source = HealthSource.category(.sleepAnalysis)
        if case .category(let type) = source {
            #expect(type == .sleepAnalysis)
        } else {
            Issue.record("Expected category source")
        }
    }

    @Test("HealthSource supports workout")
    func healthSourceWorkout() {
        let source = HealthSource.workout
        if case .workout = source {
            // Pass
        } else {
            Issue.record("Expected workout source")
        }
    }

    @Test("HealthSource supports sleep session")
    func healthSourceSleepSession() {
        let source = HealthSource.sleepSession
        if case .sleepSession = source {
            // Pass
        } else {
            Issue.record("Expected sleepSession source")
        }
    }

    @Test("PredicateValue supports categoryValue")
    func predicateCategoryValue() {
        let value = PredicateValue.categoryValue(3)
        if case .categoryValue(let v) = value {
            #expect(v == 3)
        } else {
            Issue.record("Expected categoryValue")
        }
    }

    @Test("Field has stage for category queries")
    func fieldStage() {
        let field = Field.stage
        #expect(field == .stage)
    }

    @Test("Field has activityType for workout queries")
    func fieldActivityType() {
        let field = Field.activityType
        #expect(field == .activityType)
    }

    @Test("Field has duration")
    func fieldDuration() {
        let field = Field.duration
        #expect(field == .duration)
    }

    @Test("Field has totalCalories")
    func fieldTotalCalories() {
        let field = Field.totalCalories
        #expect(field == .totalCalories)
    }
}
