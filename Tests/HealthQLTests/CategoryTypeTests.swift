import Testing
import HealthKit
@testable import HealthQL

@Suite("CategoryType Tests")
struct CategoryTypeTests {

    @Test("CategoryType maps to correct HKCategoryTypeIdentifier")
    func categoryTypeIdentifiers() {
        #expect(CategoryType.sleepAnalysis.identifier == .sleepAnalysis)
        #expect(CategoryType.appetiteChanges.identifier == .appetiteChanges)
        #expect(CategoryType.headache.identifier == .headache)
    }

    @Test("CategoryType provides correct display names")
    func displayNames() {
        #expect(CategoryType.sleepAnalysis.displayName == "sleep_analysis")
        #expect(CategoryType.headache.displayName == "headache")
        #expect(CategoryType.menstrualFlow.displayName == "menstrual_flow")
    }

    @Test("CategoryType.from finds by display name")
    func fromDisplayName() {
        #expect(CategoryType.from(displayName: "sleep_analysis") == .sleepAnalysis)
        #expect(CategoryType.from(displayName: "headache") == .headache)
        #expect(CategoryType.from(displayName: "invalid") == nil)
    }

    @Test("CategoryType provides available fields")
    func availableFields() {
        let fields = CategoryType.sleepAnalysis.availableFields
        #expect(fields.contains("value"))
        #expect(fields.contains("date"))
        #expect(fields.contains("end_date"))
    }

    @Test("SleepStage enum has correct values")
    func sleepStages() {
        #expect(SleepStage.inBed.rawValue == 0)
        #expect(SleepStage.asleepUnspecified.rawValue == 1)
        #expect(SleepStage.awake.rawValue == 2)
        #expect(SleepStage.asleepCore.rawValue == 3)
        #expect(SleepStage.asleepDeep.rawValue == 4)
        #expect(SleepStage.asleepREM.rawValue == 5)
    }
}
