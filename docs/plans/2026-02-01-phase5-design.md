# Phase 5 Design: HealthKit Query Execution

## Overview

Execute HealthQL queries against HealthKit for all source types (quantity, category, workout, sleep session) using async/await wrappers around HealthKit's callback-based APIs.

## Architecture

```
HealthQuery → Executor → SourceHandler → HKQuery → Results → Formatting
                ↓
         .quantity → QuantityQueryHandler
         .category → CategoryQueryHandler
         .workout  → WorkoutQueryHandler
         .sleepSession → SleepSessionHandler
```

### Key Components

| Component | Responsibility |
|-----------|----------------|
| HealthQueryExecutor | Entry point, validates query, dispatches to handlers |
| QuantityQueryHandler | HKSampleQuery for quantities, HKStatisticsQuery for aggregates |
| CategoryQueryHandler | HKSampleQuery for categories, maps values to display names |
| WorkoutQueryHandler | HKSampleQuery for HKWorkout type |
| SleepSessionHandler | Aggregates sleep samples into nightly sessions |
| HealthStoreProtocol | Abstracts HKHealthStore for testability |

### Authorization

Each handler requests read permission for its type on first query using `healthStore.requestAuthorization()`. Subsequent queries skip authorization.

## Query Execution Flow

### Quantity Types

```swift
// Simple query: SELECT * FROM heart_rate WHERE date > today() - 7d
1. Build HKSampleQuery with predicate from IR
2. Execute async, collect HKQuantitySample results
3. Transform to ResultRow: [value, date, source, device]

// Aggregate query: SELECT avg(value) FROM heart_rate GROUP BY day
1. Build HKStatisticsCollectionQuery with interval
2. Execute async, collect HKStatistics per period
3. Transform to ResultRow: [avg_value, period_start]
```

### Predicate Mapping

| IR Predicate | HKQuery Predicate |
|--------------|-------------------|
| `.field(.date), .greaterThan, .date(d)` | `HKQuery.predicateForSamples(withStart: d, end: nil)` |
| `.field(.value), .greaterThan, .double(v)` | `HKQuery.predicateForQuantitySamples(with: .greaterThan, quantity: v)` |
| `.field(.source), .equals, .string(s)` | `HKQuery.predicateForObjects(from: sources)` |

### Result Transformation

Each `HKSample` becomes a `ResultRow`:
- `value` → `sample.quantity.doubleValue(for: unit)`
- `date` → `sample.startDate`
- `end_date` → `sample.endDate`
- `source` → `sample.sourceRevision.source.name`
- `device` → `sample.device?.name`

### Category Types

```swift
// SELECT * FROM headache WHERE date > today() - 7d
1. Build HKSampleQuery for HKCategoryType
2. Execute async, collect HKCategorySample results
3. Map integer value to display name (severity: 3 → "severe")
4. Transform to ResultRow: [value, severity, date, source]
```

Category value mapping:
- `sleep_analysis` → `SleepStage.displayName` (0="in_bed", 5="rem")
- `headache/fatigue` → `Severity.displayName` (1="mild", 3="severe")

### Workouts

```swift
// SELECT duration, total_calories FROM workouts WHERE date > today() - 30d
1. Build HKSampleQuery for HKWorkoutType
2. Execute async, collect HKWorkout results
3. Extract: duration, totalEnergyBurned, totalDistance, workoutActivityType
4. Transform to ResultRow with requested fields
```

### Sleep Sessions

```swift
// SELECT duration, deep, rem FROM sleep WHERE date > today() - 7d
1. Query all sleep_analysis samples in date range
2. Group by calendar night (samples between 6pm-12pm next day)
3. Sum durations per stage: deep, rem, core, awake
4. Calculate total sleep duration (excluding awake)
5. Return one ResultRow per night
```

## Error Handling

| Scenario | Error | Behavior |
|----------|-------|----------|
| HealthKit unavailable | `.healthKitNotAvailable` | Throw before query |
| User denies authorization | `.authorizationDenied` | Throw with message |
| Invalid field for source | `.invalidQuery(String)` | Throw at execution |
| No samples found | - | Return empty QueryResult |
| HealthKit query fails | `.healthKitError(Error)` | Wrap underlying error |

## Testing Strategy

1. **Unit tests with mock HKHealthStore** - Protocol-based injection
2. **Integration tests on device** - Real HealthKit (manual, requires entitlements)
3. **Predicate building tests** - Verify IR → HKQuery predicate mapping

```swift
protocol HealthStoreProtocol: Sendable {
    func execute(_ query: HKQuery)
    func requestAuthorization(toShare: Set<HKSampleType>?, read: Set<HKObjectType>?) async throws
}
```

## Files

**Created:**
- `Sources/HealthQL/Executor/HealthStoreProtocol.swift`
- `Sources/HealthQL/Executor/PredicateBuilder.swift`
- `Sources/HealthQL/Executor/QuantityQueryHandler.swift`
- `Sources/HealthQL/Executor/CategoryQueryHandler.swift`
- `Sources/HealthQL/Executor/WorkoutQueryHandler.swift`
- `Sources/HealthQL/Executor/SleepSessionHandler.swift`

**Modified:**
- `Sources/HealthQL/Executor/Executor.swift`

## Implementation Tasks

1. HealthStoreProtocol - Abstract HealthKit for testability
2. Predicate Builder - Convert IR predicates to HKQuery predicates
3. QuantityQueryHandler - Execute quantity sample and statistics queries
4. CategoryQueryHandler - Execute category queries with value mapping
5. WorkoutQueryHandler - Execute workout queries
6. SleepSessionHandler - Aggregate sleep samples into sessions
7. Update Executor - Dispatch to handlers, request authorization
8. Result Transformation - Convert HK samples to ResultRow
9. Unit Tests - Mock-based handler tests
10. Integration Tests - End-to-end verification

## Example Queries

```sql
-- Quantity with filter
SELECT * FROM heart_rate WHERE date > today() - 7d

-- Quantity with aggregation
SELECT avg(value) FROM steps GROUP BY day

-- Category with severity filter
SELECT * FROM headache WHERE severity = 'severe'

-- Workouts with ordering
SELECT duration, total_calories FROM workouts ORDER BY date DESC LIMIT 10

-- Sleep sessions
SELECT duration, deep, rem FROM sleep WHERE date > today() - 30d
```
