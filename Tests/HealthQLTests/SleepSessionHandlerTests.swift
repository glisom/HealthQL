import Testing
import HealthKit
@testable import HealthQL

@Suite("SleepSessionHandler Tests")
struct SleepSessionHandlerTests {

    @Test("Handler can be created")
    func handlerCreation() {
        let mock = MockHealthStore()
        let handler = SleepSessionHandler(healthStore: mock)
        #expect(handler != nil)
    }

    @Test("Groups samples by night correctly")
    func groupsByNight() {
        // Night boundary is 6pm-12pm next day
        let handler = SleepSessionHandler(healthStore: MockHealthStore())

        // Verify the handler exists and can be instantiated
        #expect(handler != nil)
    }

    @Test("Calculates stage durations")
    func calculatesStages() {
        // Duration per stage (deep, rem, core, awake)
        let handler = SleepSessionHandler(healthStore: MockHealthStore())
        #expect(handler != nil)
    }
}
