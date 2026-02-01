# Phase 4 Design: Category Types & Workouts

## Overview

Expand HealthQL to support HealthKit category types (sleep, symptoms) and workouts, enabling queries like:

```sql
SELECT duration, deep, rem FROM sleep WHERE date > today() - 7d
SELECT * FROM workouts WHERE activity_type = 'running'
SELECT count(*) FROM headache WHERE severity = 'severe' GROUP BY week
```

## New Data Types

### CategoryType

Maps to `HKCategoryType` for categorical health data:

| Type | HK Identifier | Values |
|------|---------------|--------|
| `sleep_analysis` | `.sleepAnalysis` | inBed, asleep, awake, rem, core, deep |
| `appetite_changes` | `.appetiteChanges` | increased, decreased, noChange |
| `headache` | `.headache` | notPresent, mild, moderate, severe |
| `fatigue` | `.fatigue` | notPresent, mild, moderate, severe |
| `menstrual_flow` | `.menstrualFlow` | none, light, medium, heavy |

### Sleep Sessions

Special aggregated view of sleep data:

- Table name: `sleep`
- Fields: `start_date`, `end_date`, `duration`, `in_bed_duration`, `rem`, `core`, `deep`, `awake`
- Built by aggregating `HKCategorySample` sleep analysis ranges

### WorkoutType

Maps to `HKWorkoutActivityType`:

| Type | HK Identifier |
|------|---------------|
| `running` | `.running` |
| `walking` | `.walking` |
| `cycling` | `.cycling` |
| `swimming` | `.swimming` |
| `yoga` | `.yoga` |
| `strength_training` | `.traditionalStrengthTraining` |
| `hiking` | `.hiking` |
| `elliptical` | `.elliptical` |
| `rowing` | `.rowing` |

Workout fields: `activity_type`, `start_date`, `end_date`, `duration`, `total_calories`, `distance`

## Architecture

### DataSource Protocol

```swift
protocol HealthDataSource: Sendable {
    var tableName: String { get }
    var availableFields: [String] { get }
}
```

All source types (`QuantityType`, `CategoryType`, `WorkoutType`) conform to this protocol.

### IR SourceType

```swift
enum SourceType: Sendable {
    case quantity(QuantityType)
    case category(CategoryType)
    case workout
    case sleepSession
}
```

The `HealthQuery` IR uses `SourceType` instead of just `QuantityType`.

### Executor Strategy

The executor switches on `SourceType`:

1. **quantity** - Existing `HKQuantityType` query logic
2. **category** - New `HKCategorySample` query with value mapping
3. **workout** - New `HKWorkout` query
4. **sleepSession** - Aggregate sleep category samples into sessions

## Query Examples

### Category Queries

```sql
-- Raw sleep samples
SELECT * FROM sleep_analysis WHERE date > today() - 7d
SELECT stage, duration FROM sleep_analysis WHERE stage = 'rem'

-- Symptoms
SELECT * FROM headache WHERE severity = 'severe'
SELECT count(*) FROM fatigue GROUP BY day
```

### Sleep Session Queries

```sql
SELECT duration, deep, rem, awake FROM sleep WHERE date > today() - 7d
SELECT avg(duration) FROM sleep GROUP BY week
```

### Workout Queries

```sql
SELECT * FROM workouts WHERE date > today() - 7d
SELECT activity_type, duration, total_calories FROM workouts ORDER BY date DESC LIMIT 10
SELECT sum(distance) FROM workouts WHERE activity_type = 'running' GROUP BY week
```

## Implementation Tasks

1. CategoryType enum - Define category types with HK mappings
2. WorkoutType enum - Define workout activity types
3. DataSource protocol - Unified protocol for all source types
4. IR SourceType - Extend HealthQuery with source variants
5. Compiler updates - Resolve table names to SourceType
6. Category executor - Query HKCategorySample
7. Workout executor - Query HKWorkout
8. Sleep session executor - Aggregate sleep samples into sessions
9. SchemaInfo updates - Add new types to .types/.schema
10. Integration tests - End-to-end query tests

## Files

**Modified:**
- `Sources/HealthQL/Core/IR.swift`
- `Sources/HealthQLParser/Compiler.swift`
- `Sources/HealthQL/Executor/Executor.swift`
- `Sources/HealthQLPlayground/SchemaInfo.swift`

**Created:**
- `Sources/HealthQL/Core/CategoryType.swift`
- `Sources/HealthQL/Core/WorkoutType.swift`
- `Sources/HealthQL/Core/DataSource.swift`
