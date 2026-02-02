# API Reference

## HealthQLParser Module

### HQL

Main entry point for SQL string queries.

```swift
public enum HQL {
    /// Parse a SQL query string into HealthQuery IR
    static func parse(_ query: String) throws -> HealthQuery

    /// Parse and execute a SQL query
    static func query(_ query: String) async throws -> QueryResult
}
```

#### Example

```swift
import HealthQLParser

// Parse only
let healthQuery = try HQL.parse("SELECT * FROM heart_rate")

// Parse and execute
let result = try await HQL.query("SELECT * FROM heart_rate LIMIT 10")
```

---

## HealthQL Module

### Health

Entry point for Swift DSL queries.

```swift
public enum Health {
    /// Start building a query for a quantity type
    static func select(_ type: QuantityType) -> QueryBuilder
    static func select(_ type: QuantityType, aggregate: Aggregate) -> QueryBuilder
    static func select(_ type: QuantityType, aggregates: [Aggregate]) -> QueryBuilder
}
```

### QueryBuilder

Fluent API for building queries.

```swift
public class QueryBuilder {
    /// Add a WHERE predicate
    func `where`(_ field: Field, _ op: Operator, _ value: PredicateValue) -> QueryBuilder

    /// Add GROUP BY clause
    func groupBy(_ period: GroupBy) -> QueryBuilder

    /// Add ORDER BY clause
    func orderBy(_ field: Field, _ direction: OrderDirection) -> QueryBuilder

    /// Set result limit
    func limit(_ count: Int) -> QueryBuilder

    /// Build without executing
    func buildQuery() -> HealthQuery

    /// Execute the query
    func execute() async throws -> QueryResult
}
```

### HealthQuery

Intermediate representation of a query.

```swift
public struct HealthQuery: Equatable, Sendable {
    let source: HealthSource
    let selections: [Selection]
    let predicates: [Predicate]
    let grouping: GroupBy?
    let having: [Predicate]?
    let ordering: [OrderBy]?
    let limit: Int?
}
```

### HealthSource

```swift
public enum HealthSource: Equatable, Sendable {
    case quantity(QuantityType)
    case category(CategoryType)
    case workout
    case sleepSession
}
```

### QueryResult

Result of query execution.

```swift
public struct QueryResult: Sendable {
    let rows: [ResultRow]
    let executionTime: TimeInterval
}
```

### ResultRow

Single row of query results.

```swift
public struct ResultRow: Sendable {
    let values: [String: ResultValue]

    /// Type-safe accessors
    func double(_ key: String) -> Double?
    func int(_ key: String) -> Int?
    func string(_ key: String) -> String?
    func date(_ key: String) -> Date?

    /// Subscript access
    subscript(key: String) -> ResultValue?
}
```

### ResultValue

```swift
public enum ResultValue: Sendable {
    case double(Double)
    case int(Int)
    case string(String)
    case date(Date)
    case null
}
```

---

## Enums

### QuantityType

```swift
public enum QuantityType: String, CaseIterable, Sendable {
    case steps, heartRate, activeCalories, restingCalories
    case distance, flightsClimbed, standTime, exerciseMinutes
    case bodyMass, height, bodyFatPercentage
    case heartRateVariability, oxygenSaturation, respiratoryRate
    case bodyTemperature, bloodPressureSystolic, bloodPressureDiastolic
    case bloodGlucose
}
```

### CategoryType

```swift
public enum CategoryType: String, CaseIterable, Sendable {
    case sleepAnalysis, appetiteChanges, headache, fatigue, menstrualFlow
}
```

### Aggregate

```swift
public enum Aggregate: Equatable, Sendable {
    case sum, avg, min, max, count
}
```

### GroupBy

```swift
public enum GroupBy: Equatable, Sendable {
    case hour, day, week, month, year
}
```

### Operator

```swift
public enum Operator: Equatable, Sendable {
    case equal, notEqual
    case greaterThan, greaterThanOrEqual
    case lessThan, lessThanOrEqual
    case between, isNull, isNotNull
}
```

### Field

```swift
public enum Field: Equatable, Sendable {
    case value, date, endDate, source, device
    case stage, severity  // Category fields
    case activityType, duration, totalCalories, distance  // Workout fields
    case inBedDuration, remDuration, coreDuration, deepDuration, awakeDuration  // Sleep
}
```

---

## Errors

### QueryError

```swift
public enum QueryError: Error, Equatable {
    case noSelections
    case groupByRequiresAggregate
    case healthKitNotAvailable
    case authorizationDenied
    case invalidQuery(String)
    case healthKitError(String)
}
```

### ParserError

```swift
public enum ParserError: Error {
    case unexpectedToken(expected: String, got: Token)
    case unexpectedEndOfInput
    case invalidExpression(String)
}
```

### CompilerError

```swift
public enum CompilerError: Error {
    case unknownTable(String)
    case unknownField(String)
    case invalidExpression(String)
    case unsupportedFeature(String)
}
```

### LexerError

```swift
public enum LexerError: Error {
    case unexpectedCharacter(Character, line: Int, column: Int)
    case unterminatedString(line: Int, column: Int)
}
```
