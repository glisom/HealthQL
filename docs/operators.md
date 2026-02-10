# Operators

HealthQL supports standard SQL comparison operators.

## Comparison Operators

| Operator | SQL | Description |
|----------|-----|-------------|
| Equal | `=` | Exact match |
| Not Equal | `!=` or `<>` | Not matching |
| Greater Than | `>` | Greater than value |
| Greater Than or Equal | `>=` | Greater than or equal |
| Less Than | `<` | Less than value |
| Less Than or Equal | `<=` | Less than or equal |

### Examples

```sql
-- Equal
WHERE value = 72

-- Not equal
WHERE value != 0
WHERE value <> 0

-- Greater/less than
WHERE value > 100
WHERE value < 60

-- Greater/less than or equal
WHERE value >= 60
WHERE value <= 100
```

## Range Operators

| Operator | SQL | Description |
|----------|-----|-------------|
| Between | `BETWEEN ... AND ...` | Value within range (inclusive) |

### Examples

```sql
-- Date range with datetime literals
WHERE date BETWEEN '2026-02-05 16:00' AND '2026-02-05 17:00'

-- Date range with functions
WHERE date BETWEEN today() - 7d AND today()

-- Numeric range
WHERE value BETWEEN 60 AND 100
```

## NULL Operators

| Operator | Description |
|----------|-------------|
| `IS NULL` | Value is null/missing |
| `IS NOT NULL` | Value exists |

### Examples

```sql
-- Readings without device info
WHERE device IS NULL

-- Readings with device info
WHERE device IS NOT NULL
```

## Logical Operators

| Operator | Description |
|----------|-------------|
| `AND` | Both conditions must be true |

### Examples

```sql
-- Heart rate in range
WHERE value > 60 AND value < 100

-- Recent high readings
WHERE date > today() - 7d AND value > 100

-- Multiple conditions
WHERE date > start_of_month() AND value >= 50 AND device IS NOT NULL
```

## Field Comparisons

### Date Fields

```sql
WHERE date > today()
WHERE date > today() - 7d
WHERE date > today() - 4h
WHERE date > start_of_month()
WHERE date > '2026-02-05'
WHERE date BETWEEN '2026-02-05 16:00' AND '2026-02-05 17:00'
```

### Numeric Fields

```sql
WHERE value > 100
WHERE value >= 60
WHERE value = 72
```

### String Fields

```sql
-- Note: String comparisons are case-sensitive
WHERE source = 'Apple Watch'
```

## Swift DSL Equivalents

```swift
// Comparison operators
Operator.equal              // =
Operator.notEqual           // != or <>
Operator.greaterThan        // >
Operator.greaterThanOrEqual // >=
Operator.lessThan           // <
Operator.lessThanOrEqual    // <=
Operator.between            // BETWEEN
Operator.isNull             // IS NULL
Operator.isNotNull          // IS NOT NULL

// Usage
Health.select(.heartRate)
    .where(.value, .greaterThan, .double(100))
    .where(.date, .greaterThan, .date(.daysAgo(7)))
    .execute()
```

## Complete Examples

### Normal Heart Rate Range

```sql
SELECT * FROM heart_rate
WHERE value >= 60 AND value <= 100
ORDER BY date DESC
LIMIT 100
```

### High Calorie Burn Days

```sql
SELECT sum(value) FROM active_calories
WHERE date > today() - 30d
GROUP BY day
-- Note: HAVING not yet supported for post-aggregation filtering
```

### Readings from Known Devices

```sql
SELECT value, date, device FROM heart_rate
WHERE device IS NOT NULL AND date > today() - 7d
ORDER BY date DESC
```
