import Foundation
import HealthKit
import HealthQL

/// Bridges the Expo module to the Swift HealthQL core
final class HealthQLBridge {
    private let healthStore: HKHealthStore?

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        } else {
            self.healthStore = nil
        }
    }

    /// Execute a SQL query and return results in the specified format
    func query(sql: String, format: String) async throws -> Any {
        guard healthStore != nil else {
            throw HealthQLBridgeError.healthKitNotAvailable
        }

        // Execute query using HealthQL
        let result = try await HQL.query(sql)

        // Convert to JS-friendly format
        return convertResult(result, format: format)
    }

    /// Convert QueryResult to a format suitable for JavaScript
    private func convertResult(_ result: QueryResult, format: String) -> [[String: Any]] {
        return result.rows.map { row in
            var dict: [String: Any] = [:]
            for (key, value) in row.values {
                dict[key] = convertValue(value)
            }
            return dict
        }
    }

    /// Convert a ResultValue to a JS-compatible type
    private func convertValue(_ value: ResultValue) -> Any {
        switch value {
        case .double(let d):
            return d
        case .int(let i):
            return i
        case .string(let s):
            return s
        case .date(let date):
            // Return ISO8601 string for dates
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.string(from: date)
        case .null:
            return NSNull()
        }
    }

    /// Request authorization to read the specified health types
    func requestAuthorization(types: [String]) async throws {
        guard let store = healthStore else {
            throw HealthQLBridgeError.healthKitNotAvailable
        }

        let hkTypes = try types.map { typeName -> HKObjectType in
            guard let hkType = resolveHealthType(typeName) else {
                throw HealthQLBridgeError.unknownType(typeName)
            }
            return hkType
        }

        let typeSet = Set(hkTypes)

        try await store.requestAuthorization(toShare: [], read: typeSet)
    }

    /// Get the authorization status for a specific health type
    func getAuthorizationStatus(type: String) async throws -> String {
        guard let store = healthStore else {
            throw HealthQLBridgeError.healthKitNotAvailable
        }

        guard let hkType = resolveHealthType(type) else {
            throw HealthQLBridgeError.unknownType(type)
        }

        let status = store.authorizationStatus(for: hkType)

        switch status {
        case .notDetermined:
            return "notDetermined"
        case .sharingDenied:
            return "denied"
        case .sharingAuthorized:
            return "authorized"
        @unknown default:
            return "notDetermined"
        }
    }

    /// Resolve a type name (e.g., "heart_rate") to an HKObjectType
    private func resolveHealthType(_ name: String) -> HKObjectType? {
        // Quantity types
        let quantityTypes: [String: HKQuantityTypeIdentifier] = [
            "steps": .stepCount,
            "heart_rate": .heartRate,
            "active_calories": .activeEnergyBurned,
            "resting_calories": .basalEnergyBurned,
            "distance": .distanceWalkingRunning,
            "flights_climbed": .flightsClimbed,
            "stand_time": .appleStandTime,
            "exercise_minutes": .appleExerciseTime,
            "body_mass": .bodyMass,
            "height": .height,
            "body_fat_percentage": .bodyFatPercentage,
            "heart_rate_variability": .heartRateVariabilitySDNN,
            "oxygen_saturation": .oxygenSaturation,
            "respiratory_rate": .respiratoryRate,
            "body_temperature": .bodyTemperature,
            "blood_pressure_systolic": .bloodPressureSystolic,
            "blood_pressure_diastolic": .bloodPressureDiastolic,
            "blood_glucose": .bloodGlucose
        ]

        if let identifier = quantityTypes[name] {
            return HKQuantityType(identifier)
        }

        // Category types
        let categoryTypes: [String: HKCategoryTypeIdentifier] = [
            "sleep_analysis": .sleepAnalysis,
            "appetite_changes": .appetiteChanges,
            "headache": .headache,
            "fatigue": .fatigue,
            "menstrual_flow": .menstrualFlow
        ]

        if let identifier = categoryTypes[name] {
            return HKCategoryType(identifier)
        }

        // Special types
        switch name {
        case "workouts":
            return HKObjectType.workoutType()
        case "sleep_sessions":
            return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        default:
            return nil
        }
    }
}

/// Errors specific to the bridge layer
enum HealthQLBridgeError: Error {
    case healthKitNotAvailable
    case unknownType(String)
    case authorizationDenied
}
