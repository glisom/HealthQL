import Foundation

/// Provides mock data for testing when HealthKit is not available
enum MockDataProvider {
    /// ISO 8601 date formatter
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Generate mock results for a query
    static func mockResults(for sql: String, format: String) -> Any {
        let rows = generateMockRows(for: sql)

        if format == "columnar" {
            return toColumnar(rows)
        } else {
            return rows
        }
    }

    /// Generate mock row data based on the query type
    private static func generateMockRows(for sql: String) -> [[String: Any]] {
        let lowercasedSQL = sql.lowercased()

        // Detect the health type from the query
        if lowercasedSQL.contains("heart_rate") {
            return mockHeartRateData()
        } else if lowercasedSQL.contains("steps") {
            return mockStepsData()
        } else if lowercasedSQL.contains("sleep") {
            return mockSleepData()
        } else if lowercasedSQL.contains("workout") {
            return mockWorkoutData()
        } else {
            // Generic mock data
            return mockGenericData()
        }
    }

    private static func mockHeartRateData() -> [[String: Any]] {
        let now = Date()
        return (0..<7).map { dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: now)!
            return [
                "date": isoFormatter.string(from: date),
                "value": Double.random(in: 60...100),
                "unit": "count/min"
            ]
        }
    }

    private static func mockStepsData() -> [[String: Any]] {
        let now = Date()
        return (0..<7).map { dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: now)!
            return [
                "date": isoFormatter.string(from: date),
                "value": Double(Int.random(in: 3000...12000)),
                "unit": "count"
            ]
        }
    }

    private static func mockSleepData() -> [[String: Any]] {
        let now = Date()
        return (0..<7).map { dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: now)!
            return [
                "date": isoFormatter.string(from: date),
                "value": "asleep",
                "duration": Double(Int.random(in: 25200...32400)) // 7-9 hours in seconds
            ]
        }
    }

    private static func mockWorkoutData() -> [[String: Any]] {
        let workoutTypes = ["running", "cycling", "walking", "swimming", "strength_training"]
        let now = Date()
        return (0..<5).map { dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset * 2, to: now)!
            return [
                "date": isoFormatter.string(from: date),
                "type": workoutTypes.randomElement()!,
                "duration": Double(Int.random(in: 1800...5400)), // 30-90 minutes
                "calories": Double(Int.random(in: 200...600)),
                "distance": Double(Int.random(in: 2000...10000))
            ]
        }
    }

    private static func mockGenericData() -> [[String: Any]] {
        let now = Date()
        return (0..<5).map { dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: now)!
            return [
                "date": isoFormatter.string(from: date),
                "value": Double.random(in: 0...100),
                "unit": "unit"
            ]
        }
    }

    /// Convert rows to columnar format
    private static func toColumnar(_ rows: [[String: Any]]) -> [String: Any] {
        guard let firstRow = rows.first else {
            return ["columns": [], "rows": []]
        }

        let columns = Array(firstRow.keys).sorted()
        let rowArrays: [[Any?]] = rows.map { row in
            columns.map { row[$0] }
        }

        return [
            "columns": columns,
            "rows": rowArrays
        ]
    }
}
