import Foundation
import HealthKit

/// Represents workout activity types from HealthKit
public enum WorkoutType: String, CaseIterable, Sendable {
    case running
    case walking
    case cycling
    case swimming
    case yoga
    case strengthTraining
    case hiking
    case elliptical
    case rowing
    case functionalTraining
    case coreTraining
    case highIntensityIntervalTraining

    /// The table name for workout queries
    public static let tableName = "workouts"

    /// The HealthKit activity type
    public var activityType: HKWorkoutActivityType {
        switch self {
        case .running: return .running
        case .walking: return .walking
        case .cycling: return .cycling
        case .swimming: return .swimming
        case .yoga: return .yoga
        case .strengthTraining: return .traditionalStrengthTraining
        case .hiking: return .hiking
        case .elliptical: return .elliptical
        case .rowing: return .rowing
        case .functionalTraining: return .functionalStrengthTraining
        case .coreTraining: return .coreTraining
        case .highIntensityIntervalTraining: return .highIntensityIntervalTraining
        }
    }

    /// Human-readable display name (snake_case for SQL compatibility)
    public var displayName: String {
        switch self {
        case .running: return "running"
        case .walking: return "walking"
        case .cycling: return "cycling"
        case .swimming: return "swimming"
        case .yoga: return "yoga"
        case .strengthTraining: return "strength_training"
        case .hiking: return "hiking"
        case .elliptical: return "elliptical"
        case .rowing: return "rowing"
        case .functionalTraining: return "functional_training"
        case .coreTraining: return "core_training"
        case .highIntensityIntervalTraining: return "hiit"
        }
    }

    /// Available fields for workouts
    public var availableFields: [String] {
        ["activity_type", "start_date", "end_date", "duration", "total_calories", "distance", "source", "device"]
    }

    /// Look up a workout type by display name
    public static func from(displayName: String) -> WorkoutType? {
        allCases.first { $0.displayName == displayName }
    }
}
