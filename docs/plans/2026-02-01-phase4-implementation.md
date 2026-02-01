# Phase 4: Category Types & Workouts Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add support for HealthKit category types (sleep, symptoms) and workouts to HealthQL queries.

**Architecture:** Extend the existing `HealthSource` enum to include category and workout variants. The compiler resolves table names to the appropriate source type. The executor dispatches to type-specific query handlers. Sleep sessions are aggregated from raw sleep analysis samples.

**Tech Stack:** Swift 6.2, HealthKit, Swift Testing

---

## Task 1: CategoryType Enum

**Files:**
- Create: `Sources/HealthQL/Core/CategoryType.swift`
- Test: `Tests/HealthQLTests/CategoryTypeTests.swift`

**Step 1: Write failing tests**

Create `Tests/HealthQLTests/CategoryTypeTests.swift`:
```swift
import Testing
import HealthKit
@testable import HealthQL

@Suite("CategoryType Tests")
struct CategoryTypeTests {

    @Test("CategoryType maps to correct HKCategoryTypeIdentifier")
    func categoryTypeIdentifiers() {
        #expect(CategoryType.sleepAnalysis.identifier == .sleepAnalysis)
        #expect(CategoryType.appetiteChanges.identifier == .appetiteChanges)
        #expect(CategoryType.headache.identifier == .headache)
    }

    @Test("CategoryType provides correct display names")
    func displayNames() {
        #expect(CategoryType.sleepAnalysis.displayName == "sleep_analysis")
        #expect(CategoryType.headache.displayName == "headache")
        #expect(CategoryType.menstrualFlow.displayName == "menstrual_flow")
    }

    @Test("CategoryType.from finds by display name")
    func fromDisplayName() {
        #expect(CategoryType.from(displayName: "sleep_analysis") == .sleepAnalysis)
        #expect(CategoryType.from(displayName: "headache") == .headache)
        #expect(CategoryType.from(displayName: "invalid") == nil)
    }

    @Test("CategoryType provides available fields")
    func availableFields() {
        let fields = CategoryType.sleepAnalysis.availableFields
        #expect(fields.contains("value"))
        #expect(fields.contains("date"))
        #expect(fields.contains("end_date"))
    }

    @Test("SleepStage enum has correct values")
    func sleepStages() {
        #expect(SleepStage.inBed.rawValue == 0)
        #expect(SleepStage.asleepUnspecified.rawValue == 1)
        #expect(SleepStage.awake.rawValue == 2)
        #expect(SleepStage.asleepCore.rawValue == 3)
        #expect(SleepStage.asleepDeep.rawValue == 4)
        #expect(SleepStage.asleepREM.rawValue == 5)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter CategoryTypeTests`
Expected: FAIL - "No such module 'HealthQL'" or "cannot find 'CategoryType'"

**Step 3: Implement CategoryType**

Create `Sources/HealthQL/Core/CategoryType.swift`:
```swift
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter CategoryTypeTests`
Expected: All 5 tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(core): add CategoryType for sleep and symptoms

- SleepStage enum with HK value mappings
- Severity enum for symptom types
- CategoryType with 5 category types
- Display names and field lists"
```

---

## Task 2: WorkoutType Enum

**Files:**
- Create: `Sources/HealthQL/Core/WorkoutType.swift`
- Test: `Tests/HealthQLTests/WorkoutTypeTests.swift`

**Step 1: Write failing tests**

Create `Tests/HealthQLTests/WorkoutTypeTests.swift`:
```swift
import Testing
import HealthKit
@testable import HealthQL

@Suite("WorkoutType Tests")
struct WorkoutTypeTests {

    @Test("WorkoutType maps to correct HKWorkoutActivityType")
    func workoutActivityTypes() {
        #expect(WorkoutType.running.activityType == .running)
        #expect(WorkoutType.cycling.activityType == .cycling)
        #expect(WorkoutType.swimming.activityType == .swimming)
        #expect(WorkoutType.yoga.activityType == .yoga)
    }

    @Test("WorkoutType provides correct display names")
    func displayNames() {
        #expect(WorkoutType.running.displayName == "running")
        #expect(WorkoutType.strengthTraining.displayName == "strength_training")
        #expect(WorkoutType.hiking.displayName == "hiking")
    }

    @Test("WorkoutType.from finds by display name")
    func fromDisplayName() {
        #expect(WorkoutType.from(displayName: "running") == .running)
        #expect(WorkoutType.from(displayName: "strength_training") == .strengthTraining)
        #expect(WorkoutType.from(displayName: "invalid") == nil)
    }

    @Test("WorkoutType provides available fields")
    func availableFields() {
        let fields = WorkoutType.running.availableFields
        #expect(fields.contains("activity_type"))
        #expect(fields.contains("duration"))
        #expect(fields.contains("total_calories"))
        #expect(fields.contains("distance"))
    }

    @Test("Workouts table name is correct")
    func workoutsTableName() {
        #expect(WorkoutType.tableName == "workouts")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter WorkoutTypeTests`
Expected: FAIL - "cannot find 'WorkoutType'"

**Step 3: Implement WorkoutType**

Create `Sources/HealthQL/Core/WorkoutType.swift`:
```swift
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter WorkoutTypeTests`
Expected: All 5 tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(core): add WorkoutType for exercise queries

- Maps to HKWorkoutActivityType
- 12 common workout types
- Field list for workout queries"
```

---

## Task 3: Update IR HealthSource

**Files:**
- Modify: `Sources/HealthQL/Core/IR.swift`
- Test: `Tests/HealthQLTests/IRTests.swift`

**Step 1: Write failing tests**

Add to `Tests/HealthQLTests/IRTests.swift`:
```swift
@Test("HealthSource supports category type")
func healthSourceCategory() {
    let source = HealthSource.category(.sleepAnalysis)
    if case .category(let type) = source {
        #expect(type == .sleepAnalysis)
    } else {
        Issue.record("Expected category source")
    }
}

@Test("HealthSource supports workout")
func healthSourceWorkout() {
    let source = HealthSource.workout
    if case .workout = source {
        // Pass
    } else {
        Issue.record("Expected workout source")
    }
}

@Test("HealthSource supports sleep session")
func healthSourceSleepSession() {
    let source = HealthSource.sleepSession
    if case .sleepSession = source {
        // Pass
    } else {
        Issue.record("Expected sleepSession source")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter IRTests`
Expected: FAIL - "type 'HealthSource' has no member 'category'"

**Step 3: Update HealthSource enum**

In `Sources/HealthQL/Core/IR.swift`, update `HealthSource`:
```swift
/// The source of data for a query
public enum HealthSource: Equatable, Sendable {
    case quantity(QuantityType)
    case category(CategoryType)
    case workout
    case sleepSession
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter IRTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(ir): extend HealthSource with category, workout, sleepSession

- category(CategoryType) for symptom/sleep samples
- workout for HKWorkout queries
- sleepSession for aggregated sleep data"
```

---

## Task 4: Update Compiler for New Sources

**Files:**
- Modify: `Sources/HealthQLParser/Compiler.swift`
- Test: `Tests/HealthQLParserTests/CompilerTests.swift`

**Step 1: Write failing tests**

Add to `Tests/HealthQLParserTests/CompilerTests.swift`:
```swift
@Test("Compiler resolves sleep_analysis to category source")
func compileSleepAnalysis() throws {
    let stmt = SelectStatement(
        selections: [.star],
        from: "sleep_analysis",
        whereClause: nil,
        groupBy: nil,
        orderBy: nil,
        limit: nil
    )
    let compiler = Compiler()
    let query = try compiler.compile(stmt)

    if case .category(let type) = query.source {
        #expect(type == .sleepAnalysis)
    } else {
        Issue.record("Expected category source")
    }
}

@Test("Compiler resolves workouts to workout source")
func compileWorkouts() throws {
    let stmt = SelectStatement(
        selections: [.star],
        from: "workouts",
        whereClause: nil,
        groupBy: nil,
        orderBy: nil,
        limit: nil
    )
    let compiler = Compiler()
    let query = try compiler.compile(stmt)

    if case .workout = query.source {
        // Pass
    } else {
        Issue.record("Expected workout source")
    }
}

@Test("Compiler resolves sleep to sleepSession source")
func compileSleepSession() throws {
    let stmt = SelectStatement(
        selections: [.star],
        from: "sleep",
        whereClause: nil,
        groupBy: nil,
        orderBy: nil,
        limit: nil
    )
    let compiler = Compiler()
    let query = try compiler.compile(stmt)

    if case .sleepSession = query.source {
        // Pass
    } else {
        Issue.record("Expected sleepSession source")
    }
}

@Test("Compiler resolves headache to category source")
func compileHeadache() throws {
    let stmt = SelectStatement(
        selections: [.star],
        from: "headache",
        whereClause: nil,
        groupBy: nil,
        orderBy: nil,
        limit: nil
    )
    let compiler = Compiler()
    let query = try compiler.compile(stmt)

    if case .category(let type) = query.source {
        #expect(type == .headache)
    } else {
        Issue.record("Expected category source")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter CompilerTests`
Expected: FAIL - "unknownTable" error

**Step 3: Update resolveSource in Compiler**

In `Sources/HealthQLParser/Compiler.swift`, update `resolveSource`:
```swift
private func resolveSource(_ tableName: String) throws -> HealthSource {
    // Special case: "workouts" table
    if tableName == WorkoutType.tableName {
        return .workout
    }

    // Special case: "sleep" for aggregated sleep sessions
    if tableName == "sleep" {
        return .sleepSession
    }

    // Try to find matching QuantityType by display name
    if let quantityType = QuantityType.from(displayName: tableName) {
        return .quantity(quantityType)
    }

    // Try to find matching CategoryType by display name
    if let categoryType = CategoryType.from(displayName: tableName) {
        return .category(categoryType)
    }

    // Try camelCase conversion for QuantityType
    let camelCase = tableName
        .split(separator: "_")
        .enumerated()
        .map { $0.offset == 0 ? String($0.element) : String($0.element).capitalized }
        .joined()

    if let quantityType = QuantityType(rawValue: camelCase) {
        return .quantity(quantityType)
    }

    throw CompilerError.unknownTable(tableName)
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter CompilerTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(compiler): resolve category, workout, and sleep table names

- 'workouts' -> .workout
- 'sleep' -> .sleepSession
- Category display names -> .category(type)"
```

---

## Task 5: Add CategoryValue to IR

**Files:**
- Modify: `Sources/HealthQL/Core/IR.swift`
- Test: `Tests/HealthQLTests/IRTests.swift`

**Step 1: Write failing tests**

Add to `Tests/HealthQLTests/IRTests.swift`:
```swift
@Test("PredicateValue supports categoryValue")
func predicateCategoryValue() {
    let value = PredicateValue.categoryValue(3)
    if case .categoryValue(let v) = value {
        #expect(v == 3)
    } else {
        Issue.record("Expected categoryValue")
    }
}

@Test("Field has stage for category queries")
func fieldStage() {
    let field = Field.stage
    #expect(field == .stage)
}

@Test("Field has activityType for workout queries")
func fieldActivityType() {
    let field = Field.activityType
    #expect(field == .activityType)
}

@Test("Field has duration")
func fieldDuration() {
    let field = Field.duration
    #expect(field == .duration)
}

@Test("Field has totalCalories")
func fieldTotalCalories() {
    let field = Field.totalCalories
    #expect(field == .totalCalories)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter IRTests`
Expected: FAIL - "type 'PredicateValue' has no member 'categoryValue'"

**Step 3: Update IR with new fields and values**

In `Sources/HealthQL/Core/IR.swift`, update `Field` and `PredicateValue`:
```swift
/// Fields that can be selected or used in predicates
public enum Field: Equatable, Sendable {
    case value          // The numeric value of a quantity sample
    case date           // The start date of the sample
    case endDate        // The end date of the sample
    case source         // The source (app/device) of the sample
    case device         // The device that recorded the sample
    // Category fields
    case stage          // Sleep stage (for sleep_analysis)
    case severity       // Severity level (for symptoms)
    // Workout fields
    case activityType   // Workout activity type
    case duration       // Duration in seconds
    case totalCalories  // Total energy burned
    case distance       // Distance in meters
}

/// Values that can be used in predicates
public enum PredicateValue: Equatable, Sendable {
    case date(Date)
    case double(Double)
    case int(Int)
    case string(String)
    case dateRange(start: Date, end: Date)
    case null
    case categoryValue(Int)  // For category sample values (sleep stage, severity)
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter IRTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(ir): add category and workout fields to IR

- Field: stage, severity, activityType, duration, totalCalories, distance
- PredicateValue: categoryValue for HK category sample values"
```

---

## Task 6: Update Compiler Field Resolution

**Files:**
- Modify: `Sources/HealthQLParser/Compiler.swift`
- Test: `Tests/HealthQLParserTests/CompilerTests.swift`

**Step 1: Write failing tests**

Add to `Tests/HealthQLParserTests/CompilerTests.swift`:
```swift
@Test("Compiler resolves duration field")
func compileDurationField() throws {
    let stmt = SelectStatement(
        selections: [.identifier("duration")],
        from: "workouts",
        whereClause: nil,
        groupBy: nil,
        orderBy: nil,
        limit: nil
    )
    let compiler = Compiler()
    let query = try compiler.compile(stmt)

    if case .field(let field) = query.selections[0] {
        #expect(field == .duration)
    } else {
        Issue.record("Expected field selection")
    }
}

@Test("Compiler resolves activity_type field")
func compileActivityTypeField() throws {
    let stmt = SelectStatement(
        selections: [.identifier("activity_type")],
        from: "workouts",
        whereClause: nil,
        groupBy: nil,
        orderBy: nil,
        limit: nil
    )
    let compiler = Compiler()
    let query = try compiler.compile(stmt)

    if case .field(let field) = query.selections[0] {
        #expect(field == .activityType)
    } else {
        Issue.record("Expected field selection")
    }
}

@Test("Compiler resolves total_calories field")
func compileTotalCaloriesField() throws {
    let stmt = SelectStatement(
        selections: [.identifier("total_calories")],
        from: "workouts",
        whereClause: nil,
        groupBy: nil,
        orderBy: nil,
        limit: nil
    )
    let compiler = Compiler()
    let query = try compiler.compile(stmt)

    if case .field(let field) = query.selections[0] {
        #expect(field == .totalCalories)
    } else {
        Issue.record("Expected field selection")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter CompilerTests`
Expected: FAIL - "unknownField" error

**Step 3: Update resolveField in Compiler**

In `Sources/HealthQLParser/Compiler.swift`, update `resolveField`:
```swift
private func resolveField(_ name: String) throws -> Field {
    switch name.lowercased() {
    case "value", "count": return .value
    case "date", "start_date": return .date
    case "end_date": return .endDate
    case "source": return .source
    case "device": return .device
    // Category fields
    case "stage": return .stage
    case "severity": return .severity
    // Workout fields
    case "activity_type": return .activityType
    case "duration": return .duration
    case "total_calories": return .totalCalories
    case "distance": return .distance
    default:
        throw CompilerError.unknownField(name)
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter CompilerTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(compiler): resolve category and workout field names

- stage, severity for categories
- activity_type, duration, total_calories, distance for workouts"
```

---

## Task 7: Update SchemaInfo

**Files:**
- Modify: `Sources/HealthQLPlayground/SchemaInfo.swift`
- Test: `Tests/HealthQLPlaygroundTests/SchemaInfoTests.swift`

**Step 1: Write failing tests**

Add to `Tests/HealthQLPlaygroundTests/SchemaInfoTests.swift`:
```swift
@Test("Lists category types")
func categoryTypes() {
    let info = SchemaInfo()
    let types = info.allTypes()

    #expect(types.contains("sleep_analysis"))
    #expect(types.contains("headache"))
    #expect(types.contains("fatigue"))
}

@Test("Lists workout table")
func workoutTable() {
    let info = SchemaInfo()
    let types = info.allTypes()

    #expect(types.contains("workouts"))
    #expect(types.contains("sleep"))
}

@Test("Returns schema for sleep_analysis")
func sleepAnalysisSchema() {
    let info = SchemaInfo()
    let schema = info.schema(for: "sleep_analysis")

    #expect(schema != nil)
    #expect(schema!.fields.contains("stage"))
    #expect(schema!.fields.contains("duration"))
}

@Test("Returns schema for workouts")
func workoutsSchema() {
    let info = SchemaInfo()
    let schema = info.schema(for: "workouts")

    #expect(schema != nil)
    #expect(schema!.fields.contains("activity_type"))
    #expect(schema!.fields.contains("duration"))
    #expect(schema!.fields.contains("total_calories"))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter SchemaInfoTests`
Expected: FAIL - types not found

**Step 3: Update SchemaInfo**

Replace `Sources/HealthQLPlayground/SchemaInfo.swift`:
```swift
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter SchemaInfoTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(playground): add category and workout types to SchemaInfo

- allTypes() includes category types, workouts, sleep
- schema() returns field info for all types"
```

---

## Task 8: Update Autocomplete

**Files:**
- Modify: `Sources/HealthQLPlayground/Autocomplete.swift`
- Test: `Tests/HealthQLPlaygroundTests/AutocompleteTests.swift`

**Step 1: Write failing tests**

Add to `Tests/HealthQLPlaygroundTests/AutocompleteTests.swift`:
```swift
@Test("Suggests category types after FROM")
func categoryTypesAfterFrom() {
    let autocomplete = Autocomplete()
    let suggestions = autocomplete.suggest(for: "SELECT * FROM sleep", cursorPosition: 19)

    #expect(suggestions.contains("sleep_analysis") || suggestions.contains("sleep"))
}

@Test("Suggests workouts after FROM")
func workoutsAfterFrom() {
    let autocomplete = Autocomplete()
    let suggestions = autocomplete.suggest(for: "SELECT * FROM work", cursorPosition: 18)

    #expect(suggestions.contains("workouts"))
}

@Test("Suggests workout fields")
func workoutFields() {
    let autocomplete = Autocomplete()
    let suggestions = autocomplete.suggest(for: "SELECT dur", cursorPosition: 10)

    #expect(suggestions.contains("duration"))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AutocompleteTests`
Expected: FAIL - suggestions not found

**Step 3: Update Autocomplete**

In `Sources/HealthQLPlayground/Autocomplete.swift`, update the fields and getTypeNames:

Find the `fields` static property and update:
```swift
private static let fields = ["value", "date", "end_date", "source", "device", "stage", "severity", "activity_type", "duration", "total_calories", "distance", "*"]
```

Update `getTypeNames()`:
```swift
private func getTypeNames() -> [String] {
    var types: [String] = []
    types.append(contentsOf: QuantityType.allCases.map { $0.displayName })
    types.append(contentsOf: CategoryType.allCases.map { $0.displayName })
    types.append(WorkoutType.tableName)
    types.append("sleep")
    return types
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AutocompleteTests`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat(playground): add category and workout to autocomplete

- Category and workout fields in suggestions
- Category types and workouts in FROM suggestions"
```

---

## Task 9: Integration Tests

**Files:**
- Create: `Tests/HealthQLParserTests/Phase4IntegrationTests.swift`

**Step 1: Write integration tests**

Create `Tests/HealthQLParserTests/Phase4IntegrationTests.swift`:
```swift
import Testing
@testable import HealthQL
@testable import HealthQLParser

@Suite("Phase 4 Integration Tests")
struct Phase4IntegrationTests {

    @Test("Parse and compile sleep_analysis query")
    func sleepAnalysisQuery() throws {
        let query = try HQL.parse("SELECT * FROM sleep_analysis WHERE date > today() - 7d")

        if case .category(let type) = query.source {
            #expect(type == .sleepAnalysis)
        } else {
            Issue.record("Expected category source")
        }
        #expect(query.predicates.count == 1)
    }

    @Test("Parse and compile workouts query")
    func workoutsQuery() throws {
        let query = try HQL.parse("SELECT duration, total_calories FROM workouts")

        if case .workout = query.source {
            // Pass
        } else {
            Issue.record("Expected workout source")
        }
        #expect(query.selections.count == 2)
    }

    @Test("Parse and compile sleep session query")
    func sleepSessionQuery() throws {
        let query = try HQL.parse("SELECT duration, deep, rem FROM sleep WHERE date > today() - 30d")

        if case .sleepSession = query.source {
            // Pass
        } else {
            Issue.record("Expected sleepSession source")
        }
    }

    @Test("Parse and compile symptom query with aggregation")
    func symptomAggregateQuery() throws {
        let query = try HQL.parse("SELECT count(*) FROM headache GROUP BY week")

        if case .category(let type) = query.source {
            #expect(type == .headache)
        } else {
            Issue.record("Expected category source")
        }
        #expect(query.grouping == .week)
    }

    @Test("Parse and compile workout query with ORDER BY")
    func workoutOrderByQuery() throws {
        let query = try HQL.parse("SELECT * FROM workouts ORDER BY date DESC LIMIT 10")

        if case .workout = query.source {
            // Pass
        } else {
            Issue.record("Expected workout source")
        }
        #expect(query.limit == 10)
        #expect(query.ordering?.first?.direction == .descending)
    }
}
```

**Step 2: Run tests**

Run: `swift test --filter Phase4IntegrationTests`
Expected: All 5 tests pass

**Step 3: Run full test suite**

Run: `swift test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add -A
git commit -m "test: add Phase 4 integration tests

- sleep_analysis, workouts, sleep queries
- Symptom aggregation
- Workout ORDER BY and LIMIT"
```

---

## Task 10: Run Full Test Suite

**Step 1: Run all tests**

Run: `swift test`
Expected: All tests pass (~147 tests)

**Step 2: Verify build**

Run: `swift build`
Expected: Build Succeeded

**Step 3: Final commit if needed**

```bash
git status
# If clean, no commit needed
```

---

## Phase 4 Complete

At the end of Phase 4, you have:

- **CategoryType** - Sleep analysis, symptoms (headache, fatigue, etc.)
- **WorkoutType** - 12 workout activity types
- **Extended IR** - HealthSource with category, workout, sleepSession variants
- **Extended Compiler** - Resolves new table and field names
- **Updated SchemaInfo** - Exposes all new types
- **Updated Autocomplete** - Suggests new types and fields

**Supported queries:**
```sql
-- Sleep samples
SELECT * FROM sleep_analysis WHERE date > today() - 7d

-- Aggregated sleep sessions
SELECT duration, deep, rem FROM sleep

-- Symptoms
SELECT count(*) FROM headache WHERE date > start_of_month() GROUP BY week

-- Workouts
SELECT duration, total_calories FROM workouts ORDER BY date DESC LIMIT 10
```

**Next:** Phase 5 can add actual HealthKit query execution in the Executor.
