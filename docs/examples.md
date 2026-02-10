# Examples

Common query patterns for health data analysis.

## Daily Summaries

### Steps Dashboard

```sql
-- Daily steps for past month
SELECT sum(value) FROM steps
WHERE date > today() - 30d
GROUP BY day
ORDER BY date DESC

-- Weekly average
SELECT avg(value) FROM steps
WHERE date > today() - 30d
GROUP BY week
```

### Calorie Tracking

```sql
-- Daily active calories
SELECT sum(value) FROM active_calories
WHERE date > today() - 7d
GROUP BY day

-- Combined active + resting
SELECT sum(value) FROM active_calories
WHERE date > start_of_month()
GROUP BY day
```

### Activity Rings

```sql
-- Exercise minutes today
SELECT sum(value) FROM exercise_minutes
WHERE date > today()

-- Stand hours (approximation)
SELECT sum(value) FROM stand_time
WHERE date > today()
```

## Health Monitoring

### Heart Rate Zones

```sql
-- Resting heart rate trend
SELECT avg(value) FROM heart_rate
WHERE date > today() - 30d
GROUP BY day

-- High heart rate events
SELECT value, date, source FROM heart_rate
WHERE value > 120 AND date > today() - 7d
ORDER BY value DESC
```

### Blood Oxygen

```sql
-- Daily SpO2 readings
SELECT avg(value), min(value), max(value)
FROM oxygen_saturation
WHERE date > today() - 7d
GROUP BY day

-- Low oxygen events
SELECT value, date FROM oxygen_saturation
WHERE value < 95 AND date > today() - 7d
ORDER BY date DESC
```

### HRV Trend

```sql
SELECT avg(value) FROM heart_rate_variability
WHERE date > today() - 30d
GROUP BY day
ORDER BY date ASC
```

## Fitness Tracking

### Workout History

```sql
-- Recent workouts
SELECT duration, total_calories, activity_type, date
FROM workouts
ORDER BY date DESC
LIMIT 20

-- This month's summary
SELECT count(value), sum(duration), sum(total_calories)
FROM workouts
WHERE date > start_of_month()
```

### Running Log

```sql
SELECT distance, duration, total_calories, date
FROM workouts
WHERE activity_type = 'running' AND date > today() - 30d
ORDER BY date DESC
```

### Weekly Exercise

```sql
SELECT sum(duration), sum(total_calories)
FROM workouts
WHERE date > today() - 4w
GROUP BY week
ORDER BY date DESC
```

## Sleep Analysis

### Sleep Duration

```sql
-- Nightly sleep this week
SELECT duration, date FROM sleep
WHERE date > today() - 7d
ORDER BY date DESC

-- Average by week
SELECT avg(duration) FROM sleep
WHERE date > today() - 30d
GROUP BY week
```

### Sleep Quality

```sql
-- Deep + REM sleep trend
SELECT deep_duration, rem_duration, date
FROM sleep
WHERE date > today() - 14d
ORDER BY date DESC

-- Time awake during night
SELECT awake_duration, duration, date
FROM sleep
WHERE date > today() - 7d
ORDER BY date DESC
```

## Weight & Body

### Weight Trend

```sql
-- Recent weight
SELECT value, date FROM body_mass
ORDER BY date DESC
LIMIT 30

-- Weekly average
SELECT avg(value) FROM body_mass
WHERE date > today() - 3mo
GROUP BY week
ORDER BY date ASC
```

### Body Composition

```sql
-- Body fat trend
SELECT avg(value) FROM body_fat_percentage
WHERE date > today() - 3mo
GROUP BY week
```

## Symptom Tracking

### Headache Log

```sql
-- Recent headaches
SELECT severity, date FROM headache
WHERE date > today() - 30d
ORDER BY date DESC

-- Monthly frequency
SELECT count(value) FROM headache
WHERE date > start_of_year()
GROUP BY month
```

### Energy Levels

```sql
SELECT * FROM fatigue
WHERE date > today() - 14d
ORDER BY date DESC
```

## Custom Date/Time Queries

### Active Calories for a Specific Hour

```sql
-- Get active calorie count for Feb 5th, 4:00 PM - 5:00 PM
SELECT sum(value) FROM active_calories
WHERE date BETWEEN '2026-02-05 16:00' AND '2026-02-05 17:00'
```

### Heart Rate for a Specific Date Range

```sql
SELECT avg(value), min(value), max(value) FROM heart_rate
WHERE date BETWEEN '2026-01-15' AND '2026-01-22'
GROUP BY day
ORDER BY date ASC
```

### Steps on a Specific Day

```sql
SELECT sum(value) FROM steps
WHERE date > '2026-02-05' AND date < '2026-02-06'
GROUP BY hour
```

### Data from the Last 4 Hours

```sql
SELECT avg(value) FROM heart_rate
WHERE date > today() - 4h
```

### Workout During a Specific Morning

```sql
SELECT duration, total_calories, activity_type FROM workouts
WHERE date BETWEEN '2026-02-05 06:00' AND '2026-02-05 12:00'
```

## Comparison Queries

### Today vs Yesterday

```sql
-- Today's steps
SELECT sum(value) FROM steps WHERE date > today()

-- Yesterday's steps
SELECT sum(value) FROM steps
WHERE date > today() - 1d AND date < today()
```

### This Week vs Last Week

```sql
-- This week
SELECT sum(value) FROM active_calories
WHERE date > start_of_week()

-- Last week
SELECT sum(value) FROM active_calories
WHERE date > start_of_week() - 7d AND date < start_of_week()
```

### This Month vs Last Month

```sql
-- This month
SELECT sum(value) FROM steps
WHERE date > start_of_month()
GROUP BY day

-- Last month
SELECT sum(value) FROM steps
WHERE date > start_of_month() - 30d AND date < start_of_month()
GROUP BY day
```
