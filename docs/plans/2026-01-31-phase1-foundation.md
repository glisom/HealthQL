# HealthQL Phase 1: Foundation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the core HealthQL engine with IR, schema registry, basic DSL, and query execution for quantity types.

**Architecture:** Three-layer design - DSL builds queries, Core validates and executes them against HealthKit. The IR (Intermediate Representation) is the bridge that both the DSL and future string parser compile to.

**Tech Stack:** Swift 6.2, HealthKit framework, XCTest

---

## Task 1: Package Structure Setup

**Files:**
- Modify: `Package.swift`
- Create: `Sources/HealthQL/Core/IR.swift`
- Create: `Sources/HealthQL/Core/Schema.swift`
- Create: `Sources/HealthQL/DSL/Health.swift`
- Create: `Sources/HealthQL/DSL/QueryBuilder.swift`
- Create: `Sources/HealthQL/DSL/Predicates.swift`
- Create: `Sources/HealthQL/Results/QueryResult.swift`
- Create: `Sources/HealthQL/Executor/Executor.swift`

**Step 1: Update Package.swift for iOS/macOS and HealthKit**

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HealthQL",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HealthQL",
            targets: ["HealthQL"]
        ),
    ],
    targets: [
        .target(
            name: "HealthQL",
            linkerSettings: [
                .linkedFramework("HealthKit")
            ]
        ),
        .testTarget(
            name: "HealthQLTests",
            dependencies: ["HealthQL"]
        ),
    ]
)
```

**Step 2: Create directory structure**

Run:
```bash
mkdir -p Sources/HealthQL/Core
mkdir -p Sources/HealthQL/DSL
mkdir -p Sources/HealthQL/Results
mkdir -p Sources/HealthQL/Executor
```

**Step 3: Create placeholder files**

Create `Sources/HealthQL/Core/IR.swift`:
```swift
import Foundation

// MARK: - Intermediate Representation
// The IR is the common structure that both DSL and string parser compile to
```

Create `Sources/HealthQL/Core/Schema.swift`:
```swift
import Foundation
import HealthKit

// MARK: - Schema Registry
// Maps HealthKit types to queryable schema
```

Create `Sources/HealthQL/DSL/Health.swift`:
```swift
import Foundation

// MARK: - Health DSL Entry Point
```

Create `Sources/HealthQL/DSL/QueryBuilder.swift`:
```swift
import Foundation

// MARK: - Query Builder
```

Create `Sources/HealthQL/DSL/Predicates.swift`:
```swift
import Foundation

// MARK: - Predicates
```

Create `Sources/HealthQL/Results/QueryResult.swift`:
```swift
import Foundation

// MARK: - Query Results
```

Create `Sources/HealthQL/Executor/Executor.swift`:
```swift
import Foundation
import HealthKit

// MARK: - Query Executor
```

**Step 4: Remove default placeholder file**

Run:
```bash
rm Sources/HealthQL/HealthQL.swift
```

**Step 5: Verify build**

Run: `swift build`
Expected: Build Succeeded

**Step 6: Commit**

```bash
git add -A
git commit -m "chore: set up package structure for HealthQL

- Configure platforms (iOS 15+, macOS 13+)
- Link HealthKit framework
- Create Core, DSL, Results, Executor directories"
```

---

## Task 2: Schema Registry - Quantity Types

**Files:**
- Modify: `Sources/HealthQL/Core/Schema.swift`
- Create: `Tests/HealthQLTests/SchemaTests.swift`

**Step 1: Write failing test for QuantityType enum**

Create `Tests/HealthQLTests/SchemaTests.swift`:
```swift
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
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter SchemaTests`
Expected: FAIL - "cannot find 'QuantityType' in scope"

**Step 3: Implement QuantityType enum**

Replace `Sources/HealthQL/Core/Schema.swift`:
```swift
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
        }
    }

    /// Look up a quantity type by display name
    public static func from(displayName: String) -> QuantityType? {
        allCases.first { $0.displayName == displayName }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter SchemaTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add QuantityType schema registry

- Map 18 common quantity types to HKQuantityTypeIdentifier
- Provide display names, default units, and HKQuantityType accessors
- Support lookup by display name for future parser"
```

---

## Task 3: Intermediate Representation (IR)

**Files:**
- Modify: `Sources/HealthQL/Core/IR.swift`
- Create: `Tests/HealthQLTests/IRTests.swift`

**Step 1: Write failing test for IR structures**

Create `Tests/HealthQLTests/IRTests.swift`:
```swift
import Testing
@testable import HealthQL
import Foundation

@Suite("Intermediate Representation Tests")
struct IRTests {

    @Test("HealthQuery can be constructed with source and selections")
    func basicQueryConstruction() {
        let query = HealthQuery(
            source: .quantity(.steps),
            selections: [.aggregate(.sum, .value)]
        )

        #expect(query.source == .quantity(.steps))
        #expect(query.selections.count == 1)
    }

    @Test("Predicate can express date comparisons")
    func datePredicates() {
        let predicate = Predicate(
            field: .date,
            op: .greaterThan,
            value: .date(Date.distantPast)
        )

        #expect(predicate.field == .date)
        #expect(predicate.op == .greaterThan)
    }

    @Test("GroupBy supports time periods")
    func groupByPeriods() {
        let groupBy = GroupBy.day
        #expect(groupBy == .day)

        let weekGroup = GroupBy.week
        #expect(weekGroup == .week)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter IRTests`
Expected: FAIL - "cannot find 'HealthQuery' in scope"

**Step 3: Implement IR structures**

Replace `Sources/HealthQL/Core/IR.swift`:
```swift
import Foundation

/// The source of data for a query
public enum HealthSource: Equatable, Sendable {
    case quantity(QuantityType)
    // Future: case category(CategoryType)
    // Future: case workout
    // Future: case clinicalRecord(ClinicalType)
}

/// Fields that can be selected or used in predicates
public enum Field: Equatable, Sendable {
    case value      // The numeric value of a quantity sample
    case date       // The start date of the sample
    case endDate    // The end date of the sample
    case source     // The source (app/device) of the sample
    case device     // The device that recorded the sample
}

/// Aggregation functions
public enum Aggregate: Equatable, Sendable {
    case sum
    case avg
    case min
    case max
    case count
    // Future: case p50, p90, p95, p99
    // Future: case stddev, variance
}

/// What to select from the query
public enum Selection: Equatable, Sendable {
    case field(Field)
    case aggregate(Aggregate, Field)
}

/// Comparison operators for predicates
public enum Operator: Equatable, Sendable {
    case equal
    case notEqual
    case greaterThan
    case greaterThanOrEqual
    case lessThan
    case lessThanOrEqual
    case between
    case isNull
    case isNotNull
}

/// Values that can be used in predicates
public enum PredicateValue: Equatable, Sendable {
    case date(Date)
    case double(Double)
    case int(Int)
    case string(String)
    case dateRange(start: Date, end: Date)
    case null
}

/// A condition for filtering results
public struct Predicate: Equatable, Sendable {
    public let field: Field
    public let op: Operator
    public let value: PredicateValue

    public init(field: Field, op: Operator, value: PredicateValue) {
        self.field = field
        self.op = op
        self.value = value
    }
}

/// Time period for grouping results
public enum GroupBy: Equatable, Sendable {
    case hour
    case day
    case week
    case month
    case year
}

/// Ordering direction
public enum OrderDirection: Sendable {
    case ascending
    case descending
}

/// Ordering specification
public struct OrderBy: Sendable {
    public let field: Field
    public let direction: OrderDirection

    public init(field: Field, direction: OrderDirection = .ascending) {
        self.field = field
        self.direction = direction
    }
}

/// The intermediate representation of a HealthQL query
/// Both the DSL and string parser compile to this structure
public struct HealthQuery: Sendable {
    public let source: HealthSource
    public let selections: [Selection]
    public let predicates: [Predicate]
    public let grouping: GroupBy?
    public let having: [Predicate]?
    public let ordering: [OrderBy]?
    public let limit: Int?

    public init(
        source: HealthSource,
        selections: [Selection],
        predicates: [Predicate] = [],
        grouping: GroupBy? = nil,
        having: [Predicate]? = nil,
        ordering: [OrderBy]? = nil,
        limit: Int? = nil
    ) {
        self.source = source
        self.selections = selections
        self.predicates = predicates
        self.grouping = grouping
        self.having = having
        self.ordering = ordering
        self.limit = limit
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter IRTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Intermediate Representation (IR) for queries

- HealthQuery struct as the core IR
- HealthSource enum (quantity types for now)
- Field, Aggregate, Selection enums
- Predicate with operators and values
- GroupBy time periods
- OrderBy with direction"
```

---

## Task 4: Query Results

**Files:**
- Modify: `Sources/HealthQL/Results/QueryResult.swift`
- Create: `Tests/HealthQLTests/ResultTests.swift`

**Step 1: Write failing test for QueryResult**

Create `Tests/HealthQLTests/ResultTests.swift`:
```swift
import Testing
@testable import HealthQL
import Foundation

@Suite("Query Result Tests")
struct ResultTests {

    @Test("QueryResult holds rows with values")
    func basicResult() {
        let row = ResultRow(values: [
            "date": .date(Date()),
            "sum": .double(10000)
        ])

        let result = QueryResult(rows: [row], executionTime: 0.023)

        #expect(result.rows.count == 1)
        #expect(result.executionTime == 0.023)
    }

    @Test("ResultRow provides typed accessors")
    func typedAccessors() {
        let date = Date()
        let row = ResultRow(values: [
            "date": .date(date),
            "sum": .double(10000),
            "count": .int(7)
        ])

        #expect(row.date("date") == date)
        #expect(row.double("sum") == 10000)
        #expect(row.int("count") == 7)
    }

    @Test("ResultRow returns nil for missing keys")
    func missingKeys() {
        let row = ResultRow(values: [:])

        #expect(row.double("missing") == nil)
        #expect(row.date("missing") == nil)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ResultTests`
Expected: FAIL - "cannot find 'ResultRow' in scope"

**Step 3: Implement QueryResult and ResultRow**

Replace `Sources/HealthQL/Results/QueryResult.swift`:
```swift
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ResultTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add QueryResult and ResultRow types

- ResultValue enum for typed values
- ResultRow with typed accessors (double, int, string, date)
- QueryResult with rows and execution time
- Sequence conformance for iteration"
```

---

## Task 5: DSL Query Builder

**Files:**
- Modify: `Sources/HealthQL/DSL/Health.swift`
- Modify: `Sources/HealthQL/DSL/QueryBuilder.swift`
- Modify: `Sources/HealthQL/DSL/Predicates.swift`
- Create: `Tests/HealthQLTests/DSLTests.swift`

**Step 1: Write failing test for DSL**

Create `Tests/HealthQLTests/DSLTests.swift`:
```swift
import Testing
@testable import HealthQL
import Foundation

@Suite("DSL Tests")
struct DSLTests {

    @Test("Health.select creates a query builder")
    func selectCreatesBuilder() {
        let builder = Health.select(.steps)
        let query = builder.buildQuery()

        #expect(query.source == .quantity(.steps))
    }

    @Test("Aggregate selection is captured")
    func aggregateSelection() {
        let builder = Health.select(.steps, aggregate: .sum)
        let query = builder.buildQuery()

        #expect(query.selections.count == 1)
        #expect(query.selections[0] == .aggregate(.sum, .value))
    }

    @Test("Multiple aggregates can be selected")
    func multipleAggregates() {
        let builder = Health.select(.heartRate, aggregates: [.avg, .min, .max])
        let query = builder.buildQuery()

        #expect(query.selections.count == 3)
    }

    @Test("Where clause adds predicates")
    func whereClause() {
        let date = Date()
        let builder = Health.select(.steps)
            .where(.date, .greaterThan, .date(date))
        let query = builder.buildQuery()

        #expect(query.predicates.count == 1)
        #expect(query.predicates[0].field == .date)
        #expect(query.predicates[0].op == .greaterThan)
    }

    @Test("GroupBy is captured")
    func groupBy() {
        let builder = Health.select(.steps, aggregate: .sum)
            .groupBy(.day)
        let query = builder.buildQuery()

        #expect(query.grouping == .day)
    }

    @Test("Limit is captured")
    func limit() {
        let builder = Health.select(.steps)
            .limit(10)
        let query = builder.buildQuery()

        #expect(query.limit == 10)
    }

    @Test("Full query chain works")
    func fullQueryChain() {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        let builder = Health.select(.steps, aggregate: .sum)
            .where(.date, .greaterThan, .date(sevenDaysAgo))
            .groupBy(.day)
            .orderBy(.date, .descending)
            .limit(7)

        let query = builder.buildQuery()

        #expect(query.source == .quantity(.steps))
        #expect(query.selections.count == 1)
        #expect(query.predicates.count == 1)
        #expect(query.grouping == .day)
        #expect(query.ordering?.count == 1)
        #expect(query.limit == 7)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter DSLTests`
Expected: FAIL - "cannot find 'Health' in scope"

**Step 3: Implement Health entry point**

Replace `Sources/HealthQL/DSL/Health.swift`:
```swift
import Foundation

/// Entry point for the HealthQL DSL
public enum Health {

    /// Select all fields from a quantity type
    public static func select(_ type: QuantityType) -> QueryBuilder {
        QueryBuilder(source: .quantity(type), selections: [.field(.value)])
    }

    /// Select with a single aggregate
    public static func select(_ type: QuantityType, aggregate: Aggregate) -> QueryBuilder {
        QueryBuilder(source: .quantity(type), selections: [.aggregate(aggregate, .value)])
    }

    /// Select with multiple aggregates
    public static func select(_ type: QuantityType, aggregates: [Aggregate]) -> QueryBuilder {
        let selections = aggregates.map { Selection.aggregate($0, .value) }
        return QueryBuilder(source: .quantity(type), selections: selections)
    }
}
```

**Step 4: Implement QueryBuilder**

Replace `Sources/HealthQL/DSL/QueryBuilder.swift`:
```swift
import Foundation

/// Fluent builder for constructing HealthQL queries
public struct QueryBuilder: Sendable {
    private let source: HealthSource
    private let selections: [Selection]
    private var predicates: [Predicate] = []
    private var grouping: GroupBy? = nil
    private var ordering: [OrderBy]? = nil
    private var queryLimit: Int? = nil

    internal init(source: HealthSource, selections: [Selection]) {
        self.source = source
        self.selections = selections
    }

    /// Add a WHERE predicate
    public func `where`(_ field: Field, _ op: Operator, _ value: PredicateValue) -> QueryBuilder {
        var copy = self
        copy.predicates.append(Predicate(field: field, op: op, value: value))
        return copy
    }

    /// Group results by time period
    public func groupBy(_ period: GroupBy) -> QueryBuilder {
        var copy = self
        copy.grouping = period
        return copy
    }

    /// Order results by field
    public func orderBy(_ field: Field, _ direction: OrderDirection = .ascending) -> QueryBuilder {
        var copy = self
        if copy.ordering == nil {
            copy.ordering = []
        }
        copy.ordering?.append(OrderBy(field: field, direction: direction))
        return copy
    }

    /// Limit the number of results
    public func limit(_ count: Int) -> QueryBuilder {
        var copy = self
        copy.queryLimit = count
        return copy
    }

    /// Build the intermediate representation
    public func buildQuery() -> HealthQuery {
        HealthQuery(
            source: source,
            selections: selections,
            predicates: predicates,
            grouping: grouping,
            having: nil,
            ordering: ordering,
            limit: queryLimit
        )
    }
}
```

**Step 5: Run test to verify it passes**

Run: `swift test --filter DSLTests`
Expected: All tests pass

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: add DSL with Health entry point and QueryBuilder

- Health.select() for starting queries
- Support for single and multiple aggregates
- Fluent .where(), .groupBy(), .orderBy(), .limit()
- buildQuery() returns IR HealthQuery"
```

---

## Task 6: Date Convenience Extensions

**Files:**
- Modify: `Sources/HealthQL/DSL/Predicates.swift`
- Add tests to: `Tests/HealthQLTests/DSLTests.swift`

**Step 1: Write failing test for date conveniences**

Add to `Tests/HealthQLTests/DSLTests.swift`:
```swift
@Suite("Date Convenience Tests")
struct DateConvenienceTests {

    @Test("DateReference.daysAgo calculates correctly")
    func daysAgo() {
        let reference = DateReference.daysAgo(7)
        let expected = Calendar.current.date(byAdding: .day, value: -7, to: Calendar.current.startOfDay(for: Date()))!
        let referenceDate = reference.date

        // Compare to start of expected day
        let referenceDay = Calendar.current.startOfDay(for: referenceDate)
        #expect(referenceDay == expected)
    }

    @Test("DateReference.startOfMonth is first day of month")
    func startOfMonth() {
        let reference = DateReference.startOfMonth
        let date = reference.date

        let components = Calendar.current.dateComponents([.day], from: date)
        #expect(components.day == 1)
    }

    @Test("DateReference.today is start of today")
    func today() {
        let reference = DateReference.today
        let expected = Calendar.current.startOfDay(for: Date())

        #expect(reference.date == expected)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter DateConvenienceTests`
Expected: FAIL - "cannot find 'DateReference' in scope"

**Step 3: Implement DateReference**

Replace `Sources/HealthQL/DSL/Predicates.swift`:
```swift
import Foundation

/// Convenience type for expressing dates in queries
public enum DateReference: Sendable {
    case today
    case startOfWeek
    case startOfMonth
    case startOfYear
    case daysAgo(Int)
    case weeksAgo(Int)
    case monthsAgo(Int)
    case exact(Date)

    /// Resolve to an actual Date
    public var date: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            return calendar.startOfDay(for: now)

        case .startOfWeek:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            return calendar.date(from: components) ?? now

        case .startOfMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            return calendar.date(from: components) ?? now

        case .startOfYear:
            let components = calendar.dateComponents([.year], from: now)
            return calendar.date(from: components) ?? now

        case .daysAgo(let days):
            let startOfToday = calendar.startOfDay(for: now)
            return calendar.date(byAdding: .day, value: -days, to: startOfToday) ?? now

        case .weeksAgo(let weeks):
            let startOfToday = calendar.startOfDay(for: now)
            return calendar.date(byAdding: .weekOfYear, value: -weeks, to: startOfToday) ?? now

        case .monthsAgo(let months):
            let startOfToday = calendar.startOfDay(for: now)
            return calendar.date(byAdding: .month, value: -months, to: startOfToday) ?? now

        case .exact(let date):
            return date
        }
    }
}

// MARK: - PredicateValue convenience initializer

extension PredicateValue {
    /// Create a date predicate value from a DateReference
    public static func date(_ reference: DateReference) -> PredicateValue {
        .date(reference.date)
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter DateConvenienceTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add DateReference for convenient date predicates

- today, startOfWeek, startOfMonth, startOfYear
- daysAgo, weeksAgo, monthsAgo relative dates
- PredicateValue.date() accepts DateReference"
```

---

## Task 7: Query Executor (Mock Implementation)

**Files:**
- Modify: `Sources/HealthQL/Executor/Executor.swift`
- Create: `Tests/HealthQLTests/ExecutorTests.swift`

**Step 1: Write failing test for executor**

Create `Tests/HealthQLTests/ExecutorTests.swift`:
```swift
import Testing
@testable import HealthQL
import Foundation

@Suite("Executor Tests")
struct ExecutorTests {

    @Test("Executor validates query has selections")
    func validatesSelections() async throws {
        let query = HealthQuery(
            source: .quantity(.steps),
            selections: []  // Empty selections - invalid
        )

        let executor = HealthQueryExecutor()

        await #expect(throws: QueryError.noSelections) {
            try await executor.execute(query)
        }
    }

    @Test("Executor validates groupBy requires aggregate")
    func validatesGroupByNeedsAggregate() async throws {
        let query = HealthQuery(
            source: .quantity(.steps),
            selections: [.field(.value)],  // Raw field, not aggregate
            grouping: .day  // But we have groupBy
        )

        let executor = HealthQueryExecutor()

        await #expect(throws: QueryError.groupByRequiresAggregate) {
            try await executor.execute(query)
        }
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ExecutorTests`
Expected: FAIL - "cannot find 'HealthQueryExecutor' in scope"

**Step 3: Implement executor with validation**

Replace `Sources/HealthQL/Executor/Executor.swift`:
```swift
import Foundation
import HealthKit

/// Errors that can occur during query execution
public enum QueryError: Error, Equatable {
    case noSelections
    case groupByRequiresAggregate
    case healthKitNotAvailable
    case authorizationDenied
    case invalidQuery(String)
}

/// Executes HealthQL queries against HealthKit
public final class HealthQueryExecutor: Sendable {
    private let healthStore: HKHealthStore?

    public init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        } else {
            self.healthStore = nil
        }
    }

    /// Execute a query and return results
    public func execute(_ query: HealthQuery) async throws -> QueryResult {
        // Validate query
        try validate(query)

        // For now, return empty result
        // Real implementation will query HealthKit
        let startTime = Date()

        // TODO: Implement actual HealthKit query execution

        let executionTime = Date().timeIntervalSince(startTime)
        return QueryResult(rows: [], executionTime: executionTime)
    }

    /// Validate a query before execution
    private func validate(_ query: HealthQuery) throws {
        // Must have at least one selection
        if query.selections.isEmpty {
            throw QueryError.noSelections
        }

        // If grouping, must have aggregate selections
        if query.grouping != nil {
            let hasAggregate = query.selections.contains { selection in
                if case .aggregate = selection {
                    return true
                }
                return false
            }
            if !hasAggregate {
                throw QueryError.groupByRequiresAggregate
            }
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ExecutorTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add HealthQueryExecutor with validation

- QueryError enum for execution errors
- Validation for empty selections
- Validation for groupBy requiring aggregates
- Placeholder for actual HealthKit execution"
```

---

## Task 8: DSL Execute Method

**Files:**
- Modify: `Sources/HealthQL/DSL/QueryBuilder.swift`
- Add tests to: `Tests/HealthQLTests/DSLTests.swift`

**Step 1: Write failing test for execute**

Add to `Tests/HealthQLTests/DSLTests.swift`:
```swift
@Suite("DSL Execute Tests")
struct DSLExecuteTests {

    @Test("QueryBuilder.execute returns QueryResult")
    func executeReturnsResult() async throws {
        let result = try await Health.select(.steps, aggregate: .sum)
            .where(.date, .greaterThan, .date(.daysAgo(7)))
            .groupBy(.day)
            .execute()

        // Result may be empty (no HealthKit data in test), but should not throw
        #expect(result.executionTime >= 0)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter DSLExecuteTests`
Expected: FAIL - "Value of type 'QueryBuilder' has no member 'execute'"

**Step 3: Add execute method to QueryBuilder**

Add to `Sources/HealthQL/DSL/QueryBuilder.swift` at the end of the struct:
```swift
    /// Execute the query and return results
    public func execute() async throws -> QueryResult {
        let query = buildQuery()
        let executor = HealthQueryExecutor()
        return try await executor.execute(query)
    }
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter DSLExecuteTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add execute() method to QueryBuilder

- Builds IR query and executes via HealthQueryExecutor
- Returns QueryResult with rows and timing"
```

---

## Task 9: Run Full Test Suite

**Step 1: Run all tests**

Run: `swift test`
Expected: All tests pass

**Step 2: Verify build for iOS**

Run: `swift build`
Expected: Build Succeeded

**Step 3: Final commit if needed**

```bash
git status
# If clean, no commit needed
```

---

## Task 10: Update Default Test File

**Files:**
- Remove: `Tests/HealthQLTests/HealthQLTests.swift`

**Step 1: Remove default test file**

Run:
```bash
rm Tests/HealthQLTests/HealthQLTests.swift
```

**Step 2: Run tests to verify nothing broke**

Run: `swift test`
Expected: All tests pass

**Step 3: Commit**

```bash
git add -A
git commit -m "chore: remove default placeholder test file"
```

---

## Phase 1 Complete

At the end of Phase 1, you have:

- **Schema Registry** with 18 quantity types mapped to HealthKit identifiers
- **Intermediate Representation** that captures queries in a structured format
- **Query Results** with typed value accessors
- **DSL** with fluent `.select()`, `.where()`, `.groupBy()`, `.orderBy()`, `.limit()`, `.execute()`
- **Date conveniences** like `.daysAgo(7)`, `.startOfMonth`
- **Query validation** before execution

The executor returns empty results for now - Phase 2 will implement actual HealthKit query translation.

**Next:** Phase 2 adds the string parser (lexer, grammar, parser) for SQL-like query syntax.
