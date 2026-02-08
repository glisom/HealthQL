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

// MARK: - Phase 4 Extended Vitals Tests

@Suite("Phase 4 Extended Vitals Tests")
struct Phase4VitalsTests {

    @Test("Resting heart rate maps correctly")
    func restingHeartRate() {
        #expect(QuantityType.restingHeartRate.identifier == .restingHeartRate)
        #expect(QuantityType.restingHeartRate.displayName == "resting_heart_rate")
        #expect(QuantityType.restingHeartRate.defaultUnit == HKUnit.count().unitDivided(by: .minute()))
    }

    @Test("Walking heart rate average maps correctly")
    func walkingHeartRateAverage() {
        #expect(QuantityType.walkingHeartRateAverage.identifier == .walkingHeartRateAverage)
        #expect(QuantityType.walkingHeartRateAverage.displayName == "walking_heart_rate_average")
        #expect(QuantityType.walkingHeartRateAverage.defaultUnit == HKUnit.count().unitDivided(by: .minute()))
    }

    @Test("Basal body temperature maps correctly")
    func basalBodyTemperature() {
        #expect(QuantityType.basalBodyTemperature.identifier == .basalBodyTemperature)
        #expect(QuantityType.basalBodyTemperature.displayName == "basal_body_temperature")
        #expect(QuantityType.basalBodyTemperature.defaultUnit == .degreeCelsius())
    }

    @Test("Peripheral perfusion index maps correctly")
    func peripheralPerfusionIndex() {
        #expect(QuantityType.peripheralPerfusionIndex.identifier == .peripheralPerfusionIndex)
        #expect(QuantityType.peripheralPerfusionIndex.displayName == "peripheral_perfusion_index")
        #expect(QuantityType.peripheralPerfusionIndex.defaultUnit == .percent())
    }

    @Test("Electrodermal activity maps correctly")
    func electrodermalActivity() {
        #expect(QuantityType.electrodermalActivity.identifier == .electrodermalActivity)
        #expect(QuantityType.electrodermalActivity.displayName == "electrodermal_activity")
        #expect(QuantityType.electrodermalActivity.defaultUnit == .siemen())
    }

    @Test("Blood alcohol content maps correctly")
    func bloodAlcoholContent() {
        #expect(QuantityType.bloodAlcoholContent.identifier == .bloodAlcoholContent)
        #expect(QuantityType.bloodAlcoholContent.displayName == "blood_alcohol_content")
        #expect(QuantityType.bloodAlcoholContent.defaultUnit == .percent())
    }
}

// MARK: - Phase 4 Fitness Metrics Tests

@Suite("Phase 4 Fitness Metrics Tests")
struct Phase4FitnessTests {

    @Test("VO2 max maps correctly")
    func vo2Max() {
        #expect(QuantityType.vo2Max.identifier == .vo2Max)
        #expect(QuantityType.vo2Max.displayName == "vo2_max")
        // mL/(kg·min)
        let expectedUnit = HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute()))
        #expect(QuantityType.vo2Max.defaultUnit == expectedUnit)
    }

    @Test("Distance swimming maps correctly")
    func distanceSwimming() {
        #expect(QuantityType.distanceSwimming.identifier == .distanceSwimming)
        #expect(QuantityType.distanceSwimming.displayName == "distance_swimming")
        #expect(QuantityType.distanceSwimming.defaultUnit == .meter())
    }

    @Test("Swimming stroke count maps correctly")
    func swimmingStrokeCount() {
        #expect(QuantityType.swimmingStrokeCount.identifier == .swimmingStrokeCount)
        #expect(QuantityType.swimmingStrokeCount.displayName == "swimming_stroke_count")
        #expect(QuantityType.swimmingStrokeCount.defaultUnit == .count())
    }

    @Test("Distance wheelchair maps correctly")
    func distanceWheelchair() {
        #expect(QuantityType.distanceWheelchair.identifier == .distanceWheelchair)
        #expect(QuantityType.distanceWheelchair.displayName == "distance_wheelchair")
        #expect(QuantityType.distanceWheelchair.defaultUnit == .meter())
    }

    @Test("Push count maps correctly")
    func pushCount() {
        #expect(QuantityType.pushCount.identifier == .pushCount)
        #expect(QuantityType.pushCount.displayName == "push_count")
        #expect(QuantityType.pushCount.defaultUnit == .count())
    }

    @Test("Distance downhill snow sports maps correctly")
    func distanceDownhillSnowSports() {
        #expect(QuantityType.distanceDownhillSnowSports.identifier == .distanceDownhillSnowSports)
        #expect(QuantityType.distanceDownhillSnowSports.displayName == "distance_downhill_snow_sports")
        #expect(QuantityType.distanceDownhillSnowSports.defaultUnit == .meter())
    }
}

// MARK: - Phase 4 Body Measurements Tests

@Suite("Phase 4 Body Measurements Tests")
struct Phase4BodyMeasurementsTests {

    @Test("Lean body mass maps correctly")
    func leanBodyMass() {
        #expect(QuantityType.leanBodyMass.identifier == .leanBodyMass)
        #expect(QuantityType.leanBodyMass.displayName == "lean_body_mass")
        #expect(QuantityType.leanBodyMass.defaultUnit == .gramUnit(with: .kilo))
    }

    @Test("Body mass index maps correctly")
    func bodyMassIndex() {
        #expect(QuantityType.bodyMassIndex.identifier == .bodyMassIndex)
        #expect(QuantityType.bodyMassIndex.displayName == "body_mass_index")
        #expect(QuantityType.bodyMassIndex.defaultUnit == .count())
    }

    @Test("Waist circumference maps correctly")
    func waistCircumference() {
        #expect(QuantityType.waistCircumference.identifier == .waistCircumference)
        #expect(QuantityType.waistCircumference.displayName == "waist_circumference")
        #expect(QuantityType.waistCircumference.defaultUnit == .meter())
    }
}

// MARK: - Phase 4 Lookup Tests

@Suite("Phase 4 Display Name Lookup Tests")
struct Phase4LookupTests {

    @Test("Extended vitals can be looked up by display name")
    func vitalsLookup() {
        #expect(QuantityType.from(displayName: "resting_heart_rate") == .restingHeartRate)
        #expect(QuantityType.from(displayName: "walking_heart_rate_average") == .walkingHeartRateAverage)
        #expect(QuantityType.from(displayName: "basal_body_temperature") == .basalBodyTemperature)
        #expect(QuantityType.from(displayName: "peripheral_perfusion_index") == .peripheralPerfusionIndex)
        #expect(QuantityType.from(displayName: "electrodermal_activity") == .electrodermalActivity)
        #expect(QuantityType.from(displayName: "blood_alcohol_content") == .bloodAlcoholContent)
    }

    @Test("Fitness metrics can be looked up by display name")
    func fitnessLookup() {
        #expect(QuantityType.from(displayName: "vo2_max") == .vo2Max)
        #expect(QuantityType.from(displayName: "distance_swimming") == .distanceSwimming)
        #expect(QuantityType.from(displayName: "swimming_stroke_count") == .swimmingStrokeCount)
        #expect(QuantityType.from(displayName: "distance_wheelchair") == .distanceWheelchair)
        #expect(QuantityType.from(displayName: "push_count") == .pushCount)
        #expect(QuantityType.from(displayName: "distance_downhill_snow_sports") == .distanceDownhillSnowSports)
    }

    @Test("Body measurements can be looked up by display name")
    func bodyMeasurementsLookup() {
        #expect(QuantityType.from(displayName: "lean_body_mass") == .leanBodyMass)
        #expect(QuantityType.from(displayName: "body_mass_index") == .bodyMassIndex)
        #expect(QuantityType.from(displayName: "waist_circumference") == .waistCircumference)
    }
}
