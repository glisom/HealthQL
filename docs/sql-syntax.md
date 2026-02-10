# SQL Syntax

HealthQL supports a SQL-like syntax for querying HealthKit data.

## Basic Query Structure

```sql
SELECT <selections>
FROM <table>
[WHERE <conditions>]
[GROUP BY <period>]
[ORDER BY <field> [ASC|DESC]]
[LIMIT <count>]
```

## SELECT Clause

### Select All Fields

```sql
SELECT * FROM heart_rate
```

### Select Specific Fields

```sql
SELECT value, date, source FROM heart_rate
```

### Aggregations

```sql
SELECT sum(value) FROM steps
SELECT avg(value), min(value), max(value) FROM heart_rate
SELECT count(value) FROM workouts
```

| Function | Description |
|----------|-------------|
| `sum()` | Sum of values |
| `avg()` | Average (mean) |
| `min()` | Minimum value |
| `max()` | Maximum value |
| `count()` | Number of records |

## FROM Clause

Specify the health data type to query:

```sql
FROM heart_rate
FROM steps
FROM workouts
FROM sleep_analysis
```

See [Quantity Types](quantity-types.md), [Category Types](category-types.md), [Workouts](workouts.md), and [Sleep](sleep.md) for all available tables.

## WHERE Clause

### Comparison Operators

```sql
WHERE value > 100
WHERE value >= 60
WHERE value < 200
WHERE value <= 80
WHERE value = 72
WHERE value != 0
WHERE value <> 0
```

### Date Comparisons

```sql
WHERE date > today()
WHERE date > today() - 7d
WHERE date > today() - 4h
WHERE date > start_of_month()
```

### Custom Date/Time Literals

```sql
WHERE date > '2026-02-05'
WHERE date > '2026-02-05 16:00'
WHERE date > '2026-02-05 16:30:45'
```

### BETWEEN Operator

```sql
WHERE date BETWEEN '2026-02-05 16:00' AND '2026-02-05 17:00'
WHERE date BETWEEN today() - 7d AND today()
WHERE value BETWEEN 60 AND 100
```

### Multiple Conditions

```sql
WHERE value > 60 AND value < 100
WHERE date > today() - 7d AND value > 80
```

### NULL Checks

```sql
WHERE device IS NULL
WHERE device IS NOT NULL
```

## GROUP BY Clause

Aggregate data by time periods:

```sql
GROUP BY hour
GROUP BY day
GROUP BY week
GROUP BY month
GROUP BY year
```

> **Note:** GROUP BY requires at least one aggregation function in SELECT.

```sql
-- Valid
SELECT avg(value) FROM heart_rate GROUP BY day

-- Invalid - no aggregation
SELECT value FROM heart_rate GROUP BY day
```

## ORDER BY Clause

```sql
ORDER BY date ASC      -- Oldest first
ORDER BY date DESC     -- Newest first (default)
ORDER BY value DESC    -- Highest first
```

## LIMIT Clause

```sql
LIMIT 10       -- Return at most 10 rows
LIMIT 100      -- Return at most 100 rows
```

## Complete Examples

### Daily Heart Rate Summary

```sql
SELECT avg(value), min(value), max(value)
FROM heart_rate
WHERE date > today() - 30d
GROUP BY day
ORDER BY date DESC
LIMIT 30
```

### Weekly Step Totals

```sql
SELECT sum(value)
FROM steps
WHERE date > start_of_year()
GROUP BY week
ORDER BY date ASC
```

### Recent High Heart Rate

```sql
SELECT value, date, source
FROM heart_rate
WHERE value > 100 AND date > today() - 7d
ORDER BY value DESC
LIMIT 20
```

### Monthly Calorie Burn

```sql
SELECT sum(value)
FROM active_calories
WHERE date > today() - 1y
GROUP BY month
```

### Active Calories for a Specific Hour

```sql
SELECT sum(value)
FROM active_calories
WHERE date BETWEEN '2026-02-05 16:00' AND '2026-02-05 17:00'
```

### Heart Rate for a Date Range

```sql
SELECT avg(value), min(value), max(value)
FROM heart_rate
WHERE date BETWEEN '2026-01-15' AND '2026-01-22'
GROUP BY day
```

## Case Sensitivity

- **Keywords** are case-insensitive: `SELECT`, `select`, `Select` all work
- **Table names** are case-sensitive: use `heart_rate`, not `Heart_Rate`
- **Field names** are case-sensitive: use `value`, not `Value`

## Whitespace

Extra whitespace and newlines are ignored:

```sql
SELECT    avg(value)
FROM      heart_rate
WHERE     date > today() - 7d
GROUP BY  day
```
