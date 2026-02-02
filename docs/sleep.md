# Sleep

HealthQL provides two ways to query sleep data.

## Sleep Tables

| Table | Description |
|-------|-------------|
| `sleep` | Aggregated nightly sessions |
| `sleep_analysis` | Raw sleep stage samples |

## Sleep Sessions (`sleep`)

The `sleep` table provides aggregated nightly sleep data, grouping individual sleep samples into complete nights.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `duration` | Double | Total sleep time (seconds) |
| `in_bed_duration` | Double | Time in bed (seconds) |
| `rem_duration` | Double | REM sleep time (seconds) |
| `core_duration` | Double | Core/light sleep time (seconds) |
| `deep_duration` | Double | Deep sleep time (seconds) |
| `awake_duration` | Double | Time awake during night (seconds) |
| `date` | Date | Night start date |

### Examples

```sql
-- Sleep summary for past week
SELECT * FROM sleep
WHERE date > today() - 7d
ORDER BY date DESC

-- Total sleep per night
SELECT duration, date FROM sleep
WHERE date > today() - 30d
ORDER BY date DESC

-- Average sleep by week
SELECT avg(duration) FROM sleep
WHERE date > today() - 30d
GROUP BY week
```

### Sleep Quality Analysis

```sql
-- Deep sleep percentage trend
SELECT deep_duration, duration, date FROM sleep
WHERE date > today() - 30d
ORDER BY date DESC

-- REM sleep over time
SELECT avg(rem_duration) FROM sleep
WHERE date > start_of_month()
GROUP BY week
```

## Raw Sleep Analysis (`sleep_analysis`)

For granular sleep stage data, use `sleep_analysis`. This returns individual sleep samples as recorded by Apple Watch or other devices.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `value` | Int | Stage value (0-5) |
| `stage` | String | Stage name |
| `date` | Date | Start time |
| `end_date` | Date | End time |
| `duration` | Double | Sample duration |
| `source` | String | Recording device |

### Sleep Stages

| Value | Name | Description |
|-------|------|-------------|
| 0 | in_bed | In bed, not asleep |
| 1 | asleep | Asleep (unspecified) |
| 2 | awake | Awake during night |
| 3 | core | Core/light sleep |
| 4 | deep | Deep sleep |
| 5 | rem | REM sleep |

### Examples

```sql
-- Last night's sleep stages
SELECT stage, duration, date FROM sleep_analysis
WHERE date > today() - 1d
ORDER BY date ASC

-- All sleep samples this week
SELECT * FROM sleep_analysis
WHERE date > today() - 7d
ORDER BY date DESC
LIMIT 100
```

## Which Table to Use?

| Use Case | Table |
|----------|-------|
| "How much did I sleep last night?" | `sleep` |
| "What's my average sleep this month?" | `sleep` |
| "Show me my sleep stages" | `sleep_analysis` |
| "When did I wake up during the night?" | `sleep_analysis` |
| "Total REM sleep this week" | `sleep` |
| "Deep sleep duration trend" | `sleep` |

## Swift DSL

```swift
// Aggregated sleep sessions
Health.select(.sleepSession)
    .where(.date, .greaterThan, .date(.daysAgo(7)))
    .execute()

// Raw sleep analysis
Health.select(.sleepAnalysis)
    .where(.date, .greaterThan, .date(.daysAgo(1)))
    .orderBy(.date, .ascending)
    .execute()
```
