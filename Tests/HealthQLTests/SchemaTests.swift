import Testing
@testable import HealthQL
import HealthKit

@Suite("Schema Registry Tests")
struct SchemaTests {

    @Test("QuantityType maps to correct HKQuantityTypeIdentifier")
    func quantityTypeIdentifiers() {
        #expect(QuantityType.steps.identifier == HKQuantityTypeIdentifier.stepCount)
        #expect(QuantityType.heartRate.identifier == HKQuantityTypeIdentifier.heartRate)
        #expect(QuantityType.activeCalories.identifier == HKQuantityTypeIdentifier.activeEnergyBurned)
    }

    @Test("QuantityType provides correct display names")
    func quantityTypeDisplayNames() {
        #expect(QuantityType.steps.displayName == "steps")
        #expect(QuantityType.heartRate.displayName == "heart_rate")
        #expect(QuantityType.activeCalories.displayName == "active_calories")
    }

    @Test("QuantityType provides correct default units")
    func quantityTypeUnits() {
        #expect(QuantityType.steps.defaultUnit == .count())
        #expect(QuantityType.heartRate.defaultUnit == HKUnit.count().unitDivided(by: .minute()))
        #expect(QuantityType.activeCalories.defaultUnit == .kilocalorie())
    }
}
