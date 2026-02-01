import Foundation
import HealthKit

/// Sleep stages from HKCategoryValueSleepAnalysis
public enum SleepStage: Int, CaseIterable, Sendable {
    case inBed = 0
    case asleepUnspecified = 1
    case awake = 2
    case asleepCore = 3
    case asleepDeep = 4
    case asleepREM = 5

    public var displayName: String {
        switch self {
        case .inBed: return "in_bed"
        case .asleepUnspecified: return "asleep"
        case .awake: return "awake"
        case .asleepCore: return "core"
        case .asleepDeep: return "deep"
        case .asleepREM: return "rem"
        }
    }
}

/// Severity levels for symptoms
public enum Severity: Int, CaseIterable, Sendable {
    case notPresent = 0
    case mild = 1
    case moderate = 2
    case severe = 3
    case unspecified = 4

    public var displayName: String {
        switch self {
        case .notPresent: return "not_present"
        case .mild: return "mild"
        case .moderate: return "moderate"
        case .severe: return "severe"
        case .unspecified: return "unspecified"
        }
    }
}

/// Represents queryable category types from HealthKit
public enum CategoryType: String, CaseIterable, Sendable {
    case sleepAnalysis
    case appetiteChanges
    case headache
    case fatigue
    case menstrualFlow

    /// The HealthKit identifier for this category type
    public var identifier: HKCategoryTypeIdentifier {
        switch self {
        case .sleepAnalysis: return .sleepAnalysis
        case .appetiteChanges: return .appetiteChanges
        case .headache: return .headache
        case .fatigue: return .fatigue
        case .menstrualFlow: return .menstrualFlow
        }
    }

    /// The HKCategoryType for this category type
    public var hkType: HKCategoryType {
        HKCategoryType(identifier)
    }

    /// Human-readable display name (snake_case for SQL compatibility)
    public var displayName: String {
        switch self {
        case .sleepAnalysis: return "sleep_analysis"
        case .appetiteChanges: return "appetite_changes"
        case .headache: return "headache"
        case .fatigue: return "fatigue"
        case .menstrualFlow: return "menstrual_flow"
        }
    }

    /// Available fields for this category type
    public var availableFields: [String] {
        switch self {
        case .sleepAnalysis:
            return ["value", "stage", "date", "end_date", "duration", "source", "device"]
        default:
            return ["value", "severity", "date", "end_date", "source", "device"]
        }
    }

    /// Look up a category type by display name
    public static func from(displayName: String) -> CategoryType? {
        allCases.first { $0.displayName == displayName }
    }
}
