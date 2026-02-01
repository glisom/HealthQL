import Testing
import HealthKit
@testable import HealthQL

@Suite("WorkoutType Tests")
struct WorkoutTypeTests {

    @Test("WorkoutType maps to correct HKWorkoutActivityType")
    func workoutActivityTypes() {
        #expect(WorkoutType.running.activityType == .running)
        #expect(WorkoutType.cycling.activityType == .cycling)
        #expect(WorkoutType.swimming.activityType == .swimming)
        #expect(WorkoutType.yoga.activityType == .yoga)
    }

    @Test("WorkoutType provides correct display names")
    func displayNames() {
        #expect(WorkoutType.running.displayName == "running")
        #expect(WorkoutType.strengthTraining.displayName == "strength_training")
        #expect(WorkoutType.hiking.displayName == "hiking")
    }

    @Test("WorkoutType.from finds by display name")
    func fromDisplayName() {
        #expect(WorkoutType.from(displayName: "running") == .running)
        #expect(WorkoutType.from(displayName: "strength_training") == .strengthTraining)
        #expect(WorkoutType.from(displayName: "invalid") == nil)
    }

    @Test("WorkoutType provides available fields")
    func availableFields() {
        let fields = WorkoutType.running.availableFields
        #expect(fields.contains("activity_type"))
        #expect(fields.contains("duration"))
        #expect(fields.contains("total_calories"))
        #expect(fields.contains("distance"))
    }

    @Test("Workouts table name is correct")
    func workoutsTableName() {
        #expect(WorkoutType.tableName == "workouts")
    }
}
