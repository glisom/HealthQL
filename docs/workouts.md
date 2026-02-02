# Workouts

Query exercise sessions recorded in HealthKit.

## Table

Use `workouts` to query workout data.

```sql
SELECT * FROM workouts
ORDER BY date DESC
LIMIT 10
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `duration` | Double | Duration in seconds |
| `total_calories` | Double | Total energy burned (kcal) |
| `distance` | Double | Distance in meters |
| `activity_type` | String | Workout type name |
| `date` | Date | Start time |
| `end_date` | Date | End time |
| `source` | String | Recording app |

## Activity Types

Common workout types:

| Type | Description |
|------|-------------|
| running | Running |
| walking | Walking |
| cycling | Cycling |
| swimming | Swimming |
| hiking | Hiking |
| yoga | Yoga |
| strength_training | Weight training |
| hiit | High-intensity interval |
| elliptical | Elliptical machine |
| rowing | Rowing |

## Examples

### Recent Workouts

```sql
SELECT duration, total_calories, activity_type
FROM workouts
ORDER BY date DESC
LIMIT 20
```

### Workout Summary

```sql
-- Total calories this week
SELECT sum(total_calories) FROM workouts
WHERE date > start_of_week()

-- Total duration this month
SELECT sum(duration) FROM workouts
WHERE date > start_of_month()
```

### Weekly Stats

```sql
SELECT sum(duration), sum(total_calories)
FROM workouts
WHERE date > today() - 30d
GROUP BY week
```

### Running Distance

```sql
SELECT sum(distance), sum(duration)
FROM workouts
WHERE activity_type = 'running' AND date > start_of_month()
GROUP BY week
```

### Longest Workouts

```sql
SELECT duration, total_calories, activity_type, date
FROM workouts
ORDER BY duration DESC
LIMIT 10
```

### Most Calorie-Intensive

```sql
SELECT total_calories, duration, activity_type, date
FROM workouts
ORDER BY total_calories DESC
LIMIT 10
```

## Aggregations

```sql
-- Weekly workout count
SELECT count(value) FROM workouts
WHERE date > today() - 30d
GROUP BY week

-- Average workout duration
SELECT avg(duration) FROM workouts
WHERE date > start_of_month()

-- Total distance this year
SELECT sum(distance) FROM workouts
WHERE date > start_of_year()
GROUP BY month
```

## Swift DSL

```swift
// Select workout fields
Health.select(.workout)
    .orderBy(.date, .descending)
    .limit(10)
    .execute()

// Aggregate workouts
Health.select(.workout, aggregate: .sum)
    .where(.date, .greaterThan, .date(.startOfMonth))
    .groupBy(.week)
    .execute()
```
