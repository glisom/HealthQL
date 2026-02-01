# HealthQL Design

A SQL-like query language for Apple HealthKit that simplifies the verbose API and makes health data accessible to developers and power users alike.

## Goals

1. **Simplify HealthKit's complex API** - Replace verbose, callback-heavy code with declarative queries
2. **Enable non-developers to query health data** - Accessible syntax for analysts, researchers, and power users
3. **Two interfaces, one engine** - String-based SQL syntax for exploration, type-safe Swift DSL for production apps

## Deliverables

- **HealthQL** - Swift package for developers (DSL + core engine)
- **HealthQL Playground** - iOS/macOS REPL app for interactive querying

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Interfaces                                     │
│  ├── String Parser ("SELECT steps FROM...")     │
│  └── Swift DSL (Health.select(.steps)...)       │
└──────────────────────┬──────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────┐
│  HealthQL Core                                  │
│  ├── Query IR (Intermediate Representation)     │
│  ├── Query Planner (optimize, validate)         │
│  ├── Schema Registry (all HealthKit types)      │
│  └── Executor (translates IR → HKQuery calls)   │
└──────────────────────┬──────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────┐
│  HealthKit Framework                            │
└─────────────────────────────────────────────────┘
```

Both the string parser and Swift DSL compile to the same intermediate representation, ensuring consistent behavior.

---

## Query Language Syntax

### Basic Structure

```sql
SELECT <metrics>
FROM <health_type>
[WHERE <conditions>]
[GROUP BY <time_period>]
[HAVING <aggregate_conditions>]
[ORDER BY <field> [ASC|DESC]]
[LIMIT <n>]
```

### Example Queries

```sql
-- Simple: steps from last 7 days
SELECT sum(count) FROM steps WHERE date > today() - 7d

-- Grouped: daily average heart rate this month
SELECT avg(value), min(value), max(value)
FROM heart_rate
WHERE date > start_of_month()
GROUP BY day

-- Statistical: heart rate percentiles during workouts
SELECT p50(value), p90(value), stddev(value)
FROM heart_rate
WHERE workout IS NOT NULL

-- Correlation/join: sleep vs next-day steps
SELECT sleep.duration, steps.count
FROM sleep
JOIN steps ON steps.date = sleep.end_date
WHERE sleep.date > today() - 30d

-- Category data: sleep stages breakdown
SELECT stage, sum(duration)
FROM sleep_analysis
GROUP BY stage

-- Workouts with nested data
SELECT type, duration, avg(heart_rate.value)
FROM workouts
WHERE date > today() - 30d
```

### Time Literals and Functions

- Duration literals: `7d`, `2w`, `3mo`, `1y`
- Functions: `today()`, `start_of_week()`, `start_of_month()`, `start_of_year()`

### Supported Operations

**Aggregations:** SUM, AVG, MIN, MAX, COUNT

**Statistical:** P50, P90, P95, P99, STDDEV, VARIANCE, MOVING_AVG

**Correlations:** JOIN across health types

---

## Swift DSL

### Query Examples

```swift
// Simple: steps from last 7 days
Health.select(.steps, aggregate: .sum)
    .where { $0.date > .daysAgo(7) }

// Grouped: daily average heart rate this month
Health.select(.heartRate, aggregates: [.avg, .min, .max])
    .where { $0.date > .startOfMonth }
    .groupBy(.day)

// Statistical: heart rate percentiles during workouts
Health.select(.heartRate, aggregates: [.p50, .p90, .stddev])
    .where { $0.workout != nil }

// Correlation/join: sleep vs next-day steps
Health.select(.sleep, .steps)
    .join(.steps, on: { $0.steps.date == $0.sleep.endDate })
    .where { $0.sleep.date > .daysAgo(30) }

// Workouts with nested data
Health.select(.workouts)
    .including(.heartRate, aggregate: .avg)
    .where { $0.date > .daysAgo(30) }
```

### Execution

```swift
let results = try await Health.select(.steps, aggregate: .sum)
    .where { $0.date > .daysAgo(7) }
    .groupBy(.day)
    .execute()

for row in results {
    print("\(row.date): \(row.sum) steps")
}
```

### Design Principles

- Async/await for all queries
- Generic result types based on selected fields
- Compile-time validation of field names and aggregations

---

## Intermediate Representation

```swift
struct HealthQuery {
    let source: HealthSource
    let selections: [Selection]
    let predicates: [Predicate]
    let grouping: GroupBy?
    let having: [Predicate]?
    let ordering: [OrderBy]?
    let limit: Int?
    let joins: [Join]?
}

enum HealthSource {
    case quantity(QuantityType)
    case category(CategoryType)
    case workout
    case clinicalRecord(ClinicalType)
    case correlation(HealthSource, HealthSource)
}

enum Selection {
    case field(Field)
    case aggregate(Aggregate, Field)
}

struct Predicate {
    let field: Field
    let op: Operator
    let value: PredicateValue
}
```

### Query Lifecycle

```
String/DSL → Parse → IR → Validate → Plan → Execute → Results
```

The planner translates one HealthQuery IR into potentially multiple HKQuery calls (e.g., a join requires separate queries then local correlation).

---

## Schema Registry

### Type Mapping

```swift
enum QuantityType: String, CaseIterable {
    case steps = "HKQuantityTypeIdentifierStepCount"
    case heartRate = "HKQuantityTypeIdentifierHeartRate"
    case activeCalories = "HKQuantityTypeIdentifierActiveEnergyBurned"
    // ... all quantity types

    var displayName: String { /* "steps", "heart_rate" */ }
    var unit: HKUnit { /* .count(), .bpm(), .kilocalorie() */ }
    var fields: [Field] { /* value, date, source, device */ }
}
```

### Unified Fields

| Type | Common Fields | Type-Specific Fields |
|------|--------------|---------------------|
| Quantities | date, source, device | value (Double), unit |
| Categories | date, source, device | category (enum value) |
| Workouts | date, source, device | duration, type, distance, calories |
| Sleep | date, source, device | stage, duration |
| Clinical | date, source | fhirResource, type |

### SQL Aliases

```sql
-- These all work:
SELECT * FROM steps
SELECT * FROM step_count
SELECT * FROM HKQuantityTypeIdentifierStepCount
```

---

## Playground App (REPL)

### Interface

```
┌─────────────────────────────────────────────────────┐
│ HealthQL>                                           │
├─────────────────────────────────────────────────────┤
│ HealthQL> SELECT sum(count) FROM steps              │
│           WHERE date > today() - 7d                 │
│           GROUP BY day                              │
│                                                     │
│ ┌─────────────┬───────────┐                         │
│ │ date        │ sum       │                         │
│ ├─────────────┼───────────┤                         │
│ │ 2024-01-25  │ 8,432     │                         │
│ │ 2024-01-26  │ 12,105    │                         │
│ │ 2024-01-27  │ 6,221     │                         │
│ └─────────────┴───────────┘                         │
│ 3 rows (23ms)                                       │
│                                                     │
│ HealthQL> _                                         │
└─────────────────────────────────────────────────────┘
```

### Features

- **Autocomplete** - Tab-completion for types, fields, functions, keywords
- **History** - Up/down arrows, persistent across sessions
- **Multi-line input** - Detects incomplete queries, continues on next line
- **Meta commands:**
  - `.schema steps` - Show fields for a type
  - `.types` - List all available health types
  - `.history` - Show query history
  - `.export csv` - Export last result
  - `.clear` - Clear screen

### Error Handling

```
HealthQL> SELECT sum(value) FROM stepz
Error: Unknown type 'stepz'. Did you mean 'steps'?
```

---

## Project Structure

```
HealthQL/
├── Package.swift
├── Sources/
│   ├── HealthQL/                    # Swift package (for developers)
│   │   ├── DSL/
│   │   │   ├── Health.swift         # Entry point: Health.select(...)
│   │   │   ├── QueryBuilder.swift   # Fluent builder API
│   │   │   └── Predicates.swift     # Where clause operators
│   │   ├── Core/
│   │   │   ├── IR.swift             # Intermediate representation
│   │   │   ├── Planner.swift        # Query optimization
│   │   │   ├── Executor.swift       # HKQuery translation
│   │   │   └── Schema.swift         # Type registry
│   │   └── Results/
│   │       ├── QueryResult.swift    # Typed result containers
│   │       └── Row.swift            # Individual result rows
│   │
│   └── HealthQLParser/              # Separate module for string parsing
│       ├── Lexer.swift
│       ├── Parser.swift
│       └── Grammar.swift
│
├── Apps/
│   └── HealthQLPlayground/          # iOS/macOS app
│       ├── REPL/
│       │   ├── REPLView.swift
│       │   ├── Autocomplete.swift
│       │   └── History.swift
│       └── App/
│           └── HealthQLApp.swift
│
└── Tests/
    ├── HealthQLTests/
    └── ParserTests/
```

---

## Implementation Phases

### Phase 1 - Foundation
- Core IR and schema registry
- Basic DSL for quantity types (steps, heart rate, calories)
- Simple predicates (date ranges, value comparisons)
- Basic aggregations (sum, avg, min, max, count)

### Phase 2 - Query Language
- String parser (lexer, grammar, parser)
- GROUP BY time periods
- ORDER BY, LIMIT

### Phase 3 - Playground App
- REPL interface with input/output
- Autocomplete engine
- Query history
- Meta commands (.schema, .types, etc.)

### Phase 4 - Full Coverage
- Category types (sleep, symptoms)
- Workouts with nested samples
- Clinical records
- Statistical functions (percentiles, stddev, moving averages)

### Phase 5 - Advanced
- JOINs and correlations
- HAVING clauses
- Query optimization
- Export functionality

---

## Distribution

- **HealthQL** - Published to Swift Package Manager
- **HealthQL Playground** - Distributed via TestFlight / App Store
