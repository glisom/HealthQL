import Foundation
import HealthKit

/// Represents queryable quantity types from HealthKit
public enum QuantityType: String, CaseIterable, Sendable {
    case steps
    case heartRate
    case activeCalories
    case restingCalories
    case distance
    case flightsClimbed
    case standTime
    case exerciseMinutes
    case bodyMass
    case height
    case bodyFatPercentage
    case heartRateVariability
    case oxygenSaturation
    case respiratoryRate
    case bodyTemperature
    case bloodPressureSystolic
    case bloodPressureDiastolic
    case bloodGlucose

    // Phase 4: Extended Vitals
    case restingHeartRate
    case walkingHeartRateAverage
    case basalBodyTemperature
    case peripheralPerfusionIndex
    case electrodermalActivity
    case bloodAlcoholContent

    // Phase 4: Fitness Metrics
    case vo2Max
    case distanceSwimming
    case swimmingStrokeCount
    case distanceWheelchair
    case pushCount
    case distanceDownhillSnowSports

    // Phase 4: Body Measurements
    case leanBodyMass
    case bodyMassIndex
    case waistCircumference

    /// The HealthKit identifier for this quantity type
    public var identifier: HKQuantityTypeIdentifier {
        switch self {
        case .steps: return .stepCount
        case .heartRate: return .heartRate
        case .activeCalories: return .activeEnergyBurned
        case .restingCalories: return .basalEnergyBurned
        case .distance: return .distanceWalkingRunning
        case .flightsClimbed: return .flightsClimbed
        case .standTime: return .appleStandTime
        case .exerciseMinutes: return .appleExerciseTime
        case .bodyMass: return .bodyMass
        case .height: return .height
        case .bodyFatPercentage: return .bodyFatPercentage
        case .heartRateVariability: return .heartRateVariabilitySDNN
        case .oxygenSaturation: return .oxygenSaturation
        case .respiratoryRate: return .respiratoryRate
        case .bodyTemperature: return .bodyTemperature
        case .bloodPressureSystolic: return .bloodPressureSystolic
        case .bloodPressureDiastolic: return .bloodPressureDiastolic
        case .bloodGlucose: return .bloodGlucose
        // Phase 4: Extended Vitals
        case .restingHeartRate: return .restingHeartRate
        case .walkingHeartRateAverage: return .walkingHeartRateAverage
        case .basalBodyTemperature: return .basalBodyTemperature
        case .peripheralPerfusionIndex: return .peripheralPerfusionIndex
        case .electrodermalActivity: return .electrodermalActivity
        case .bloodAlcoholContent: return .bloodAlcoholContent
        // Phase 4: Fitness Metrics
        case .vo2Max: return .vo2Max
        case .distanceSwimming: return .distanceSwimming
        case .swimmingStrokeCount: return .swimmingStrokeCount
        case .distanceWheelchair: return .distanceWheelchair
        case .pushCount: return .pushCount
        case .distanceDownhillSnowSports: return .distanceDownhillSnowSports
        // Phase 4: Body Measurements
        case .leanBodyMass: return .leanBodyMass
        case .bodyMassIndex: return .bodyMassIndex
        case .waistCircumference: return .waistCircumference
        }
    }

    /// The HKQuantityType for this quantity type
    public var hkType: HKQuantityType {
        HKQuantityType(identifier)
    }

    /// Human-readable display name (snake_case for SQL compatibility)
    public var displayName: String {
        switch self {
        case .steps: return "steps"
        case .heartRate: return "heart_rate"
        case .activeCalories: return "active_calories"
        case .restingCalories: return "resting_calories"
        case .distance: return "distance"
        case .flightsClimbed: return "flights_climbed"
        case .standTime: return "stand_time"
        case .exerciseMinutes: return "exercise_minutes"
        case .bodyMass: return "body_mass"
        case .height: return "height"
        case .bodyFatPercentage: return "body_fat_percentage"
        case .heartRateVariability: return "heart_rate_variability"
        case .oxygenSaturation: return "oxygen_saturation"
        case .respiratoryRate: return "respiratory_rate"
        case .bodyTemperature: return "body_temperature"
        case .bloodPressureSystolic: return "blood_pressure_systolic"
        case .bloodPressureDiastolic: return "blood_pressure_diastolic"
        case .bloodGlucose: return "blood_glucose"
        // Phase 4: Extended Vitals
        case .restingHeartRate: return "resting_heart_rate"
        case .walkingHeartRateAverage: return "walking_heart_rate_average"
        case .basalBodyTemperature: return "basal_body_temperature"
        case .peripheralPerfusionIndex: return "peripheral_perfusion_index"
        case .electrodermalActivity: return "electrodermal_activity"
        case .bloodAlcoholContent: return "blood_alcohol_content"
        // Phase 4: Fitness Metrics
        case .vo2Max: return "vo2_max"
        case .distanceSwimming: return "distance_swimming"
        case .swimmingStrokeCount: return "swimming_stroke_count"
        case .distanceWheelchair: return "distance_wheelchair"
        case .pushCount: return "push_count"
        case .distanceDownhillSnowSports: return "distance_downhill_snow_sports"
        // Phase 4: Body Measurements
        case .leanBodyMass: return "lean_body_mass"
        case .bodyMassIndex: return "body_mass_index"
        case .waistCircumference: return "waist_circumference"
        }
    }

    /// The default unit for this quantity type
    public var defaultUnit: HKUnit {
        switch self {
        case .steps: return .count()
        case .heartRate: return HKUnit.count().unitDivided(by: .minute())
        case .activeCalories, .restingCalories: return .kilocalorie()
        case .distance: return .meter()
        case .flightsClimbed: return .count()
        case .standTime, .exerciseMinutes: return .minute()
        case .bodyMass: return .gramUnit(with: .kilo)
        case .height: return .meter()
        case .bodyFatPercentage, .oxygenSaturation: return .percent()
        case .heartRateVariability: return .secondUnit(with: .milli)
        case .respiratoryRate: return HKUnit.count().unitDivided(by: .minute())
        case .bodyTemperature: return .degreeCelsius()
        case .bloodPressureSystolic, .bloodPressureDiastolic: return .millimeterOfMercury()
        case .bloodGlucose: return HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        // Phase 4: Extended Vitals
        case .restingHeartRate, .walkingHeartRateAverage: return HKUnit.count().unitDivided(by: .minute())
        case .basalBodyTemperature: return .degreeCelsius()
        case .peripheralPerfusionIndex: return .percent()
        case .electrodermalActivity: return .siemen()
        case .bloodAlcoholContent: return .percent()
        // Phase 4: Fitness Metrics
        case .vo2Max: return HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo).unitMultiplied(by: .minute()))
        case .distanceSwimming, .distanceWheelchair, .distanceDownhillSnowSports: return .meter()
        case .swimmingStrokeCount, .pushCount: return .count()
        // Phase 4: Body Measurements
        case .leanBodyMass: return .gramUnit(with: .kilo)
        case .bodyMassIndex: return .count()
        case .waistCircumference: return .meter()
        }
    }

    /// Look up a quantity type by display name
    public static func from(displayName: String) -> QuantityType? {
        allCases.first { $0.displayName == displayName }
    }
}
