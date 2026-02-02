# Category Types

HealthQL supports 5 category types from HealthKit for tracking symptoms and conditions.

## Available Types

| SQL Name | Description |
|----------|-------------|
| `sleep_analysis` | Raw sleep stage data |
| `appetite_changes` | Appetite tracking |
| `headache` | Headache occurrences |
| `fatigue` | Fatigue levels |
| `menstrual_flow` | Menstrual cycle data |

## Sleep Analysis

Raw sleep data with individual stages.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `value` | Int | Stage value (0-5) |
| `stage` | String | Stage name |
| `date` | Date | Start time |
| `end_date` | Date | End time |
| `duration` | Double | Duration in seconds |
| `source` | String | Recording app/device |

### Sleep Stages

| Value | Stage Name |
|-------|------------|
| 0 | in_bed |
| 1 | asleep |
| 2 | awake |
| 3 | core |
| 4 | deep |
| 5 | rem |

### Examples

```sql
-- Recent sleep data
SELECT * FROM sleep_analysis
WHERE date > today() - 7d
ORDER BY date DESC

-- Sleep from last night
SELECT stage, duration, date FROM sleep_analysis
WHERE date > today() - 1d
ORDER BY date ASC
```

> **Tip:** For aggregated nightly sleep data, use the `sleep` table instead. See [Sleep](sleep.md).

## Symptom Types

Track symptoms with severity levels.

### Severity Levels

| Value | Level |
|-------|-------|
| 0 | not_present |
| 1 | mild |
| 2 | moderate |
| 3 | severe |
| 4 | unspecified |

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `value` | Int | Severity value (0-4) |
| `severity` | String | Severity name |
| `date` | Date | When recorded |
| `end_date` | Date | End time |
| `source` | String | Recording app |

## Headache

```sql
-- Recent headaches
SELECT * FROM headache
WHERE date > today() - 30d
ORDER BY date DESC

-- Headache frequency by week
SELECT count(value) FROM headache
WHERE date > today() - 3mo
GROUP BY week
```

## Fatigue

```sql
-- Recent fatigue entries
SELECT * FROM fatigue
WHERE date > today() - 14d
ORDER BY date DESC

-- Fatigue occurrences this month
SELECT count(value) FROM fatigue
WHERE date > start_of_month()
```

## Appetite Changes

```sql
-- Appetite tracking
SELECT * FROM appetite_changes
WHERE date > today() - 7d
ORDER BY date DESC
```

## Menstrual Flow

```sql
-- Cycle data
SELECT * FROM menstrual_flow
WHERE date > today() - 30d
ORDER BY date DESC
```

## Swift DSL

```swift
// Using CategoryType enum
Health.select(.sleepAnalysis)
Health.select(.headache)
Health.select(.fatigue)
Health.select(.appetiteChanges)
Health.select(.menstrualFlow)
```
