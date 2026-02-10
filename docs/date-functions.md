# Date Functions

HealthQL provides date functions and duration syntax for filtering health data.

## Date Functions

| Function | Returns |
|----------|---------|
| `today()` | Start of current day (midnight) |
| `start_of_week()` | Start of current week (Sunday midnight) |
| `start_of_month()` | First day of current month |
| `start_of_year()` | January 1st of current year |

### Examples

```sql
-- Data from today only
WHERE date > today()

-- Data from this week
WHERE date > start_of_week()

-- Data from this month
WHERE date > start_of_month()

-- Data from this year
WHERE date > start_of_year()
```

## Duration Syntax

Subtract durations from date functions:

| Unit | Syntax | Example |
|------|--------|---------|
| Hours | `h` | `4h` |
| Days | `d` | `7d` |
| Weeks | `w` | `4w` |
| Months | `mo` | `3mo` |
| Years | `y` | `1y` |

### Examples

```sql
-- Last 4 hours
WHERE date > today() - 4h

-- Last 7 days
WHERE date > today() - 7d

-- Last 4 weeks
WHERE date > today() - 4w

-- Last 3 months
WHERE date > today() - 3mo

-- Last year
WHERE date > today() - 1y
```

## Custom Date/Time Literals

Use date and datetime strings for querying specific dates and times:

| Format | Example |
|--------|---------|
| Date only | `'2026-02-05'` |
| Date + time | `'2026-02-05 16:00'` |
| Date + time + seconds | `'2026-02-05 16:30:45'` |

### Examples

```sql
-- Data after a specific date
WHERE date > '2026-02-05'

-- Data on a specific day
WHERE date > '2026-02-05' AND date < '2026-02-06'

-- Data during a specific hour
WHERE date BETWEEN '2026-02-05 16:00' AND '2026-02-05 17:00'
```

## BETWEEN Operator

Use `BETWEEN` for range queries. Works with both date functions and date literals:

```sql
-- Active calories for a specific hour on Feb 5th
SELECT sum(value) FROM active_calories
WHERE date BETWEEN '2026-02-05 16:00' AND '2026-02-05 17:00'

-- Data from a specific date range
SELECT avg(value) FROM heart_rate
WHERE date BETWEEN '2026-01-15' AND '2026-01-22'
GROUP BY day

-- Using date functions
SELECT sum(value) FROM steps
WHERE date BETWEEN today() - 7d AND today()
GROUP BY day
```

## Common Patterns

### Daily Data for Past Week

```sql
SELECT avg(value) FROM heart_rate
WHERE date > today() - 7d
GROUP BY day
```

### Weekly Data for Past Month

```sql
SELECT sum(value) FROM steps
WHERE date > today() - 4w
GROUP BY week
```

### Monthly Data for Past Year

```sql
SELECT sum(value) FROM active_calories
WHERE date > today() - 1y
GROUP BY month
```

### This Month vs Last Month

```sql
-- This month
SELECT sum(value) FROM steps
WHERE date > start_of_month()

-- Last month (30 days ago to start of month)
SELECT sum(value) FROM steps
WHERE date > today() - 30d AND date < start_of_month()
```

## Swift DSL Equivalents

```swift
// Date references
DateReference.today           // today()
DateReference.startOfWeek     // start_of_week()
DateReference.startOfMonth    // start_of_month()
DateReference.startOfYear     // start_of_year()

// Durations
DateReference.hoursAgo(4)     // today() - 4h
DateReference.daysAgo(7)      // today() - 7d
DateReference.weeksAgo(4)     // today() - 4w
DateReference.monthsAgo(3)    // today() - 3mo

// Exact dates
DateReference.exact(someDate)  // '2026-02-05 16:00'

// Usage
Health.select(.steps, aggregate: .sum)
    .where(.date, .greaterThan, .date(.daysAgo(7)))
    .groupBy(.day)
    .execute()

// BETWEEN using the DSL
Health.select(.activeCalories, aggregate: .sum)
    .where(.date, .between, .dateRange(start: startDate, end: endDate))
    .execute()
```

## Notes

- All date functions return dates at midnight (00:00:00)
- Week starts on Sunday by default (follows system calendar)
- Duration subtraction is based on calendar units, not fixed intervals
- Date/datetime string literals use the device's local timezone
- Hour durations (`h`) subtract from the current time, not midnight
