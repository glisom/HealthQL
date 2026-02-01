import Testing
import HealthKit
@testable import HealthQL

@Suite("CategoryQueryHandler Tests")
struct CategoryQueryHandlerTests {

    @Test("Handler can be created")
    func handlerCreation() {
        let mock = MockHealthStore()
        let handler = CategoryQueryHandler(healthStore: mock)
        #expect(handler != nil)
    }

    @Test("Maps sleep stage value to display name")
    func mapsSleepStage() {
        #expect(SleepStage(rawValue: 0)?.displayName == "in_bed")
        #expect(SleepStage(rawValue: 5)?.displayName == "rem")
    }

    @Test("Maps severity value to display name")
    func mapsSeverity() {
        #expect(Severity(rawValue: 1)?.displayName == "mild")
        #expect(Severity(rawValue: 3)?.displayName == "severe")
    }
}
