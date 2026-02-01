import Foundation
import HealthQL

/// Provides schema information for REPL commands
public struct SchemaInfo: Sendable {

    public struct TypeSchema: Sendable {
        public let name: String
        public let displayName: String
        public let fields: [String]
        public let unit: String
    }

    public init() {}

    /// Get all available type names
    public func allTypes() -> [String] {
        var types: [String] = []

        // Quantity types
        types.append(contentsOf: QuantityType.allCases.map { $0.displayName })

        // Category types
        types.append(contentsOf: CategoryType.allCases.map { $0.displayName })

        // Special tables
        types.append(WorkoutType.tableName)  // "workouts"
        types.append("sleep")                 // aggregated sleep sessions

        return types.sorted()
    }

    /// Get schema for a specific type
    public func schema(for typeName: String) -> TypeSchema? {
        // Special case: workouts
        if typeName == WorkoutType.tableName {
            return TypeSchema(
                name: "workouts",
                displayName: "workouts",
                fields: ["activity_type", "start_date", "end_date", "duration", "total_calories", "distance", "source", "device"],
                unit: "session"
            )
        }

        // Special case: sleep sessions
        if typeName == "sleep" {
            return TypeSchema(
                name: "sleep",
                displayName: "sleep",
                fields: ["start_date", "end_date", "duration", "in_bed_duration", "rem", "core", "deep", "awake"],
                unit: "session"
            )
        }

        // Try quantity type
        if let type = QuantityType.from(displayName: typeName) {
            return quantitySchema(for: type)
        }

        // Try category type
        if let type = CategoryType.from(displayName: typeName) {
            return categorySchema(for: type)
        }

        // Try camelCase conversion
        let camelCase = typeName
            .split(separator: "_")
            .enumerated()
            .map { $0.offset == 0 ? String($0.element) : String($0.element).capitalized }
            .joined()

        if let type = QuantityType(rawValue: camelCase) {
            return quantitySchema(for: type)
        }

        return nil
    }

    /// Suggest similar type names for typos
    public func suggest(for typeName: String) -> [String] {
        let allNames = allTypes()
        let lowercased = typeName.lowercased()

        return allNames.filter { name in
            let nameLC = name.lowercased()
            let commonPrefix = nameLC.commonPrefix(with: lowercased)
            let similarity = Double(commonPrefix.count) / Double(max(nameLC.count, lowercased.count))

            return similarity > 0.5 || levenshteinDistance(nameLC, lowercased) <= 2
        }
    }

    private func quantitySchema(for type: QuantityType) -> TypeSchema {
        TypeSchema(
            name: type.rawValue,
            displayName: type.displayName,
            fields: ["value", "date", "end_date", "source", "device"],
            unit: type.defaultUnit.unitString
        )
    }

    private func categorySchema(for type: CategoryType) -> TypeSchema {
        TypeSchema(
            name: type.rawValue,
            displayName: type.displayName,
            fields: type.availableFields,
            unit: "category"
        )
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count

        if m == 0 { return n }
        if n == 0 { return m }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i-1] == s2Array[j-1] ? 0 : 1
                matrix[i][j] = Swift.min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }

        return matrix[m][n]
    }
}
