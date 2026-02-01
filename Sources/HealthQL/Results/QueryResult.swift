import Foundation

/// A value in a result row
public enum ResultValue: Sendable, Equatable {
    case double(Double)
    case int(Int)
    case string(String)
    case date(Date)
    case null
}

/// A single row in query results
public struct ResultRow: Sendable {
    public let values: [String: ResultValue]

    public init(values: [String: ResultValue]) {
        self.values = values
    }

    /// Get a Double value by column name
    public func double(_ key: String) -> Double? {
        if case .double(let value) = values[key] {
            return value
        }
        return nil
    }

    /// Get an Int value by column name
    public func int(_ key: String) -> Int? {
        if case .int(let value) = values[key] {
            return value
        }
        return nil
    }

    /// Get a String value by column name
    public func string(_ key: String) -> String? {
        if case .string(let value) = values[key] {
            return value
        }
        return nil
    }

    /// Get a Date value by column name
    public func date(_ key: String) -> Date? {
        if case .date(let value) = values[key] {
            return value
        }
        return nil
    }

    /// Check if a column is null
    public func isNull(_ key: String) -> Bool {
        if case .null = values[key] {
            return true
        }
        return values[key] == nil
    }
}

/// The result of executing a HealthQL query
public struct QueryResult: Sendable {
    public let rows: [ResultRow]
    public let executionTime: TimeInterval

    public init(rows: [ResultRow], executionTime: TimeInterval) {
        self.rows = rows
        self.executionTime = executionTime
    }

    /// Number of rows in the result
    public var count: Int { rows.count }

    /// Whether the result is empty
    public var isEmpty: Bool { rows.isEmpty }
}

extension QueryResult: Sequence {
    public func makeIterator() -> IndexingIterator<[ResultRow]> {
        rows.makeIterator()
    }
}
